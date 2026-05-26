// @claude-yt-channel/openclaw-plugin — native OpenClaw plugin.
//
// Exposes the dashboard at /__openclaw__/yt-channel/ and serves the
// SQLite-backed API + WebSocket event stream for the claude-yt-channel
// pipeline.

import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
import { spawn } from "node:child_process";
import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";

const require = createRequire(import.meta.url);

const BASE_PATH = "/__openclaw__/yt-channel";
const STATIC_PREFIX = `${BASE_PATH}/static/`;
const API_PREFIX = `${BASE_PATH}/api/`;
const WS_PATH = `${BASE_PATH}/ws`;

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".mp4": "video/mp4",
};

const DEFAULT_WORKSPACE = "${PROJECT_ROOT}";

function resolveConfig(pluginConfig) {
  const workspaceDir = (pluginConfig?.workspaceDir || DEFAULT_WORKSPACE).trim();
  const remotionDir = pluginConfig?.remotionDir?.trim() || path.join(workspaceDir, "remotion");
  const pythonBin = pluginConfig?.pythonBin?.trim() || "python3";
  return {
    workspaceDir,
    remotionDir,
    pythonBin,
    dbPath: path.join(workspaceDir, "data", "runs.db"),
    runsDir: path.join(workspaceDir, "runs"),
    orchestratorPath: path.join(workspaceDir, "pipeline", "orchestrator.py"),
    staticDir: path.resolve(new URL(".", import.meta.url).pathname, "..", "dashboard-static"),
  };
}

let dbInstance = null;
function getDb(config) {
  if (dbInstance) return dbInstance;
  let Database;
  try {
    Database = require("better-sqlite3");
  } catch {
    return null;
  }
  if (!fs.existsSync(config.dbPath)) return null;
  dbInstance = new Database(config.dbPath, { readonly: false, fileMustExist: false });
  dbInstance.pragma("journal_mode = WAL");
  return dbInstance;
}

function sendJson(res, status, body) {
  const payload = Buffer.from(JSON.stringify(body), "utf8");
  res.writeHead(status, {
    "content-type": MIME[".json"],
    "content-length": payload.length,
    "cache-control": "no-store",
  });
  res.end(payload);
}

function sendStatus(res, status, message) {
  const text = `${status} ${message || ""}`.trim();
  res.writeHead(status, { "content-type": "text/plain; charset=utf-8" });
  res.end(text);
}

function sendFile(res, filePath) {
  if (!fs.existsSync(filePath)) return sendStatus(res, 404, "not found");
  const ext = path.extname(filePath).toLowerCase();
  const mime = MIME[ext] || "application/octet-stream";
  const stat = fs.statSync(filePath);
  res.writeHead(200, {
    "content-type": mime,
    "content-length": stat.size,
    "cache-control": "no-cache",
  });
  fs.createReadStream(filePath).pipe(res);
}

