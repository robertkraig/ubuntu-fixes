#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied.

# Only makes sense on systems with NVMe/SSD
ls /sys/block/nvme* >/dev/null 2>&1 || { echo "no NVMe drives found"; exit 1; }

stale=()

# Check noatime on ext4 mounts
while read -r uuid mp fstype opts _rest; do
    [[ "$fstype" == ext4 ]] || continue
    [[ "$opts" == *noatime* ]] || stale+=("noatime missing on $mp")
done < <(grep -vE '^\s*(#|$)' /etc/fstab)

# Check zram
zramctl 2>/dev/null | grep -q zram || stale+=("zram not active")

[ ${#stale[@]} -eq 0 ] && { echo "already applied"; exit 2; }
echo "${stale[*]}"
exit 0
