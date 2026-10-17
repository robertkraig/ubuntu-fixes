#!/bin/bash
# Exit 0 = applies, 1 = not applicable, 2 = already applied. Prints the reason.

systemctl list-unit-files docker.service >/dev/null 2>&1 \
    && systemctl cat docker.service >/dev/null 2>&1 || { echo "Docker not installed"; exit 1; }

if ! systemctl is-enabled docker.service docker.socket >/dev/null 2>&1 \
    && ! systemctl is-enabled containerd.service >/dev/null 2>&1; then
    echo "already applied: docker, docker.socket and containerd disabled at boot"
    exit 2
fi

echo "Docker starts at boot"
exit 0
