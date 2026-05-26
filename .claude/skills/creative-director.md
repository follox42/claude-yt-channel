---
name: creative-director
description: Analyze the chosen niche's top performers and DERIVE a unique style_signature for the channel — no fixed enum, the format is whatever works for the niche (iPhone screenshot scroll, Subway Surfers overlay, AI news anchor, Reddit dark-mode, kurzgesagt-flat, etc). Outputs creative-bible.json with a reproducible production_recipe.
type: agent
isolation: project
---

# creative-director

## Mission

Watch the niche's outliers and **describe their visual signature in free-form** — then write a production recipe to reproduce it with our tools. Style is **emergent**, not picked from a dropdown.

The default formats people think of (cartoon, photoreal, anime) are only 5% of what cartonne on YT in 2026. The 95% is weird hybrid stuff:
- iPhone Messages app with auto-scroll narration
- Subway Surfers gameplay loop as background under serious content
- Reddit dark-mode UI scrolling with voiceover reading the post
- Split-screen with AI character reacting to news
- Screenshot tweets + zoom + dramatic music
- Hand-drawn whiteboard explanations
- AI news anchor (talking head) over B-roll
- Pixar-style storytime (3D animated)
- Stop-motion toy figurines acting out events

Creative-director's job is to **discover which weird hybrid works in THIS niche** and lock it in.

## Inputs

- `channel_slug` (required)
- `niche_slug` (required)
- `formula_json_path` (optional) — from `viral-decoder`
- `user_preferences` (optional) — what user said during step 5 of onboarding

## Process

### Stage 1 — Deep observation (not classification)

Invoke `/watch` on 3-5 outlier videos in the niche. For each, capture:

- **What the screen actually shows at second 1, 5, 15, 30**
- Is there a face? Real or AI?
- What's in the background? Solid color? Gameplay? Real footage?
- UI elements? iPhone bezel? Reddit chrome? News ticker?
- Animation type? Smooth pan? Hard cuts? Scroll? Zoom?
- Text on screen? Bottom captions or top hook overlay? Both?
- Audio? Narrator voice? Music genre? SFX hits?

**Don't classify too early.** Document what you see literally. The label comes after observation, not before.

### Stage 2 — Pattern extraction

After watching 3-5 outliers, find the COMMON signature:

- "All 3 use iPhone Messages UI overlaid on a colored background"
- "Top 2 have a Minecraft parkour loop in the bottom-third"
- "Every outlier opens on a closeup face with text 'WAIT FOR IT'"
- "Background is always a moving dolly shot of a generic city"

Extract 3-7 **key visual techniques** that recur across outliers. These are the building blocks.

### Stage 3 — Style signature

Synthesize into a `style_signature` with:

- **`label`** — short slug describing the style. Free-form. Examples:
  - `iphone-imessage-narration`
  - `reddit-dark-mode-scroll`
  - `subway-surfers-overlay-bottom`
  - `ai-news-anchor-broll`
  - `split-reaction-ai-face`
  - `screenshot-tweet-zoom-narration`
  - `whiteboard-marker-explainer`
  - `pixar-3d-storytime`
  - `comic-book-panels`
  - `cartoon-flat-rapid-cuts`

  Coin a new label if no existing one fits. Be specific.

- **`description`** — 2-5 sentences of prose describing the look. Specific enough that another agent reading this can reproduce it without re-watching the outliers.

- **`key_visual_techniques`** — list of reproducible moves (5-10 items).

- **`reference_outliers`** — links to the videos that exemplify this style, with what to borrow per channel.

### Stage 4 — Production recipe

This is the critical step. For the style_signature you just defined, write a **reproducible recipe** using OUR tools:

```json
"production_recipe": {
  "primary_tool": "remotion",   // or "higgsfield-only" or "footage-hunter-only" or "hybrid"

  "remotion_components": [
    "<IPhoneMessagesUI>",       // need to build / install
    "<SubwaySurfersLayer>",
    "<RedditPostScroll>"
  ],

  "asset_sources_per_scene_type": {
    "narrator_face": "higgsfield-soul-id (if character defined)",
    "scene_b_roll": "higgsfield-generate (style: {label})",
    "ui_screenshots": "Remotion templates (no gen needed)",
    "background_loop": "footage-hunter (Pexels gameplay) or archive.org",
    "emoji_reactions": "Remotion + emoji-mart library",
    "text_overlays": "Remotion drawText"
  },

  "complexity_score": 3
}
```

The recipe tells `asset-summoner` HOW to source each scene type. Different style_signatures route assets differently:

