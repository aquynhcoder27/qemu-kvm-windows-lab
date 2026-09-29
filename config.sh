# =============================================================================
# Lab KVM — Configuration
# Copy config.local.example.sh to config.local.sh and set values for this host.
# Keep host-specific disk identifiers out of the shared project.
# =============================================================================

# --- Disk ---
# Only used by the explicit --format operation. Use a whole-disk by-id path.
LAB_DISK=""

# UUID of the ext4 filesystem containing the VM images. Required for use.
LAB_FS_UUID=""

# Label assigned when formatting a new disk.
LAB_LABEL="lab-vms"

# Where the disk will be mounted on this host.
LAB_MOUNT="/mnt/lab-vms"

# --- Network ---
# Dedicated NAT network for new labs. Existing labs may use "default" via
# config.local.sh; the project will never redefine or remove that shared net.
LAB_NET="lab-kvm-nat"

# --- Libvirt ---
# Always use the system daemon for these VM definitions.
export LIBVIRT_DEFAULT_URI="qemu:///system"

# Name of the libvirt storage pool.
LAB_POOL="lab-vms"

# --- VM Sizing ---
# Adjust based on your host RAM. Total across all running VMs must stay
# below (host RAM - 3 GiB reserved for host OS).
SERVER_RAM_MB=2560   # per Windows Server VM
CLIENT_RAM_MB=1536   # per Windows client VM
SERVER_VCPU=2
CLIENT_VCPU=1
SERVER_DISK_GB=35
CLIENT_DISK_GB=20

# --- VM Names ---
# Changing these after VMs are created will break references.
VM_SRV="win-srv-01"
VM_W7_1="win-w7-01"
VM_W7_2="win-w7-02"

# Per-host configuration is intentionally untracked.
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$CONFIG_DIR/config.local.sh" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_DIR/config.local.sh"
fi
