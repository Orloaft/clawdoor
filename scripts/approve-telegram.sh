#!/usr/bin/env bash
set -euo pipefail

code="${1:-}"
if [[ -z "$code" ]]; then
  echo "Usage: $0 <PAIRING_CODE>"
  echo "Pending requests:"
  openclaw pairing list telegram || true
  exit 1
fi

openclaw pairing approve telegram "$code" --notify
openclaw pairing list telegram || true

echo "Waiting for the gateway to settle after pairing approval..."
for _ in {1..90}; do
  if openclaw gateway status >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! openclaw channels status --channel telegram --probe --timeout 90000; then
  echo
  echo "Pairing approval may still have succeeded even if the health probe timed out."
  echo "Check the allow list with:"
  echo "  sed -n '1,80p' ~/.openclaw/credentials/telegram-default-allowFrom.json"
fi
