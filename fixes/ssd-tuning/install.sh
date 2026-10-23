#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../lib/deploy.sh"

rc=0; reason=$("$DIR/applies.sh") || rc=$?
[ "$rc" -eq 1 ] && { echo "Skipping: $reason"; exit 0; }
[ "$rc" -eq 2 ] && { echo "Already applied: $reason"; exit 0; }

# Add noatime to all ext4 mounts in /etc/fstab that don't have it
echo "==> Adding noatime to ext4 mounts in /etc/fstab..."
cp /etc/fstab /etc/fstab.bak
# For each ext4 line without noatime, insert noatime after the options field
sed -i -E '/ext4/ s/(UUID=[^ ]+[[:space:]]+[^ ]+[[:space:]]+ext4[[:space:]]+)([^ ]*noatime[^ ]*)/\1\2/; /ext4/ { /noatime/! s/(UUID=[^ ]+[[:space:]]+[^ ]+[[:space:]]+ext4[[:space:]]+)([^ ]+)/\1noatime,\2/ }' /etc/fstab
echo "    /etc/fstab updated (backup at /etc/fstab.bak)"
grep ext4 /etc/fstab | sed 's/^/    /'

# Remount to apply noatime without reboot
echo "==> Remounting filesystems with noatime..."
while read -r uuid mp fstype opts _rest; do
    [[ "$fstype" == ext4 ]] || continue
    [[ "$mp" == "/" ]] && { mount -o remount,noatime / && echo "    remounted /"; continue; }
    mount -o remount,noatime "$mp" 2>/dev/null && echo "    remounted $mp" || echo "    skipped $mp (may need reboot)"
done < <(grep -vE '^\s*(#|$)' /etc/fstab)

# Enable zram
echo "==> Enabling zram..."
if ! dpkg -l zram-config 2>/dev/null | grep -q '^ii'; then
    apt install -y zram-config
fi
systemctl enable --now zram-config 2>/dev/null || true
# Ubuntu 22.04+ uses systemd-zram-setup
if systemctl list-units --all | grep -q zram-setup; then
    systemctl enable --now systemd-zram-setup@zram0 2>/dev/null || true
fi
zramctl 2>/dev/null || echo "    zram will be active after reboot"

echo "==> Done. noatime reduces SSD writes; zram compresses memory before hitting swap."
