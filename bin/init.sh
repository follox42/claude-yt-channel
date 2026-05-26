#!/usr/bin/env bash
# claude-yt-channel — robust first-run setup wizard
#
# What this does (in order):
#   1. Asks for owner_id/name/email/mem0_user
#   2. Replaces __REPLACE_ME__ placeholders in config files
#   3. Initializes SQLite DB (schema + migration)
#   4. Deploys .openclaw-agent/* into ~/.openclaw/<workspace>/
#   5. Fixes permissions on .openclaw/skills/ (drwx------ -> drwxr-xr-x)
#   6. Copies Higgsfield creds into the workspace if available
#   7. Patches openclaw.json agents.list[] to register the orchestrator
#   8. Verifies everything via bin/test.sh
#
# Idempotent — re-runnable if you cancel mid-way.

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# --- helpers -----------------------------------------------------------------
log() { echo -e "  $*"; }
ok() { echo -e "  ✓ $*"; }
warn() { echo -e "  ⚠ $*"; }
err() { echo -e "  ✗ $*" >&2; }

ask() {
  local prompt="$1" default="$2" var
  read -p "  ${prompt} [${default}]: " var
  echo "${var:-$default}"
}

# --- header ------------------------------------------------------------------
echo
echo "════════════════════════════════════════════════════"
echo "  claude-yt-channel — setup wizard"
echo "════════════════════════════════════════════════════"
echo

# Re-init guard
if [ -f ".initialized" ]; then
  warn "Project already initialized (.initialized exists)."
  if [ "${1:-}" != "--force" ]; then
    read -p "  Re-run anyway? [y/N] " yn
    [[ "$yn" =~ ^[Yy]$ ]] || { log "Aborted."; exit 0; }
  fi
fi

# --- detect defaults ---------------------------------------------------------
DEFAULT_OWNER="$(git config user.name 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/^-//;s/-$//' || true)"
[ -z "$DEFAULT_OWNER" ] && DEFAULT_OWNER="me"
DEFAULT_EMAIL="$(git config user.email 2>/dev/null || echo "")"
DEFAULT_WS_NAME="yt-channel"

# --- gather inputs -----------------------------------------------------------
echo "Step 1/8 — Identity"
echo
OWNER_ID="$(ask "Owner ID (slug, no spaces)" "$DEFAULT_OWNER")"
OWNER_NAME="$(ask "Your name" "$OWNER_ID")"
OWNER_EMAIL="$(ask "Your email" "$DEFAULT_EMAIL")"
HF_EMAIL="$(ask "Higgsfield account email" "$OWNER_EMAIL")"
MEM0_USER="$(ask "mem0 user_id" "$OWNER_ID")"
WS_NAME="$(ask "OpenClaw workspace name" "$DEFAULT_WS_NAME")"

# Compute paths
OC_HOME="${HOME}/.openclaw"
WS_DIR="${OC_HOME}/${WS_NAME}"
WS_AGENT_DIR="${WS_DIR}/agents/${WS_NAME}-orchestrator/agent"

echo
echo "Step 2/8 — Plan"
echo "  Owner ID:     ${OWNER_ID}"
echo "  Owner name:   ${OWNER_NAME}"
echo "  Owner email:  ${OWNER_EMAIL}"
echo "  HF email:     ${HF_EMAIL}"
echo "  mem0 user:    ${MEM0_USER}"
echo "  Workspace:    ${WS_DIR}"
echo

read -p "  Proceed? [Y/n] " yn
[[ "$yn" =~ ^[Nn]$ ]] && { log "Aborted."; exit 0; }

# --- step 3: replace placeholders in config ----------------------------------
echo
echo "Step 3/8 — Patching config files"
cat > config/owner.json <<EOF
{
  "owner_id": "${OWNER_ID}",
  "name": "${OWNER_NAME}",
  "email": "${OWNER_EMAIL}",
  "higgsfield": {
    "account_email": "${HF_EMAIL}",
    "auth_method": "cli",
    "credentials_path": "~/.config/higgsfield/credentials.json",
    "plan": "free",
    "credit_budget_per_run": 8
  },
  "anthropic": {
    "auth_method": "claude-code",
    "_note": "Uses parent Claude Code auth — no separate API key needed."
  },
  "mem0": {
    "user_id": "${MEM0_USER}",
    "mcp_server": "openmemory-${MEM0_USER}"
  },
  "camoufox": {
    "_note": "Per-channel profiles isolate cookies. See identities/channels/<slug>/camoufox/.",
    "global_profile_for_higgsfield_browse": "${WS_NAME}-owner-${OWNER_ID}"
  }
}
EOF
ok "config/owner.json written"

# Patch _channels.json
PY="$(command -v python3 || echo ~/.local/bin/python3)"
"$PY" - <<EOF
import json
with open('identities/_channels.json') as f: d = json.load(f)
d['owner_id'] = '${OWNER_ID}'
with open('identities/_channels.json','w') as f: json.dump(d, f, indent=2)
print("  ✓ identities/_channels.json patched")
EOF

