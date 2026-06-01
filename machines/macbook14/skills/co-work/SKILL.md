---
name: co-work
description: Reset to the co-work session protocol — read all communication channels, summarize what's new, and present structured next-step options before taking any action. Use when asked to "co-work", "start over", "follow the protocol", "session start", "reset", "what should we do", "give me options", "summarize and ask", or "follow instructions".
---

# Session Start Protocol

> **For all agents.** Every agent should install this skill locally and use it at session start or when asked to reset.

When this skill is invoked, stop whatever you're doing and restart the co-work session protocol. Do NOT take any actions until the user picks one.

## Step 1: Read everything fresh

Clone co-work fresh and read these files in order:

```bash
rm -rf /tmp/co-work
git clone --depth 1 https://github.com/asaddodhy/co-work.git /tmp/co-work
```

1. `INBOX.md` — new messages from Asad
2. `AGENT_QA.md` — unread announcements, pending questions, open tasks
3. `sessions/nadia-myaiteam.md` — last session context and pending tasks
4. `AGENTS.md` — team rules (skim for any changes)

## Step 2: Check GitHub activity

Check open PRs across all active repos (owner: `asaddodhy`):
`co-work`, `perplexity-stack`, `my-ai-team`, `gmail-perplexity-assistant`, `voice-ai`, `AI-Live-translate`, `opencode-agentic-setup`

Run all checks in parallel.

## Step 3: Present a summary

Write a concise summary with these sections. Keep each section to 2-3 lines max unless there's something urgent.

**Messages from Asad** — anything in INBOX.md (quote it)

**Agent activity** — new PRs, questions, announcements since last session. Count them, don't list every detail.

**Pending from last session** — items from the session file that are still open

**Issues or concerns** — anything that needs attention (conflicts, non-compliance, blockers)

## Step 4: Present next-step options

After the summary, ALWAYS present 4-6 clickable options using `ask_clarifying_questions`. The options should be based on what's actually pending. Common options include:

- Review and merge open PRs
- Answer pending agent questions
- Continue a parked task (name it)
- Check a specific repo for updates
- Update session file with current state
- Archive completed work

Frame the question as: **"What would you like to focus on?"**

## Rules

- **Do NOT take any action** before presenting options and getting a choice
- **Do NOT merge, commit, or push** anything during this skill — only read and summarize
- **Keep the summary short** — the user wants a quick overview, not a wall of text
- **Always end with options** — never end with "What would you like me to do?" as free text. Use `ask_clarifying_questions` with concrete choices.
- **If nothing is pending**, say so and offer proactive options (archive old work, update docs, check for stale PRs)
