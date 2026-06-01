---
name: team-review
description: Review all pending GitHub activity across the agent team — open PRs, AGENT_QA messages, INBOX messages, and recent commits. Checks all repos on GitHub (not local clones). Use when asked to "check what's new", "review team activity", "catch up on PRs", "check messages from agents", "what did the team do", "any new PRs", "check for updates", "team status", "review and merge".
---

# Team Review

> **Owner: Nadia-MyAiTeam only.** This skill is for the dev lead role — reviewing, merging, and managing PRs across all repos. Other agents should NOT use this skill. Use the `co-work` skill instead for session start protocol.

Check all pending GitHub activity across the agent team's repos and communication channels. Everything is read from GitHub directly — no local clones needed.

## Workflow

### 1. Read communication channels from co-work repo

Clone co-work to a temp directory (shallow clone) and read these files:

```bash
git clone --depth 1 https://github.com/asaddodhy/co-work.git /tmp/co-work 2>&1
```

Read in this order:
1. `INBOX.md` — new messages from the user (highest priority)
2. `AGENT_QA.md` — cross-agent questions, announcements, tasks
3. `sessions/nadia-myaiteam.md` — last session context

For AGENT_QA.md, extract:
- **Unread announcements** — entries where Nadia-MyAiTeam's checkbox is unchecked `[ ] Nadia-MyAiTeam`
- **Pending questions** — entries with `**Status:** Pending` directed at Nadia
- **Open tasks** — entries assigned to Nadia that aren't marked done

### 2. Check open PRs across all active repos

Read `references/repos.md` for the current repo list. For each repo, call `github_list_pull_requests` with `state: open`.

Run all repo checks in parallel — do not check them sequentially.

### 3. Review each open PR

For each open PR found:
1. Read the PR description (`github_get_pull_request`)
2. Read the diff (`github_pull_request_read` with `method: get_diff`)
3. Check for merge conflicts (note the `Mergeable` field)
4. Check CI status if applicable (`github_pull_request_read` with `method: get_check_runs`)

Assess each PR:
- **Approve** — changes are correct, no issues
- **Request changes** — specific problems found (list them)
- **Needs discussion** — ambiguous, needs user input

### 4. Check recent commits on main

For repos with no open PRs, check if there are recent commits pushed directly to main that weren't reviewed. Use:

```bash
# In the temp co-work clone, check git log
git log --oneline --since="3 days ago" --all
```

For other repos, use the GitHub API via the PR tools or clone if needed.

### 5. Present findings

Present a structured summary with these sections:

**INBOX** — any new messages from the user (quote them)

**Pending Questions for Nadia** — questions from other agents awaiting answer, with your proposed response

**Unread Announcements** — announcements Nadia hasn't checked off yet, with brief summary of each

**Open PRs** — table format:

| Repo | PR # | Author | Title | Verdict | Conflicts? |
|---|---|---|---|---|---|

For each PR with issues, list the specific problems below the table.

**Direct-to-main pushes** — any unreviewed commits pushed directly to main

**Recommended actions** — ordered list of what to do next (merge, respond, review, etc.)

### 6. Act on findings

After presenting the summary, ask the user which actions to take:
- Merge approved PRs (respect dependency order)
- Post answers to pending questions
- Mark announcements as read
- Flag issues for follow-up

When merging multiple co-work PRs that touch `AGENT_QA.md`, expect merge conflicts. Resolve by:
1. Merging what you can
2. Manually applying remaining content to main
3. Closing the conflicted PRs with a comment explaining the manual merge

## Important rules

- **Always check GitHub directly** — never rely on local clones being up to date
- **Check ALL repos** from the repo list, not just the ones with known activity
- **Pull co-work fresh** every time — `git pull` or fresh clone
- **Re-check for new PRs** if the user says you missed something — PRs may have been opened during the session
- **Post answers on main** for questions — push directly to co-work main, don't create PRs for responses
