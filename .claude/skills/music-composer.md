---
name: music-composer
description: Source or generate music tracks per scene type (hook, buildup, payoff, outro) according to the creative-bible's music direction. Supports stock libraries (Pixabay, YT Audio Library) and AI generation (Suno API, Udio).
type: agent
isolation: project
---

# music-composer

## Mission

Provide one or more music tracks for a video that match the channel's `creative-bible.json::music` direction. Returns local file paths ready for `render-engine` to mix.

## Inputs

- `run_id` (required)
- `script_path` (required) — `runs/<id>/script.json` (to detect scene types + total duration)
- `creative_bible_path` (required) — `identities/channels/<slug>/creative-bible.json`

## Process

1. Read creative-bible `music` section:
   ```json
   {
     "mode": "stock-library",   // stock-library | ai-generated-suno | ai-generated-udio | none
     "stock_library": "pixabay",
     "genre_per_scene_type": {
       "hook": "tense-cinematic-build",
       "buildup": "tense-cinematic-rise",
       "payoff": "epic-orchestral-hit",
       "outro": "subtle-fade"
     }
   }
   ```

2. If `mode == "none"` → skip, return empty manifest.

3. If `mode == "stock-library"`:
   a. Read script.json → group scenes by type (hook/buildup/payoff/outro).
   b. For each scene type, query the stock library with the genre keyword:
      - **Pixabay** API: `https://pixabay.com/api/videos/music/?q=<genre>` — free, returns mp3
      - **YT Audio Library** (no API — pre-download a curated batch per genre)
      - **Epidemic Sound** ($15/mo, has API)
   c. Download top candidate per scene type → `runs/<id>/music/<type>.mp3`.

4. If `mode == "ai-generated-suno"`:
   a. Call Suno API ($10/mo subscription required) with prompt:
      ```
      Generate a {duration_sec}s music track:
      - Genre: {genre_for_scene_type}
      - Mood: matches script intent for this section
      - No vocals
      - Loopable: {true if buildup else false}
      - Key: minor (default — adjust if upbeat)
      - BPM: {derived from scene pacing}
      ```
   b. Download generated MP3 → `runs/<id>/music/<type>-suno.mp3`.

5. Build the final mix timeline:
   - Hook plays scene 1 with -18 dB
   - Buildup ramps -16 dB → -12 dB during scenes 2-3
   - Payoff hit at climax scene (-8 dB peak)
   - Outro fades to -∞ over last 5s
   - Auto-ducking: drop -8 dB when voice present (read voice_actor manifest)

6. Output mix manifest:
   ```json
   {
     "tracks": [
       {"scene_type": "hook", "path": "runs/<id>/music/hook.mp3", "start_sec": 0, "end_sec": 8, "gain_db": -18},
       {"scene_type": "buildup", "path": "runs/<id>/music/buildup.mp3", "start_sec": 8, "end_sec": 30, "gain_db": -16, "ramp_to_db": -12},
       ...
     ],
     "ducking": {"voice_aware": true, "voice_duck_db": -8, "attack_ms": 50, "release_ms": 200},
     "lufs_target": -10,
     "true_peak_max_db": -1.0
   }
   ```

## Tools

- `curl` for stock APIs
- `ffmpeg` for trimming, fading, loudness normalization (`loudnorm` filter)
- `yt-dlp` for YouTube Audio Library if pre-downloads not available

## Constraints

- Total music file budget: < 30 MB
- Tracks must be MP3 or WAV (Remotion handles both)
- Per-track length matched to scene group duration (trim or loop as needed)
- LUFS target -10 (loud Short style) — see creative-bible

## When invoked

- After `script-smith` (need scene list) but before `render-engine` (need music files for composition)
- Can run in parallel with `asset-summoner` and `voice-actor` (no dependency between them)

## Files read

- `runs/<id>/script.json`
- `identities/channels/<slug>/creative-bible.json`

## Files written

- `runs/<id>/music/<type>.mp3` (one per scene type)
- `runs/<id>/music/manifest.json`
- Updates `stage_events`

## Cost

- Stock library: free or $15/mo subscription
- Suno API: $10/mo + ~$0.05 per track at scale
- Udio: similar to Suno
