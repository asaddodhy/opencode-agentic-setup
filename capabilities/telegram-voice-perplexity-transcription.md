# Capability: Telegram Voice → Perplexity Transcription → Action

> **Generic pattern**: receive a voice note via Telegram, convert to a
> compatible format, send to Perplexity for transcription, then do something
> with the result.
>
> ⚠️ **This document contains the EXACT code, prompts, models, and parsing
> logic proven to work.** Do not simplify or "improve" it — every detail
> here exists because something broke without it.

---

## Architecture

```
User sends voice note → Telegram bot
  → downloads .ogg audio (Telegram's native format)
  → converts to .wav (16kHz mono PCM) via ffmpeg   ← CRITICAL: Perplexity cannot transcribe OGG directly
  → calls bridge script (transcribe.py) with .wav
     → bridge script loads Perplexity MCP client
     → sends audio + EXACT transcription prompt to Perplexity
     → Perplexity returns JSON with transcription text
     → bridge script extracts text from nested response
  → your action: reply, save, analyze, trigger workflow, etc.
```

---

## Prerequisites

### A. Perplexity MCP Client (the core library)

The `perplexity-subscription-mcp` package is NOT on PyPI. It lives in
`perplexity-web-wrapper`, cloned from GitHub:

```bash
# 1. Clone into your project or alongside it
git clone https://github.com/balakumardev/perplexity-web-wrapper.git
cd perplexity-web-wrapper

# 2. Sync the venv (creates .venv/ with curl-cffi + mcp)
uv sync --extra api

# 3. Verify the client imports correctly
.venv/bin/python3 -c "from perplexity_subscription_mcp import client; print('OK')"
```

### B. Perplexity Cookies (Authentication)

Perplexity uses browser cookies, not an API key. You must export them from
a logged-in browser session:

```bash
# 1. Log into https://perplexity.ai in your browser
# 2. Install Cookie-Editor extension (https://cookie-editor.com)
# 3. Click Cookie-Editor → Export → Copy (Cmd+C)
# 4. Save to a persistent location:
mkdir -p ~/.config/perplexity
pbpaste > ~/.config/perplexity/cookies.json

# 5. Symlink into the wrapper so the MCP client finds them:
ln -sf ~/.config/perplexity/cookies.json \
  perplexity-web-wrapper/perplexity_cookies.json

# 6. Verify:
.venv/bin/python3 -c "
import json
with open('perplexity_cookies.json') as f:
    raw = json.load(f)
from perplexity_subscription_mcp import client as p
cookies = p.normalize_cookies(raw)
print(f'✅ {len(cookies)} cookies loaded')
"
```

**Cookies expire** (typically days to weeks). When transcription stops
working, re-export from browser.

### C. System Dependencies

```bash
# ffmpeg — required for audio conversion (OGG → WAV)
brew install ffmpeg   # macOS
# apt install ffmpeg   # Linux

# Python dependencies for the Telegram listener
pip install python-telegram-bot python-dotenv
```

---

## Step 1: The Bridge Script (transcribe.py)

This is the **reusable core**. It wraps the MCP client complexity into a
simple CLI command. **Do not modify the prompt, model, or parsing logic**
unless you know what you're doing.

Create `scripts/transcribe.py`:

