# OpenCode Agent Team Setup

A portable multi-agent development team for [OpenCode](https://opencode.ai) and [OpenWork](https://opencode.ai), featuring:

| Agent | Role | Mode |
|---|---|---|
| **Alfred** 🏗️ | Dev team lead — orchestrates, delegates, drives completion | Primary (build) |
| **Prometheus** 📋 | Strategic planner — interviews, analyzes, creates plans | Primary (read-only) |
| **Atlas** 🎯 | Todo orchestrator — systematically executes plans | Primary |
| **Michael** 💻 | General coding — features, implementation | Subagent |
| **Michael-Quick** ⚡ | Quick fixes — minimal changes, fast turnaround | Subagent |
| **Michael-Deep** 🧠 | Deep architecture — refactoring, complex work | Subagent |

## Prerequisites

- **macOS** (for Homebrew install — adapt for other platforms)
- **OpenCode** 1.15+ (desktop app or CLI)
- **Perplexity stack** — a local Perplexity API proxy (port 8002) for code generation
- **Node.js 18+** — for the Telegram bot (optional)

## Quick Start

### 1. Install OpenCode

```bash
brew install opencode
```

### 2. Set up the global config & prompts

Run the setup script:

```bash
chmod +x setup.sh
./setup.sh
```

This will:
- Create `~/.config/opencode/` directories
- Copy `config/global/opencode.json` → `~/.config/opencode/opencode.json`
- Copy all prompts from `prompts/` → `~/.config/opencode/prompts/`
- Create a starter `wisdom/` directory in your project

### 3. Set up the Perplexity stack

You need a local Perplexity API proxy running on port 8002. See the [perplexity-stack](https://github.com/asaddodhy/perplexity-stack) repo for setup instructions.

Required environment variable:

```bash
export PERPLEXITY_SESSION_TOKEN="your_341_char_jwt_token_here"
```

### 4. Create a project

```bash
mkdir my-project && cd my-project
```

Copy the project-level config:

```bash
cp /path/to/opencode-agentic-setup/config/project/opencode.json ./opencode.json
```

Initialize the wisdom directory:

```bash
mkdir -p wisdom/plans wisdom/tasks
cp /path/to/opencode-agentic-setup/wisdom/*.md wisdom/
```

### 5. Launch OpenCode

```bash
opencode
```

You're now running with the full agent team. **Alfred** is the default agent (build mode). Use `/agent` or the UI to switch.

---

## OpenWork Setup

The same agent team also works in **OpenWork** (the desktop app).

### Quick Start

```bash
# Run the setup with the --openwork flag
./setup.sh --openwork

# Or set a custom workspace path:
OPENWORK_WORKSPACE_DIR=~/Documents/MyWorkspace ./setup.sh --openwork
```

Then follow the full guide at `openwork/SETUP_OPENWORK.md` for co-work integration, git identity, and session protocols.

---

## Agent Workflow

```
You → Alfred (orchestrates)
        ├── Prometheus (complex planning)
        ├── Atlas (systematic execution)
        ├── Michael (general coding)
        ├── Michael-Quick (quick fixes)
        └── Michael-Deep (architecture/refactoring)
```

**Typical flow for a feature:**

1. Describe what you want → **Alfred** starts
2. For complex work, Alfred switches to **Prometheus** for planning
3. Once the plan is ready, **Atlas** or **Alfred** delegates to **Michael** variants
4. Each agent reads/writes **wisdom** — persistent memory across sessions

---

## Wisdom System

The `wisdom/` directory is the project's persistent memory:

```
your-project/
├── wisdom/
│   ├── learnings.md     ← Conventions, patterns, discoveries
│   ├── decisions.md     ← Architectural decisions + rationale
│   ├── issues.md        ← Open problems, blockers, questions
│   ├── plans/           ← Feature plans (created by Prometheus)
│   └── tasks/           ← Task breakdowns + progress
```

Every agent reads wisdom at session start and appends findings after work. This ensures knowledge persists even though sessions are isolated.

---

## Telegram Bot (Optional)

Connect your OpenCode session to Telegram for remote access.

### Install

```bash
npm install -g @grinev/opencode-telegram-bot@latest
```

### Configure

```bash
mkdir -p ~/Library/Application\ Support/opencode-telegram-bot
cp telegram-bot/.env.example ~/Library/Application\ Support/opencode-telegram-bot/.env
# Edit .env with your bot token and user ID
```

### Create the bot

1. Open Telegram, message **@BotFather**
2. Send `/newbot` and follow the prompts
3. Copy the bot token
4. Message **@userinfobot** to get your numeric user ID

### Run

```bash
# Start the OpenCode server
opencode serve --port 4096 --print-logs

# In another terminal, start the bot
opencode-telegram start --daemon

# (Optional) Attach desktop to the server
opencode attach http://localhost:4096 --username opencode --password $OPENCODE_SERVER_PASSWORD
```

---

## File Layout

```
opencode-agentic-setup/
├── README.md                      ← This file
├── setup.sh                       ← One-command setup script
├── config/
│   ├── global/
│   │   └── opencode.json          ← Global provider + MCP config
│   └── project/
│       └── opencode.json          ← Project-level agent definitions
├── prompts/
│   ├── alfred.txt                 ← Dev team lead / orchestrator
│   ├── prometheus.txt             ← Strategic planner (read-only)
│   ├── atlas.txt                  ← Todo orchestrator
│   ├── michael.txt                ← General coding specialist
│   ├── michael-quick.txt          ← Quick-fix coder
│   └── michael-deep.txt           ← Deep architecture specialist
├── wisdom/
│   ├── learnings.md               ← Starter template
│   ├── decisions.md               ← Starter template
│   ├── issues.md                  ← Starter template
│   ├── plans/                     ← Feature plans directory
│   └── tasks/                     ← Task tracking directory
├── openwork/                      ← OpenWork app support
│   ├── agents/                    ← Agent .md files for OpenWork
│   │   ├── alfred.md
│   │   ├── prometheus.md
│   │   ├── atlas.md
│   │   ├── michael.md
│   │   ├── michael-quick.md
│   │   └── michael-deep.md
│   └── SETUP_OPENWORK.md          ← Step-by-step OpenWork setup guide
├── telegram-bot/
│   └── .env.example               ← Telegram bot config template
└── scripts/
    └── (future)
```

## Security Notes

- **Never commit** your `.env` files, `PERPLEXITY_SESSION_TOKEN`, or Telegram bot tokens to git
- The configs reference secrets via environment variables (`${VAR_NAME}`)
- Rotate bot tokens if they're exposed in chat histories
- The OpenCode server on port 4096 uses Basic Auth — set `OPENCODE_SERVER_PASSWORD` to a strong value

## Customization

- **Prompts**: Edit the `.txt` files in `~/.config/opencode/prompts/` to customize agent behavior
- **Permissions**: Adjust the `permission` blocks in `opencode.json` to set tool access levels
- **Models**: Add/remove models in the global config's `provider.perp.models` section
- **Git identity**: Update the identity info in the Michael prompts to match your setup
- **OpenWork agents**: Edit the `.md` files in `openwork/agents/` to customize OpenWork agent behavior
