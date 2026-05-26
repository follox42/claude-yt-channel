---
name: character-forge
description: Train a Higgsfield Soul ID character for visual consistency across all videos of a channel. Use when creative-director chose mode="single-recurring" or "small-cast" in the creative bible.
type: agent
isolation: project
---

# character-forge

## Mission

Create one or more **recurring AI characters** for a channel using Higgsfield Soul ID. Each character gets a `reference_id` that asset-summoner uses across ALL videos → same face, same outfit, same vibe in every Short. Critical for storytelling channels.

## Inputs

- `channel_slug` (required)
- `character_brief` (required) — JSON with:
  - `name`: e.g. "Aria" (the narrator), "Magnus" (the Viking)
  - `role`: "narrator" / "protagonist" / "mascot"
  - `appearance`: "young woman, late 20s, brown wavy hair, casual modern style" OR uploaded reference image path
  - `vibe`: "curious and analytical" / "stoic warrior" / "comedic guide"

## Process

1. Read `identities/channels/<slug>/creative-bible.json` to get `visual_format.primary_style` (cartoon vs photoreal vs anime — Soul ID format must match).

2. For each character in `character_brief`:
   a. Generate 5-8 reference images via `higgsfield-generate` skill, varying poses/expressions but locking appearance:
      - Front portrait neutral
      - Front portrait smiling
      - 3/4 view excited
      - Profile thinking
      - Action shot relevant to role
      - 1-2 alternates
   b. Review consistency — if any image deviates, regenerate with stronger prompt.
   c. Invoke `higgsfield-soul-id` skill with the 5-8 reference images → returns `reference_id` (e.g. `soul_xyz123`).
   d. Test: generate 1 image of the character in a NEW scene using the `reference_id` to verify Soul ID locked the appearance.

3. Save per character:
   - `identities/channels/<slug>/soul-characters/<name>.json`:
     ```json
     {
       "name": "Aria",
       "role": "narrator",
       "soul_reference_id": "soul_xyz123",
       "appearance_locked": "young woman, late 20s, brown wavy hair, casual modern style",
       "reference_images": ["runs/<id>/characters/aria-1.png", ...],
       "training_date": "2026-05-26",
       "test_generation_passed": true
     }
     ```
   - Reference images persisted in `identities/channels/<slug>/soul-characters/refs/<name>-N.png`.

4. Update creative-bible.json:
   ```json
   "characters": {
     "mode": "single-recurring",
     "cast": [
       {"name": "Aria", "role": "narrator", "soul_reference_id": "soul_xyz123"}
     ]
   }
   ```

## Constraints

- Cost: ~6-12 Higgsfield credits per character (5-8 reference gens + 1 test)
- Time: ~5-10 min per character (Higgsfield gen + Soul ID training takes a few minutes)
- Max 4 characters per channel — beyond that, narrative complexity hurts retention
- After training, the `reference_id` is PERMANENT — reuse across all videos of this channel

## When invoked

- ONCE per channel during onboarding (step 5b if characters opted in)
- Re-invoked only if user wants to add a new character OR redo a character (cost reset)

## Files read

- `identities/channels/<slug>/creative-bible.json`
- `config/owner.json` (Higgsfield budget)

## Files written

- `identities/channels/<slug>/soul-characters/<name>.json` (one per character)
- `identities/channels/<slug>/soul-characters/refs/<name>-*.png`
- Updates `identities/channels/<slug>/creative-bible.json::characters.cast[]`

## Downstream consumer

`asset-summoner` reads the cast at run start. When a scene mentions a character by name, asset-summoner passes the `soul_reference_id` to `higgsfield-generate` so the character looks identical to previous videos.
