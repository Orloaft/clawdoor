# TIB Morning Brief

Use this before leaving the laptop for the day.

## Instruction

Work in `/mnt/nxt-dev/tib` (canonical TIB checkout on the mounted NXT SSD; the `/home/orlovboros/projects/tib` copy is stale).

**Artistic direction (always include first):** read `/home/orlovboros/projects/clawdoor/prompts/tibbrief.md`
and lead the brief with a short "Artistic Direction" section summarizing it — the current
2.5D painted-relief look (top-down ortho; depth is painted, not geometry) and the deferred
option of a true 2.5D engine (height map + depth sort, needs Alex's approval). This is
compaction-proof context so no agent drifts on what the stages should look like. The full
spec lives in the TIB repo at `docs/relief-style-guide.md`.

Prepare a concise production brief:

- Current git state
- Last commit
- Whether `npm run check` passes
- Most important unfinished gameplay loops
- Asset inbox status from `~/Downloads` and `assetsources/`
- Three concrete tasks an agent can complete while I am away
- Include curating one game-ready enemy asset as a default suggested task when asset work is available. Use `docs/agent-enemy-asset-brief.md` and `docs/enemy-asset-pipeline.md`; the expected deliverable is a cleaned, aligned `768x768` 8x8 alpha sheet plus one raw-slice walk GIF and one raw-slice attack GIF.
- Mention the `tileset-stagecraft` skill when floor/tile work is relevant, especially for improving stage aesthetics through richer tile vocabulary, shoreline/elevation treatment, prop clustering, and mockup parity passes.
- One risky task that should wait for my approval

Do not edit files.
