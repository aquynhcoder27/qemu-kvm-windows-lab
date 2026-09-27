#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-config/lab.env}"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Không tìm thấy file cấu hình: $CONFIG_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

if virsh net-info "$LAB_NET_NAME" >/dev/null 2>&1; then
  echo "Network '$LAB_NET_NAME' đã tồn tại, bỏ qua tạo mới."
  exit 0
fi

TMP_XML="$(mktemp)"
trap 'rm -f "$TMP_XML"' EXIT

cat > "$TMP_XML" <<XML
<network>
  <name>${LAB_NET_NAME}</name>
  <forward mode='nat'/>
  <ip address='${LAB_NET_GATEWAY}' netmask='${LAB_NET_NETMASK}'>
    <dhcp>
      <range start='${LAB_NET_DHCP_START}' end='${LAB_NET_DHCP_END}'/>
    </dhcp>
  </ip>
</network>
XML

virsh net-define "$TMP_XML"
virsh net-start "$LAB_NET_NAME"
virsh net-autostart "$LAB_NET_NAME"

echo "Đã tạo network '$LAB_NET_NAME'."
