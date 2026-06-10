#!/usr/bin/env bash
# Create the manager agent workspace/config without binding it to Telegram.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="/home/orlovboros/projects/manager"
AGENT_ID="manager"
MODEL="openai/gpt-5.5"

mkdir -p "$WORKSPACE"

if openclaw agents list --json | grep -q '"id": "manager"'; then
  echo "manager agent already exists"
else
  openclaw agents add "$AGENT_ID" \
    --workspace "$WORKSPACE" \
    --model "$MODEL" \
    --non-interactive
fi

install -m 0644 "$ROOT/prompts/manager-system.md" "$WORKSPACE/AGENTS.md"
# The manager is already configured by this script; keeping the bootstrap
# prompt around can leak first-run instructions into Telegram sessions.
if [[ -f "$WORKSPACE/BOOTSTRAP.md" ]]; then
  if command -v gio >/dev/null 2>&1; then
    gio trash "$WORKSPACE/BOOTSTRAP.md"
  else
    rm -f "$WORKSPACE/BOOTSTRAP.md"
  fi
fi
# Seed the prompt-pattern library only if absent — the manager appends
# lessons to its working copy, which must survive re-runs of this script.
if [[ ! -f "$WORKSPACE/prompt-patterns.md" ]]; then
  install -m 0644 "$ROOT/prompts/manager-prompt-patterns.md" "$WORKSPACE/prompt-patterns.md"
fi

cat <<'MSG'
manager safe prep complete

No Telegram binding was added. Verify with:
  openclaw agents list --bindings

Test without delivery:
  ./scripts/manager-test.sh
MSG
