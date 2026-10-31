# ⚔️ MODULE 6: DI CHUYỂN & TÁC CHIẾN (MOVEMENT & COMBAT)

## 📌 File Code: [`mod_movement_combat.lua`](./mod_movement_combat.lua)

Module này chuyên trách việc điều khiển nhân vật di chuyển tới tọa độ, xử lý triệt để bài toán **"Cắm đầu chạy không được đánh quái"**, và quản lý bật/tắt AutoFight một cách khoa học.

---

### 📍 Bài Học Xương Máu: Vừa Chạy Vừa Đánh Quái

* **Hiện tượng lỗi**: Khi bot nhận lệnh chạy đến vị trí trong Huyết Lâu / Quảng Trường Quỷ hoặc bãi train, nhân vật vừa chạy vài bước lại quay sang vung gậy/chém quái bên đường, làm chậm tốc độ tiếp cận bãi.
* **Nguyên nhân**: Trong vòng lặp tick (mỗi giây), code gọi `me:MoveTo(...)` nhưng lại **tiện tay gọi luôn `me:SetAutoFight("AutoFight")` ra ngoài**. Khi `SetAutoFight` được bật, AI của game quét thấy quái gần đó -> lập tức lock `TargetAvatar` và tung skill.
* **Giải pháp chuẩn đã kiểm định**:
  ```lua
  local dist = math.sqrt((curX - tx)^2 + (curY - ty)^2)
  if dist > 1.5 then
      -- BƯỚC 1: Dừng đánh
      if me.isAutoFight then
          if me.StopAutoFight then me:StopAutoFight() end
          _G.EventManager.Dispatch(_G.Event.Role_StopAutoFight)
      end
      -- BƯỚC 2: Hủy mục tiêu quái đang lock
      me.TargetAvatar = nil
      -- BƯỚC 3: Cắm đầu chạy
      me:MoveTo({ x = tx, y = ty }, 0)
      return -- DỪNG TICK NÀY, TUYỆT ĐỐI KHÔNG BẬT AUTOFIGHT!
  else
      -- Đã vào cự ly <= 1.5m -> Bật AutoFight
      if me.SetAutoFight and not me.isAutoFight then
          me:SetAutoFight("AutoFight")
      end
  end
  ```

---

### 💡 Các Hàm Tiện Ích Trong Module

* `ModMovementCombat.StopFightAndClearTarget()`: Tắt AutoFight và hủy target ngay lập tức.
* `ModMovementCombat.MoveToCoord(tx, ty, stopRadius)`: Chạy tới tọa độ cell.
* `ModMovementCombat.StartAutoFight()`: Kích hoạt AutoFight an toàn.
* `ModMovementCombat.RushToCoord(tx, ty, threshold, onArrived)`: Một hàm duy nhất tự động phân luồng cắm đầu chạy khi `dist > threshold` và bật đánh khi `dist <= threshold`.

---

### 🛡️ Quy Tắc Auto Hunt Khi Ở Bãi Train
* **Khi đi săn ngoài bãi train**: `RoleTargetManager.IsCanAttackMonster` trả về `false` để nhân vật chỉ săn người/PK, tuyệt đối không bị quái ven đường cản trở.
* **Khi về tới bãi train (`Mod_IsAtTrainSpot()`)**: `IsCanAttackMonster` cho phép đánh quái bình thường, PK Scan loop duy trì `AutoFight` để nhân vật tiếp tục cày cấp/đồ trong thời gian chờ Boss tiếp theo.

