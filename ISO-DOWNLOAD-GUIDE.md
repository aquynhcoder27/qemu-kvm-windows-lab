# Hướng dẫn tải ISO cho Lab KVM

## 1. Windows Server 2008 SP2 x64 (bản thường, không phải R2)

Nếu có quyền truy cập Visual Studio subscription hoặc bộ cài gốc, hãy dùng ISO
từ nguồn đó. Tên bản x64 tiếng Anh là
`en_windows_server_2008_with_sp2_x64_dvd_342336.iso`; mã SHA-1 được liệt kê
[ở đây](https://www.heidoc.net/php/myvsdump_details.php?id=P634F38998Ax64Len)
là `34c7d726c57b0f8b19ba3b40d1b4044c15fc2029`.

Nếu không có ISO gốc, [Internet Archive lưu bản sao](https://archive.org/details/en_windows_server_2008_with_sp2_x64_dvd_342336_202212).
Đây là nguồn bên thứ ba; tải xong phải so SHA-1 với giá trị ở trên trước khi dùng.

```bash
curl -fL --retry 3 --continue-at - \
  -o /mnt/lab-vms/ISOs/win-server-2008.iso \
  https://archive.org/download/en_windows_server_2008_with_sp2_x64_dvd_342336_202212/en_windows_server_2008_with_sp2_x64_dvd_342336.iso
printf '%s  %s\n' \
  34c7d726c57b0f8b19ba3b40d1b4044c15fc2029 \
  /mnt/lab-vms/ISOs/win-server-2008.iso | sha1sum --check
```

Windows Server 2008 cần giấy phép hợp lệ để sử dụng. [Microsoft đã kết thúc hỗ
trợ Server 2008 vào 14/01/2020](https://learn.microsoft.com/en-us/lifecycle/announcements/prepare-end-of-support-2019-2020).
Chỉ bật kết nối mạng khi cần cho bài lab.

---

## 2. VirtIO Drivers ISO (cho các máy Windows 7)

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
# win-server-2008.iso
# virtio-win.iso
# win7.iso (cần để tạo mới 2 VM Windows 7)
```

Sau đó chạy:
```bash
~/lab-kvm/scripts/create-vms.sh
```

Để tải Firefox 115 ESR cho Windows 7, đóng gói ISO và gắn vào ba máy ảo,
xem [mục Firefox trong README](README.md#put-firefox-installers-in-the-windows-guests).
