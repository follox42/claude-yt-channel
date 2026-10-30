# HOWTO — Get from zero to first Short

Step-by-step to take this scaffold from "files on disk" to "a Short uploaded to YouTube".

## 0. Prerequisites already installed

- `python3` 3.12 at `~/.local/bin/python3`
- `yt-dlp` 2026.x at `~/.local/bin/yt-dlp` (needed for viral-decoder)
- `ffmpeg` / `ffprobe` 7.0.2 static at `~/.local/bin/`
- `node` v22.x via nvm (need for Remotion + dashboard)

If any are missing, see `docs/SETUP.md` (TBD) or rerun the install commands from prior sessions.

## 1. First-time install (one shot)

```bash
cd ${PROJECT_ROOT}

# Python deps are stdlib-only for the orchestrator MVP

# Remotion install (~3 min, downloads chrome-headless on first render)
cd remotion && npm install
# Add Remotion's official Claude Code skills
npx remotion skills add
cd ..

# Dashboard install (~2 min)
cd dashboard && npm install
cd ..

# DB
python3 pipeline/orchestrator.py --init-db

# Env (fill in keys)
cp config/.env.example config/.env
$EDITOR config/.env
```

## 2. Start the dashboard

```bash
cd dashboard && npm run dev
# -> http://localhost:3737
```

Leave it running in one terminal. It tails the SQLite db live.

## 3. Browser spaces setup (once)

The stealth browser is web-stealth MCP v3: one isolated *space* (cookies, tabs, files) per bearer token, exposed on mcphub as a server `browser-<space>` (tools `browser-<space>-browser_open`, `-browser_act`, `-browser_upload`, `-browser_handoff`, …).

1. Owner space (`browser-<owner_id>`, e.g. `browser-nolann`): `browser_open(url="https://higgsfield.ai")` then `browser_handoff(reason="Higgsfield login", wait=True)` — log in via Google through the control link.
2. One space per channel: on the web-stealth server `python -m stealth_mcp.admin tenant add yt-<slug> --tools basic`, add the `browser-yt-<slug>` server (`http://mcp-stealth:9000/mcp`, Bearer) to the agent's mcphub group.
3. In that space: `browser-yt-<slug>-browser_open(url="https://studio.youtube.com")` + `browser_handoff(...)` — log in as that channel only.
4. Nothing to close: cookies are persisted by the server (state saved after each navigation).

Sanity check: `browser-yt-<slug>-browser_open(url="https://studio.youtube.com")` then `browser_shot()` — you should still be logged in.

## 4. Smoke test (already passed)

```bash
python3 pipeline/orchestrator.py --niche test-smoke --mode mvp
python3 pipeline/orchestrator.py --status
```

Each stage writes a stub JSON. The dashboard at :3737 should show the run.

## 5. Wiring real agent invocation (next milestone)

The orchestrator's `invoke_agent()` is a stub. Real wiring options:

### Option A — Shell out to Claude Code (simplest)
```python
result = subprocess.run([
    "claude", "-p",
    f"Use the {stage} skill from .claude/skills/{stage}.md "
    f"with these args: {json.dumps(args)}. "
    f"Working dir is the project root. Write artifact to runs/{run_id}/."
], capture_output=True, text=True, cwd=PROJECT_ROOT)
```

### Option B — Claude Agent SDK
```python
from claude_agent_sdk import query
async for msg in query(prompt=..., options=...):
    ...
```
Use this when you want streaming events into stage_events for live dashboard updates.

### Option C — Direct Anthropic API + tool use
Cheapest for repeated stages. Bypass Claude Code entirely. Less flexibility for browser auto though.

For MVP: start with Option A.

## 6. First real run — minimal niche pick

Niche pick is the riskiest step. For first run, hard-code it:

```python
# In niche-radar agent, override:
# Use Jack Craig's "AI pet salon" angle (proven to work) OR
# Chris Barrera's "police bodycam" (proven RPM + outlier potential)
```

Recommended first niche: **`anime-reaction-shorts`** — low legal risk, plenty of reference footage, fast iteration.

Then:
```bash
python3 pipeline/orchestrator.py --niche anime-reaction-shorts --mode mvp
```

The pipeline runs through `niche_radar -> ... -> thumb_craft` (stops before upload). Output at `runs/<run_id>/final.mp4`. You manually review + upload.

## 7. Going semi-auto (Phase 2)

Once 3-5 manual uploads validated, enable uploader:

```bash
python3 pipeline/orchestrator.py --niche anime-reaction-shorts --mode full --skip niche_radar viral_decoder
# (skip the slow stages if niche + formula already cached)
```

## 8. Budget tracking

Each agent writes `cost_eur` to its stage_event payload. The orchestrator sums them into `runs.cost_eur`. The dashboard shows total spend.

Soft cap per run: 2 EUR. Hard kill if exceeded (TODO: add budget guard in orchestrator).

## 9. Common issues

| Issue | Fix |
|---|---|
| `python3: command not found` | `ln -sf /host/usr/bin/python3.12 ~/.local/bin/python3` |
| Dashboard "DB error" | Run `python3 pipeline/orchestrator.py --init-db` |
| Higgsfield login expired | Re-do step 3 above |
| Remotion render very slow | `Config.setConcurrency(8)` in `remotion.config.ts` |
| YouTube upload stuck on "processing" | The stealth browser needs longer `stay_at_least_ms` — bump to 30s |

## 10. Where to read more

- `README.md` — high-level architecture
- `.claude/skills/*.md` — what each agent does
- `pipeline/playbooks/*.json` — browser automation steps
- `data/schema.sql` — state model
- `remotion/src/ShortComposition.tsx` — video template
