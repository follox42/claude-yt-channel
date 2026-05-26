---
name: sentry
description: Track post-publish metrics of uploaded Shorts and feed performance signals back to idea-forge. Use as scheduled job after uploads, or on-demand.
type: agent
isolation: claude-yt-channel
---

# sentry

## Mission

Monitor every published Short's performance and create a feedback signal that idea-forge can use to bias future ideation toward what works.

## Inputs

- `mode` (default `incremental`): `incremental` (only check uploads < 7 days old) | `all`
- `channel_filter` (optional): single channel name

## Process

1. Query SQLite `uploads` for videos to check.
2. For each, navigate via camoufox to YouTube Studio analytics OR the public watch URL.
3. Capture:
   - views, likes, comments, avg view %, watch time, audience retention curve
   - first-24h velocity (views per hour)
4. Compute scores:
   - `engagement_rate` = (likes + comments) / views
   - `retention_health` = avg_view_pct
   - `velocity_score` = first-24h views vs channel median
5. Write to SQLite `metrics` (one row per capture, multiple over time).
6. Generate feedback summary per niche:
   - Which ideas overperformed (top 20%)?
   - Which beat templates retained best?
   - Which thumbnail variants won?
7. Output a `feedback.json` consumed by idea-forge on next ideation run.

## Output

Inserted rows in SQLite `metrics` + `runs/<id>/sentry-feedback.json`:
```json
{
  "captured_at": "2026-05-26T...",
  "winning_patterns": {
    "hook_styles": ["incident-reveal", "stakes-first"],
    "beat_templates": ["template_A"],
    "thumbnail_styles": ["face-shocked-yellow-text"]
  },
  "losing_patterns": {...},
  "niche_health": {"police-bodycam": "healthy", "anime-reaction": "declining"}
}
```

## Constraints

- camoufox, no API
- Check each video at: +1h, +24h, +7d, +30d after upload
- Anti-detect: vary delays, vary navigation paths
- Read-only on YouTube (NEVER comment, like, etc. from sentry session)

## Files

- Reads: SQLite `uploads`
- Writes: SQLite `metrics`, `runs/<id>/sentry-feedback.json`