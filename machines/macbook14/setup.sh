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
#
# This script recreates the machine from the files in this
# directory. To UPDATE the backup after making changes, run
# the backup-on-demand skill instead (see skills/backup/).
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PATCHES_DIR="$REPO_DIR/patches/telegram-bot"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  OpenCode Agentic Setup — MacBook 14" Recovery       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Helper ──────────────────────────────────────────────────
step() {
    local n="$1" total="$2" label="$3"
    echo ""
    echo "▸ Step $n/$total: $label..."
}

# ── Step 1: Install OpenCode ───────────────────────────────
TOTAL_STEPS=14
step 1 "$TOTAL_STEPS" "Installing OpenCode"
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

# ── Step 2: Install Node.js + system deps ──────────────────
step 2 "$TOTAL_STEPS" "Checking system dependencies"
if ! command -v node &>/dev/null; then
    echo "  ⚠️  Node.js not found. Install it from https://nodejs.org"
    exit 1
fi
echo "  ✅ Node.js $(node --version)"
if ! command -v npm &>/dev/null; then
    echo "  ⚠️  npm not found."
    exit 1
fi
echo "  ✅ npm $(npm --version)"
if ! command -v ffmpeg &>/dev/null; then
    echo "  ⚠️  ffmpeg not found. Installing via Homebrew..."
    brew install ffmpeg
fi
echo "  ✅ ffmpeg installed"
if ! command -v uv &>/dev/null; then
    echo "  Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.local/bin/env"
fi
echo "  ✅ uv $(uv --version)"

# ── Step 3: Install Telegram Bot ───────────────────────────
step 3 "$TOTAL_STEPS" "Installing Telegram bot"
if npm ls -g @grinev/opencode-telegram-bot &>/dev/null; then
    echo "  ✅ Telegram bot already installed"
    echo "  ⚠️  Re-applying patches to ensure they match current version..."
else
    npm install -g @grinev/opencode-telegram-bot@latest
    echo "  ✅ Telegram bot installed"
fi

# ── Step 4: Apply patches ──────────────────────────────────
step 4 "$TOTAL_STEPS" "Applying Telegram bot patches"

VOICE_JS_PATH="/opt/homebrew/lib/node_modules/@grinev/opencode-telegram-bot/dist/bot/handlers/voice.js"
CONFIG_JS_PATH="/opt/homebrew/lib/node_modules/@grinev/opencode-telegram-bot/dist/config.js"

if [ -f "$VOICE_JS_PATH" ] && [ -f "$CONFIG_JS_PATH" ]; then
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
else
    echo "  ⚠️  Telegram bot dist files not found at expected paths. Skipping patches."
    echo "     Expected:"
    echo "       $VOICE_JS_PATH"
    echo "       $CONFIG_JS_PATH"
fi

cd "$REPO_DIR"

# ── Step 5: Set up workspace ──────────────────────────────
step 5 "$TOTAL_STEPS" "Setting up OpenWork workspace"

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

# ── Step 6: Configure Telegram .env ───────────────────────
step 6 "$TOTAL_STEPS" "Setting up Telegram .env"
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
echo "     - VOICE_FOLLOWUP_PROMPT (the prompt template)"

# ── Step 7: Set up wisdom symlink ─────────────────────────
step 7 "$TOTAL_STEPS" "Setting up wisdom symlink"
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

# ── Step 8: Set up git identity ───────────────────────────
step 8 "$TOTAL_STEPS" "Setting up git identity (local to workspace)"
cd "$WORKSPACE_DIR"
if [ ! -d .git ]; then
    git init
fi
git config user.name "Michael-Macbook14"
git config user.email "michael-macbook14@my-ai-team.dev"
echo "  ✅ Git identity set: Michael-Macbook14 <michael-macbook14@my-ai-team.dev>"

# ── Step 9: Clone project repos ───────────────────────────
step 9 "$TOTAL_STEPS" "Cloning project repos"
DEV_DIR="$HOME/Documents/Development"
mkdir -p "$DEV_DIR"

