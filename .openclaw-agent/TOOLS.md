# TOOLS.md — yt-channel-orchestrator local notes

## Comptes / Auth

### Higgsfield (asset generation)
- **CLI account** : __OWNER_EMAIL__
- **Auth method** : `higgsfield auth login` (device flow, OAuth via gmail SSO)
- **Token storage** : `~/.config/higgsfield/auth.json`
- **Plan actuel** : free (10 credits) — surveiller via `higgsfield account status`
- **Budget par run** : 8 credits max (voir owner.json)
- **MCP** : ajoute a mcphub mais OAuth tokens non-persistes — utilise le CLI plutot

### Anthropic / Claude
- Auth via Claude Code (pas de cle API separee)

### mem0 (long-term memory)
- MCP : `openmemory-__OWNER_ID__`
- Namespace de cet agent : prefixer toutes les writes avec `yt-channel.<channel_slug>.`

### YouTube
- Aucun OAuth Data API v3 pour le MVP — tout passe par camoufox UI
- Chaque canal a son profil camoufox dedie (voir ci-dessous)

## Camoufox profiles (regle HARD : jamais de cross-channel)

| Profile | Logged into | Usage |
|---|---|---|
| `yt-channel-owner-__OWNER_ID__` | Higgsfield UI (gmail SSO fallback) | Fallback si CLI/MCP fail |
| `yt-channel-channel-<slug>` | YouTube Studio de CE canal | Upload + sentry pour ce canal seulement |
| `yt-channel-research` | rien (logged-out) | niche-radar + viral-decoder anonymes |

**Setup d'un nouveau profile (manual, ~5 min) :**
1. `mcp__camoufox-stealth_profiles list` — verifier qu'il n'existe pas
2. Ouvrir camoufox avec le profile (via MCP ou CLI)
3. Naviguer vers YouTube Studio (ou Higgsfield)
4. Login manuel
5. Fermer proprement
6. Les cookies persistent dans `~/.camoufox/profiles/<profile>/`

## Workspace paths cles

- **Projet code** : `${PROJECT_ROOT}/`
- **DB SQLite** : `${PROJECT_ROOT}/data/runs.db`
- **Per-run artifacts** : `${PROJECT_ROOT}/runs/<run_id>/`
- **Per-channel identity** : `${PROJECT_ROOT}/identities/channels/<slug>/`
- **Dashboard** (via plugin) : `http://<openclaw>/__openclaw__/yt-channel/`

## Skills cles a invoquer

| Skill | Quand |
|---|---|
| `niche-radar` | Stage 1 — explorer/refresh niches |
| `viral-decoder` | Stage 2 — decompose top 3 outliers |
| `idea-forge` | Stage 3 — generer 20 ideas |
| `script-smith` | Stage 4 — ecrire script scene-by-scene |
| `asset-summoner` | Stage 5 — appelle `higgsfield-generate` pour chaque scene |
| `render-engine` | Stage 6 — delegue au skill global `video-editor` |
| `thumb-craft` | Stage 7 — 3 variantes thumbnail |
| `uploader` | Stage 8 (full mode only) — camoufox upload |
| `sentry` | Stage 9 — track metrics post-pub |
| **higgsfield-generate** | Direct invoque par asset-summoner |
| **higgsfield-soul-id** | Si character consistency multi-scenes |
| **video-editor** | Pipeline rendu generique (Remotion + sub-agents si VFX) |
| **watch** | (bradautomates/claude-video) Analyser une video YT |

## Binaires sur PATH (sandbox)

- `python3` (3.12) - `~/.local/bin/python3` (symlink vers host)
- `yt-dlp` (2026.03.17) - wrapper `~/.local/bin/yt-dlp`
- `ffmpeg`, `ffprobe` (7.0.2 static) - `~/.local/bin/`
- `higgsfield`, `higgs`, `hf` (0.1.40) - `~/.local/bin/`
- `node`, `npx`, `npm` (22.22.0) - wrappers `~/.local/bin/`
- `openclaw` CLI - via `npx openclaw@latest` (broken symlink fallback)

## MCP servers utiles (mcphub.nocode18.com)

- `camoufox` — stealth browser
- `higgsfield` — image/video gen (alternative au CLI)
- `obsidian` — vault __OWNER_NAME__ (knowledge / niches / formulas)
- `openmemory-__OWNER_ID__` — mem0 namespace
- `plane` — task tracking (si besoin)
- `searxng` — recherche web (niches, trends)
- `video-gemini` — analyser une video (alternative au /watch skill)

## Tips d'execution

- **Toujours symlink vers source de verite** : tous les skills dans `.openclaw/skills/` sont des symlinks vers le projet ou `.claude/skills/` global. Pas de duplication.
- **Background long tasks** : Higgsfield generations peuvent prendre 3-5 min — utiliser `Bash run_in_background` ou attendre asynchrone.
- **WS dashboard updates** : chaque write dans `stage_events` est broadcast au dashboard en ~2s.
- **Memory pattern** : ecrire daily logs avec timestamps + decisions dans `memory/YYYY-MM-DD.md`.
