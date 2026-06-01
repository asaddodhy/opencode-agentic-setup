# WhatsApp Voice Bridge — Capability Reference

A WhatsApp voice note listener that transcribes audio via the Perplexity MCP bridge and processes it through your application pipeline.

## How It Works

```
Dad sends voice note → your WhatsApp number
  → whatsapp-web.js (headless Chrome) receives it
  → downloads the audio
  → calls transcribe.py (Perplexity MCP bridge)
  → transcription → your app's processing pipeline
  → reply sent back via WhatsApp
```

## Quick Start

The bridge lives in `asaddodhy/the-doctor/whatsapp/`. To use it in your own project:

```bash
# 1. Create a whatsapp/ directory in your project
mkdir -p your-project/whatsapp
cd your-project/whatsapp

# 2. Copy the files from The Doctor
cp -r path/to/the-doctor/whatsapp/* .

# 3. Install dependencies
npm install

# 4. Configure
# Edit .env or set env vars:
export DOCTOR_WHATSAPP_ALLOWED=491512345678  # Allowed numbers (no +)
export DOCTOR_BRIDGE_SCRIPT=/path/to/perplexity-stack/scripts/transcribe.py
export DOCTOR_BRIDGE_PYTHON=/path/to/perplexity-web-wrapper/.venv/bin/python3

# 5. Start
node listener.mjs
# Scan QR with WhatsApp (Settings > Linked Devices > Link a Device)
```

## Dependencies

- **Node.js 18+** (tested with v25)
- **Google Chrome** (for puppeteer — auto-downloaded if missing)
- **Perplexity MCP bridge** (transcribe.py from perplexity-stack)
- **Perplexity cookies** (`~/.config/perplexity/cookies.json`)

## Architecture

```
whatsapp/
├── listener.mjs       # Main WhatsApp listener (whatsapp-web.js + Baileys)
├── package.json       # Node.js dependencies
├── .env.example       # Configuration template
└── .whatsapp-auth/    # Session data (auto-created, don't commit)
```

## Key Features

- Voice note reception and transcription
- Per-phone-number access control via `DOCTOR_WHATSAPP_ALLOWED`
- Automatic QR code login on first run
- Session persistence (reconnects without re-scanning)
- Calls The Doctor's processor for health data extraction
- Easily replaceable — swap out the processor callback

## Replacing the Processor

In `listener.mjs`, the `processWithDoctor()` function is where you'd plug in your own logic:

```javascript
async function processWithDoctor(audioPath, recordingTime) {
  // Replace with your own pipeline
  // e.g., send to your API, save to database, etc.
}
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| QR code doesn't appear | Ensure terminal supports Unicode |
| "Browser already running" | Kill stale Chrome: `pkill -f "Chrome for Testing"` |
| Voice notes not processed | Check `DOCTOR_WHATSAPP_ALLOWED` includes the sender's number |
| Bridge script fails | Verify Perplexity cookies are fresh |
