# Learnings 2026-05-27 — Jacksons AI + WOLF Money breakdowns

Analysed 2 viral tutorials to extract production patterns + integrate into template.

## Sources

| Video | Channel | Views | Format | Key insight |
|---|---|---|---|---|
| [FREE & UNLIMITED \| How I Make VIRAL 3D Documentary Videos 100% With AI](https://www.youtube.com/watch?v=--w3Rumz9sM) | Jacksons AI (38.8k) | 85k | 34min tutorial | Full faceless pipeline with ZERO paid tools |
| [$0 - $1,000/Day On A Secret YouTube Channel](https://www.youtube.com/watch?v=BePppCvXC-k) | WOLF Money (11.5k) | 555k | 10min vlog | Outlier mining + 100x effort + mythbusting format |

## Big takeaway #1 — Meta AI + Google Flow = unlimited free gen

Both image AND video, completely free, no credit budget, just login.

| Tool | Capability | Cost | Auth |
|---|---|---|---|
| **Meta AI** (meta.ai) | Unlimited images + videos | $0 | Login: Google / IG / Facebook |
| **Google Flow** | Nano Banana model unlimited images, Seedance 15s video | $0 | Google login |

**Implication for our pipeline**:
- Higgsfield is NICE but not REQUIRED for MVP
- asset-summoner should add Meta AI + Google Flow as Tier 0 (zero-cost) fallbacks
- Higgsfield Premium ($15/mo) becomes optional quality upgrade, not blocker

## Big takeaway #2 — Multi-shot chapter prompting

Instead of generating individual scenes, generate **chapter prompts** that produce multi-shot sequences in a single output.

```
Standard approach (our current):
  Scene 1 (5s) → 1 image + 1 image-to-video
  Scene 2 (5s) → 1 image + 1 image-to-video
  ...
  Result: 8-12 separate Higgsfield gens

Chapter approach (Jacksons):
  Chapter 1 (15s, multi-shot) = "city street night, slow zoom, cut to gym, cut to laptop" → ONE gen
  Chapter 2 (15s, multi-shot) = "...next sequence" → ONE gen
  Result: 4-6 Higgsfield gens for a 60s Short
```

**Models that support multi-shot**: Seedance 2.0 (15s limit), VO3 (8s limit), Higgsfield premium models.

**Implication**: script-smith should output 4-6 chapter prompts (not 8-12 scene prompts). asset-summoner uses fewer calls but each call is denser.

## Big takeaway #3 — ElevenLabs emotion tags

Bracket syntax in the script text directly controls voice tone:
- `[whisper] He didn't see it coming.` — whispered
- `[dramatic] But everything changed in that moment.` — dramatic emphasis
- `[laugh] You won't believe what happened next.` — laughter
- `[music]` — music swell hint

V3 model parses these and adjusts delivery. Generate in **small batches** (1 chunk at a time) for quality — full-script generation degrades.

**Implication**:
- script-smith outputs voiceover text with `[emotion]` tags
- voice-actor parses tags + generates ElevenLabs API call per chunk

## Big takeaway #4 — YouTube Audio Library

Free music library accessible inside YouTube Studio. Filter by genre + mood:
- Genre: Cinematic / Hip Hop / Pop / etc.
- Mood: Dramatic / Calm / Inspirational / Funky

No API needed — just download the MP3, attribution-free. Examples used by Jacksons:
- Never Don't Stop / Yacoby / Moon Vision / The Road To Mordor / The Marble Cinematic University

**Implication**: music-composer adds YT Audio Library as Tier 0 source (key-free). Pre-curated library by genre × mood combos.

## Big takeaway #5 — Outlier mining + 100x effort

WOLF Money's strategy that took a new channel to $1k/day in 5 videos:
1. Pick a niche with **active outliers** (videos pulling 100x channel avg)
2. Identify what makes them work (format, hook, length, thumbnail)
3. **Do the same thing but 100x better** (more research, longer, higher production)
4. Specifically: **mythbusting format** = "X is true vs X is myth" with visual proof

His specific moves:
- Channel: Roblox 99 Nights in the Forest gameplay
- Insight: everyone doing daily uploads, nobody doing high-effort
- Video 3 viral concept: mythbusting (cross-niche pattern)
- Video 4: video 3 "on steroids" — 600k views in 2 days, 34min long
- 5 videos = $1k/day, $21k in 30 days

**Implication**:
- niche-radar should weight outliers by `views / median_channel_views` (outlier score)
- idea-forge should bias toward mythbusting templates when applicable
- script-smith long-form mode should target longer durations (15-30min for high-RPM niches)

## Big takeaway #6 — Faceless 3D mannequin documentary as recognized style

Channel "Fern" pulls 20M views/month with this exact format.

**Visual signature**:
- 3D rendered mannequin characters (no face, smooth heads)
- Red/blue/grey suit-wearing mannequins
- Cinematic dark scenes
- White or coloured Impact font text overlays
- Dramatic narration ElevenLabs
- Background: cinematic music + ambient sound

**Reproducible because**:
- Higgsfield + Nano Banana + Seedance all handle mannequin style
- Reference image for consistency (suit + mannequin head)
- Story content from history / current events / mysteries

**Implication**: add `3d-mannequin-documentary` to style_signature examples + ship a Higgsfield-ready prompt template.

## Integration plan (updates to push)

### 1. asset-summoner — add Meta AI + Google Flow Tier 0
Routing priority:
```
0. Meta AI (free, unlimited, Google login required once via cookies)
0. Google Flow / Nano Banana (free, unlimited, Google login)
1. Higgsfield generic (paid — saves credits)
1. Higgsfield Soul ID (paid — character consistency)
2. footage-hunter (stock fallback)
```

### 2. script-smith — chapter-based output + emotion tags
Instead of `scenes[]` array of 8-12 items, output `chapters[]` array of 4-6 items, each with:
- duration_sec (5-15s)
- voiceover (with [emotion] tags)
- multi_shot_prompt (describes the multi-shot sequence)
- text_overlays (per beat)

### 3. voice-actor — emotion tag parsing + batched gen
Parse `[emotion]` tags from voiceover text. Generate per-chunk (one chunk = one chapter or one beat). Save per-chapter mp3.

### 4. music-composer — YouTube Audio Library as Tier 0
Pre-curated track list per (genre × mood) combo. Skip Pixabay if YT Audio Library has a match.

### 5. hooks-library — add "outlier mythbusting" archetype
13th template: pick a popular belief in the niche, set up the myth, then visual-proof bust it.

### 6. creative-bible examples — add `3d-mannequin-documentary`
With Higgsfield prompt template + Soul ID reference image spec.

## Status

- ✅ Documented learnings in this file
- ⏳ Push integration updates to template (next)
- ⏳ Sync to live workspace
