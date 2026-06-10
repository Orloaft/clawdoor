#!/usr/bin/env bash
# Verify the live OpenClaw config still matches config/baseline.json5.
#
# Compares every leaf value in the baseline (arrays compared wholesale)
# against `openclaw config get`, plus the claude-review Opus pin. On drift it
# prints the mismatches and, with --notify-telegram CHAT_ID, sends them to
# Telegram using the same bot-token file as the context guard.
#
# Always exits 0 unless invoked incorrectly, so it can run as an extra
# ExecStart of the context-guard oneshot without blocking session cleanup.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASELINE="$ROOT/config/baseline.json5"
openclaw_home="${OPENCLAW_HOME:-$HOME/.openclaw}"
notify_chat=""

# systemd user services don't get the login-shell PATH where npm globals live.
command -v openclaw >/dev/null 2>&1 || PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw binary not found on PATH; skipping drift check" >&2
  exit 0
fi

while (($#)); do
  case "$1" in
    --notify-telegram)
      notify_chat="${2:-}"
      [[ -n "$notify_chat" ]] || { echo "--notify-telegram requires a chat id" >&2; exit 2; }
      shift 2
      ;;
    -h|--help)
      echo "Usage: scripts/check-config-drift.sh [--notify-telegram CHAT_ID]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

notify() {
  local text="$1"
  [[ -n "$notify_chat" ]] || return 0
  local token_file="${openclaw_home}/secrets/telegram-bot-token"
  [[ -f "$token_file" ]] || return 0
  local token
  token="$(<"$token_file")"
  curl -fsS -X POST "https://api.telegram.org/bot${token}/sendMessage" \
    -d "chat_id=${notify_chat}" \
    --data-urlencode "text=${text}" >/dev/null || true
}

drift=()

# `openclaw config get` prints JSON for arrays/objects/numbers/booleans but
# bare unquoted text for strings — normalize the latter into JSON strings.
normalize() {
  local raw="$1"
  if jq -e . >/dev/null 2>&1 <<<"$raw"; then
    jq -cS . <<<"$raw"
  else
    jq -c -R . <<<"$raw"
  fi
}

# Leaf paths in the baseline; array values are leaves (numeric path components excluded).
while IFS= read -r path; do
  expected="$(jq -cS --arg p "$path" 'getpath($p | split("."))' "$BASELINE")"
  raw="$(openclaw config get "$path" 2>/dev/null)" || raw=""
  actual="$(normalize "$raw")"
  if [[ "$expected" != "$actual" ]]; then
    drift+=("${path}: expected ${expected}, live ${actual}")
  fi
done < <(jq -r 'paths(type != "object") | select(all(.[]; type == "string")) | join(".")' "$BASELINE")

# claude-review must stay pinned to Opus (cross-family review lane).
review_model="$(openclaw config get agents.list 2>/dev/null \
  | jq -r '.[] | select(.id == "claude-review") | .model.primary // "unset"')"
if [[ "$review_model" != "anthropic/claude-opus-4-8" ]]; then
  drift+=("claude-review model.primary: expected anthropic/claude-opus-4-8, live ${review_model:-unset}")
fi

if ((${#drift[@]} == 0)); then
  echo "Config matches baseline."
  exit 0
fi

echo "CONFIG DRIFT detected (${#drift[@]} mismatch(es)):"
printf '  %s\n' "${drift[@]}"
echo "Restore with: scripts/apply-baseline.sh"

msg="OpenClaw config drift (${#drift[@]}):"
for line in "${drift[@]}"; do
  msg+=$'\n'"- ${line}"
done
msg+=$'\n'"Fix: clawdoor/scripts/apply-baseline.sh"
notify "$msg"

exit 0