```python
#!/usr/bin/env python3
"""
Transcribe an audio file via Perplexity MCP client.

Usage:
    <wrapper-venv-python> transcribe.py <audio_path> [prompt] [model]

Output (stdout, JSON):
    {"text": "...transcription...", "backend_uuid": "..."}

Exit code 1 on error (message on stderr).

EXACT WORKING VERSION — do not simplify the prompt, model, mode, or
response parsing. Every detail here exists because alternatives broke.
"""
import json
import os
import sys

# ── Configuration ──────────────────────────────────────────────────
# Cookie path is relative to the bridge script's location
COOKIES_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "../perplexity-web-wrapper/perplexity_cookies.json",
)

# ⚠️ EXACT PROMPT that works. Do not change unless testing.
#    Urdu transcription with mixed English words/phrases.
DEFAULT_PROMPT = (
    "This audio is primarily in Urdu with some English words and phrases "
    "mixed in. Transcribe it exactly as spoken — Urdu words in Urdu script, "
    "English words in English. Return only the transcription."
)

# ⚠️ EXACT model and mode that work.
DEFAULT_MODEL = "gpt-4.5"
DEFAULT_MODE = "pro"

# ── Main ───────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("Usage: transcribe.py <audio_path> [prompt] [model]", file=sys.stderr)
        sys.exit(1)

    audio_path = sys.argv[1]
    prompt = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_PROMPT
    model = sys.argv[3] if len(sys.argv) > 3 else DEFAULT_MODEL

    # Validate inputs
    if not os.path.isfile(audio_path):
        print(f"Audio file not found: {audio_path}", file=sys.stderr)
        sys.exit(1)

    if not os.path.isfile(COOKIES_PATH):
        print(f"Cookies file not found: {COOKIES_PATH}", file=sys.stderr)
        print("Export cookies from browser: Cookie-Editor → Export → pbpaste > ...", file=sys.stderr)
        sys.exit(1)

    # Load cookies
    with open(COOKIES_PATH, encoding="utf-8") as f:
        raw = json.load(f)

    # Import MCP client from the wrapper directory
    wrapper_dir = os.path.dirname(os.path.dirname(COOKIES_PATH))
    sys.path.insert(0, wrapper_dir)
    try:
        from perplexity_subscription_mcp import client as p
    except ImportError:
        print(
            "perplexity_subscription_mcp not found. Run `uv sync --extra api` "
            "in the perplexity-web-wrapper directory.",
            file=sys.stderr,
        )
        sys.exit(1)

    cookies = p.normalize_cookies(raw)
    client = p.Client(cookies)

    # Read audio file into memory
    with open(audio_path, "rb") as f:
        audio_bytes = f.read()

    filename = os.path.basename(audio_path)

    # ⚠️ Send to Perplexity — uses DEFAULT_MODE="pro"
    try:
        result = client.search(
            prompt,
            mode=DEFAULT_MODE,
            model=model,
            files={filename: audio_bytes},
            stream=False,
        )
    except Exception as e:
        print(f"Perplexity search failed: {e}", file=sys.stderr)
        sys.exit(1)

    # ⚠️ EXACT response extraction logic. Perplexity returns nested data:
    #   result["answer"]                 ← direct answer (may be None)
    #   result["text"] = [               ← list of step dicts
    #       { "step_type": "FINAL",
    #         "content": { "answer": "..." } }
    #   ]
    #   result["text"][0]["content"]["web_results"][0]["snippet"]  ← fallback
    backend_uuid = result.get("backend_uuid") if isinstance(result, dict) else None
    answer = None

    # Strategy 1: Top-level "answer" field
    if isinstance(result, dict):
        top_answer = result.get("answer")
        if top_answer and isinstance(top_answer, str) and len(top_answer) > 10:
            answer = top_answer

    # Strategy 2: Iterate through text steps, find FINAL step
    if not answer:
        text_data = result.get("text", []) if isinstance(result, dict) else []
        if isinstance(text_data, list):
            for step in text_data:
                step_type = step.get("step_type", "")
                content = step.get("content", {})

                if step_type == "FINAL":
                    step_answer = content.get("answer") or content.get("text") or ""
                    if isinstance(step_answer, str) and len(step_answer) > 10:
                        answer = step_answer
                        break

                if step_type == "SEARCH_RESULTS":
                    web_results = content.get("web_results", [])
                    if web_results:
                        snippet = web_results[0].get("snippet", "")
                        # Clean up "[Unknown Speaker A]" prefix from Perplexity
                        if snippet.startswith("[Unknown Speaker"):
                            snippet = snippet.split("] ", 1)[-1] if "] " in snippet else snippet
                        if snippet:
                            answer = snippet
                            break

    # Output as JSON
    if answer:
        print(json.dumps({"text": answer, "backend_uuid": backend_uuid}))
        sys.exit(0)

    # Last resort: return raw result as string
    print(json.dumps({"text": str(result), "backend_uuid": backend_uuid}))
    sys.exit(0)


if __name__ == "__main__":
    main()
```

