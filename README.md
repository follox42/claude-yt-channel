# claude-yt-channel

Isolated test project — autonomous AI pipeline producing faceless YouTube Shorts. Inspired by methods from Jack Craig (V1) and Chris Barrera (V2) breakdown, but with NEW agents (no reuse of existing team prompts directly).

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  niche-radar → viral-decoder → idea-forge → script-smith →          │
│  asset-summoner → render-engine → thumb-craft → uploader → sentry   │
└─────────────────────────────────────────────────────────────────────┘
                          ↓ events
                  ┌────────────────────┐
                  │  Dashboard (3737)  │  Next.js + SQLite
                  └────────────────────┘
```

## Stack

| Layer | Tech | Why |
|---|---|---|
| Agents | Claude Code skills (local `.claude/skills/`) | Project-scoped, isolated |
| Orchestration | Python 3.12 + asyncio | Simple, fast iteration |
| Browser auto | camoufox playbooks (YouTube + Higgsfield) | Human-like, anti-detect |
| Editing | **Remotion v4** (React/TS, headless ffmpeg render) — uses official `npx remotion skills add` for Claude Code integration. **Also exposed as OpenClaw tool `yt_channel_render_short`** | Anthropic-endorsed in 2026 |
| Dashboard | **OpenClaw native plugin** at `/__openclaw__/yt-channel/` — vanilla HTML + SQLite + WS. **Zero `npm run dev`** | Lives inside OpenClaw |
| Asset gen | **Higgsfield MCP** (`mcp__mcphub__higgsfield-*`) via mcphub | Native tool calls, OAuth gmail |
| State store | SQLite at `data/runs.db` | Zero config |
| Per-run dir | `runs/<slug>-<timestamp>/` | Auditable |

## Agents (isolated copies — inspired but rewritten)

| # | Name | Role | New / Inspired-by |
|---|------|------|-------------------|
| 1 | `niche-radar` | Find YouTube niches with RPM ≥ $5 and small-channel outliers | inspired by niche-spy + theme-detector |
| 2 | `viral-decoder` | Extract narrative formula from top 3 outliers in chosen niche | inspired by script-extractor + content-dna |
| 3 | `idea-forge` | Generate 10-30 short ideas matching the decoded formula | inspired by content-ideator |
| 4 | `script-smith` | Write 30-60s short script with scene-by-scene breakdown | new |
| 5 | `asset-summoner` | Drive Higgsfield via camoufox to generate images + image-to-video | new |
| 6 | `render-engine` | Compose final Short in Remotion (text overlays, scene timing, music) | new |
| 7 | `thumb-craft` | Generate Short thumbnail (3 variants for A/B) | new |
| 8 | `uploader` | Upload to YouTube via camoufox (title + tags + thumbnail + schedule) | new |
| 9 | `sentry` | Track post-publish metrics, feedback loop to idea-forge | inspired by analytics-tracker |

## Budget (max 20 EUR/month target)

| Service | Cost | Status |
|---|---|---|
| Higgsfield | already paid | gmail account |
| Claude API | ~10 EUR/mo | pay-as-you-go |
| YouTube API | free | optional later (camoufox suffit MVP) |
| ElevenLabs | skip MVP | Shorts text-overlay-only |
| Total NEW spend | ~10-12 EUR/mo | well under cap |

## Phases

### Phase 0 — Scaffolding (NOW)
- Workspace structure
- Agent skill files written
- Dashboard skeleton up
- Remotion project init
- Camoufox playbook templates

### Phase 1 — Single Short E2E (Week 1)
- Manual niche pick by Nolann
- Auto: viral-decoder → idea-forge → script-smith → asset-summoner → render-engine → preview
- Manual: thumbnail tweak + upload
- Goal: 1 published Short, validate quality

### Phase 2 — Semi-auto (Weeks 2-4)
- niche-radar autonomous weekly
- thumb-craft auto with A/B
- uploader auto via camoufox
- Goal: 3 Shorts/week, 1 channel

### Phase 3 — Multi-channel loop (Weeks 5-8)
- Multi-channel parallel
- sentry feedback loop to idea-forge
- Quality gate (review-gate inspired)
- Goal: 3-5 channels × 5 shorts/week

## YouTube "inauthentic content" mitigation

- Style variety per channel (different visual identity)
- Manual human touch on titles/thumbs every 2-3 uploads
- No 100% AI voice — text overlays primary
- Real subjects/scenarios (not pure AI fabrication)

## Files

- `.claude/skills/*.md` — agent skill definitions (isolated, inspired-not-copied)
- `pipeline/playbooks/*.json` — camoufox stealth playbooks (YouTube only — Higgsfield uses MCP now)
- `pipeline/orchestrator.py` — main pipeline driver
- `remotion/` — video composition project (also reachable via OpenClaw tool `yt_channel_render_short`)
- `plugin/` — **OpenClaw native plugin (the new dashboard home)**
- `dashboard/` — *deprecated standalone Next.js dashboard — kept for reference, can be deleted*
- `data/runs.db` — SQLite state store
- `runs/` — per-execution artifacts
- `config/` — API keys (gitignored), settings
- `docs/` — design notes, decisions log

## Running

```bash
cd ${PROJECT_ROOT}
# Dashboard
cd dashboard && npm run dev          # → http://localhost:3737
# Pipeline
python pipeline/orchestrator.py --niche bodycam --mode mvp
```

## OpenClaw integration (2026-05-26)

Everything now lives INSIDE the OpenClaw runtime at `~/.openclaw/`:

```
~/.openclaw/
├── agents/yt-channel-orchestrator/
│   └── agent/prompts/system.md          ← Manager agent definition
├── skills/                              ← 15 symlinked skills
│   ├── yt-channel-{9 stages}              → projects/claude-yt-channel/.claude/skills/
│   ├── higgsfield-{generate,soul-id,product-photoshoot,marketplace-cards}
│   ├── video-editor                     → /config/.claude/skills/video-editor/
│   └── watch                            (already installed)
```

Source of truth stays in this project — symlinks let OpenClaw discover everything without duplication.

**Activate the agent:** `openclaw run yt-channel-orchestrator`
**Install the plugin (dashboard):** `openclaw plugins install file:$(pwd)/plugin`

See `~/.openclaw/agents/yt-channel-orchestrator/agent/MIGRATION.md` for the full layout + commands.

## Status (Phase 0 + native plugin + OpenClaw migration done — 2026-05-26)

- [x] Workspace structure
- [x] 9 agent skill files (`.claude/skills/`)
- [x] 3 camoufox playbooks (YouTube browse, YouTube metrics, YouTube upload — Higgsfield ones deprecated, replaced by MCP)
- [x] Remotion project (composition + types + config)
- [x] Python orchestrator with stage state machine
- [x] SQLite schema + smoke test passed end-to-end (stub mode)
- [x] **Higgsfield MCP added to mcphub** (`mcp.higgsfield.ai/mcp` via `mcp-remote`)
- [x] **OpenClaw native plugin `@claude-yt-channel/openclaw-plugin`** — dashboard at `/__openclaw__/yt-channel/`, Remotion render as tool, no `npm run dev` needed
- [ ] Plugin installed in OpenClaw (user runs `openclaw plugins install file:.../plugin`)
- [ ] **Real Claude Code agent invocation wired** (next: shell out to `claude -p`)
- [ ] First real Short produced
- [ ] First Short uploaded

## Next session priorities

1. **Install the OpenClaw plugin** (5 min):
   ```bash
   cd plugin && npm install && node build.mjs
   openclaw plugins install file:${PROJECT_ROOT}/plugin
   # then open: http://<your-openclaw-host>/__openclaw__/yt-channel/
   ```
2. Wire `invoke_agent()` in `pipeline/orchestrator.py` to real Claude Code (Option A in HOWTO §5)
3. Camoufox profile setup for YouTube (one-shot, just for browse + upload now — Higgsfield is MCP)
4. Hard-code first niche to `anime-reaction-shorts` (low legal risk)
5. Trigger first run from the dashboard `+ new run` button
6. Manual review + upload

See `docs/HOWTO.md` for the step-by-step and `plugin/README.md` for plugin specifics.
