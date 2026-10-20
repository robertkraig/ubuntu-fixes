#!/bin/bash
# Called by acpid on any lid event. Read the actual state to decide action.
STATE=$(cat /proc/acpi/button/lid/LID0/state 2>/dev/null | awk '{print $2}')
case "$STATE" in
    closed) exec /usr/local/bin/lid-closed ;;
    open)   exec /usr/local/bin/lid-open ;;
esac
