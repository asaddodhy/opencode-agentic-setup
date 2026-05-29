# Learnings

Tagged, append-only log of patterns, conventions, and discoveries.
Format: `[YYYY-MM-DD] [agent-tag] One concise fact per line`
[2026-05-29] [alfred] Telegram bot @alfred5886Bot installed via @grinev/opencode-telegram-bot v0.20.6, config at ~/Library/Application Support/opencode-telegram-bot/.env
[2026-05-29] [alfred] OpenCode server runs on port 4096 via `opencode serve --port 4096`
[2026-05-29] [alfred] Server model ID is `deepseek-v4-flash-free` — bot's OPENCODE_MODEL_ID must match exactly
[2026-05-29] [alfred] Telegram bot supports commands: /projects, /sessions, /new, /commands, /skills, /task, /tasklist, /status, /help
[2026-05-29] [alfred] Bot can attach to existing sessions — it restored the session on restart
[2026-05-29] [alfred] Created GitHub repo asaddodhy/opencode-agentic-setup — portable setup for the agent team
[2026-05-29] [alfred] opencode-agentic-setup has 17 files: configs, prompts, wisdom starters, setup.sh, README, Telegram bot template
[2026-05-29] [alfred] Project renamed from 'OpenCode Test agent' to 'OpenCode Agentic Setup' — bot's settings.json updated, server+bot restarted at new path
[2026-05-29] [alfred] OpenCode server uses Basic Auth — OPENCODE_SERVER_PASSWORD env var controls it, no --key option on serve
[2026-05-29] [alfred] `opencode attach` supports --password/-p and --username/-u flags, defaults to OPENCODE_SERVER_PASSWORD and OPENCODE_SERVER_USERNAME env vars
