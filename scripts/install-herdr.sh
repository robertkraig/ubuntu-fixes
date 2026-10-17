#!/bin/bash
# Args: $1=ACTUAL_USER $2=USER_HOME
ACTUAL_USER="$1"
USER_HOME="$2"
HERDR_BIN="$USER_HOME/.local/bin/herdr"

[ -f "$HERDR_BIN" ] && { echo "  herdr already installed at $HERDR_BIN"; exit 0; }

# Try GitHub releases first
HERDR_URL=$(curl -fsSL https://api.github.com/repos/herdr-io/herdr/releases/latest 2>/dev/null \
    | grep "browser_download_url.*linux.*x86_64" \
    | grep -v ".sha\|.asc" \
    | cut -d '"' -f 4 | head -1)

if [ -z "$HERDR_URL" ]; then
    echo "  WARNING: Could not find herdr release. Install manually from herdr.io"
    exit 0
fi

mkdir -p "$USER_HOME/.local/bin"
curl -fsSL "$HERDR_URL" -o "$HERDR_BIN"
chmod +x "$HERDR_BIN"
chown "$ACTUAL_USER:$ACTUAL_USER" "$HERDR_BIN"
echo "  herdr installed to $HERDR_BIN"
