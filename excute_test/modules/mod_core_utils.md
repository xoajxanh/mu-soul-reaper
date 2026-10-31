# ⚙️ MODULE 8: TIỆN ÍCH LÕI CỦA MOD (CORE UTILS)

## 📌 File Code: [`mod_core_utils.lua`](./mod_core_utils.lua)

Module này đóng vai trò hạt nhân cung cấp các tiện ích hệ thống: Quản lý Timer chống leak, Lưu/Đọc cấu hình người chơi (PlayerPrefs), Thông báo màn hình và Ghi nhật ký vào `output.txt`.

---

### 📍 Các Đoạn Code Đã Dùng Trong Mod Nguồn

1. **Quản Lý Timer Có Theo Dõi (`Mod_StartTrackedTimer`)**:
   * *Nguồn gốc: `EmmyluaDebug.lua` lines 9600-9620*:
     * Kiểm tra `_G.Mod_ActiveTrackedTimers[name]` và dừng trước khi tạo mới.
     * Sử dụng `Timer.New(func, interval, count):Start()`.
     * **Ưu điểm**: Khi hot-reload qua `input.txt` hoặc bật/tắt tính năng trên menu mod, không bao giờ lo bị chạy song song 2 timer cùng một việc!

2. **Lưu Trữ Cấu Hình (`CS.UnityEngine.PlayerPrefs`)**:
   * *Nguồn gốc: `EmmyluaDebug.lua` lines 500-540*:
     * Hỗ trợ lưu trạng thái Toggle (0/1), số nguyên và chuỗi tọa độ `14#60`.
     * Luôn gọi `PlayerPrefs.Save()` sau khi ghi để lưu vĩnh viễn trên thiết bị.

3. **Ghi Dữ Liệu Ra `output.txt`**:
   * *Nguồn gốc: `EmmyluaDebug.lua` & `input.txt`*:
     * Ghi vào: `CS.UnityEngine.Application.persistentDataPath .. "/output.txt"`.
     * Đây là file đích cố định duy nhất mà `push_test.ps1` pull về máy tính.
