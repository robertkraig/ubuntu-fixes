#!/bin/bash
# Shared helpers for fix install/applies scripts.

# render_template SRC KEY=VALUE [KEY=VALUE ...]
# Reads SRC, substitutes __KEY__ tokens, prints rendered content.
render_template() {
    local src="$1"; shift
    local content
    content=$(cat "$src")
    for kv in "$@"; do
        local key="${kv%%=*}"
        local val="${kv#*=}"
        content="${content//__${key}__/$val}"
    done
    echo "$content"
}

# deployed_and_current SRC DST KEY=VALUE [...]
# Returns 0 if DST exists and its content matches rendering SRC with substitutions.
# Returns 1 if DST is missing or stale.
deployed_and_current() {
    local src="$1" dst="$2"; shift 2
    [ -f "$dst" ] || return 1
    local rendered
    rendered=$(render_template "$src" "$@")
    local src_hash dst_hash
    src_hash=$(echo "$rendered" | sha256sum | cut -d' ' -f1)
    dst_hash=$(sha256sum "$dst" | cut -d' ' -f1)
    [ "$src_hash" = "$dst_hash" ]
}

# deploy_template SRC DST OWNER KEY=VALUE [...]
# Renders SRC with substitutions and writes to DST with given owner.
deploy_template() {
    local src="$1" dst="$2" owner="$3"; shift 3
    render_template "$src" "$@" > "$dst"
    [ -n "$owner" ] && chown "$owner:" "$dst" 2>/dev/null || true
    chmod 644 "$dst"
}

# deploy_file SRC DST OWNER [MODE]
# Copies SRC to DST verbatim, sets owner and optional mode.
deploy_file() {
    local src="$1" dst="$2" owner="$3" mode="${4:-755}"
    install -D -m "$mode" "$src" "$dst"
    [ -n "$owner" ] && chown "$owner:" "$dst" 2>/dev/null || true
}

# file_current SRC DST
# Returns 0 if DST exists and sha256 matches SRC exactly (no substitution).
file_current() {
    local src="$1" dst="$2"
    [ -f "$dst" ] || return 1
    [ "$(sha256sum "$src" | cut -d' ' -f1)" = "$(sha256sum "$dst" | cut -d' ' -f1)" ]
}
