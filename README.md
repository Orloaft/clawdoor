# Clawdoor OpenClaw Setup

This folder is the local runbook for the personal OpenClaw gateway on this laptop.

## Current State

- OpenClaw CLI installed globally: `openclaw --version` (currently v2026.5.22)
- Gateway service installed with user `systemd` (`openclaw-gateway.service`)
- Gateway URL: `http://127.0.0.1:19000/`
- Gateway bind: loopback only
- Gateway auth: token
- Workspace: `/home/orlovboros/projects`
- Live config: `~/.openclaw/openclaw.json` (edit with `openclaw config set|unset|patch`, then restart the service)
- Telegram route: bound to `opus-main` by default; toggle via [`./scripts/telegram-agent`](scripts/telegram-agent) (`opus` or `codex`)
- Default model (`agents.defaults`): primary `openai-codex/gpt-5.5`, fallback `anthropic/claude-haiku-4-5` (avoids accidental opus burn)
- Compaction model: `anthropic/claude-haiku-4-5` (fast, no SSD dependency)
- Agents:
  - `main` — no model override (inherits the gpt-5.5 → haiku default)
  - `codex-dev` (`openai-codex/gpt-5.5`)
  - `opus-main` (`anthropic/claude-opus-4-8`, **no fallback**) — active Telegram lane; runs remote/phone work on opus-4-8
  - `claude-review` (`anthropic/claude-opus-4-7`) — opus reviewer for TIB
  - `ops` (`openai-codex/gpt-5.5`)

## Quick Commands

```bash
./scripts/status.sh
./scripts/login-models.sh
TELEGRAM_BOT_TOKEN='123:abc' ./scripts/connect-telegram.sh
./scripts/approve-telegram.sh <PAIRING_CODE>
./scripts/telegram-agent           # show current Telegram target
./scripts/telegram-agent opus      # route Telegram to opus-main (opus-4-8)
./scripts/telegram-agent codex     # route Telegram to codex-dev (gpt-5.5)
./scripts/mount-ollama-ssd         # only needed if you re-enable ollama compaction (see below)
```

Restart the gateway after any config change:

```bash
systemctl --user restart openclaw-gateway.service
```

## Phone Workflow

Use Telegram as the Android command surface. Create a private bot with BotFather,
connect the token on the laptop, DM the bot from your phone, approve the pairing
code on the laptop, then send work requests from Telegram.

Keep the bot private. Do not add it to public groups.

### `/compact` on Telegram

`/compact` is a built-in chat command (it is **not** gated by any allowlist —
`allowCommands` in config only applies to `gateway.nodes.*` RPC). It runs
synchronously using the **compaction model**, so it needs that model to be fast
and reachable — this is why compaction lives on haiku rather than the local
ollama 8B (which hung on a removable SSD and got the session watchdog-aborted).

It also requires an **active model session**. If the bot has been idle the
session closes, and a cold `/compact` replies *"Compaction needs an active model
session. Send a message first, then run /compact."* — so send any normal message
first, then `/compact`.

## Token Optimization

Compaction runs on `anthropic/claude-haiku-4-5` and the default fallback chain
drops to Claude Haiku instead of Opus, so model-resolve fallbacks stay cheap.

Compaction previously ran on a local ollama model (`llama3.1:8b`) on a portable
SSD for zero API cost, but that was moved off ollama on 2026-05-29 because the
8B CPU inference hung Telegram `/compact`. The ollama setup
(`./scripts/mount-ollama-ssd`, the ext4-loop-on-exFAT image, the SSD replug
workflow) is retained for rollback only. See
[docs/token-optimization.md](docs/token-optimization.md) for the audit findings,
exact config paths, the ext4-loop-on-exFAT rationale, and the SSD replug workflow.
