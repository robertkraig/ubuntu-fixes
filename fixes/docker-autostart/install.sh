#!/bin/bash
# Run as your regular user, not root (edits your shell rc, uses sudo itself).
set -e

SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    echo "ERROR: Could not find .zshrc or .bashrc"
    exit 1
fi

echo "==> Disabling Docker autostart..."
sudo systemctl disable docker docker.socket containerd

echo "==> Stopping Docker if running..."
sudo systemctl stop docker docker.socket containerd 2>/dev/null || true

# Clear restart policies if Docker is accessible
if sudo docker ps -q 2>/dev/null | grep -q .; then
    echo "==> Clearing container restart policies..."
    sudo docker update --restart=no $(sudo docker ps -aq)
fi

# Add aliases if not already present
if ! grep -q "docker-start" "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "alias docker-start='sudo systemctl start docker docker.socket containerd && echo \"Docker started\"'" >> "$SHELL_RC"
    echo "alias docker-stop='sudo systemctl stop docker docker.socket containerd && echo \"Docker stopped\"'" >> "$SHELL_RC"
    echo "==> Added docker-start / docker-stop aliases to $SHELL_RC"
else
    echo "==> Aliases already present in $SHELL_RC"
fi

echo "==> Done. Docker will not start at boot."
echo "    Use 'docker-start' / 'docker-stop' to toggle it."
echo "    Run: source $SHELL_RC"
