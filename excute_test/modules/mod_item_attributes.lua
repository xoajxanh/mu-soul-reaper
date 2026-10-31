-- =========================================================================
-- [MODULE]: mod_item_attributes.lua
-- Mục đích: Đọc và phân tích thuộc tính trang bị (Dòng trác việt, Cường hóa, Gia cường, Ngọc, Sao)
-- Tham chiếu code gốc:
--   - RoleEquipUtility.lua, cfg_Item_equip.lua, ItemUtility.lua
--   - EmmyluaDebug.lua lines 4449-4525 (IsEnhancedEquip), 4815-4865, 4995-5040
-- =========================================================================

local ModItemAttributes = {}

--- Lấy danh sách mô tả các dòng Trác Việt (Excellence Options) của trang bị
-- @param item table: Item object từ túi đồ
-- @return table: Mảng chuỗi các dòng thuộc tính (ví dụ: { "Tăng Tấn Công +4%", "Tỷ lệ sát thương chí mạng +10%" })
function ModItemAttributes.GetExcellenceDescriptions(item)
    if not item then return {} end

    local tblEquip = item.tblEquip or (item.data and item.data.tblEquip) or {}
    local itemId = item.itemId or (item.data and item.data.itemId) or (item.tblItem and item.tblItem.id) or 0

    if (not tblEquip or not tblEquip.id) and itemId > 0 and _G.ClientTable and _G.ClientTable.cfg_Item_equipManager then
        pcall(function()
            local eq = _G.ClientTable.cfg_Item_equipManager:TryGetValue(itemId)
            if eq then tblEquip = eq end
        end)
    end
    tblEquip = tblEquip or {}

    local excDesList = {}
    local sInfo = item.serverInfo or item.serverData or {}
    local rawExc = item.excellence or sInfo.excellentList or sInfo.excellentInfo or sInfo.excellentAttrs

    -- Cách 1: RoleEquipUtility.GetEquipExcellence
    if _G.RoleEquipUtility then
        if rawExc and _G.RoleEquipUtility.GetEquipExcellence then
            pcall(function() excDesList = _G.RoleEquipUtility.GetEquipExcellence(rawExc, tblEquip) end)
        end
        -- Cách 2: RoleEquipUtility.GetEquipExcellenceDesByServerInfo
        if (#excDesList == 0) and _G.RoleEquipUtility.GetEquipExcellenceDesByServerInfo then
            pcall(function() excDesList = _G.RoleEquipUtility.GetEquipExcellenceDesByServerInfo(sInfo) end)
        end
    end

    -- Cách 3: Phương thức trực tiếp trên item object
    if (#excDesList == 0) and item.GetEquipExcellenceDesList then
        pcall(function() excDesList = item:GetEquipExcellenceDesList() end)
    end

    return excDesList or {}
end

--- Kiểm tra trang bị đã được Cường Hóa / Gia Cường / Tẩy Luyện / Khảm Ngọc / Lên Sao chưa
-- Rất quan trọng: Dùng để bảo vệ đồ VIP không bị mod tự động thu hồi / phân giải / bán nhầm!
-- @param item table
-- @return boolean: true nếu đồ ĐÃ ĐƯỢC ĐẦU TƯ / NÂNG CẤP
function ModItemAttributes.IsEnhancedEquip(item)
    if not item then return false end
    local sInfo = item.serverInfo or item.serverData or {}
    local d = item.data or {}
    local dSInfo = d.serverInfo or d.serverData or {}

    -- 1. Cường hóa (intensify > 0)
    local intensify = tonumber(item.intensify) or tonumber(d.intensify) or tonumber(sInfo.intensify) or tonumber(dSInfo.intensify) or 0
    if intensify > 0 then return true end

    -- 2. Gia cường (additional > 0)
    local additional = tonumber(item.additional) or tonumber(d.additional) or tonumber(sInfo.additional) or tonumber(dSInfo.additional) or 0
    if additional > 0 then return true end

    -- 3. Tái sinh / Tẩy luyện (RegenerateAttributeList)
    local regenList = item.RegenerateAttributeList or d.RegenerateAttributeList or sInfo.RegenerateAttributeList or dSInfo.RegenerateAttributeList
    if regenList then
        local hasRegen = false
        pcall(function()
            if type(regenList) == "table" then
                if #regenList > 0 then hasRegen = true end
                if not hasRegen and _G.next and _G.next(regenList) ~= nil then hasRegen = true end
            elseif type(regenList) == "userdata" then
                local c = regenList.Count or regenList.Length or 0
                if c > 0 then hasRegen = true end
            end
        end)
        if hasRegen then return true end
    end

    -- 4. Khảm ngọc / Lỗ ngọc (gemList / inlayList)
    local gems = item.gemList or item.inlayList or d.gemList or d.inlayList or sInfo.gemList or sInfo.inlayList
    if gems then
        local hasGem = false
        pcall(function()
            if type(gems) == "table" then
                for _, g in pairs(gems) do
                    if g and (g.id or g.itemId or (type(g) == "number" and g > 0)) then
                        hasGem = true
                        break
                    end
                end
            elseif type(gems) == "userdata" then
                local c = gems.Count or gems.Length or 0
                if c > 0 then hasGem = true end
            end
        end)
        if hasGem then return true end
    end

    -- 5. Cấp sao (star / starLevel > 0)
    local star = tonumber(item.star) or tonumber(item.starLevel) or tonumber(d.star) or tonumber(sInfo.star) or 0
    if star > 0 then return true end

    -- 6. Đồ Dung Luyện (canSmelt == true)
    if sInfo.canSmelt == true or dSInfo.canSmelt == true or item.canSmelt == true then
        return true
    end

    -- 7. Kỹ năng đặc thù Trang Sức Bộ (specialEffectIds)
    local spec = sInfo.specialEffectIds or dSInfo.specialEffectIds or item.specialEffectIds or d.specialEffectIds
    if spec then
        local hasSpec = false
        pcall(function()
            if type(spec) == "table" then
                if _G.next and _G.next(spec) ~= nil then hasSpec = true end
            elseif type(spec) == "userdata" then
                local c = spec.Count or spec.Length or 0
                if c > 0 then hasSpec = true end
            end
        end)
        if hasSpec then return true end
    end

    return false
end

--- Phân loại trang bị (Giáp, Vũ khí, Trang sức...)
-- @param subType number
-- @return table: { isArmor = bool, isWeapon = bool, isJewelry = bool, isSmelt = bool }
function ModItemAttributes.ClassifyEquipType(subType)
    subType = tonumber(subType) or 0

    local isArmor = (subType >= 13 and subType <= 17)
    local isWeapon = ((subType >= 1 and subType <= 12) or subType == 24 or subType == 25 or subType == 56 or subType == 57 or subType == 81)
    local isJewelry = (subType == 18 or subType == 19 or subType == 20 or subType == 21 or subType == 22 or subType == 26 or (subType >= 34 and subType <= 38))
    local isSmelt = (subType >= 100) or isJewelry

    return {
        isArmor = isArmor,
        isWeapon = isWeapon,
        isJewelry = isJewelry,
        isSmelt = isSmelt
    }
end

--- Lấy tóm tắt chỉ số cơ bản của trang bị (Cấp độ cường hóa, phẩm chất, số dòng trác việt)
-- @param item table
-- @return table
function ModItemAttributes.GetEquipSummary(item)
    if not item then return nil end

    local tblItem = item.tblItem or (item.data and item.data.tblItem) or {}
    local subType = tblItem.subType or 0
    local sInfo = item.serverInfo or item.serverData or {}

    local intensify = tonumber(item.intensify) or tonumber(sInfo.intensify) or 0
    local additional = tonumber(item.additional) or tonumber(sInfo.additional) or 0
    local star = tonumber(item.star) or tonumber(sInfo.star) or 0
    local excList = ModItemAttributes.GetExcellenceDescriptions(item)
    local isEnhanced = ModItemAttributes.IsEnhancedEquip(item)
    local equipType = ModItemAttributes.ClassifyEquipType(subType)

    return {
        name = tblItem.name or item.name or "Unknown Item",
        quality = tblItem.quality or 0,
        subType = subType,
        intensify = intensify,
        additional = additional,
        star = star,
        excellenceCount = #excList,
        excellenceList = excList,
        isEnhanced = isEnhanced,
        equipType = equipType
    }
end

return ModItemAttributes
