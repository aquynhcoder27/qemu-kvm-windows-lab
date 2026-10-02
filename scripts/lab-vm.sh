#!/usr/bin/env bash
# lab-vm.sh — Daily VM management helper.
# Usage: lab-vm.sh {list|start|stop|stopall|console|ip} [vm-name]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

LAB_VMS=("$VM_SRV" "$VM_W7_1" "$VM_W7_2")
MAX_CONCURRENT=2

cmd="${1:-list}"
vm="${2:-}"

case "$cmd" in
  list)
    echo "=== Lab VMs ==="
    virsh list --all | grep -E "Name|$(IFS='|'; echo "${LAB_VMS[*]}")" || true
    echo ""
    echo "=== Storage ==="
    virsh pool-info "$LAB_POOL" 2>/dev/null | grep -E "Name|State|Capacity|Available" || echo "Pool not found"
    if mountpoint -q "$LAB_MOUNT"; then
      echo "Storage UUID: $(findmnt -nro UUID --mountpoint "$LAB_MOUNT") (expected: $LAB_FS_UUID)"
    else
      echo "Lab storage not mounted at $LAB_MOUNT"
    fi
    ;;

  start)
    [[ -n "$vm" ]] || { echo "Usage: $0 start <vm-name>"; printf '  VMs: %s\n' "${LAB_VMS[@]}"; exit 1; }

    known_vm=0
    for candidate in "${LAB_VMS[@]}"; do
      [[ "$vm" == "$candidate" ]] && known_vm=1
    done
    [[ $known_vm -eq 1 ]] || die "VM '$vm' is not configured for this lab."
    require_lab_storage

    # Guard: check VM exists
    if ! virsh dominfo "$vm" > /dev/null 2>&1; then
      echo "ERROR: VM '$vm' not found. Run 'scripts/create-vms.sh' first."
      exit 1
    fi

    disk_source=$(virsh domblklist "$vm" --details | awk '$2 == "disk" {print $4; exit}')
    [[ "$disk_source" == "$LAB_MOUNT/$vm.qcow2" && -f "$disk_source" && ! -L "$disk_source" ]] ||
      die "VM disk is missing or outside the verified storage: $disk_source"
    nic_network=$(virsh domiflist "$vm" | awk '$2 == "network" {print $3; exit}')
    [[ "$nic_network" == "$LAB_NET" ]] ||
      die "VM uses network '$nic_network', but config.local.sh specifies '$LAB_NET'."

    "$SCRIPT_DIR/setup-libvirt.sh"

    if [[ $(virsh domstate "$vm") == running ]]; then
      echo "$vm is already running."
      exit 0
    fi

    # Guard: RAM limit
    running_names=$(virsh list --state-running --name)
    running=0
    for candidate in "${LAB_VMS[@]}"; do
      if grep -Fxq "$candidate" <<<"$running_names"; then
        running=$((running + 1))
      fi
    done
    if [[ "$running" -ge "$MAX_CONCURRENT" ]]; then
      echo "ERROR: $running VM(s) already running (max $MAX_CONCURRENT)."
      echo "  Running: $(tr '\n' ' ' <<<"$running_names")"
      echo "  Stop one first: $0 stop <vm-name>"
      exit 1
    fi

    echo "Starting $vm ..."
    virsh start "$vm"
    echo "Open console: $0 console $vm"
    ;;

  stop)
    [[ -n "$vm" ]] || { echo "Usage: $0 stop <vm-name>"; exit 1; }

    # Check if running at all
    state=$(virsh domstate "$vm" 2>/dev/null || echo "not found")
    if [[ "$state" == "not found" ]]; then
      echo "ERROR: VM '$vm' not found."
      exit 1
    fi
    if [[ "$state" != "running" ]]; then
      echo "VM '$vm' is not running (state: $state). Nothing to do."
      exit 0
    fi

    echo "Sending graceful shutdown to $vm ..."
    echo "Windows will shut down gracefully; wait until the VM is off."
    virsh shutdown "$vm"
    ;;

  stopall)
    echo "Sending graceful shutdown to all running lab VMs ..."
    SENT=0
    for v in "${LAB_VMS[@]}"; do
      state=$(virsh domstate "$v" 2>/dev/null || echo "not found")
      if [[ "$state" == "running" ]]; then
        virsh shutdown "$v" && echo "  -> $v: shutdown sent" && SENT=1
      fi
    done
    if [[ $SENT -eq 0 ]]; then
      echo "  No VMs were running."
    fi
    ;;

  console)
    [[ -n "$vm" ]] || { echo "Usage: $0 console <vm-name>"; exit 1; }
    echo "Opening console for $vm ..."
    virt-viewer --connect qemu:///system "$vm" &
    ;;

  ip)
    echo "=== VM IP Addresses ==="
    for v in "${LAB_VMS[@]}"; do
      found_ip=$(virsh domifaddr "$v" --source lease 2>/dev/null | awk '$3 == "ipv4" {print $4; exit}' || true)
      printf '  %-14s  %s\n' "$v" "${found_ip:-unknown (VM may be off or use a static address)}"
    done
    ;;

  *)
    echo "Usage: $0 {list|start|stop|stopall|console|ip} [vm-name]"
    echo ""
    echo "  list          Show all VMs and storage status"
    echo "  start <vm>    Start a VM (max $MAX_CONCURRENT at once)"
    echo "  stop <vm>     Gracefully shut down a VM"
    echo "  stopall       Gracefully shut down all running VMs"
    echo "  console <vm>  Open graphical console"
    echo "  ip            Show IP addresses of all VMs"
    echo ""
    echo "  VMs: ${LAB_VMS[*]}"
    ;;
esac
