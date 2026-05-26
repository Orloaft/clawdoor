#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
  echo "Set TELEGRAM_BOT_TOKEN first."
  echo "Example: TELEGRAM_BOT_TOKEN='123:abc' $0"
  exit 1
fi

secret_dir="$HOME/.openclaw/secrets"
token_file="$secret_dir/telegram-bot-token"
mkdir -p "$secret_dir"
chmod 700 "$secret_dir"
printf '%s' "$TELEGRAM_BOT_TOKEN" > "$token_file"
chmod 600 "$token_file"

openclaw channels add \
  --channel telegram \
  --name personal-telegram \
  --token-file "$token_file"

openclaw config patch --stdin <<'JSON5'
{
  channels: {
    telegram: {
      enabled: true,
      dmPolicy: "pairing",
      groupPolicy: "allowlist",
      groups: {
        "*": {
          requireMention: true
        }
      },
      streaming: {
        mode: "partial",
        preview: {
          toolProgress: true,
          commandText: "status"
        }
      }
    }
  }
}
JSON5

openclaw agents bind --agent codex-dev --bind telegram --json || true
openclaw gateway restart

echo "Waiting for the gateway to come back online..."
for _ in {1..60}; do
  if openclaw gateway status >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

openclaw channels status --channel telegram --probe --timeout 60000

cat <<'MSG'

Now DM your Telegram bot from your Android phone.
If it returns a pairing code, approve it on this laptop:

  ./scripts/approve-telegram.sh <PAIRING_CODE>

Pairing codes expire after 1 hour.
MSG
