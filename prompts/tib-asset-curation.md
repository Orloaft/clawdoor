# TIB Asset Curation Task

Use this when asking the Telegram agent to process generated images from
`~/Downloads` into import-ready candidates for TIB.

## Instruction

Work in `/mnt/nxt-dev/tib` (canonical TIB checkout on the mounted NXT SSD; the
`/home/orlovboros/projects/tib` copy is stale).

Work with:

- Source downloads: `/home/orlovboros/Downloads`
- Project: `/mnt/nxt-dev/tib`
- Asset sources: `/mnt/nxt-dev/tib/assetsources`
- Runtime assets: `/mnt/nxt-dev/tib/public`

Goal:

```text
PASTE ASSET GOAL HERE
```

Rules:

- Never delete originals from `~/Downloads`.
- Copy source images into `assetsources/inbox/YYYY-MM-DD/`.
- Select useful candidates into `assetsources/selected/`.
- Put rejected candidates into `assetsources/rejected/` only by copy or move from
  project inbox, never from Downloads.
- Create a short `asset-review.md` explaining selection decisions.
- For import-ready output, use lowercase hyphenated filenames.
- Keep `public/` for game-ready files only.
- If slicing/spritesheeting is needed, explain the target tile size/frame size
  before changing runtime assets.
- Commit direct changes when done.

End with:

- Source images considered
- Selected assets
- Rejected assets
- Files placed in `public/`
- Any manual art decisions still needed
