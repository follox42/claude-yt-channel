#!/usr/bin/env bash
# claude-yt-channel — install all prerequisites
# Installs static binaries: ffmpeg, ffprobe, yt-dlp, higgsfield CLI
# + npm deps for Remotion + plugin
# + official Higgsfield Claude skills

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

log() { echo -e "  $*"; }
ok() { echo -e "  ✓ $*"; }
warn() { echo -e "  ⚠ $*"; }

echo
echo "════════════════════════════════════════════════════"
echo "  claude-yt-channel — install prerequisites"
echo "════════════════════════════════════════════════════"
echo

mkdir -p "$HOME/.local/bin"
need_cmd() { command -v "$1" >/dev/null 2>&1 || [ -x "$HOME/.local/bin/$1" ]; }

# 1. Python3 (required for orchestrator + yt-dlp fallback)
if ! need_cmd python3; then
  case "$(uname -s)" in
    Darwin) command -v brew >/dev/null && brew install python@3.12 ;;
    Linux)
      # Try to find an existing system Python and symlink it
      for p in /usr/bin/python3 /usr/bin/python3.12 /usr/bin/python3.11 /usr/bin/python3.10 /host/usr/bin/python3.12; do
        if [ -x "$p" ]; then
          ln -sf "$p" "$HOME/.local/bin/python3"
          break
        fi
      done
      ;;
  esac
fi
need_cmd python3 && ok "python3" || warn "python3 missing — install manually"

# 2. Node
if ! need_cmd node; then
  warn "node missing — install Node ≥22 (nvm install 22 || brew install node)"
fi
need_cmd node && ok "node $(node --version 2>&1 | head -1)"

# 3. ffmpeg + ffprobe (static binary — no dependencies)
if ! need_cmd ffmpeg; then
  log "Installing static ffmpeg + ffprobe..."
  case "$(uname -s)" in
    Darwin) command -v brew >/dev/null && brew install ffmpeg ;;
    Linux)
      curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | \
        python3 -c "
import sys, lzma, tarfile, os
home_bin = os.path.expanduser('~/.local/bin')
os.makedirs(home_bin, exist_ok=True)
with tarfile.open(fileobj=lzma.open(sys.stdin.buffer), mode='r|') as t:
  for m in t:
    if m.name.endswith('/ffmpeg') or m.name.endswith('/ffprobe'):
      m.name = m.name.split('/')[-1]
      t.extract(m, home_bin)
import stat
for b in ['ffmpeg','ffprobe']:
  os.chmod(os.path.join(home_bin, b), 0o755)
"
      ;;
  esac
fi
need_cmd ffmpeg && ok "ffmpeg $(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')"
need_cmd ffprobe && ok "ffprobe $(ffprobe -version 2>&1 | head -1 | awk '{print $3}')"

# 4. yt-dlp standalone (no Python runtime needed)
if ! need_cmd yt-dlp; then
  log "Installing yt-dlp standalone binary..."
  curl -sL -o "$HOME/.local/bin/yt-dlp" \
    "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux"
  chmod +x "$HOME/.local/bin/yt-dlp"
fi
need_cmd yt-dlp && ok "yt-dlp $($HOME/.local/bin/yt-dlp --version 2>&1 | head -1)"

# 5. Higgsfield CLI (static Go binary)
if ! need_cmd higgsfield; then
  log "Installing Higgsfield CLI..."
  curl -fsSL https://raw.githubusercontent.com/higgsfield-ai/cli/main/install.sh | \
    sh -s -- --prefix="$HOME/.local" 2>&1 | tail -3
fi
need_cmd higgsfield && ok "higgsfield $(higgsfield --version 2>&1 | head -1 | awk '{print $2}')"

# 6. npm deps — Remotion
if [ -d remotion ] && [ ! -d remotion/node_modules ]; then
  log "Installing Remotion deps (~3 min, downloads Chrome on first render)..."
  ( cd remotion && npm install --no-audit --no-fund ) 2>&1 | tail -3
fi
ok "Remotion deps"

# 7. npm deps — Plugin
if [ -d plugin ] && [ ! -d plugin/node_modules ]; then
  log "Installing OpenClaw plugin deps..."
  ( cd plugin && npm install --no-audit --no-fund && node build.mjs ) 2>&1 | tail -3
fi
ok "Plugin deps (and built)"

# 8. Official Higgsfield skills (4 of them)
if [ ! -d .agents/skills/higgsfield-generate ]; then
  log "Installing official Higgsfield Claude skills..."
  npx --yes skills@latest add higgsfield-ai/skills 2>&1 | tail -5
fi
ok "Higgsfield skills"

echo
echo "════════════════════════════════════════════════════"
echo "  ✓ Prereqs installed"
echo "════════════════════════════════════════════════════"
echo
echo "Next:"
echo "  1. higgsfield auth login    (one-time OAuth via browser)"
echo "  2. bash bin/init.sh         (configures workspace)"
echo "  3. bash bin/test.sh         (verifies install)"
echo
