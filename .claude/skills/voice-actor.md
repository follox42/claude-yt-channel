---
name: voice-actor
description: Generate ElevenLabs voiceover tracks for a script. Uses the voice_id locked in the channel's creative-bible for consistency across videos. Use after script-smith and before render-engine.
type: agent
isolation: project
---

# voice-actor

## Mission

Convert the script's `voiceover` text into MP3 audio files via ElevenLabs API, using the channel's locked voice for consistency.

## Inputs

- `run_id` (required)
- `script_path` (required) — `runs/<id>/script.json`
- `creative_bible_path` (required) — `identities/channels/<slug>/creative-bible.json`

## Process

1. Read creative-bible:
   ```json
   "voice": {
     "mode": "elevenlabs-ai",
     "elevenlabs": {
       "voice_id": "ErXwobaYiN016d6Wd6Y8",
       "voice_name": "Antoni",
       "tone": "dramatic narration",
       "stability": 0.5,
       "similarity_boost": 0.75
     }
   }
   ```

2. If `mode != "elevenlabs-ai"` → skip, return empty.

3. Read script.json. Per scene, extract `voiceover` text. Group into chunks (one API call per scene).

4. For each chunk, call ElevenLabs API:
   ```bash
   curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
     -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
     -H "Content-Type: application/json" \
     -d "{
       \"text\": \"${voiceover_text}\",
       \"model_id\": \"eleven_multilingual_v2\",
       \"voice_settings\": {
         \"stability\": 0.5,
         \"similarity_boost\": 0.75
       }
     }" \
     --output runs/<id>/voice/scene_<n>.mp3
   ```

5. Verify each MP3 file is valid (ffprobe duration check).

6. Build manifest:
   ```json
   {
     "tracks": [
       {"scene_id": 1, "path": "runs/<id>/voice/scene_1.mp3", "duration_sec": 4.2, "text": "..."},
       {"scene_id": 2, "path": "runs/<id>/voice/scene_2.mp3", "duration_sec": 6.8, "text": "..."}
     ],
     "voice_id": "ErXwobaYiN016d6Wd6Y8",
     "voice_name": "Antoni",
     "total_duration_sec": 54.1
   }
   ```

## Constraints

- ElevenLabs free tier = 10k chars/month. Plus tier $5/mo = 30k chars. Creator tier $22/mo = 100k chars.
- Average 30s Short voiceover = ~100 words = ~600 chars → ~16 free Shorts/month.
- For long-form 10min videos: ~12-18k chars per video → 1-3 videos/month on Plus.

## API key

Stored in `config/.env`:
```
ELEVENLABS_API_KEY=sk_xxx
```

## When invoked

- After `script-smith`, in parallel with `asset-summoner` and `music-composer`
- Skip entirely if `creative-bible.voice.mode == "text-overlay-only"`

## Files read

- `runs/<id>/script.json`
- `identities/channels/<slug>/creative-bible.json`
- `config/.env`

## Files written

- `runs/<id>/voice/scene_<n>.mp3`
- `runs/<id>/voice/manifest.json`
- Updates `stage_events`

## Voice library (popular ElevenLabs voices)

| voice_id | name | tone | best for |
|---|---|---|---|
| `ErXwobaYiN016d6Wd6Y8` | Antoni | dramatic narration | history, true crime |
| `pNInz6obpgDQGcFmaJgB` | Adam | low authoritative | documentary |
| `IKne3meq5aSn9XLyUdCD` | Charlie | casual upbeat | tech, reactions |
| `21m00Tcm4TlvDq8ikWAM` | Rachel | warm calm | educational, science |
| `AZnzlk1XvdvUeBnXmlld` | Domi | mysterious | conspiracy, mystery |
| `MF3mGyEYCl7XYWbV9V6O` | Elli | young female | gen-z, lifestyle |
| `TxGEqnHWrfWFTfGW9XjX` | Josh | youthful male | gaming, action |

`creative-director` picks the right voice_id based on niche during onboarding.