# --- step 4: SQLite DB --------------------------------------------------------
echo
echo "Step 4/8 — SQLite DB"
mkdir -p data runs
if [ -f data/runs.db ]; then
  warn "data/runs.db already exists — skipping init"
else
  if ! command -v python3 >/dev/null 2>&1 && [ ! -x ~/.local/bin/python3 ]; then
    err "python3 not found. Run bin/prereqs.sh first then re-run this script."
    exit 1
  fi
  PY="$(command -v python3 || echo ~/.local/bin/python3)"
  "$PY" - <<EOF
import sqlite3
c = sqlite3.connect('data/runs.db')
with open('data/schema.sql') as f: c.executescript(f.read())
with open('data/migration-001-add-channel.sql') as f: c.executescript(f.read())
c.commit()
EOF
  ok "data/runs.db initialized (6 tables + channel_slug migration)"
fi

# --- step 5: deploy OpenClaw workspace ---------------------------------------
echo
echo "Step 5/8 — Deploy OpenClaw workspace at ${WS_DIR}"
mkdir -p "${WS_DIR}" "${WS_AGENT_DIR}/prompts" "${WS_DIR}/.openclaw/skills" "${WS_DIR}/bin" "${WS_DIR}/.config/higgsfield"

# Workspace root files: BOOTSTRAP, IDENTITY, USER, SOUL, AGENTS, TOOLS, HEARTBEAT
for f in BOOTSTRAP.md IDENTITY.md USER.md SOUL.md AGENTS.md TOOLS.md; do
  if [ -f ".openclaw-agent/$f" ]; then
    sed -e "s|__OWNER_NAME__|${OWNER_NAME}|g" \
        -e "s|__OWNER_EMAIL__|${OWNER_EMAIL}|g" \
        -e "s|__OWNER_ID__|${OWNER_ID}|g" \
        -e "s|\${PROJECT_ROOT}|${PROJECT_ROOT}|g" \
        ".openclaw-agent/$f" > "${WS_DIR}/$f"
    ok "${WS_DIR}/$f"
  fi
done
# HEARTBEAT.md (empty by default = no polls)
[ -f "${WS_DIR}/HEARTBEAT.md" ] || cat > "${WS_DIR}/HEARTBEAT.md" <<EOF
# HEARTBEAT.md
# Keep empty to disable periodic polls. Add tasks below if you want the agent to check things on a schedule.
EOF

# Agent prompts
for f in system.md onboarding.md; do
  if [ -f ".openclaw-agent/prompts/$f" ]; then
    sed -e "s|__OWNER_NAME__|${OWNER_NAME}|g" \
        -e "s|__OWNER_EMAIL__|${OWNER_EMAIL}|g" \
        -e "s|__OWNER_ID__|${OWNER_ID}|g" \
        -e "s|\${PROJECT_ROOT}|${PROJECT_ROOT}|g" \
        ".openclaw-agent/prompts/$f" > "${WS_AGENT_DIR}/prompts/$f"
    ok "${WS_AGENT_DIR}/prompts/$f"
  fi
done

