#!/usr/bin/env bash
# create-vms.sh — Create disk images and define all lab VMs in libvirt.
# Safe to re-run; skips VMs and disks that already exist.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

ISO_DIR="$LAB_MOUNT/ISOs"

echo "=== Lab KVM — VM Creation ==="
echo ""

# -- Pre-flight checks -------------------------------------------------------

require_lab_storage

if ! groups | grep -qw libvirt; then
  echo "ERROR: Current user is not in the 'libvirt' group."
  echo "  Run: newgrp libvirt  (or logout and login)"
  exit 1
fi

if ! virsh pool-info "$LAB_POOL" > /dev/null 2>&1; then
  echo "ERROR: Storage pool '$LAB_POOL' not found."
  echo "  Run scripts/setup-libvirt.sh first."
  exit 1
fi

if ! pool_is_active; then
  die "Storage pool '$LAB_POOL' is inactive. Run scripts/setup-libvirt.sh first."
fi
if ! virsh net-list --name | grep -Fxq "$LAB_NET"; then
  die "NAT network '$LAB_NET' is inactive. Run scripts/setup-libvirt.sh first."
fi

# -- Check ISOs --------------------------------------------------------------

echo "=== Checking ISOs ==="
MISSING=0
for iso in "win-server-2022.iso" "virtio-win.iso"; do
  if [[ -f "$ISO_DIR/$iso" ]]; then
    echo "  OK: $iso"
  else
    echo "  MISSING: $ISO_DIR/$iso"
    MISSING=1
  fi
done

WIN7_ISO="$ISO_DIR/win7.iso"
HAS_WIN7=0
if [[ -f "$WIN7_ISO" ]]; then
  HAS_WIN7=1
  echo "  OK: win7.iso"
else
  echo "  INFO: win7.iso not found — client VMs will be skipped"
fi

if [[ $MISSING -eq 1 ]]; then
  echo ""
  echo "Place missing ISO files in: $ISO_DIR"
  echo "See ISO-DOWNLOAD-GUIDE.md for download links."
  exit 1
fi

# -- Disk images -------------------------------------------------------------

echo ""
echo "=== Creating VM Disk Images ==="

create_disk() {
  local path="$1"
  local size="$2"
  [[ ! -L "$path" ]] || die "Refusing disk image symlink: $path"
  if [[ -f "$path" ]]; then
    echo "  Exists (skipped): $(basename "$path")"
  else
    [[ ! -e "$path" ]] || die "Disk image path exists but is not a regular file: $path"
    qemu-img create -f qcow2 "$path" "$size"
    echo "  Created: $(basename "$path") ($size)"
  fi
}

create_disk "$LAB_MOUNT/${VM_SRV}.qcow2"   "${SERVER_DISK_GB}G"
create_disk "$LAB_MOUNT/${VM_W7_1}.qcow2"  "${CLIENT_DISK_GB}G"
create_disk "$LAB_MOUNT/${VM_W7_2}.qcow2"  "${CLIENT_DISK_GB}G"

virsh pool-refresh "$LAB_POOL"

# -- VM definitions ----------------------------------------------------------

echo ""
echo "=== Defining VMs ==="

define_server_vm() {
  local name="$1"
  local disk="$LAB_MOUNT/${name}.qcow2"

  if virsh dominfo "$name" > /dev/null 2>&1; then
    echo "  Already defined (skipped): $name"
    return
  fi

  virt-install \
    --name "$name" \
    --memory "$SERVER_RAM_MB" \
    --vcpus "$SERVER_VCPU" \
    --cpu host-passthrough \
    --disk "path=$disk,format=qcow2,bus=virtio,cache=writeback" \
    --disk "path=$ISO_DIR/virtio-win.iso,device=cdrom,bus=sata" \
    --cdrom "$ISO_DIR/win-server-2022.iso" \
    --os-variant win2k22 \
    --network "network=$LAB_NET,model=virtio" \
    --graphics spice,listen=127.0.0.1 \
    --video qxl \
    --channel spicevmc \
    --boot uefi,menu=on \
    --features kvm_hidden=on \
    --clock offset=localtime \
    --noautoconsole \
    --noreboot
  echo "  Defined: $name"
}

define_win7_vm() {
  local name="$1"
  local disk="$LAB_MOUNT/${name}.qcow2"

  if virsh dominfo "$name" > /dev/null 2>&1; then
    echo "  Already defined (skipped): $name"
    return
  fi

  if [[ $HAS_WIN7 -eq 0 ]]; then
    echo "  Skipped (no win7.iso): $name"
    return
  fi

  virt-install \
    --name "$name" \
    --memory "$CLIENT_RAM_MB" \
    --vcpus "$CLIENT_VCPU" \
    --cpu host-passthrough \
    --disk "path=$disk,format=qcow2,bus=virtio,cache=writeback" \
    --disk "path=$ISO_DIR/virtio-win.iso,device=cdrom,bus=sata" \
    --cdrom "$ISO_DIR/win7.iso" \
    --os-variant win7 \
    --network "network=$LAB_NET,model=e1000" \
    --graphics spice,listen=127.0.0.1 \
    --video qxl \
    --channel spicevmc \
    --boot cdrom,hd,menu=on \
    --features kvm_hidden=on \
    --clock offset=localtime \
    --noautoconsole \
    --noreboot
  echo "  Defined: $name"
}

define_server_vm "$VM_SRV"
define_win7_vm   "$VM_W7_1"
define_win7_vm   "$VM_W7_2"

echo ""
echo "✅ Done. Run 'scripts/lab-vm.sh list' to verify."
