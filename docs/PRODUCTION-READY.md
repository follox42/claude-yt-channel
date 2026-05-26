# PRODUCTION-READY checklist

What's needed to produce a real viral Short end-to-end, organized by deployment level.

## Level 0 — Bare minimum (0 EUR/month, ~3 Shorts max)

Status: shipped with the template. Just clone, init, go.

| Component | Provided | Notes |
|---|---|---|
| Skills (15) | ✅ | All pipeline stages |
| Remotion compositions | ✅ | `<TextOverlayShort>` covers basic Shorts |
| SQLite schema | ✅ | + channel_slug migration |
| OpenClaw workspace files | ✅ | BOOTSTRAP/IDENTITY/USER/SOUL/AGENTS/TOOLS |
| Onboarding wizard | ✅ | 9-step guided flow |
| Static binaries | ✅ via `bin/prereqs.sh` | ffmpeg, yt-dlp, higgsfield CLI |
| Higgsfield credits | 🟡 10 free / month | ~3 Shorts before running out |
| Stock fallback | 🟡 Pexels free key | Get from pexels.com/api |
| Voice | 🚫 text-overlay-only | No voice gen needed |
| Music | 🚫 silent or stock | Optional |

**Limitations**: only `text-overlay-only` voice mode. Only style_signatures that don't need ElevenLabs / Suno / custom Remotion components.

**To start**:
```bash
git clone https://github.com/follox42/claude-yt-channel.git my-channel
cd my-channel
bash bin/prereqs.sh
higgsfield auth login
bash bin/init.sh
bash bin/test.sh         # all green?

# Get Pexels key (free): https://www.pexels.com/api/new/
echo "PEXELS_API_KEY=xxxxxxxxxxxxx" >> config/.env

openclaw plugins install --link --dangerously-force-unsafe-install ./plugin
openclaw run yt-channel-orchestrator
```

---

## Level 1 — Hobby (~20 EUR/month, ~10 Shorts with voice)

Add ElevenLabs voice + Higgsfield Premium.

| Component | Add | Cost |
|---|---|---|
| Higgsfield Premium | ~500 credits/mo | $15/mo |
| ElevenLabs Starter | 30k chars/mo | $5/mo |
| Pexels/Pixabay | free | 0 |

```bash
# Sign up + get keys
echo "ELEVENLABS_API_KEY=sk_xxx" >> config/.env
echo "PIXABAY_API_KEY=xxx" >> config/.env

# Upgrade Higgsfield via web at higgsfield.ai/pricing
```

Unlocked style_signatures: `cartoon-flat`, `retro-vhs-cinematic-with-narrator`, `photoreal-documentary`, `stock-footage-narration`.

---

## Level 2 — Pro (~50 EUR/month, ~30 Shorts with custom music)

Add Suno AI music + ElevenLabs Creator.

| Component | Add | Cost |
|---|---|---|
| Higgsfield Premium | ~500 credits/mo | $15/mo |
| ElevenLabs Creator | 100k chars/mo | $22/mo |
| Suno Pro | unlimited gens | $10/mo |

Unlocked: `subway-surfers-overlay`, `pixar-3d-storytime`, `ai-news-anchor-broll`.

---

## Level 3 — Multi-channel automation (~150 EUR/month, scaled production)

Add Epidemic Sound (commercial music licensing) + multiple Higgsfield slots + camoufox profiles per channel.

| Component | Add | Cost |
|---|---|---|
| Higgsfield Premium x3 channels | ~1500 credits/mo | $45/mo |
| ElevenLabs Pro | 500k chars/mo | $99/mo |
| Suno Pro | unlimited | $10/mo |
| Epidemic Sound (optional commercial) | unlimited library | $15/mo |

---

## What's still NOT built (roadmap)

The template covers ~85% of a viral pipeline. These items are designed but need code to materialize:

