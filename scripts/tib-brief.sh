#!/usr/bin/env bash
set -euo pipefail

# Canonical TIB checkout lives on the mounted NXT SSD; the projects/tib copy is stale.
tib_dir="${TIB_DIR:-/mnt/nxt-dev/tib}"
downloads="/home/orlovboros/Downloads"

echo "== TIB Git =="
git -C "$tib_dir" status --short --branch || true
echo

echo "== TIB Scripts =="
node -e "const p=require('$tib_dir/package.json'); console.log(JSON.stringify(p.scripts,null,2))"
echo

echo "== Check =="
(cd "$tib_dir" && npm run check)
echo

echo "== Runtime Assets =="
find "$tib_dir/public" -maxdepth 1 -type f -printf '%f\n' | sort
echo

echo "== Recent Downloaded Images =="
find "$downloads" -maxdepth 1 -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
  -mtime -14 -printf '%TY-%Tm-%Td %TH:%TM %f\n' | sort -r | head -40
