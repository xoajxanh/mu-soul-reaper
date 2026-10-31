-- =========================================================================
-- [MODULE]: mod_ground_pickup.lua
-- Mục đích: Quét vật phẩm rơi trên mặt đất đa nguồn & Hút/Vét đồ tự động (Ground Item Sweeper)
-- Tham chiếu code gốc:
--   - ViewData.lua (gameObjectDataCollection / GetGameObjectsInView)
--   - VipManager.lua (vipAutoPickDropItems upvalue)
--   - DropItemManager.lua (dropItems upvalue)
--   - PickupManager.lua (ReqPickUpMapItem, ReqPickUpMapItems)
--   - EmmyluaDebug.lua (Mod_GetGroundDropItems, Mod_SweepGroundItems)
-- CẢNH BÁO QUAN TRỌNG (CRITICAL GOTCHA):
--   - KHÔNG ĐƯỢC chỉ quét `DropItemManager.GetDropItemById` upvalue `dropItems`!
--   - Khi vật phẩm rơi từ quái chết (`isMonsterDeath == true`) và thỏa điều kiện VIP auto-pickup
--     (hoặc trong phó bản đặc biệt như Hang Động Vàng 260001), `DropItemManager` sẽ return sớm
--     và KHÔNG lưu vào `dropItems` (khiến `dropItems` = 0 phần tử).
--   - Nguồn chứa 100% mọi vật phẩm trên bản đồ là `ViewData.GetGameObjectsInView()` và `VipManager`.
-- =========================================================================

local ModGroundPickup = {}

--- Quét toàn bộ vật phẩm đang nằm trên mặt đất từ tất cả các nguồn bộ nhớ
-- @param filterFn function|nil: Hàm lọc tùy chọn `function(itemInfo) return true/false end`
-- @return table: Danh sách `{ id, x, y, confId, count, type, name, dist, raw }`
function ModGroundPickup.GetGroundDropItems(filterFn)
    local result = {}
    local seenIds = {}

    local me = _G.RoleManager and _G.RoleManager.me
    local meCoord = me and (me.serverCoord or me.cellPos or (me.data and me.data.serverCoord))
    local meX = meCoord and (meCoord.x or meCoord.X) or 0
    local meY = meCoord and (meCoord.y or meCoord.Y) or 0

    local function AddItemToResult(objId, ix, iy, confId, count, itemType, name, rawObj)
        if not objId or seenIds[objId] then return end
        seenIds[objId] = true

        local itemInfo = {
            id = objId,
            x = ix or 0,
            y = iy or 0,
            confId = confId or 0,
            count = count or 1,
            type = itemType or 0,
            name = name or "",
            raw = rawObj
        }

        if not filterFn or filterFn(itemInfo) then
            local dist = 999
            if meX > 0 and meY > 0 and itemInfo.x > 0 and itemInfo.y > 0 then
                dist = math.max(math.abs(meX - itemInfo.x), math.abs(meY - itemInfo.y))
            end
            itemInfo.dist = dist
            table.insert(result, itemInfo)
        end
    end

    -- 1. Nguồn chính (Chuẩn 100%): ViewData.GetGameObjectsInView()
    pcall(function()
        if _G.ViewData and _G.ViewData.GetGameObjectsInView then
            local objs = _G.ViewData.GetGameObjectsInView()
            if objs then
                for id, obj in pairs(objs) do
                    if obj then
                        local isDrop = (obj.item ~= nil) or (obj.dropTime ~= nil) or (obj.configID == 1000021) or (obj.type == 103 or obj.type == 24 or obj.type == 26)
                        if isDrop then
                            local itemId = (obj.item and obj.item.itemId) or obj.configID or obj.itemId or 0
                            local name = obj.name or ""
                            local count = (obj.item and obj.item.count) or 1
                            local ix = obj.x or (obj.serverCoord and obj.serverCoord.x) or 0
                            local iy = obj.y or (obj.serverCoord and obj.serverCoord.y) or 0
                            local itemType = obj.type or 0
                            AddItemToResult(id, ix, iy, itemId, count, itemType, name, obj)
                        end
                    end
                end
            end
        end
    end)

    -- 2. Nguồn 2: VipManager upvalue #1 (vipAutoPickDropItems)
    pcall(function()
        if _G.VipManager and _G.VipManager.Update then
            local _, val = debug.getupvalue(_G.VipManager.Update, 1)
            if type(val) == "table" then
                for id, itemObj in pairs(val) do
                    if itemObj then
                        local d = itemObj.data or itemObj
                        local objId = (d and d.id) or id
                        local itemId = (d and d.item and d.item.itemId) or (d and d.configID) or (d and d.itemId) or 0
                        local name = (d and d.name) or ""
                        local count = (d and d.item and d.item.count) or 1
                        local ix = (d and d.x) or itemObj.x or 0
                        local iy = (d and d.y) or itemObj.y or 0
                        local itemType = (d and d.type) or 0
                        AddItemToResult(objId, ix, iy, itemId, count, itemType, name, itemObj)
                    end
                end
            end
        end
    end)

    -- 3. Nguồn 3: DropItemManager upvalues (dropItems)
    pcall(function()
        if _G.DropItemManager and _G.DropItemManager.GetDropItemById then
            for i = 1, 3 do
                local _, val = debug.getupvalue(_G.DropItemManager.GetDropItemById, i)
                if type(val) == "table" and next(val) ~= nil then
                    for id, itemObj in pairs(val) do
                        if itemObj then
                            local d = itemObj.data or itemObj
                            local objId = (d and d.id) or id
                            local ix = (d and d.x) or (itemObj.serverCoord and itemObj.serverCoord.x) or 0
                            local iy = (d and d.y) or (itemObj.serverCoord and itemObj.serverCoord.y) or 0
                            local confId = (d and d.item and d.item.itemId) or (d and d.configID) or (d and d.configId) or 0
                            local count = (d and d.item and d.item.count) or 1
                            local itemType = (d and d.type) or 0
                            local name = (d and d.name) or ""
                            AddItemToResult(objId, ix, iy, confId, count, itemType, name, itemObj)
                        end
                    end
                    break
                end
            end
        end
    end)

    -- 4. Nguồn 4: Mod_GroundItemsTracked (Hook sự kiện AddDropSceneCellPos)
    if _G.Mod_GroundItemsTracked then
        for objId, info in pairs(_G.Mod_GroundItemsTracked) do
            AddItemToResult(objId, info.x, info.y, info.confId, info.count, info.type, "", nil)
        end
    end

    return result
