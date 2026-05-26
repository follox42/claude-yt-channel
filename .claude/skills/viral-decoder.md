---
name: viral-decoder
description: Deep-extract EVERYTHING from top 3 outliers in a niche — narrative structure, visual style, music (genre/BPM/drops), voiceover (AI vs human, accent, pace), SFX, thumbnails, on-screen text patterns. Output is the complete formula.json + audio-fingerprint.json + thumbnail-analysis.json used by creative-director and downstream skills.
type: agent
isolation: project
---

# viral-decoder

## Mission

Take a niche + 3-5 outlier videos and produce a **full creative DNA dump** — not just the story arc, but every reproducible element: visuals, music, voice, SFX, thumbnails, on-screen text.

Three artifacts produced:
1. `formula.json` — narrative structure (hook, beats, retention tricks)
2. `audio-fingerprint.json` — music + voice + SFX analysis
3. `thumbnail-analysis.json` — outlier thumbs decomposed

These feed `creative-director` (which derives the style_signature) and downstream skills (script-smith, music-composer, voice-actor, thumb-craft).

## Inputs

- `niche_slug` (required)
- `outlier_urls` (required) — list of 3-5 YouTube URLs to decompose
- `format` (default `shorts`)

## Process

### Stage 1 — Download

For each outlier URL:
```bash
$WS/bin/yt-dlp \
  -f "bestvideo[height<=720]+bestaudio/best[height<=720]" \
  --merge-output-format mp4 \
  --write-auto-sub --write-sub --sub-lang en --sub-format vtt \
  --write-thumbnail \
  --write-info-json \
  -o "runs/<id>/outliers/<n>/video" \
  "$URL"
```

Save: video.mp4 + subs.en.vtt + thumbnail.jpg + info.json (metadata).

### Stage 2 — Narrative formula (existing)

Use `/watch` skill on each video to extract:
- Hook (first 3-5 sec): exact words + visual + technique
- Beat structure: scenes with duration, content, transition
- Retention tricks: pattern interrupts, open loops, mid-payoffs
- CTA / End structure
- On-screen text patterns (font, position, animation, when)

Cross-compare 3 outliers → common formula in `formula.json`.

### Stage 3 — Audio fingerprint (NEW)

For each outlier video:

**3a. Extract audio**
```bash
$WS/bin/ffmpeg -i video.mp4 -vn -acodec copy audio.m4a
$WS/bin/ffmpeg -i video.mp4 -vn -ar 16000 -ac 1 audio_16k.wav
```

**3b. Voice detection**
- Run silence detection: `ffmpeg -af silencedetect=n=-30dB:d=0.5`
- If continuous voice present > 70% → has voiceover
- If voice present, extract a 5s sample → identify:
  - **Gender** (via pitch range analysis with ffmpeg)
  - **AI vs human**: ElevenLabs/AI voices have very consistent pitch + no breath sounds. Real humans have micro-breath, pitch variation, mouth sounds.
    - Check pitch standard deviation across the sample — AI voice usually < 30Hz std, human > 50Hz std.
    - Check breath noise frequency content
  - **Voice mood**: dramatic / casual / sarcastic / educational (Claude vision on transcript + audio context)
  - **Pace**: words per minute from transcript / audio duration

**3c. Music detection**
- Compute audio without voice (stem separation IF demucs installed, ELSE assume music is bottom layer):
- BPM detection via tempo analysis (using onset detection):
  ```bash
  $WS/bin/ffmpeg -i audio_16k.wav -af "asetnsamples=samples=16000,astats=metadata=1:reset=1" -f null - 2>&1 | grep "Overall.*tempo"
  ```
- OR use librosa if python available (more accurate)
- Detect music drops: large peaks in audio energy aligned to beats
- Identify genre via Claude analysis of audio + scene context
- Music presence per scene (was music playing during scene N? attenuated for voice ducking?)

**3d. SFX detection**
- Detect transient peaks NOT aligned with music beats and NOT voice
- These are SFX hits (whoosh, ding, punch, glitch, etc.)
- Log SFX timestamps + suspected type
- Pattern: how many SFX per minute? Aligned with cuts?

Output `audio-fingerprint.json`:
```json
{
  "niche_slug": "...",
  "per_outlier": [
    {
      "url": "...",
      "duration_sec": 55.2,
      "voice": {
        "present": true,
        "type_estimate": "ai_elevenlabs",
        "gender": "male",
        "mood": "dramatic-narration",
        "wpm": 165,
        "consistent_voice": true,
        "language": "en",
        "accent": "american-neutral"
      },
      "music": {
        "present": true,
        "genre_estimate": "tense-cinematic-build",
        "bpm": 124,
        "key_estimate": "minor",
        "loudness_relative_to_voice_db": -6,
        "drops": [
          {"ts": 8.2, "intensity": "high", "context": "hook payoff"},
          {"ts": 32.5, "intensity": "max", "context": "twist reveal"}
        ],
        "ducking_detected": true
      },
      "sfx": [
        {"ts": 2.1, "type": "whoosh", "context": "transition_to_scene_2"},
        {"ts": 4.5, "type": "ding", "context": "text_pop_in"},
        {"ts": 18.0, "type": "glitch", "context": "twist_intro"}
      ],
      "sfx_per_minute": 4.5
    }
  ],
  "common_pattern": {
    "voice_mode": "ai_elevenlabs (3/3 outliers)",
    "voice_mood": "dramatic-narration (2/3)",
    "music_genre": "tense-cinematic-build (3/3)",
    "music_drops_per_minute": 1.5,
    "sfx_density": "high (4-6 per minute)",
    "recommended_voice_id_match": "ErXwobaYiN016d6Wd6Y8 (Antoni — closest to outlier voices)"
  }
}
```

