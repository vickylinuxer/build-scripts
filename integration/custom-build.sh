#!/bin/bash
# Custom firmware build wrapper (CMake cross-compilation)
# Sources are expected to be synced by the integration manifest (repo sync)
# Usage: ./custom-build.sh [--toolchain FILE] [--source-dir DIR]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

# Configuration
SOURCE_DIR="${SOURCE_DIR:-${WORKSPACE}/projects/custom-firmware}"
BUILD_DIR="${SOURCE_DIR}/build"
TOOLCHAIN_FILE="${TOOLCHAIN_FILE:-/opt/toolchains/aarch64-linux-gnu.cmake}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --toolchain) TOOLCHAIN_FILE="$2"; shift 2 ;;
        --source-dir) SOURCE_DIR="$2"; BUILD_DIR="${SOURCE_DIR}/build"; shift 2 ;;
        *) die "Unknown option: $1" ;;
    esac
done

# --- Build ---
build() {
    [ -d "$SOURCE_DIR" ] || die "Source directory not found: $SOURCE_DIR"
    [ -f "${SOURCE_DIR}/CMakeLists.txt" ] || die "No CMakeLists.txt in $SOURCE_DIR"

    cd "$SOURCE_DIR"

    log "CMake Configure"
    local cmake_args="-B ${BUILD_DIR}"
    if [ -f "$TOOLCHAIN_FILE" ]; then
        cmake_args+=" -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}"
        log "Toolchain: $TOOLCHAIN_FILE"
    fi

    cmake $cmake_args .

    log "CMake Build"
    cmake --build "$BUILD_DIR"

    # Report
    log "=== Build Artifacts ==="
    find "$BUILD_DIR" -name '*.elf' -o -name '*.bin' -o -name '*.hex' 2>/dev/null | while read -r f; do
        ls -lh "$f"
    done
    report_size "$BUILD_DIR" "Build directory"
}

# --- Main ---
log "=== Custom Firmware Build ==="
build
log "=== Custom Build Complete ==="