end

--- Gửi gói tin nhặt 1 vật phẩm theo Instance ID trên bản đồ
-- @param dropItemId number|string: ID thực thể của cọc đồ trên sàn
function ModGroundPickup.PickupItemById(dropItemId)
    if not dropItemId then return end
    pcall(function()
        if _G.PickupManager and _G.PickupManager.ReqPickUpMapItem then
            _G.PickupManager.ReqPickUpMapItem(dropItemId)
        elseif _G.networkRequest and _G.networkRequest.ReqPickUpMapItem then
            _G.networkRequest.ReqPickUpMapItem(dropItemId)
        end
    end)
end

--- Gửi gói tin nhặt hàng loạt vật phẩm theo danh sách ID (Batch Loot)
-- @param batchIds table: Mảng các ID cọc đồ `{ id1, id2, ... }`
function ModGroundPickup.PickupItemsBatch(batchIds)
    if not batchIds or #batchIds == 0 then return end
    pcall(function()
        if _G.PickupManager and _G.PickupManager.ReqPickUpMapItems then
            _G.PickupManager.ReqPickUpMapItems(batchIds)
        elseif _G.networkRequest and _G.networkRequest.ReqPickUpMapItems then
            _G.networkRequest.ReqPickUpMapItems(batchIds)
        end
    end)
end

--- Vét sạch toàn bộ vật phẩm trên mặt đất (kết hợp ReqPickUpMapItem + ReqPickUpMapItems + MoveTo tùy chọn)
-- @param options table|nil: `{ filterFn = function, allowMove = boolean }`
-- @return table: `{ isClean = boolean, count = number, nearest = table|nil, batchIds = table }`
function ModGroundPickup.SweepGroundItems(options)
    options = options or {}
    local filterFn = options.filterFn
    local allowMove = (options.allowMove == true)
    local items = ModGroundPickup.GetGroundDropItems(filterFn)

    if not items or #items == 0 then
        return { isClean = true, count = 0 }
    end

    local batchIds = {}
    for _, it in ipairs(items) do
        if it.id then
            table.insert(batchIds, it.id)
            ModGroundPickup.PickupItemById(it.id)
        end
    end

    if #batchIds > 0 then
        ModGroundPickup.PickupItemsBatch(batchIds)
    end

    table.sort(items, function(a, b)
        return (a.dist or 999) < (b.dist or 999)
    end)
    local nearest = items[1]

    if allowMove and nearest and nearest.dist and nearest.dist > 1.2 then
        local me = _G.RoleManager and _G.RoleManager.me
        if me and me.MoveTo and nearest.x > 0 and nearest.y > 0 then
            pcall(function()
                if me.StopMoveImmediate then me:StopMoveImmediate() end
                if me.MoveCloseAutoFight then me:MoveCloseAutoFight() end
                if me.SetAutoFight then me:SetAutoFight("None") end
                me:MoveTo({ x = nearest.x, y = nearest.y }, 0)
            end)
        end
    end

    return {
        isClean = false,
        count = #items,
        nearest = nearest,
        batchIds = batchIds
    }
end

return ModGroundPickup

