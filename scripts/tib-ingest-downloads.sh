#!/usr/bin/env bash
set -euo pipefail

days="${1:-14}"
date_stamp="$(date +%F)"
downloads="/home/orlovboros/Downloads"
tib_dir="/home/orlovboros/projects/tib"
dest="$tib_dir/assetsources/inbox/$date_stamp"
manifest="$dest/manifest.tsv"

mkdir -p "$dest"
printf 'source\tcopy\n' > "$manifest"

count=0
while IFS= read -r -d '' src; do
  base="$(basename "$src")"
  ext="${base##*.}"
  stem="${base%.*}"
  clean="$(printf '%s' "$stem" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
  target="$dest/${clean}.${ext,,}"
  n=1
  while [[ -e "$target" ]]; do
    target="$dest/${clean}-${n}.${ext,,}"
    n=$((n + 1))
  done
  cp -p "$src" "$target"
  printf '%s\t%s\n' "$src" "$target" >> "$manifest"
  count=$((count + 1))
done < <(
  find "$downloads" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    -mtime "-$days" -print0
)

echo "Copied $count image(s) into $dest"
echo "Manifest: $manifest"
