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
- Telegram route: toggle via [`./scripts/telegram-agent`](scripts/telegram-agent) (`opus` or `codex`)
- **Cost baseline**: canonical values live in [`config/baseline.json5`](config/baseline.json5),
  applied with `./scripts/apply-baseline.sh` and enforced every 5 minutes by
  `./scripts/check-config-drift.sh` (runs as a second `ExecStart` of
  `openclaw-context-guard.service`; Telegram alert on drift)
- Default model (`agents.defaults`): primary `openai/gpt-5.5` (runs on the
  `codex` agent runtime → billed to the Codex subscription, not an API key),
  fallback `anthropic/claude-haiku-4-5` (avoids accidental opus burn)
- Compaction model: `ollama/qwen3:4b`, mode `default` — local GPU inference, zero API cost
  (validated 2026-06-10: 2,192 tok/s prompt eval / 30s end-to-end via
  `./scripts/test-local-compaction.sh`). Needs the NXT SSD mounted; if it is
  unplugged, compaction skips for that turn and nothing falls back to Opus.
- Agents:
  - `main` — no model override (inherits the gpt-5.5 → haiku default)
  - `manager` (`openai/gpt-5.5`) — prepared orchestrator lane, not bound to Telegram yet
  - `codex-dev` (`openai/gpt-5.5`)
  - `opus-main` (`anthropic/claude-fable-5`, alias `fable`, **no fallback**) — Telegram lane via `opus-telegram` account; switched from opus-4-8 on 2026-06-10
  - `claude-review` (`anthropic/claude-opus-4-8`) — opus reviewer for TIB (pinned by `apply-baseline.sh`)
  - `ops` — no model override (inherits the default)

## Quick Commands

```bash
./scripts/status.sh
./scripts/check-config-drift.sh   # live config vs config/baseline.json5
./scripts/apply-baseline.sh       # restore the cost baseline (restarts gateway)
./scripts/login-models.sh
TELEGRAM_BOT_TOKEN='123:abc' ./scripts/connect-telegram.sh
./scripts/approve-telegram.sh <PAIRING_CODE>
./scripts/telegram-agent           # show current Telegram target
./scripts/telegram-agent opus      # route Telegram to opus-main (opus-4-8)
./scripts/telegram-agent codex     # route Telegram to codex-dev (gpt-5.5)
./scripts/setup-manager-agent.sh   # create manager agent without binding Telegram
./scripts/manager-test.sh          # non-delivering manager smoke test
./scripts/setup-forum-group.sh <chatId>             # forum group = parallel sessions
./scripts/topic-route.sh <chatId> <threadId> <agent> # pin a topic to an agent
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

### Parallel sessions via forum Topics

Each topic in a forum supergroup is its own isolated session — creating a new
topic from the phone spawns a new parallel session, no laptop needed. One-time
setup (at the laptop):

1. From the phone: create a **private group**, enable **Topics** in group
   settings, add the bot.
2. On the laptop: `openclaw directory groups list --channel telegram` to find
   the chat id (`-100…`), then `./scripts/setup-forum-group.sh <chatId>`.
   Unmatched topics route to `codex-dev` by default.
3. Pin standing "desks" to specific agents:
   `./scripts/topic-route.sh <chatId> <threadId> <agentId>` — e.g. an *Inbox*
   topic -> `manager` (rough ideas, distilled and delegated), a *Review*
   topic -> `claude-review`. Get a topic's threadId via "Copy Link" on any
   message in it (`t.me/c/<chat>/<threadId>/<msgId>`).

Known issue to watch: openclaw/openclaw#31494 (a topic occasionally splitting
into two session keys) — smoke-test with two topics after setup.

### Manager Agent Prep

The manager lane is scaffolded for the future Telegram front door, but safe prep
does **not** change the current routes. See
[docs/manager-workflow.md](docs/manager-workflow.md).

Current safe target state:

- default Telegram account -> `codex-dev`
- `opus-telegram` account -> `opus-main`
- `manager` -> no Telegram binding until an at-laptop cutover

### `/compact` on Telegram

`/compact` is a built-in chat command (it is **not** gated by any allowlist —
`allowCommands` in config only applies to `gateway.nodes.*` RPC). It runs
synchronously using the **compaction model**, so it needs that model to be fast
and reachable. Compaction runs on local `ollama/qwen3:4b` (GPU); if the SSD is
unplugged the compaction errors and the turn proceeds without it.

**On Codex-backed agents (`codex-dev`, the default Telegram lane), `/compact`
is silent by design.** Codex compacts through its native app-server thread
state: OpenClaw fires it, does not wait, does not time out, and sends **no
completion message** — and the `compaction.model` override is ignored on that
lane (the local qwen only runs there as a fallback when the thread binding
fails, and for non-Codex agents). "No response" ≠ failure. To verify it
worked: `openclaw sessions --agent codex-dev` and watch the token count drop.

It also requires an **active model session**. If the bot has been idle the
session closes, and a cold `/compact` replies *"Compaction needs an active model
session. Send a message first, then run /compact."* — so send any normal message
first, then `/compact`.

## Token Optimization

Compaction runs on `anthropic/claude-haiku-4-5` and the default fallback chain
drops to Claude Haiku instead of Opus, so model-resolve fallbacks stay cheap.

Compaction previously ran on a local ollama model (`llama3.1:8b`) on a portable
SSD for zero API cost, but that was moved off ollama on 2026-05-29 because
inference hung Telegram `/compact`. See
[docs/token-optimization.md](docs/token-optimization.md) for the audit findings,
exact config paths, the ext4-loop-on-exFAT rationale, and the SSD replug workflow.

### GPU driver wedge: diagnosed and fixed (2026-06-09 → 2026-06-10)

The original 8B "hang" was misdiagnosed as model size: ollama had been running
**CPU-only** because CUDA init failed even though NVML saw the RTX 3060. Root
cause: a stuck runtime-D3 (fine-grained) GPU power state after 13+ days of
uptime — `nvidia-smi` showed `ERR!` fan/temp/perf fields. A `nvidia_uvm`
module reload was not enough (the wedge lives in the core `nvidia` module);
only a **reboot** cleared it. The wedged state also hung shutdown
(`nvidia-modeset: Error while waiting for GPU progress` loop on a black
screen — power button required).

Post-fix validation (2026-06-10): `./scripts/test-local-compaction.sh` passed
in 30s (2,192 tok/s prompt eval on GPU), and compaction switched to
`ollama/qwen3:4b` in the baseline.

Recurrence insurance (optional, needs sudo):

```bash
# coarse-grained runtime D3 instead of fine-grained:
sudo tee /etc/modprobe.d/nvidia-pm.conf <<< 'options nvidia NVreg_DynamicPowerManagement=0x01'
sudo update-initramfs -u
# and purge the leftover co-installed 590 driver:
sudo apt purge 'nvidia-*590*'
```

### SSD replug / reboot recovery

Both dev state and ollama models live in ext4 loop images on the exFAT NXT
SSD; neither mount survives a reboot or replug:

```bash
mount-ollama-ssd                                # ollama-models.ext4 -> /mnt/ollama-ssd
./scripts/mount-nxt-dev                         # dev.ext4 -> /mnt/nxt-dev (TIB, loopduel, ...)
sudo systemctl restart ollama
./scripts/test-local-compaction.sh              # optional sanity check
```
