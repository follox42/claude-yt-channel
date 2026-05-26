---
name: script-smith
description: Write a short script with chapter-based or scene-based breakdown, including multi-shot prompts, ElevenLabs emotion-tagged voiceover, text overlays, and music cues. Use after idea-forge selects an idea.
type: agent
isolation: project
---

# script-smith

## Mission

Convert an idea into a production-ready short script structured for the rest of the pipeline:
- **Voiceover** with ElevenLabs `[emotion]` tags (whisper / dramatic / laugh / etc)
- **Multi-shot chapter prompts** for video gen (4-6 chapters per 60s Short)
- **Text overlays** with position + animation per beat
- **Music cues** per scene type (hook / buildup / payoff / outro)
- **Audio SFX hints** for music-composer ducking sync

## Inputs

- `idea_id` (required) — from `ideas` table
- `output_mode` (default `chapters`) — `chapters` (4-6 multi-shot, preferred) | `scenes` (8-12 single-shot, legacy)
- `target_duration_sec` (default 55) — Shorts sweet spot
- `target_voice_id` (optional) — overrides creative-bible voice_id

## Process

1. Read idea's `beat_assignment` + niche `formula.json` + channel `creative-bible.json`.

2. Generate the script via Claude (sonnet) targeting `output_mode`.

### Chapter mode (default, recommended)

Output 4-6 **chapters**, each:
- `chapter_id` (int)
- `start_sec`, `end_sec` (8-15s per chapter)
- `scene_type` (hook / buildup / payoff / outro)
- `voiceover` (text with `[emotion]` tags) — concatenated and synced to chapter duration
- `multi_shot_prompt` (single rich prompt describing internal cuts) — for Seedance 2.0 / Google Flow
- `text_overlays[]` (list of overlays within the chapter with timing)
- `music_cue` (genre hint for this chapter)
- `sfx_cues[]` (timestamps for whoosh / impact / glitch)

Example chapter:
```json
{
  "chapter_id": 1,
  "start_sec": 0, "end_sec": 12,
  "scene_type": "hook",
  "voiceover": "[dramatic] It's the 4th of March, 2023. [whisper] A marble hall in downtown Dubai. [calm] A man walks onto the stage.",
  "multi_shot_prompt": "Cinematic wide establishing shot of a marble auditorium at night, then cuts to a close-up of a faceless mannequin in a black suit stepping onto a glowing stage, then pulls back to a behind-shoulder shot revealing a giant projection screen lighting up. All in 3D mannequin documentary style, sepia-cinematic grade.",
  "text_overlays": [
    {"text": "WAIT FOR IT", "at_sec": 0, "duration_sec": 3, "position": "top-center", "animation": "pop-spring"},
    {"text": "DUBAI 2023", "at_sec": 5, "duration_sec": 3, "position": "bottom-center", "animation": "fade-in"}
  ],
  "music_cue": "tense-cinematic-build",
  "sfx_cues": [{"at_sec": 7, "type": "deep_drone_swell"}]
}
```

### Scene mode (legacy, only for models without multi-shot)

Output 8-12 **scenes**, each with single image_prompt + motion_prompt. Same as old structure.

## ElevenLabs emotion tag syntax

In `voiceover` text, use `[bracket]` tags inline:
- `[whisper]` — whispered delivery
- `[dramatic]` — dramatic emphasis
- `[laugh]` — laughter
- `[excited]` / `[calm]` / `[serious]` — tone shifts
- `[music]` — instrumental swell hint (not parsed as audio, used by music-composer)

Tags are consumed by `voice-actor` skill and produce the matching ElevenLabs V3 prosody.

## Multi-shot prompt rules

- Describe **3-4 internal cuts** within one chapter (so model generates a sequence in single output)
- Use temporal markers: "then cuts to", "pulls back to reveal", "final wide shot"
- Anchor visual style from creative-bible (`primary_style`, color_palette, key_visual_techniques)
- Include character reference if defined (e.g. "the recurring red-suit mannequin")

## Output

JSON at `runs/<id>/script.json`:
```json
{
  "idea_id": 42,
  "duration_sec": 55,
  "output_mode": "chapters",
  "chapters": [ {...}, {...} ],
  "total_voice_chars": 850,
  "creative_bible_ref": "identities/channels/<slug>/creative-bible.json",
  "estimated_render_time_sec": 180,
  "estimated_higgsfield_credits": 4,
  "estimated_elevenlabs_chars": 850
}
```

## Constraints

- 45-60s total for Shorts (no longer)
- Chapters: 4-6 per Short, each 8-15s
- Text overlays present in EVERY chapter (sound-off viewing dominates)
- Voiceover with `[emotion]` tags — at least 2 tag changes per chapter
- Multi-shot prompts: avoid copyrighted refs, no real people names, no controversial figures
- Cost cap: 0.3 EUR per run

## Files

- Reads: SQLite `ideas`, `niches.formula_json`, `identities/channels/<slug>/creative-bible.json`, `~/.claude/skills/hooks-library` (for hook archetype reference)
- Writes: `runs/<id>/script.json`

## Downstream consumers

- `asset-summoner` reads `chapters[].multi_shot_prompt` → routes to meta-flow-gen / higgsfield
- `voice-actor` reads `chapters[].voiceover` → parses `[emotion]` tags → ElevenLabs V3 per-chapter
- `music-composer` reads `chapters[].music_cue` → picks track per type from YT Audio Library
- `render-engine` assembles all chapters + voice + music + overlays via Remotion
- `thumb-craft` picks high-impact frame timestamps from chapters
