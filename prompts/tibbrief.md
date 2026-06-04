# TIB Artistic Direction — Brief Anchor

**Purpose:** durable, compaction-proof statement of TIB's stage art direction. The morning
brief MUST surface this so that aggressive mid-session context compaction never causes an
agent to hallucinate or drift from the agreed direction. If unsure what the look "should be,"
this file is the authority. Last updated: 2026-06-04 (Alex confirmed the direction).

## Current artistic direction: 2.5D painted-relief (top-down ortho)

- The engine renders **top-down orthogonal**, NOT isometric. The stage look is **2.5D
  painted relief** — depth is a *lighting illusion* (lit plateau tops, sun-catch rims,
  ribbed faces painted up from the lip, strata-bench terraces, foot contact-shadows),
  **never real geometry**. Collision/reachability stay flat tile-based.
- **Why this matters / how we got here:** parity kept failing because the image-gen mockups
  were assembled in **3/4 isometric — the wrong camera**. The engine can't produce that.
  The fix (Alex's call, 2026-06-04): bend the art language to the engine, not vice versa.
  **Mockups are palette/content/mood references, NOT camera or geometry targets.**
- Proven on **floor 6 (Searing Badlands)**: lit mesa tops + rim + organic cliffs + meandering
  teal river + multi-tier strata terraces. Branch `northwood-visual-parity` on
  `Orloaft/slopquest`. Full spec: `docs/relief-style-guide.md` in the TIB repo.
- **Northwood (floor 3)** is the finished-stage quality bar to match.

## The hard limit to keep stating

There is **no per-entity depth/height sort** — characters/props draw flat on top. So the
current style is **terrain-relief ONLY**: cliffs/terraces/water are fine; characters
standing on / occluded by ledges, or elevation affecting gameplay, are NOT supported.

## Open option: a true 2.5D engine (future, needs Alex's approval)

Going beyond painted relief to **real** 2.5D is on the table but is an **engine project**, not
a style pass. It would require: a per-tile **height map**, **depth sorting** of entities vs
terrain, and probably **taller sprites/tiles**. Big investment; explicitly deferred. Do NOT
start it without Alex's go-ahead — surface it as the "risky task that waits for approval."
