# Machine Manifest: MacBook 14"

> Full backup of the OpenCode Agentic Setup for this machine.
> Run `./setup.sh` to restore from scratch.
> Run the backup skill (`/skill backup`) to UPDATE this backup.

## Machine Info

| Property | Value |
|----------|-------|
| Machine | MacBook 14" (Apple Silicon, macOS) |
| Agent name | Michael-Macbook14 |
| Git identity | `Michael-Macbook14 <michael-macbook14@my-ai-team.dev>` |
| OpenWork workspace | `~/Documents/Openwork/` |
| Co-work repo | `asaddodhy/co-work` → `~/Documents/Development/co-work/` |
| Perplexity stack | `asaddodhy/perplexity-stack` → `~/Documents/Development/perplexity-stack/` |
| The Doctor | `asaddodhy/the-doctor` → `~/Documents/Development/the-doctor/` |
| Created | 2026-06-01 |
| Last updated | 2026-06-02 |

## Software Installed

| Tool | Version | Purpose |
|------|---------|---------|
| OpenCode | latest | AI coding agent |
| `@grinev/opencode-telegram-bot` | latest | Telegram bot for OpenCode |
| `whatsapp-web.js` | latest | WhatsApp voice note listener |
| Node.js | 18+ | Runtime for Telegram bot + WhatsApp |
| Python 3.13 | via uv | MCP client + The Doctor |
| `uv` | latest | Python package manager |
| ffmpeg | latest | Audio format conversion |
| Google Chrome | latest | puppeteer dependency for WhatsApp |

## Directory Structure

```
~/Documents/
├── Openwork/                        # OpenWork workspace (opencode workspace)
│   ├── opencode.jsonc               # Workspace config (providers, plugins)
│   ├── wisdom/ → ~/Documents/Open Code/wisdom/  # Shared knowledge symlink
│   └── .opencode/
│       ├── agents/                  # Agent .md files (copied from backup)
│       ├── skills/                  # Installed skills (copied from backup)
│       └── openwork.json            # Workspace metadata
│
└── Development/
    ├── co-work/                     # Team communication repo
    ├── perplexity-stack/            # Perplexity API stack
    │   ├── scripts/transcribe.py    # Bridge script for audio transcription
    │   ├── perplexity-web-wrapper/  # MCP client (submodule/checkout)
    │   │   ├── .venv/               # Python venv with curl-cffi + mcp
    │   │   ├── perplexity_cookies.json → ~/.config/perplexity/cookies.json
    │   │   └── perplexity_subscription_mcp/  # Client + server package
    │   ├── conversation_api.py      # Port 8002 server
    │   ├── start-servers.sh         # Launch all 3 API servers
    │   └── opencode.json            # Custom OpenCode provider config
    │
    └── the-doctor/                  # Health data processing agent
        ├── telegram_listener.py     # Telegram bot for dad's voice notes
        ├── whatsapp/listener.mjs    # WhatsApp voice note listener
        ├── processor.py             # Audio → health data extraction
        ├── dashboard/app.py         # Web dashboard (port 9001)
        ├── start-all.sh             # Launch all services
        ├── scripts/test_pipeline.sh # End-to-end test script
        ├── launchd/                 # Auto-start on boot
        │   ├── com.thedoctor.start-all.plist
        │   └── install.sh
        ├── data/                    # JSON storage (transcripts + health data)
        ├── logs/                    # Service logs
        └── .env                     # Secrets (gitignored)
```

## What's Backed Up (in this `machines/macbook14/` directory)

| Item | Location in backup | Description |
|------|-------------------|-------------|
| Agent `.md` files | `agents/` | 7 agent definitions (michael, alfred, atlas, prometheus, etc.) |
| Installed skills | `skills/` | co-work, team-review, wrap-up skill files |
| Telegram patches | `patches/telegram-bot/` → `../../patches/telegram-bot/` | Symlink to generic patches |
| `.env` template | `templates/.env.example` | Telegram bot env template |
| `opencode.jsonc` template | `templates/opencode.jsonc` | Workspace config template |
| Recovery script | `setup.sh` | Fully automated 14-step recovery |
| This manifest | `manifest.md` | Documentation + inventory |

## What's NOT Backed Up (Secrets — must be re-provided)

