# TIB Opus Review

Use this to ask the Claude Opus lane to review a Codex change.

## Instruction

Review the latest TIB changes in `/mnt/nxt-dev/tib` (canonical TIB checkout on
the mounted NXT SSD; the `/home/orlovboros/projects/tib` copy is stale).

Focus on:

- MMO server authority and cheating risks
- Performance issues for multiple players
- Gameplay clarity for friends joining casually
- Asset/style consistency
- Bugs introduced by client/server state drift
- Missing tests or checks

Do not edit files unless explicitly asked.

Return:

- Findings ordered by severity
- Specific file references
- Suggested fix strategy
- Whether the change is safe to keep