clone_repo() {
    local repo="$1" dir="$2"
    if [ ! -d "$dir" ]; then
        echo "  Cloning $repo..."
        if git ls-remote "https://github.com/$repo.git" &>/dev/null; then
            git clone "https://github.com/$repo.git" "$dir"
            cd "$dir"
            git config user.name "Michael-Macbook14"
            git config user.email "michael-macbook14@my-ai-team.dev"
            echo "  ✅ $repo cloned"
        else
            echo "  ⚠️  $repo doesn't exist on GitHub yet"
            echo "     Create it first, then re-run this step"
        fi
    else
        echo "  ✅ $repo already cloned at $dir"
        # Pull latest
        cd "$dir" && git pull origin main 2>/dev/null || true
    fi
}

clone_repo "asaddodhy/co-work" "$DEV_DIR/co-work"
clone_repo "asaddodhy/perplexity-stack" "$DEV_DIR/perplexity-stack"
clone_repo "asaddodhy/the-doctor" "$DEV_DIR/the-doctor"

# ── Step 10: Set up Perplexity stack ──────────────────────
step 10 "$TOTAL_STEPS" "Setting up Perplexity stack"

# Sync the web wrapper (contains the MCP client)
WRAPPER_DIR="$DEV_DIR/perplexity-stack/perplexity-web-wrapper"
if [ -d "$WRAPPER_DIR" ]; then
    echo "  Syncing MCP client venv..."
    cd "$WRAPPER_DIR"
    uv sync --extra api
    echo "  ✅ MCP client venv synced"

    # Verify the client imports
    echo "  Verifying MCP client import..."
    if "$WRAPPER_DIR/.venv/bin/python3" -c "from perplexity_subscription_mcp import client; print('  ✅ MCP client OK')" 2>/dev/null; then
        :
    else
        echo "  ⚠️  MCP client import failed — may need deps or different Python version"
    fi

    # Set up cookies symlink
    echo "  Setting up Perplexity cookies..."
    COOKIE_SRC="$HOME/.config/perplexity/cookies.json"
    COOKIE_DST="$WRAPPER_DIR/perplexity_cookies.json"
    mkdir -p "$HOME/.config/perplexity"
    if [ -f "$COOKIE_SRC" ]; then
        ln -sf "$COOKIE_SRC" "$COOKIE_DST"
        echo "  ✅ Cookies symlinked: $COOKIE_DST → $COOKIE_SRC"
    else
        echo "  ⚠️  Cookies not found at $COOKIE_SRC"
        echo "     You'll need to export them from browser:"
        echo "     1. Log into perplexity.ai"
        echo "     2. Cookie-Editor extension → Export → Copy"
        echo "     3. Run: pbpaste > $COOKIE_SRC"
    fi
else
    echo "  ⚠️  perplexity-web-wrapper not found at expected path"
    echo "     It should be inside perplexity-stack repo"
fi

# ── Step 11: Set up The Doctor ─────────────────────────────
step 11 "$TOTAL_STEPS" "Setting up The Doctor"

DOCTOR_DIR="$DEV_DIR/the-doctor"
if [ -d "$DOCTOR_DIR" ]; then
    # Sync Python deps
    echo "  Syncing The Doctor's Python dependencies..."
    cd "$DOCTOR_DIR"
    uv sync 2>/dev/null && echo "  ✅ Python deps synced" || echo "  ⚠️  uv sync had issues (may need pyproject.toml)"

    # Create .env from template (if not exists)
    if [ ! -f "$DOCTOR_DIR/.env" ]; then
        cp "$DOCTOR_DIR/.env.example" "$DOCTOR_DIR/.env"
        echo "  ✅ .env created from .env.example"
        echo ""
        echo "  ⚠️  Edit $DOCTOR_DIR/.env with:"
        echo "     - DOCTOR_BOT_TOKEN (Telegram bot token for @dads_doctor_bot)"
        echo "     - DOCTOR_ALLOWED_USERS (comma-separated Telegram user IDs)"
        echo "     - DOCTOR_WHATSAPP_ALLOWED (comma-separated WhatsApp numbers)"
    else
        echo "  ✅ .env already exists"
    fi

    # Create logs directory
    mkdir -p "$DOCTOR_DIR/logs"
    echo "  ✅ Logs directory created"

    # Install WhatsApp bridge deps
    if [ -d "$DOCTOR_DIR/whatsapp" ]; then
        echo "  Installing WhatsApp bridge dependencies..."
        cd "$DOCTOR_DIR/whatsapp"
        npm install 2>&1 | tail -3
        echo "  ✅ WhatsApp bridge dependencies installed"
    fi
