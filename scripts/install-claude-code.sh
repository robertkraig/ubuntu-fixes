#!/bin/bash
# Args: $1=ACTUAL_USER $2=USER_HOME
ACTUAL_USER="$1"

command -v claude >/dev/null 2>&1 && { echo "  Claude Code already installed"; exit 0; }

sudo -u "$ACTUAL_USER" npm install -g @anthropic-ai/claude-code
echo "  Claude Code CLI installed"
