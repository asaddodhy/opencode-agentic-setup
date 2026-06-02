# Backup Skill — Snapshot current state to machine backup

Trigger: "backup", "update the backup", "save the current setup"

## What This Does

Snapshots the current state of this machine's OpenWork configuration
(agents, skills, workspace config) and updates the machine backup files
in `opencode-agentic-setup/machines/macbook14/`.

It also updates the machine `manifest.md` if anything structural changed.

## Run

From the OpenWork workspace (`~/Documents/Openwork/`):

```bash
cd ~/Documents/Development/opencode-agentic-setup
git pull origin main   # ensure latest
```

Then copy the live configs to the backup:

```bash
# ── Agents ──
cp -r ~/Documents/Openwork/.opencode/agents/* \
      machines/macbook14/agents/

# ── Skills (except backup itself) ──
for skill in ~/Documents/Openwork/.opencode/skills/*/; do
    name=$(basename "$skill")
    if [ "$name" != "backup" ]; then
        cp -r "$skill" machines/macbook14/skills/
    fi
done

# ── Workspace config ──
cp ~/Documents/Openwork/opencode.jsonc \
   machines/macbook14/templates/opencode.jsonc
```

Then commit and push:

```bash
cd ~/Documents/Development/opencode-agentic-setup
git add -A
git commit -m "Backup: snapshot $(date +%Y-%m-%d)"
git push origin main
```

## What Gets Backed Up

| Source | Backup destination |
|--------|-------------------|
| `~/Documents/Openwork/.opencode/agents/*` | `machines/macbook14/agents/` |
| `~/Documents/Openwork/.opencode/skills/*` (except `backup/`) | `machines/macbook14/skills/` |
| `~/Documents/Openwork/opencode.jsonc` | `machines/macbook14/templates/opencode.jsonc` |

## What Does NOT Get Backed Up (Secrets)

- `~/Documents/Openwork/.opencode/openwork.json` (workspace metadata)
- `.env` files anywhere
- `perplexity_cookies.json` or `~/.config/perplexity/cookies.json`
- WhatsApp auth sessions (`.whatsapp-auth/`)
- `data/` directories (transcripts, health data)

These are machine-local and must be re-created on restore.

## Notes

- The `setup.sh` in the backup is NOT auto-updated — it's a stable recovery
  script. Only update it when you add new structural steps (new repos,
  new services, new dependencies).
- The `manifest.md` is also manual — update it when adding new capabilities
  or changing the machine's role.
