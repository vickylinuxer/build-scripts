#!/bin/bash
# CMake component build
# Usage: cmake-build.sh [--install]
#
# Required env: SOURCE_DIR
# Optional env: BUILD_DIR, BUILD_TYPE, TOOLCHAIN_FILE, CMAKE_ARGS,
#               INSTALL_PREFIX, GENERATOR, TARGET, JOBS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

SOURCE_DIR="${SOURCE_DIR:-.}"
BUILD_DIR="${BUILD_DIR:-build}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
TOOLCHAIN_FILE="${TOOLCHAIN_FILE:-}"
CMAKE_ARGS="${CMAKE_ARGS:-}"
INSTALL_PREFIX="${INSTALL_PREFIX:-}"
GENERATOR="${GENERATOR:-}"
TARGET="${TARGET:-}"
JOBS="${JOBS:-$(nproc)}"
DO_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --install) DO_INSTALL=true; shift ;;
        *) die "Unknown option: $1" ;;
    esac
done

cd "$SOURCE_DIR"

# Configure
log "=== CMake Configure ==="
cmake_cmd="cmake -B ${BUILD_DIR} -DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
[ -n "$TOOLCHAIN_FILE" ] && cmake_cmd+=" -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}"
[ -n "$INSTALL_PREFIX" ] && cmake_cmd+=" -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}"
[ -n "$GENERATOR" ] && cmake_cmd+=" -G '${GENERATOR}'"
[ -n "$CMAKE_ARGS" ] && cmake_cmd+=" ${CMAKE_ARGS}"

log "Build type: $BUILD_TYPE"
[ -n "$TOOLCHAIN_FILE" ] && log "Toolchain: $TOOLCHAIN_FILE"

eval $cmake_cmd

# Build
log "=== CMake Build ==="
build_cmd="cmake --build ${BUILD_DIR} --parallel ${JOBS}"
[ -n "$TARGET" ] && build_cmd+=" --target ${TARGET}"
$build_cmd

# Install
if $DO_INSTALL && [ -n "$INSTALL_PREFIX" ]; then
    log "=== CMake Install ==="
    cmake --install "${BUILD_DIR}"
fi

# Report
log "=== Build Output ==="
find "${BUILD_DIR}" -type f -executable -not -path '*/CMakeFiles/*' 2>/dev/null | head -20
report_size "${BUILD_DIR}" "Build directory"
