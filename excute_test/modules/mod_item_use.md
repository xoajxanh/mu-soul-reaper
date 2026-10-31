# 💊 MODULE 3: SỬ DỤNG VẬT PHẨM (ITEM USE)

## 📌 File Code: [`mod_item_use.lua`](./mod_item_use.lua)

Module này chịu trách nhiệm gửi lệnh sử dụng vật phẩm: Thẻ Buff EXP, Thuốc tăng lực, Bình máu/mana, Mở rương và các bùa chú.

---

### 📍 Các Cơ Chế Sử Dụng Vật Phẩm Trong Game Gốc

1. **Chuẩn BehaviorNode (`ItemUtility.UseItem`)**:
   * *Nguồn gốc: `BehaviorNode.lua` lines 700-708*:
     ```lua
     local useItemTbl = {
         useCount = 1,
         useItemId = item.id,
         configId = item.itemId,
         useParam = item.tblItem and item.tblItem.useParam,
         params = nil,
         itemInfo = item
     }
     ItemUtility.UseItem(useItemTbl)
     ```
   * *Ưu điểm*: Cập nhật Cooldown ở client (`MeController.UpdateClientItemCd`), kiểm tra điều kiện cấp độ, tự động gọi tiếp `BagInfoController.UseItemReq`.

2. **Gọi Trực Tiếp Controller (`BagInfoController.UseItemReq`)**:
   * *Nguồn gốc: `BagInfoController.lua` lines 615-629*:
     ```lua
     BagInfoController.UseItemReq(count, item.id, clientParams, item.itemId)
     ```

3. **Gửi Gói Mạng Trực Tiếp (`networkRequest.ReqUseItem`)**:
   * *Nguồn gốc: `EmmyluaDebug.lua` lines 4191, 18991, 19057*:
     ```lua
     _G.networkRequest.ReqUseItem(count, item.id)
     ```

---

### 🎯 Quy Trình Tự Dùng Thẻ Buff EXP Chuẩn (`AutoUseExpCard`)

1. Đếm số thẻ đã dùng trong lần vào phó bản (`_G.Mod_DungeonExpCardsUsed < 2`).
2. Kiểm tra Cooldown chống spam gói tin (cách nhau >= 2.0s).
3. Đọc danh sách Buff từ `BuffData.GetBuffs(myRoleId)` xem buff EXP còn hiệu lực >= 10 phút (600s) không.
4. Quét túi lấy `cardItem` từ `BagInfoData.GetItemByConfigID(3000400)`.
5. Thực thi qua chuỗi 4 cơ chế fallback đảm bảo 100% lệnh đến được server.
