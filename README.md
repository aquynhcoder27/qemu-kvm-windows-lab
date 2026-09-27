# qemu-kvm-windows-lab

Project hướng dẫn dựng lab QEMU/KVM để học quản trị Windows với:
- 01 Windows Server (`ws01`)
- 02 Windows 7 (`win7-01`, `win7-02`)

## Mục tiêu
- Tạo môi trường lab chuẩn, có thể lặp lại.
- Có sẵn scripts để dựng network và VM.
- Có documents để triển khai từ đầu đến sau cài đặt.

## Cấu trúc repository
- `docs/guide.md`: hướng dẫn đầy đủ từng bước.
- `scripts/create-network.sh`: tạo NAT network cho lab bằng `virsh`.
- `scripts/create-vms.sh`: tạo 3 VM bằng `virt-install`.
- `config/lab.env.example`: biến cấu hình mẫu.

## Quickstart
1. Cài đặt các gói cần thiết theo `docs/guide.md`.
2. Copy file cấu hình mẫu:
   ```bash
   cp config/lab.env.example config/lab.env
   ```
3. Chỉnh lại đường dẫn ISO và tài nguyên trong `config/lab.env`.
4. Tạo network:
   ```bash
   bash scripts/create-network.sh config/lab.env
   ```
5. Tạo VM:
   ```bash
   bash scripts/create-vms.sh config/lab.env
   ```

## Lưu ý
- Cần quyền `sudo` hoặc user thuộc nhóm `libvirt`/`kvm`.
- Không commit file ISO và disk image (`qcow2`) lên git.
