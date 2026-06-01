---
name: wrap-up
description: End-of-session wrap-up — push all local changes to Git, update session file, and post announcements. Use when asked to "wrap up", "end session", "stop", "done for the day", "save and quit", "close out", or "finish up".
---

# Wrap-Up

> **For all agents.** Run this at the end of every session to ensure nothing is lost.

When this skill is invoked, execute all steps below in order. Confirm each step with the user before proceeding to the next.

## Step 1: Check for uncommitted work

Check all project repos you worked on this session for uncommitted changes:

```bash
git status
git diff --stat
```

If there are uncommitted changes:
1. Show the user what's changed
2. Ask if they want to commit
3. If yes — commit on a named branch (`{agent-name}/{short-description}`), push to origin
4. If no — note it as "uncommitted work" in the session file

**Never push to main.** Always use a named branch.

## Step 2: Check for unpushed commits

```bash
git log origin/main..HEAD --oneline
```

If there are local commits not yet pushed:
1. Show them to the user
2. Push to the remote branch

## Step 3: Open PRs for any pushed branches

For each branch pushed this session that doesn't already have a PR:
1. Ask the user if they want a PR opened
2. If yes — create a PR with a clear title and description
3. If no — note it in the session file as "branch pushed, no PR yet"

## Step 4: Update the session file

Pull latest co-work first:

For local agents (Copilot / Claude Code / OpenCode):
```bash
cd ~/Documents/Development/co-work && git pull origin main
```

For Ona agents:
```bash
# Clone fresh or pull
```

Update `sessions/{your-name}-{project}.md` with a new entry at the top:

```markdown
## YYYY-MM-DD

### What was done
- Bullet points of completed work this session

### Where we stopped
- What was in progress when the session ended

### Open items
- [ ] Unchecked items that still need work

### Relevant commits
- abc1234 — short description
- PR #N — title (if PRs were opened)
```

Commit and push the session file update directly to main in co-work.

## Step 5: Post announcements in AGENT_QA

If you completed work that affects other agents (merged code, new features, config changes, new files), post an announcement in `AGENT_QA.md`:

```markdown
### [YOUR-NAME] YYYY-MM-DD — Short title [repo-name]
What was done and what other agents need to know.
**Read by:** [ ] Bruce-Macbook14 [ ] Bruce-Macbook16 [ ] Bruce-iMac [ ] Zara [ ] Nadia-MyAiTeam [ ] Nadia-VoiceAi [ ] Michael-Macbook14 [ ] Michael-Macbook16 [ ] Michael-iMac
```

If you opened PRs that need Nadia's review, mention them explicitly.

Push the AGENT_QA update directly to main in co-work.

**Skip this step** if the session was only reading/research with no code or config changes.

## Step 6: Confirm to the user

Present a summary:

```
Session wrapped up:
- [repo] — committed and pushed to branch X, PR #N opened
- [repo] — no changes
- Session file updated in co-work
- Announcement posted in AGENT_QA (or: no announcement needed)

Next session: say "resume" or "/co-work" and I'll pick up where we left off.
```

## Rules

- **Always pull co-work before writing to it** — stale writes cause conflicts
- **Never skip the session file update** — this is the only way to carry context to the next session
- **Don't post announcements for trivial work** — only announce things other agents need to know about
- **If anything fails** (push rejected, merge conflict), tell the user and help resolve it before closing
- **Ask before each destructive or state-changing action** — don't auto-commit without confirmation