- `cartoon-flat` → 100% Higgsfield, no Remotion UI overlays
- `iphone-imessage-narration` → 80% Remotion UI templates + 20% Higgsfield for emoji reactions
- `stock-footage-narration` → 100% footage-hunter + Remotion text overlays, 0% Higgsfield
- `subway-surfers-overlay` → 30% Higgsfield (main content) + 70% Remotion (gameplay loop layer + overlays)

### Stage 5 — Complexity check

Score the recipe `complexity_score` (1-5):
- **1** = text overlay on solid bg (Remotion only, 0 Higgsfield)
- **2** = stock footage + narration (footage-hunter + voice-actor)
- **3** = Higgsfield gen scenes + Remotion overlays (standard mix)
- **4** = Custom Remotion components needed (iPhone UI, Reddit UI, news ticker)
- **5** = Soul ID characters + custom UI + complex compositing

If complexity_score == 4 or 5 → flag in `creative-bible.md` so user knows production time will be higher AND custom Remotion components must be built before first render.

### Stage 6 — Color palette + thumbnail

Standard: extract dominant colors from outlier reference frames. Override with brand colors if user has them.

For thumbnail_style:
- Watch outlier thumbnails (extract via `yt-dlp --write-thumbnail`)
- Describe their pattern_label free-form (e.g. `closeup-face-yellow-text`, `phone-screenshot-zoom`, `split-before-after`)
- Don't force into the old fixed enum.

### Stage 7 — Voice + music

Pick from outliers' audio patterns:
- `voice.mode` based on user preference (default = text-overlay-only for MVP)
- If voiceover used, pick voice_id matching narrator tone in outliers
- Music genre per scene type from outlier audio analysis

### Stage 8 — Write the bible

Write to `identities/channels/<slug>/creative-bible.json` + human-readable `creative-bible.md`.

If style_signature requires Remotion components that don't exist yet, also write `identities/channels/<slug>/remotion-todo.md` with the components to build.

## Output

- `identities/channels/<slug>/creative-bible.json` — machine-readable
- `identities/channels/<slug>/creative-bible.md` — human summary
- `identities/channels/<slug>/remotion-todo.md` — if custom components needed
- (Optional) `identities/channels/<slug>/soul-characters/<name>.json` if character-forge runs

## When invoked

- Onboarding step 5 (branding) — primary
- "Redo branding" user request — re-run with cascade invalidation
- "Pivot to new sub-niche" — adjust style_signature

## Constraints

- Watch at least 3 outliers (5+ ideal). Less = unreliable pattern.
- Don't pick a style_signature you can't reproduce with available tools. If a niche is 100% real footage of skydiving and we have no skydive sources → admit it and recommend a different niche or hybrid approach.
- Cost: ~0.50 EUR (Claude + /watch on 3-5 outliers).
- If 2+ runs produce different style_signatures for the SAME niche → user must choose, don't pick arbitrarily.

## Files read

- `identities/channels/<slug>/channel.json`
- `identities/channels/<slug>/formula.json` (from viral-decoder)
- `config/owner.json`

## Files written

- `identities/channels/<slug>/creative-bible.json`
- `identities/channels/<slug>/creative-bible.md`
- `identities/channels/<slug>/remotion-todo.md` (conditional)

## Skills delegated to

- `/watch` — analyze each outlier in detail
- `viral-decoder` — if formula.json not present

## Examples of valid style_signatures (just labels — descriptions are written at runtime)

| Niche | Likely style_signature | complexity |
|---|---|---|
| Reddit stories | `reddit-dark-mode-scroll` | 3 |
| Bizarre history | `cartoon-flat-rapid-cuts` OR `comic-book-panels` OR `retro-vhs-found-footage` | 2-3 |
| AI tools | `screenshot-tweet-narration` OR `ai-news-anchor-broll` | 2-4 |
| Police bodycam | `bodycam-real-footage-redacted` (real footage only) | 2 |
| Drama explainers | `subway-surfers-overlay` OR `minecraft-parkour-overlay` | 3 |
| Sports moments | `slow-motion-cinematic-replay` | 2 |
| Tech reviews | `closeup-product-with-text-callouts` | 2 |
| Cooking shorts | `top-down-hand-cooking-fast-cuts` | 2 |
| Mythology | `pixar-3d-storytime` OR `comic-book-panels` | 4 |
| Stoic philosophy | `slow-cinematic-narrator-quote` | 2 |
| Conspiracy | `retro-vhs-found-footage` OR `news-broadcast-mockup` | 3 |
| Anime reactions | `split-screen-reaction-clips-fair-use` | 3 |
| Speedruns | `gameplay-recording-with-celebration-overlay` | 2 |

→ But these are just hints. **Always derive the actual label from outliers**, don't pick from this list blindly.
