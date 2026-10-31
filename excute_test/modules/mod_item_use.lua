-- =========================================================================
-- [MODULE]: mod_item_use.lua
-- Mục đích: Kích hoạt / sử dụng vật phẩm từ túi đồ (Dùng thẻ EXP, thuốc, mở rương...)
-- Tham chiếu code gốc:
--   - ItemUtility.lua (lines 1356-1520), BehaviorNode.lua (lines 700-710)
--   - BagInfoController.lua (lines 615-629)
--   - EmmyluaDebug.lua lines 4185-4200, 18985-18995, 19045-19065
-- =========================================================================

local ModItemUse = {}

--- Sử dụng vật phẩm tổng quát bằng Item Object
-- @param item table: Item object lấy từ BagInfoData
-- @param count number: Số lượng muốn dùng (mặc định = 1)
-- @return boolean: true nếu đã gửi lệnh thành công
function ModItemUse.UseItem(item, count)
    if not item then return false end
    count = count or 1

    local instanceId = item.id or (item.data and item.data.id)
    local configId = item.itemId or (item.data and item.data.itemId) or (item.tblItem and item.tblItem.id) or 0
    local tblItem = item.tblItem or (item.data and item.data.tblItem) or {}
    local useParam = tblItem.useParam

    if not instanceId then return false end

    local used = false

    -- CÁCH 1: ItemUtility.UseItem (Chuẩn BehaviorNode của game gốc)
    if _G.ItemUtility and _G.ItemUtility.UseItem then
        local ok = pcall(function()
            local useItemTbl = {
                useCount = count,
                useItemId = instanceId,
                configId = configId,
                useParam = useParam,
                params = nil,
                itemInfo = item
            }
            _G.ItemUtility.UseItem(useItemTbl)
            used = true
        end)
        if ok and used then return true end
    end

    -- CÁCH 2: BagInfoController.UseItemReq (Controller xử lý túi đồ)
    if not used and _G.BagInfoController and _G.BagInfoController.UseItemReq then
        local ok = pcall(function()
            _G.BagInfoController.UseItemReq(count, instanceId, nil, configId)
            used = true
        end)
        if ok and used then return true end
    end

    -- CÁCH 3: networkRequest.ReqUseItem (Gói mạng RPC trực tiếp)
    if not used and _G.networkRequest and _G.networkRequest.ReqUseItem then
        local ok = pcall(function()
            _G.networkRequest.ReqUseItem(count, instanceId)
            used = true
        end)
        if ok and used then return true end
    end

    -- CÁCH 4: NetManager.Send trực tiếp
    if not used and _G.NetManager and _G.NetManager.Send then
        local msgType = (_G.BagMessage and _G.BagMessage.ReqUseItem) or (_G.ItemMessage and _G.ItemMessage.ReqUseItem)
        if msgType then
            pcall(function()
                _G.NetManager.Send(msgType, { count = count, itemId = instanceId, id = instanceId })
                used = true
            end)
        end
    end

    return used
end

--- Tìm và sử dụng vật phẩm theo Config ID
-- @param configId number: ID cấu hình (ví dụ 3000400)
-- @param count number: Số lượng (mặc định = 1)
-- @return boolean: true nếu tìm thấy và đã gọi lệnh
function ModItemUse.UseItemByConfigId(configId, count)
    if not configId or configId <= 0 then return false end
    count = count or 1

    local targetItem = nil
    if _G.BagInfoData and _G.BagInfoData.GetItemByConfigID then
        pcall(function() targetItem = _G.BagInfoData.GetItemByConfigID(configId) end)
    end

    if not targetItem and _G.BagInfoData and _G.BagInfoData.TotalItems then
        for _, it in pairs(_G.BagInfoData.TotalItems) do
            if it and (it.itemId == configId or (it.data and it.data.itemId == configId)) then
                targetItem = it
                break
            end
        end
    end

    if targetItem then
        return ModItemUse.UseItem(targetItem, count)
    end

    return false
end

