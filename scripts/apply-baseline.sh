#!/usr/bin/env bash
# Apply the canonical cost baseline (config/baseline.json5) to the live
# OpenClaw config, re-pin claude-review to Opus, and restart the gateway.
#
# The baseline file is the single source of truth for the cost-critical
# settings. scripts/check-config-drift.sh verifies live config against the
# same file every 5 minutes via the context-guard timer.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASELINE="$ROOT/config/baseline.json5"

echo "== Patching agents.defaults from $BASELINE =="
openclaw config patch --file "$BASELINE"

echo "== Pinning claude-review to anthropic/claude-opus-4-8 =="
idx="$(openclaw config get agents.list | jq -r 'to_entries[] | select(.value.id == "claude-review") | .key')"
if [[ -n "$idx" ]]; then
  openclaw config set "agents.list.${idx}.model.primary" anthropic/claude-opus-4-8 > /dev/null
else
  echo "warning: claude-review agent not found; skipping pin" >&2
fi

echo "== Restarting gateway =="
systemctl --user restart openclaw-gateway.service
sleep 2

echo "== Verifying =="
"$ROOT/scripts/check-config-drift.sh"
