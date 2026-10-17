#!/bin/bash
# fixes.sh — Walk through fixes/*/ and run each install.sh, asking first.
# Usage: ./fixes.sh [--list]
# Run as your regular user; sudo is used per fix when needed.
#
# Each fix may have an applies.sh that checks the hardware/software it targets:
#   exit 0 = applies, 1 = not applicable, 2 = already applied (prints the reason)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXES_DIR="$SCRIPT_DIR/fixes"
MIN_UBUNTU="26.04"

# ─── Helpers ──────────────────────────────────────────────────────────────────

info()    { echo -e "\e[34m==>\e[0m $*"; }
success() { echo -e "\e[32m ✓\e[0m $*"; }
warn()    { echo -e "\e[33m  !\e[0m $*"; }
die()     { echo -e "\e[31mERROR:\e[0m $*"; exit 1; }

[ "$EUID" -ne 0 ] || die "Run as your regular user, not with sudo. Each fix asks for sudo if it needs it."

. /etc/os-release
[ "$ID" = "ubuntu" ] || die "These fixes are for Ubuntu (found: $PRETTY_NAME)."
dpkg --compare-versions "$VERSION_ID" ge "$MIN_UBUNTU" \
    || die "These fixes need Ubuntu $MIN_UBUNTU or newer (found: $VERSION_ID)."

# Title from the README's first heading, minus the "Fix: " prefix
fix_title() {
    head -1 "$1/README.md" 2>/dev/null | sed -e 's/^# *//' -e 's/^Fix: *//'
}

# Fixes marked "# Run as your regular user" (they edit $HOME or call sudo themselves)
runs_as_user() {
    grep -q '^# Run as your regular user' "$1/install.sh"
}

# Sets APPLIES (0/1/2) and REASON from the fix's applies.sh; no applies.sh = applies
check_applies() {
    APPLIES=0; REASON="no applies.sh, assuming it applies"
    [ -f "$1/applies.sh" ] || return
    REASON=$(bash "$1/applies.sh" 2>&1) || APPLIES=$?
    [ "$APPLIES" -gt 2 ] && APPLIES=1
}

# ─── List mode ────────────────────────────────────────────────────────────────

if [ "$1" = "--list" ]; then
    info "$PRETTY_NAME, $(uname -m), checking fixes..."
    for dir in "$FIXES_DIR"/*/; do
        dir=${dir%/}
        [ -f "$dir/install.sh" ] || continue
        check_applies "$dir"
        case $APPLIES in 0) mark="→";; 1) mark="✗";; 2) mark="✓";; esac
        printf "  %s %-24s %s\n" "$mark" "$(basename "$dir")" "$REASON"
    done
    echo "  → applies   ✓ already applied   ✗ not applicable"
    exit 0
fi

# ─── Run ──────────────────────────────────────────────────────────────────────

info "$PRETTY_NAME, $(uname -m)"
ran=(); skipped=(); failed=()

for dir in "$FIXES_DIR"/*/; do
    dir=${dir%/}
    name=$(basename "$dir")
    [ -f "$dir/install.sh" ] || continue

    echo
    info "$name — $(fix_title "$dir")"

    check_applies "$dir"
    case $APPLIES in
        0) echo "    applies: $REASON"; default="y" ;;
        1) warn "not applicable: $REASON"; default="n" ;;
        2) success "already applied: $REASON"; default="n" ;;
    esac
    runs_as_user "$dir" && echo "    runs as: $USER" || echo "    runs as: root (sudo)"

    while true; do
        if [ "$default" = "y" ]; then prompt="[Y/n/r=readme/q=quit]"; else prompt="[y/N/r=readme/q=quit]"; fi
        read -rp "    Run this fix? $prompt " answer
        answer=${answer:-$default}
        case "${answer,,}" in
            y|yes)
                if runs_as_user "$dir"; then
                    (cd "$dir" && bash ./install.sh)
                else
                    (cd "$dir" && sudo bash ./install.sh)
                fi
                if [ $? -eq 0 ]; then success "$name"; ran+=("$name")
                else warn "$name failed"; failed+=("$name"); fi
                break ;;
            n|no) skipped+=("$name"); break ;;
            r|readme) ${PAGER:-less} "$dir/README.md" ;;
            q|quit) break 2 ;;
            *) echo "    Please answer y, n, r or q." ;;
        esac
    done
done

# ─── Summary ──────────────────────────────────────────────────────────────────

echo
info "Summary"
[ ${#ran[@]} -gt 0 ]     && success "ran:     ${ran[*]}"
[ ${#skipped[@]} -gt 0 ] && echo "    skipped: ${skipped[*]}"
[ ${#failed[@]} -gt 0 ]  && warn "failed:  ${failed[*]}"
[ ${#failed[@]} -eq 0 ]
