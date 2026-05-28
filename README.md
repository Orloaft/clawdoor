# Clawdoor OpenClaw Setup

This folder is the local runbook for the personal OpenClaw gateway on this laptop.

## Current State

- OpenClaw CLI installed globally: `openclaw --version`
- Gateway service installed with user `systemd`
- Gateway URL: `http://127.0.0.1:19000/`
- Gateway bind: loopback only
- Gateway auth: token
- Workspace: `/home/orlovboros/projects`
- Telegram route: toggle via [`./scripts/telegram-agent`](scripts/telegram-agent) (`codex-dev` or `opus-main`)
- Primary model: `openai-codex/gpt-5.5`
- Fallback model: `anthropic/claude-haiku-4-5` (avoids accidental opus burn)
- Compaction model: `ollama/llama3.1:8b` (local, zero API cost)
- Agents:
  - `main`
  - `codex-dev` (`openai-codex/gpt-5.5`)
  - `opus-main` (`anthropic/claude-opus-4-7`) — general Telegram lane when Codex is rate-limited
  - `claude-review` (`anthropic/claude-opus-4-7`) — opus reviewer for TIB
  - `ops`

## Quick Commands

```bash
./scripts/status.sh
./scripts/login-models.sh
TELEGRAM_BOT_TOKEN='123:abc' ./scripts/connect-telegram.sh
./scripts/approve-telegram.sh <PAIRING_CODE>
./scripts/mount-ollama-ssd         # remount the ollama model image after SSD replug
./scripts/telegram-agent           # show current Telegram target
./scripts/telegram-agent opus      # route Telegram to opus-main
./scripts/telegram-agent codex     # route Telegram to codex-dev
```

## Phone Workflow

Use Telegram as the Android command surface. Create a private bot with BotFather,
connect the token on the laptop, DM the bot from your phone, approve the pairing
code on the laptop, then send work requests from Telegram.

Keep the bot private. Do not add it to public groups.

## Token Optimization

Compaction runs on a local ollama model (`llama3.1:8b`) on a portable SSD, and
the fallback chain drops to Claude Haiku instead of Opus. See
[docs/token-optimization.md](docs/token-optimization.md) for the audit findings,
exact config paths, the ext4-loop-on-exFAT rationale, and the SSD replug workflow.
