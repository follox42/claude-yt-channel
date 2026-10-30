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
- Aucun OAuth Data API v3 pour le MVP — tout passe par le navigateur stealth (CloakBrowser, web-stealth MCP v3, serveurs mcphub `browser-<space>`)
- Chaque canal a son espace navigateur dedie (voir ci-dessous)

## Espaces navigateur (regle HARD : jamais de cross-channel)

Le navigateur stealth v3 a un espace (cookies, onglets, fichiers) par token ; chaque espace est un serveur mcphub `browser-<space>` et ses outils s'appellent `browser-<space>-browser_open`, `-browser_act`, `-browser_read`, `-browser_shot`, `-browser_upload`, `-browser_files`, `-browser_handoff`, `-playbook`… Plus de parametre `profile` / `cookie_profile` : l'espace EST l'identite.

| Espace (serveur mcphub) | Logged into | Usage |
|---|---|---|
| `browser-__OWNER_ID__` | Higgsfield UI (gmail SSO fallback), compte de l'owner | Fallback si CLI/MCP fail |
| `browser-yt-<slug>` | YouTube Studio de CE canal | Upload + sentry pour ce canal seulement |
| `browser-yt-research` | rien (logged-out) | niche-radar + viral-decoder anonymes |

**Setup d'un nouvel espace (admin, ~5 min) :**
1. `browser-yt-<slug>-browser_status` — verifier qu'il n'existe pas deja (erreur = pas de serveur)
2. Sur le serveur web-stealth : `python -m stealth_mcp.admin tenant add yt-<slug> --tools basic` (token affiche une seule fois)
3. Dans mcphub : serveur `browser-yt-<slug>` (streamable-http, `http://mcp-stealth:9000/mcp`, `Authorization: Bearer <token>`), ajoute au groupe de cet agent
4. `browser-yt-<slug>-browser_open(url="https://studio.youtube.com")` puis `browser-yt-<slug>-browser_handoff(reason="Login YouTube Studio <slug>", wait=True)` — login manuel par l'humain via le lien de controle
5. Les cookies persistent dans l'espace ; rien a fermer (le serveur gere les onglets inactifs)

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
| `uploader` | Stage 8 (full mode only) — upload via `browser-yt-<slug>` |
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

- `browser-<space>` — stealth browser (web-stealth v3, CloakBrowser) : `browser-__OWNER_ID__`, `browser-yt-<slug>`
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
