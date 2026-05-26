---
name: uploader
description: Upload the rendered Short to YouTube via camoufox (human-like flow) with title, description, tags, thumbnail. Use after thumb-craft + manual approval.
type: agent
isolation: claude-yt-channel
---

# uploader

## Mission

Upload the final.mp4 to YouTube as a Short, set metadata (title, description, tags), pick thumbnail, and either publish or schedule.

## Inputs

- `run_id` (required)
- `channel_profile` (required): camoufox profile name for the target YouTube channel
- `thumbnail_choice` (default `v1`): which thumb variant to use
- `publish_mode` (default `draft`): `draft` | `now` | `schedule:<ISO>`

## Process

1. Launch camoufox with profile `<channel_profile>` (channel already logged in).
2. Navigate to YouTube Studio upload page.
3. Upload `runs/<id>/final.mp4`.
4. Wait for processing.
5. Fill metadata:
   - Title: from `ideas.title` (truncate to 100 chars, ensure compelling)
   - Description: built from script.json (CTA + hashtags)
   - Tags: derived from niche + idea (10-15 tags)
6. Set thumbnail: upload chosen variant from `runs/<id>/thumbs/`.
7. Mark as Short (vertical aspect handled automatically by YouTube if final.mp4 is 1080x1920).
8. Set "Made for kids" = No, audience appropriate.
9. Choose publish mode (draft / publish / schedule).
10. Capture the resulting video URL/ID.

## Output

Insert into SQLite `uploads`:
```json
{
  "run_id": "...",
  "youtube_video_id": "abc123",
  "channel_name": "...",
  "title": "...",
  "description": "...",
  "tags": [...],
  "thumbnail_path": "runs/<id>/thumbs/v1.png"
}
```

## Constraints

- camoufox ONLY (no YouTube Data API for MVP)
- Sleep 2-5s between UI actions
- One upload per session (avoid suspicion)
- Per-channel daily limit: 3 uploads max
- ALWAYS check for shadowban / strike warnings during the flow; abort if detected
- Manual approval required before `publish_mode=now` (default to `draft`)

## Files

- Reads: `runs/<id>/final.mp4`, `runs/<id>/thumbs/`, `runs/<id>/script.json`, SQLite `ideas`
- Writes: SQLite `uploads`, `runs/<id>/upload-result.json`