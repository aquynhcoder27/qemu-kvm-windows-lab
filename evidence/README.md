# Minh chứng bài thực hành

Thư mục này lưu ảnh chụp và lời giải thích để viết báo cáo từ kết quả **đã
thực hiện** trên ba VM. PDF gốc nằm riêng tại `.exercises/` và không được đưa
vào Git.

## Cách ghi một bài

1. Tạo mục bài trong [INDEX.md](INDEX.md): mã bài, tên PDF, trang hoặc phần,
   mục tiêu, VM dùng và trạng thái (`chưa làm`, `đang làm`, `xong`, `bị chặn`).
2. Chụp màn hình vào `images/` bằng tên
   `<nguon>-<bai>-<so>-<noi-dung>.png`, ví dụ
   `nn08-l01-01-ipconfig-server.png`. Dùng mã nguồn `nn08` cho tài liệu
   Server 2008/Windows 7, `bkap12-p1`, `bkap12-p2`, `bkap12-p3` cho ba PDF BKAP.
3. Thêm **một dòng giải thích cho mỗi ảnh** trong INDEX: máy, yêu cầu trong
   PDF, thao tác hoặc phép kiểm tra, kết quả nhìn thấy, và vì sao kết quả đó
   chứng minh bài đã đạt. Ghi trang PDF và các khác biệt so với tài liệu.
4. Ghi cả lỗi và cách khắc phục nếu chúng ảnh hưởng đến kết quả. Báo cáo sau
   này nên phân biệt phần đã kiểm chứng với phần còn dự kiến.

Chụp đủ khung hình để thấy tên máy hoặc địa chỉ, lệnh/thông số và kết quả.
Ẩn mật khẩu, khóa, thông tin cá nhân và token trước khi lưu ảnh. Không đổi
tên ảnh đã được INDEX tham chiếu nếu chưa sửa lại đường dẫn.

Ba VM hiện tại là `win-srv-01` (`.10`), `win-w7-01` (`.11`) và
`win-w7-02` (`.12`) trên `192.168.122.0/24`. Khi PDF yêu cầu mạng hoặc số VM
khác, ghi rõ cách ánh xạ hoặc lý do bài bị chặn. Kiểm tra tính năng Server
2012 trong PDF BKAP với Server 2008 R2 trước khi cấu hình.
