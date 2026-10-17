#!/bin/bash
# Copy this machine's current Claude Code memories back into the repo.
set -e

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/memory"
SRC="$HOME/.claude/projects/$(echo "$HOME" | tr '/' '-')/memory"

[ -d "$SRC" ] || { echo "ERROR: No memories found at $SRC"; exit 1; }

echo "==> Saving memories from $SRC..."
mkdir -p "$DEST"
cp "$SRC"/*.md "$DEST/"

echo "==> Done. Review and commit:"
echo "    git -C \"$(dirname "$DEST")\" status"
