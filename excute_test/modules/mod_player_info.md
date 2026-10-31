# 👤 MODULE 1: THÔNG TIN NGƯỜI CHƠI (PLAYER INFO)

## 📌 File Code: [`mod_player_info.lua`](./mod_player_info.lua)

Module này chuyên trách cung cấp thông tin nhân vật của người chơi: tên, ID, cấp độ, chức nghiệp (career), bang hội (WarAlliance), máu/mana, chế độ PK và tọa độ.

---

### 📍 Các Đoạn Code Đã Dùng Trong Mod Nguồn (`modified_lua_dev_client\EmmyluaDebug.lua`)

1. **Lấy RoleID & Level**:
   * *Line 688, 833*:
     ```lua
     local roleId = tostring((_G.ViewData and _G.ViewData.meData and _G.ViewData.meData.id) or (_G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.id) or 0)
     ```
   * *Line 9880*:
     ```lua
     local pMe = _G.RoleManager and _G.RoleManager.me
     local curLvl = tonumber((_G.ViewData and _G.ViewData.meData and _G.ViewData.meData.level) or (pMe and pMe.level) or 1)
     ```
2. **Lấy Nghề Nghiệp (Career)**:
   * *Line 640-641*:
     ```lua
     local isSum = (_G.RoleUtility.GetBasicCareer(_G.RoleManager.me.career) == _G.ERoleCareer.SummonMagician)
     ```
3. **Lấy Tọa Độ & Bản Đồ**:
   * *Line 9778-9780*:
     ```lua
     local curX = (me.serverCoord and me.serverCoord.x) or (me.cellPos and me.cellPos.x) or (me.Position and me.Position.x) or 0
     local curY = (me.serverCoord and me.serverCoord.y) or (me.cellPos and me.cellPos.y) or (me.Position and me.Position.y) or 0
     ```
   * *Line 9678-9680*:
     ```lua
     local cMap = (_G.SceneData and (_G.SceneData.mapId or _G.SceneData.groupId)) or 0
     ```
4. **Bang Hội (Guild)**:
   * *Line 6773*:
     ```lua
     if _G.WarAllianceData and _G.WarAllianceData.GetIsSameUnion and _G.WarAllianceData.GetIsSameUnion(ownerId) then
     ```
   * *File gốc `WarAllianceData.lua`*:
     - `WarAllianceData.IsHaveUnion`: `true`/`false` (Đã vào bang hay chưa)
     - `WarAllianceData.MyWarAllianceData.name`: Tên Bang
     - `WarAllianceData.MyWarAllianceData.id`: ID Bang

---

### 💡 Cách Sử Dụng Nhanh

```lua
local PlayerInfo = require("modules.mod_player_info")

local basic = PlayerInfo.GetBasicInfo()
print(string.format("Người chơi: %s (Lv %d, Nghề: %s)", basic.name, basic.level, basic.careerName))

local pos = PlayerInfo.GetPosition()
print(string.format("Tọa độ hiện tại: %d#%d", pos.cellX, pos.cellY))

local guild = PlayerInfo.GetGuildInfo()
print(string.format("Bang hội: %s (HasGuild: %s)", guild.guildName, tostring(guild.hasGuild)))
```
