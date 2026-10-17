#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/memory"
DEST="$HOME/.claude/projects/$(echo "$HOME" | tr '/' '-')/memory"

missing=0
for f in "$SRC"/*.md; do
    [ "$(basename "$f")" = "MEMORY.md" ] && continue
    [ -f "$DEST/$(basename "$f")" ] || missing=$((missing + 1))
done

[ "$missing" -eq 0 ] && { echo "already installed"; exit 2; }
echo "$missing memory file(s) not installed yet"
exit 0
