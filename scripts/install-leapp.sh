#!/bin/bash
# Leapp by Noovolari — cloud credentials manager
# https://github.com/Noovolari/leapp
# Binaries are not on GitHub releases. Download the .deb from the Leapp website.

dpkg -l leapp 2>/dev/null | grep -q "^ii" && { echo "  Leapp already installed"; exit 0; }

# TODO: replace with direct .deb URL once known
# Typical pattern: https://asset.noovolari.com/latest/Leapp-<version>.deb
# or check: https://docs.leapp.cloud/latest/installation/install-leapp/

echo "  Leapp must be installed manually:"
echo "  1. Visit https://www.leapp.cloud/releases"
echo "  2. Download the Linux .deb package"
echo "  3. Run: sudo dpkg -i Leapp-*.deb"
