#!/usr/bin/env bash
# Mount the configured lab SSD after plugging it in. This entrypoint cannot format a disk.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ne 0 ]]; then
  echo "Usage: $0" >&2
  exit 2
fi

if [[ $EUID -eq 0 ]]; then
  exec "$SCRIPT_DIR/setup-disk.sh"
fi

exec sudo "$SCRIPT_DIR/setup-disk.sh"
