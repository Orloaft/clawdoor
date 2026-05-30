#!/usr/bin/env bash
set -euo pipefail

apply=false
older_than_days=7
root="${OPENCLAW_HOME:-$HOME/.openclaw}/agents"

usage() {
  cat <<'EOF'
Usage: scripts/openclaw-maintenance.sh [--apply] [--older-than-days N]

Runs OpenClaw session cleanup, then reports old native Codex rollout logs.
By default this is a dry run. With --apply, old rollout logs are moved to the
desktop trash using gio trash when available, otherwise to ~/.local/share/Trash/files.

Examples:
  scripts/openclaw-maintenance.sh
  scripts/openclaw-maintenance.sh --older-than-days 2
  scripts/openclaw-maintenance.sh --apply --older-than-days 14
EOF
}

while (($#)); do
  case "$1" in
    --apply)
      apply=true
      shift
      ;;
    --older-than-days)
      older_than_days="${2:-}"
      [[ "$older_than_days" =~ ^[0-9]+$ ]] || {
        echo "Expected a numeric value after --older-than-days" >&2
        exit 2
      }
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

echo "== OpenClaw session cleanup =="
if "$apply"; then
  openclaw sessions cleanup --all-agents --enforce
else
  openclaw sessions cleanup --all-agents --dry-run
fi

echo
echo "== Native Codex rollout logs older than ${older_than_days} day(s) =="
mapfile -d '' files < <(
  find "$root" \
    -path '*/agent/codex-home/sessions/*' \
    -type f \
    -name 'rollout-*.jsonl' \
    -mtime +"$older_than_days" \
    -print0
)

if ((${#files[@]} == 0)); then
  echo "No old native Codex rollout logs found."
  exit 0
fi

total_bytes=0
for file in "${files[@]}"; do
  bytes=$(stat -c '%s' "$file")
  total_bytes=$((total_bytes + bytes))
  printf '%10s  %s\n' "$(numfmt --to=iec-i --suffix=B "$bytes")" "$file"
done
printf 'Total: %s across %d file(s)\n' "$(numfmt --to=iec-i --suffix=B "$total_bytes")" "${#files[@]}"

if ! "$apply"; then
  echo
  echo "Dry run only. Re-run with --apply to move these files to trash."
  exit 0
fi

if command -v gio >/dev/null 2>&1; then
  for file in "${files[@]}"; do
    gio trash "$file"
  done
else
  trash_dir="$HOME/.local/share/Trash/files/openclaw-codex-rollouts-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$trash_dir"
  for file in "${files[@]}"; do
    mkdir -p "$trash_dir/$(dirname "${file#$root/}")"
    mv "$file" "$trash_dir/${file#$root/}"
  done
fi

echo "Moved old native Codex rollout logs to trash."