### Remotion components (per style_signature)
- ✅ `<TextOverlayShort>` — generic text-on-video Short (shipped)
- ✅ `<IPhoneMessagesUI>` — for reddit-stories style (shipped, basic)
- 🚧 `<SubwaySurfersLayer>` — gameplay loop overlay
- 🚧 `<RedditPostScroll>` — dark-mode UI with auto-scroll
- 🚧 `<AINewsAnchor>` — talking head + B-roll layout
- 🚧 `<SplitScreenReaction>` — face cam + content split
- 🚧 `<WhiteboardTimelapse>` — hand-drawn timelapse
- 🚧 `<PixarStorytime>` — 3D cartoon storybook style
- 🚧 `<ScreenshotTweetZoom>` — tweet card + Ken Burns
- 🚧 `<ThumbnailFactory>` — for thumb-craft to render variants

→ These get built **on demand** when `creative-director` produces a `complexity_score` ≥ 4 OR when a niche's outliers use a style we don't have a component for. Build via `gsd:plan-phase` or directly when needed.

### Phase 2 — YouTube Data API upload
The current `uploader` skill uses camoufox UI automation. Cleaner long-term:
- Setup YT Data API v3 + OAuth flow (`bin/yt-oauth.sh` to add)
- Get refresh token + scopes (youtube.upload + youtube.readonly)
- Add to .env: `YOUTUBE_CLIENT_ID`, `YOUTUBE_CLIENT_SECRET`, `YOUTUBE_REFRESH_TOKEN`
- Update uploader to detect API mode vs camoufox mode

### Phase 3 — Multi-channel orchestration
- The orchestrator currently handles 1 channel per run. For parallel multi-channel:
  - Update orchestrator.py to accept `--channels <slug1,slug2,...>`
  - Use process pool to run pipeline per channel concurrently
  - Aggregate budget tracking across channels
  - Dashboard shows per-channel stats

### Phase 4 — Feedback loop (sentry → idea-forge)
- `sentry` writes feedback.json per run (winning patterns / losing patterns)
- `idea-forge` reads recent sentry feedback at run start
- Bias future ideas toward winners (max 50% bias to keep variety)
- Requires: at least 5 uploads with metrics captured

### Phase 5 — Quality gate (review-gate)
- After `render-engine`, run a quality review skill
- Score on: hook strength, retention prediction, brand consistency, TOS-safety
- Block publish if score < threshold (user-configurable)

---

## Right NOW — exactly what's missing for YOUR first viral video

Assuming you've just cloned:

### Mandatory (10 min setup)
1. ✅ Run `bash bin/prereqs.sh` → installs binaries
2. ✅ Run `higgsfield auth login` → OAuth (popup)
3. ✅ Run `bash bin/init.sh` → wizard fills owner.json + workspace
4. ✅ Sign up Pexels (free), add `PEXELS_API_KEY` to `config/.env`

### Recommended (5 min more)
5. Sign up Pixabay (free), add `PIXABAY_API_KEY` 
6. Upgrade Higgsfield to Premium ($15/mo) if you want > 3 Shorts

### Optional (depends on style)
7. ElevenLabs Starter ($5/mo) if your creative-bible.voice.mode = "elevenlabs-ai"
8. Suno Pro ($10/mo) if your creative-bible.music.mode = "ai-generated-suno"

### After all setup
9. `openclaw plugins install --link --dangerously-force-unsafe-install ./plugin`
10. `openclaw run yt-channel-orchestrator` → wizard launches automatically
11. Wizard does: niche-radar → niche-pick → naming → creative-director → character-forge (optional) → competitor-study → YT account create → camoufox profile → validation
12. Then: `lance un short pour mon canal`
13. Pipeline runs: niche-radar → viral-decoder → idea-forge → script-smith → asset-summoner + voice-actor + music-composer (parallel) → render-engine → thumb-craft → STOP (mvp mode)
14. Review `runs/<id>/final.mp4` + 3 thumbnails
15. Manual upload to YT or proceed to Phase 2

Total time first video: ~30-45 min from cold clone (mostly waiting for renders + Higgsfield gens).
Total cost first video: ~0.50 EUR (Higgsfield credits ~6 + Claude tokens ~0.20 EUR).

---

## Test command (works at any level)

```bash
bash bin/test.sh
```

Output tells you exactly what's missing for the level you want to operate at.
