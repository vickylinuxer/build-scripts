#!/bin/bash
# Make component build
# Usage: make-build.sh [--install]
#
# Required env: SOURCE_DIR
# Optional env: MAKE_TARGET, MAKE_ARGS, MAKEFILE, INSTALL_TARGET, JOBS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

SOURCE_DIR="${SOURCE_DIR:-.}"
MAKE_TARGET="${MAKE_TARGET:-all}"
MAKE_ARGS="${MAKE_ARGS:-}"
MAKEFILE="${MAKEFILE:-}"
INSTALL_TARGET="${INSTALL_TARGET:-}"
JOBS="${JOBS:-$(nproc)}"
DO_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --install) DO_INSTALL=true; shift ;;
        *) die "Unknown option: $1" ;;
    esac
done

cd "$SOURCE_DIR"

makefile_arg=""
[ -n "$MAKEFILE" ] && makefile_arg="-f ${MAKEFILE}"

log "=== Make Build ==="
log "Target: $MAKE_TARGET"
make ${makefile_arg} -j"${JOBS}" ${MAKE_ARGS} ${MAKE_TARGET}

if $DO_INSTALL && [ -n "$INSTALL_TARGET" ]; then
    log "=== Make Install ==="
    make ${makefile_arg} ${INSTALL_TARGET}
fi

log "=== Build Complete ==="
