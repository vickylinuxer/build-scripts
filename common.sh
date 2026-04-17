#!/bin/bash
# Common functions for build wrapper scripts

set -euo pipefail

WORKSPACE="${WORKSPACE:-/mnt/workspace}"
CACHE_DIR="${CACHE_DIR:-${WORKSPACE}/cache}"
BACKUP_DIR="${BACKUP_DIR:-${WORKSPACE}/backup/cache}"
LOG_DIR="${LOG_DIR:-${WORKSPACE}/logs}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

die() {
    error "$@"
    exit 1
}

ensure_dir() {
    for d in "$@"; do
        mkdir -p "$d"
    done
}

elapsed() {
    local start=$1
    local end
    end=$(date +%s)
    local diff=$((end - start))
    printf '%02d:%02d:%02d' $((diff/3600)) $((diff%3600/60)) $((diff%60))
}

report_size() {
    local dir="$1"
    local label="${2:-$dir}"
    if [ -d "$dir" ]; then
        log "${label}: $(du -sh "$dir" 2>/dev/null | cut -f1)"
    fi
}
