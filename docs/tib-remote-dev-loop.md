# TIB Remote Development Loop

TIB is the first optimized target for the phone-controlled OpenClaw workflow.

## Default Lanes

- `codex-dev`: implement features, run checks, commit direct changes.
- `claude-review`: use Opus for architecture, risk, performance, and game-design review.
- `ops`: run builds, checks, repo summaries, and asset-processing scripts.

## First Safety Fix

Before heavy agent work, make `/home/orlovboros/projects/tib` its own git repo.
Right now `git -C /home/orlovboros/projects/tib` resolves to
`/home/orlovboros/projects`, which makes sibling projects appear as untracked
files. That is too noisy for autonomous commits.

Recommended command:

```bash
cd /home/orlovboros/projects/tib
git init
git add README.md package.json package-lock.json src server public data assetsources
git commit -m "Initial TIB project snapshot"
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
