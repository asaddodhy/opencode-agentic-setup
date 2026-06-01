# OpenWork Multi-Agent Setup

Set up the same Alfred/Prometheus/Atlas/Michael agent team in **OpenWork** (the desktop app).

## Prerequisites

- **OpenWork** app installed on your machine
- This repo cloned locally:
  ```bash
  git clone git@github.com:asaddodhy/opencode-agentic-setup.git
  cd opencode-agentic-setup
  ```
- The OpenCode prompts already installed (run `./setup.sh` from the repo root first)
- **co-work repo** — team orchestration hub (see Step 2)

---

## Step 1: Authenticate GitHub CLI

```bash
gh auth login
```

Verify:
```bash
gh auth status
# Should show: ✓ Logged in to github.com account <your-username>
```

---

## Step 2: Clone the co-work repo (Team Orchestration)

```bash
mkdir -p ~/Documents/Development
cd ~/Documents/Development
git clone git@github.com:asaddodhy/co-work.git
```

---

## Step 3: Create or Open Your OpenWork Workspace

In OpenWork, create a new workspace at `~/Documents/Openwork` (or open an existing one).

---

## Step 4: Copy the OpenWork Agent Files

From this repo, copy the 6 agent files into your OpenWork workspace:

```bash
cp -r opencode-agentic-setup/openwork/agents/* ~/Documents/Openwork/.opencode/agents/
```

Verify:
```bash
ls ~/Documents/Openwork/.opencode/agents/
# Should show: alfred.md  atlas.md  michael.md  michael-deep.md  michael-quick.md  openwork.md  prometheus.md
```

---

## Step 5: Create or Link the Wisdom Directory

```bash
# Create fresh wisdom directory
mkdir -p ~/Documents/Openwork/wisdom/plans
mkdir -p ~/Documents/Openwork/wisdom/tasks
cp opencode-agentic-setup/wisdom/*.md ~/Documents/Openwork/wisdom/
```

Or if you already have a wisdom directory elsewhere, symlink it:
```bash
cd ~/Documents/Openwork
ln -s /path/to/your/wisdom ./wisdom
```

---

## Step 6: Configure Git Identity for This Workspace

```bash
cd ~/Documents/Openwork
git init
git config user.name "Michael-Macbook14"
git config user.email "michael-macbook14@my-ai-team.dev"
```

Adjust the name and email to match your machine (see co-work `AGENTS.md` for naming conventions).

---

## Step 7: Update co-work References (if needed)

If your machine name is different from "Macbook14", update the git identity in all 6 agent files under `.opencode/agents/`. Search for `Michael-Macbook14` and replace with your identity.

---

## Step 8: Verify the Setup

```bash
ls ~/Documents/Openwork/.opencode/agents/   # 6 agent files
ls ~/Documents/Openwork/wisdom/             # learnings.md, decisions.md, issues.md, plans/, tasks/
ls ~/Documents/Development/co-work/         # team repo
git config user.name                        # your agent identity
```

---

## How It Works

| Agent | Role | File |
|-------|------|------|
| **Alfred** 🏗️ | Dev team lead — orchestrates, delegates | `alfred.md` |
| **Prometheus** 📋 | Strategic planner (read-only) | `prometheus.md` |
| **Atlas** 🗺️ | Todo orchestrator | `atlas.md` |
| **Michael** 💻 | General coding specialist | `michael.md` |
| **Michael-Quick** ⚡ | Quick-fix coder | `michael-quick.md` |
| **Michael-Deep** 🧠 | Deep architecture specialist | `michael-deep.md` |

### Agent modes in the conversation

- **Default**: Alfred — driving work, delegating to Michaels
- **"Let's plan"**: Prometheus — planning mode (conceptual)
- **"Execute the plan"**: Atlas — systematic execution

### Co-work protocol

All agents follow rules from `asaddodhy/co-work`:
- Check `INBOX.md` and `AGENT_QA.md` at session start
- Work on named branches, never push to main
- Save session files to `sessions/`
- Git identity: `{Name}-{Machine}` pattern

---

## Customization

- **Edit prompts**: Modify the `.md` files in `.opencode/agents/` to change agent behavior
- **Change identity**: Update `git config user.name` and the agent files to match your machine
- **Add projects**: Each project gets its own `wisdom/` directory and is registered in co-work