### Test the Bridge Script

```bash
# Test with a WAV file (works)
/path/to/perplexity-web-wrapper/.venv/bin/python3 \
  scripts/transcribe.py ~/Downloads/test_speech.wav

# Expected output:
# {"text": "ہیلو، یہ ایک ٹیسٹ ہے...", "backend_uuid": "428f9791-..."}

# Test with an OGG file (will fail unless converted first — see Step 2)
```

---

## Step 2: Audio Conversion (CRITICAL)

**Perplexity's GPT-4.5 model cannot transcribe OGG Opus files.** Telegram
sends voice notes as OGG. You MUST convert to WAV before sending to the
bridge script.

```python
import subprocess
from typing import Optional

FFMPEG = "ffmpeg"

def convert_to_wav(audio_path: str) -> Optional[str]:
    """
    Convert OGG (Telegram format) to WAV (Perplexity-compatible).
    
    Uses 16kHz mono PCM — the format GPT-4.5 handles best.
    Returns path to the converted WAV file, or None on failure.
    
    The WAV file is created alongside the original with "_converted.wav"
    suffix. Caller MUST clean it up after use.
    """
    wav_path = audio_path.rsplit(".", 1)[0] + "_converted.wav"
    try:
        result = subprocess.run(
            [FFMPEG, "-y", "-i", audio_path,
             "-acodec", "pcm_s16le",   # PCM 16-bit little-endian
             "-ar", "16000",           # 16kHz sample rate
             "-ac", "1",               # Mono channel
             wav_path],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            print(f"  ⚠️  Audio conversion failed: {result.stderr.strip()}")
            return None
        print(f"  🔄 Converted to WAV: {wav_path}")
        return wav_path
    except Exception as e:
        print(f"  ⚠️  Audio conversion error: {e}")
        return None
```

**Usage in the Telegram handler:**
```python
# Download Telegram voice as .ogg
with tempfile.NamedTemporaryFile(delete=False, suffix=".ogg") as tmp:
    tmp_path = tmp.name
    await file.download_to_drive(tmp_path)

# Convert to WAV before transcribing
wav_path = convert_to_wav(tmp_path)
audio_for_transcription = wav_path if wav_path else tmp_path

try:
    text = transcribe(audio_for_transcription)
    # ... process text ...
finally:
    # Clean up BOTH temp files
    os.unlink(tmp_path)
    if wav_path:
        os.unlink(wav_path)
```

---

## Step 3: The Telegram Listener

A complete, working Telegram bot that receives voice notes and transcribes
them. Copy this file and replace `on_transcription()` with your action.

**`telegram_listener.py`:**

