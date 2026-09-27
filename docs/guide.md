# Hướng dẫn dựng lab QEMU/KVM cho Windows

## 1) Kiến trúc lab
- Host: Linux có hỗ trợ VT-x/AMD-V.
- VM:
  - `ws01` (Windows Server)
  - `win7-01` (Windows 7)
  - `win7-02` (Windows 7)
- Network lab: `lab-net` (NAT qua libvirt), dải mặc định `192.168.77.0/24`.

## 2) Điều kiện tiên quyết
Cài tối thiểu:
- `qemu-kvm`
- `libvirt-daemon-system`
- `virtinst`
- `bridge-utils` (tuỳ distro)

Ví dụ (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system virtinst bridge-utils
sudo systemctl enable --now libvirtd
```

## 3) Chuẩn bị cấu hình
```bash
cp config/lab.env.example config/lab.env
```
Sửa `config/lab.env`:
- Đường dẫn ISO Windows Server và Windows 7
- VCPU/RAM/Disk cho từng máy

## 4) Tạo network lab
```bash
bash scripts/create-network.sh config/lab.env
```
Script sẽ:
- Tạo network `lab-net` nếu chưa có
- Đặt gateway mặc định `192.168.77.1`
- Bật autostart

## 5) Tạo 3 máy ảo
```bash
bash scripts/create-vms.sh config/lab.env
```
Script sẽ tạo:
- `ws01`
- `win7-01`
- `win7-02`

## 6) Sau khi cài đặt OS
Khuyến nghị:
- Cài VirtIO driver và QEMU guest agent
- Đặt IP tĩnh theo nhu cầu lab
- Tạo snapshot baseline:
  ```bash
  virsh snapshot-create-as ws01 baseline "clean install"
  virsh snapshot-create-as win7-01 baseline "clean install"
  virsh snapshot-create-as win7-02 baseline "clean install"
  ```
