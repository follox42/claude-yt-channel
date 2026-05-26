---
name: creative-director
description: Analyze the chosen niche + competitor channels and output a unified creative-bible.json for the channel — visual format (cartoon/anime/photoreal/...), color palette, character setup, voice direction, music direction, thumbnail style. Run ONCE per channel during onboarding (step 5 — branding). All downstream skills read this bible.
type: agent
isolation: project
---

# creative-director

## Mission

Produce a **unified creative bible** for a YouTube channel that locks down all visual + audio + character + thumbnail decisions in one file. Every other skill (script-smith, asset-summoner, render-engine, thumb-craft, music-composer, voice-actor) reads this bible at run start and conforms to it.

**Why one file**: previous version had styling spread across brand.json + channel.json + ad-hoc decisions per video → drift, inconsistency, "AI slop" feel. With a bible, every video looks like it's from the same channel.

## Inputs

- `channel_slug` (required) — the channel being onboarded
- `niche_slug` (required) — the chosen niche
- `formula_json_path` (optional) — output from `viral-decoder` if 3 outliers already analyzed
- `user_preferences` (optional) — what the user said during step 5 of onboarding (mood, voice mode, music intent)

## Process

### Stage 1 — Format analysis

Read `formula.json` (or invoke `viral-decoder` if missing). For each of the 3 reference outliers, identify:
- Visual style (cartoon, photoreal, anime, mixed, etc.)
- Color palette dominant
- Character usage (recurring? narrator only? none?)
- Voice register (dramatic, casual, formal, sarcastic)
- Music genre per beat type
- Thumbnail pattern (face emotion, text size, color)

Cross-reference + identify the WINNING combination in the niche.

### Stage 2 — Decision matrix

Score 4 visual format candidates for THIS specific niche:

| Format | Higgsfield strength | Production cost | Differentiation potential | Audience fit |
|---|---|---|---|---|
| cartoon-flat | ⭐⭐ | low | medium | depends |
| photorealistic-cinematic | ⭐⭐⭐⭐⭐ | medium | low (saturated) | most niches |
| anime | ⭐⭐⭐⭐ | medium | high if niche allows | gaming, reactions, lore |
| retro-vhs | ⭐⭐⭐ | low | high | conspiracy, lost media, history |
| comic-book | ⭐⭐⭐ | medium | high | history, true crime, lore |
| mixed-media | ⭐⭐ | high | very high | premium documentary |

Pick the format that:
1. Higgsfield can produce reliably (avoid mixed-media at low budget)
2. Differs from the 3 reference outliers if they're all using the same style (differentiation = algorithm signal)
3. Matches audience expectation but with a twist

### Stage 3 — Character decision

Ask (or infer from user preferences):
- **No characters** (narrator-only, faceless documentary) → simplest, default for history/educational
- **Single recurring character** (channel mascot, "host" avatar) → builds brand recognition, requires Higgsfield Soul ID
- **Small cast** (2-4 recurring) → for storytelling channels (mythology, fictional history)

If single-recurring or small-cast → **invoke `character-forge` skill** for each character (trains Soul ID, gets reference_id). Store the IDs in the bible.

### Stage 4 — Voice direction

If user said "no voice" during onboarding step 5 → set `voice.mode = "text-overlay-only"`.
Otherwise → pick ElevenLabs voice matching the niche tone:
- Documentary serious: `Brian` / `Adam` (low-pitched authoritative)
- Reaction/casual: `Charlie` / `Sam`
- Dramatic narration: `Antoni` / `Daniel`
- Mysterious: `Liam` (low whispered)

Lock `voice_id` in bible.

### Stage 5 — Music direction

Determine genre per scene type (hook/buildup/payoff/outro). Examples for niches:
- **Bizarre history** → tense-cinematic-build → epic-orchestral-hit
- **AI tools daily** → upbeat-electronic → tech-beat
- **Mythology** → atmospheric-dark → epic-orchestral-rise
- **Reactions** → quirky-loop → comedy-sting

Set `music.mode`:
- `stock-library: pixabay` (free, default)
- `ai-generated-suno` ($10/mo, full control)
- `none` if user prefers silent overlay

### Stage 6 — Thumbnail style discovery

From the 3 reference outliers' thumbnails:
- Dominant pattern (face-shock, before-after, object-closeup, text-only)
- Color contrast level (high/medium/low)
- Text word count + position
- Face emotion if face present

Decide:
- **Mirror** the dominant pattern (lower differentiation, proven works)
- **Adjacent** pattern (slightly different but same niche feel)
- **Differentiate** (risky but algorithm-friendly if niche is saturated)

Default = **adjacent** (best risk/reward for new channel).

### Stage 7 — Write the bible

Write to `identities/channels/<slug>/creative-bible.json` using the template at `identities/_template-channel/creative-bible.json`. Replace ALL `__REPLACE_ME__` and `_options` arrays should be removed (keep only the chosen value).

Also write a human-readable `creative-bible.md` next to it summarizing the choices + rationale.

## Output

- `identities/channels/<slug>/creative-bible.json` — machine-readable
- `identities/channels/<slug>/creative-bible.md` — human summary (what was chosen + why)
- `identities/channels/<slug>/soul-characters/` — Soul ID reference_ids if characters defined

## When invoked

- **Onboarding step 5 (branding)** — primary use
- **User says "redo branding"** — re-run for an existing channel (rare, requires invalidation cascade)
- **Pivot to new sub-niche** — adjust bible, may invalidate already-produced content

## Constraints

- 1 invocation per channel per major iteration (not per video)
- Cost: ~0.30 EUR (Claude analyzes 3 outliers via /watch + reasoning)
- DO NOT invoke during a regular run — bible is sacred between runs

## Files read by this skill

- `identities/channels/<slug>/channel.json` — basic channel info
- `identities/channels/<slug>/formula.json` — output from viral-decoder
- `config/owner.json` — Higgsfield budget constraints
- `identities/_template-channel/creative-bible.json` — template

## Files this skill writes

- `identities/channels/<slug>/creative-bible.json`
- `identities/channels/<slug>/creative-bible.md`
- (Optional) `identities/channels/<slug>/soul-characters/<name>.json` with reference_id from character-forge
