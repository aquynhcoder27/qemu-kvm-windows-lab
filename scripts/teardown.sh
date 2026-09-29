#!/usr/bin/env bash
# teardown.sh — Remove lab VMs and libvirt configuration.
#
# Removes libvirt definitions after confirmation. Disk images are retained.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

LAB_VMS=("$VM_SRV" "$VM_W7_1" "$VM_W7_2")

confirm() {
  local prompt="$1"
  read -rp "$prompt [y/N] " ans
  [[ "${ans,,}" == "y" ]]
}

echo "=== Lab KVM — Teardown ==="
echo ""
echo "This script removes libvirt config only."
echo "Disk images in $LAB_MOUNT are NOT touched."
echo ""

# -- Stage 1: Stop and undefine VMs -----------------------------------------

echo "--- Stage 1: VMs ---"
for vm in "${LAB_VMS[@]}"; do
  if ! virsh dominfo "$vm" > /dev/null 2>&1; then
    echo "  $vm: not defined, skipping"
    continue
  fi

  state=$(virsh domstate "$vm" 2>/dev/null || echo "unknown")

  if [[ "$state" != "shut off" ]]; then
    echo "  $vm is $state; shut it down before removing its definition."
  else
    if confirm "  Remove VM definition for $vm (disk image kept)?"; then
      virsh undefine "$vm" --keep-nvram --keep-tpm
      echo "  $vm: removed"
    else
      echo "  $vm: skipped"
    fi
  fi
done

remaining_vms=0
for vm in "${LAB_VMS[@]}"; do
  if virsh dominfo "$vm" >/dev/null 2>&1; then
    remaining_vms=$((remaining_vms + 1))
  fi
done
if [[ $remaining_vms -gt 0 ]]; then
  echo "$remaining_vms lab VM definition(s) remain. Keeping storage pool and network."
  exit 0
fi

# -- Stage 2: Storage pool ---------------------------------------------------

echo ""
echo "--- Stage 2: Storage Pool ---"
if virsh pool-info "$LAB_POOL" > /dev/null 2>&1; then
  if confirm "  Remove storage pool '$LAB_POOL' from libvirt? (files in $LAB_MOUNT are kept)"; then
    virsh pool-destroy "$LAB_POOL" 2>/dev/null || true
    virsh pool-undefine "$LAB_POOL"
    echo "  Pool removed"
  else
    echo "  Pool skipped"
  fi
else
  echo "  Pool '$LAB_POOL' not defined, skipping"
fi

# -- Stage 3: Network --------------------------------------------------------

echo ""
echo "--- Stage 3: Network ---"
if [[ "$LAB_NET" == default ]]; then
  echo "  Keeping shared default NAT network."
elif [[ "$LAB_NET" != lab-kvm-nat ]]; then
  echo "  Keeping network '$LAB_NET'; it is not owned by this project."
elif virsh net-info "$LAB_NET" > /dev/null 2>&1; then
  if confirm "  Remove network '$LAB_NET' from libvirt?"; then
    virsh net-destroy "$LAB_NET" 2>/dev/null || true
    virsh net-undefine "$LAB_NET"
    echo "  Network removed"
  else
    echo "  Network skipped"
  fi
else
  echo "  Network '$LAB_NET' not defined, skipping"
fi

echo ""
echo "✅ Teardown complete."
echo "   Disk images remain in: $LAB_MOUNT"
echo "   Optional mount entry in /etc/fstab was kept for manual review."
