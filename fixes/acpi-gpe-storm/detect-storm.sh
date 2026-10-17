#!/bin/bash
# Prints "<hex> <rate>/s" for each ACPI GPE firing more than THRESHOLD times/sec.
# Usage: detect-storm.sh [seconds] [threshold]
SECONDS_TO_SAMPLE=${1:-3}
THRESHOLD=${2:-100}
IRQ_DIR=/sys/firmware/acpi/interrupts

[ -d "$IRQ_DIR" ] || exit 0

snapshot() {
    for f in "$IRQ_DIR"/gpe[0-9A-F][0-9A-F]; do
        echo "$(basename "$f") $(awk '{print $1}' "$f")"
    done
}

before=$(snapshot)
sleep "$SECONDS_TO_SAMPLE"
after=$(snapshot)

join <(echo "$before") <(echo "$after") | while read -r name a b; do
    rate=$(( (b - a) / SECONDS_TO_SAMPLE ))
    [ "$rate" -gt "$THRESHOLD" ] && echo "${name#gpe} $rate"
done
exit 0
