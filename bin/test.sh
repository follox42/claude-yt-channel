#!/usr/bin/env bash
# claude-yt-channel — verify the install
# Exits 0 if everything works, 1 if any check fails.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

ok() { echo -e "  \033[32m✓\033[0m $*"; }
fail() { echo -e "  \033[31m✗\033[0m $*"; FAILS=$((FAILS+1)); }
warn() { echo -e "  \033[33m⚠\033[0m $*"; WARNS=$((WARNS+1)); }

FAILS=0; WARNS=0

echo
echo "════════════════════════════════════════════════════"
echo "  claude-yt-channel — install verification"
echo "════════════════════════════════════════════════════"
echo

if [ ! -f .initialized ]; then
  fail "Project not initialized — run \`bash bin/init.sh\` first"
  exit 1
fi
OWNER_ID="$(python3 -c "import json; print(json.load(open('config/owner.json'))['owner_id'])" 2>/dev/null)"
WS_NAME="${OPENCLAW_WS:-yt-channel}"
WS_DIR="$HOME/.openclaw/$WS_NAME"

echo "Owner:        $OWNER_ID"
echo "Workspace:    $WS_DIR"
echo

# 1. Binaries
echo "1) Binaries"
for bin in python3 node npm npx ffmpeg ffprobe yt-dlp higgsfield; do
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$bin on PATH"
  elif [ -x "$WS_DIR/bin/$bin" ]; then
    ok "$bin in workspace bin/"
  else
    fail "$bin missing — run \`bash bin/prereqs.sh\`"
  fi
done

# 2. Higgsfield auth
echo
echo "2) Higgsfield auth"
if higgsfield account status 2>&1 | grep -q "@"; then
  ok "$(higgsfield account status 2>&1 | head -1)"
else
  warn "Not authenticated — run \`higgsfield auth login\`"
fi

# 3. SQLite DB
echo
echo "3) Database"
if [ -f data/runs.db ]; then
  TABLES="$(python3 -c "
import sqlite3
c = sqlite3.connect('data/runs.db')
tables = [r[0] for r in c.execute(\"SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name\")]
print(','.join(tables))
")"
  EXPECTED="ideas,metrics,niches,runs,stage_events,uploads"
  if [ "$TABLES" = "$EXPECTED" ]; then
    ok "data/runs.db (6 tables)"
    HAS_CHANNEL="$(python3 -c "
import sqlite3
c = sqlite3.connect('data/runs.db')
cols = [r[1] for r in c.execute('PRAGMA table_info(runs)')]
print('yes' if 'channel_slug' in cols else 'no')
")"
    [ "$HAS_CHANNEL" = "yes" ] && ok "channel_slug column present (migration 001)" || fail "channel_slug missing"
  else
    fail "Schema mismatch. Got: $TABLES"
  fi
else
  fail "data/runs.db not found"
fi

# 4. Workspace
echo
echo "4) OpenClaw workspace"
if [ -d "$WS_DIR" ]; then
  ok "Workspace: $WS_DIR"
  for f in BOOTSTRAP.md IDENTITY.md USER.md SOUL.md AGENTS.md TOOLS.md; do
    [ -f "$WS_DIR/$f" ] && ok "  $f" || warn "  $f missing"
  done
  N_SKILLS="$(ls "$WS_DIR/.openclaw/skills/" 2>/dev/null | wc -l)"
  [ "$N_SKILLS" -ge 9 ] && ok "  $N_SKILLS skills materialized" || fail "  only $N_SKILLS skills (expected ≥9)"
  PERMS="$(stat -c "%a" "$WS_DIR/.openclaw" 2>/dev/null || stat -f "%Lp" "$WS_DIR/.openclaw" 2>/dev/null)"
  [ "$PERMS" = "755" ] || [ "$PERMS" = "775" ] && ok "  .openclaw perms: $PERMS" || fail "  .openclaw perms: $PERMS (need 755)"
  N_BINS="$(ls "$WS_DIR/bin/" 2>/dev/null | wc -l)"
  [ "$N_BINS" -ge 4 ] && ok "  $N_BINS binaries in workspace" || warn "  only $N_BINS binaries"
  [ -f "$WS_DIR/.config/higgsfield/credentials.json" ] && ok "  HF creds in workspace" || warn "  HF creds NOT in workspace"
else
  fail "Workspace not deployed: $WS_DIR"
fi

# 5. Plugin
echo
echo "5) OpenClaw plugin"
if npx --yes openclaw@latest plugins list 2>/dev/null | grep -qE "yt-channel|yt-viral"; then
  ok "Plugin installed"
else
  warn "Plugin NOT installed — \`openclaw plugins install --link --dangerously-force-unsafe-install ./plugin\`"
fi

# 6. Agent registration
echo
echo "6) Agent registration"
OC_JSON="$HOME/.openclaw/openclaw.json"
if [ -f "$OC_JSON" ]; then
  AGENT_ID="${WS_NAME}-orchestrator"
  IDS="$(python3 -c "import json; print(','.join(a['id'] for a in json.load(open('$OC_JSON'))['agents']['list']))" 2>/dev/null || echo "")"
  echo "$IDS" | grep -q "$AGENT_ID" && ok "$AGENT_ID registered" || warn "$AGENT_ID not in openclaw.json"
else
  warn "openclaw.json not found"
fi

echo
echo "════════════════════════════════════════════════════"
if [ $FAILS -eq 0 ] && [ $WARNS -eq 0 ]; then
  echo "  ✓ All checks passed. Ready to talk to the agent."
elif [ $FAILS -eq 0 ]; then
  echo "  ✓ Core OK ($WARNS warnings — non-blocking)"
else
  echo "  ✗ $FAILS failures, $WARNS warnings"
fi
echo "════════════════════════════════════════════════════"
exit $FAILS
