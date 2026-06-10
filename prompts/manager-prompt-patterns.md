# Prompt Pattern Library

This is the manager's working library for distilling Alex's rough, on-the-go
ideas into well-scoped worker prompts. It is a living document: after every
delegation, record what the worker misunderstood or got right in the Lessons
section, and fold recurring lessons back into the patterns.

The full delegation skeleton lives in `manager-delegation-template.md`. The
patterns below are pre-filled variants of it for the common task shapes.

## How to distill a rough idea

1. Identify the task shape (feature, bug, review, research, assets, ops).
2. Pick the matching pattern; fill every slot. If a slot can't be filled from
   Alex's message, that's the clarifying question to ask — ask at most two.
3. State the repo path explicitly and require `pwd` verification (anti-drift).
4. Always end the worker prompt with a Return block — workers without an
   explicit return format ramble and bury the result.

## Patterns

### Feature slice (codex-dev)

For: "add X to the game/app". The unit of work is one vertical slice that can
be implemented, checked, and committed without manual playtesting.

- Goal: one slice, named concretely ("a Frost Nova spell castable from the
  hotbar", not "spell system improvements").
- Scope: list the layers the slice touches end to end (data, logic, UI,
  persistence) and say "nothing else".
- Verification: the project's check command must pass; commit directly.
- Watch for: slices that secretly require live playtesting — those are
  at-laptop tasks, push back instead of delegating.

### Bug hunt (codex-dev)

For: "X is broken / behaves weirdly".

- Goal: reproduce first, then fix. Require the repro evidence in the Return.
- Scope: fix the root cause; no drive-by refactors.
- Verification: the repro no longer occurs + checks pass.
- Watch for: symptom descriptions from memory — have the worker confirm the
  symptom exists before fixing anything.

### Review / second opinion (opus-main, deliberate escalation)

For: "is this approach right", "review the last change".

- Goal: a judgment with reasons, not a rewrite. State "do not edit files".
- Context: the exact commit range or design question.
- Return: top findings ranked by severity, each with file:line and a concrete
  suggested action.
- Watch for: burning Opus turns on questions codex-dev can answer; escalate
  only for architecture, risk, or taste.

### Research / design sketch (opus-main)

For: "how should I approach X", "compare options for Y".

- Goal: a recommendation with trade-offs, sized to a phone screen.
- Return: recommendation first, then at most three alternatives with one-line
  reasons for rejection.

### Asset curation (ops)

For: "process the new images".

- Goal: ingest → contact sheet → selected/rejected split → import-ready files.
- Safety: never delete from `~/Downloads`; follow the TIB asset policy paths.

## Lessons

Append dated entries after each delegation. Format:
`- YYYY-MM-DD <worker>: <what went wrong/right> -> <pattern change made>`

- 2026-06-09 (seed): workers lose the active repo on compaction and drift to
  TIB -> every prompt and every follow-up restates the repo path and requires
  `pwd` + `git rev-parse --show-toplevel` before acting.
