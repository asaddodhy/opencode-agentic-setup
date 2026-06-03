#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# OpenCode Agentic Setup — Machine Recovery (MacBook 14")
# ─────────────────────────────────────────────────────────────
# Run this after cloning opencode-agentic-setup on a wiped/
# new MacBook 14" to restore your full development environment.
#
# Usage:
#   cd opencode-agentic-setup/machines/macbook14/
#   ./setup.sh
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PATCHES_DIR="$REPO_DIR/patches/telegram-bot"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  OpenCode Agentic Setup — MacBook 14" Recovery       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Install OpenCode ───────────────────────────────
echo "▸ Step 1/8: Installing OpenCode..."
if command -v opencode &>/dev/null; then
    echo "  ✅ OpenCode already installed ($(opencode --version 2>/dev/null || echo "unknown version"))"
else
    if command -v brew &>/dev/null; then
        brew install opencode
        echo "  ✅ OpenCode installed via Homebrew"
    else
        echo "  ⚠️  Homebrew not found. Install it from https://brew.sh, then re-run."
        echo "     Or install OpenCode manually: https://opencode.ai"
        exit 1
    fi
fi

# ── Step 2: Install Telegram Bot ───────────────────────────
echo ""
echo "▸ Step 2/8: Installing Telegram bot..."
if npm ls -g @grinev/opencode-telegram-bot &>/dev/null; then
    echo "  ✅ Telegram bot already installed"
    echo "  ⚠️  Re-applying patches to ensure they match current version..."
else
    npm install -g @grinev/opencode-telegram-bot@latest
    echo "  ✅ Telegram bot installed"
fi

# ── Step 3: Apply patches ──────────────────────────────────
echo ""
echo "▸ Step 3/8: Applying Telegram bot patches..."

VOICE_JS_PATH="/opt/homebrew/lib/node_modules/@grinev/opencode-telegram-bot/dist/bot/handlers/voice.js"
CONFIG_JS_PATH="/opt/homebrew/lib/node_modules/@grinev/opencode-telegram-bot/dist/config.js"

# Backup original files before patching
cp "$VOICE_JS_PATH" "${VOICE_JS_PATH}.bak.$(date +%s)"
cp "$CONFIG_JS_PATH" "${CONFIG_JS_PATH}.bak.$(date +%s)"

# Apply patches
cd "$(dirname "$VOICE_JS_PATH")"
if patch --dry-run -p0 < "$PATCHES_DIR/voice.js.patch" &>/dev/null; then
    patch -p0 < "$PATCHES_DIR/voice.js.patch"
    echo "  ✅ voice.js patch applied"
else
    echo "  ⚠️  voice.js patch rejected — may already be applied or version mismatch"
fi

cd "$(dirname "$CONFIG_JS_PATH")"
if patch --dry-run -p0 < "$PATCHES_DIR/config.js.patch" &>/dev/null; then
    patch -p0 < "$PATCHES_DIR/config.js.patch"
    echo "  ✅ config.js patch applied"
else
    echo "  ⚠️  config.js patch rejected — may already be applied or version mismatch"
fi

cd "$REPO_DIR"

# ── Step 4: Set up workspace ──────────────────────────────
echo ""
echo "▸ Step 4/8: Setting up OpenWork workspace..."

WORKSPACE_DIR="${OPENWORK_WORKSPACE_DIR:-$HOME/Documents/Openwork}"
mkdir -p "$WORKSPACE_DIR/.opencode/agents"
mkdir -p "$WORKSPACE_DIR/.opencode/skills"

# Copy agent files
cp -r "$SCRIPT_DIR/agents/"* "$WORKSPACE_DIR/.opencode/agents/"
echo "  ✅ Agent files copied to $WORKSPACE_DIR/.opencode/agents/"

# Copy skills
cp -r "$SCRIPT_DIR/skills/"* "$WORKSPACE_DIR/.opencode/skills/"
echo "  ✅ Skills copied to $WORKSPACE_DIR/.opencode/skills/"

# Copy workspace config
cp "$SCRIPT_DIR/templates/opencode.jsonc" "$WORKSPACE_DIR/opencode.jsonc"
echo "  ✅ Workspace config copied"

# ── Step 5: Configure .env ─────────────────────────────────
echo ""
echo "▸ Step 5/8: Setting up Telegram .env..."
ENV_DIR="$HOME/Library/Application Support/opencode-telegram-bot"
mkdir -p "$ENV_DIR"

if [ -f "$ENV_DIR/.env" ]; then
    echo "  ⚠️  .env already exists at $ENV_DIR/.env"
    read -rp "     Overwrite? (y/N): " OVERWRITE
    if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
        cp "$SCRIPT_DIR/templates/.env.example" "$ENV_DIR/.env"
        echo "  ✅ Template copied — edit $ENV_DIR/.env with your secrets"
    fi
