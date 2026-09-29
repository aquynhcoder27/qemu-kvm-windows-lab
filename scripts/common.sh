#!/usr/bin/env bash
# Shared, read-only checks used before any VM storage operation.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../config.sh
source "$SCRIPT_DIR/../config.sh"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_lab_storage() {
  [[ -n "$LAB_FS_UUID" && "$LAB_FS_UUID" != REPLACE_WITH_EXT4_UUID ]] ||
    die "Set LAB_FS_UUID in config.local.sh first."

  mountpoint -q "$LAB_MOUNT" ||
    die "$LAB_MOUNT is not mounted. Connect the SSD and run: sudo scripts/setup-disk.sh"

  local actual_uuid actual_type
  actual_uuid=$(findmnt -nro UUID --mountpoint "$LAB_MOUNT") ||
    die "Cannot identify the filesystem mounted at $LAB_MOUNT."
  actual_type=$(findmnt -nro FSTYPE --mountpoint "$LAB_MOUNT") ||
    die "Cannot identify the filesystem type at $LAB_MOUNT."

  [[ "$actual_uuid" == "$LAB_FS_UUID" && "$actual_type" == ext4 ]] ||
    die "$LAB_MOUNT is the wrong filesystem (UUID=$actual_uuid, type=$actual_type); expected ext4 UUID=$LAB_FS_UUID."
}

pool_is_active() {
  local pool_name="${1:-$LAB_POOL}"
  virsh pool-list --name | awk -v pool="$pool_name" '
    { sub(/[[:space:]]+$/, ""); if ($0 == pool) found = 1 }
    END { exit !found }
  '
}
