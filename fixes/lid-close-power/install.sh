#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/deploy.sh"

rc=0; reason=$("$DIR/applies.sh") || rc=$?
[ "$rc" -eq 1 ] && { echo "Skipping: $reason"; exit 0; }
[ "$rc" -eq 2 ] && { echo "Already applied: $reason"; exit 0; }

echo "==> Installing lid close power scripts..."
deploy_file "$DIR/lid-closed.sh" /usr/local/bin/lid-closed "" 755
deploy_file "$DIR/lid-open.sh"   /usr/local/bin/lid-open   "" 755

echo "==> Installing udev rule..."
deploy_file "$DIR/99-lid-tlp.rules" /etc/udev/rules.d/99-lid-tlp.rules "" 644
udevadm control --reload-rules

echo "==> Done. Close the lid to test — CPU power will be capped at 15W."
