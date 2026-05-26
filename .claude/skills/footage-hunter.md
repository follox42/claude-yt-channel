---
name: footage-hunter
description: Multi-source asset sourcing for video production. Search and download free stock footage/images from Pexels, Pixabay, Unsplash, archive.org, government FOI databases. Use as fallback when Higgsfield credits low OR when real footage is required (historical documentary, news reactions).
type: agent
isolation: project
---

# footage-hunter

## Mission

Source video/image assets from **non-Higgsfield sources** — used either as primary (long-form documentaries needing real footage) or fallback (Higgsfield credits exhausted).

Returns local file paths ready for `render-engine` to compose.

## Inputs

- `scene_description` (required) — what the asset should show, in plain English
- `media_type` (required) — `image` | `video` | `audio`
- `duration_sec` (if video) — target duration
- `aspect_ratio` (if video/image) — `9:16` | `16:9` | `1:1`
- `style_hint` (optional) — match the creative-bible visual_format if possible
- `n_results` (default 5) — how many candidates to return

## Sources by priority

### Tier 1 — Free APIs (no auth needed beyond free signup)

| Source | Use for | API | Auth |
|---|---|---|---|
| **Pexels** | Stock photo + video, modern lifestyle | `https://api.pexels.com/v1/search` | Free key |
| **Pixabay** | Stock photo + video + audio | `https://pixabay.com/api/` | Free key |
| **Unsplash** | High-res photo | `https://api.unsplash.com/search/photos` | Free key |
| **YT Audio Library** | Royalty-free music + SFX | manual download | none |

### Tier 2 — Archive sources

| Source | Use for | Method |
|---|---|---|
| **archive.org** | Historical footage, public domain | `archive.org/details/<id>` + `yt-dlp` |
| **NASA Images Library** | Space/science imagery | `https://images-api.nasa.gov` |
| **Public.work** | Public domain art + photos | Web scrape via camoufox |
| **Library of Congress** | Historical images, USA | Web scrape |
| **Europeana** | European cultural heritage | API |

### Tier 3 — Niche-specific

| Niche | Source |
|---|---|
| Bodycam / police | FOI requests (long lead time) OR Police Activity YouTube channels (fair-use clips with substantial commentary) |
| Anime | clip-sourcing TBD (rights-grey — use stills + commentary only) |
| News | Reuters / AP archive (paid) or news YT channels with fair-use commentary |
| Historical photos | Library of Congress + Europeana + Public.work |
| Maps / diagrams | OpenStreetMap + d3.js generated SVG |

## Process

1. Read `identities/channels/<slug>/creative-bible.json` to get `visual_format.primary_style`.

2. For each requested scene:
   a. Build search query — extract keywords from `scene_description`.
   b. Try Tier 1 APIs first (Pexels → Pixabay → Unsplash) — fastest, highest quality.
   c. If no satisfying match, try Tier 2 (archive sources via API or yt-dlp + camoufox).
   d. If still nothing, fallback to camoufox stealth search on Google Images (extract attribution-free CC0/CC-BY results).

3. For each candidate, download + save to `runs/<id>/footage/scene_<n>/<source>-<n>.{mp4,jpg,wav}`.

4. Return manifest JSON:
   ```json
   {
     "scene_id": 1,
     "candidates": [
       {"source": "pexels", "license": "Pexels Free", "path": "runs/<id>/footage/scene_1/pexels-1.mp4", "duration_sec": 12.3, "aspect": "9:16"},
       {"source": "pixabay", "license": "Pixabay License", "path": "runs/<id>/footage/scene_1/pixabay-2.mp4", "duration_sec": 8.5, "aspect": "16:9"}
     ],
     "recommended_index": 0
   }
   ```

## Licensing rules (HARD)

- ALWAYS record the source + license in the manifest.
- Pexels/Pixabay/Unsplash → free for commercial use, no attribution needed on YouTube (but record in run metadata).
- archive.org → public domain only (filter `mediatype=movies/audio/image` AND `licenseurl=public-domain`).
- NEVER use copyrighted material without explicit fair-use commentary in script.
- If license unclear → SKIP the asset, don't include in candidates.

## Constraints

- API rate limits: Pexels 200 req/hour, Pixabay 100 req/hour — cache responses
- File size cap per asset: 50 MB (max ~30s 1080p video)
- Total footage budget per video: 500 MB
- Max sources per scene: 5 candidates

## API keys

Stored in `config/.env`:
```
PEXELS_API_KEY=xxx
PIXABAY_API_KEY=xxx
UNSPLASH_ACCESS_KEY=xxx
```

If a key missing → skip that source silently and try next.

## When invoked

- **Inside `asset-summoner`** as fallback when:
  - Higgsfield credits below threshold (per `owner.json::higgsfield.credit_budget_per_run`)
  - Scene requires real footage (creative-bible `asset_sourcing_priority` has `footage-hunter-stock` before `higgsfield-*`)
  - Specific niche demands real footage (bodycam, news, historical photos)

- **Standalone** for B-roll harvest before a multi-video production run.

## Files read

- `identities/channels/<slug>/creative-bible.json`
- `config/.env` (API keys)
- `config/owner.json` (budget)

## Files written

- `runs/<id>/footage/scene_<n>/<source>-<idx>.{mp4,jpg,wav}`
- `runs/<id>/footage/manifest.json`
- Updates `stage_events` with source counts + licenses

## Tools used

- `curl` for direct API calls (Pexels/Pixabay/Unsplash JSON)
- `yt-dlp` for archive.org video downloads
- `camoufox` MCP for web scraping when no API exists
- `ffmpeg` for any conversion needed (codec, aspect)
