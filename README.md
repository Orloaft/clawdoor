# Clawdoor OpenClaw Setup

This folder is the local runbook for the personal OpenClaw gateway on this laptop.

## Current State

- OpenClaw CLI installed globally: `openclaw --version`
- Gateway service installed with user `systemd`
- Gateway URL: `http://127.0.0.1:19000/`
- Gateway bind: loopback only
- Gateway auth: token
- Workspace: `/home/orlovboros/projects`
- Telegram route: `telegram -> codex-dev`
- Primary model: `openai-codex/gpt-5.5`
- Fallback model: `anthropic/claude-opus-4-7`
- Agents:
  - `main`
  - `codex-dev`
  - `claude-review` (`anthropic/claude-opus-4-7`)
  - `ops`

## Quick Commands

```bash
./scripts/status.sh
./scripts/login-models.sh
TELEGRAM_BOT_TOKEN='123:abc' ./scripts/connect-telegram.sh
./scripts/approve-telegram.sh <PAIRING_CODE>
```

## Phone Workflow

Use Telegram as the Android command surface. Create a private bot with BotFather,
connect the token on the laptop, DM the bot from your phone, approve the pairing
code on the laptop, then send work requests from Telegram.

Keep the bot private. Do not add it to public groups.