--- Tự động sử dụng Thẻ Buff EXP (3000400 hoặc thẻ tương đương)
-- @param maxCardsPerSession number: Giới hạn số thẻ tối đa dùng mỗi lần (mặc định = 2)
-- @param minRemainingSeconds number: Chỉ dùng nếu buff còn dưới số giây này (mặc định = 600s / 10 phút)
-- @return boolean: true nếu đã kích hoạt dùng thẻ
function ModItemUse.AutoUseExpCard(maxCardsPerSession, minRemainingSeconds)
    maxCardsPerSession = maxCardsPerSession or 2
    minRemainingSeconds = minRemainingSeconds or 600

    -- 1. Kiểm tra số thẻ đã dùng trong lượt này
    _G.Mod_DungeonExpCardsUsed = _G.Mod_DungeonExpCardsUsed or 0
    if _G.Mod_DungeonExpCardsUsed >= maxCardsPerSession then
        return false
    end

    -- 2. Kiểm tra Cooldown giữa 2 lần dùng thẻ (ít nhất 2 giây)
    local now = CS.UnityEngine.Time.realtimeSinceStartup
    if (now - (_G.Mod_LastExpCardUseTime or 0)) < 2.0 then
        return false
    end

    -- 3. Kiểm tra thời gian hiệu lực còn lại của Buff EXP
    local myRoleId = _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.id
    local buffs = (_G.BuffData and _G.BuffData.GetBuffs and _G.BuffData.GetBuffs(myRoleId)) or {}
    local expRemainTime = 0
    for _, b in pairs(buffs) do
        if b and b.buffConfig and b.buffConfig.name then
            local bName = b.buffConfig.name
            if string.find(bName, "EXP") or string.find(bName, "Kinh Nghiệm") then
                local rTime = tonumber(b.time) or 0
                if rTime > expRemainTime then expRemainTime = rTime end
            end
        end
    end

    -- 4. Nếu buff còn nhiều hơn ngưỡng cần buff -> Chưa cần dùng
    if expRemainTime >= minRemainingSeconds then
        return false
    end

    -- 5. Tìm thẻ trong túi đồ (ConfigID: 3000400)
    local cardItem = nil
    if _G.BagInfoData and _G.BagInfoData.GetItemByConfigID then
        pcall(function() cardItem = _G.BagInfoData.GetItemByConfigID(3000400) end)
    end
    if not cardItem and _G.BagInfoData and _G.BagInfoData.TotalItems then
        for _, it in pairs(_G.BagInfoData.TotalItems) do
            if it and (it.itemId == 3000400 or (it.tblItem and it.tblItem.name and it.tblItem.name:find("Buff EXP"))) then
                cardItem = it
                break
            end
        end
    end

    if cardItem then
        local success = ModItemUse.UseItem(cardItem, 1)
        if success then
            _G.Mod_LastExpCardUseTime = now
            _G.Mod_DungeonExpCardsUsed = _G.Mod_DungeonExpCardsUsed + 1
            if _G.FloatingWordUtility and _G.FloatingWordUtility.QuickMsg then
                _G.FloatingWordUtility.QuickMsg(string.format("Đã dùng Thẻ Buff EXP (%d/%d)", _G.Mod_DungeonExpCardsUsed, maxCardsPerSession))
            end
            return true
        end
    else
        -- Không có thẻ trong túi
        if _G.ShowDungeonRedWarning then
            _G.ShowDungeonRedWarning("<color=#FF3333>Không có Thẻ Buff EXP trong túi!</color>")
        end
    end

    return false
end

--- Mở rương vật phẩm với số lượng chỉ định
-- @param chestInstanceId number: GUID rương trong túi
-- @param count number: Số lượng muốn mở
function ModItemUse.OpenChest(chestInstanceId, count)
    if not chestInstanceId then return false end
    count = count or 1

    if _G.networkRequest and _G.networkRequest.ReqUseItem then
        pcall(function() _G.networkRequest.ReqUseItem(count, chestInstanceId) end)
        return true
    elseif _G.BagInfoController and _G.BagInfoController.UseItemReq then
        pcall(function() _G.BagInfoController.UseItemReq(count, chestInstanceId) end)
        return true
    end
    return false
end

return ModItemUse
