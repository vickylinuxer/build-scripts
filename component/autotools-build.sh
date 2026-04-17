#!/bin/bash
# Autotools component build
# Usage: autotools-build.sh [--autoreconf]
#
# Required env: SOURCE_DIR
# Optional env: CONFIGURE_ARGS, MAKE_ARGS, MAKE_TARGET, INSTALL_PREFIX, JOBS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

SOURCE_DIR="${SOURCE_DIR:-.}"
CONFIGURE_ARGS="${CONFIGURE_ARGS:-}"
MAKE_ARGS="${MAKE_ARGS:-}"
MAKE_TARGET="${MAKE_TARGET:-all}"
INSTALL_PREFIX="${INSTALL_PREFIX:-}"
JOBS="${JOBS:-$(nproc)}"
DO_AUTORECONF=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --autoreconf) DO_AUTORECONF=true; shift ;;
        *) die "Unknown option: $1" ;;
    esac
done

cd "$SOURCE_DIR"

if $DO_AUTORECONF; then
    log "=== Autoreconf ==="
    autoreconf -fi
fi

log "=== Configure ==="
configure_cmd="./configure ${CONFIGURE_ARGS}"
[ -n "$INSTALL_PREFIX" ] && configure_cmd+=" --prefix=${INSTALL_PREFIX}"
eval $configure_cmd

log "=== Build ==="
make -j"${JOBS}" ${MAKE_ARGS} ${MAKE_TARGET}

log "=== Build Complete ==="
