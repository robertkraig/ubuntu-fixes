#!/bin/bash
dpkg -l zoom 2>/dev/null | grep -q "^ii" && { echo "  Zoom already installed"; exit 0; }

curl -fsSL "https://zoom.us/client/latest/zoom_amd64.deb" -o /tmp/zoom.deb
apt-get install -y /tmp/zoom.deb
rm /tmp/zoom.deb
echo "  Zoom installed"
