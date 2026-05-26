#!/usr/bin/env bash
# claude-yt-channel — first-run setup wizard
# Replaces __REPLACE_ME__ placeholders with your identity, sets up dirs, inits DB.

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo
echo "=================================================="
echo "  claude-yt-channel — first-run setup wizard"
echo "=================================================="
echo

# Check if already initialized
if [ -f ".initialized" ]; then
  echo "⚠️  This project is already initialized (.initialized exists)."
  read -p "Re-run anyway and overwrite owner.json + _channels.json? [y/N] " yn
  case $yn in
    [Yy]*) echo "OK, re-initializing.";;
    *) echo "Aborting."; exit 0;;
  esac
fi

# Detect owner_id from git or env
DEFAULT_OWNER="$(git config user.name 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/^-//;s/-$//' || echo "")"
[ -z "$DEFAULT_OWNER" ] && DEFAULT_OWNER="me"

DEFAULT_EMAIL="$(git config user.email 2>/dev/null || echo "")"

read -p "Owner ID (slug, no spaces) [$DEFAULT_OWNER]: " OWNER_ID
OWNER_ID="${OWNER_ID:-$DEFAULT_OWNER}"

read -p "Your name [$OWNER_ID]: " OWNER_NAME
OWNER_NAME="${OWNER_NAME:-$OWNER_ID}"

read -p "Your email [$DEFAULT_EMAIL]: " OWNER_EMAIL
OWNER_EMAIL="${OWNER_EMAIL:-$DEFAULT_EMAIL}"

read -p "Higgsfield account email (same as above? Enter to confirm) [$OWNER_EMAIL]: " HF_EMAIL
HF_EMAIL="${HF_EMAIL:-$OWNER_EMAIL}"

read -p "mem0 user_id (defaults to owner_id) [$OWNER_ID]: " MEM0_USER
MEM0_USER="${MEM0_USER:-$OWNER_ID}"

echo
echo "Configuring..."

# Replace placeholders in owner.json
sed -i.bak \
  -e "s|__REPLACE_ME__|$OWNER_ID|g" \
  config/owner.json
# Now overwrite owner.json with real values (the sed above was naive)
cat > config/owner.json <<EOF
{
  "owner_id": "$OWNER_ID",
  "name": "$OWNER_NAME",
  "email": "$OWNER_EMAIL",
  "higgsfield": {
    "account_email": "$HF_EMAIL",
    "auth_method": "cli",
    "credentials_path": "~/.config/higgsfield/auth.json",
    "plan": "free",
    "credit_budget_per_run": 8
  },
  "anthropic": {
    "auth_method": "claude-code",
    "_note": "Uses parent Claude Code auth — no separate API key needed."
  },
  "mem0": {
    "user_id": "$MEM0_USER",
    "mcp_server": "openmemory-$MEM0_USER"
  },
  "camoufox": {
    "_note": "Per-channel profiles isolate cookies. See identities/channels/<slug>/camoufox/.",
    "global_profile_for_higgsfield_browse": "yt-channel-os-owner-$OWNER_ID"
  }
}
EOF
rm -f config/owner.json.bak

# Update _channels.json owner_id
sed -i.bak "s|\"owner_id\": \"__REPLACE_ME__\"|\"owner_id\": \"$OWNER_ID\"|" identities/_channels.json
rm -f identities/_channels.json.bak

# Update _template-channel
sed -i.bak "s|\"owner_id\": \"nolann\"|\"owner_id\": \"$OWNER_ID\"|" identities/_template-channel/channel.json 2>/dev/null
rm -f identities/_template-channel/channel.json.bak

# Init SQLite DB if not exists
mkdir -p data runs
if [ ! -f data/runs.db ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import sqlite3
c = sqlite3.connect('data/runs.db')
with open('data/schema.sql') as f: c.executescript(f.read())
with open('data/migration-001-add-channel.sql') as f: c.executescript(f.read())
c.commit()
print('  [ok] data/runs.db initialized')
"
  else
    echo "  ⚠️  python3 not found — run bin/prereqs.sh first, then re-run this script"
  fi
else
  echo "  [skip] data/runs.db already exists"
fi

# Create .env from example
if [ ! -f config/.env ]; then
  cp config/.env.example config/.env
  echo "  [ok] config/.env created (review and fill in if needed)"
fi

# Mark initialized
touch .initialized

echo
echo "=================================================="
echo "  ✓ Initialized for owner: $OWNER_ID"
echo "=================================================="
echo
echo "Next steps:"
echo "  1. bash bin/prereqs.sh         # install Python/Node/ffmpeg/yt-dlp/higgsfield"
echo "  2. higgsfield auth login       # auth your Higgsfield account"
echo "  3. openclaw plugins install --link --dangerously-force-unsafe-install ."
echo "  4. openclaw run yt-channel-orchestrator   # start the onboarding wizard"
echo
echo "The wizard will guide you through creating your first channel."
echo