# Skills as REAL files (no symlinks — agent's container can't follow them outside the workspace)
echo
echo "  Materializing skills into ${WS_DIR}/.openclaw/skills/ ..."
for skill_file in .claude/skills/*.md; do
  [ -e "$skill_file" ] || continue
  skill_name="$(basename "$skill_file" .md)"
  mkdir -p "${WS_DIR}/.openclaw/skills/$skill_name"
  cp "$skill_file" "${WS_DIR}/.openclaw/skills/$skill_name/SKILL.md"
done
n_skills="$(ls -1 "${WS_DIR}/.openclaw/skills/" 2>/dev/null | wc -l)"
ok "Skills materialized: ${n_skills}"

# Fix perms (the agent's user may differ from yours; 755 is safe)
chmod -R 755 "${WS_DIR}/.openclaw"
ok ".openclaw/ perms set to 755 (agent can list)"

# Copy project data assets the agent needs at runtime
mkdir -p "${WS_DIR}/data" "${WS_DIR}/pipeline" "${WS_DIR}/identities" "${WS_DIR}/config" "${WS_DIR}/docs"
cp -n data/schema.sql data/migration-001-add-channel.sql "${WS_DIR}/data/" 2>/dev/null || true
cp -n data/runs.db "${WS_DIR}/data/" 2>/dev/null || true
cp -rn pipeline/* "${WS_DIR}/pipeline/" 2>/dev/null || true
cp -rn identities/* "${WS_DIR}/identities/" 2>/dev/null || true
cp -n config/*.json "${WS_DIR}/config/" 2>/dev/null || true
cp -n config/.env.example "${WS_DIR}/config/" 2>/dev/null || true
cp -rn docs/* "${WS_DIR}/docs/" 2>/dev/null || true
ok "Project data/pipeline/identities/config/docs copied into workspace"

# --- step 6: binaries into workspace bin/ ------------------------------------
echo
echo "Step 6/8 — Materialize binaries into workspace"
copy_binary() {
  local name="$1" found=""
  for candidate in "$HOME/.local/bin/$name" "/usr/local/bin/$name" "/usr/bin/$name"; do
    if [ -x "$candidate" ]; then found="$candidate"; break; fi
  done
  if [ -n "$found" ]; then
    cp "$found" "${WS_DIR}/bin/$name"
    chmod +x "${WS_DIR}/bin/$name"
    ok "  ${name} → ${WS_DIR}/bin/${name}"
  else
    warn "  ${name} not found on PATH — run bin/prereqs.sh first"
  fi
}
for bin in ffmpeg ffprobe yt-dlp higgsfield hf higgs; do
  copy_binary "$bin"
done

# --- step 7: Higgsfield creds into workspace ---------------------------------
echo
echo "Step 7/8 — Higgsfield credentials"
HF_CREDS_SRC="$HOME/.config/higgsfield/credentials.json"
if [ -f "$HF_CREDS_SRC" ]; then
  cp "$HF_CREDS_SRC" "${WS_DIR}/.config/higgsfield/credentials.json"
  chmod 644 "${WS_DIR}/.config/higgsfield/credentials.json"
  ok "credentials.json copied to ${WS_DIR}/.config/higgsfield/"
  ok "Agent can: \`mkdir -p ~/.config/higgsfield && cp .config/higgsfield/credentials.json ~/.config/higgsfield/\`"
else
  warn "No Higgsfield creds at ${HF_CREDS_SRC}"
  warn "Run \`higgsfield auth login\` (one-time, opens browser) AFTER this script, then re-run init.sh --force to copy creds."
fi

# --- step 8: openclaw.json agent registration --------------------------------
echo
echo "Step 8/8 — Register agent in openclaw.json"
OC_JSON="${OC_HOME}/openclaw.json"
if [ ! -f "$OC_JSON" ]; then
  warn "openclaw.json not found at ${OC_JSON}"
  warn "If you use OpenClaw, run \`openclaw init\` first then re-run this script."
else
  AGENT_ID="${WS_NAME}-orchestrator"
  PY="$(command -v python3 || echo ~/.local/bin/python3)"
  "$PY" - <<EOF
import json, os
path = "${OC_JSON}"
backup = path + ".bak-pre-${WS_NAME}"
if not os.path.exists(backup):
  import shutil; shutil.copy(path, backup)
with open(path) as f: d = json.load(f)
existing = {a.get('id') for a in d.get('agents', {}).get('list', [])}
agent = {
  "id": "${AGENT_ID}",
  "name": "${AGENT_ID}",
  "workspace": "${WS_DIR}",
  "agentDir": "${WS_AGENT_DIR}",
  "model": "anthropic/claude-opus-4-7",
  "params": {"thinking": "adaptive", "cacheRetention": "long"},
  "tools": {
    "alsoAllow": ["read","write","memory_get","memory_set","memory_search","memory_list","memory_update","sessions_spawn","sessions_send","exec","code_execution","mcp_*"],
    "deny": ["config_*","gateway"]
  }
}
if "${AGENT_ID}" in existing:
  d['agents']['list'] = [a if a.get('id') != "${AGENT_ID}" else agent for a in d['agents']['list']]
  print(f"  ✓ Agent ${AGENT_ID} updated in openclaw.json")
else:
  d.setdefault('agents', {}).setdefault('list', []).append(agent)
  print(f"  ✓ Agent ${AGENT_ID} added to openclaw.json (backup: {backup})")
with open(path,'w') as f: json.dump(d, f, indent=2, ensure_ascii=False)
EOF
fi

# --- finalize ----------------------------------------------------------------
touch .initialized
echo
echo "════════════════════════════════════════════════════"
echo "  ✓ Setup complete"
echo "════════════════════════════════════════════════════"
echo
echo "Next steps:"
echo
echo "  1. Auth Higgsfield (one-time):"
echo "       higgsfield auth login"
echo "     Then re-run \`bash bin/init.sh --force\` to copy creds into workspace."
echo
echo "  2. Install the OpenClaw plugin (dashboard at /__openclaw__/${WS_NAME}/):"
echo "       openclaw plugins install --link --dangerously-force-unsafe-install ./plugin"
echo
echo "  3. Verify the install:"
echo "       bash bin/test.sh"
echo
echo "  4. Talk to the agent — it'll detect _onboarding_required and launch the wizard:"
echo "       openclaw run ${WS_NAME}-orchestrator"
echo "     Or via WebChat / Discord / wherever your OpenClaw is set up."
echo
echo "  Workspace location: ${WS_DIR}"
echo