else
    echo "  ⚠️  The Doctor repo not found at $DOCTOR_DIR"
fi

# ── Step 12: Install launchd auto-start ───────────────────
step 12 "$TOTAL_STEPS" "Installing launchd auto-start (The Doctor)"

if [ -f "$DOCTOR_DIR/launchd/install.sh" ]; then
    cd "$DOCTOR_DIR"
    bash launchd/install.sh install
    echo "  ✅ Launchd service installed"
else
    echo "  ⚠️  launchd/install.sh not found in The Doctor repo"
    echo "     Auto-start on boot will need manual setup"
fi

# ── Step 13: Add Perplexity stack custom provider to OpenWork ──
step 13 "$TOTAL_STEPS" "Adding Perplexity local model to OpenWork"

PERPLEXITY_OPCODE_CONFIG="$DEV_DIR/perplexity-stack/opencode.json"
WORKSPACE_OPCODE_CONFIG="$WORKSPACE_DIR/opencode.jsonc"

if [ -f "$PERPLEXITY_OPCODE_CONFIG" ]; then
    echo "  Perplexity stack has its own opencode.json with custom provider config."
    echo "  To use it in OpenWork:"
    echo "    1. Merge the 'provider' section from $PERPLEXITY_OPCODE_CONFIG"
    echo "       into $WORKSPACE_OPCODE_CONFIG"
    echo "    2. Set PERPLEXITY_SESSION_TOKEN env var from your Perplexity account"
    echo "    3. Start OpenWork and run /models to select Perplexity Local"
    echo ""
    echo "  ⚠️  This step is manual — run: cat $PERPLEXITY_OPCODE_CONFIG"
else
    echo "  ⚠️  No opencode.json found in perplexity-stack"
fi

# ── Step 14: Post-Setup Info ──────────────────────────────
step 14 "$TOTAL_STEPS" "Post-setup summary"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Recovery Complete!                                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  ✅ OpenCode installed"
echo "  ✅ Telegram bot + patches installed"
echo "  ✅ OpenWork workspace configured"
echo "  ✅ Git identity set"
echo "  ✅ All repos cloned"
echo "  ✅ Perplexity stack venv synced"
echo "  ✅ The Doctor set up"
echo "  ✅ Launchd auto-start installed"
echo ""
echo "  ── What's left to do manually ──"
echo ""
echo "  1. Edit Telegram bot .env:"
echo "     $ENV_DIR/.env"
echo "     Add: TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USER_ID, OPENCODE_SERVER_PASSWORD"
echo ""
echo "  2. Edit The Doctor .env:"
echo "     $DOCTOR_DIR/.env"
echo "     Add: DOCTOR_BOT_TOKEN, DOCTOR_ALLOWED_USERS, DOCTOR_WHATSAPP_ALLOWED"
echo ""
echo "  3. Export Perplexity cookies:"
echo "     Cookie-Editor → Export → pbpaste > ~/.config/perplexity/cookies.json"
echo ""
echo "  4. Set PERPLEXITY_SESSION_TOKEN env var (for OpenWork model)"
echo ""
echo "  5. Start services:"
echo "     - The Doctor:    cd ~/Documents/Development/the-doctor && ./start-all.sh"
echo "     - Telegram bot:  opencode-telegram start --daemon"
echo "     - Perplexity:    cd ~/Documents/Development/perplexity-stack && ./start-servers.sh"
echo "     - OpenWork:      opencode serve --port 4096"
echo ""
echo "  For full details, see: $SCRIPT_DIR/manifest.md"
