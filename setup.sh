#!/usr/bin/env bash
set -euo pipefail

# opencode-agentic-setup — one-command setup
# This script copies configs and prompts to the right locations.
#
# Usage:
#   ./setup.sh              # OpenCode CLI setup (default)
#   ./setup.sh --openwork   # OpenWork app setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Parse flags ──────────────────────────────────────────────────
OPENWORK=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --openwork) OPENWORK=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ═════════════════════════════════════════════════════════════════
# OpenCode CLI Setup (runs always)
# ═════════════════════════════════════════════════════════════════
echo "🚀 Setting up OpenCode agent team..."

# ── 1. Create target directories ──────────────────────────────────
echo "📁 Creating directories..."
mkdir -p ~/.config/opencode/prompts

# ── 2. Copy global config ─────────────────────────────────────────
echo "📄 Copying global config..."
cp "$SCRIPT_DIR/config/global/opencode.json" ~/.config/opencode/opencode.json

# ── 3. Copy agent prompts ─────────────────────────────────────────
echo "📝 Copying agent prompts..."
for prompt in "$SCRIPT_DIR/prompts/"*.txt; do
  filename=$(basename "$prompt")
  # Skip arthur.txt — it belongs to the creative writing project
  if [ "$filename" != "arthur.txt" ]; then
    cp "$prompt" ~/.config/opencode/prompts/"$filename"
    echo "   ✓ $filename"
  fi
done

# ── 4. Create wisdom starter in current directory (if not exists) ──
if [ ! -d "wisdom" ]; then
  echo "🧠 Creating wisdom directory in $(pwd)..."
  mkdir -p wisdom/plans wisdom/tasks
  cp "$SCRIPT_DIR/wisdom/"*.md wisdom/
  echo "   ✓ wisdom/ initialized"
else
  echo "🧠 wisdom/ already exists — skipping"
fi

# ── 5. Create project-level opencode.json if not exists ────────────
if [ ! -f "opencode.json" ]; then
  echo "🔧 Creating project-level opencode.json..."
  cp "$SCRIPT_DIR/config/project/opencode.json" ./opencode.json
  echo "   ✓ opencode.json created"
else
  echo "🔧 opencode.json already exists — skipping"
fi

# ── 6. Verify installation ──────────────────────────────────────
echo ""
echo "✅ OpenCode CLI setup complete!"
echo ""
echo "OpenCode config:   ~/.config/opencode/opencode.json"
echo "Prompts:           ~/.config/opencode/prompts/"
echo "Project config:    $(pwd)/opencode.json"
echo "Wisdom:            $(pwd)/wisdom/"
echo ""
echo "Run 'opencode' to start with the full agent team."

# ═════════════════════════════════════════════════════════════════
# OpenWork Setup (only with --openwork flag)
# ═════════════════════════════════════════════════════════════════
if [ "$OPENWORK" = true ]; then
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "🖥️  Setting up OpenWork agent files..."
  echo "═══════════════════════════════════════════════"

  WORKSPACE_DIR="${OPENWORK_WORKSPACE_DIR:-$PWD}"

  # ── Create agents directory ───────────────────────────────────
  mkdir -p "$WORKSPACE_DIR/.opencode/agents"

  # ── Copy OpenWork agent .md files ─────────────────────────────
  echo "📝 Copying OpenWork agent files..."
  for agent in "$SCRIPT_DIR/openwork/agents/"*.md; do
    filename=$(basename "$agent")
    if [ -f "$WORKSPACE_DIR/.opencode/agents/$filename" ]; then
      echo "   ⚠️  $filename already exists — skipping (delete first to overwrite)"
    else
      cp "$agent" "$WORKSPACE_DIR/.opencode/agents/$filename"
      echo "   ✓ $filename"
    fi
  done

  # ── Link or create wisdom directory ───────────────────────────
  if [ ! -d "$WORKSPACE_DIR/wisdom" ]; then
    echo "🧠 Creating wisdom directory in $WORKSPACE_DIR..."
    mkdir -p "$WORKSPACE_DIR/wisdom/plans" "$WORKSPACE_DIR/wisdom/tasks"
    cp "$SCRIPT_DIR/wisdom/"*.md "$WORKSPACE_DIR/wisdom/"
    echo "   ✓ wisdom/ created"
  else
    echo "🧠 wisdom/ already exists in workspace — skipping"
  fi

  # ── Offer to set git identity ─────────────────────────────────
  echo ""
  echo "⚠️  Don't forget to set your git identity:"
  echo "   cd $WORKSPACE_DIR"
  echo "   git init"
  echo "   git config user.name \"Michael-Macbook14\""
  echo "   git config user.email \"michael-macbook14@my-ai-team.dev\""
  echo ""
  echo "   (Adjust the identity to match your machine)"
  echo ""
  echo "📖 For full instructions, see: openwork/SETUP_OPENWORK.md"

  # ── Verify ────────────────────────────────────────────────────
  echo ""
  echo "✅ OpenWork setup complete!"
  echo "OpenWork agents:  $WORKSPACE_DIR/.opencode/agents/"
  echo "Wisdom:           $WORKSPACE_DIR/wisdom/"
fi