```python
"""
Generic Telegram Voice → Perplexity → Action listener.

EXACT WORKING VERSION — do not simplify. Every detail:
- Audio conversion (OGG → WAV) — critical for Perplexity
- Temp file cleanup (both .ogg and .wav)
- Error logging
- User authorization
- Dashboard link
"""

import os
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv

load_dotenv()

# ── Configuration ──────────────────────────────────────────────────

BOT_TOKEN = os.getenv("BOT_TOKEN", "")
ALLOWED_USERS = {int(uid.strip()) for uid in
                 os.getenv("ALLOWED_USERS", "").split(",") if uid.strip()}

# Paths to the bridge script (adjust for your machine)
BRIDGE_SCRIPT = os.getenv("BRIDGE_SCRIPT",
    str(Path.home() / "scripts" / "transcribe.py"))
BRIDGE_PYTHON = os.getenv("BRIDGE_PYTHON",
    str(Path.home() / "perplexity-web-wrapper" / ".venv" / "bin" / "python3"))

FFMPEG = "ffmpeg"

# ── Audio Conversion ───────────────────────────────────────────────

def convert_to_wav(audio_path: str) -> Optional[str]:
    """
    Convert OGG (Telegram format) to WAV (Perplexity-compatible).
    16kHz mono PCM — required for GPT-4.5 transcription.
    """
    wav_path = audio_path.rsplit(".", 1)[0] + "_converted.wav"
    try:
        result = subprocess.run(
            [FFMPEG, "-y", "-i", audio_path,
             "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1", wav_path],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            print(f"  ⚠️  Audio conversion failed: {result.stderr.strip()}")
            return None
        return wav_path
    except Exception as e:
        print(f"  ⚠️  Audio conversion error: {e}")
        return None


# ── Transcription ──────────────────────────────────────────────────

def transcribe(audio_path: str) -> Optional[str]:
    """
    Call the bridge script. Returns transcription text or None.
    """
    if not os.path.isfile(BRIDGE_SCRIPT):
        print(f"  ❌ Bridge script not found: {BRIDGE_SCRIPT}")
        return None
    if not os.path.isfile(BRIDGE_PYTHON):
        print(f"  ❌ Bridge Python not found: {BRIDGE_PYTHON}")
        return None

    try:
        import json
        result = subprocess.run(
            [BRIDGE_PYTHON, BRIDGE_SCRIPT, audio_path],
            capture_output=True, text=True, timeout=120,
        )
    except subprocess.TimeoutExpired:
        print("  ❌ Bridge script timed out after 120s")
        return None

    if result.returncode != 0:
        print(f"  ❌ Bridge script failed (exit {result.returncode}): {result.stderr.strip()}")
        return None

    try:
        data = json.loads(result.stdout)
        text = data.get("text", "")
        if text:
            return text
        print("  ⚠️  Bridge returned empty transcription")
        return None
    except json.JSONDecodeError as e:
        print(f"  ❌ Bridge output not valid JSON: {e}")
        print(f"     stdout: {result.stdout[:200]}")
        return None


# ── Your Custom Action ─────────────────────────────────────────────

def on_transcription(transcription: str, recording_time: str,
                     update, context):
    """
    ★ REPLACE THIS with your project-specific logic ★

    This is called after successful transcription. The `transcription`
    string contains the raw Perplexity output (may be JSON-wrapped).

    Args:
        transcription: Raw text from Perplexity
        recording_time: ISO timestamp of the voice note
        update, context: python-telegram-bot objects
    """
    # Example: just reply with the transcription
    preview = transcription[:1500]
    response = f"✅ Transcription:\n\n{preview}"
    if len(transcription) > 1500:
        response += "\n\n*(truncated)*"
    update.message.reply_text(response)


# ── Telegram Bot (boilerplate — works as-is) ───────────────────────

from telegram import Update
from telegram.ext import Application, MessageHandler, filters, CommandHandler

async def handle_voice(update, context):
    """Handle incoming voice messages: download → convert → transcribe → action."""
    user = update.effective_user
    user_id = user.id if user else None

    # Authorization
    if ALLOWED_USERS and user_id not in ALLOWED_USERS:
        print(f"  ⛔ Unauthorized voice from user {user_id}")
        await update.message.reply_text("Not authorized.")
        return

    voice = update.message.voice
    if not voice:
        return

    print(f"  🎤 Voice note from {user.full_name if user else '?'} (ID: {user_id})")
    await update.message.reply_text("🔄 Processing...")

    # Download
    file = await voice.get_file()
    recording_time = update.message.date.strftime("%Y-%m-%d %H:%M:%S")

    with tempfile.NamedTemporaryFile(delete=False, suffix=".ogg") as tmp:
        tmp_path = tmp.name
        await file.download_to_drive(tmp_path)

    print(f"  💾 Downloaded: {tmp_path} ({os.path.getsize(tmp_path)} bytes)")

    # Convert OGG → WAV (critical step!)
    wav_path = convert_to_wav(tmp_path)
    audio_for_transcription = wav_path if wav_path else tmp_path

    try:
        # Transcribe
        await update.message.reply_text("🎤 Transcribing audio...")
        text = transcribe(audio_for_transcription)

        if not text:
            await update.message.reply_text("❌ Transcription failed.")
            return

        print(f"  ✅ Transcription ({len(text)} chars)")
        print(f"     Preview: {text[:200]}...")

        # Call your custom action
        on_transcription(text, recording_time, update, context)

    except Exception as e:
        print(f"  ❌ Error: {e}")
        await update.message.reply_text(f"❌ Error: {str(e)[:200]}")
    finally:
        # Clean up BOTH temp files
        os.unlink(tmp_path)
        if wav_path:
            os.unlink(wav_path)


async def start_cmd(update, context):
    await update.message.reply_text(
        f"Send me a voice note. Your user ID: {update.effective_user.id}"
    )


app = Application.builder().token(BOT_TOKEN).build()
app.add_handler(CommandHandler("start", start_cmd))
app.add_handler(MessageHandler(filters.VOICE, handle_voice))
print("🤖 Bot started. Listening for voice notes...")
app.run_polling(allowed_updates=["message"])
```

