# Magnet MODULE 9: QUÉT & VÉT ĐỒ TRÊN MẶT ĐẤT (GROUND ITEM SWEEPER / HOOVER)

## 📌 File Code: [`mod_ground_pickup.lua`](./mod_ground_pickup.lua)

Module này chịu trách nhiệm quét 100% vật phẩm rơi trên mặt đất (vàng khóa, zen, trang bị, ngọc, rương...) và thực hiện hút/vét đồ tự động từ xa hoặc điều hướng nhân vật chạy tới nhặt.

---

### ⚠️ BẪY LỚN CẦN TRÁNH TUYỆT ĐỐI (CRITICAL GOTCHA)

* **SAI LẦM PHỔ BIẾN**:
  ```lua
  -- SAI: Chỉ lấy upvalue dropItems của DropItemManager.GetDropItemById
  local _, dropItems = debug.getupvalue(_G.DropItemManager.GetDropItemById, 1)
  ```
  * **Nguyên nhân lỗi**: Trong `DropItemManager.OnDropItemEnterView`, khi vật phẩm rơi ra từ quái chết (`dropItemData.isMonsterDeath == true`), game gọi `PutDropItemInWhenIamVip(dropItemData)`. Nếu thỏa điều kiện VIP auto-pickup (hoặc trong các map đặc biệt như Hang Động Vàng `260001`), hàm này `return` ngay lập tức mà **KHÔNG** lưu vào `DropItemManager.dropItems` (làm `dropItems` có 0 phần tử!).
* **CÁCH ĐÚNG 100% ĐÃ KIỂM ĐỊNH**:
  1. **Nguồn 1 (`ViewData.GetGameObjectsInView()`)**: Mọi gói tin `ServerViewController.ItemEnterView` từ Server gửi về đều bắt buộc đi qua `ViewData.AddItem` và lưu vào `gameObjectDataCollection`. Khi nhặt xong, `ViewData.RemoveGameObject(id)` tự động xóa khỏi bảng này. Đây là nguồn chuẩn xác tuyệt đối 100%.
  2. **Nguồn 2 (`VipManager.Update` upvalue 1 `vipAutoPickDropItems`)**: Nơi chứa các vật phẩm được phân luồng sang VIP Auto-Pickup.
  3. **Nguồn 3 (`DropItemManager.GetDropItemById` upvalue `dropItems`)**: Nơi chứa các vật phẩm rơi thông thường không qua VIP.

---

### 📍 Cấu Trúc Thực Tế Của Cọc Đồ Trong `ViewData`

Ví dụ thực tế từ Hang Động Vàng (Map `260001`):
* `id`: `5944970078628420671` (Instance ID trên bản đồ - dùng để truyền vào `ReqPickUpMapItem`)
* `configID` / `item.itemId`: `1000021` (Vàng Khóa)
* `name`: `"Vàng Khoá"`
* `item.count`: `50000`
* `x`, `y`: `78`, `109` (Tọa độ ô lưới Server)
* `type`: `103` (`EResourcesType.QiJiBi`)
* `isMonsterDeath`: `true`

---

### 💡 Ví Dụ Sử Dụng

```lua
-- 1. Quét toàn bộ vật phẩm trên đất
local drops = _G.Mod_GetGroundDropItems()
if #drops > 0 then
    -- 2. Vét sạch đồ trên đất (bắn cả ReqPickUpMapItem đơn lẻ lẫn ReqPickUpMapItems batch)
    local res = _G.Mod_SweepGroundItems({
        allowMove = false -- Map nhỏ (như Hang Động Vàng) chỉ cần hút từ xa, không cần chạy bộ
    })
else
    -- Khi #drops == 0 nghĩa là toàn bộ đồ trên sàn đã được hút sạch!
end
```

