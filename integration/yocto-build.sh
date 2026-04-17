#!/bin/bash
# Yocto build wrapper for Raspberry Pi 4
# Sources are expected to be synced by the integration manifest (repo sync)
# Usage: ./yocto-build.sh [--image IMAGE] [--machine MACHINE]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

# Configuration
POKY_DIR="${WORKSPACE}/yocto/poky"
META_RPI_DIR="${WORKSPACE}/yocto/meta-raspberrypi"
BUILD_DIR="${WORKSPACE}/yocto/build"
DL_DIR="${CACHE_DIR}/yocto/downloads"
SSTATE_DIR="${CACHE_DIR}/yocto/sstate"
SOURCE_MIRROR="${SOURCE_MIRROR:-/mnt/workspace/cache/yocto/downloads}"
MACHINE="${MACHINE:-raspberrypi4-64}"
DISTRO="${DISTRO:-poky}"
IMAGE="${IMAGE:-core-image-minimal}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --image) IMAGE="$2"; shift 2 ;;
        --machine) MACHINE="$2"; shift 2 ;;
        *) die "Unknown option: $1" ;;
    esac
done

ensure_dir "$DL_DIR" "$SSTATE_DIR" "$BUILD_DIR"

# Verify sources are present (synced by manifest)
[ -d "${POKY_DIR}" ] || die "Poky not found at ${POKY_DIR} — check integration manifest"
[ -d "${META_RPI_DIR}" ] || die "meta-raspberrypi not found at ${META_RPI_DIR} — check integration manifest"

# --- Build ---
build() {
    log "Initializing build environment..."
    set +u  # oe-init-build-env uses uninitialized vars (BBSERVER etc.)
    source "${POKY_DIR}/oe-init-build-env" "$BUILD_DIR"
    set -u

    NPROC=$(nproc)

    # Write local.conf
    cat > "${BUILD_DIR}/conf/local.conf" <<EOF
MACHINE = "${MACHINE}"
DISTRO = "${DISTRO}"
DL_DIR = "${DL_DIR}"
SSTATE_DIR = "${SSTATE_DIR}"
TMPDIR = "${BUILD_DIR}/tmp"
PACKAGE_CLASSES = "package_rpm"
BB_NUMBER_THREADS = "${NPROC}"
PARALLEL_MAKE = "-j ${NPROC}"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
INHERIT += "own-mirrors"
SOURCE_MIRROR_URL = "file://${SOURCE_MIRROR}"
BB_GENERATE_MIRROR_TARBALLS = "1"
EOF

    # Write bblayers.conf
    cat > "${BUILD_DIR}/conf/bblayers.conf" <<EOF
POKY_BBLAYERS_CONF_VERSION = "2"
BBPATH = "\${TOPDIR}"
BBFILES ?= ""
BBLAYERS ?= " \\
  ${POKY_DIR}/meta \\
  ${POKY_DIR}/meta-poky \\
  ${POKY_DIR}/meta-yocto-bsp \\
  ${META_RPI_DIR} \\
"
EOF

    # Clean stale pseudo database files to prevent do_package path mismatch errors
    # Only remove DB files (not directories) so pseudo can reinitialize cleanly
    if [ -d "${BUILD_DIR}/tmp" ]; then
        log "Cleaning stale pseudo database files..."
        find "${BUILD_DIR}/tmp" -path "*/pseudo/*.db" -delete 2>/dev/null || true
        find "${BUILD_DIR}/tmp" -name "pseudo.pid" -delete 2>/dev/null || true
    fi

    log "Building ${IMAGE} for ${MACHINE} (${NPROC} threads)..."
    local start
    start=$(date +%s)

    bitbake "$IMAGE"

    log "Build completed in $(elapsed "$start")"

    # Report artifacts
    local deploy_dir="${BUILD_DIR}/tmp/deploy/images/${MACHINE}"
    log "=== Build Artifacts ==="
    if [ -d "$deploy_dir" ]; then
        ls -lh "$deploy_dir"/*.wic* "$deploy_dir"/*.ext3 "$deploy_dir"/*.tar.bz2 2>/dev/null || true
        report_size "$deploy_dir" "Deploy directory"
    fi
    report_size "$BUILD_DIR/tmp" "Build tmp"
    report_size "$DL_DIR" "Downloads cache"
    report_size "$SSTATE_DIR" "Sstate cache"
}

# --- Main ---
log "=== Yocto Build: ${IMAGE} for ${MACHINE} ==="
build
log "=== Yocto Build Complete ==="
