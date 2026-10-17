#!/bin/bash
# Args: $1=ACTUAL_USER $2=USER_HOME
NVIM_DIR="/opt/nvim"

[ -f "$NVIM_DIR/bin/nvim" ] && { echo "  Neovim already installed"; exit 0; }

NVIM_URL=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest \
    | grep "browser_download_url.*nvim-linux-x86_64.tar.gz" \
    | cut -d '"' -f 4)

curl -fsSL "$NVIM_URL" -o /tmp/nvim.tar.gz
mkdir -p "$NVIM_DIR"
tar -xzf /tmp/nvim.tar.gz -C "$NVIM_DIR" --strip-components=1
rm /tmp/nvim.tar.gz

echo "  Neovim installed to $NVIM_DIR/bin/nvim"
echo "  Ensure PATH includes /opt/nvim/bin"
echo "  LazyVim: https://lazyvim.org"
