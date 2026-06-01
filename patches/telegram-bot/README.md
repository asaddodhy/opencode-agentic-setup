# Telegram Bot — Audio Transcription Patches

These patches enable the `@grinev/opencode-telegram-bot` to accept voice/audio messages, transcribe them via an external service (e.g., Perplexity MCP), and send the transcription to OpenCode as a follow-up prompt.

## Files

| Patch | Description |
|-------|-------------|
| `voice.js.patch` | Replaces the `stt.not_configured` reply with a full pipeline: download audio → write temp file → spawn bridge script → parse transcription → show in Telegram → send to OpenCode with follow-up prompt |
| `config.js.patch` | Adds `voice.followupPrompt` config block, loaded from `VOICE_FOLLOWUP_PROMPT` env var |

## How to Apply

### Prerequisites

- `@grinev/opencode-telegram-bot` installed globally:
  ```bash
  npm install -g @grinev/opencode-telegram-bot@latest
  ```

- A bridge script installed at a known path. The patch expects:
  ```
  /Users/asadpreuss-dodhy/Documents/Development/perplexity-stack/scripts/transcribe.py
  ```
  with its venv Python at:
  ```
  /Users/asadpreuss-dodhy/Documents/Development/perplexity-stack/perplexity-web-wrapper/.venv/bin/python3
  ```

### Apply

```bash
# Apply voice.js patch
cd /opt/homebrew/lib/node_modules/@grinev/opencode-telegram-bot/dist/bot/handlers
patch -p0 < /path/to/patches/telegram-bot/voice.js.patch

# Apply config.js patch
cd /opt/homebrew/lib/node_modules/@grinev/opencode-telegram-bot/dist
patch -p0 < /path/to/patches/telegram-bot/config.js.patch
```

### Configure

Add to your `.env`:
```bash
VOICE_FOLLOWUP_PROMPT=What should I do with this transcription?
```

### Revert

```bash
# Revert voice.js
cd /opt/homebrew/lib/node_modules/@grinev/opencode-telegram-bot/dist/bot/handlers
patch -R < /path/to/patches/telegram-bot/voice.js.patch

# Revert config.js
cd /opt/homebrew/lib/node_modules/@grinev/opencode-telegram-bot/dist
patch -R < /path/to/patches/telegram-bot/config.js.patch
```

## Recovery

These patches are backed up as part of the machine-specific recovery:
- `machines/macbook14/patches/telegram-bot/` → symlink back to this folder

The `machines/macbook14/setup.sh` script applies these patches automatically.
