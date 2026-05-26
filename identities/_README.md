# Identities — isolation per-owner + per-channel

Two-level identity model for the yt-channel pipeline.

## Level 1 — Owner (who runs the system)

A single owner = one human (or team) operating the pipeline. Owner-scoped state:

- Higgsfield account (CLI auth lives at `~/.config/higgsfield/auth.json`, ONE per machine — switch by re-running `higgsfield auth login`)
- Anthropic / Claude Code auth
- mem0 user_id (for cross-channel learnings)

Stored at `config/owner.json`. For Nolann: `owner_id: nolann`.

If multiple humans share this codebase (rare), copy `config/owner.json` per person and run via `OWNER_ID=<id> openclaw run yt-channel-orchestrator`.

## Level 2 — Channel (where content goes)

One channel = one YouTube channel = one isolated identity bubble. Each channel has:

- Own camoufox profile (cookies, login state for YT + Higgsfield)
- Own brand.json (colors, fonts, voice tone)
- Own niche specialization
- Own mem0 sub-namespace
- Own upload history + analytics

Layout:

```
identities/
├── _README.md              this file
├── _channels.json          machine-readable registry (auto-maintained)
└── channels/
    └── <slug>/             one folder per channel
        ├── channel.json    metadata (YT channel ID, niche, status, branding ref)
        ├── brand.json      override of project-default brand-default.json
        ├── camoufox/       camoufox profile snapshot (cookies, session)
        │   └── .gitkeep    placeholder; real cookies live in camoufox storage
        └── uploads/        log of uploads (one .json per video)
```

## Camoufox profile naming convention

| Profile name | Purpose | Logged into |
|---|---|---|
| `yt-channel-owner-<owner_id>` | Higgsfield UI browsing (fallback if MCP/CLI fails) | Higgsfield gmail |
| `yt-channel-channel-<slug>` | YouTube Studio for one specific channel | only that YT channel |
| `yt-channel-research` | Anonymous research (niche-radar, viral-decoder) | nothing — logged-out browsing |

**Hard rule**: never share profiles between channels. Cross-contamination of cookies = ban risk.

## Creating a new channel

```bash
# 1. Create the channel folder + scaffold
CHANNEL=my-new-niche
mkdir -p identities/channels/$CHANNEL/{camoufox,uploads}

# 2. Create channel.json (copy template below + edit)
cat > identities/channels/$CHANNEL/channel.json <<EOF
{
  "slug": "$CHANNEL",
  "name": "My New Niche",
  "owner_id": "nolann",
  "youtube_channel_id": "",
  "youtube_channel_url": "",
  "niche_slug": "$CHANNEL",
  "status": "draft",
  "camoufox_profile": "yt-channel-channel-$CHANNEL",
  "brand_anchor": "identities/channels/$CHANNEL/brand.json",
  "mem0_namespace": "yt-channel.$CHANNEL"
}
EOF

# 3. Copy default brand.json (optionally override)
cp config/brand-default.json identities/channels/$CHANNEL/brand.json

# 4. Register in _channels.json (or let the agent auto-discover)
python3 -c "import json; d=json.load(open('identities/_channels.json')); d['channels'].append('$CHANNEL'); json.dump(d, open('identities/_channels.json','w'), indent=2)"

# 5. Setup camoufox profile (manual, 5 min):
#    Open camoufox with profile yt-channel-channel-$CHANNEL
#    Login to YouTube as that channel
#    Close cleanly — cookies persist
```

## Session isolation (OpenClaw)

The `yt-channel-orchestrator` agent has ONE `sessions/` directory under `.openclaw/yt-channel/agents/yt-channel-orchestrator/sessions/`. All channels share this orchestrator.

When a run targets a specific channel, the orchestrator:
1. Reads `--channel <slug>` from the request (or defaults to the only active channel)
2. Loads `identities/channels/<slug>/channel.json` + `brand.json`
3. Passes the channel context to ALL downstream skills (asset-summoner uses the brand, uploader uses the camoufox profile, sentry namespaces metrics)
4. Logs the channel slug in every `stage_events.payload`

Sessions stay shared (one orchestrator brain) but artifacts are scoped per channel:
- `runs/<id>/` directories include `channel.json` snapshot
- SQLite `runs` table will gain a `channel_slug` column (TODO)

## Multi-channel workflow

```bash
# List channels
openclaw send yt-channel-orchestrator "list channels"

# Run for a specific channel
openclaw send yt-channel-orchestrator "lance un short pour le canal anime-reactions"

# Add a new channel
openclaw send yt-channel-orchestrator "cree le canal bodycam-policer avec niche police-bodycam"

# Channel-scoped stats
openclaw send yt-channel-orchestrator "stats du canal anime-reactions"
```

## What gets shared vs isolated

| Resource | Shared (owner-level) | Isolated (channel-level) |
|---|---|---|
| Higgsfield account | ✅ | ❌ (one Higgsfield for all channels) |
| Higgsfield credits budget | ✅ | tracked per channel via cost_eur |
| Claude API auth | ✅ | ❌ |
| Camoufox profile | ❌ | ✅ per channel (cookies, YT login) |
| Brand style | template default | overridable per channel |
| mem0 memory | nolann user_id | namespaced sub-keys (yt-channel.\<slug\>) |
| Niche knowledge | sometimes cross-channel | mostly per channel |
| OpenClaw agent sessions | ✅ | tagged with channel in payload |
| SQLite DB | ✅ (`channel_slug` column) | rows isolated by channel |
| `runs/` artifacts | filesystem shared | per-run dirs include channel info |

## See also

- `config/owner.json` — owner-level config
- `identities/channels/anime-reactions/channel.json` — example channel
- `.openclaw/yt-channel/agents/yt-channel-orchestrator/agent/prompts/system.md` — orchestrator reads identities at run start
