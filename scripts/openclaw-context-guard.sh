#!/usr/bin/env bash
set -euo pipefail

apply=false
restart=false
notify_chat=""
max_tokens=85000
max_ratio=90
openclaw_home="${OPENCLAW_HOME:-$HOME/.openclaw}"

usage() {
  cat <<'EOF'
Usage: scripts/openclaw-context-guard.sh [--apply] [--restart] [--notify-telegram CHAT_ID]
                                      [--max-tokens N] [--max-ratio PCT]

Hard guard for runaway OpenClaw sessions. It scans persisted session rows and
retires any session whose reported token count exceeds either:
  - --max-tokens N, or
  - --max-ratio PCT of its configured contextTokens.

Retiring a row does not delete the transcript. It archives the session metadata
under ~/.openclaw/session-guard/archive and removes the active mapping so the
next message starts a fresh session instead of reusing a bloated one.

Default mode is dry-run.
EOF
}

while (($#)); do
  case "$1" in
    --apply)
      apply=true
      shift
      ;;
    --restart)
      restart=true
      shift
      ;;
    --notify-telegram)
      notify_chat="${2:-}"
      [[ -n "$notify_chat" ]] || { echo "--notify-telegram requires a chat id" >&2; exit 2; }
      shift 2
      ;;
    --max-tokens)
      max_tokens="${2:-}"
      [[ "$max_tokens" =~ ^[0-9]+$ ]] || { echo "--max-tokens requires a number" >&2; exit 2; }
      shift 2
      ;;
    --max-ratio)
      max_ratio="${2:-}"
      [[ "$max_ratio" =~ ^[0-9]+$ ]] || { echo "--max-ratio requires a number" >&2; exit 2; }
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

lock_dir="${openclaw_home}/session-guard"
mkdir -p "$lock_dir"
exec 9>"${lock_dir}/context-guard.lock"
if ! flock -n 9; then
  echo "Another context guard run is already active."
  exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
archive_root="${lock_dir}/archive/${timestamp}"
total_retired=0
summary_lines=()

sanitize_key() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

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

while IFS= read -r -d '' store; do
  [[ -s "$store" ]] || continue
  mapfile -t offenders < <(
    jq -r --argjson maxTokens "$max_tokens" --argjson maxRatio "$max_ratio" '
      to_entries[]
      | (.value.totalTokens // 0) as $tokens
      | (.value.contextTokens // 0) as $ctx
      | select(($tokens > $maxTokens) or ($ctx > 0 and (($tokens * 100) > ($ctx * $maxRatio))))
      | [
          .key,
          ($tokens | tostring),
          ($ctx | tostring),
          (.value.model // "?"),
          (.value.sessionId // "?"),
          (.value.sessionFile // "")
        ] | @tsv
    ' "$store"
  )
  ((${#offenders[@]} > 0)) || continue

  echo "Store: $store"
  for row in "${offenders[@]}"; do
    IFS=$'\t' read -r key tokens ctx model session_id session_file <<<"$row"
    ratio="?"
    if [[ "$ctx" =~ ^[0-9]+$ && "$ctx" -gt 0 ]]; then
      ratio=$((tokens * 100 / ctx))
    fi
    printf '  over-budget: %s tokens=%s context=%s ratio=%s%% model=%s session=%s\n' \
      "$key" "$tokens" "$ctx" "$ratio" "$model" "$session_id"
    summary_lines+=("${key}: ${tokens}/${ctx} (${ratio}%)")
  done

  if "$apply"; then
    agent_id="$(basename "$(dirname "$(dirname "$store")")")"
    archive_dir="${archive_root}/${agent_id}"
    mkdir -p "$archive_dir"
    cp -p "$store" "${archive_dir}/sessions.json.before"

    keys_json='[]'
    for row in "${offenders[@]}"; do
      IFS=$'\t' read -r key _tokens _ctx _model _session_id _session_file <<<"$row"
      safe_key="$(sanitize_key "$key")"
      jq --arg key "$key" '.[$key]' "$store" > "${archive_dir}/${safe_key}.session-entry.json"
      keys_json="$(jq --arg key "$key" '. + [$key]' <<<"$keys_json")"
    done

    tmp="${store}.context-guard-${timestamp}.tmp"
    jq --argjson keys "$keys_json" 'del(.[$keys[]])' "$store" > "$tmp"
    chmod 600 "$tmp"
    mv "$tmp" "$store"
    cp -p "$store" "${archive_dir}/sessions.json.after"
    total_retired=$((total_retired + ${#offenders[@]}))
  fi
done < <(find "$openclaw_home/agents" -path '*/sessions/sessions.json' -type f -print0 2>/dev/null)

if ((total_retired == 0)); then
  if ((${#summary_lines[@]} == 0)); then
    echo "No over-budget sessions found. Guard limit: ${max_tokens} tokens or ${max_ratio}%."
  elif ! "$apply"; then
    echo
    echo "Dry run only. Re-run with --apply to retire the over-budget sessions above."
  fi
else
  echo
  echo "Retired ${total_retired} over-budget session(s). Archive: ${archive_root}"
  notify "OpenClaw context guard retired ${total_retired} over-budget session(s). Next message will start fresh. Limit: ${max_tokens} tokens or ${max_ratio}%."
  if "$restart"; then
    openclaw gateway restart
  fi
fi
