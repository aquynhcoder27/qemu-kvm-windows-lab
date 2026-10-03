# Hướng dẫn tải ISO cho Lab KVM

## 1. Windows Server 2008 R2 SP1 x64

Nếu có quyền truy cập Visual Studio subscription hoặc bộ cài gốc, hãy dùng ISO
từ nguồn đó. Tên bộ cài tiếng Anh chứa các bản Standard, Enterprise, Datacenter
và Web là `en_windows_server_2008_r2_with_sp1_x64_dvd_617601.iso`.
[Danh mục ảnh gốc](https://www.heidoc.net/php/myvsdump_details.php?id=P781F44782Ax64Len)
ghi SHA-1 `d3fd7bf85ee1d5bdd72de5b2c69a7b470733cd0a`.

Nếu không có ISO gốc, [Internet Archive lưu bản sao](https://archive.org/details/en_windows_server_2008_r2_with_sp1_x64_dvd_617601_202405).
Đây là nguồn bên thứ ba; tải xong phải so SHA-1 với giá trị ở trên trước khi dùng.

```bash
curl -fL --retry 3 --continue-at - \
  -o /mnt/lab-vms/ISOs/win-server-2008-r2-sp1.iso \
  https://archive.org/download/en_windows_server_2008_r2_with_sp1_x64_dvd_617601_202405/en_windows_server_2008_r2_with_sp1_x64_dvd_617601.iso
printf '%s  %s\n' \
  d3fd7bf85ee1d5bdd72de5b2c69a7b470733cd0a \
  /mnt/lab-vms/ISOs/win-server-2008-r2-sp1.iso | sha1sum --check
```

Windows Server 2008 R2 cần giấy phép hợp lệ để sử dụng. [Microsoft đã kết thúc hỗ
trợ Server 2008 R2 vào 14/01/2020](https://learn.microsoft.com/en-us/lifecycle/products/windows-server-2008-r2).
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
# win-server-2008-r2-sp1.iso
# virtio-win.iso
# win7.iso (cần để tạo mới 2 VM Windows 7)
```

Sau đó chạy:
```bash
~/lab-kvm/scripts/create-vms.sh
```

Để tải Firefox 115 ESR cho Windows 7, đóng gói ISO và gắn vào ba máy ảo,
xem [mục Firefox trong README](README.md#put-firefox-installers-in-the-windows-guests).
