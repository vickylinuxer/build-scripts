#!/bin/bash
# Build a component using a Yocto SDK (cross-compilation environment)
# Usage: yocto-sdk-build.sh [--cmake | --make | --autotools | --meson]
#
# Required env: SDK_ENV (path to environment-setup-* script), SOURCE_DIR
# Optional env: BUILD_DIR, BUILD_TYPE, CMAKE_ARGS, MAKE_TARGET, CONFIGURE_ARGS,
#               INSTALL_PREFIX, JOBS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

SDK_ENV="${SDK_ENV:-}"
SOURCE_DIR="${SOURCE_DIR:-.}"
BUILD_DIR="${BUILD_DIR:-build}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
CMAKE_ARGS="${CMAKE_ARGS:-}"
MAKE_TARGET="${MAKE_TARGET:-all}"
MAKE_ARGS="${MAKE_ARGS:-}"
CONFIGURE_ARGS="${CONFIGURE_ARGS:-}"
INSTALL_PREFIX="${INSTALL_PREFIX:-}"
JOBS="${JOBS:-$(nproc)}"
BUILD_SYSTEM=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --cmake) BUILD_SYSTEM="cmake"; shift ;;
        --make) BUILD_SYSTEM="make"; shift ;;
        --autotools) BUILD_SYSTEM="autotools"; shift ;;
        --meson) BUILD_SYSTEM="meson"; shift ;;
        *) die "Unknown option: $1" ;;
    esac
done

[ -z "$SDK_ENV" ] && die "SDK_ENV is required (path to environment-setup-* script)"
[ -f "$SDK_ENV" ] || die "SDK environment script not found: $SDK_ENV"

# Source the Yocto SDK environment (sets CC, CXX, CFLAGS, etc.)
log "=== Sourcing Yocto SDK ==="
log "SDK: $SDK_ENV"
source "$SDK_ENV"
log "CC=$CC"
log "SDKTARGETSYSROOT=$SDKTARGETSYSROOT"

cd "$SOURCE_DIR"

# Auto-detect build system if not specified
if [ -z "$BUILD_SYSTEM" ]; then
    if [ -f CMakeLists.txt ]; then
        BUILD_SYSTEM="cmake"
    elif [ -f configure.ac ] || [ -f configure ]; then
        BUILD_SYSTEM="autotools"
    elif [ -f meson.build ]; then
        BUILD_SYSTEM="meson"
    elif [ -f Makefile ] || [ -f makefile ]; then
        BUILD_SYSTEM="make"
    else
        die "Cannot detect build system. Use --cmake, --make, --autotools, or --meson"
    fi
    log "Auto-detected build system: $BUILD_SYSTEM"
fi

case "$BUILD_SYSTEM" in
    cmake)
        log "=== CMake Configure (Yocto SDK) ==="
        cmake_cmd="cmake -B ${BUILD_DIR} -DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
        # Yocto SDK sets CMAKE_FIND_ROOT_PATH via env, no toolchain file needed
        [ -n "$INSTALL_PREFIX" ] && cmake_cmd+=" -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}"
        [ -n "$CMAKE_ARGS" ] && cmake_cmd+=" ${CMAKE_ARGS}"
        eval $cmake_cmd

        log "=== CMake Build ==="
        cmake --build "${BUILD_DIR}" --parallel "${JOBS}"
        ;;
    make)
        log "=== Make Build (Yocto SDK) ==="
        make -j"${JOBS}" ${MAKE_ARGS} ${MAKE_TARGET}
        ;;
    autotools)
        if [ -f configure.ac ] && [ ! -f configure ]; then
            log "=== Autoreconf ==="
            autoreconf -fi
        fi
        log "=== Configure (Yocto SDK) ==="
        configure_cmd="./configure --host=${CONFIGURE_HOST:-$TARGET_PREFIX}"
        [ -n "$CONFIGURE_ARGS" ] && configure_cmd+=" ${CONFIGURE_ARGS}"
        [ -n "$INSTALL_PREFIX" ] && configure_cmd+=" --prefix=${INSTALL_PREFIX}"
        eval $configure_cmd

        log "=== Build ==="
        make -j"${JOBS}" ${MAKE_ARGS} ${MAKE_TARGET}
        ;;
    meson)
        log "=== Meson Setup (Yocto SDK) ==="
        meson setup "${BUILD_DIR}" --buildtype="${BUILD_TYPE}" ${MESON_ARGS:-}

        log "=== Meson Compile ==="
        meson compile -C "${BUILD_DIR}" -j"${JOBS}"
        ;;
esac

log "=== Build Complete (Yocto SDK) ==="
report_size "${BUILD_DIR}" "Build directory"
