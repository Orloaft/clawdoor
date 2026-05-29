# TIB Remote Development Loop

TIB is the first optimized target for the phone-controlled OpenClaw workflow.

## Default Lanes

- `codex-dev`: implement features, run checks, commit direct changes.
- `claude-review`: use Opus for architecture, risk, performance, and game-design review.
- `ops`: run builds, checks, repo summaries, and asset-processing scripts.

## Canonical Checkout

All TIB work happens in `/mnt/nxt-dev/tib`, the canonical checkout on the
mounted NXT SSD. The `/home/orlovboros/projects/tib` copy is stale — do not
work there. `/mnt/nxt-dev/tib` is its own git repo, so `git -C /mnt/nxt-dev/tib`
resolves correctly and autonomous commits stay clean.

Scripts default to this path and honor a `TIB_DIR` override:

```bash
TIB_DIR=/mnt/nxt-dev/tib clawdoor/scripts/tib-brief.sh
```

## Daily Loop

Before leaving:

```text
Use /home/orlovboros/projects/clawdoor/prompts/tib-morning-brief.md for TIB.
```

During the day:

```text
Use the TIB feature template. Add a small vertical slice for [feature].
Run checks and commit directly.
```

For generated images:

```text
Run clawdoor/scripts/tib-ingest-downloads.sh, make a contact sheet, curate the
best assets for [purpose], and prepare import-ready files for TIB.
```

For review:

```text
Ask claude-review with the TIB Opus review template to inspect the latest TIB
commit. Do not edit files.
```

When home:

```text
Use /home/orlovboros/projects/clawdoor/prompts/tib-evening-summary.md for TIB.
```

## Asset Policy

- `~/Downloads`: original generated files; never delete.
- `assetsources/inbox/YYYY-MM-DD`: copied intake from Downloads.
- `assetsources/selected`: promising source files.
- `assetsources/rejected`: rejected project-local copies.
- `public`: runtime-ready files only.
- Runtime filenames should be lowercase hyphenated names.

## Good Away-From-Laptop Tasks

- Add one spell, item, monster, NPC, vendor feature, or map interaction.
- Improve one UI panel.
- Add one persistence field end to end.
- Curate a batch of generated images into selected/rejected/import-ready.
- Run Opus review on the latest gameplay change.

## Avoid While Away

- Large networking rewrites.
- Persistence migrations.
- Deleting assets.
- Replacing core map/entity abstractions.
- Any feature that needs live manual playtesting before commit.
