---
name: meta-flow-gen
description: ZERO-COST unlimited image and video generation via Meta AI (meta.ai) and Google Flow (Nano Banana model). Drives via camoufox browser automation. Used as Tier 0 fallback before consuming Higgsfield credits.
type: agent
isolation: project
---

# meta-flow-gen

## Mission

Generate images and videos using **completely free** AI services that have **unlimited** generation quotas:
- **Meta AI** (meta.ai) — unlimited images + videos, login via Google/IG/Facebook
- **Google Flow** (labs.google/fx/tools/flow) — Nano Banana model unlimited images, Seedance 15s video

This is the **Tier 0 image/video gen** in the asset-summoner sourcing ladder. Higgsfield credits become an upgrade for quality, not a requirement.

## Why it works

Both services require browser login (Google SSO) but no paid plan. Once cookies are saved in a camoufox profile, generation is unlimited. Discovered via Jacksons AI tutorial (2026-05-15).

## Inputs

- `prompt` (required) — natural-language description of what to generate
- `media_type` (required) — `image` | `video`
- `aspect_ratio` (optional) — `9:16` | `16:9` | `1:1` (default 9:16 for Shorts)
- `duration_sec` (if video, default 8) — Seedance allows up to 15
- `reference_image_path` (optional) — for image-to-image or character consistency
- `provider` (default `auto`) — `meta-ai` | `google-flow` | `auto` (race both)

## Process

### Setup (one-time)

```bash
# Open camoufox to Meta AI, login with Google
camoufox-stealth-navigate "https://www.meta.ai" --cookie_profile meta-ai-default

# Then Google Flow
camoufox-stealth-navigate "https://labs.google/fx/tools/flow" --cookie_profile google-flow-default
```

User logs in once via the camoufox session, cookies saved. Subsequent runs auto-login.

### Image generation (Meta AI)

1. Navigate to `https://www.meta.ai/?prompt=<encoded_prompt>` with `cookie_profile=meta-ai-default`
2. Toggle "Create image" if not on
3. If reference image: upload via the attachment button
4. Send prompt + optional aspect ratio instruction (e.g. "9:16 vertical")
5. Wait for generated image
6. Right-click → save image OR scrape the img src

### Image generation (Google Flow / Nano Banana)

1. Navigate to `https://labs.google/fx/tools/flow/project/<random-uuid>` with `cookie_profile=google-flow-default`
2. Select Nano Banana model (default for new projects)
3. Paste prompt
4. Set aspect ratio
5. Generate
6. Download via the download button

### Video generation

- **Meta AI**: text-to-video OR image-to-video. Duration 4-8s typically.
- **Google Flow Seedance 2.0**: better for multi-shot 15s clips. Image-to-video with reference attached.

### Multi-shot chapter prompts

For complex sequences, use **chapter-based prompting** (per Jacksons AI tutorial):

```
Chapter 1 (15s, multi-shot):
"The camera tracks down a neon Tokyo alley at night. Cuts to a black-suited figure
turning the corner. Pulls back to reveal a glowing portal. Final wide shot:
the portal opens."
```

One generation produces a multi-cut sequence inside the duration limit. Much better
density than per-scene generation.

## Output

Saves to `runs/<run_id>/assets/scene_<n>/`:
- `image.png` (if image)
- `video.mp4` (if video)
- `metadata.json` with `provider`, `cookie_profile`, `prompt`, `duration_sec`, `model_used`

## Constraints

- **First call requires manual login via camoufox** (cookies then persist 30+ days)
- Generation latency: 30-90s per image, 60-180s per video
- Aspect ratio control: Meta AI is less precise — include "vertical 9:16" in prompt
- Sometimes rate-limited (~10 gens / 5 min) — pause + retry
- Reference image upload: file must be < 5MB, JPG/PNG

## When invoked

- **Inside asset-summoner** as Tier 0 source (before Higgsfield):
  ```
  asset_sourcing_priority:
    - meta-flow-gen (Tier 0, free, unlimited)
    - higgsfield-soul-id (paid, character consistency)
    - higgsfield-generic (paid)
    - footage-hunter-stock (free, real footage)
  ```
- **Standalone** for asset harvesting before a run

## Quality vs Higgsfield Premium

| Aspect | Meta AI / Google Flow | Higgsfield Premium |
|---|---|---|
| Cost | $0 | $15/mo |
| Quota | Unlimited | ~500 credits/mo |
| Quality | Good — 90% of Higgsfield | Excellent |
| Character consistency | Via reference image attach | Via Soul ID training (better) |
| Aspect ratio control | Approximate | Precise |
| Speed | 60-90s | 30-60s |
| API access | None (browser only) | CLI + MCP |

**Use Meta/Flow for**: MVP, prototyping, high-volume Shorts, budget runs.
**Upgrade to Higgsfield when**: quality matters, recurring characters via Soul ID, batch automation.

## Files

- Reads: `runs/<id>/script.json`, `creative-bible.json`, camoufox cookie profiles
- Writes: `runs/<id>/assets/scene_<n>/`, `runs/<id>/assets/manifest.json`

## Tools used

- camoufox stealth_navigate + stealth_click + stealth_type
- camoufox cookie profile persistence
- ffmpeg for any conversion needed (aspect, codec)