---

## Step 4: Environment Configuration

Create `.env`:

```bash
# Required
BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11

# Optional: restrict to specific Telegram user IDs (comma-separated)
ALLOWED_USERS=123456789,987654321

# Optional: override bridge script paths (defaults shown)
BRIDGE_SCRIPT=/Users/yourname/scripts/transcribe.py
BRIDGE_PYTHON=/Users/yourname/perplexity-web-wrapper/.venv/bin/python3
```

---

## Custom Action Patterns

Here are concrete, working examples for the `on_transcription()` function.

### Pattern A: Just Reply with Transcription (Foundation)

```python
def on_transcription(text, recording_time, update, context):
    preview = text[:1500]
    response = f"✅ Transcription:\n\n{preview}"
    if len(text) > 1500:
        response += "\n\n*(truncated — full text saved to dashboard)*"
    update.message.reply_text(response)
```

### Pattern B: Save to JSON + Reply

```python
import json
from pathlib import Path

DATA_DIR = Path("data")
DATA_DIR.mkdir(exist_ok=True)

def on_transcription(text, recording_time, update, context):
    # Load existing transcripts
    transcript_file = DATA_DIR / "transcripts.json"
    transcripts = []
    if transcript_file.exists() and transcript_file.stat().st_size > 0:
        with open(transcript_file) as f:
            try:
                transcripts = json.load(f)
            except json.JSONDecodeError:
                transcripts = []

    # Append new entry
    transcripts.append({
        "id": len(transcripts) + 1,
        "recording_time": recording_time,
        "processed_at": datetime.now().isoformat(),
        "transcription": text,
    })

    # Save
    with open(transcript_file, "w") as f:
        json.dump(transcripts, f, indent=2)

    update.message.reply_text(f"✅ Saved (entry #{len(transcripts)})")
```

### Pattern C: Second Perplexity Call for Data Extraction

```python
def on_transcription(text, recording_time, update, context):
    # Send transcription text back to Perplexity for structured extraction
    import sys
    from pathlib import Path

    wrapper_path = Path.home() / "perplexity-web-wrapper"
    sys.path.insert(0, str(wrapper_path))

    with open(Path.home() / ".config" / "perplexity" / "cookies.json") as f:
        raw = json.load(f)
    from perplexity_subscription_mcp import client as p
    cookies = p.normalize_cookies(raw)
    perp_client = p.Client(cookies)

    extraction_prompt = (
        f"Extract health data from this transcription:\n\n{text}\n\n"
        f"Return JSON with: blood_sugar, meals, medications, symptoms"
    )
    result = perp_client.search(extraction_prompt, mode="pro", stream=False)

    # Parse response
    response_text = ""
    if isinstance(result, dict):
        answer = result.get("answer")
        if isinstance(answer, str):
            response_text = answer
        else:
            for step in result.get("text", []):
                if isinstance(step, dict) and step.get("step_type") == "FINAL":
                    response_text = step.get("content", {}).get("answer", "")
                    break
    if not response_text:
        response_text = str(result)

    update.message.reply_text(f"📊 {response_text[:1500]}")
```

