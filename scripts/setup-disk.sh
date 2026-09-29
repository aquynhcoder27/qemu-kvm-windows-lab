#!/usr/bin/env bash
# Mount an existing lab SSD. Formatting requires --format and a blank USB disk.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

[[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]] ||
  die "Run this script with sudo from your normal user account."

if [[ ${1:-} == --format && $# -eq 1 ]]; then
  [[ "$LAB_DISK" == /dev/disk/by-id/* && "$LAB_DISK" != *-part* ]] ||
    die "Set LAB_DISK to a whole-disk /dev/disk/by-id/ path in config.local.sh."
  [[ -b "$LAB_DISK" ]] || die "Disk $LAB_DISK is not connected."

  disk=$(readlink -f "$LAB_DISK")
  [[ $(lsblk -dnro TYPE "$disk") == disk ]] || die "$LAB_DISK is not a whole disk."
  [[ $(lsblk -dnro TRAN "$disk") == usb ]] || die "$LAB_DISK is not a USB disk."

  root_device=$(findmnt -nro SOURCE /)
  root_parent=$(lsblk -dnro PKNAME "$root_device")
  [[ "$disk" != "/dev/$root_parent" ]] || die "Refusing to format the host system disk."
  [[ -z $(lsblk -nrpo NAME,TYPE "$disk" | awk '$2 == "part" {print $1}') ]] ||
    die "$LAB_DISK already has partitions. Formatting is only supported for a blank disk."
  [[ -z $(lsblk -dnro FSTYPE "$disk") ]] ||
    die "$LAB_DISK already has a filesystem. Refusing to erase it."

  echo "Disk to initialize:"
  lsblk -dnro NAME,SIZE,MODEL,SERIAL,TRAN "$disk"
  echo "All data on this blank USB disk will be erased."
  expected="FORMAT ${LAB_DISK##*/}"
  read -rp "Type '$expected' to continue: " confirmation
  [[ "$confirmation" == "$expected" ]] || die "Confirmation did not match."

  parted "$disk" --script mklabel gpt
  parted "$disk" --script mkpart primary ext4 1MiB 100%
  partprobe "$disk"
  udevadm settle
  mapfile -t partitions < <(lsblk -nrpo NAME,TYPE "$disk" | awk '$2 == "part" {print $1}')
  [[ ${#partitions[@]} -eq 1 ]] || die "Expected exactly one new partition on $disk."
  mkfs.ext4 -L "$LAB_LABEL" "${partitions[0]}"
  new_uuid=$(blkid -s UUID -o value "${partitions[0]}")
  echo "Disk initialized. Set LAB_FS_UUID=\"$new_uuid\" in config.local.sh,"
  echo "then run: sudo scripts/setup-disk.sh"
  exit 0
elif [[ $# -ne 0 ]]; then
  die "Usage: sudo scripts/setup-disk.sh [--format]"
fi

[[ -n "$LAB_FS_UUID" && "$LAB_FS_UUID" != REPLACE_WITH_EXT4_UUID ]] ||
  die "Set LAB_FS_UUID in config.local.sh first."
device=$(findfs "UUID=$LAB_FS_UUID") || die "SSD with UUID=$LAB_FS_UUID is not connected."
[[ $(blkid -s TYPE -o value "$device") == ext4 ]] || die "$device is not ext4."

if ! mountpoint -q "$LAB_MOUNT"; then
  install -d -m 0755 "$LAB_MOUNT"
  [[ -z $(find "$LAB_MOUNT" -mindepth 1 -maxdepth 1 -print -quit) ]] ||
    die "$LAB_MOUNT contains files while the SSD is absent. Inspect them before mounting."
fi

fstab_source=$(findmnt --fstab -nro SOURCE --mountpoint "$LAB_MOUNT" || true)
if [[ -n "$fstab_source" ]]; then
  fstab_device=$(findfs "$fstab_source") || die "fstab source $fstab_source does not exist."
  [[ $(blkid -s UUID -o value "$fstab_device") == "$LAB_FS_UUID" ]] ||
    die "fstab points $LAB_MOUNT to a different filesystem."
  fstab_options=$(findmnt --fstab -nro OPTIONS --mountpoint "$LAB_MOUNT")
  [[ ",$fstab_options," == *,nofail,* && ",$fstab_options," == *,x-systemd.device-timeout=5s,* ]] ||
    die "fstab mount for $LAB_MOUNT must include nofail,x-systemd.device-timeout=5s."
else
  backup=$(mktemp -p /etc fstab.lab-kvm.XXXXXXXX.bak)
  cp -a /etc/fstab "$backup"
  printf 'UUID=%s %s ext4 defaults,noatime,nofail,x-systemd.device-timeout=5s 0 2\n' \
    "$LAB_FS_UUID" "$LAB_MOUNT" >> /etc/fstab
  systemctl daemon-reload
  echo "Added optional mount to /etc/fstab (backup: $backup)"
fi

if ! mountpoint -q "$LAB_MOUNT"; then
  mount "$LAB_MOUNT"
fi

require_lab_storage
chown "$SUDO_USER:libvirt" "$LAB_MOUNT"
chmod 2775 "$LAB_MOUNT"
install -d -m 2775 -o "$SUDO_USER" -g libvirt "$LAB_MOUNT/ISOs"
echo "Ready: $LAB_MOUNT (UUID=$LAB_FS_UUID)"
