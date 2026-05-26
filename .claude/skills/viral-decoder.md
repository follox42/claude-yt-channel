---
name: viral-decoder
description: Extract narrative formula from top 3 outliers in a niche by downloading the videos and analyzing structure scene-by-scene. Use after niche-radar selects a niche.
type: agent
isolation: claude-yt-channel
---

# viral-decoder

> Isolated workspace agent. Inspired by `script-extractor` + `content-dna` but rewritten and scoped to short-form.

## Mission

Given a niche, find the 3 most viral short videos and extract their shared narrative formula (hook pattern, beat structure, retention tricks).

## Inputs

- `niche_slug` (required): identifier from `niches` table
- `count` (default `3`): number of outliers to analyze
- `format` (default `shorts`): `shorts` | `long` | `mixed`

## Process

1. Query `niches` table for competitor_channels and outlier_examples.
2. For each of the top N outliers:
   - Download via `yt-dlp` (360p + .vtt subs + thumbnail + metadata).
   - Extract frames at 1 fps using ffmpeg (Short = ~60 frames max).
   - Parse the .vtt into a dedup'd transcript.
3. For each video, decompose:
   - **Hook segment** (first 3-5 sec): exact words + visual + technique
   - **Beat structure**: list scenes with duration, content, transition
   - **Text overlays**: position, font weight, animation
   - **Retention tricks**: pattern interrupts, open loops, mid-payoff
   - **CTA / End**: if any
4. Cross-compare the 3 videos. Find the COMMON formula:
   - Hook format archetype
   - Beat sequence template (e.g. `[problem 0-3s] -> [stakes 3-7s] -> [process 7-30s] -> [reveal 30-50s] -> [twist 50-60s]`)
   - Visual signature (color palette, overlay style)

## Output

JSON written to `niches.formula_json` AND `runs/<id>/formula.json`:
```json
{
  "niche_slug": "police-bodycam",
  "formula_archetype": "incident-reveal",
  "hook_pattern": "Cop says X. Camera shows Y. Text overlay: \"WHAT HAPPENS NEXT WILL SHOCK YOU\"",
  "beat_template": [
    {"name": "incident_intro", "duration_sec": [0, 5], "purpose": "establish stakes"},
    {"name": "escalation", "duration_sec": [5, 20], "purpose": "tension build"},
    {"name": "twist", "duration_sec": [20, 45], "purpose": "payoff"},
    {"name": "resolution", "duration_sec": [45, 60], "purpose": "closure"}
  ],
  "text_overlay_style": {"position": "center-top", "font": "Impact-bold", "color": "white-yellow", "animation": "pop-in"},
  "retention_tricks": ["constant text on screen", "audio peaks every 4-6s", "frame zoom on key moments"],
  "examples": [{"url": "...", "performance": {"views": 2100000, "subs": 8000}}]
}
```

## Constraints

- Use the `/watch` skill (`/config/.claude/skills/watch/scripts/watch.py`) for download + frames + transcript
- DO read frames as images to verify visual analysis
- Max 30 min per niche

## Files

- Reads: SQLite `niches`
- Writes: SQLite `niches.formula_json`, `runs/<id>/formula.json`, frames cached in `runs/<id>/frames/`