#!/usr/bin/env bash
# Configure a Telegram forum supergroup as the parallel-sessions workspace.
#
# Each forum topic gets its own isolated OpenClaw session
# (agent:<id>:telegram:group:<chatId>:topic:<threadId>), so creating a new
# topic from the phone = spawning a new parallel session. Unmatched topics
# fall through the "*" wildcard to the default agent; pin specific topics to
# other agents with scripts/topic-route.sh.
#
# Usage:
#   scripts/setup-forum-group.sh <chatId> [defaultAgent]
#
# Find <chatId> after adding the bot to the group:
#   openclaw directory groups list --channel telegram
# Forum supergroup IDs look like -100xxxxxxxxxx.
set -euo pipefail

CHAT_ID="${1:-}"
DEFAULT_AGENT="${2:-codex-dev}"

if [[ ! "$CHAT_ID" =~ ^-100[0-9]+$ ]]; then
  echo "usage: $(basename "$0") <chatId> [defaultAgent]" >&2
  echo "chatId must be a supergroup id like -1001234567890" >&2
  exit 2
fi

if ! openclaw agents list --json | grep -q "\"id\": \"$DEFAULT_AGENT\""; then
  echo "unknown agent: $DEFAULT_AGENT" >&2
  exit 2
fi

base="channels.telegram.accounts.default.groups.${CHAT_ID}"

# In a private 1-person workspace group, requiring @-mentions on every
# message defeats the purpose (the account-wide groups."*" default is
# requireMention=true, so other groups keep mention-gating).
openclaw config set "${base}.requireMention" false --json > /dev/null
openclaw config set "${base}.topics.*.agentId" "$DEFAULT_AGENT" > /dev/null
openclaw config validate > /dev/null

systemctl --user restart openclaw-gateway.service
sleep 2

cat <<MSG
Forum group ${CHAT_ID} configured:
  - every topic = its own isolated session
  - unmatched topics -> ${DEFAULT_AGENT}
  - requireMention off for this group

Pin a topic to a specific agent (get threadId from "Copy Link" on any
message in the topic — t.me/c/<chat>/<threadId>/<msgId>):
  scripts/topic-route.sh ${CHAT_ID} <threadId> <agentId>

Smoke test: create two topics from the phone, send a different question in
each, confirm answers don't bleed across topics.
MSG
