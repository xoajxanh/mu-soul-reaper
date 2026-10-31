-- =========================================================================
-- [MODULE]: mod_bag_items.lua
-- Mục đích: Quét, tra cứu, đếm và lấy dữ liệu vật phẩm trong túi đồ (Bag)
-- Tham chiếu code gốc:
--   - BagInfoData.lua, BehaviorNode.lua, ItemUtility.lua
--   - EmmyluaDebug.lua lines 1219-1225, 4187-4190, 4806-4820, 7467-7468, 9892-9893
-- CẢNH BÁO QUAN TRỌNG:
--   - KHÔNG ĐƯỢC DÙNG `BagInfoData.bagItems` (BỊ NIL TRONG GAME!).
--   - PHẢI DÙNG `BagInfoData.TotalItems` hoặc hàm `BagInfoData.GetItemByConfigID(cfgId)`.
-- =========================================================================

local ModBagItems = {}

--- Lấy danh sách toàn bộ vật phẩm trong túi đồ
-- @return table danh sách item data
function ModBagItems.GetTotalItems()
    local items = _G.BagInfoData and _G.BagInfoData.TotalItems
    if not items and _G.BagInfoData and _G.BagInfoData.GetTotalItems then
        pcall(function() items = _G.BagInfoData:GetTotalItems() end)
    end
    return items or {}
end

--- Đếm tổng số lượng của 1 Item Config ID trong túi đồ
-- @param configId number: ID cấu hình của vật phẩm (ví dụ: 20000021 bùa về thành, 3000400 thẻ exp)
-- @return number: Số lượng vật phẩm đang có
function ModBagItems.GetItemCount(configId)
    if not configId or configId <= 0 then return 0 end

    -- Cách nhanh & chuẩn nhất: Gọi hàm sẵn có của game
    if _G.BagInfoData and _G.BagInfoData.GetItemTotalCountByItemId then
        local count = 0
        local ok = pcall(function()
            count = _G.BagInfoData.GetItemTotalCountByItemId(configId) or 0
        end)
        if ok and count >= 0 then return count end
    end

    -- Cách fallback: Duyệt TotalItems
    local total = 0
    local items = ModBagItems.GetTotalItems()
    for _, item in pairs(items) do
        if item then
            local cId = item.itemId or (item.data and item.data.itemId) or (item.tblItem and item.tblItem.id) or 0
            if cId == configId then
                local cnt = item.count or (item.data and item.data.count) or 1
                total = total + cnt
            end
        end
    end
    return total
end

--- Tìm vật phẩm đầu tiên trong túi khớp với configId
-- @param configId number
-- @return table|nil: Item object (chứa .id instanceId, .itemId, .tblItem, .serverInfo...)
function ModBagItems.FindItemByConfigId(configId)
    if not configId or configId <= 0 then return nil end

    -- 1. Ưu tiên hàm của game
    if _G.BagInfoData and _G.BagInfoData.GetItemByConfigID then
        local item = nil
        pcall(function() item = _G.BagInfoData.GetItemByConfigID(configId) end)
        if item then return item end
    end

    -- 2. Quét thủ công trong TotalItems
    local items = ModBagItems.GetTotalItems()
    for _, item in pairs(items) do
        if item then
            local cId = item.itemId or (item.data and item.data.itemId) or (item.tblItem and item.tblItem.id) or 0
            if cId == configId then
                return item
            end
        end
    end
    return nil
end

--- Tìm kiếm các vật phẩm theo tên (hỗ trợ tìm chuỗi con, không phân biệt hoa thường)
-- @param keyword string: Từ khóa tìm kiếm (ví dụ "Buff EXP", "Thuốc", "Vé")
-- @return table: Danh sách các item thỏa mãn
function ModBagItems.FindItemsByName(keyword)
    local results = {}
    if not keyword or keyword == "" then return results end

    local items = ModBagItems.GetTotalItems()
    for _, item in pairs(items) do
        if item then
            local tblItem = item.tblItem or (item.data and item.data.tblItem) or {}
            local name = tblItem.name or item.name or ""
            if string.find(name, keyword) then
                table.insert(results, item)
            end
        end
    end
    return results
end

--- Tìm vật phẩm đầu tiên khớp với một trong các configId trong danh sách ưu tiên
-- @param configIdList table: Mảng các ID theo thứ tự ưu tiên { id1, id2, id3... }
-- @return table|nil: Item tìm thấy đầu tiên
function ModBagItems.FindItemInPriorityList(configIdList)
    if not configIdList or #configIdList == 0 then return nil end
    for _, cfgId in ipairs(configIdList) do
        local it = ModBagItems.FindItemByConfigId(cfgId)
        if it then return it end
    end
    return nil
end

--- Lấy Instance ID (GUID trong túi) của item để gửi packet mạng
-- @param item table
-- @return number|string|nil: id để truyền vào ReqUseItem
function ModBagItems.GetInstanceId(item)
    if not item then return nil end
    return item.id or (item.data and item.data.id) or (item.serverInfo and item.serverInfo.id)
end

--- Kiểm tra trạng thái sức chứa của túi đồ
-- @return table: { isFull = boolean, curCount = number, maxCount = number, freeCount = number }
function ModBagItems.GetBagCapacity()
    local curBagCount = (_G.BagInfoData and _G.BagInfoData.curBagCellCount) or 0
    local maxBagCount = (_G.BagInfoData and _G.BagInfoData.bagCellCount) or 0
    local totalItems = ModBagItems.GetTotalItems()
    local usedCount = 0
    for _ in pairs(totalItems) do usedCount = usedCount + 1 end

    local isFull = (_G.BagInfoData and _G.BagInfoData.bagFull) or (usedCount >= curBagCount)

    return {
        isFull = isFull,
        usedCount = usedCount,
        curCellCount = curBagCount,
        maxCellCount = maxBagCount,
        freeCount = math.max(0, curBagCount - usedCount)
    }
end

--- Lấy số lượng tiền tệ / tài nguyên theo Config ID (1000021: Vàng Khóa, 1000020: Vàng, 1000030: Kim Cương, 1000010: Zen)
-- LƯU Ý: Không dùng GetItemTotalCountByItemId(1000021) vì hàm đó sẽ cộng gộp cả Vàng không khóa (bindEqualItem = 1000020).
-- @param coinConfigId number: Mặc định 1000021 (Vàng Khóa)
-- @return number: Số dư hiện tại
function ModBagItems.GetCoinCount(coinConfigId)
    coinConfigId = coinConfigId or 1000021
    local amount = 0
    pcall(function()
        if _G.BagInfoData then
            if _G.BagInfoData.CoinInfos and _G.BagInfoData.CoinInfos[coinConfigId] then
                amount = _G.BagInfoData.CoinInfos[coinConfigId]
            elseif _G.BagInfoData.GetItemCountByItemConfigId then
                amount = _G.BagInfoData.GetItemCountByItemConfigId(coinConfigId) or 0
            end
        end
    end)
    return amount
end

--- Lấy nhanh số Vàng Khóa hiện tại của nhân vật (Config ID: 1000021)
-- @return number
function ModBagItems.GetBoundGoldCount()
    return ModBagItems.GetCoinCount(1000021)
end

--- Định dạng số có dấu phẩy ngăn cách hàng nghìn (ví dụ: 1250000 -> "1,250,000")
-- @param n number
-- @return string
function ModBagItems.FormatNumber(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local k
    while true do
        s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return s
end

return ModBagItems
