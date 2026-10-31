-- =========================================================================
-- [MODULE]: mod_player_info.lua
-- Mục đích: Đọc đầy đủ thông tin người chơi (Role / Player / Guild / Position)
-- Tham chiếu code gốc:
--   - RoleManager.lua, Me.lua, ViewData.lua, WarAllianceData.lua
--   - EmmyluaDebug.lua lines 640-690, 1660-1670, 2180-2195, 6770-6775
-- =========================================================================

local ModPlayerInfo = {}

--- Lấy object Me hiện tại
function ModPlayerInfo.GetMe()
    return _G.RoleManager and _G.RoleManager.me
end

--- Lấy dữ liệu cơ bản nhân vật (ID, Tên, Cấp độ, Lực chiến)
function ModPlayerInfo.GetBasicInfo()
    local me = ModPlayerInfo.GetMe()
    local meData = _G.ViewData and _G.ViewData.meData

    local id = (me and me.id) or (meData and meData.id) or 0
    local name = (me and me.name) or (meData and meData.name) or "Unknown"
    local level = tonumber((meData and meData.level) or (me and me.level) or 1)
    local masterLevel = tonumber((meData and meData.masterLevel) or (me and me.masterLevel) or 0)
    local fight = tonumber((meData and meData.fight) or 0)
    local career = (me and me.career) or (meData and meData.career) or 0

    local careerName = "Unknown"
    if _G.RoleUtility and _G.RoleUtility.GetCareerName then
        pcall(function() careerName = _G.RoleUtility.GetCareerName(career) end)
    end

    local basicCareer = 0
    if _G.RoleUtility and _G.RoleUtility.GetBasicCareer then
        pcall(function() basicCareer = _G.RoleUtility.GetBasicCareer(career) end)
    end

    return {
        id = id,
        name = name,
        level = level,
        masterLevel = masterLevel,
        fight = fight,
        career = career,
        careerName = careerName,
        basicCareer = basicCareer,
        isDead = (me and me.isDead) or false
    }
end

--- Lấy thông tin máu & mana hiện tại
function ModPlayerInfo.GetHpMp()
    local me = ModPlayerInfo.GetMe()
    if not me then return { hp = 0, maxHp = 1, mp = 0, maxMp = 1, hpPercent = 0, mpPercent = 0 } end

    local hp = tonumber(me.hp) or 0
    local maxHp = tonumber(me.maxHp) or 1
    local mp = tonumber(me.mp) or 0
    local maxMp = tonumber(me.maxMp) or 1

    return {
        hp = hp,
        maxHp = maxHp,
        mp = mp,
        maxMp = maxMp,
        hpPercent = (hp / maxHp) * 100,
        mpPercent = (mp / maxMp) * 100
    }
end

--- Lấy tọa độ nhân vật (Ưu tiên: ServerCoord -> CellPos -> Position 3D)
function ModPlayerInfo.GetPosition()
    local me = ModPlayerInfo.GetMe()
    if not me then return { x = 0, y = 0, z = 0, cellX = 0, cellY = 0 } end

    local sX = (me.serverCoord and me.serverCoord.x) or (me.cellPos and me.cellPos.x) or 0
    local sY = (me.serverCoord and me.serverCoord.y) or (me.cellPos and me.cellPos.y) or 0
    local cX = (me.cellPos and me.cellPos.x) or sX
    local cY = (me.cellPos and me.cellPos.y) or sY
    local pX = (me.Position and me.Position.x) or cX
    local pY = (me.Position and me.Position.y) or cY
    local pZ = (me.Position and me.Position.z) or 0

    return {
        serverX = sX,
        serverY = sY,
        cellX = cX,
        cellY = cY,
        worldX = pX,
        worldY = pY,
        worldZ = pZ
    }
end

--- Lấy thông tin bản đồ hiện tại (MapId, MapName, GroupId)
function ModPlayerInfo.GetCurrentMap()
    local mapId = (_G.SceneData and (_G.SceneData.mapId or _G.SceneData.groupId)) or 0
    local groupId = (_G.SceneData and _G.SceneData.groupId) or mapId
    local mapName = "Unknown Map"

    if mapId > 0 and _G.ClientTable and _G.ClientTable.cfg_Map_mapManager then
        pcall(function()
            local mapTbl = _G.ClientTable.cfg_Map_mapManager:TryGetValue(mapId, "id")
            if mapTbl and mapTbl.name then
                mapName = mapTbl.name
            end
        end)
    end

    return {
        mapId = mapId,
        groupId = groupId,
        mapName = mapName
    }
end

--- Lấy thông tin bang hội (Guild / WarAlliance)
function ModPlayerInfo.GetGuildInfo()
    local hasGuild = (_G.WarAllianceData and _G.WarAllianceData.IsHaveUnion) or false
    local guildData = (_G.WarAllianceData and _G.WarAllianceData.MyWarAllianceData) or {}

    local guildId = guildData.id or 0
    local guildName = guildData.name or (hasGuild and "Có bang" or "Chưa vào bang")
    local isLeader = false
    if _G.WarAllianceData and _G.WarAllianceData.IsLeader then
        pcall(function() isLeader = _G.WarAllianceData.IsLeader() end)
    end

    return {
        hasGuild = hasGuild,
        guildId = guildId,
        guildName = guildName,
        isLeader = isLeader
    }
end

--- Kiểm tra một nhân vật khác có cùng bang với mình không
function ModPlayerInfo.IsSameGuild(targetRoleId)
    if not targetRoleId then return false end
    if _G.WarAllianceData and _G.WarAllianceData.GetIsSameUnion then
        local isSame = false
        pcall(function() isSame = _G.WarAllianceData.GetIsSameUnion(targetRoleId) end)
        return isSame
    end
    return false
end

--- Lấy chế độ PK hiện tại (0: Hòa bình, 1: Toàn thể, 2: Tổ đội, 3: Bang...)
function ModPlayerInfo.GetPKMode()
    local me = ModPlayerInfo.GetMe()
    return (me and me.PKMode) or 0
end

return ModPlayerInfo
