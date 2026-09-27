#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-config/lab.env}"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Không tìm thấy file cấu hình: $CONFIG_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

require_file() {
  local path="$1"
  local name="$2"
  if [[ ! -f "$path" ]]; then
    echo "Thiếu ISO $name: $path" >&2
    exit 1
  fi
}

create_vm() {
  local name="$1" vcpus="$2" ram_mb="$3" disk_gb="$4" iso="$5"

  if virsh dominfo "$name" >/dev/null 2>&1; then
    echo "VM '$name' đã tồn tại, bỏ qua."
    return
  fi

  virt-install \
    --name "$name" \
    --memory "$ram_mb" \
    --vcpus "$vcpus" \
    --cpu host \
    --disk "path=${VM_STORAGE_DIR}/${name}.qcow2,size=${disk_gb},format=qcow2,bus=sata" \
    --cdrom "$iso" \
    --network "network=${LAB_NET_NAME},model=e1000" \
    --os-variant win10 \
    --graphics spice \
    --video qxl \
    --boot cdrom,hd \
    --noautoconsole

  echo "Đã tạo VM '$name'."
}

mkdir -p "$VM_STORAGE_DIR"
require_file "$WS_ISO" "Windows Server"
require_file "$WIN7_ISO" "Windows 7"

create_vm "$WS_NAME" "$WS_VCPUS" "$WS_RAM_MB" "$WS_DISK_GB" "$WS_ISO"
create_vm "$WIN7_1_NAME" "$WIN7_1_VCPUS" "$WIN7_1_RAM_MB" "$WIN7_1_DISK_GB" "$WIN7_ISO"
create_vm "$WIN7_2_NAME" "$WIN7_2_VCPUS" "$WIN7_2_RAM_MB" "$WIN7_2_DISK_GB" "$WIN7_ISO"
