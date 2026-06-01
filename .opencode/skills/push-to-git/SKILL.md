---
name: push-to-git
description: Push local changes to GitHub following the co-work branch/PR workflow
---

# Push to Git Skill

When loaded, handle the complete git push workflow for the current project.

## Workflow

### 1. User tells you what to push

The user says something like "push changes" or "push to git" or describes specific changes.

### 2. Sync from working directory to git repo

Check if `$PWD` matches the actual git repo directory. If not, sync files:
- Copy updated files from working directory to git repo
- Only copy files the user wants pushed
- Ask the user to confirm the file list before copying

### 3. Set git identity

Set git identity for this repo:
```bash
git config user.name "Michael-Macbook16"
git config user.email "michael-macbook16@my-ai-team.dev"
```

### 4. Create branch

Branch name format: `{agent-name}/{short-description}` e.g.:
- `michael-macbook16/telegram-bot-setup`
- `michael-macbook16/password-fix`

### 5. Commit

```bash
git add -A
git commit -m "{descriptive message}"
```

### 6. Push

```bash
git push origin {branch-name}
```

### 7. Create PR

```bash
gh pr create --repo asaddodhy/{repo-name} --base main --head {branch-name} \
  --title "{title}" --body "{description}"
```

### 8. Announce in co-work

1. Pull latest co-work: `cd ~/Documents/Development/co-work && git checkout main && git pull origin main`
2. Add announcement to `AGENT_QA.md` using the Announcement format from AGENTS.md (includes read-tracking checkboxes)
3. Create branch in co-work: `{agent-name}/announce-{short-description}`
4. Commit and push
5. Create PR in co-work: `gh pr create --repo asaddodhy/co-work ...`

### 9. Report back

Tell the user:
- Branch name
- PR URL (both repos)
- What was pushed
- What to do next (wait for Nadia review or request merge)
