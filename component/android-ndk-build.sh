#!/bin/bash
# Build a component using Android NDK
# Usage: android-ndk-build.sh [--cmake | --ndk-build]
#
# Required env: SOURCE_DIR, ANDROID_NDK (path to NDK)
# Optional env: ANDROID_ABI, ANDROID_PLATFORM, BUILD_DIR, BUILD_TYPE,
#               CMAKE_ARGS, NDK_BUILD_ARGS, JOBS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

SOURCE_DIR="${SOURCE_DIR:-.}"
ANDROID_NDK="${ANDROID_NDK:-}"
ANDROID_ABI="${ANDROID_ABI:-arm64-v8a}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-30}"
BUILD_DIR="${BUILD_DIR:-build}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
CMAKE_ARGS="${CMAKE_ARGS:-}"
NDK_BUILD_ARGS="${NDK_BUILD_ARGS:-}"
JOBS="${JOBS:-$(nproc)}"
BUILD_SYSTEM=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --cmake) BUILD_SYSTEM="cmake"; shift ;;
        --ndk-build) BUILD_SYSTEM="ndk-build"; shift ;;
        *) die "Unknown option: $1" ;;
    esac
done

[ -z "$ANDROID_NDK" ] && die "ANDROID_NDK is required (path to NDK root)"
[ -d "$ANDROID_NDK" ] || die "Android NDK not found: $ANDROID_NDK"

cd "$SOURCE_DIR"

# Auto-detect build system
if [ -z "$BUILD_SYSTEM" ]; then
    if [ -f CMakeLists.txt ]; then
        BUILD_SYSTEM="cmake"
    elif [ -f jni/Android.mk ] || [ -f Android.mk ]; then
        BUILD_SYSTEM="ndk-build"
    else
        die "Cannot detect build system. Use --cmake or --ndk-build"
    fi
    log "Auto-detected build system: $BUILD_SYSTEM"
fi

case "$BUILD_SYSTEM" in
    cmake)
        TOOLCHAIN="${ANDROID_NDK}/build/cmake/android.toolchain.cmake"
        [ -f "$TOOLCHAIN" ] || die "NDK CMake toolchain not found: $TOOLCHAIN"

        log "=== CMake Configure (Android NDK) ==="
        log "ABI: $ANDROID_ABI"
        log "Platform: $ANDROID_PLATFORM"

        cmake -B "${BUILD_DIR}" \
            -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN}" \
            -DANDROID_ABI="${ANDROID_ABI}" \
            -DANDROID_PLATFORM="${ANDROID_PLATFORM}" \
            -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
            ${CMAKE_ARGS}

        log "=== CMake Build ==="
        cmake --build "${BUILD_DIR}" --parallel "${JOBS}"
        ;;
    ndk-build)
        log "=== ndk-build (Android NDK) ==="
        log "ABI: $ANDROID_ABI"

        "${ANDROID_NDK}/ndk-build" \
            -j"${JOBS}" \
            APP_ABI="${ANDROID_ABI}" \
            APP_PLATFORM="${ANDROID_PLATFORM}" \
            ${NDK_BUILD_ARGS}
        ;;
esac

log "=== Build Complete (Android NDK) ==="
report_size "${BUILD_DIR}" "Build directory"
