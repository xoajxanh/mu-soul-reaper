# 💎 MODULE 5: DÒNG THUỘC TÍNH & TRANG BỊ (ITEM ATTRIBUTES & ENHANCEMENT)

## 📌 File Code: [`mod_item_attributes.lua`](./mod_item_attributes.lua)

Module này chuyên trách việc phân tích dữ liệu dòng thuộc tính của trang bị (Dòng Trác Việt, Cường Hóa, Gia Cường, Tẩy Luyện, Khảm Ngọc, Cấp Sao và Phân Loại Vũ Khí/Giáp).

---

### 📍 Các Đoạn Code Đã Dùng Trong Mod Nguồn

1. **Lấy Dòng Trác Việt (`RoleEquipUtility`)**:
   * *Nguồn gốc: `EmmyluaDebug.lua` lines 4831-4846*:
     ```lua
     local rawExc = item.excellence or sInfo.excellentList or sInfo.excellentInfo or sInfo.excellentAttrs
     local excDesList = {}
     if _G.RoleEquipUtility and rawExc and _G.RoleEquipUtility.GetEquipExcellence then
         excDesList = _G.RoleEquipUtility.GetEquipExcellence(rawExc, tblEquip)
     end
     if #excDesList == 0 and _G.RoleEquipUtility.GetEquipExcellenceDesByServerInfo then
         excDesList = _G.RoleEquipUtility.GetEquipExcellenceDesByServerInfo(sInfo)
     end
     ```

2. **Kiểm Tra Đồ Đã Cường Hóa / Nâng Cấp (`IsEnhancedEquip`)**:
   * *Nguồn gốc: `EmmyluaDebug.lua` lines 4449-4525*:
     * Hàm này kiểm tra **7 tiêu chí toàn diện**:
       1. `intensify > 0`: Cấp cường hóa (+1 trở lên).
       2. `additional > 0`: Cấp gia cường (+4, +8 trở lên).
       3. `RegenerateAttributeList`: Đã tẩy luyện / tái sinh.
       4. `gemList / inlayList`: Có khảm ngọc hoặc đục lỗ ngọc.
       5. `star / starLevel > 0`: Đã lên cấp sao.
       6. `canSmelt == true`: Đồ dung luyện.
       7. `specialEffectIds`: Kỹ năng đặc thù trang sức bộ.
     * **Mục đích sinh tử**: Khi làm tính năng tự động thu hồi/tách đồ/bán đồ, nếu `IsEnhancedEquip(item) == true` thì **tuyệt đối không được đụng vào**, tránh làm mất đồ VIP của người chơi!

3. **Phân Loại Trang Bị Theo `subType`**:
   * Giáp: `subType >= 13 and subType <= 17` (Mũ, Áo, Quần, Tay, Chân).
   * Vũ khí: `subType >= 1 and subType <= 12` hoặc `24, 25, 56, 57, 81`.
   * Trang sức / Đồ dung: `subType == 18..22, 26, 34..38, >= 100`.
