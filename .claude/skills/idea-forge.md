---
name: idea-forge
description: Generate 10-30 short video ideas matching a decoded niche formula. Use after viral-decoder has populated niches.formula_json.
type: agent
isolation: claude-yt-channel
---

# idea-forge

> Isolated workspace agent. Inspired by `content-ideator` but rewritten for short-form viral mechanics.

## Mission

Produce a ranked pool of short video ideas that fit the niche's decoded formula but have a unique angle each (per Chris Barrera's "always have a unique twist" rule).

## Inputs

- `niche_slug` (required)
- `count` (default `20`): ideas to generate
- `feedback_loop` (optional): performance data from `sentry` to bias toward what worked

## Process

1. Read `niches.formula_json` for the target niche.
2. Read the 3 outlier examples for inspiration anchors.
3. Brainstorm ~30-50 raw ideas using Claude (sonnet) with the formula as constraint:
   - Each idea = `{title, hook, angle, beat_assignment}`
   - Hook must be specific (no "Look at this cop", instead "Cop pulls over himself by mistake")
   - Angle must differ from the 3 reference outliers (different incident, character, twist)
4. Score each idea 0-100 on:
   - **Hook strength** (0-30): specificity, surprise, curiosity gap
   - **Replicability** (0-25): can we produce the visuals with available tools (Higgsfield + Remotion)?
   - **Differentiation** (0-25): how unique vs the references
   - **Format fit** (0-20): aligns with beat template
5. Keep top `count` ideas. Insert into `ideas` table with `status='queued'`.

## Output

JSON array AND inserted rows:
```json
[
  {
    "title": "Officer pulls over his own brother (he didn't know)",
    "hook": "Bodycam: cop walks up to driver, drops the citation, hugs him",
    "angle": "family relation reveal during routine stop",
    "score": 87,
    "beat_assignment": {
      "0-5": "stop initiation, attitude tense",
      "5-15": "cop approaches, sees face",
      "15-30": "recognition, mood shift",
      "30-45": "emotional resolution",
      "45-60": "text overlay: 'small world'"
    }
  }
]
```

## Constraints

- Use Claude API direct (no skill chain to upstream `content-ideator`)
- Each idea must reference a SPECIFIC beat assignment
- Reject ideas requiring footage we can't produce (no real cops, no copyrighted clips)
- For bodycam/police niches: pivot to staged/animated reenactments (Higgsfield can do)
- Cost cap: 0.5 EUR per run (~50k tokens Sonnet)

## Files

- Reads: SQLite `niches`, optionally `metrics`
- Writes: SQLite `ideas`, `runs/<id>/ideas.json`