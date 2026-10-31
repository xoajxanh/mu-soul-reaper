# 🎒 MODULE 2: QUẢN LÝ & TRA CỨU TÚI ĐỒ (BAG ITEMS)

## 📌 File Code: [`mod_bag_items.lua`](./mod_bag_items.lua)

Module này chuyên trách việc quét túi đồ, đếm số lượng, tìm kiếm vật phẩm theo Config ID hoặc Tên, và lấy Instance ID để tương tác.

---

### ⚠️ BẪY LỚN CẦN TRÁNH TUYỆT ĐỐI (CRITICAL GOTCHA)
* **SAI LẦM PHỔ BIẾN CỦA AGENT**:
  ```lua
  -- SAI: Biến bagItems KHÔNG HỀ TỒN TẠI trong BagInfoData.lua! Luôn bị nil!
  for _, item in pairs(_G.BagInfoData.bagItems) do ... end
  ```
* **CÁCH ĐÚNG 100% ĐÃ KIỂM ĐỊNH**:
  ```lua
  -- ĐÚNG: Dữ liệu thật nằm trong TotalItems
  for _, item in pairs(_G.BagInfoData.TotalItems) do ... end
  
  -- HOẶC dùng hàm có sẵn của game:
  local item = _G.BagInfoData.GetItemByConfigID(3000400)
  local count = _G.BagInfoData.GetItemTotalCountByItemId(3000400)
  ```

---

### 📍 Các Đoạn Code Đã Dùng Trong Mod Nguồn

1. **Lấy danh sách vật phẩm trong túi**:
   * *Line 4187-4188, 4806-4808, 19031-19033*:
     ```lua
     local items = _G.BagInfoData and _G.BagInfoData.TotalItems
     if not items and _G.BagInfoData and _G.BagInfoData.GetTotalItems then
         pcall(function() items = _G.BagInfoData:GetTotalItems() end)
     end
     ```
2. **Đếm số lượng vé/vật phẩm**:
   * *Line 7467-7468 (Đếm ngọc hồi sinh), Line 9892-9893 (Đếm vé Huyết Lâu/QTQ), Line 20364 (Đếm Kim Phiếu `1000193`)*:
     ```lua
     local count = _G.BagInfoData.GetItemTotalCountByItemId(itemId) or 0
     ```
2b. **Lấy số dư Tiền tệ / Vàng Khóa (`1000021`), Vàng thường (`1000020`), Kim Cương (`1000030`)**:
   * ⚠️ **BẪY QUAN TRỌNG**: Không dùng `GetItemTotalCountByItemId(1000021)` để lấy riêng Vàng Khóa vì hàm đó tự cộng gộp cả `bindEqualItem` (`1000020` Vàng không khóa).
   * ✅ **CÁCH CHUẨN 100%**: Truy cập trực tiếp bảng `BagInfoData.CoinInfos[1000021]` hoặc `BagInfoData.GetItemCountByItemConfigId(1000021)`:
     ```lua
     local boundGold = (_G.BagInfoData.CoinInfos and _G.BagInfoData.CoinInfos[1000021])
                    or _G.BagInfoData.GetItemCountByItemConfigId(1000021) or 0
     ```
3. **Cấu trúc trường của một `itemData`**:
   * `itemData.id`: Instance ID (GUID trong túi, ví dụ: 59449... - dùng để gửi packet mạng `ReqUseItem`).
   * `itemData.itemId`: Config ID (ví dụ: 20000021 bùa về thành, 3000400 thẻ buff exp, 100414 vé HL...).
   * `itemData.count`: Số lượng trong slot.
   * `itemData.tblItem`: Dữ liệu tĩnh từ `cfg_Item_item` (`name`, `type`, `subType`, `useParam`, `useKey`).
   * `itemData.serverInfo`: Dữ liệu động từ máy chủ (cường hóa, gia cường, dòng trác việt...).

---

### 💡 Ví Dụ Sử Dụng

```lua
local Bag = require("modules.mod_bag_items")

-- 1. Kiểm tra số lượng vé Huyết Lâu (ConfigID: 100414)
local ticketCount = Bag.GetItemCount(100414)
print("Số vé Huyết Lâu đang có: " .. ticketCount)

-- 2. Tìm Thẻ Buff EXP trong túi
local expCard = Bag.FindItemByConfigId(3000400)
if expCard then
    print("Tìm thấy thẻ EXP! InstanceID=" .. Bag.GetInstanceId(expCard))
end

-- 3. Kiểm tra sức chứa túi đồ
local cap = Bag.GetBagCapacity()
print(string.format("Túi đồ: %d/%d (Trống: %d ô, Đầy: %s)", cap.usedCount, cap.curCellCount, cap.freeCount, tostring(cap.isFull)))
```