### Stage 4 — Thumbnail analysis (NEW)

For each outlier thumbnail (already downloaded via yt-dlp `--write-thumbnail`):

**4a. Vision analysis** (use Claude vision via Read):
- Face present? Emotion? (shocked / excited / scared / neutral)
- Text overlay? Word count? Position? Color? Font weight?
- Color contrast level (high/medium/low — measure histogram spread)
- Dominant colors (extract via ffmpeg palette or PIL)
- Subject prominence (subject covers % of frame)
- Visual effects (arrows, circles, glow, split-screen?)

**4b. Cross-reference**

Output `thumbnail-analysis.json`:
```json
{
  "per_outlier": [
    {
      "url": "...",
      "thumbnail_path": "runs/<id>/outliers/1/thumbnail.jpg",
      "face": {"present": true, "emotion": "shocked", "subject_pct": 35},
      "text": {"present": true, "word_count": 4, "position": "top-center", "color": "#FFD700", "stroke": "#000000"},
      "colors_dominant": ["#FF4757", "#000000", "#FFD700"],
      "contrast_level": "high",
      "effects": ["red_arrow_overlay", "glow_around_face"]
    }
  ],
  "common_pattern": {
    "face_present_count": 3,
    "face_emotion_dominant": "shocked",
    "text_position_dominant": "top-center",
    "text_word_count_avg": 4.3,
    "color_palette_shared": ["#FF4757", "#000000", "#FFD700"],
    "effects_recurring": ["red_arrow_overlay"]
  },
  "pattern_label_suggestion": "face-shock-yellow-text-red-arrow"
}
```

### Stage 5 — Visual signature (NEW)

For each outlier video, sample frames every 5 sec via `/watch` and analyze:
- Visual format (cartoon? photoreal? screenshot-based? UI overlay?)
- Background type (solid / gradient / gameplay / real footage / AI gen)
- UI elements (iPhone? Reddit? News ticker?)
- Animation type (smooth pan / hard cuts / scroll / zoom)
- Camera moves
- Color grading

Output `visual-signature.json` (used by creative-director to derive style_signature):
```json
{
  "per_outlier": [
    {
      "url": "...",
      "format_estimate": "stock-footage-narration",
      "background_dominant": "real-archive-footage",
      "ui_elements": [],
      "animation_type": "ken-burns-slow",
      "color_grade": "warm-vintage",
      "key_techniques": [
        "Sepia color grade",
        "Ken Burns zoom on stills",
        "Text overlay top-center yellow",
        "Cuts on music drops"
      ]
    }
  ],
  "common_visual_techniques": [
    "Sepia/warm grade (3/3)",
    "Stills + Ken Burns (3/3)",
    "Yellow-text overlay (3/3)",
    "Music-synced cuts (2/3)"
  ]
}
```

### Stage 6 — Master output

Insert into SQLite `niches.formula_json` AND write to filesystem:
- `runs/<id>/outliers/formula.json`
- `runs/<id>/outliers/audio-fingerprint.json`
- `runs/<id>/outliers/thumbnail-analysis.json`
- `runs/<id>/outliers/visual-signature.json`

Update `stage_events` with key insights.

## Tools used

- `$WS/bin/yt-dlp` — download video + subs + thumbnail
- `$WS/bin/ffmpeg` / `ffprobe` — audio extraction, BPM, voice detection
- `/watch` skill — visual frame analysis
- Claude vision (Read PNG/JPG) — thumbnail + visual signature
- Optional: `librosa` Python lib for accurate BPM (`pip install --user librosa`)
- Optional: `demucs` for stem separation (`pip install --user demucs`) — heavier

## Constraints

- Max 30 min per niche analysis (with 5 outliers)
- File size: 360p downloads to keep under 25MB per video
- Skip outliers > 3 min if format = shorts (waste of bandwidth)

## When invoked

- Once per niche after `niche-radar` identifies the outliers
- Before `creative-director` (creative-director needs all 4 output files)

## Files read

- SQLite `niches` table (outlier URLs)
- Network: YouTube via yt-dlp

## Files written

- `runs/<id>/outliers/<n>/{video.mp4, subs.en.vtt, thumbnail.jpg, info.json}`
- `runs/<id>/outliers/formula.json`
- `runs/<id>/outliers/audio-fingerprint.json`
- `runs/<id>/outliers/thumbnail-analysis.json`
- `runs/<id>/outliers/visual-signature.json`
- SQLite `niches.formula_json` (compact summary)

## Cost

- ~0.30 EUR per niche (Claude analysis + /watch on 3-5 outliers)
- 0 EUR yt-dlp/ffmpeg (free + local)