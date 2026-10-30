---
name: uploader
description: Upload the rendered Short to YouTube via the stealth browser (CloakBrowser, `browser-<space>` MCP servers of web-stealth v3) (human-like flow) with title, description, tags, thumbnail. Use after thumb-craft + manual approval.
type: agent
isolation: claude-yt-channel
---

# uploader

## Mission

Upload the final.mp4 to YouTube as a Short, set metadata (title, description, tags), pick thumbnail, and either publish or schedule.

## Inputs

- `run_id` (required)
- `browser_space` (required): the channel's browser space, from `channel.json::browser_space` (mcphub server `browser-<space>`, e.g. `browser-yt-<slug>`)
- `thumbnail_choice` (default `v1`): which thumb variant to use
- `publish_mode` (default `draft`): `draft` | `now` | `schedule:<ISO>`

## Process

1. Use the channel's space: every call is `browser-<browser_space>-<tool>` (channel already logged in; verify with `browser_read(mode="find", query="Create")`, else `browser_handoff`).
2. `browser_open(url="https://studio.youtube.com", tab="studio")`, open the upload dialog with `browser_act`.
3. Put the file in the space first — `browser_files(action="fetch_url", url=<public URL of final.mp4>, name="final.mp4")` (or `browser_files(action="drop_link")` for a human drop) — then `browser_upload(target="input[type='file']", file="uploads/final.mp4", tab="studio")`. Same for the thumbnail.
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

- stealth browser (`browser-<space>` MCP, web-stealth v3) ONLY (no YouTube Data API for MVP)
- Sleep 2-5s between UI actions
- One upload per session (avoid suspicion)
- Per-channel daily limit: 3 uploads max
- ALWAYS check for shadowban / strike warnings during the flow; abort if detected
- Manual approval required before `publish_mode=now` (default to `draft`)

## Files

- Reads: `runs/<id>/final.mp4`, `runs/<id>/thumbs/`, `runs/<id>/script.json`, SQLite `ideas`
- Writes: SQLite `uploads`, `runs/<id>/upload-result.json`