async function readJsonBody(req, limit = 1024 * 1024) {
  return new Promise((resolve, reject) => {
    let total = 0;
    const chunks = [];
    req.on("data", (chunk) => {
      total += chunk.length;
      if (total > limit) {
        req.destroy();
        reject(new Error("payload too large"));
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => {
      try { resolve(JSON.parse(Buffer.concat(chunks).toString("utf8") || "{}")); }
      catch (e) { reject(e); }
    });
    req.on("error", reject);
  });
}

function listRecentRuns(config, limit = 50) {
  const db = getDb(config);
  if (!db) return [];
  return db.prepare("SELECT * FROM runs ORDER BY started_at DESC LIMIT ?").all(limit);
}

function getRun(config, id) {
  const db = getDb(config);
  if (!db) return null;
  return db.prepare("SELECT * FROM runs WHERE id=?").get(id) || null;
}

function listRunEvents(config, runId) {
  const db = getDb(config);
  if (!db) return [];
  return db.prepare("SELECT * FROM stage_events WHERE run_id=? ORDER BY ts ASC").all(runId);
}

function listNiches(config) {
  const db = getDb(config);
  if (!db) return [];
  return db.prepare("SELECT * FROM niches WHERE status='active' ORDER BY created_at DESC").all();
}

function summary(config) {
  const db = getDb(config);
  if (!db) return { db_missing: true };
  const c = (sql) => db.prepare(sql).get().c;
  return {
    total_runs: c("SELECT COUNT(*) as c FROM runs"),
    running: c("SELECT COUNT(*) as c FROM runs WHERE state='running'"),
    done: c("SELECT COUNT(*) as c FROM runs WHERE state='done'"),
    failed: c("SELECT COUNT(*) as c FROM runs WHERE state='failed'"),
    niches: c("SELECT COUNT(*) as c FROM niches WHERE status='active'"),
    uploads: c("SELECT COUNT(*) as c FROM uploads"),
    total_cost_eur: db.prepare("SELECT COALESCE(SUM(cost_eur),0) as s FROM runs").get().s,
  };
}

// WS broadcaster + event poller
const wsClients = new Set();
let lastEventId = 0;
let pollerStarted = false;
function startEventPoller(config) {
  if (pollerStarted) return;
  pollerStarted = true;
  setInterval(() => {
    const db = getDb(config);
    if (!db) return;
    try {
      const rows = db
        .prepare("SELECT * FROM stage_events WHERE id > ? ORDER BY id ASC LIMIT 50")
        .all(lastEventId);
      for (const r of rows) {
        lastEventId = Math.max(lastEventId, r.id);
        const data = JSON.stringify({ type: "stage_event", payload: r });
        for (const ws of wsClients) {
          try { ws.send(data); } catch { wsClients.delete(ws); }
        }
      }
    } catch {}
  }, 2000);
}

function makeHttpHandler(config) {
  return async function handle(req, res) {
    const url = new URL(req.url, "http://x");
    const p = url.pathname;

    if (p === BASE_PATH || p === `${BASE_PATH}/`) {
      return sendFile(res, path.join(config.staticDir, "index.html"));
    }

    if (p.startsWith(STATIC_PREFIX)) {
      const rel = p.slice(STATIC_PREFIX.length);
      if (rel.includes("..")) return sendStatus(res, 400, "bad path");
      return sendFile(res, path.join(config.staticDir, rel));
    }

    if (p.startsWith(API_PREFIX)) {
      const apiPath = p.slice(API_PREFIX.length);
      if (req.method === "GET" && apiPath === "summary") return sendJson(res, 200, summary(config));
      if (req.method === "GET" && apiPath === "runs") {
        const limit = parseInt(url.searchParams.get("limit") || "50", 10);
        return sendJson(res, 200, { runs: listRecentRuns(config, limit) });
      }
      if (req.method === "GET" && apiPath.startsWith("runs/")) {
        const id = apiPath.slice(5);
        const run = getRun(config, id);
        if (!run) return sendStatus(res, 404, "not found");
        return sendJson(res, 200, { run, events: listRunEvents(config, id) });
      }
      if (req.method === "GET" && apiPath === "niches") {
        return sendJson(res, 200, { niches: listNiches(config) });
      }
      if (req.method === "POST" && apiPath === "runs") {
        try {
          const body = await readJsonBody(req);
          if (!body.niche) return sendStatus(res, 400, "niche required");
          const argv = [config.orchestratorPath, "--niche", body.niche, "--mode", body.mode || "mvp"];
          const child = spawn(config.pythonBin, argv, {
            cwd: config.workspaceDir, detached: true, stdio: "ignore",
          });
          child.unref();
          return sendJson(res, 202, { spawned_pid: child.pid });
        } catch (e) { return sendStatus(res, 400, e.message); }
      }
      return sendStatus(res, 404, "unknown api");
    }

    return sendStatus(res, 404, "not found");
  };
}

function makeUpgradeHandler(/* config */) {
  // Lazy-load ws module (optional dep)
  let WSlib = null;
  let wss = null;
  try {
    WSlib = require("ws");
    wss = new WSlib.WebSocketServer({ noServer: true });
  } catch {
    return null;
  }
  return function handleUpgrade(req, socket, head) {
    const url = new URL(req.url, "http://x");
    if (url.pathname !== WS_PATH) return false;
    wss.handleUpgrade(req, socket, head, (ws) => {
      wsClients.add(ws);
      ws.on("close", () => wsClients.delete(ws));
      ws.on("error", () => wsClients.delete(ws));
    });
    return true;
  };
}

export default definePluginEntry({
  id: "yt-channel",
  name: "YouTube Short Viral",
  description:
    "Native dashboard + Remotion render + pipeline orchestration for claude-yt-channel. Visible at /__openclaw__/yt-channel/.",
  register(api) {
    const log = (msg) => api.logger?.info?.(`[yt-channel] ${msg}`);
    const pluginConfig = api.pluginConfig || {};
    const config = resolveConfig(pluginConfig);

    if (!fs.existsSync(config.workspaceDir)) {
      api.logger?.warn?.(
        `[yt-channel] workspaceDir does not exist: ${config.workspaceDir}. Dashboard will show empty.`,
      );
    }

    const handler = makeHttpHandler(config);
    const handleUpgrade = makeUpgradeHandler(config);

    api.registerHttpRoute({
      path: BASE_PATH,
      auth: "plugin",
      match: "prefix",
      handler,
      handleUpgrade: handleUpgrade || undefined,
    });

    startEventPoller(config);
    log(`activated — dashboard at ${BASE_PATH}/`);
  },
});
