#!/bin/bash
# Run as your regular user, not root.
set -e

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/memory"
# Claude Code keys project memory by the working directory, with / replaced by -
DEST="$HOME/.claude/projects/$(echo "$HOME" | tr '/' '-')/memory"

echo "==> Installing Claude Code memories to $DEST..."
mkdir -p "$DEST"

for f in "$SRC"/*.md; do
    name=$(basename "$f")
    [ "$name" = "MEMORY.md" ] && continue
    if [ -f "$DEST/$name" ]; then
        echo "  skip (exists): $name"
    else
        cp "$f" "$DEST/$name"
        echo "  added: $name"
    fi
done

echo "==> Merging MEMORY.md index..."
touch "$DEST/MEMORY.md"
while IFS= read -r line; do
    [ -z "$line" ] && continue
    grep -qxF "$line" "$DEST/MEMORY.md" || echo "$line" >> "$DEST/MEMORY.md"
done < "$SRC/MEMORY.md"

echo "==> Done. New Claude Code sessions in $HOME will load these memories."
