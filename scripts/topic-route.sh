#!/usr/bin/env bash
# Pin a Telegram forum topic to a specific agent ("desk").
#
# Usage:
#   scripts/topic-route.sh <chatId> <threadId> <agentId>
#   scripts/topic-route.sh <chatId> <threadId> --unset   # fall back to "*"
#
# threadId: open the topic in Telegram, "Copy Link" on any message —
# the link is t.me/c/<chat>/<threadId>/<msgId>.
set -euo pipefail

CHAT_ID="${1:-}"
THREAD_ID="${2:-}"
AGENT_ID="${3:-}"

if [[ ! "$CHAT_ID" =~ ^-100[0-9]+$ || ! "$THREAD_ID" =~ ^[0-9]+$ || -z "$AGENT_ID" ]]; then
  echo "usage: $(basename "$0") <chatId> <threadId> <agentId|--unset>" >&2
  exit 2
fi

path="channels.telegram.accounts.default.groups.${CHAT_ID}.topics.${THREAD_ID}"

if [[ "$AGENT_ID" == "--unset" ]]; then
  openclaw config unset "$path" > /dev/null
  echo "topic ${THREAD_ID} unpinned (falls back to the \"*\" default)"
else
  if ! openclaw agents list --json | grep -q "\"id\": \"$AGENT_ID\""; then
    echo "unknown agent: $AGENT_ID" >&2
    exit 2
  fi
  openclaw config set "${path}.agentId" "$AGENT_ID" > /dev/null
  echo "topic ${THREAD_ID} -> ${AGENT_ID}"
fi

openclaw config validate > /dev/null
systemctl --user restart openclaw-gateway.service
