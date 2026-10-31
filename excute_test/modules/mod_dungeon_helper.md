# 🏰 MODULE 7: PHÓ BẢN HUYẾT LÂU & QUẢNG TRƯỜNG QUỶ (DUNGEON HELPER)

## 📌 File Code: [`mod_dungeon_helper.lua`](./mod_dungeon_helper.lua)

Module này chuyên trách việc nhận diện bản đồ phó bản, kiểm tra lịch trình giờ mở cửa, điều kiện vé và lượt, cũng như tự động bấm bỏ qua 30 giây chờ đợi.

---

### 📍 Các Đoạn Code Đã Dùng Trong Mod Nguồn

1. **Dải Map ID Nhận Diện**:
   * *Huyết Lâu (Blood Castle)*: `cMap >= 1012000 and cMap <= 1012099`.
   * *Quảng Trường Quỷ (Demon Plaza)*: `cMap >= 1010000 and cMap <= 1010099`.

2. **Lệnh Bỏ Qua 30s Chờ (`TriggerSkipWait`)**:
   * *Nguồn gốc: `EmmyluaDebug.lua` lines 8954, 9693*:
     ```lua
     _G.networkRequest.ReqSkipWait()
     -- Fallback:
     _G.NetManager.Send(_G.TranScriptMessage.ReqSkipWait, {})
     ```

3. **Kiểm Tra Điều Kiện & Vé Vào Phó Bản**:
   * *Nguồn gốc: `EmmyluaDebug.lua` lines 9880-9905*:
     * Lấy map đích phù hợp cấp độ:
       `enterData = TranScriptData.GetEnterConditionData(subType, condId, maxNumId, curLvl)`
     * Lấy số lượt đi còn lại trong ngày:
       `leftCount = RefreshData.GetInstanceCount(effectId)`
     * Kiểm tra vé trong túi:
       `haveTicket = BagInfoData.GetItemTotalCountByItemId(ticketId)`

4. **Khung Giờ Mở Cửa**:
   * **Giờ lẻ (1h, 3h, 5h, 7h...)**: Huyết Lâu (Blood Castle).
   * **Giờ chẵn (0h, 2h, 4h, 6h...)**: Quảng Trường Quỷ (Demon Plaza).
   * **Phút 00 -> 14**: Cửa phó bản mở, bot ưu tiên vào phó bản trước bãi train.

5. **Hang Động Vàng (Gold Cave - Auto Kim Phiếu)**:
   * **Map ID**: `260001`
   * **Vé vào cổng**: `1000193` (Kim Phiếu)
   * **Boss**: `20220001` (Thần Rồng Vàng)
   * **Vàng rơi**: `1000021` (Vàng Khóa - `Type = 103`, `SL = 50000`)
   * **Lệnh vào hang**: `_G.networkRequest.ReqJoinGoldCaves(1, 1)`
   * **Lệnh thoát phó bản**: `_G.TranScriptController.ReqExitInstance()` (hoặc `_G.NetManager.Send(_G.MapMessage.ReqExitInstance)`)
   * ⚠️ **Bẫy bắt mục tiêu Rồng Vàng**: Không dùng `role:CanSelect()` khi kiểm tra Rồng sống vì 1–2s đầu lúc Rồng đang đáp từ trên trời xuống `CanSelect()` trả về `false` gây trễ. Chỉ kiểm tra `not role.isDead and hp > 0` và tách riêng biến `LastJoinTime` (chỉ chặn khi đứng ngoài map) để vào hang là đánh tức thì ở 0ms.
