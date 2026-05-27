# TIB Feature Task

Use this when asking the Telegram agent to implement gameplay or UI work in
`/home/orlovboros/projects/tib`.

## Instruction

Work in `/home/orlovboros/projects/tib`.

Goal:

```text
PASTE FEATURE GOAL HERE
```

Rules:

- Keep the multiplayer server authoritative.
- Preserve the current lightweight Phaser/Vite/Node architecture.
- Prefer small vertical slices over broad rewrites.
- Update client and server together when gameplay state changes.
- Run `npm run check` before committing.
- Commit directly if the check passes.
- End with: changed files, behavior added, commands run, commit hash, risks.

Good task shape:

```text
Add a simple fishing prototype: interact with water tiles, wait 3 seconds,
roll a fish item, add it to inventory, and show a chat/system message.
```
