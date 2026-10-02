# Hướng dẫn tải ISO cho Lab KVM

## 1. Windows Server 2022 Evaluation (Chính thức, Miễn phí 180 ngày)

**Nguồn**: Microsoft Evaluation Center — hoàn toàn hợp lệ cho học thuật.

1. Truy cập: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022
2. Chọn **ISO downloads** (không cần Azure)
3. Đăng ký theo hướng dẫn của Microsoft
4. Tải file ISO
5. Đổi tên thành `win-server-2022.iso`
6. Copy vào `/mnt/lab-vms/ISOs/win-server-2022.iso`

Lệnh copy nhanh (thay đường dẫn file tải về):
```bash
cp ~/Downloads/SERVER_EVAL_x64FRE_en-us.iso /mnt/lab-vms/ISOs/win-server-2022.iso
```

> Microsoft cho biết bản Evaluation hết hạn sau 180 ngày và cần kích hoạt qua
> Internet trong 10 ngày đầu sau khi cài đặt.

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

Windows 7 đã EOL (2020). Các nguồn tham khảo cho bộ cài:

### Option A: Nếu bạn có subscription (khuyến nghị)
- **Azure Dev Tools for Teaching** (trường/đại học): https://azureforeducation.microsoft.com/devtools
- **MSDN / Visual Studio subscription**: https://my.visualstudio.com/downloads

### Option B: Internet Archive (bản lưu trữ lịch sử)
- https://archive.org/details/win-7-pro-sp-1-x-64
- Tìm: "Windows 7 SP1 x64" — chọn bản có SHA1 match với MSDN checksums

Script hiện tại chỉ tạo client từ `win7.iso` với `--os-variant win7`. Muốn dùng
Windows 10 cần sửa cấu hình tạo VM trước; đặt tên file là `win10.iso` sẽ không
được script nhận. Với Windows 7, đổi tên ISO thành `win7.iso` và đặt tại
`/mnt/lab-vms/ISOs/win7.iso`.

---

## Kiểm tra sau khi tải xong

```bash
ls -lh /mnt/lab-vms/ISOs/
# Phải thấy:
# win-server-2022.iso
# virtio-win.iso
# win7.iso (cần để tạo mới 2 VM Windows 7)
```

Sau đó chạy:
```bash
~/lab-kvm/scripts/create-vms.sh
```

Để tải Firefox 115 ESR cho Windows 7, đóng gói ISO và gắn vào ba máy ảo,
xem [mục Firefox trong README](README.md#put-firefox-installers-in-the-windows-guests).
