# 🌀 MODULE 4: BÙA VỀ THÀNH & DỊCH CHUYỂN (TELEPORT & TOWN SCROLL)

## 📌 File Code: [`mod_teleport_townscroll.lua`](./mod_teleport_townscroll.lua)

Module này chuyên trách việc sử dụng Bùa Về Thành Lorencia, Phù Bay Ngẫu Nhiên và các cơ chế Dịch chuyển Bản đồ an toàn.

---

### 📍 Các Đoạn Code Đã Dùng Trong Mod Nguồn

1. **Bùa Về Thành (ConfigId: 20000021)**:
   * *Nguồn gốc: `EmmyluaDebug.lua` lines 4182-4205*:
     * Quét `TotalItems` tìm item có `itemId == 20000021`.
     * Gửi `_G.networkRequest.ReqUseItem(1, instanceId)`.
     * **Cơ chế Fallback tuyệt vời**: Nếu túi không có bùa, mod tự động gửi gói mạng gọi cờ về thành Lorencia (Map 1001, tọa độ an toàn x=54, y=63):
       ```lua
       _G.NetManager.Send(_G.MapMessage.ReqCallFlag, { mapId = 1001, line = 1, x = 54, y = 63 })
       ```

2. **Đá Truyền Tống Ngẫu Nhiên (ConfigId: 20000022 - Phù bay nhanh)**:
   * *Nguồn gốc: `EmmyluaDebug.lua` lines 19030-19065 & `ItemUtility.lua` lines 1508-1514*:
     * Kiểm tra bản đồ hiện tại: `mapTab = cfg_Map_mapManager:TryGetValue(mapId); if mapTab.flyScroll ~= 0 then return end` (nếu khác 0 là cấm dùng phù).
     * Gọi lệnh: `_G.BagInfoController.UseItemReq(1, stoneBagId, nil, 20000022)`.

3. **Dịch Chuyển Tức Thời Tới Bản Đồ Bất Kỳ (FlyTransferScene)**:
   * Dùng khi chuyển sang bản đồ train hoặc vào map phụ:
     ```lua
     _G.PathFinderManager.FlyTransferScene(mapId, targetPos)
     ```
   * Hoặc phát sự kiện đổi map:
     ```lua
     _G.EventManager.Dispatch(_G.Event.Map_ChangeMap, { mapId = targetMapId })
     ```