| Secret | Where it goes | How to get it |
|--------|---------------|---------------|
| `TELEGRAM_BOT_TOKEN` | `$ENV_DIR/.env` | @BotFather on Telegram |
| `TELEGRAM_ALLOWED_USER_ID` | `$ENV_DIR/.env` | @userinfobot on Telegram |
| `OPENCODE_SERVER_PASSWORD` | `$ENV_DIR/.env` | Create a strong password |
| `VOICE_FOLLOWUP_PROMPT` | `$ENV_DIR/.env` | Custom prompt template |
| `DOCTOR_BOT_TOKEN` | `the-doctor/.env` | @BotFather (for @dads_doctor_bot) |
| `DOCTOR_ALLOWED_USERS` | `the-doctor/.env` | Telegram user IDs |
| `DOCTOR_WHATSAPP_ALLOWED` | `the-doctor/.env` | Dad's WhatsApp number |
| Perplexity cookies | `~/.config/perplexity/cookies.json` | Cookie-Editor extension → Export |
| `PERPLEXITY_SESSION_TOKEN` | env var | From Perplexity account settings |
| WhatsApp auth session | `the-doctor/whatsapp/.whatsapp-auth/` | Generated on first QR scan |

## Capabilities Installed on This Machine

| Capability | Description | Trigger |
|-----------|-------------|---------|
| **Telegram voice → transcription** | Voice note → transcribe.py → English text → OpenCode follow-up | Send voice to Telegram bot |
| **WhatsApp voice → health data** | Voice note → transcribe.py → processor.py → dashboard | Send voice to dad's number |
| **Telegram health bot (@dads_doctor_bot)** | Voice note → transcribe.py → processor.py → dashboard | Send voice to @dads_doctor_bot |
| **Perplexity Local model in OpenCode** | Use local Perplexity stack as chat model | `/models` → select `perplexity-local` |
| **Auto-start on boot** | All services launch via launchd | Machine restart |

## Capabilities Backed Up as Generic Reusable Patterns

These can be adopted by any agent on any machine. Each includes the EXACT
working code, prompts, models, and parsing logic.

| Capability | Location | What it contains |
|-----------|----------|-----------------|
| **Telegram Voice → Perplexity → Action** | `capabilities/telegram-voice-perplexity-transcription.md` | Full standalone setup: bridge script (exact prompt, model, mode, response parsing), Telegram listener with OGG→WAV conversion, env config, troubleshooting. **Start here for any agent that needs audio transcription.** |
| **Telegram bot (OpenCode patches)** | `patches/telegram-bot/` | Patches for `@grinev/opencode-telegram-bot` — voice transcription inside the OpenCode ecosystem |
| **WhatsApp voice bridge** | `patches/whatsapp-bridge/` | WhatsApp voice note listener via whatsapp-web.js |

**To replicate on a new machine**, an agent should:
1. Read `capabilities/telegram-voice-perplexity-transcription.md` for the full setup
2. Copy `scripts/transcribe.py` and `telegram_listener.py` from that doc
3. Follow the prerequisite steps (clone wrapper, sync venv, get cookies, ffmpeg)
4. No guessing — every prompt, model, port, and parsing rule is documented

## Recovery Steps

```bash
# 1. Install prerequisites (Homebrew, Node.js, uv)
# 2. Clone this repo
git clone https://github.com/asaddodhy/opencode-agentic-setup.git
# 3. Run recovery
cd opencode-agentic-setup/machines/macbook14/
./setup.sh
# 4. Provide secrets (see "What's NOT Backed Up" above)
# 5. Start services
```

## Updating This Backup

After making changes to agents, skills, configs, or adding new capabilities:

```bash
# Use the backup skill
cd ~/Documents/Development/opencode-agentic-setup
# Run: /skill backup
# Or manually copy updated files:
cp -r ~/Documents/Openwork/.opencode/agents/* machines/macbook14/agents/
cp -r ~/Documents/Openwork/.opencode/skills/* machines/macbook14/skills/
cp ~/Documents/Openwork/opencode.jsonc machines/macbook14/templates/opencode.jsonc
# Then commit and push
git add -A && git commit -m "Backup: <describe what changed>" && git push
```

## Notes

- The `perplexity-web-wrapper` is a git checkout inside `perplexity-stack/`, cloned from `https://github.com/balakumardev/perplexity-web-wrapper`. It is NOT on GitHub as `asaddodhy/` — if the remote is lost, re-clone from upstream.
- The Telegram bot patches assume `@grinev/opencode-telegram-bot` v0.21.x. If the version changes, patches may need updating.
- Wisdom directory is symlinked, never copied. The source is `~/Documents/Open Code/wisdom/`.
