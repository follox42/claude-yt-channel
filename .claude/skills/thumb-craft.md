---
name: thumb-craft
description: Generate 3 thumbnail variants for A/B testing of a YouTube Short. Use after render-engine produces the final MP4.
type: agent
isolation: claude-yt-channel
---

# thumb-craft

## Mission

Produce 3 thumbnail candidates per video — each with a different hook angle and visual treatment — for manual or auto A/B selection.

## Inputs

- `run_id` (required)
- `final_mp4`: `runs/<id>/final.mp4`
- `idea`: from SQLite `ideas` table

## Process

1. Extract 5-10 candidate frames from the MP4 (at narrative peaks per script beat_template):
   ```bash
   ffmpeg -i runs/<id>/final.mp4 -vf "select='eq(pict_type,I)'" -vsync vfr runs/<id>/thumbs/raw_%03d.png
   ```
2. Use Claude (with vision via Read) to score each frame on:
   - Visual impact
   - Curiosity gap
   - Face/subject prominence
3. Pick the 3 best base frames.
4. For each: generate a thumbnail with:
   - Big bold text (3-5 words max, derived from `idea.hook`)
   - Arrow/circle highlight on key element
   - Slight color boost
5. Use Remotion's still rendering (`npx remotion still`) for consistent text/styling, OR ffmpeg + drawtext for simpler approach.

## Output

- `runs/<id>/thumbs/v1.png`
- `runs/<id>/thumbs/v2.png`
- `runs/<id>/thumbs/v3.png`
- `runs/<id>/thumbs/choices.json` — reasoning per variant

## Constraints

- 1080x1920 (Shorts thumbnail spec — vertical)
- Text font: Impact-bold or similar, 80-120px
- Color contrast: high (white + black stroke)
- No copyrighted elements, no real people from non-AI gen

## Files

- Reads: `runs/<id>/final.mp4`, idea row from SQLite
- Writes: `runs/<id>/thumbs/`