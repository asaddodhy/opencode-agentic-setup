# Ideas & Tasks

Log of ideas, features, and improvements. New items start in **New**, move to **In Progress** when work begins, and graduate to **Done** when complete. Items that won't be pursued go to **Removed** with a reason.

---

## New

_Open to work on — no particular order._

- [ ] Set up `launchd` service so OpenCode server + Telegram bot auto-start on boot
- [ ] Rotate bot token via BotFather (was exposed in conversation history)
- [ ] Add Arthur creative writing project setup to the repo as a reference
- [ ] Create a `.zshrc` helper — aliases/scripts for common commands (opencode attach, server start, etc.)
- [ ] Document the Perplexity stack setup (port 8000 / 8002) as a separate guide

### Messaging & Remote Connection

- [ ] Telegram ↔ Desktop sync — messages sent on one side don't appear in the other's TUI
- [ ] Telegram bot buttons — test the inline keyboard buttons and explore customization
- [ ] WhatsApp bridge — research and implement WhatsApp connectivity similar to Telegram
- [ ] Remote access — access OpenCode server from another Mac (LAN or internet)

### More Agents

- [ ] Personal assistant agent — set up in a separate OpenCode project
- [ ] Hermes agent — explore if it can integrate with OpenCode or needs standalone install
- [ ] Gemini Code Assist — configure Gemini models as a subagent team member
  - Best path: `ai-sdk-provider-gemini-cli` (Vercel AI SDK community provider) — OAuth or API key auth, works with AI SDK v6
  - Alternative: `lokkju/llm-gemini-code-assist` (Python LLM plugin) — OAuth auth, ~3 req/min rate limit
  - Both support models: gemini-2.5-flash, gemini-2.5-pro, gemini-3-pro-preview, etc.

### More Models

- [ ] Grok API — add as an OpenCode provider similar to Perplexity Web setup

### More Tools

- [ ] Browser operator — control a browser: navigate sites, take screenshots, download files
- [ ] Audio file parsing — speech-to-text for audio files (local or cloud STT)
- [ ] Image parsing & OCR — extract text and analyze images

---

## In Progress

_Currently being worked on._

_(none)_

---

## Done

_Completed items._

- [x] Telegram bot (@alfred5886Bot) installed and configured via @grinev/opencode-telegram-bot
- [x] OpenCode server running on port 4096 via `opencode serve`
- [x] Bot connected to shared session — Telegram ↔ Desktop synced
- [x] Created GitHub repo `asaddodhy/opencode-agentic-setup` with portable setup
- [x] Wisdom system implemented (learnings.md, decisions.md, issues.md with append-only format)
- [x] Agent team configured (Alfred, Prometheus, Atlas, Michael, Michael-Quick, Michael-Deep)
- [x] Arthur moved to separate writing project
- [x] Perplexity conversation API v2.2.0 running on port 8002
- [x] Prompt files created/verified for all agents
- [x] Research done on oh-my-openagent patterns

---

## Removed

_Items intentionally not pursued, with reason._

- (none yet)

---

## Adding a new idea

Just append a new `- [ ] Description` to the **New** section. Date it if helpful:

```
[2026-05-29] [user] Description of the idea
```
