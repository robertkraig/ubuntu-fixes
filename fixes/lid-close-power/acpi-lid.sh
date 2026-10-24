#!/bin/bash
# Called by acpid on any lid event. Read the actual state to decide action.

# Log everything to the journal: journalctl -t ubuntu-fixes/acpi-lid
exec > >(logger -t ubuntu-fixes/acpi-lid) 2>&1

# Lid device name varies (LID0, LID, LID1)
STATE=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2; exit}')
echo "event: $*, lid $STATE"
case "$STATE" in
    closed) exec /usr/local/bin/lid-closed ;;
    open)   exec /usr/local/bin/lid-open ;;
    *)      echo "unknown lid state, doing nothing" ;;
esac
