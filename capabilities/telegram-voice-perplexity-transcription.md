# Capability: Telegram Voice → Perplexity Transcription → Action

> **Generic pattern**: receive an audio file via Telegram, send it to
> Perplexity for transcription/processing, then do something with the result.
>
> The transcription + translation step is the **foundation**. Everything else
> (health extraction, summarization, data entry, etc.) is a custom action
> plugged on top of it.

## Overview

```
User sends voice note → Telegram bot
  → downloads .ogg audio
  → calls Perplexity MCP client with audio file
  → Perplexity returns transcription (and/or analysis)
  → your action: save, analyze, reply, trigger workflow, etc.
```

## Prerequisites (One-Time Setup)

### A. Perplexity Access

You need the **Perplexity MCP client** — a local Python package that talks to
Perplexity AI using your subscription cookies (no API key needed).

```bash
# 1. Clone the wrapper (contains the client)
git clone https://github.com/balakumardev/perplexity-web-wrapper.git
cd perplexity-web-wrapper

# 2. Create venv with deps
uv sync --extra api

# 3. Verify client works
.venv/bin/python3 -c "from perplexity_subscription_mcp import client; print('OK')"
```

#### Get Perplexity Cookies (Auth)

1. Log into [perplexity.ai](https://perplexity.ai) in your browser
2. Install [Cookie-Editor](https://cookie-editor.com/) extension
3. Click Cookie-Editor → Export → Copy
4. Save to `~/.config/perplexity/cookies.json`:
   ```bash
   pbpaste > ~/.config/perplexity/cookies.json
   ```
5. Symlink into the wrapper:
   ```bash
   ln -sf ~/.config/perplexity/cookies.json \
     perplexity-web-wrapper/perplexity_cookies.json
   ```

### B. Telegram Bot

```bash
# 1. Create a bot via @BotFather on Telegram
#    - Send /newbot → choose name → get token
#    - Save the token (e.g., 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11)

# 2. Write a Python listener (see templates below)
#    Dependencies: python-telegram-bot (pip install python-telegram-bot)
```

## Step 1: Set Up the Bridge Script

The bridge script is the reusable piece that takes any audio file and returns
transcription JSON. Create this file (adjust paths to your setup):

**`scripts/transcribe.py`:**
```python
#!/usr/bin/env python3
"""
Transcribe an audio file via Perplexity MCP client.
Usage: <venv-python> transcribe.py <audio_path> [prompt] [model]
Output: JSON: {"text": "...", "backend_uuid": "..."}
"""
import json, os, sys

COOKIES_PATH = os.path.expanduser("~/.config/perplexity/cookies.json")
DEFAULT_PROMPT = "Transcribe this audio exactly as spoken. Return only the transcription."

def main():
    audio_path = sys.argv[1]
    prompt = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_PROMPT
    model = sys.argv[3] if len(sys.argv) > 3 else "gpt-4.5"

    # Load cookies
    with open(COOKIES_PATH, encoding="utf-8") as f:
        raw = json.load(f)

    # Import MCP client (from wrapper's directory)
    wrapper_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sys.path.insert(0, wrapper_dir)
    from perplexity_subscription_mcp import client as p

    cookies = p.normalize_cookies(raw)
    client = p.Client(cookies)

    with open(audio_path, "rb") as f:
        audio_bytes = f.read()

    result = client.search(
        prompt, mode="pro", model=model,
        files={os.path.basename(audio_path): audio_bytes},
        stream=False,
    )

    # Extract text from result
    answer = None
    if isinstance(result, dict):
        answer = result.get("answer")
        if not answer:
            for step in result.get("text", []):
                if step.get("step_type") == "FINAL":
                    answer = step.get("content", {}).get("answer") or \
                             step.get("content", {}).get("text")

    print(json.dumps({"text": answer or str(result),
                      "backend_uuid": result.get("backend_uuid") if isinstance(result, dict) else None}))

if __name__ == "__main__":
    main()
```

**Test it:**
```bash
/path/to/perplexity-web-wrapper/.venv/bin/python3 \
  scripts/transcribe.py ~/Downloads/test_audio.ogg
# → {"text": "हैलो, यह एक परीक्षण है...", "backend_uuid": "..."}
```

## Step 2: Set Up the Telegram Listener

This is a generic Telegram bot that receives voice notes, transcribes them
via the bridge script, and calls your custom action.

**`telegram_listener.py`:**
```python
"""
Generic Telegram Voice → Perplexity → Action listener.
Replace `on_transcription()` with your own logic.
"""
import json, os, subprocess, sys, tempfile
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

# ── Config ──────────────────────────────────────────────────
BOT_TOKEN = os.getenv("BOT_TOKEN", "")
ALLOWED_USERS = {int(uid.strip()) for uid in
                 os.getenv("ALLOWED_USERS", "").split(",") if uid.strip()}

# Bridge script paths (adjust for your machine)
BRIDGE_SCRIPT = os.getenv("BRIDGE_SCRIPT",
    str(Path.home() / "scripts" / "transcribe.py"))
BRIDGE_PYTHON = os.getenv("BRIDGE_PYTHON",
    str(Path.home() / "perplexity-web-wrapper" / ".venv" / "bin" / "python3"))
# ────────────────────────────────────────────────────────────

def transcribe(audio_path):
    """Call the bridge script → returns text or None."""
    result = subprocess.run(
        [BRIDGE_PYTHON, BRIDGE_SCRIPT, audio_path],
        capture_output=True, text=True, timeout=120
    )
    if result.returncode != 0:
        return None
    return json.loads(result.stdout).get("text")

def on_transcription(transcription, recording_time, update, context):
    """
    ★ YOUR CUSTOM ACTION ★
    
    This is where you process the transcription. Examples:
    - Save to a database
    - Send to another API
    - Extract structured data
    - Reply with a summary
    - Trigger a workflow
    
    Args:
        transcription: English/Urdu text from Perplexity
        recording_time: ISO timestamp of the voice note
        update, context: python-telegram-bot objects (for replying)
    """
    # ★ REPLACE THIS with your project-specific logic ★
    print(f"  Transcription ({len(transcription)} chars): {transcription[:100]}...")
    update.message.reply_text(f"✅ Received: {transcription[:200]}...")

# ── Bot Setup (boilerplate — works as-is) ───────────────────

from telegram import Update
from telegram.ext import Application, MessageHandler, filters, CommandHandler

async def handle_voice(update, context):
    user = update.effective_user
    if ALLOWED_USERS and user.id not in ALLOWED_USERS:
        await update.message.reply_text("Not authorized.")
        return
    
    voice = update.message.voice
    if not voice:
        return
    
    await update.message.reply_text("🔄 Processing...")
    file = await voice.get_file()
    recording_time = update.message.date.strftime("%Y-%m-%d %H:%M:%S")
    
    with tempfile.NamedTemporaryFile(delete=False, suffix=".ogg") as tmp:
        tmp_path = tmp.name
        await file.download_to_drive(tmp_path)
    
    try:
        text = transcribe(tmp_path)
        if text:
            on_transcription(text, recording_time, update, context)
        else:
            await update.message.reply_text("❌ Transcription failed.")
    finally:
        os.unlink(tmp_path)

async def start_cmd(update, context):
    await update.message.reply_text(
        f"Send me a voice note. Your user ID: {update.effective_user.id}")

app = Application.builder().token(BOT_TOKEN).build()
app.add_handler(CommandHandler("start", start_cmd))
app.add_handler(MessageHandler(filters.VOICE, handle_voice))
print("🤖 Bot listening...")
app.run_polling()
```

## Step 3: Customize the Action

The `on_transcription()` function is your hook. Here are common patterns:

### Pattern A: Just Transcribe & Reply (Foundation)
```python
def on_transcription(text, time, update, context):
    update.message.reply_text(f"📝 {text}")
```

### Pattern B: Transcribe + Translate
Send the transcription back to Perplexity for translation:
```python
def on_transcription(text, time, update, context):
    # Step 2: Translate via Perplexity
    translation = perplexity_client.search(
        f"Translate this to English: {text}",
        mode="pro", stream=False
    )
    update.message.reply_text(f"🇬🇧 {translation}")
```

### Pattern C: Extract Structured Data (e.g., Health)
```python
def on_transcription(text, time, update, context):
    # Step 2: Ask Perplexity to extract structured data
    result = perplexity_client.search(
        f"Extract health data from this note:\n{text}\n\n"
        f"Return JSON with fields: blood_sugar, meals, medications, symptoms",
        mode="pro", stream=False
    )
    # Save to database
    save_to_db(json.loads(result))
    update.message.reply_text("✅ Health data saved.")
```

### Pattern D: Trigger External Workflow
```python
def on_transcription(text, time, update, context):
    response = requests.post("https://your-api.com/process", json={
        "text": text, "timestamp": time
    })
    update.message.reply_text(f"✅ Sent to workflow (ID: {response.json()['id']})")
```

## Reusing This Capability

To give this capability to another agent on another machine:

1. Copy the `scripts/transcribe.py` bridge script
2. Copy the `telegram_listener.py` listener
3. Run the Perplexity prerequisite setup (clone wrapper + sync venv + cookies)
4. Customize `on_transcription()` for the new project
5. Set env vars: `BOT_TOKEN`, `ALLOWED_USERS`, `BRIDGE_SCRIPT`, `BRIDGE_PYTHON`

> The bridge script is **the reusable core**. It wraps the complexity of
> the MCP client + cookies + audio upload into a simple CLI:
> `<python> transcribe.py <audio> → {"text": "...", "backend_uuid": "..."}`

## Troubleshooting

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| `perplexity_subscription_mcp not found` | Wrong Python interpreter | Use the wrapper's `.venv/bin/python3` |
| `Cookies file not found` | Missing cookies | Export from browser (Cookie-Editor) |
| Empty transcription | Expired cookies | Re-export from browser |
| `Timed out after 120 seconds` | Large file or Perplexity slow | Increase timeout or reduce audio length |
| Telegram: "Not authorized" | User ID not in ALLOWED_USERS | Add the Telegram user ID to .env |
| `ffmpeg not found` | Missing audio converter | `brew install ffmpeg` or `apt install ffmpeg` |
