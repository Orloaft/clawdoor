#!/usr/bin/env bash
# Run a non-delivering smoke test against the manager agent.
set -euo pipefail

openclaw agent \
  --agent manager \
  --session-key agent:manager:safe-prep-smoke \
  --message 'Smoke test your manager instructions. Do not delegate or change config. Reply with your role, the current safe-prep guardrails, and the next cutover step.'