---

## Complete File Layout

```
your-project/
├── scripts/
│   └── transcribe.py              ← Bridge script (copy exactly)
├── telegram_listener.py            ← Telegram listener (copy exactly)
├── .env                            ← Bot token + config
└── data/
    └── transcripts.json            ← Saved transcriptions (auto-created)
```

Plus the cloned `perplexity-web-wrapper/` alongside (or referenced by path):
```
your-project/../perplexity-web-wrapper/
├── .venv/                          ← uv-synced venv
├── perplexity_cookies.json         → symlink to ~/.config/perplexity/cookies.json
└── perplexity_subscription_mcp/    ← The MCP client package
```

---

## Reusing This Capability on a New Machine

An agent on a new machine should follow these steps **exactly**:

```bash
# 1. Install system deps
brew install ffmpeg nodejs
pip install python-telegram-bot python-dotenv

# 2. Clone the MCP client
git clone https://github.com/balakumardev/perplexity-web-wrapper.git
cd perplexity-web-wrapper && uv sync --extra api && cd ..

# 3. Create bridge script
mkdir -p scripts
# Copy scripts/transcribe.py from this capability doc

# 4. Get Perplexity cookies
#    Log into perplexity.ai → Cookie-Editor → Export → pbpaste > ~/.config/perplexity/cookies.json
ln -sf ~/.config/perplexity/cookies.json perplexity-web-wrapper/perplexity_cookies.json

# 5. Create Telegram listener
# Copy telegram_listener.py from this capability doc

# 6. Create .env
# Set BOT_TOKEN, ALLOWED_USERS, BRIDGE_SCRIPT, BRIDGE_PYTHON

# 7. Test
cd perplexity-web-wrapper
.venv/bin/python3 ../scripts/transcribe.py ~/Downloads/test_speech.wav
# → {"text": "..."}
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|------|
| `perplexity_subscription_mcp not found` | Wrong Python interpreter | Use the wrapper's `.venv/bin/python3` |
| `Cookies file not found` | No cookies | Export from browser (Cookie-Editor) |
| Empty transcription | Expired cookies | Re-export from browser |
| `curl: (35) Recv failure: Connection reset` | Perplexity server error or stale connection | Wait and retry; re-export cookies |
| Audio "I can't transcribe this" | OGG format sent to GPT-4.5 | Convert to WAV first (Step 2) |
| `Timed out after 120s` | Large file or Perplexity slow | Increase timeout or shorten audio |
| `ffmpeg not found` | Missing ffmpeg | `brew install ffmpeg` |
| `json.decoder.JSONDecodeError: Expecting value` | Empty/corrupt JSON file | Check that data files are valid JSON; use `load_json()` with error handling |
| Telegram: "Not authorized" | User ID not in ALLOWED_USERS | Add the ID to .env |
| `[Unknown Speaker A]...` prefix in result | Perplexity formatting | Bridge script handles this — if your code doesn't, strip `[Unknown Speaker` prefix |

---

## Key Things That Will Break If You Change Them

| Setting | Working value | What breaks if changed |
|---------|--------------|----------------------|
| Model | `gpt-4.5` | Other models may not support file uploads or audio transcription |
| Mode | `pro` | `auto` mode may choose a model without file support |
| Prompt | "This audio is primarily in Urdu..." | Different prompt may return different format or refuse to transcribe |
| Audio format | WAV (16kHz mono PCM) | OGG → GPT-4.5 says "I can't transcribe this" |
| Response parsing | Iterate `text` steps, find `FINAL` | `.get("answer")` often returns None for audio queries |
| Cookies path | Symlinked to `~/.config/perplexity/cookies.json` | Must match what MCP client expects |
| Wrapper Python | `perplexity-web-wrapper/.venv/bin/python3` | System Python won't have the MCP client installed |
