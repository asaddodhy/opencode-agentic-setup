#!/usr/bin/env bash
set -euo pipefail

# opencode-agent-setup — one-command setup
# This script copies configs and prompts to the right locations.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
echo "✅ Setup complete!"
echo ""
echo "Make sure these environment variables are set:"
echo "   export PERPLEXITY_SESSION_TOKEN=\"your_jwt_token\""
echo "   export OPENCODE_SERVER_PASSWORD=\"your_server_password\""
echo ""
echo "OpenCode config:   ~/.config/opencode/opencode.json"
echo "Prompts:           ~/.config/opencode/prompts/"
echo "Project config:    $(pwd)/opencode.json"
echo "Wisdom:            $(pwd)/wisdom/"
echo ""
echo "Run 'opencode' to start with the full agent team."
