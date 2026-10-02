#!/usr/bin/env bash
# Register the lab storage pool and provide a NAT network.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

command -v virsh >/dev/null || die "Install libvirt-daemon-system and libvirt-clients first."
groups | grep -qw libvirt || die "Join the libvirt group and start a new login session."
require_lab_storage

if virsh pool-info "$LAB_POOL" >/dev/null 2>&1; then
  pool_xml=$(virsh pool-dumpxml "$LAB_POOL")
  [[ "$pool_xml" == *"<pool type='dir'>"* && "$pool_xml" == *"<path>$LAB_MOUNT</path>"* ]] ||
    die "Pool $LAB_POOL exists but is not a directory pool at $LAB_MOUNT."
else
  virsh pool-define-as "$LAB_POOL" dir --target "$LAB_MOUNT"
fi

# Keep activation explicit so the mount is verified before libvirt uses this path.
virsh pool-autostart --disable "$LAB_POOL"
if ! pool_is_active; then
  virsh pool-start "$LAB_POOL"
fi
virsh pool-refresh "$LAB_POOL"

# Some existing labs also register the ISO directory as a separate pool.
if virsh pool-info ISOs >/dev/null 2>&1; then
  iso_pool_xml=$(virsh pool-dumpxml ISOs)
  if [[ "$iso_pool_xml" == *"<pool type='dir'>"* &&
        "$iso_pool_xml" == *"<path>$LAB_MOUNT/ISOs</path>"* ]]; then
    virsh pool-autostart --disable ISOs
    if ! pool_is_active ISOs; then
      virsh pool-start ISOs
    fi
    virsh pool-refresh ISOs
  fi
fi

if [[ "$LAB_NET" == lab-kvm-nat ]] && ! virsh net-info "$LAB_NET" >/dev/null 2>&1; then
  virsh net-define "$SCRIPT_DIR/../networks/lab-nat.xml"
fi
network_xml=$(virsh net-dumpxml "$LAB_NET") || die "Network $LAB_NET does not exist."
grep -Eq "<forward[[:space:]]+mode=['\"]nat['\"]" <<<"$network_xml" ||
  die "Network $LAB_NET is not a NAT network."
if ! virsh net-list --name | grep -Fxq "$LAB_NET"; then
  virsh net-start "$LAB_NET"
fi
if [[ "$LAB_NET" == lab-kvm-nat ]]; then
  virsh net-autostart --disable "$LAB_NET"
fi

echo "Ready: pool $LAB_POOL on $LAB_MOUNT; NAT network $LAB_NET"
