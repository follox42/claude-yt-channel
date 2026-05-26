# @claude-yt-channel/openclaw-plugin

OpenClaw native plugin for the `claude-yt-channel` project. **No more `npm run dev`** for the dashboard, no more separate Remotion process — both live inside OpenClaw.

## What it does

| Feature | URL / Tool |
|---|---|
| Dashboard (HTML) | `http://<openclaw>/__openclaw__/yt-channel/` |
| API: summary | `GET /__openclaw__/yt-channel/api/summary` |
| API: list runs | `GET /__openclaw__/yt-channel/api/runs` |
| API: get run + events | `GET /__openclaw__/yt-channel/api/runs/<id>` |
| API: list niches | `GET /__openclaw__/yt-channel/api/niches` |
| API: start a run | `POST /__openclaw__/yt-channel/api/runs` `{niche, mode}` |
| WS: live events | `ws://<openclaw>/__openclaw__/yt-channel/ws` |
| Tool: `yt_channel_list_runs` | List recent runs |
| Tool: `yt_channel_get_run` | Run details + events |
| Tool: `yt_channel_list_niches` | Active niches |
| Tool: `yt_channel_pipeline_status` | Stats summary |
| Tool: `yt_channel_start_run` | Spawn pipeline run |
| Tool: `yt_channel_render_short` | Headless Remotion render |

## Install

From the plugin directory:

```bash
cd ${PROJECT_ROOT}/plugin
npm install              # gets better-sqlite3
node build.mjs           # copies src/ -> dist/
```

Then, from OpenClaw:

```bash
# Local install (recommended for dev — no npm publish needed)
openclaw plugins install file:${PROJECT_ROOT}/plugin

# Or via npm if you publish it later
# openclaw plugins install @claude-yt-channel/openclaw-plugin
```

OpenClaw will:
1. Read `openclaw.plugin.json` (manifest)
2. Read `package.json` `openclaw.extensions` → load `dist/index.js`
3. Activate the plugin (`onActivate` hook registers HTTP/WS/tools)
4. The dashboard becomes available at `/__openclaw__/yt-channel/`

## Configure (optional)

In OpenClaw plugin config (e.g. via `openclaw plugins config yt-channel`):

```json
{
  "workspaceDir": "${PROJECT_ROOT}",
  "remotionDir": "${PROJECT_ROOT}/remotion",
  "pythonBin": "python3"
}
```

Defaults work if you keep the standard project layout.

## Prereqs for full operation

- Workspace exists at `workspaceDir` with `data/runs.db` (run `python3 pipeline/orchestrator.py --init-db` first)
- `python3` on PATH
- `npx` + `remotion` deps installed in `remotionDir` (`npm install` once)

The plugin still works without them — the dashboard renders empty / displays a hint.

## Development

- Source: `src/index.js` (no TypeScript, no bundler — vanilla ESM)
- Static files: `dashboard-static/` (HTML + CSS + JS, no framework)
- After editing source: `node build.mjs` to copy to `dist/`
- OpenClaw hot-reload picks it up on plugin restart: `openclaw plugins reload yt-channel`

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ OpenClaw host process (port: whatever OpenClaw uses)    │
│                                                         │
│  /__openclaw__/yt-channel/        ← HTML dashboard       │
│  /__openclaw__/yt-channel/api/*   ← JSON endpoints       │
│  /__openclaw__/yt-channel/ws      ← WS live events       │
│                                                         │
│  ┌──────────────────────────────────────────────┐       │
│  │ plugin dist/index.js                         │       │
│  │ ├─ HTTP handler (HTML + JSON)                │       │
│  │ ├─ WS hub (broadcasts stage_events)          │       │
│  │ ├─ DB reader (better-sqlite3 on runs.db)     │       │
│  │ ├─ Spawns: python3 orchestrator.py           │       │
│  │ └─ Spawns: npx remotion render               │       │
│  └──────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────┘
                  │
                  ▼ reads/writes
        ${PROJECT_ROOT}/
        ├── data/runs.db
        ├── pipeline/orchestrator.py
        ├── remotion/
        └── runs/<id>/...
```

The plugin **does not own** any data — it's a thin native UI/tool layer over the existing project on disk.
