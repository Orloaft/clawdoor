#!/usr/bin/env python3
import html
import sys
from pathlib import Path


def main() -> int:
    # Canonical TIB checkout lives on the mounted NXT SSD; the projects/tib copy is stale.
    folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/mnt/nxt-dev/tib/assetsources/inbox")
    folder = folder.expanduser().resolve()
    if not folder.exists():
        print(f"Folder does not exist: {folder}", file=sys.stderr)
        return 1

    images = sorted(
        p for p in folder.rglob("*")
        if p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".gif"}
    )
    out = folder / "contact-sheet.html"
    cards = []
    for img in images:
        rel = img.relative_to(folder)
        cards.append(
            "<figure>"
            f"<img src=\"{html.escape(str(rel))}\" loading=\"lazy\">"
            f"<figcaption>{html.escape(str(rel))}</figcaption>"
            "</figure>"
        )

    doc = f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>TIB Asset Contact Sheet</title>
  <style>
    body {{ margin: 24px; font-family: system-ui, sans-serif; background: #101214; color: #f2f2f2; }}
    h1 {{ font-size: 20px; }}
    .grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 16px; }}
    figure {{ margin: 0; padding: 8px; background: #1b1f23; border: 1px solid #30363d; border-radius: 6px; }}
    img {{ width: 100%; image-rendering: pixelated; background: #0b0d0f; }}
    figcaption {{ margin-top: 8px; font-size: 12px; overflow-wrap: anywhere; color: #c9d1d9; }}
  </style>
</head>
<body>
  <h1>TIB Asset Contact Sheet: {html.escape(str(folder))}</h1>
  <div class="grid">
    {''.join(cards)}
  </div>
</body>
</html>
"""
    out.write_text(doc, encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
