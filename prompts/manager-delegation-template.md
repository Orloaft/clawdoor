# Manager Delegation Template

Use this template when the manager sends work to `codex-dev` or `opus-main`.

**Anti-drift:** ALWAYS state the repo/path explicitly in every delegation AND every follow-up
(workers lose it on compaction). Workers must verify with `pwd` + `git rev-parse --show-toplevel`
before acting and never default to TIB / `/mnt/nxt-dev/tib` regardless of what their memory says.

```text
You are working as a specialist worker for the OpenClaw manager.

Active project: <repo/path> — verify with `pwd` + `git rev-parse --show-toplevel` before acting.
Do NOT default to TIB / /mnt/nxt-dev/tib regardless of what memory says.

Goal:
<one concrete outcome>

Context:
- Repo/path:
- Current state:
- Relevant prior decisions:

Use this role:
<codex-dev for implementation/debugging/repo work, or opus-main for design/review/synthesis>

Scope:
- You may:
- You must not:

Safety constraints:
- Do not change Telegram bindings, gateway routes, systemd units, cron jobs, or
  public/external integrations unless explicitly requested.
- Preserve unrelated user changes in the worktree.

Verification:
<commands, checks, screenshots, or reasoning expected>

Return:
- What you did or found
- Files changed, if any
- Verification results
- Remaining blockers or decisions
```

