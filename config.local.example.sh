# Copy this file to config.local.sh and edit the values for your machine.
# Find a stable disk path with: ls -l /dev/disk/by-id/
# LAB_DISK is only used by: sudo scripts/setup-disk.sh --format
LAB_DISK="" # e.g. /dev/disk/by-id/usb-YOUR_DISK; needed only for --format

# Find the UUID with: lsblk -f
# Leave empty until a new disk has been formatted.
LAB_FS_UUID="REPLACE_WITH_EXT4_UUID"

# Existing VMs can keep using their current NAT network, for example:
# LAB_NET="default"

# Optional: preserve the old server VM's DHCP address when replacing its disk.
# SERVER_MAC="52:54:00:xx:xx:xx"
