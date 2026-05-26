---
name: asset-summoner
description: Source visual assets for each scene — Tier 0 (free unlimited Meta AI + Google Flow Nano Banana) first, Higgsfield (paid) for quality + character consistency, footage-hunter (stock) as last fallback. Reads the channel's creative-bible for unified style.
type: agent
isolation: project
---

# asset-summoner

## Mission

For each chapter/scene in the script, produce a visual asset (image + image-to-video) that:
1. Matches the channel's locked visual_format from creative-bible
2. Uses ZERO-COST gen first (Meta AI / Google Flow) — unlimited free
3. Falls back to Higgsfield (paid) for quality + Soul ID character consistency
4. Falls back to footage-hunter (real stock footage) as last resort

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
   - **Tier 0 first** (free, unlimited):
     - `meta-flow-gen` (Meta AI OR Google Flow Nano Banana) — ZERO cost
   - **Tier 1** (paid, quality):
     - If scene mentions a named character with `soul_reference_id` → `higgsfield-soul-id` (best character consistency)
     - Else if Higgsfield credits remaining > scene cost → `higgsfield-generic` (premium quality)
   - **Tier 2** (real footage fallback):
     - `footage-hunter-stock` (archive.org / Wikimedia / NASA / YT CC)

Default priority: try Tier 0 first, only escalate to Tier 1 if Tier 0 quality insufficient or character consistency required.

2. **Build the prompt** prefixed with creative-bible style:
   ```
   {primary_style}, {scene.image_prompt}, color palette: {color_palette}
   ```
   Example: `cartoon-flat, an officer pulls over a sedan at night, color palette: red+black+gold`

3. **Generate image** (mode-dependent):
   - `meta-flow-gen` → invoke skill with provider=auto (race Meta AI + Google Flow), aspect from creative-bible
   - `higgsfield-soul-id` → invoke `higgsfield-generate` skill with `--soul-id <reference_id>` + prompt
   - `higgsfield-generic` → invoke `higgsfield-generate` skill with prompt only
   - `footage-hunter-stock` → invoke `footage-hunter` skill with scene description, get image candidate

4. **Generate motion** (image → video):
   - If image from `meta-flow-gen` → invoke same skill with media_type=video + reference_image_path + multi_shot_prompt
   - If image came from Higgsfield → invoke `higgsfield-generate` for image-to-video with motion_prompt
   - If image came from footage-hunter → use Remotion Ken Burns effect (slow zoom) OR find matching video from stock

## Multi-shot chapter prompting (RECOMMENDED — per Jacksons AI 2026-05-27)

Instead of generating per-scene, generate **per-chapter** (4-6 chapters per 60s Short instead of 8-12 scenes). Each chapter has a multi-shot prompt that describes a sequence with internal cuts:

```
Chapter 1 (15s):
"The camera tracks down a neon Tokyo alley at night. Cuts to a black-suited figure
turning the corner. Pulls back to reveal a glowing portal. Final wide shot:
the portal opens."
```

One gen → one 15s clip with 4 internal cuts. Density 4× better than 1-scene-1-gen.

Models supporting multi-shot:
- Seedance 2.0 (Higgsfield, 15s) ⭐ best
- Google Flow / Nano Banana (free, varies)
- VO3 (8s limit, multi-shot capable)

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
