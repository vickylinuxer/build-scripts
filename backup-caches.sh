#!/bin/bash
# Backup build caches (Yocto DL_DIR, sstate, AOSP ccache)
# Usage: ./backup-caches.sh [--yocto] [--aosp] [--all]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_dir "$BACKUP_DIR"

DATE=$(date +%Y%m%d)
DO_YOCTO=false
DO_AOSP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --yocto) DO_YOCTO=true; shift ;;
        --aosp) DO_AOSP=true; shift ;;
        --all) DO_YOCTO=true; DO_AOSP=true; shift ;;
        *) die "Unknown option: $1. Usage: $0 [--yocto] [--aosp] [--all]" ;;
    esac
done

# Default to all if nothing specified
if ! $DO_YOCTO && ! $DO_AOSP; then
    DO_YOCTO=true
    DO_AOSP=true
fi

backup_dir() {
    local src="$1"
    local name="$2"
    local dest="${BACKUP_DIR}/${name}-${DATE}.tar.gz"

    if [ ! -d "$src" ] || [ -z "$(ls -A "$src" 2>/dev/null)" ]; then
        log "Skipping ${name}: directory empty or missing"
        return
    fi

    local src_parent
    local src_base
    src_parent=$(dirname "$src")
    src_base=$(basename "$src")

    if [ -f "$dest" ]; then
        log "Backup already exists: $dest"
        return
    fi

    report_size "$src" "${name} source"
    log "Backing up ${name}..."
    local start
    start=$(date +%s)

    tar czf "$dest" -C "$src_parent" "$src_base"

    log "${name} backup done in $(elapsed "$start"): $(du -h "$dest" | cut -f1)"
}

# --- Yocto caches ---
if $DO_YOCTO; then
    log "=== Yocto Cache Backup ==="
    backup_dir "${CACHE_DIR}/yocto/downloads" "yocto-downloads"
    backup_dir "${CACHE_DIR}/yocto/sstate" "yocto-sstate"
fi

# --- AOSP ccache ---
if $DO_AOSP; then
    log "=== AOSP Cache Backup ==="
    backup_dir "${CACHE_DIR}/aosp/ccache" "aosp-ccache"
fi

# Cleanup old backups (keep last 3)
log "=== Cleanup old backups ==="
for prefix in yocto-downloads yocto-sstate aosp-ccache; do
    count=$(ls -1 "${BACKUP_DIR}/${prefix}-"*.tar.gz 2>/dev/null | wc -l)
    if [ "$count" -gt 3 ]; then
        ls -1t "${BACKUP_DIR}/${prefix}-"*.tar.gz | tail -n +4 | while read -r old; do
            log "Removing old backup: $old"
            rm -f "$old"
        done
    fi
done

log "=== Backup Summary ==="
ls -lh "${BACKUP_DIR}/"*.tar.gz 2>/dev/null || log "No backups found"
