---
name: footage-hunter
description: Source visual/audio assets from KEY-FREE public sources first (archive.org, Wikimedia, NASA, DuckDuckGo image scrape via camoufox). Optionally upgrade with Pexels/Pixabay/Unsplash keys if user provides them. Use as fallback when Higgsfield credits are low OR when real footage is required.
type: agent
isolation: project
---

# footage-hunter

## Mission

Source assets from sources that **DON'T require account creation or API keys** by default. Optional upgrade paths exist via paid/free-tier APIs but are not required.

Design principle: the pipeline must work **end-to-end with zero key-management overhead** for the user.

## Inputs

- `scene_description` (required)
- `media_type` (required) — `image` | `video` | `audio`
- `duration_sec` (if video)
- `aspect_ratio` (if video/image)
- `style_hint` (optional) — match creative-bible visual_format
- `n_results` (default 5)

## Sources by priority (zero-key first)

### Tier 0 — ZERO-KEY (always available)

| Source | Media | Method | License |
|---|---|---|---|
| **archive.org** | video, audio, image | `yt-dlp` + JSON API (no key) | Public domain (filter `licenseurl=*public-domain*`) |
| **Wikimedia Commons** | image, audio | REST API `commons.wikimedia.org/w/api.php` (no key) | Public domain / CC-BY-SA |
| **NASA Images Library** | image, video, audio | `https://images-api.nasa.gov` (no key) | Public domain (US govt works) |
| **Library of Congress** | image, audio | `loc.gov/apis` JSON (no key) | Public domain |
| **Europeana** | image, video | `api.europeana.eu` (free key, 5k req/day — optional) | Mostly CC |
| **YouTube Creative Commons** | video | `yt-dlp 'ytsearch:{query} licence=Creative Commons'` | CC-BY |
| **DuckDuckGo Images** | image | camoufox scrape `duckduckgo.com/?iax=images&iar=images&q=...` + filter free-to-use | varies (verify) |
| **Pixabay (no-API scrape)** | image, video, audio | camoufox scrape (slower, fragile) | Pixabay License |
| **Pexels (no-API scrape)** | image, video | camoufox scrape | Pexels License |

→ These cover ~80% of typical Short B-roll needs WITHOUT any API key.

### Tier 1 — OPTIONAL upgrade keys (if user signed up)

| Source | Why upgrade | Cost |
|---|---|---|
| **Pexels API** | Faster, JSON-structured, no scraping fragility | Free key (anti-bot blocks programmatic signup — manual 30s required) |
| **Pixabay API** | Faster, includes audio library | Free key (manual signup) |
| **Unsplash API** | Premium quality photos | Free key |
| **Storyblocks / Epidemic** | Production-grade, licensed | $15-30/mo |

If user has these keys in `config/.env`, footage-hunter prefers them for speed. Otherwise falls back to Tier 0.

## Process

1. Read `creative-bible.json::style_signature` for style guidance.

2. **Tier 0 first** — try the no-key sources in order:
   a. archive.org JSON API search → if match found, download via yt-dlp
   b. Wikimedia Commons API search → download direct URL
   c. NASA API search → download
   d. Library of Congress → if historical theme
   e. YouTube CC search via yt-dlp → if no other source matches
   f. DuckDuckGo image scrape via camoufox → fallback for images
   g. Pixabay/Pexels scrape via camoufox → last resort for stock photos
   
   Stop as soon as a quality candidate is found.

3. **Tier 1 (if keys present)** — try Pexels/Pixabay/Unsplash APIs in parallel for speed gain. Skip if keys empty.

4. **Validate** each candidate:
   - Resolution matches aspect_ratio
   - Duration matches range (video)
   - License is record-compatible (free commercial use OR PD)

5. Save to `runs/<id>/footage/scene_<n>/<source>-<idx>.{mp4,jpg,wav}`.

6. Output manifest:
   ```json
   {
     "scene_id": 1,
     "candidates": [
       {"source": "archive.org", "license": "Public Domain", "path": "...", "url": "...", "duration_sec": 12.3},
       {"source": "wikimedia", "license": "CC-BY-SA", "path": "...", "attribution_required": true}
     ],
     "recommended_index": 0,
     "tier_used": 0
   }
   ```

## API examples (no keys needed)

### archive.org search
```bash
curl -s "https://archive.org/advancedsearch.php?q=mediatype:movies+AND+licenseurl:%22publicdomain%22+AND+description:%22{query}%22&fl=identifier,title,description&rows=10&output=json" | jq .response.docs
```

### Wikimedia Commons
```bash
curl -s "https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=filetype:bitmap+{query}&format=json&srlimit=10" | jq .query.search
```

### NASA Images
```bash
curl -s "https://images-api.nasa.gov/search?q={query}&media_type=image,video" | jq .collection.items
```

### YouTube Creative Commons (yt-dlp)
```bash
$WS/bin/yt-dlp \
  "ytsearch20:{query} creative commons" \
  --match-filter "license=Creative Commons" \
  --no-download \
  --print "%(title)s|%(id)s|%(license)s|%(duration)s" \
  | head -10
```

## Licensing rules (HARD)

Always record source + license in the manifest. Reject if license is unclear.

- Public domain → no attribution needed
- CC-BY → attribution required in video description (auto-added by uploader)
- CC-BY-SA → attribution + share-alike (rare, OK for short clips with commentary)
- Copyrighted → REJECT unless fair-use commentary is clearly applicable AND clip < 10s

## When invoked

- Inside `asset-summoner` as fallback when:
  - Higgsfield credits at 75%+ usage
  - Style requires real footage (per creative-bible.style_signature)
  - Scene description matches public-domain archive (historical, science, news)

- Standalone for B-roll harvest before multi-video production runs.

## Files

- Reads: `runs/<id>/script.json`, `creative-bible.json`, `config/.env` (optional keys)
- Writes: `runs/<id>/footage/scene_<n>/`, `runs/<id>/footage/manifest.json`

## Tools used

- `curl` — direct API calls (all Tier 0 sources)
- `yt-dlp` — archive.org video + YouTube CC search
- `ffmpeg` — conversion, trimming, aspect fixing
- `jq` — JSON parsing
- `camoufox` — scraping fallback if APIs fail

## What makes this design robust

- **Works on first run with zero setup** — no API keys, no signups, no manual steps
- **Public domain bias** — minimizes copyright risk
- **Multiple fallbacks** — if archive.org has nothing, NASA / Wikimedia / DuckDuckGo catch it
- **Optional speed boost** — user CAN add Pexels/Pixabay/Unsplash keys later if speed matters
