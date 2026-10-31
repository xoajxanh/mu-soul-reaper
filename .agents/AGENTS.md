# Mod Development & Deployment Workflow (`mu-soul-reaper`)

1. **Target Environment**: Chỉ làm việc trực tiếp trên `d:\MUVH\android\mu-soul-reaper\dev\client`.
2. **Quản lý Cấu trúc Thư mục & File Thực thi (Zero Clutter & Self-Contained)**:
   - Không tạo file rác hoặc dàn trải script ra thư mục gốc dự án.
   - Các file script/Python/tạm thời phục vụ quá trình test hoặc phân tích trong `excute_test` phải đặt gọn trong `d:\MUVH\android\mu-soul-reaper\excute_test\temp`.
   - **Độc lập hoàn toàn với dự án cũ (`mu-decompiled`)**: Tuyệt đối không gọi trực tiếp các tool hay thư viện bên thư mục `mu-decompiled` (MU Vĩnh Hằng). Khi cần dùng bất kỳ tool/thư viện nào từ bên đó, phải clone sang `d:\MUVH\android\mu-soul-reaper\tools` (hoặc `<thư_mục_quy_trình>\tools`) và cập nhật lại đường dẫn nội bộ để tránh mất dữ liệu khi xóa thư mục cũ.
   - **Quy tắc bắt buộc**: Khi cần tạo thư mục mới hoặc tạo file thực thi/tool cho một quy trình mới (reverse engineering, extract, decompile, compile, build,...), Agent **PHẢI hỏi ý kiến USER trước** để USER quyết định cấu trúc thư mục.
3. **Tham khảo & Tái sử dụng Thư viện Modules (`excute_test\modules`)**:
   - Trước khi làm bất cứ chức năng gì hoặc viết script test, Agent BẮT BUỘC phải kiểm tra và tham khảo thư mục `d:\MUVH\android\mu-soul-reaper\excute_test\modules` (đọc `README.md` và các file `.lua` / `.md` liên quan) trước tiên.
   - Tái sử dụng tối đa các method chuẩn đã được kiểm định trong `modules` để tránh mất thời gian tìm hiểu lại từ đầu hoặc mắc các lỗi cấu trúc dữ liệu đã biết.
   - Khi xây dựng và kiểm thử thành công một cơ chế/method mới, phải đóng gói bổ sung vào `d:\MUVH\android\mu-soul-reaper\excute_test\modules` (cả `.lua`, `.md` và cập nhật `README.md`) để dùng lại về sau.
4. **Ideation & Planning**: Luôn trao đổi, thảo luận phương án/kế hoạch cụ thể trước với USER. Không tự ý sửa code khi chưa thống nhất.
5. **Development & Approval**: Chờ USER phê duyệt phương án trước khi triển khai code.
6. **Code Commenting & Tagging**: Mọi khối code triển khai logic chức năng mới hoặc sửa đổi PHẢI có chú thích tên chức năng ở đầu logic theo định dạng chuẩn (ví dụ: `-- =========================================================================` / `-- [MOD FEATURE]: <TÊN CHỨC NĂNG>` / `-- Mô tả: ...`) để dễ dàng tìm kiếm (search text).
7. **Build & Release Structure**:
   - Code nguồn dev đặt tại `d:\MUVH\android\mu-soul-reaper\dev\client`.
   - Công cụ biên dịch & đóng gói bundle đặt tại `d:\MUVH\android\mu-soul-reaper\compiled\tools` (`compile_lua.py`, `pack_lua.py`).
   - Công cụ ký & đóng gói APK đặt tại `d:\MUVH\android\mu-soul-reaper\build` (`build.ps1`, `BUILD.bat`, `uber-apk-signer.jar`).
   - File APK xuất bản đặt tại `d:\MUVH\android\mu-soul-reaper\released\client`.
8. **Build Phase**: Chỉ chạy script build APK SAU KHI nhận được sự đồng ý rõ ràng từ USER.
9. **Push Test & Android Device**: USER tự chọn Android Device ID và tự chạy `push_test.ps1` để execute. Agent không can thiệp, không tự tìm Android ID hoặc push all devices, và tuyệt đối không tự ý sửa đổi `push_test.ps1` theo hướng đó.
