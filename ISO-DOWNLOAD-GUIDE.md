# Hướng dẫn tải ISO cho Lab KVM

## 1. Windows Server 2022 Evaluation (Chính thức, Miễn phí 180 ngày)

**Nguồn**: Microsoft Evaluation Center — hoàn toàn hợp lệ cho học thuật.

1. Truy cập: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022
2. Chọn **ISO downloads** (không cần Azure)
3. Điền form đăng ký (có thể dùng email bất kỳ)
4. Tải file ISO ~5.4 GB
5. Đổi tên thành `win-server-2022.iso`
6. Copy vào `/mnt/lab-vms/ISOs/win-server-2022.iso`

Lệnh copy nhanh (thay đường dẫn file tải về):
```bash
cp ~/Downloads/SERVER_EVAL_x64FRE_en-us.iso /mnt/lab-vms/ISOs/win-server-2022.iso
```

> Key license: KHÔNG cần key — Evaluation mode tự kích hoạt 180 ngày.
> Có thể extend thêm 5 lần (tổng ~3 năm) bằng `slmgr /rearm`.

---

## 2. VirtIO Drivers ISO (Bắt buộc cho Windows nhận disk/NIC)

**Nguồn**: Fedora Project — official, miễn phí.

```bash
# Tải thẳng bằng wget (không cần browser)
wget -O /mnt/lab-vms/ISOs/virtio-win.iso \
  https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

Hoặc tải trang: https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md

---

## 3. Windows 7 SP1

Windows 7 đã EOL (2020). Các tùy chọn hợp pháp cho học thuật:

### Option A: Nếu bạn có subscription (khuyến nghị)
- **Azure Dev Tools for Teaching** (trường/đại học): https://azureforeducation.microsoft.com/devtools
- **MSDN / Visual Studio subscription**: https://my.visualstudio.com/downloads

### Option B: Internet Archive (lưu trữ lịch sử, academic use)
- https://archive.org/details/win-7-pro-sp-1-x-64
- Tìm: "Windows 7 SP1 x64" — chọn bản có SHA1 match với MSDN checksums

### Option C: Chuyển sang Windows 10 LTSC 2019
Nếu mục tiêu là học SysAdmin (Group Policy, domain join, event logs):
- Windows 10 LTSC 2019 Evaluation hoạt động tốt hơn Win7 với VirtIO
- Tải tại: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-10-enterprise

> Tên file sau khi tải: đổi thành `win7.iso` (hoặc `win10.iso` nếu dùng Win10)
> Đặt vào: `/mnt/lab-vms/ISOs/win7.iso`

---

## Kiểm tra sau khi tải xong

```bash
ls -lh /mnt/lab-vms/ISOs/
# Phải thấy:
# win-server-2022.iso  (~5.4 GB)
# virtio-win.iso       (~600 MB)
# win7.iso             (~3.2 GB) hoặc win10.iso (~5 GB)
```

Sau đó chạy:
```bash
~/lab-kvm/scripts/create-vms.sh
```
