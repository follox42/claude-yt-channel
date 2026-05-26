---
name: niche-radar
description: Find YouTube niches with RPM >= $5 and small-channel outliers using camoufox on YouTube. Use when discovering a new niche or refreshing the niche pool.
type: agent
isolation: claude-yt-channel
---

# niche-radar

> Isolated workspace agent. Inspired by `niche-spy` + `theme-detector` but rewritten for this project. Do NOT call those upstream skills directly.

## Mission

Identify YouTube niches where a small creator can break in. Output a ranked list of niche candidates with measurable signals.

## Inputs

- `seed` (optional): topic seed or `null` to scan general trending
- `min_rpm` (default `5.0`): exclude niches with estimated RPM below this
- `max_channel_size` (default `50000`): focus on small/medium channels

## Process

1. Open camoufox session with profile `claude-yt-channel` (cookies persisted between runs).
2. Navigate to YouTube. Search for `seed` or browse trending Shorts.
3. For each candidate niche (~10-20):
   - Open 3-5 top videos from the last 30 days.
   - Capture: channel sub count, video views, upload frequency, comment activity.
   - Estimate RPM band based on niche category (bodycam/finance/news = high; entertainment/meme = low).
4. Score each niche on:
   - **Outlier score**: median views / channel sub ratio (small channels with viral hits = high score)
   - **RPM estimate**: $1-$30 band
   - **Saturation**: number of comparable channels (lower = better)
   - **Replicability**: visual/format complexity (text-overlay + b-roll = easy; face-cam = harder)
5. Write top 5-10 niches to SQLite `niches` table with `status='active'`.

## Output

JSON array on stdout AND insert into `niches` table:
```json
{
  "slug": "police-bodycam",
  "name": "Police Bodycam Footage",
  "rpm_estimate": 12.5,
  "competitor_channels": [{"name": "Code Blue Cam", "subs": 3200000, "url": "..."}],
  "outlier_examples": [{"title": "...", "views": 2300000, "channel_subs": 8000}],
  "saturation_score": 0.6,
  "replicability_score": 0.8
}
```

## Constraints

- Use camoufox EXCLUSIVELY (no YouTube API for MVP)
- Sleep 2-5s between actions (anti-detect)
- Max 30 min per run
- Cap at 20 video opens per session
- Persist cookies between runs to avoid relogin

## Files

- Reads: `config/.env`, `pipeline/playbooks/youtube_browse.json`
- Writes: SQLite `niches`, `runs/<id>/niche-radar.json`
- Emits stage events: `niche_radar:started`, `niche_radar:niche_found`, `niche_radar:finished`