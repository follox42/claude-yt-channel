#!/usr/bin/env bash
# claude-yt-channel — install prerequisites
# Installs ffmpeg, yt-dlp, higgsfield CLI, npm deps for Remotion + plugin.

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo
echo "=================================================="
echo "  claude-yt-channel — installing prerequisites"
echo "=================================================="
echo

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# 1. Python
if ! need_cmd python3; then
  echo "❌ python3 not found. Install Python 3.10+ first:"
  echo "   macOS:  brew install python@3.12"
  echo "   Linux:  sudo apt install python3"
  exit 1
fi
echo "  ✓ python3 $(python3 --version 2>&1 | awk '{print $2}')"

# 2. Node
if ! need_cmd node; then
  echo "❌ node not found. Install Node ≥22 first:"
  echo "   macOS:  brew install node"
  echo "   nvm:    nvm install 22"
  exit 1
fi
NODE_VER="$(node --version | tr -d 'v' | cut -d. -f1)"
if [ "$NODE_VER" -lt 22 ]; then
  echo "⚠️  Node version $NODE_VER, recommended ≥22"
fi
echo "  ✓ node $(node --version)"

# 3. ffmpeg
if ! need_cmd ffmpeg; then
  echo "  Installing ffmpeg (static binary)..."
  mkdir -p "$HOME/.local/bin"
  case "$(uname -s)" in
    Darwin) brew install ffmpeg ;;
    Linux)
      curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | \
        python3 -c "
import sys, lzma, tarfile
with tarfile.open(fileobj=lzma.open(sys.stdin.buffer), mode='r|') as t:
  for m in t:
    if m.name.endswith('/ffmpeg') or m.name.endswith('/ffprobe'):
      m.name = m.name.split('/')[-1]
      t.extract(m, '$HOME/.local/bin/')
"
      chmod +x "$HOME/.local/bin/ffmpeg" "$HOME/.local/bin/ffprobe"
      echo "    ⚠️  add $HOME/.local/bin to your PATH"
      ;;
  esac
fi
need_cmd ffmpeg && echo "  ✓ ffmpeg $(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')"

# 4. yt-dlp
if ! need_cmd yt-dlp; then
  echo "  Installing yt-dlp via pip..."
  python3 -m pip install --user --quiet yt-dlp 2>&1 | tail -3
fi
need_cmd yt-dlp && echo "  ✓ yt-dlp $(yt-dlp --version 2>&1 | head -1)"

# 5. Higgsfield CLI
if ! need_cmd higgsfield; then
  echo "  Installing Higgsfield CLI..."
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://raw.githubusercontent.com/higgsfield-ai/cli/main/install.sh | sh -s -- --prefix="$HOME/.local"
fi
need_cmd higgsfield && echo "  ✓ higgsfield $(higgsfield --version 2>&1 | head -1)"

# 6. npm deps (Remotion + plugin)
if [ -d remotion ] && [ ! -d remotion/node_modules ]; then
  echo "  Installing Remotion deps (~3 min)..."
  ( cd remotion && npm install --no-audit --no-fund )
fi
echo "  ✓ Remotion deps"

if [ -d plugin ] && [ ! -d plugin/node_modules ]; then
  echo "  Installing OpenClaw plugin deps..."
  ( cd plugin && npm install --no-audit --no-fund )
  ( cd plugin && node build.mjs )
fi
echo "  ✓ Plugin deps + built"

# 7. Higgsfield skills
if [ ! -d .agents/skills/higgsfield-generate ]; then
  echo "  Installing official Higgsfield skills..."
  npx --yes skills@latest add higgsfield-ai/skills 2>&1 | tail -5
fi
echo "  ✓ Higgsfield skills"

echo
echo "=================================================="
echo "  ✓ All prerequisites installed"
echo "=================================================="
echo
echo "Next: higgsfield auth login   (one-time popup browser)"
echo
