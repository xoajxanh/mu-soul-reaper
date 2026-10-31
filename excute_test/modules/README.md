# 📚 THƯ VIỆN MODULES CHUẨN CỦA MU-MOD (MU LUA REFERENCE LIBRARY)

Tài liệu này lưu trữ toàn bộ các phương thức, API và module đã được **kiểm định thực tế (verified & battle-tested)** trong quá trình phát triển Mod MU (`modified_lua_dev_client` và `modified_lua_dev_farm`).

Mục đích: **Tránh việc Agent đi mày mò lại các hàm đã có hoặc đoán sai cấu trúc dữ liệu của game (như lỗi `bagItems` thay vì `TotalItems`).**

---

## 🗂️ DANH MỤC CÁC MODULE KIỂM ĐỊNH

| STT | File Module | Mục Đích & Nội Dung Chính | Trạng Thái |
|:---:|:---|:---|:---:|
| 1 | [`mod_player_info.lua`](./mod_player_info.lua) / [MD](./mod_player_info.md) | Lấy Tên, Cấp, Career, Guild/Bang, HP/MP, Tọa độ (World/Cell/Server), PK Mode | ✅ Đã kiểm định |
| 2 | [`mod_bag_items.lua`](./mod_bag_items.lua) / [MD](./mod_bag_items.md) | Quét túi đồ, đếm số lượng item, tìm item theo ID/tên/loại, cấu trúc ItemData | ✅ Đã kiểm định |
| 3 | [`mod_item_use.lua`](./mod_item_use.lua) / [MD](./mod_item_use.md) | Gọi lệnh dùng item: Thẻ Buff EXP, Thuốc, Mở rương, Đá truyền tống, ItemUtility | ✅ Đã kiểm định |
| 4 | [`mod_teleport_townscroll.lua`](./mod_teleport_townscroll.lua) / [MD](./mod_teleport_townscroll.md) | Bùa về thành (20000021), Phù ngẫu nhiên (20000022), ReqCallFlag, FlyTransfer | ✅ Đã kiểm định |
| 5 | [`mod_item_attributes.lua`](./mod_item_attributes.lua) / [MD](./mod_item_attributes.md) | Lấy dòng Trác Việt (Excellence), Cường hóa, Gia cường, Cấp sao, Tẩy luyện, Ngọc | ✅ Đã kiểm định |
| 6 | [`mod_movement_combat.lua`](./mod_movement_combat.lua) / [MD](./mod_movement_combat.md) | Di chuyển (MoveTo), Dừng đánh khi chạy (StopAutoFight), Xóa mục tiêu, Bật Auto | ✅ Đã kiểm định |
| 7 | [`mod_dungeon_helper.lua`](./mod_dungeon_helper.lua) / [MD](./mod_dungeon_helper.md) | Nhận diện map Huyết Lâu / QTQ / Hang Động Vàng (260001), ReqSkipWait, ReqJoinGoldCaves, ReqExitInstance | ✅ Đã kiểm định |
| 8 | [`mod_core_utils.lua`](./mod_core_utils.lua) / [MD](./mod_core_utils.md) | Quản lý Timer chuẩn, Tạo Toggle/Button/Input UI, Lưu PlayerPrefs, Ghi output.txt | ✅ Đã kiểm định |
| 9 | [`mod_ground_pickup.lua`](./mod_ground_pickup.lua) / [MD](./mod_ground_pickup.md) | Quét vật phẩm rơi trên đất đa nguồn (`ViewData` + `VipManager` + `DropItemManager`) & Vét đồ (`ReqPickUpMapItem` / `ReqPickUpMapItems`) | ✅ Đã kiểm định |

---

## ⚠️ BẢNG TỔNG HỢP CÁC BẪY PHỔ BIẾN (COMMON PITFALLS)

1. **Túi đồ**:
   * ❌ `BagInfoData.bagItems` -> **KHÔNG TỒN TẠI (NIL)**.
   * ✅ `BagInfoData.TotalItems` hoặc `BagInfoData.GetItemByConfigID(cfgId)`.
2. **Số lượng item trong túi & Tiền tệ (Vàng Khóa)**:
   * ✅ Đếm item/vé: `BagInfoData.GetItemTotalCountByItemId(cfgId)` (nhanh & chính xác nhất).
   * ⚠️ **Bẫy Vàng Khóa (`1000021`)**: Không dùng `GetItemTotalCountByItemId(1000021)` vì hàm này tự cộng gộp cả `bindEqualItem` (`1000020` Vàng không khóa).
   * ✅ Lấy riêng Vàng Khóa chuẩn 100%: `BagInfoData.CoinInfos[1000021]` hoặc `BagInfoData.GetItemCountByItemConfigId(1000021)`.
3. **Quét vật phẩm rơi dưới đất (Ground Drop Items)**:
   * ❌ Chỉ quét upvalue `dropItems` của `DropItemManager.GetDropItemById` -> **BỊ RỖNG (0 phần tử)** khi vật phẩm rơi từ quái chết (`isMonsterDeath == true`) do game đẩy sang `VipManager` (`vipAutoPickDropItems`) và không lưu vào `DropItemManager`.
   * ✅ Phải quét từ `_G.ViewData.GetGameObjectsInView()` (chứa 100% mọi đối tượng trên map) kết hợp `_G.VipManager.Update` (upvalue 1 `vipAutoPickDropItems`) — xem chi tiết tại [`mod_ground_pickup.lua`](./mod_ground_pickup.lua).
4. **Bắt mục tiêu Boss vừa xuất hiện (như Thần Rồng Vàng `20220001`)**:
   * ❌ Kiểm tra `role:CanSelect() == true` -> Làm trễ 1.5–2 giây đầu khi Boss đang diễn hoạt đáp xuống đất.
   * ✅ Chỉ kiểm tra `not role.isDead and (not hp or hp > 0)` để khóa mục tiêu & đánh ngay ở 0ms.
5. **Bang hội (Guild)**:
   * ✅ `WarAllianceData.IsHaveUnion` (boolean) và `WarAllianceData.MyWarAllianceData.name`.
6. **Dừng đánh khi chạy**:
   * Bật `MoveTo` thôi chưa đủ, nếu `SetAutoFight` đang bật thì AI vẫn quay sang đánh quái.
   * ✅ Phải gọi `me:StopAutoFight()`, `EventManager.Dispatch(Event.Role_StopAutoFight)` và `me.TargetAvatar = nil`.
7. **Dùng item từ client**:
   * ✅ Dùng bảng tham số theo mẫu `BehaviorNode.lua`:
     `ItemUtility.UseItem({ useCount = 1, useItemId = item.id, configId = item.itemId, useParam = item.tblItem.useParam, itemInfo = item })`
   * Fallback gọi trực tiếp: `BagInfoController.UseItemReq(1, item.id, nil, item.itemId)`.
