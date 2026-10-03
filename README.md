# Lab Windows trên KVM

Project này phục vụ các bài thực hành trong `.exercises/`. Trên host hiện tại,
điều quan trọng nhất là **ba VM đã cài và đang hoạt động**; không cần chạy lại
script tạo VM để bắt đầu làm bài. Ảnh đĩa và ISO nằm ở `/mnt/lab-vms/`, ngoài Git.

## Ba máy đang dùng

| VM libvirt | Hệ điều hành | IPv4 tĩnh | Vai trò ban đầu |
| --- | --- | --- | --- |
| `win-srv-01` | Windows Server 2008 R2 SP1 Standard x64 | `192.168.122.10` | Server |
| `win-w7-01` | Windows 7 SP1 x64 | `192.168.122.11` | Client 01 |
| `win-w7-02` | Windows 7 SP1 x64 | `192.168.122.12` | Client 02 |

Cả ba nối vào mạng libvirt `default` (`192.168.122.0/24`), gateway và DNS hiện
là `192.168.122.1`. DHCP chỉ cấp `.100–.254`, không trùng ba IP tĩnh. Các máy
đã ping qua lại, có Internet và chạy OpenSSH; Server có PowerShell 2.0. Tình
trạng này được kiểm tra lần cuối ngày 2026-10-03, nên kiểm tra lại trước khi
thay đổi một dịch vụ mạng. Windows 7 và Server 2008 R2 đã hết hỗ trợ; giữ
firewall bật và chỉ dùng Internet khi cần cho bài lab.

### Vận hành hằng ngày

```bash
virsh list --all
scripts/lab-vm.sh list
scripts/lab-vm.sh start win-srv-01
scripts/lab-vm.sh start win-w7-01
scripts/lab-vm.sh start win-w7-02
scripts/lab-vm.sh console win-srv-01
scripts/lab-vm.sh stopall
```

`lab-vm.sh` kiểm tra ổ lưu VM trước khi khởi động và cho phép chạy cả ba máy.
Lệnh `ip` trong script đọc DHCP lease nên có thể hiện `unknown` cho IP tĩnh;
dùng `ipconfig /all` trong Windows để xác nhận. Nếu host không thấy ảnh đĩa,
kiểm tra mount `/mnt/lab-vms/` trước khi khởi động.

Truy cập SSH từ host: `ssh -tt Administrator@192.168.122.10`,
`ssh -tt Client01@192.168.122.11`, hoặc
`ssh -tt Client02@192.168.122.12`. Thông tin đăng nhập chỉ nằm trong ghi chú
cục bộ `.agent/`, không đưa vào repo hay ảnh chụp.

## Làm bài tập và lưu minh chứng

1. Chọn **một bài cụ thể** trong bốn PDF cục bộ ở `.exercises/` và đọc yêu cầu,
   sơ đồ máy, địa chỉ IP của bài đó.
2. Đối chiếu yêu cầu với ba VM hiện có. Tài liệu Nhất Nghệ dùng Server 2008
   và Windows 7 nên là điểm khởi đầu hợp lý; ba PDF BKAP dùng Server 2012,
   có giao diện và một số tính năng khác. Không áp dụng nguyên xi địa chỉ IP
   trong PDF vì lab đang dùng `192.168.122.0/24`.
3. Ghi từng bước, kết quả kiểm tra, ảnh chụp và giải thích tại
   [evidence/](evidence/README.md). Đây là nguồn để Agent lập báo cáo kết quả
   sau này. Ghi rõ chỗ làm khác tài liệu gốc và lý do.

Nên bắt đầu từ **Lab 01** của tài liệu Server 2008/Windows 7 (IP, local user,
chia sẻ dữ liệu và máy in). Các lab về domain, nhiều mạng, TMG, VPN hoặc
nhiều domain controller có thể cần đổi vai trò máy, thêm NIC/VM hay phần mềm;
kiểm tra từng bài trước khi triển khai. Khi dựng AD/DNS, cấu hình DNS trên
Server và forwarder trước, sau đó mới chuyển DNS của client từ `.1` sang
`192.168.122.10`, nếu không client có thể mất phân giải tên Internet.

## Phần cấu hình chỉ dùng khi cần sửa hoặc dựng lại lab

- `scripts/`: mount ổ, cài libvirt, tạo và vận hành VM. `create-vms.sh` bỏ qua
  VM/ảnh đĩa đã tồn tại, không cập nhật cấu hình Windows bên trong guest.
- `config.sh` và `config.local.sh`: cấu hình mặc định và ghi đè riêng của host;
  file local được Git bỏ qua. Trên host này `LAB_NET=default`. Mạng mẫu
  `networks/lab-nat.xml` dùng `192.168.233.0/24` **không phải mạng của ba VM hiện tại**.
- `guest-tools/`: script cài OpenSSH và mở ICMP trong guest. Script PowerShell
  ở đây chỉ dành cho bản Server 2008 SP2 cũ; **không chạy trên Server 2008 R2**.
- [ISO-DOWNLOAD-GUIDE.md](ISO-DOWNLOAD-GUIDE.md): nguồn cài đặt nếu cần dựng
  lại máy. Không cần tải ISO để tiếp tục làm bài trên ba VM hiện có.
- `.agent/` và `.exercises/`: ghi chú Agent, thông tin cục bộ và PDF bài tập;
  cả hai không được push lên GitHub.

Trước khi sửa libvirt hoặc dịch vụ mạng, xem trạng thái thật bằng `virsh list
--all`, `virsh domblklist <vm> --details`, `virsh net-dumpxml default` và
`ipconfig /all` trong guest. Các đợt phát triển cũ đã dùng Server 2008 SP2 và
một NAT khác; cấu hình thực tế của ba VM ở bảng trên là mốc hiện hành.
