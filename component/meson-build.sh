#!/bin/bash
# Meson component build
# Usage: meson-build.sh
#
# Required env: SOURCE_DIR
# Optional env: BUILD_DIR, BUILD_TYPE, CROSS_FILE, SETUP_ARGS, TARGET, JOBS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

SOURCE_DIR="${SOURCE_DIR:-.}"
BUILD_DIR="${BUILD_DIR:-builddir}"
BUILD_TYPE="${BUILD_TYPE:-release}"
CROSS_FILE="${CROSS_FILE:-}"
SETUP_ARGS="${SETUP_ARGS:-}"
TARGET="${TARGET:-}"
JOBS="${JOBS:-$(nproc)}"

cd "$SOURCE_DIR"

log "=== Meson Setup ==="
log "Build type: $BUILD_TYPE"
setup_cmd="meson setup ${BUILD_DIR} --buildtype=${BUILD_TYPE}"
[ -n "$CROSS_FILE" ] && setup_cmd+=" --cross-file=${CROSS_FILE}" && log "Cross file: $CROSS_FILE"
[ -n "$SETUP_ARGS" ] && setup_cmd+=" ${SETUP_ARGS}"
eval $setup_cmd

log "=== Meson Compile ==="
compile_cmd="meson compile -C ${BUILD_DIR} -j${JOBS}"
[ -n "$TARGET" ] && compile_cmd+=" ${TARGET}"
$compile_cmd

log "=== Build Complete ==="
report_size "${BUILD_DIR}" "Build directory"
