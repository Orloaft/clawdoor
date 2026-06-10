# Manager Agent Workflow

This document captures the safe-prep path for adding a Telegram-facing manager
agent without cutting over the live Telegram route.

## Intended Architecture

- `manager`: Telegram-facing planner/orchestrator.
- `codex-dev`: implementation worker for code, shell, repo inspection, tests,
  and file edits.
- `opus-main`: judgment worker for architecture, critique, review, and synthesis.

The manager receives Alex's rough goal, asks clarifying questions when needed,
delegates internally, reviews the worker result, follows up if needed, and
reports a concise status back to Alex.

## Safe Prep

These steps are safe while away from the laptop because they do not change the
existing Telegram bindings:

```bash
./scripts/setup-manager-agent.sh
./scripts/telegram-agent status
openclaw agents list --bindings
```

Expected bindings after safe prep:

- default Telegram account -> `codex-dev`
- `opus-telegram` account -> `opus-main`
- `manager` has no Telegram binding yet

## Internal Test

After setup, run a non-delivering manager turn:

```bash
./scripts/manager-test.sh
```

This sends a short prompt to `manager` with a stable test session key. It should
not post to Telegram because it does not use `--deliver`.

## Cutover: Inbox topic, not account rebind (revised 2026-06-09)

The original plan rebound the default Telegram account to `manager`, making it
a mandatory middleman on every message. The forum-topics workspace makes that
unnecessary: bind the manager to **one topic** ("Inbox") and it becomes
opt-in — rough ideas go to Inbox, direct commands go to the specialists'
topics. The DM lanes and `telegram-agent` toggle stay untouched, so there is
nothing to roll back.

1. Set up the forum group: `scripts/setup-forum-group.sh <chatId>` (see
   README "Phone Workflow" for the phone-side steps).
2. Create an "Inbox" topic from the phone; grab its threadId via "Copy Link"
   on any message in it (`t.me/c/<chat>/<threadId>/<msgId>`).
3. Pin it: `scripts/topic-route.sh <chatId> <threadId> manager`.
4. Send a rough idea to Inbox; the manager should distill it using
   `prompt-patterns.md` (in its workspace), delegate, and report back.

Undo: `scripts/topic-route.sh <chatId> <threadId> --unset`.

## Prompt-Pattern Learning Loop

The manager's workspace carries `prompt-patterns.md` (seeded from
[prompts/manager-prompt-patterns.md](../prompts/manager-prompt-patterns.md)).
Its system prompt instructs it to append a dated lesson after every
delegation and fold recurring lessons back into the patterns. Re-running
`scripts/setup-manager-agent.sh` refreshes `AGENTS.md` but never overwrites
the working `prompt-patterns.md` (the accumulated lessons are the point).

The loop is closed by three mechanisms (added 2026-06-10):

- **Consolidation trigger:** the manager workspace `HEARTBEAT.md` tells the
  manager to fold and prune the Lessons section once it grows past ~10
  entries, instead of relying on it doing maintenance mid-task.
- **Version history:** the manager workspace is its own git repo (deliberately
  separate from clawdoor — it is live agent state, not tooling). The manager
  commits before and after every fold/prune so accumulated lessons survive a
  bad rewrite.
- **Upstreaming:** the manager flags lessons that generalize in its reports;
  Alex (or a delegated worker) copies them into the seed file here. The
  working copy and the seed are expected to diverge — only generalized rules
  flow back.

