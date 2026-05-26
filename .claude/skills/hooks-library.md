---
name: hooks-library
description: Reference library of proven viral hook templates for YouTube Shorts (and adaptable to long-form). Used by script-smith when generating the first 3 seconds of a Short.
type: knowledge
isolation: project
---

# hooks-library

## The 3-second rule

YouTube Shorts retention curve drops ~30% in the first 3 seconds if the hook fails. The hook IS the only thing that matters for impressions.

## 12 proven hook templates (2026)

### 1. **Problem statement + visual proof**
> "I have a problem on this channel, a big one"
> *Visual: stats/dashboard showing the problem*

Best for: meta-content (about YouTube/business), educational
Conversion: visual must immediately prove the problem
Reference: Jack Craig V1

### 2. **Bold claim + escalation**
> "This made me $45,000 in 30 days WITHOUT showing my face"
> *Visual: dashboard with money figure*

Best for: business, finance, get-rich-quick adjacent
Risk: TOS-grey if too aggressive
Reference: Chris Barrera V2

### 3. **Curiosity gap**
> "You won't believe what happened next..."
> *Visual: dramatic setup shot*

Best for: storytelling, bizarre history, news reactions
Avoid: too clickbaity will drop retention mid-video

### 4. **Pattern interrupt (visual shock)**
> "Wait... is that real?"
> *Visual: visually surprising frame (zoom on something weird)*

Best for: science, paranormal, mystery
Critical: the visual must actually be surprising — no false promise

### 5. **Question + immediate stakes**
> "What if I told you 90% of [common belief] is wrong?"
> *Visual: text overlay with the statistic*

Best for: educational, debunking, counterintuitive content
Effective when the answer pays off in <30s

### 6. **Time-bound challenge**
> "I built a YouTube channel in 24 hours"
> *Visual: timer or clock overlay*

Best for: tutorials, experiments, challenges
Audience: aspiring creators / learners

### 7. **Cold open (mid-scene)**
> *Open mid-action with no setup, then "...how did we get here?"*

Best for: storytelling, narrative-driven content
Risk: requires strong middle to retain after the cold open

### 8. **Stat punch**
> "Only 0.01% of YouTubers know this"
> *Visual: comparison chart*

Best for: educational, tutorial
Note: must back up the stat in the video

### 9. **Personal stake**
> "I lost $50k testing this so you don't have to"
> *Visual: red bank balance graph*

Best for: finance, lessons learned, experiments
Authenticity matters — must be true or feel true

### 10. **Conspiracy / reveal**
> "This is what they don't want you to see"
> *Visual: blurred/redacted footage*

Best for: news, conspiracy, history, mystery
TOS-careful: don't actually spread misinformation

### 11. **Before/after split**
> *Visual: split screen with dramatic before/after, no narration first 1s*

Best for: transformations, tutorials, fitness, design
Highly visual, low narration in first second

### 12. **Confession**
> "I've been lying to you about [X]"
> *Visual: serious face cam or text overlay*

Best for: rebuilds trust, authenticity-driven channels
Use sparingly — channels that overuse get tagged as manipulative

## Hook engineering rules

| Rule | Why |
|---|---|
| ≤ 12 words spoken in first 3 sec | Keeps cognitive load low |
| Big text overlay during hook (3-5 words) | For sound-off viewers (70%+ of Shorts watched silent) |
| First visual must be VIVID (no slow fade-in) | YouTube algorithm reads first-frame thumbnail-like |
| End the hook with a payoff PROMISE | "I'll show you how..." / "Watch what happens..." |
| Sync the hook end with a music drop or SFX hit | Audio cue locks in the viewer |

## Picking a hook for a script

1. Read the niche's `formula.json` from viral-decoder
2. Identify which of the 12 templates the outliers used (often 1-3 dominate per niche)
3. Pick from those dominant templates for the new script
4. Vary the WORDING but keep the STRUCTURE

Example for `forgotten-history` niche:
- Outliers used templates #3 (curiosity gap), #4 (pattern interrupt visual), #10 (reveal)
- New script picks template #4 with different content:
  - "Wait... is that real?" → "Wait until you hear what they did to..."
  - Visual: dramatic Higgsfield generated scene of the historical event

## Bad hooks to avoid

- "Hey guys, today we're talking about..." (announcement)
- "In this video..." (meta-narration)
- "So basically..." (filler opener)
- Any hook that starts with the narrator's name/channel
- Asking permission ("Did you know that...")
- Slow build-up (no payoff in first 5s)

## Hook variants for testing

For each video, generate 3 hook variants (script-smith does this):
- Variant A: dominant template from the niche
- Variant B: adjacent template (slightly different)
- Variant C: contrarian (different template, riskier)

A/B test via thumbnail experimentation in YT Studio.
