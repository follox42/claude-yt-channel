---
name: asset-summoner
description: Source visual assets for each scene — Higgsfield AI gen first (with Soul ID for character consistency if defined), footage-hunter stock fallback if credits low. Reads the channel's creative-bible for unified style.
type: agent
isolation: project
---

# asset-summoner

## Mission

For each scene in the script, produce a visual asset (image + image-to-video) that:
1. Matches the channel's locked visual_format from creative-bible
2. Uses Soul ID character reference_ids if characters are defined
3. Falls back to footage-hunter (stock) if Higgsfield credits run low

## Inputs

- `run_id` (required)
- `script_path` (required) — `runs/<id>/script.json`
- `creative_bible_path` (required) — `identities/channels/<slug>/creative-bible.json`

## Process

### Stage 1 — Load context

Read creative-bible:
- `visual_format.primary_style` — passed to every Higgsfield prompt
- `visual_format.color_palette` — used in style guidance
- `characters.cast[]` — get Soul ID `reference_id` per named character
- `asset_sourcing_priority` — ordered list like `["higgsfield-soul-id", "higgsfield-generic", "footage-hunter-stock", "footage-hunter-archive"]`

Read run budget from `config/owner.json::higgsfield.credit_budget_per_run` (default 8).

### Stage 2 — Per-scene asset sourcing

For each scene in script.json:

1. **Determine sourcing mode** based on `asset_sourcing_priority`:
   - If scene mentions a named character AND that character has a `soul_reference_id` → `higgsfield-soul-id`
   - Else if Higgsfield credits remaining > scene cost → `higgsfield-generic`
   - Else → `footage-hunter-stock` (fallback)

2. **Build the prompt** prefixed with creative-bible style:
   ```
   {primary_style}, {scene.image_prompt}, color palette: {color_palette}
   ```
   Example: `cartoon-flat, an officer pulls over a sedan at night, color palette: red+black+gold`

3. **Generate image** (mode-dependent):
   - `higgsfield-soul-id` → invoke `higgsfield-generate` skill with `--soul-id <reference_id>` + prompt
   - `higgsfield-generic` → invoke `higgsfield-generate` skill with prompt only
   - `footage-hunter-stock` → invoke `footage-hunter` skill with scene description, get image candidate

4. **Generate motion** (image → video):
   - If image came from Higgsfield → invoke `higgsfield-generate` for image-to-video with motion_prompt
   - If image came from footage-hunter → use Remotion Ken Burns effect (slow zoom) OR find matching video from stock

5. **Save** to `runs/<id>/assets/scene_<n>/image.png` + `video.mp4`.

### Stage 3 — Budget tracking

Maintain a running total in `runs/<id>/assets/budget.json`:
```json
{
  "credits_used": 0,
  "credit_cap": 8,
  "scenes_done": 0,
  "fallback_count": 0,
  "warnings": []
}
```

- If credits_used > 75% of cap → switch all remaining scenes to `footage-hunter`.
- If `fallback_count > 50% of scenes` → log warning (creative-bible budget too tight).

### Stage 4 — Manifest

Write `runs/<id>/assets/manifest.json` with full per-scene metadata + total credits + fallback counts.

## Constraints

- Max 12 generations per run (credit cap)
- Per-scene timeout: 5 min image + 5 min video
- On Higgsfield error: retry 1× with rephrase, else fallback to footage-hunter
- ALWAYS verify image dimensions match `creative-bible::visual_format.aspect_ratio`
- NEVER mix style mid-video (all scenes must use the same `primary_style`)

## When invoked

- After `script-smith`
- In parallel with `voice-actor` and `music-composer`
- Before `render-engine`

## Files read

- `runs/<id>/script.json`
- `identities/channels/<slug>/creative-bible.json`
- `identities/channels/<slug>/soul-characters/*.json`
- `config/owner.json`

## Files written

- `runs/<id>/assets/scene_<n>/{image,video}.{png,jpg,mp4}`
- `runs/<id>/assets/manifest.json`
- `runs/<id>/assets/budget.json`

## Delegates to

- `higgsfield-generate` (image + video)
- `higgsfield-soul-id` (character lock during gen)
- `footage-hunter` (stock fallback)
