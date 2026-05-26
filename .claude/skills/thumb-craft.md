---
name: thumb-craft
description: Generate 3-5 thumbnail variants per video, auto-matching the channel's thumbnail_style from creative-bible. Analyzes outlier thumbnails in the niche for pattern fit.
type: agent
isolation: project
---

# thumb-craft

## Mission

Produce a **batch of thumbnail variants** for A/B testing — all matching the channel's `creative-bible::thumbnail_style` pattern but with intentional micro-differences. Uses the most expressive frames from the final video.

## Inputs

- `run_id` (required)
- `final_mp4_path` (required) — `runs/<id>/final.mp4`
- `creative_bible_path` (required)
- `script_path` (optional) — context-aware text selection
- `n_variants` (default `creative-bible::thumbnail_style.variants_to_generate` or 3)

## Process

### Stage 1 — Frame extraction

Extract candidate frames at narrative peaks via ffmpeg:
```bash
ffmpeg -i runs/<id>/final.mp4 \
  -vf "select='eq(pict_type,I)+gt(scene,0.4)'" \
  -vsync vfr \
  runs/<id>/thumbs/raw/%03d.png
```

### Stage 2 — Frame scoring

For each candidate, score on:
- Face emotion match (if creative-bible specifies `face_emotion_target`)
- Subject prominence (subject occupies > 30% of frame)
- Color contrast (visual punch)
- Text-readable space (room for overlay text)

Use Claude vision (Read on PNG) to score subjectively. Pick top 5-10 base frames.

### Stage 3 — Pattern application

Read `creative-bible::thumbnail_style.pattern`:

| Pattern | Layout |
|---|---|
| `face-shock-with-text` | Zoom on face + huge text top |
| `before-after-split` | Vertical split, two scenes |
| `scene-with-arrow` | Arrow/circle highlight on key element |
| `object-closeup` | Tight crop on subject + minimal text |
| `text-only-bold` | No image — massive Impact text on contrast bg |

For each base frame, generate a variant by:
1. Composite frame in 1080×1920 canvas (Shorts) or 1280×720 (long-form).
2. Add big text overlay (3-5 words from script's hook or title).
3. Apply pattern-specific styling.
4. Color grade: saturation +20%, slight vignette.

### Stage 4 — Variant differentiation

Across N variants, vary:
- Base frame (different narrative moments)
- Text wording (3 angles: question / claim / pain-point)
- Text position (top / center / bottom)
- Color treatment (warm / cool / dark / vibrant)

Enough difference to A/B test, all consistent with brand.

### Stage 5 — Output

- `runs/<id>/thumbs/v1.png` ... `vN.png`
- `runs/<id>/thumbs/choices.json`:
  ```json
  {
    "variants": [
      {
        "file": "v1.png",
        "base_frame_ts": "0:08",
        "text": "HE LIED ABOUT EVERYTHING",
        "text_position": "top-center",
        "rationale": "Mirror Outlier_1 pattern — highest velocity comp"
      }
    ],
    "creative_bible_pattern": "face-shock-with-text"
  }
  ```

## Implementation

**Default = Remotion still rendering** (preferred):
- `<Thumbnail>` Remotion composition with props (frame, text, color)
- `npx remotion still src/index.tsx Thumbnail runs/<id>/thumbs/v1.png --props=...`
- Consistent typography, exact pattern

**Fallback = ffmpeg + drawtext** (lower quality, faster):
- `ffmpeg -i frame.png -vf "drawtext=..." out.png`

## Constraints

- Output: 1080×1920 (Shorts) or 1280×720 (long-form)
- Max 5 variants per video
- Per-thumbnail render < 5s
- No copyrighted elements
- WCAG AA text contrast (4.5:1 minimum)

## When invoked

- After `render-engine` (need the final.mp4)
- Before `uploader` (need thumbs to upload)

## Files read

- `runs/<id>/final.mp4`
- `identities/channels/<slug>/creative-bible.json`
- `runs/<id>/script.json`

## Files written

- `runs/<id>/thumbs/v1.png` ... `vN.png`
- `runs/<id>/thumbs/choices.json`
- Updates `stage_events`

## Tooling

- ffmpeg for frame extraction
- Claude vision (Read on PNG) for frame scoring
- Remotion `still` for variant rendering