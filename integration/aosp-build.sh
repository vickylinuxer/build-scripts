#!/bin/bash
# AOSP build wrapper for Raspberry Pi 4
# Sources are expected to be synced by the integration manifest (repo sync)
# Usage: ./aosp-build.sh [--jobs N] [--target TARGET]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

# Configuration
AOSP_DIR="${SOURCE_DIR:-${WORKSPACE}/aosp}"
CCACHE_DIR="${CACHE_DIR}/aosp/ccache"
CCACHE_SIZE="${CCACHE_SIZE:-50G}"
TARGET="${TARGET:-rpi4-ap3a-userdebug}"
JOBS="${JOBS:-$(nproc)}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --jobs) JOBS="$2"; shift 2 ;;
        --target) TARGET="$2"; shift 2 ;;
        *) die "Unknown option: $1" ;;
    esac
done

ensure_dir "$AOSP_DIR" "$CCACHE_DIR"

# Verify sources are present (synced by manifest)
[ -f "${AOSP_DIR}/build/envsetup.sh" ] || die "AOSP sources not found at ${AOSP_DIR} — check integration manifest"

# --- Build ---
build() {
    cd "$AOSP_DIR"

    log "Setting up build environment..."
    export USE_CCACHE=1
    export CCACHE_DIR="$CCACHE_DIR"
    ccache -M "$CCACHE_SIZE" 2>/dev/null || true

    set +u  # envsetup.sh uses uninitialized vars
    source build/envsetup.sh

    log "lunch ${TARGET}..."
    lunch "$TARGET"
    set -u

    log "Building with ${JOBS} parallel jobs..."
    local start
    start=$(date +%s)

    m -j"$JOBS"

    log "Build completed in $(elapsed "$start")"

    # Report artifacts
    log "=== Build Artifacts ==="
    if [ -d out/target/product ]; then
        find out/target/product -name '*.img' -type f | head -20
        du -sh out/target/product/*/ 2>/dev/null || true
    else
        log "No build output found"
    fi
    report_size "$CCACHE_DIR" "ccache"
    ccache -s 2>/dev/null | grep -E "cache size|hit rate" || true
}

# --- Main ---
log "=== AOSP Build: ${TARGET} ==="
build
log "=== AOSP Build Complete ==="
