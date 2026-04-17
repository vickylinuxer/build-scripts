#!/bin/bash
# Bazel component build
# Usage: bazel-build.sh
#
# Required env: SOURCE_DIR
# Optional env: BAZEL_TARGETS, BUILD_ARGS, CONFIG_FLAGS, STARTUP_FLAGS, JOBS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

SOURCE_DIR="${SOURCE_DIR:-.}"
BAZEL_TARGETS="${BAZEL_TARGETS:-//...}"
BUILD_ARGS="${BUILD_ARGS:-}"
CONFIG_FLAGS="${CONFIG_FLAGS:-}"
STARTUP_FLAGS="${STARTUP_FLAGS:-}"
JOBS="${JOBS:-}"

cd "$SOURCE_DIR"

log "=== Bazel Build ==="
log "Targets: $BAZEL_TARGETS"

jobs_arg=""
[ -n "$JOBS" ] && jobs_arg="--jobs=${JOBS}"

bazel ${STARTUP_FLAGS} build ${CONFIG_FLAGS} ${jobs_arg} ${BUILD_ARGS} ${BAZEL_TARGETS}

log "=== Build Complete ==="