else
    cp "$SCRIPT_DIR/templates/.env.example" "$ENV_DIR/.env"
    echo "  ✅ Template copied — edit $ENV_DIR/.env with your secrets"
fi

echo ""
echo "  ⚠️  You MUST edit $ENV_DIR/.env with:"
echo "     - TELEGRAM_BOT_TOKEN (from @BotFather)"
echo "     - TELEGRAM_ALLOWED_USER_ID (from @userinfobot)"
echo "     - OPENCODE_SERVER_PASSWORD (create a strong one)"

# ── Step 6: Set up wisdom symlink ─────────────────────────
echo ""
echo "▸ Step 6/8: Setting up wisdom symlink..."
WISDOM_SRC="$HOME/Documents/Open Code/wisdom"
WISDOM_DST="$WORKSPACE_DIR/wisdom"

if [ -d "$WISDOM_SRC" ]; then
    if [ ! -L "$WISDOM_DST" ]; then
        ln -sf "$WISDOM_SRC" "$WISDOM_DST"
        echo "  ✅ Symlinked wisdom/ → $WISDOM_SRC"
    else
        echo "  ✅ wisdom/ symlink already exists"
    fi
else
    echo "  ⚠️  Source wisdom directory not found at $WISDOM_SRC"
    echo "     Create it manually, then symlink:"
    echo "     ln -s /path/to/wisdom $WISDOM_DST"
fi

# ── Step 7: Set up git identity ───────────────────────────
echo ""
echo "▸ Step 7/8: Setting up git identity (local to workspace)..."
cd "$WORKSPACE_DIR"
if [ ! -d .git ]; then
    git init
fi
git config user.name "Michael-Macbook14"
git config user.email "michael-macbook14@my-ai-team.dev"
echo "  ✅ Git identity set: Michael-Macbook14 <michael-macbook14@my-ai-team.dev>"

# ── Step 8: Clone project repos ───────────────────────────
echo ""
echo "▸ Step 8/8: Cloning project repos..."
mkdir -p "$HOME/Documents/Development"

# Co-work
if [ ! -d "$HOME/Documents/Development/co-work" ]; then
    echo "  Cloning co-work..."
    git clone https://github.com/asaddodhy/co-work.git "$HOME/Documents/Development/co-work"
    cd "$HOME/Documents/Development/co-work"
    git config user.name "Michael-Macbook14"
    git config user.email "michael-macbook14@my-ai-team.dev"
    echo "  ✅ co-work cloned"
else
    echo "  ✅ co-work already cloned"
fi

# Perplexity stack
if [ ! -d "$HOME/Documents/Development/perplexity-stack" ]; then
    echo "  Cloning perplexity-stack..."
    git clone https://github.com/asaddodhy/perplexity-stack.git "$HOME/Documents/Development/perplexity-stack"
    cd "$HOME/Documents/Development/perplexity-stack"
    git config user.name "Michael-Macbook14"
    git config user.email "michael-macbook14@my-ai-team.dev"
    echo "  ✅ perplexity-stack cloned"
else
    echo "  ✅ perplexity-stack already cloned"
fi

# The Doctor
if [ ! -d "$HOME/Documents/Development/the-doctor" ]; then
    echo "  Cloning the-doctor..."
    if git ls-remote https://github.com/asaddodhy/the-doctor.git &>/dev/null; then
        git clone https://github.com/asaddodhy/the-doctor.git "$HOME/Documents/Development/the-doctor"
        cd "$HOME/Documents/Development/the-doctor"
        git config user.name "Michael-Macbook14"
        git config user.email "michael-macbook14@my-ai-team.dev"
        echo "  ✅ the-doctor cloned"
    else
        echo "  ⚠️  the-doctor repo doesn't exist on GitHub yet"
        echo "     Create it first, then re-run this step"
    fi
else
    echo "  ✅ the-doctor already cloned"
fi

# Install WhatsApp bridge dependencies (the-doctor/whatsapp/)
if [ -d "$HOME/Documents/Development/the-doctor/whatsapp" ]; then
    echo "  Installing WhatsApp bridge dependencies..."
    cd "$HOME/Documents/Development/the-doctor/whatsapp"
    npm install 2>&1 | tail -3
    echo "  ✅ WhatsApp bridge dependencies installed"
fi

# ── Done ───────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Recovery Complete!                                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Next steps:"
echo "  1. Edit $ENV_DIR/.env with your secrets"
echo "  2. Start OpenCode: opencode serve --port 4096"
echo "  3. Start Telegram bot: opencode-telegram start --daemon"
echo ""
echo "  For details, see: $SCRIPT_DIR/manifest.md"
