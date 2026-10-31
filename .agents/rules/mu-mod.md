---
trigger: always_on
---

# ⚡ QUY TẮC THỰC THI & KỸ THUẬT (MU SOUL REAPER WORKFLOW)

## 1. Tổ chức Thư mục & Quản lý File Gọn Gàng
- Dự án đặt gốc tại `d:\MUVH\android\mu-soul-reaper` (không dùng thư mục trung gian `final\`).
- **Độc lập hoàn toàn (Self-Contained)**: Không bao giờ gọi trực tiếp tool/thư viện từ thư mục `mu-decompiled` cũ. Cần dùng công cụ hay thư viện nào thì phải clone sang `d:\MUVH\android\mu-soul-reaper\tools` (hoặc `<module>\tools`) và chỉnh lại path nội bộ.
- **Hỏi trước khi tạo mới**: Trong quá trình làm việc, nếu phát sinh nhu cầu tạo thư mục mới hoặc tạo file thực thi/script cho một quy trình mới (extract, decompile, compile, build, tool phụ trợ...), Agent **BẮT BUỘC phải hỏi USER trước** để USER quyết định vị trí và cấu trúc thư mục.
- **Không xả rác ra thư mục gốc**: Mọi script Python, file phụ trợ hoặc dữ liệu trung gian phục vụ cho việc chạy thử/phân tích trong `excute_test` phải được gom vào `d:\MUVH\android\mu-soul-reaper\excute_test\temp`.

## 2. Tham khảo & Đóng gói Thư viện Modules (`excute_test\modules`)
- Trước khi bắt đầu làm BẤT CỨ chức năng gì hoặc viết script test, Agent BẮT BUỘC phải tham khảo thư mục:
  `d:\MUVH\android\mu-soul-reaper\excute_test\modules` (đọc `README.md` và các module `.lua` / `.md` tương ứng).
- Tuyệt đối không tự mò mẫm hoặc viết lại các method đã có sẵn trong `modules`, tránh tốn thời gian và tránh lặp lại các bẫy dữ liệu của game.
- Sau khi nghiên cứu và test thành công một tính năng/method mới, phải đóng gói cập nhật vào `d:\MUVH\android\mu-soul-reaper\excute_test\modules` để tái sử dụng lâu dài.

## 3. Thực thi lệnh tự động qua Master Executor
- USER đã cấp quyền phê duyệt vĩnh viễn cho Master Executor.
- Tuyệt đối KHÔNG chạy các câu lệnh terminal tùy ý trực tiếp qua `run_command` (sẽ bị hiện popup xin quyền).
- Khi cần chạy bất kỳ lệnh PowerShell, Python, Luac, Git, ADB, v.v.:
  * Dùng tool ghi nội dung kịch bản cần thực thi vào:
    `d:\MUVH\android\mu-soul-reaper\excute_test\exec_cmd.ps1`
  * Sau đó CHỈ gọi DUY NHẤT một câu lệnh cố định qua `run_command`:
    `powershell -ExecutionPolicy Bypass -File d:\MUVH\android\mu-soul-reaper\excute_test\executor.ps1`
  * Script `executor.ps1` sẽ tự động chạy `exec_cmd.ps1`, xuất output chuẩn UTF-8 và bắt lỗi chi tiết.

## 4. Quy trình tạo Script Test / Debug nhanh & Quản lý Thiết bị Android
- Khi USER yêu cầu viết script thử nghiệm / test / debug một logic mới:
  * Agent CHỈ ĐƯỢC PHÉP chỉnh sửa/ghi mã nguồn Lua vào file:
    `d:\MUVH\android\mu-soul-reaper\excute_test\input.txt`
  * Khi script test cần xuất dữ liệu kết quả, PHẢI ghi trực tiếp vào `output.txt` thông qua `CS.UnityEngine.Application.persistentDataPath .. "/output.txt"`. Tuyệt đối KHÔNG tạo file tên khác, vì `push_test.ps1` chỉ pull đúng file `output.txt` về máy.
  * **Quy tắc Push Test & Android Device**: USER tự chọn Android Device ID và tự chạy `push_test.ps1` (hoặc `Run_Push_Test.bat`) để execute. Agent không can thiệp, không tự tìm Android ID hoặc push all devices, và TUYỆT ĐỐI KHÔNG tự ý sửa đổi `push_test.ps1` theo hướng đó.

## 5. Môi trường Code Chính thức
- Chỉ chỉnh sửa code chính thức trực tiếp trên `d:\MUVH\android\mu-soul-reaper\dev\client`.
- Luôn thảo luận kế hoạch và chỉ triển khai code khi được USER đồng ý.
- Không tự ý chạy script build APK khi chưa có yêu cầu từ USER.

---

## 🛠️ CÁC ĐƯỜNG DẪN QUAN TRỌNG
* `d:\MUVH\android\mu-soul-reaper\dev\client\`: Thư mục mã nguồn Dev Client chính.
* `d:\MUVH\android\mu-soul-reaper\base\`: Chứa Base APK (`MU_base.apk`), Base Bundle (`lua.mu2`) và `bundles.txt`.
* `d:\MUVH\android\mu-soul-reaper\compiled\tools\`: Chứa công cụ biên dịch & đóng gói Lua (`compile_lua.py`, `pack_lua.py`).
* `d:\MUVH\android\mu-soul-reaper\build\`: Chứa công cụ build & sign APK (`build.ps1`, `BUILD.bat`, `uber-apk-signer.jar`).
* `d:\MUVH\android\mu-soul-reaper\released\client\`: Chứa APK đầu ra của bản Client (`MU_client.apk`).
* `d:\MUVH\android\mu-soul-reaper\tools\`: Chứa bộ công cụ dùng chung (`unluac.jar`, `lua53`, `convert_64_to_32.py`,...).
* `d:\MUVH\android\mu-soul-reaper\extracted\luas\`: Chứa toàn bộ mã nguồn Lua gốc đã decompile.
* `d:\MUVH\android\mu-soul-reaper\excute_test\modules\`: Thư viện Modules chuẩn đã kiểm định.
* `d:\MUVH\android\mu-soul-reaper\excute_test\temp\`: Thư mục chứa các file Python / script / dữ liệu tạm phục vụ `excute_test`.
* `d:\MUVH\android\mu-soul-reaper\excute_test\input.txt`: File chứa script test Lua cho Execute Admin.
* `d:\MUVH\android\mu-soul-reaper\excute_test\executor.ps1`: File nhận lệnh trung tâm (cố định).
* `d:\MUVH\android\mu-soul-reaper\excute_test\exec_cmd.ps1`: File chứa kịch bản thực thi terminal động.
