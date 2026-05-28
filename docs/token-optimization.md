# Token Optimization

Notes on how this gateway was tuned to stop burning the weekly Codex quota,
and how local ollama is wired in for compaction.

## Why

The default OpenClaw config sent every chat-history compaction summary through
the agent's primary model. With Telegram bound to `codex-dev` (model
`openai-codex/gpt-5.5`), that meant compaction itself was billed against the
Codex weekly quota — on top of the actual coding turns. Combined with a
10 MB transcript cap that effectively never triggered compaction, the context
grew unbounded and each turn re-read the whole thing.

The audit on 2026-05-27 identified the two leaks above plus a third:
`agents.defaults.model.fallbacks` was `["anthropic/claude-opus-4-7"]`, so any
Codex hiccup silently promoted the agent to Opus — 10–15x more expensive than
needed for the brainstorming and debugging that most fallbacks cover.

## Applied config baseline

Live values at `agents.defaults` and `skills.limits` in
`~/.openclaw/openclaw.json`:

| Path | Value | Effect |
|---|---|---|
| `compaction.model` | `ollama/llama3.1:8b` | Summaries run locally on the laptop GPU. Zero API cost. |
| `compaction.maxActiveTranscriptBytes` | `1mb` | Compaction fires ~10x sooner (was `10mb`). |
| `compaction.maxHistoryShare` | `0.5` | Caps retained history share after compaction. |
| `compaction.truncateAfterCompaction` | `true` | Rotates the active JSONL after compaction. |
| `contextLimits.toolResultMaxChars` | `16000` | Per-tool-output cap; sprite/asset dumps no longer re-sent whole. |
| `contextPruning.mode` | `cache-ttl` | Prunes stale tool output as prompt-cache TTL expires. |
| `contextPruning.ttl` | `10m` | Align with typical cache window. |
| `contextPruning.keepLastAssistants` | `6` | Keep recent assistant turns verbatim. |
| `contextPruning.minPrunableToolChars` | `2000` | Don't bother pruning small results. |
| `imageMaxDimensionPx` | `512` | Downscale before the vision model; ~75% fewer vision tokens for pixel art. |
| `model.fallbacks` | `["anthropic/claude-haiku-4-5"]` | Fallback drops to Haiku, not Opus. |
| `skills.limits.maxSkillsPromptChars` | `4000` | Trim injected skill schemas. |

Apply changes with `openclaw config patch --file <patch.json5>` then
`systemctl --user restart openclaw-gateway.service`.

### Gotchas observed during the audit

- The skill-limit knob lives at `skills.limits.maxSkillsPromptChars` (global) or
  `agents.list[].skillsLimits` (per-agent). There is no
  `agents.defaults.skillsLimits` — patches there fail schema validation.
- `contextPruning.mode` enum is `off | cache-ttl`.
- `compaction.mode` enum is `default | safeguard`. `safeguard` adds quality
  audit retries, which costs more tokens — keep on `default` for cost saving.
- `cache.ttl` does not exist as a top-level config key.

## Local ollama for compaction

`compaction.model: ollama/llama3.1:8b` requires a running ollama daemon and
the model file on disk.

### Why ext4-on-loop instead of writing directly to the SSD

The portable SSD is exFAT (preserves Windows compatibility for the rest of the
drive). exFAT under Linux has a known issue: large writes (>~4 GB) can persist
corrupted bytes even after a successful in-memory checksum. The first
`llama3.1:8b` pull verified fine during the pull (SHA matched the bytes ollama
held in cache) but the persisted blob's actual sha256 differed from the
filename. Inference produced pure-noise output because the loaded weights were
literally noise.

Fix without reformatting: a 10 GB ext4 image file lives on the SSD, loop-mounted
at `/mnt/ollama-ssd`. Ollama writes models into the ext4 filesystem inside
that file. The rest of the SSD stays exFAT for everything else.

### Setup that's already in place

- Ollama 0.24.0 installed via `curl -fsSL https://ollama.com/install.sh | sh`.
- Systemd drop-in at `/etc/systemd/system/ollama.service.d/override.conf` runs
  the service as user `orlovboros` (not the default `ollama` system user, so
  the loop mount's owner permissions work cleanly):
  ```ini
  [Service]
  User=orlovboros
  Group=orlovboros
  Environment="OLLAMA_MODELS=/mnt/ollama-ssd/ollama-models"
  ```
- Loop image: `/media/orlovboros/NXT 256GB/ollama-models.ext4` (10 GB, created
  with `dd` + `mkfs.ext4 -F`). Mounted to `/mnt/ollama-ssd`.
- Gateway systemd user drop-in at
  `~/.config/systemd/user/openclaw-gateway.service.d/ollama-env.conf` sets
  `OLLAMA_API_KEY=local`. The gateway only checks that the env var exists; the
  value is unused for a local ollama. `~/.bashrc` exports the same for CLI
  convenience.
- Auth profile `ollama:manual` registered via
  `openclaw models auth paste-token --provider ollama`.

### Replug workflow

After unplugging and replugging the SSD:

```bash
./scripts/mount-ollama-ssd          # remounts the ext4 image at /mnt/ollama-ssd
sudo systemctl restart ollama       # ollama re-scans the model dir
```

(Also installed at `~/.local/bin/mount-ollama-ssd` for shell convenience.)

If the SSD is unplugged when compaction tries to run, ollama errors and the
turn proceeds without that compaction; the model.fallbacks chain drops to
Haiku rather than Opus, so cost stays bounded.

## Behavioral levers still up to the user

Telegram is hard-bound to `codex-dev` via the `bindings` route, which means
every Telegram message hits gpt-5.5 by default. Two manual habits matter most:

- `/compact` after finishing a sub-task — forces a clean summary before
  unrelated work continues, and runs free on local ollama.
- `/model anthropic/claude-haiku-4-5` for brainstorming, debugging, naming
  things; `/model openai-codex/gpt-5.5` (or alias `codex`) when you genuinely
  need heavy coding. The bot doesn't auto-route by task type, so this is a
  conscious switch.
