# Machine Manifest: MacBook 14"

> Full backup of the OpenCode Agentic Setup for this machine.
> Created: 2026-06-01
> Agent: Michael-Macbook14

## Machine Info

| Property | Value |
|----------|-------|
| Machine | MacBook 14" (Apple Silicon) |
| Agent | Michael-Macbook14 |
| Git identity | `Michael-Macbook14 <michael-macbook14@my-ai-team.dev>` |
| OpenWork workspace | `~/Documents/Openwork/` |
| Co-work repo | `~/Documents/Development/co-work/` |
| Perplexity stack | `~/Documents/Development/perplexity-stack/` |
| The Doctor | `~/Documents/Development/the-doctor/` |

## What's Backed Up

| Item | Location in backup | Restored by |
|------|-------------------|-------------|
| Agent `.md` files | `agents/` | setup.sh |
| Installed skills | `skills/` | setup.sh |
| Telegram bot patches | `patches/telegram-bot/` (symlink → `../../patches/telegram-bot/`) | setup.sh |
| `.env` template | `templates/.env.example` | setup.sh (user fills secrets) |
| `opencode.jsonc` template | `templates/opencode.jsonc` | setup.sh |

## What's NOT Backed Up (Secrets)

You'll need to provide these when running `setup.sh`:

| Secret | Source |
|--------|--------|
| `TELEGRAM_BOT_TOKEN` | @BotFather on Telegram |
| `OPENCODE_SERVER_PASSWORD` | Create a strong random password |
| Perplexity cookies | Export from browser (Cookie-Editor) |
| `PERPLEXITY_SESSION_TOKEN` | From Perplexity account |

## Recovery Steps

```bash
git clone https://github.com/asaddodhy/opencode-agentic-setup.git
cd opencode-agentic-setup/machines/macbook14/
./setup.sh
```

## Capabilities

This machine includes reusable capabilities that any agent can adopt:

| Capability | Location | How to use |
|-----------|----------|-----------|
| **Telegram voice transcription** | `patches/telegram-bot/` | Apply `voice.js.patch` + `config.js.patch` to `@grinev/opencode-telegram-bot` |
| **WhatsApp voice bridge** | `asaddodhy/the-doctor/whatsapp/` | Clone `the-doctor`, run `node whatsapp/listener.mjs`, scan QR to link device |
| **Perplexity MCP bridge** | `asaddodhy/perplexity-stack/scripts/transcribe.py` | Transcribes audio via Perplexity MCP client |

## Notes

- The Telegram bot bridge script (`transcribe.py`) lives in the `perplexity-stack` repo, not in this backup. Setup.sh will clone it.
- The Doctor repo (`asaddodhy/the-doctor`) is now on GitHub and will be cloned automatically by setup.sh.
- The WhatsApp bridge uses `whatsapp-web.js` (puppeteer-based) — requires Node.js and Google Chrome.
- The patches assume `@grinev/opencode-telegram-bot` v0.21.0. If the version changes, patches may need updating.
- Wisdom directory is symlinked (`~/Documents/Openwork/wisdom/` → `~/Documents/Open Code/wisdom/`).
