---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global
---@diagnostic disable: duplicate-set-field
-- EmmyluaDebug.lua
-- Bắt buộc phải có để Main.lua gọi không bị lỗi
EmmyluaDebug = {}

--------------------------------------------------------------------------------
-- ACTIVE SYSTEM CORE (Remote Config & Active Validation)
--------------------------------------------------------------------------------
_G.Mod_IsDev = true
_G.Mod_IsActive = false
_G.Mod_ActiveConfig = nil
_G.Mod_HasFetchedConfig = false
_G.Mod_RawConfigPayload = ""
_G.Mod_ActiveStatusMsg = "Bản Mod chưa được kích hoạt!"

_G.Mod_Config_FOV_Min = 30
_G.Mod_Config_FOV_Max = 50
_G.Mod_Config_BossRefresh_Min = 3
_G.Mod_Config_BossRefresh_Max = 60
_G.Mod_Config_MaxMoveSpeed = 1.5
_G.Mod_Config_MaxAttackSpeed = 2.0
_G.Mod_Config_MaxMonsterRange = 12
_G.Mod_Config_MaxPickupCount = 5
_G.Mod_Config_PickupDelay_Min = 100
_G.Mod_Config_PickupDelay_Max = 500
_G.Mod_Config_ActiveBasicTab = true
_G.Mod_Config_ActiveAdvancedTab = true
_G.Mod_Config_ActiveAutoFarmTab = true
-- =========================================================================
-- [MOD FEATURE]: CẤU HÌNH LIÊN HỆ ADMIN (TELEGRAM & ZALO)
-- Mô tả: Đường dẫn liên hệ hỗ trợ kích hoạt bản quyền cho khách
-- =========================================================================
_G.Mod_Config_AdminTelegram = { "vutmod" }
_G.Mod_Config_AdminZalo = "https://zalo.me/0386918686"
_G.Mod_Config_AdminZaloPhone = "0386918686"

local SECRET_SALT = "MUVH_SECRET_SALT_XOAI"

local function Mod_CalculateMD5(str)
    if not str or str == "" then return "" end
    local ok1, pcRes = pcall(function()
        if CS.PCUtility and CS.PCUtility.Md5 then
            return string.lower(tostring(CS.PCUtility.Md5(str)))
        end
    end)
    if ok1 and pcRes and pcRes ~= "" and pcRes ~= "nil" then return pcRes end

    local ok2, res = pcall(function()
        local md5 = CS.System.Security.Cryptography.MD5.Create()
        local bytes = CS.System.Text.Encoding.UTF8:GetBytes(str)
        local hash = md5:ComputeHash(bytes)
        local hexTbl = {}
        for i = 0, hash.Length - 1 do
            table.insert(hexTbl, string.format("%02x", hash[i]))
        end
        return table.concat(hexTbl)
    end)
    if ok2 and res then return res end
    return ""
end

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function Mod_Base64Decode(b64Str)
    if not b64Str or b64Str == "" then return nil end
    local ok1, res1 = pcall(function()
        local bytes = CS.System.Convert.FromBase64String(b64Str)
        return CS.System.Text.Encoding.UTF8:GetString(bytes)
    end)
    if ok1 and res1 and res1 ~= "" and res1 ~= "nil" then return res1 end

    local ok2, res2 = pcall(function()
        local data = string.gsub(b64Str, '[^' .. b64chars .. '=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r, f = '', (b64chars:find(x) - 1)
            for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end))
    end)
    if ok2 and res2 then return res2 end
    return nil
end

local function Mod_ParseJSON(str)
    if not str or str == "" then return nil end
    local function parseValue(valStr)
        valStr = string.gsub(valStr, "^%s*(.-)%s*$", "%1")
        if valStr == "true" then return true end
        if valStr == "false" then return false end
        if valStr == "null" then return nil end
        if string.sub(valStr, 1, 1) == '"' and string.sub(valStr, -1) == '"' then
            return string.sub(valStr, 2, -2)
        end
        local num = tonumber(valStr)
        if num then return num end
        return valStr
    end
    local result = {}
    for k, v in string.gmatch(str, '"([^"]+)":%s*([^,{}%]]+)') do
        result[k] = parseValue(v)
    end
    local arrKey, arrBody = string.match(str, '"([^"]+)":%s*%[([^%]]+)%]')
    if arrKey and arrBody then
        local arr = {}
        for item in string.gmatch(arrBody, '"([^"]+)"') do
            table.insert(arr, item)
        end
        result[arrKey] = arr
    end
    return result
end

local function Mod_GetDeviceSerialMD5()
    local rawSerial = ""
    pcall(function()
        rawSerial = CS.UnityEngine.SystemInfo.deviceUniqueIdentifier
    end)
    if not rawSerial or rawSerial == "" then rawSerial = "UNKNOWN_DEVICE_ID" end
    return Mod_CalculateMD5(rawSerial)
end

local function Mod_GetCharacterUID()
    local uid = ""
    pcall(function()
        if _G.LoginData and _G.LoginData.sdk_pid and tostring(_G.LoginData.sdk_pid) ~= "" then
            uid = tostring(_G.LoginData.sdk_pid)
        end
    end)
    return uid
end

-- =========================================================================
-- [MOD FEATURE]: TRÍCH XUẤT THÔNG TIN NHÂN VẬT & MÁY CHỦ CHO CUSTOMER
-- Mô tả: Lấy tên nhân vật, máy chủ để ghi nhận lịch sử đăng nhập thiết bị
-- =========================================================================
local function Mod_GetCharacterRoleName()
    local roleName = ""
    pcall(function()
        if _G.ViewData and _G.ViewData.meData and _G.ViewData.meData.name then
            roleName = tostring(_G.ViewData.meData.name)
        elseif _G.RoleManager and _G.RoleManager.me then
            local me = _G.RoleManager.me
            if me.name and me.name ~= "" then
                roleName = tostring(me.name)
            elseif me.data and me.data.name and me.data.name ~= "" then
                roleName = tostring(me.data.name)
            end
        elseif _G.LoginData and _G.LoginData.roleName and _G.LoginData.roleName ~= "" then
            roleName = tostring(_G.LoginData.roleName)
        end
    end)
    return roleName
end
_G.Mod_GetCharacterRoleName = Mod_GetCharacterRoleName

local function Mod_GetServerName()
    local serverName = ""
    pcall(function()
        if _G.LoginData then
            if _G.LoginData.GetServerName then
                serverName = tostring(_G.LoginData.GetServerName())
            elseif _G.LoginData.server_name then
                serverName = tostring(_G.LoginData.server_name)
            elseif _G.LoginData.serverName then
                serverName = tostring(_G.LoginData.serverName)
            end
        end
    end)
    return serverName
end
_G.Mod_GetServerName = Mod_GetServerName

local function Mod_UrlEncode(str)
    if not str then return "" end
    str = string.gsub(tostring(str), "\n", "\r\n")
    str = string.gsub(str, "([^%w%-_%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return str
end
_G.Mod_UrlEncode = Mod_UrlEncode

local function Mod_DecryptPayload(payloadB64)
    if _G.WriteLog then
        _G.WriteLog("[ActiveCheck] [BUOC 4.1] Giai ma Base64 Envelope, Do dai = " ..
            tostring(#payloadB64))
    end
    if not payloadB64 or payloadB64 == "" then return nil, "Payload rỗng" end
    local decoded = Mod_Base64Decode(payloadB64)
    if not decoded then
        if _G.WriteLog then _G.WriteLog("[ActiveCheck] [LOI] Mod_Base64Decode giai ma thoi ban Base64 that bai!") end
        return nil, "Không thể giải mã Base64"
    end
    local jsonStr, signature = string.match(decoded, "^(.*)|([a-fA-F0-9]+)$")
    if not jsonStr or not signature then
        if _G.WriteLog then _G.WriteLog("[ActiveCheck] [LOI] Cau truc Envelope khong chua ky tu '|' va MD5 signature!") end
        return nil, "Cấu trúc Payload không hợp lệ"
    end
    if _G.WriteLog then
        _G.WriteLog("[ActiveCheck] [BUOC 4.2] Tách JSON String len = " ..
            tostring(#jsonStr) .. ", Signature = " .. tostring(signature))
    end
    local expectedSig = Mod_CalculateMD5(jsonStr .. SECRET_SALT)
    if string.lower(expectedSig) ~= string.lower(signature) then
        if _G.WriteLog then
            _G.WriteLog("[ActiveCheck] [LOI CHU KY] Expected MD5=" ..
                tostring(expectedSig) .. " != Server Signature=" .. tostring(signature))
        end
        return nil, "Chữ ký MD5 không hợp lệ!"
    end
    if _G.WriteLog then
        _G.WriteLog(
            "[ActiveCheck] [BUOC 4.3] Chu ky MD5 Salt TRUNG KHOP 100%! Dang parse Config JSON...")
    end
    local configObj = Mod_ParseJSON(jsonStr)
    if not configObj then return nil, "Không thể đọc dữ liệu JSON" end
    return configObj, nil
end

local API_BASE_URL = "http://g3events.asia/api/v1/config"

local function Mod_ValidateConfig(config)
    if not config then return false, "Chưa có cấu hình kích hoạt!" end
    local currentTime = os.time()
    if config.expire_time and currentTime > tonumber(config.expire_time) then
        return false, "Tài khoản / Cấu hình đã hết hạn sử dụng!"
    end
    local currentSerialMD5 = Mod_GetDeviceSerialMD5()
    local cfgSN = config.device_sn_hash or config.serial_number
    if cfgSN and tostring(cfgSN) ~= "" then
        local cfgSNStr = tostring(cfgSN)
        local cfgSNMD5 = Mod_CalculateMD5(cfgSNStr)
        if cfgSNStr ~= currentSerialMD5 and cfgSNMD5 ~= currentSerialMD5 then
            return false, "Mã thiết bị (Serial MD5) không trùng khớp!"
        end
    end
    local cfgUID = config.character_uid or config.uid
    local currentUID = Mod_GetCharacterUID()
    if cfgUID and tostring(cfgUID) ~= "" then
        if currentUID == "" then
            return false, "Vui lòng đăng nhập nhân vật trong game để xác thực UID!"
        end
        if tostring(cfgUID) ~= currentUID then
            return false, "Mã nhân vật (UID) không trùng khớp!"
        end
    end
    return true, "OK"
end

local function Mod_FormatExpireDate(ts)
    if not ts then return "Không giới hạn" end
    local num = tonumber(ts)
    if not num or num <= 0 then return "Không giới hạn" end
    local ok, res = pcall(function()
        return os.date("%d/%m/%Y %H:%M", num)
    end)
    if ok and res then return res end
    return tostring(ts)
end

_G.Mod_ActiveTimers = _G.Mod_ActiveTimers or {}

_G.Mod_StopTimer = function(name)
    pcall(function()
        if not name then return end
        if _G.Mod_ActiveTimers and _G.Mod_ActiveTimers[name] then
            if _G.Timer and _G.Timer.Stop then
                _G.Timer.Stop(_G.Mod_ActiveTimers[name])
            end
            _G.Mod_ActiveTimers[name] = nil
        end
    end)
end

_G.Mod_StopAllTimers = function()
    pcall(function()
        if not _G.Mod_ActiveTimers then return end
        for k, timerObj in pairs(_G.Mod_ActiveTimers) do
            if timerObj and _G.Timer and _G.Timer.Stop then
                pcall(function() _G.Timer.Stop(timerObj) end)
            end
            _G.Mod_ActiveTimers[k] = nil
        end
    end)
end

_G.Mod_StartTrackedTimer = function(name, interval, count, callback)
    if not name or not callback then return nil end
    _G.Mod_StopTimer(name)
    local timerObj = nil
    if _G.Timer then
        if count == -1 then
            if _G.Timer.StartLoopForever then
                timerObj = _G.Timer.StartLoopForever(interval, callback)
            elseif _G.Timer.StartLoop then
                timerObj = _G.Timer.StartLoop(interval, -1, callback)
            end
        elseif count == 1 and _G.Timer.Start then
            timerObj = _G.Timer.Start(interval, callback)
        elseif _G.Timer.StartLoop then
            timerObj = _G.Timer.StartLoop(interval, count, callback)
        end
    end
    if timerObj then
        _G.Mod_ActiveTimers[name] = timerObj
    end
    return timerObj
end

local function SetCameraFOV(fov)
    if not fov then return end
    local maxFov = _G.Mod_Config_FOV_Max or 50
    local minFov = _G.Mod_Config_FOV_Min or 35
    fov = math.max(minFov, math.min(maxFov, fov))
    _G.currentFOV = fov
    _G.SavedFOV = fov
    pcall(function()
        local cam = CS.UnityEngine.Camera.main
        if cam then
            cam.fieldOfView = fov
        end
        CS.UnityEngine.PlayerPrefs.SetFloat("Mod_FOV", fov)
        CS.UnityEngine.PlayerPrefs.Save()
    end)
end
_G.SetCameraFOV = SetCameraFOV

_G.Mod_ResetSavedModConfigs = function()
    _G.Mod_AutoFarmBoss_Config = {}
    _G.Mod_SmeltConfig = {}
    for t = 3, 12 do
        _G.Mod_SmeltConfig["KeepGood_C" .. t] = true
        _G.Mod_SmeltConfig["KeepGoodTV_C" .. t] = true
    end
    _G.Mod_AutoFarmBoss_Target = nil
    pcall(function()
        local modKeys = {
            "Mod_AutoPick_Limit", "Mod_FOV", "Mod_AutoRefresh", "Mod_RefreshInterval",
            "Mod_ShowKundunHP", "Mod_AutoGuildPK_Enabled", "Mod_LockTarget_Enabled", "Mod_LockTarget_Name",
            "ModAutoBossConfigTab", "Mod_AutoFarmBoss_EnterHiddenMap_Diamond"
        }
        for _, k in ipairs(modKeys) do
            CS.UnityEngine.PlayerPrefs.DeleteKey(k)
        end
        CS.UnityEngine.PlayerPrefs.Save()
    end)
    if _G.WriteLog then _G.WriteLog("[Mod] Reset complete Mod_AutoFarmBoss_Config, Mod_SmeltConfig & safe Mod keys!") end
end

local function Mod_ApplyConfig(config)
    _G.Mod_ActiveConfig = config
    _G.Mod_IsActive = true
    _G.Mod_LastVerifiedUID = Mod_GetCharacterUID()
    if config.fov_min then _G.Mod_Config_FOV_Min = tonumber(config.fov_min) end
    if config.fov_max then _G.Mod_Config_FOV_Max = tonumber(config.fov_max) end
    if config.boss_refresh_min then _G.Mod_Config_BossRefresh_Min = tonumber(config.boss_refresh_min) end
    if config.boss_refresh_max then _G.Mod_Config_BossRefresh_Max = tonumber(config.boss_refresh_max) end
    if config.max_move_speed then _G.Mod_Config_MaxMoveSpeed = tonumber(config.max_move_speed) end
    if config.max_attack_speed then _G.Mod_Config_MaxAttackSpeed = tonumber(config.max_attack_speed) end
    -- =========================================================================
    -- [MOD FEATURE]: GIỚI HẠN TỐI ĐA PHÁT HIỆN ĐỊCH (MAX 15)
    -- Mô tả: Kể cả Token có cấu hình max_monster_range bao nhiêu cũng chỉ lấy tối đa 15
    -- =========================================================================
    if config.max_monster_range then
        _G.Mod_Config_MaxMonsterRange = math.min(15, tonumber(config.max_monster_range) or 15)
    else
        _G.Mod_Config_MaxMonsterRange = math.min(15, _G.Mod_Config_MaxMonsterRange or 12)
    end
    if config.max_pickup_count then _G.Mod_Config_MaxPickupCount = tonumber(config.max_pickup_count) end
    if config.pickup_delay_min then _G.Mod_Config_PickupDelay_Min = tonumber(config.pickup_delay_min) end
    if config.pickup_delay_max then _G.Mod_Config_PickupDelay_Max = tonumber(config.pickup_delay_max) end

    if config.active_basic_tab ~= nil then
        _G.Mod_Config_ActiveBasicTab = config.active_basic_tab
    elseif config.active_tab_basic ~= nil then
        _G.Mod_Config_ActiveBasicTab = config.active_tab_basic
    end

    if config.active_advanced_tab ~= nil then
        _G.Mod_Config_ActiveAdvancedTab = config.active_advanced_tab
    elseif config.active_tab_advanced ~= nil then
        _G.Mod_Config_ActiveAdvancedTab = config.active_tab_advanced
    end

    if config.active_autofarm_tab ~= nil then
        _G.Mod_Config_ActiveAutoFarmTab = config.active_autofarm_tab
    elseif config.active_tab_autofarm ~= nil then
        _G.Mod_Config_ActiveAutoFarmTab = config.active_tab_autofarm
    end

    _G.Mod_AutoFarmBoss_Config = _G.Mod_AutoFarmBoss_Config or {}
    _G.Mod_SmeltConfig = _G.Mod_SmeltConfig or {}

    local reincPrimary = tonumber(config.character_reincarnation_primary)
        or tonumber(config.character_reincarnation)
        or _G.Mod_Config_CurrentRebirth
        or 8
    local reincSecondary = tonumber(config.character_reincarnation_secondary)
        or (reincPrimary > 1 and (reincPrimary - 1) or 1)

    if reincPrimary and reincPrimary >= 3 and reincPrimary <= 12 then
        _G.Mod_Config_Reincarnation_Primary = reincPrimary
        _G.Mod_Config_CurrentRebirth = reincPrimary
        _G.ModBossTab = "C" .. tostring(reincPrimary)
        _G.ModAutoBossConfigTab = "C" .. tostring(reincPrimary)
        _G.ModKundunBossTab = "C" .. tostring(reincPrimary)
    end
    if reincSecondary and reincSecondary >= 1 and reincSecondary <= 12 then
        _G.Mod_Config_Reincarnation_Secondary = reincSecondary
    end

    if _G.Mod_DisableVisuals == nil then
        pcall(function()
            _G.Mod_DisableVisuals = CS.UnityEngine.PlayerPrefs.GetInt("Mod_DisableVisuals", 0) == 1
        end)
        if _G.Mod_DisableVisuals == nil then _G.Mod_DisableVisuals = false end
    end
    _G.Mod_IsDisableVisualsActive = function()
        return (_G.Mod_DisableVisuals == true) or (_G.AutoPick_Enabled == true)
    end
    if _G.Mod_FindHoaLong_Enabled == nil then
        _G.Mod_FindHoaLong_Enabled = false
    end

    if _G.RunSpeedMultiplier and _G.Mod_Config_MaxMoveSpeed then
        _G.RunSpeedMultiplier = math.min(_G.RunSpeedMultiplier, _G.Mod_Config_MaxMoveSpeed)
    end
    if _G.AtkSpeedMultiplier and _G.Mod_Config_MaxAttackSpeed then
        _G.AtkSpeedMultiplier = math.min(_G.AtkSpeedMultiplier, _G.Mod_Config_MaxAttackSpeed)
    end
    if _G.Mod_CustomAttackRange then
        local maxRange = math.min(15, _G.Mod_Config_MaxMonsterRange or 15)
        _G.Mod_CustomAttackRange = math.min(_G.Mod_CustomAttackRange, maxRange)
    end
    if _G.AutoPick_Limit and _G.Mod_Config_MaxPickupCount then
        _G.AutoPick_Limit = math.min(_G.AutoPick_Limit, _G.Mod_Config_MaxPickupCount)
    end

    -- Clamping current FOV to new remote config boundaries
    local maxFov = _G.Mod_Config_FOV_Max or 50
    local minFov = _G.Mod_Config_FOV_Min or 35
    _G.currentFOV = _G.currentFOV or maxFov
    if _G.currentFOV > maxFov then _G.currentFOV = maxFov end
    if _G.currentFOV < minFov then _G.currentFOV = minFov end
    if _G.fovValTxt and not _G.fovValTxt:Equals(nil) then
        _G.fovValTxt.text = "FOV: " .. tostring(_G.currentFOV)
    end
    if _G.SetCameraFOV then _G.SetCameraFOV(_G.currentFOV) end
    if _G.RefreshMainTabs then _G.RefreshMainTabs() end
    if _G.ParseBossData then pcall(_G.ParseBossData) end
    if _G.UpdateBossWatchUIText then pcall(_G.UpdateBossWatchUIText) end
    if _G.ModUpdateKundunUI then pcall(_G.ModUpdateKundunUI) end
    if _G.ModRefreshAutoBossConfigUI then pcall(_G.ModRefreshAutoBossConfigUI) end

    local expireStr = Mod_FormatExpireDate(config.expire_time)
    _G.Mod_ActiveStatusMsg = "Đã kích hoạt thành công! Hạn dùng: " ..
        expireStr ..
        " | FOV Max: " .. tostring(_G.Mod_Config_FOV_Max) .. " | Tốc đánh: " .. tostring(_G.Mod_Config_MaxAttackSpeed)

    if _G.WriteLog then
        _G.WriteLog("[ActiveCheck] GIAI MA THANH CONG! Hạn dùng: " ..
            expireStr ..
            " | FOV: " ..
            tostring(_G.Mod_Config_FOV_Min) ..
            "-" ..
            tostring(_G.Mod_Config_FOV_Max) ..
            " | Delay: " ..
            tostring(_G.Mod_Config_PickupDelay_Min) .. "-" .. tostring(_G.Mod_Config_PickupDelay_Max) .. "ms")
    end

    if _G.Mod_UpdateUI_ActiveState then _G.Mod_UpdateUI_ActiveState() end
    if _G.RefreshMainTabs then _G.RefreshMainTabs() end
end

local function Mod_FetchRemotePayloadFromAPI(isInitialLogin, callback)
    local serialMD5 = Mod_GetDeviceSerialMD5()
    local uid = Mod_GetCharacterUID()
    local roleName = Mod_GetCharacterRoleName()
    local serverName = Mod_GetServerName()
    local isLoginParam = isInitialLogin and "1" or "0"

    local url = API_BASE_URL .. "?sn=" .. tostring(serialMD5) ..
                "&uid=" .. tostring(uid) ..
                "&name=" .. Mod_UrlEncode(roleName) ..
                "&server=" .. Mod_UrlEncode(serverName) ..
                "&isLogin=" .. isLoginParam

    if _G.WriteLog then
        _G.WriteLog("[ActiveCheck] [BUOC 1] Gui request API: " .. tostring(url))
    end

    pcall(function()
        local req = CS.UnityEngine.Networking.UnityWebRequest.Get(url)
        req.timeout = 10
        local asyncOp = req:SendWebRequest()

        local count = 0
        local hasFinished = false
        local timerObj = nil
        if _G.Timer and _G.Timer.StartLoop then
            timerObj = _G.Timer.StartLoop(0.05, 100, function()
                if hasFinished then return end
                count = count + 1
                local isDone = false
                pcall(function() isDone = req.isDone end)
                if isDone or count >= 100 then
                    hasFinished = true
                    if timerObj and timerObj.Stop then pcall(function() timerObj:Stop() end) end
                    local payload = ""
                    local isSuccess = false
                    pcall(function()
                        if req.downloadHandler and req.downloadHandler.text then
                            payload = req.downloadHandler.text
                            if payload and payload ~= "" then
                                isSuccess = true
                            end
                        end
                        req:Dispose()
                    end)
                    if _G.WriteLog then
                        _G.WriteLog("[ActiveCheck] [BUOC 2] Response payload len = " ..
                            tostring(#payload) .. ", text = " .. tostring(payload))
                    end
                    if callback then callback(isSuccess, payload) end
                end
            end)
        else
            if callback then callback(false, "") end
        end
    end)
end

local lastCheckTime = 0
local isCheckingAPI = false
local function Mod_UpdatePeriodicCheck(isInitialLogin, onFinish)
    if type(isInitialLogin) == "function" then
        onFinish = isInitialLogin
        isInitialLogin = false
    end
    local now = os.time()
    if not isInitialLogin and not onFinish and (now - lastCheckTime < 60) then return end
    if isCheckingAPI then
        if onFinish then onFinish(false, _G.Mod_IsActive, _G.Mod_ActiveStatusMsg) end
        return
    end
    lastCheckTime = now
    isCheckingAPI = true

    Mod_FetchRemotePayloadFromAPI(isInitialLogin == true, function(isSuccess, remotePayload)
        isCheckingAPI = false
        _G.Mod_HasFetchedConfig = true

        if not isSuccess or not remotePayload or remotePayload == "" then
            _G.Mod_IsActive = false
            _G.Mod_ActiveStatusMsg = "Lỗi kết nối mạng / Không thể kết nối Server API!"
            if _G.WriteLog then _G.WriteLog("[ActiveCheck] LOI: KHONG THE KET NOI API SERVER!") end
            if _G.Mod_UpdateUI_ActiveState then _G.Mod_UpdateUI_ActiveState() end
            if _G.Mod_RefreshAuthPanelData then _G.Mod_RefreshAuthPanelData() end
            if onFinish then onFinish(false, false, _G.Mod_ActiveStatusMsg) end
            return
        end

        _G.Mod_RawConfigPayload = remotePayload
        local tokenStr = ""
        local apiObj = Mod_ParseJSON(remotePayload)
        if apiObj and apiObj.token then
            tokenStr = apiObj.token
            if _G.WriteLog then _G.WriteLog("[ActiveCheck] [BUOC 3] Extract Token Envelope tu JSON thanh cong!") end
        elseif apiObj and apiObj.error then
            _G.Mod_IsActive = false
            _G.Mod_ActiveStatusMsg = tostring(apiObj.error)
            if _G.WriteLog then _G.WriteLog("[ActiveCheck] LOI PHAN HOI TU SERVER: " .. tostring(apiObj.error)) end
            if _G.Mod_UpdateUI_ActiveState then _G.Mod_UpdateUI_ActiveState() end
            if _G.Mod_RefreshAuthPanelData then _G.Mod_RefreshAuthPanelData() end
            if onFinish then onFinish(true, false, _G.Mod_ActiveStatusMsg) end
            return
        else
            tokenStr = remotePayload
        end

        if _G.WriteLog then
            _G.WriteLog(
                "[ActiveCheck] [BUOC 4] Dang giai ma Base64 Envelope & Verifying MD5 Signature...")
        end
        local config, err = Mod_DecryptPayload(tokenStr)
        if config then
            if _G.WriteLog then _G.WriteLog("[ActiveCheck] [BUOC 5] Giai ma Token chu ky MD5 TRUNG KHOP 100%!") end
            local valid, reason = Mod_ValidateConfig(config)
            if valid then
                Mod_ApplyConfig(config)
            else
                _G.Mod_IsActive = false
                _G.Mod_ActiveStatusMsg = reason
                if _G.WriteLog then _G.WriteLog("[ActiveCheck] LOI VALIDATE CONFIG: " .. tostring(reason)) end
            end
        else
            _G.Mod_IsActive = false
            _G.Mod_ActiveStatusMsg = err or "Giải mã cấu hình từ Server thất bại"
            if _G.WriteLog then _G.WriteLog("[ActiveCheck] LOI GIAI MA ENVELOPE: " .. tostring(err)) end
        end
        if _G.Mod_UpdateUI_ActiveState then _G.Mod_UpdateUI_ActiveState() end
        if _G.Mod_RefreshAuthPanelData then _G.Mod_RefreshAuthPanelData() end
        if onFinish then onFinish(true, _G.Mod_IsActive, _G.Mod_ActiveStatusMsg) end
    end)
end

_G.Mod_UpdatePeriodicCheck = Mod_UpdatePeriodicCheck

_G.Mod_CheckActiveConfigNow = function(onFinish)
    lastCheckTime = 0
    isCheckingAPI = false
    _G.Mod_RawConfigPayload = ""
    Mod_UpdatePeriodicCheck(true, onFinish)
end

function EmmyluaDebug.InitEmmyluaDebug(obj)
    _G.Mod_IsDev = true
    _G.Mod_HasFetchedConfig = false
    _G.Mod_IsActive = false
    _G.Mod_ActiveConfig = nil

    _G.Mod_IsDebug = true
    _G.Mod_DebugMsg = function(msg)
        if _G.Mod_IsDebug then
            if _G.FloatingWordUtility then _G.FloatingWordUtility.QuickMsg(msg) end
            if _G.WriteLog then _G.WriteLog("[AutoFarm] " .. msg) end
        end
    end

    -- Xóa file update cũ và tạo thư mục giả để chặn game tải lại lua.mu2
    pcall(function()
        local Application = CS.UnityEngine.Application
        local Directory = CS.System.IO.Directory
        local File = CS.System.IO.File

        -- Xóa sạch rác
        local function DeleteDummyDir(path)
            if Directory.Exists(path) then Directory.Delete(path, true) end
            if File.Exists(path) then File.Delete(path) end
        end
        local rootDir = Application.persistentDataPath
        DeleteDummyDir(rootDir .. "/lua.mu2")
        DeleteDummyDir(rootDir .. "/bundles.txt")
        DeleteDummyDir(rootDir .. "/Bundles/lua.mu2")
        DeleteDummyDir(rootDir .. "/Bundles/bundles.txt")
        DeleteDummyDir(rootDir .. "/bundles/lua.mu2")
        DeleteDummyDir(rootDir .. "/bundles/bundles.txt")

        -- (Đã xóa Directory Blocker theo yêu cầu của user để không làm hỏng tiến trình tải Bundles.v158)
    end)
end

if _G.ModInitialized then return true end
_G.ModInitialized = true

_G.ModCallbacks = {}

local function WriteLog(msg)
    pcall(function()
        local logPath = CS.UnityEngine.Application.persistentDataPath .. "/MyModLog.txt"
        local finalMsg = tostring(msg)
        if string.find(finalMsg, "%[AutoLoot%]") then
            local timeStr = CS.System.DateTime.Now:ToString("yyyy-MM-dd HH:mm:ss.fff")
            finalMsg = timeStr .. ": " .. finalMsg
        end
        local f = io.open(logPath, "a")
        if f then
            f:write(finalMsg .. "\n")
            f:close()
        end
        CS.UnityEngine.Debug.LogError("[MySuperMod] " .. finalMsg)
    end)
end
_G.WriteLog = WriteLog

_G.Mod_BossStateMap = _G.Mod_BossStateMap or {}

if _G.EventManager and _G.EventManager.Regist and _G.Event and _G.Event.Map_BossAndElite then
    pcall(function()
        _G.EventManager.Regist(_G.Event.Map_BossAndElite, function(id, msg)
            if msg and msg.list then
                for _, item in ipairs(msg.list) do
                    if item and item.id then
                        _G.Mod_BossStateMap[item.id] = item.state
                    end
                end
            end
        end)
    end)
end

-- =========================================================================
-- [MOD FEATURE]: CẤU HÌNH SKILL MAP ẨN (MAP ẨN SKILL MEMORY & AUTO TOGGLE)
-- Mô tả: Ghi nhớ cấu hình skill tùy chọn cho Map Ẩn, tự động áp dụng khi vào Map Ẩn và rollback khi rời map.
-- =========================================================================
_G.Mod_SaveMapAnSkills = function()
    local saved = {}
    local onSkills = {}
    local offSkills = {}
    pcall(function()
        local skills = (_G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.skills) or
                       (_G.ViewData and _G.ViewData.meData and _G.ViewData.meData.skills)
        if skills and _G.ClientTable and _G.QiJiHelperData then
            for _, v in pairs(skills) do
                local skillData = _G.ClientTable.cfg_Skill_skillManager:TryGetValue(v.sid)
                if skillData and skillData.groupId and skillData.autoSkillType then
                    local aType = skillData.autoSkillType
                    local isBuff = (aType == (_G.AutoSkillEnum and _G.AutoSkillEnum.BuffSkill or 5))
                    local isGroup = (aType == (_G.AutoSkillEnum and _G.AutoSkillEnum.SelfSelGroupSkill or 9))
                    local isInd = (aType == (_G.AutoSkillEnum and _G.AutoSkillEnum.SelfSelIndSkill or 8))
                    local isCommon = (aType == (_G.AutoSkillEnum and _G.AutoSkillEnum.CommonSkill or 4))

                    if isBuff or isGroup or isInd or isCommon then
                        local isOpen = false
                        if isBuff then
                            local buffSkill = _G.QiJiHelperData.GetBuffSkill and _G.QiJiHelperData.GetBuffSkill(skillData.groupId)
                            isOpen = buffSkill and buffSkill.isOpen or false
                        else
                            local selSkill = _G.QiJiHelperData.GetSelfSelSkill and _G.QiJiHelperData.GetSelfSelSkill(skillData.groupId)
                            isOpen = selSkill and selSkill.isOpen or false
                        end

                        local sName = skillData.name or tostring(v.sid)
                        local isOnNum = isOpen and 1 or 0
                        local typeFlag = isBuff and "BUFF" or "SKILL"
                        table.insert(saved, tostring(v.sid) .. "=" .. tostring(isOnNum) .. ":" .. typeFlag)
                        if isOpen then
                            table.insert(onSkills, sName)
                        else
                            table.insert(offSkills, sName)
                        end
                    end
                end
            end
        end
    end)

    if #saved > 0 then
        local dataStr = table.concat(saved, ";")
        pcall(function()
            CS.UnityEngine.PlayerPrefs.SetString("Mod_MapAn_SavedSkills", dataStr)
            CS.UnityEngine.PlayerPrefs.Save()
        end)
        local msg = string.format("Đã nhớ %d Skill Map Ẩn (%d Bật, %d Tắt)", #saved, #onSkills, #offSkills)
        if _G.FloatingWordUtility then
            _G.FloatingWordUtility.QuickMsg(msg)
        end
        if LogMsg then LogMsg(string.format("[MAP ẨN] %s (Bật: %s | Tắt: %s)", msg, table.concat(onSkills, ", "), table.concat(offSkills, ", "))) end
        return true
    else
        if _G.FloatingWordUtility then
            _G.FloatingWordUtility.QuickMsg("Không tìm thấy dữ liệu Skill để lưu!")
        end
        return false
    end
end

_G.Mod_ApplyMapAnSkills = function()
    local dataStr = ""
    pcall(function()
        dataStr = CS.UnityEngine.PlayerPrefs.GetString("Mod_MapAn_SavedSkills", "")
    end)
    if not dataStr or dataStr == "" then
        return
    end

    if not _G.Mod_MapAn_OriginalSkillsSnapshot then
        _G.Mod_MapAn_OriginalSkillsSnapshot = {}
        pcall(function()
            local skills = (_G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.skills) or
                           (_G.ViewData and _G.ViewData.meData and _G.ViewData.meData.skills)
            if skills and _G.ClientTable and _G.QiJiHelperData then
                for _, v in pairs(skills) do
                    local skillData = _G.ClientTable.cfg_Skill_skillManager:TryGetValue(v.sid)
                    if skillData and skillData.groupId and skillData.autoSkillType then
                        local aType = skillData.autoSkillType
                        local isBuff = (aType == (_G.AutoSkillEnum and _G.AutoSkillEnum.BuffSkill or 5))
                        local isGroup = (aType == (_G.AutoSkillEnum and _G.AutoSkillEnum.SelfSelGroupSkill or 9))
                        local isInd = (aType == (_G.AutoSkillEnum and _G.AutoSkillEnum.SelfSelIndSkill or 8))
                        local isCommon = (aType == (_G.AutoSkillEnum and _G.AutoSkillEnum.CommonSkill or 4))

                        if isBuff or isGroup or isInd or isCommon then
                            local isOpen = false
                            if isBuff then
                                local buffSkill = _G.QiJiHelperData.GetBuffSkill and _G.QiJiHelperData.GetBuffSkill(skillData.groupId)
                                isOpen = buffSkill and buffSkill.isOpen or false
                            else
                                local selSkill = _G.QiJiHelperData.GetSelfSelSkill and _G.QiJiHelperData.GetSelfSelSkill(skillData.groupId)
                                isOpen = selSkill and selSkill.isOpen or false
                            end
                            _G.Mod_MapAn_OriginalSkillsSnapshot[v.sid] = {
                                isOpen = isOpen,
                                isBuff = isBuff
                            }
                        end
                    end
                end
            end
        end)
    end

    local toggledAny = false
    pcall(function()
        local pairsList = string.split(dataStr, ";")
        for _, pair in ipairs(pairsList) do
            if pair and pair ~= "" then
                local parts = string.split(pair, "=")
                if #parts == 2 then
                    local sId = tonumber(parts[1])
                    local subParts = string.split(parts[2], ":")
                    local isOn = (tonumber(subParts[1]) == 1)
                    local isBuff = (subParts[2] == "BUFF")

                    if subParts[2] == nil and _G.ClientTable then
                        local skillData = _G.ClientTable.cfg_Skill_skillManager:TryGetValue(sId)
                        if skillData and skillData.autoSkillType == (_G.AutoSkillEnum and _G.AutoSkillEnum.BuffSkill or 5) then
                            isBuff = true
                        end
                    end

                    if sId and _G.QiJiHelperController then
                        if isBuff and _G.QiJiHelperController.SetMeBuffSkill then
                            _G.QiJiHelperController.SetMeBuffSkill(sId, isOn)
                            toggledAny = true
                        elseif _G.QiJiHelperController.SetSelfSelSkill then
                            _G.QiJiHelperController.SetSelfSelSkill(sId, isOn)
                            toggledAny = true
                        end
                    end
                end
            end
        end
    end)

    if toggledAny then
        if _G.QiJiHelperController and _G.QiJiHelperController.Save then _G.QiJiHelperController.Save() end
        if _G.UIManager and _G.UIManager.GetUiByName then
            local ui = _G.UIManager.GetUiByName("Preference_QiJiHelperUI")
            if ui and ui.Refresh then ui:Refresh() end
        end
        if LogMsg then LogMsg("[MAP ẨN] Đã chuyển sang cấu hình Skill Map Ẩn đã lưu!") end
    end
end

_G.Mod_RestoreMapAnSkills = function()
    if not _G.Mod_MapAn_OriginalSkillsSnapshot then return end

    local toggledAny = false
    pcall(function()
        if _G.QiJiHelperController then
            for skillId, snapData in pairs(_G.Mod_MapAn_OriginalSkillsSnapshot) do
                local isOpen = snapData
                local isBuff = false
                if type(snapData) == "table" then
                    isOpen = snapData.isOpen
                    isBuff = snapData.isBuff
                else
                    if _G.ClientTable then
                        local skillData = _G.ClientTable.cfg_Skill_skillManager:TryGetValue(skillId)
                        if skillData and skillData.autoSkillType == (_G.AutoSkillEnum and _G.AutoSkillEnum.BuffSkill or 5) then
                            isBuff = true
                        end
                    end
                end

                if isBuff and _G.QiJiHelperController.SetMeBuffSkill then
                    _G.QiJiHelperController.SetMeBuffSkill(skillId, isOpen)
                    toggledAny = true
                elseif _G.QiJiHelperController.SetSelfSelSkill then
                    _G.QiJiHelperController.SetSelfSelSkill(skillId, isOpen)
                    toggledAny = true
                end
            end
        end
    end)

    _G.Mod_MapAn_OriginalSkillsSnapshot = nil

    if toggledAny then
        if _G.QiJiHelperController and _G.QiJiHelperController.Save then _G.QiJiHelperController.Save() end
        if _G.UIManager and _G.UIManager.GetUiByName then
            local ui = _G.UIManager.GetUiByName("Preference_QiJiHelperUI")
            if ui and ui.Refresh then ui:Refresh() end
        end
        if LogMsg then LogMsg("[MAP ẨN] Đã khôi phục cấu hình Skill ban đầu!") end
    end
end

if _G.PathFinderManager and not _G.Mod_Hooked_JumpMapToMoveToPos then
    _G.Mod_Hooked_JumpMapToMoveToPos = true
    local old_JumpMapToMoveToPos = _G.PathFinderManager.JumpMapToMoveToPos
    _G.PathFinderManager.JumpMapToMoveToPos = function(groupId, pos, transferId, line, param, purpose, OnArrive, range, isStopTask)
        pcall(function()
            if _G.PathFinderManager and _G.PathFinderManager.ResetData then
                _G.PathFinderManager.ResetData()
            end
        end)
        return old_JumpMapToMoveToPos(groupId, pos, transferId, line, param, purpose, OnArrive, range, isStopTask)
    end
end

_G.GetAllBossPositions = function(bossId, mapId)
    if not bossId then return {} end
    local positions = {}
    local addedMap = {}
    local function AddPos(px, py)
        if px and py then
            local key = math.floor(px) .. "_" .. math.floor(py)
            if not addedMap[key] then
                addedMap[key] = true
                table.insert(positions, { x = px, y = py })
            end
        end
    end

    pcall(function()
        if _G.SceneData and _G.SceneData.bossPosDataList then
            for _, v in pairs(_G.SceneData.bossPosDataList) do
                if (v.Param == bossId or tonumber(v.Param) == tonumber(bossId)) and v.position then
                    local parts = string.split(v.position, "#")
                    if #parts >= 2 then
                        AddPos(tonumber(parts[1]), tonumber(parts[2]))
                    end
                end
            end
        end
        if #positions == 0 and _G.ConfigManager and _G.ConfigManager.FindConfigs and mapId then
            local list = _G.ConfigManager.FindConfigs("cfg_Map_minimap", "mid", mapId)
            if list then
                for _, v in pairs(list) do
                    if (v.Param == bossId or tonumber(v.Param) == tonumber(bossId)) and v.position then
                        local parts = string.split(v.position, "#")
                        if #parts >= 2 then
                            AddPos(tonumber(parts[1]), tonumber(parts[2]))
                        end
                    end
                end
            end
        end
        if #positions == 0 and _G.ClientTable and _G.ClientTable.cfg_Monster_bossManager then
            local cfg = _G.ClientTable.cfg_Monster_bossManager:TryGetValue(bossId)
            if cfg and cfg.position then
                local posGroups = string.split(cfg.position, "|")
                for _, g in ipairs(posGroups) do
                    local cleanPos = string.gsub(g, "&", "")
                    local parts = string.split(cleanPos, "#")
                    if #parts >= 2 then
                        AddPos(math.abs(tonumber(parts[1]) or 0), math.abs(tonumber(parts[2]) or 0))
                    end
                end
            end
        end
    end)
    return positions
end

_G.GetAliveBossPosition = function(bossId, mapId)
    if not bossId then return nil, 0, 0 end
    local candidatePositions = {}
    local alivePositions = {}

    pcall(function()
        if _G.SceneData and _G.SceneData.bossPosDataList then
            for _, v in pairs(_G.SceneData.bossPosDataList) do
                if (v.Param == bossId or tonumber(v.Param) == tonumber(bossId)) and v.position then
                    local parts = string.split(v.position, "#")
                    if #parts >= 2 then
                        local px, py = tonumber(parts[1]), tonumber(parts[2])
                        if px and py then
                            local posObj = { x = px, y = py, id = v.id }
                            table.insert(candidatePositions, posObj)
                            local st = _G.Mod_BossStateMap[v.id]
                            if st == 1 then
                                table.insert(alivePositions, posObj)
                            end
                        end
                    end
                end
            end
        end
    end)

    if #alivePositions > 0 then
        if #alivePositions > 1 then
            local meX, meY = nil, nil
            if _G.RoleManager and _G.RoleManager.me then
                local me = _G.RoleManager.me
                if me.cellPos then
                    meX, meY = me.cellPos.x, me.cellPos.y
                elseif me.serverCoord then
                    meX, meY = me.serverCoord.x, me.serverCoord.y
                elseif me.GetPosition then
                    local p = me:GetPosition()
                    if p then meX, meY = math.floor(p.x), math.floor(p.z) end
                elseif me.position then
                    meX, meY = math.floor(me.position.x), math.floor(me.position.z or me.position.y)
                end
            end
            if meX and meY then
                table.sort(alivePositions, function(a, b)
                    local dA = (a.x - meX) * (a.x - meX) + (a.y - meY) * (a.y - meY)
                    local dB = (b.x - meX) * (b.x - meX) + (b.y - meY) * (b.y - meY)
                    return dA < dB
                end)
            end
        end
        return alivePositions[1], #alivePositions, #candidatePositions
    end

    if #candidatePositions > 0 then
        return nil, 0, #candidatePositions
    end

    local all = _G.GetAllBossPositions(bossId, mapId)
    if all and #all > 0 then
        return all[1], 1, 1
    end

    return nil, 0, 0
end

_G.GetBossPosition = function(bossId, mapId)
    local all = _G.GetAllBossPositions(bossId, mapId)
    if all and #all > 0 then
        return all[1]
    end
    return nil
end

-- WriteLog("--- BẮT ĐẦU KHỞI TẠO HOOK MOD MENU ---")

local function CreateModUI()
    local status, err = pcall(function()
        -- =========================================================================
        -- [MOD FEATURE]: HỆ THỐNG LỆNH BÍ MẬT (SECRET COMMAND ENGINE - CUSTOMER)
        -- Mô tả: Quản lý các mã lệnh kích hoạt tính năng ẩn (/pkmodeguild)
        -- =========================================================================
        if _G.Mod_SecretCommands == nil then
            pcall(function()
                _G.Mod_SecretCommands = CS.UnityEngine.PlayerPrefs.GetString("Mod_SecretCommands", "")
            end)
            if _G.Mod_SecretCommands == nil then _G.Mod_SecretCommands = "" end
        end

        _G.Mod_ParseSecretCommands = function(cmdStr)
            local tbl = {}
            if cmdStr and cmdStr ~= "" then
                for cmd in string.gmatch(cmdStr, "%S+") do
                    tbl[string.lower(cmd)] = true
                end
            end
            _G.Mod_ActiveCommands = tbl
        end

        _G.Mod_HasSecretCommand = function(cmd)
            if not _G.Mod_ActiveCommands then return false end
            return _G.Mod_ActiveCommands[string.lower(cmd)] == true
        end

        _G.Mod_ParseSecretCommands(_G.Mod_SecretCommands)

        if _G.Mod_AutoPK_Enabled == nil then
            _G.Mod_AutoPK_Enabled = CS.UnityEngine.PlayerPrefs.GetInt(
                "Mod_AutoPK_Enabled", 0) == 1
        end
        if _G.Mod_AutoGuildPK_Enabled == nil then
            _G.Mod_AutoGuildPK_Enabled = CS.UnityEngine.PlayerPrefs.GetInt(
                "Mod_AutoGuildPK_Enabled", 0) == 1
        end
        if _G.Mod_ShowKundunHP == nil then
            pcall(function() _G.Mod_ShowKundunHP = CS.UnityEngine.PlayerPrefs.GetInt("Mod_ShowKundunHP", 0) == 1 end)
        end

        _G.Mod_SaveFarmStats = _G.Mod_SaveFarmStats or function()
            if not _G.Mod_FarmStats then return end
            local str = "hidden:" .. tostring(_G.Mod_FarmStats.hidden or 0)
            if _G.Mod_FarmStats.bosses then
                for k, v in pairs(_G.Mod_FarmStats.bosses) do
                    str = str .. ";" .. tostring(k) .. ":" .. tostring(v)
                end
            end
            CS.UnityEngine.PlayerPrefs.SetString("Mod_FarmStatsData", str)
            CS.UnityEngine.PlayerPrefs.Save()
        end

        if not _G.Mod_FarmStats_Loaded then
            _G.Mod_FarmStats = { hidden = 0, bosses = {} }
            local str = CS.UnityEngine.PlayerPrefs.GetString("Mod_FarmStatsData", "")
            if str ~= "" then
                for p in string.gmatch(str, "([^;]+)") do
                    local kStr, vStr = string.match(p, "([^:]+):(%d+)")
                    if kStr and vStr then
                        if kStr == "hidden" then
                            _G.Mod_FarmStats.hidden = tonumber(vStr) or 0
                        else
                            local bossId = tonumber(kStr)
                            if bossId then _G.Mod_FarmStats.bosses[bossId] = tonumber(vStr) end
                        end
                    end
                end
            end
            _G.Mod_FarmStats_Loaded = true
        end

        local GameObject = CS.UnityEngine.GameObject
        local RectTransform = CS.UnityEngine.RectTransform
        local Canvas = CS.UnityEngine.Canvas
        local CanvasScaler = CS.UnityEngine.UI.CanvasScaler
        local GraphicRaycaster = CS.UnityEngine.UI.GraphicRaycaster
        local Vector2 = CS.UnityEngine.Vector2
        local Color = CS.UnityEngine.Color
        local Image = CS.UnityEngine.UI.Image
        local Text = CS.UnityEngine.UI.Text
        local Button = CS.UnityEngine.UI.Button
        local InputField = CS.UnityEngine.UI.InputField
        local Toggle = CS.UnityEngine.UI.Toggle
        local Slider = CS.UnityEngine.UI.Slider
        local Font = CS.UnityEngine.Font
        local Resources = CS.UnityEngine.Resources
        local TextAnchor = CS.UnityEngine.TextAnchor
        local RenderMode = CS.UnityEngine.RenderMode

        local defaultFont = Resources.GetBuiltinResource(typeof(Font), "Arial.ttf")

        local modRoot = GameObject("MySuperModCanvas")
        CS.UnityEngine.Object.DontDestroyOnLoad(modRoot)

        local canvas = modRoot:AddComponent(typeof(Canvas))
        canvas.renderMode = RenderMode.ScreenSpaceOverlay
        canvas.sortingOrder = 9999

        local scaler = modRoot:AddComponent(typeof(CanvasScaler))
        scaler.uiScaleMode = CS.UnityEngine.UI.CanvasScaler.ScaleMode.ScaleWithScreenSize
        scaler.referenceResolution = Vector2(1920, 1080)

        modRoot:AddComponent(typeof(GraphicRaycaster))

        local btnGo = GameObject("FloatingModBtn")
        _G.FloatingModBtnGo = btnGo
        btnGo.transform:SetParent(modRoot.transform, false)
        local rt = btnGo:AddComponent(typeof(RectTransform))
        rt.anchorMin = Vector2(0, 0)
        rt.anchorMax = Vector2(0, 0)
        rt.pivot = Vector2(0, 0)
        rt.anchoredPosition = Vector2(20, 280)
        rt.sizeDelta = Vector2(60, 60)

        local img = btnGo:AddComponent(typeof(Image))
        img.color = Color(0.215, 0.490, 0.133, 1.0)
        local btnComp = btnGo:AddComponent(typeof(Button))

        local txtGo = GameObject("ModText")
        txtGo.transform:SetParent(btnGo.transform, false)
        local txtRt = txtGo:AddComponent(typeof(RectTransform))
        txtRt.anchorMin = Vector2(0, 0)
        txtRt.anchorMax = Vector2(1, 1)
        txtRt.sizeDelta = Vector2(0, 0)
        local txt = txtGo:AddComponent(typeof(Text))
        txt.text = "VỤT"
        txt.color = Color.white
        txt.fontSize = 20
        txt.alignment = TextAnchor.MiddleCenter
        txt.raycastTarget = false
        if defaultFont then txt.font = defaultFont end

        local pkBtnGo = GameObject("FloatingPKBtn")
        _G.FloatingPKBtnGo = pkBtnGo
        pkBtnGo.transform:SetParent(modRoot.transform, false)
        local pkRt = pkBtnGo:AddComponent(typeof(RectTransform))
        pkRt.anchorMin = Vector2(0, 0)
        pkRt.anchorMax = Vector2(0, 0)
        pkRt.pivot = Vector2(0, 0)
        pkRt.anchoredPosition = Vector2(20, 370)
        pkRt.sizeDelta = Vector2(60, 60)

        local pkImg = pkBtnGo:AddComponent(typeof(Image))
        pkImg.color = _G.Mod_AutoPK_Enabled and Color(0.215, 0.490, 0.133, 1.0) or Color(0.6, 0.2, 0.2, 1)

        local pkTxtGo = GameObject("PKText")
        pkTxtGo.transform:SetParent(pkBtnGo.transform, false)
        local pkTxtRt = pkTxtGo:AddComponent(typeof(RectTransform))
        pkTxtRt.anchorMin = Vector2(0, 0)
        pkTxtRt.anchorMax = Vector2(1, 1)
        pkTxtRt.sizeDelta = Vector2(0, 0)
        local pkTxt = pkTxtGo:AddComponent(typeof(Text))
        pkTxt.text = _G.Mod_AutoPK_Enabled and "PK ON" or "PK OFF"
        pkTxt.color = Color.white
        pkTxt.fontSize = 18
        pkTxt.alignment = TextAnchor.MiddleCenter
        pkTxt.raycastTarget = false
        if defaultFont then pkTxt.font = defaultFont end

        pkBtnGo:SetActive(_G.Mod_IsActive == true)

        _G.ModUpdateFloatingPKBtn = function()
            if pkTxt and pkImg then
                pkTxt.text = _G.Mod_AutoPK_Enabled and "PK ON" or "PK OFF"
                pkImg.color = _G.Mod_AutoPK_Enabled and Color(0.215, 0.490, 0.133, 1.0) or Color(0.6, 0.2, 0.2, 1)
            end
        end

        local pkBtnComp = pkBtnGo:AddComponent(typeof(Button))
        pkBtnComp.onClick:AddListener(function()
            if not _G.Mod_IsActive then return end
            _G.Mod_AutoPK_Enabled = not _G.Mod_AutoPK_Enabled
            CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoPK_Enabled", _G.Mod_AutoPK_Enabled and 1 or 0)
            CS.UnityEngine.PlayerPrefs.Save()
            if _G.ModUpdateFloatingPKBtn then _G.ModUpdateFloatingPKBtn() end
            if not _G.Mod_AutoPK_Enabled then
                pcall(function()
                    if _G.RoleManager and _G.RoleManager.me then
                        _G.RoleManager.me:SetAutoFight("None")
                    end
                end)
            end
        end)

        ---------------------------------------------------------
        -- Floating Admin EXEC Button (Below VỤT button, Dev Mode Only)
        ---------------------------------------------------------
        if _G.Mod_IsDev == true then
            local adminBtnGo = GameObject("FloatingAdminBtn")
            _G.FloatingAdminBtnGo = adminBtnGo
            adminBtnGo.transform:SetParent(modRoot.transform, false)
            local adminRt = adminBtnGo:AddComponent(typeof(RectTransform))
            adminRt.anchorMin = Vector2(0, 0)
            adminRt.anchorMax = Vector2(0, 0)
            adminRt.pivot = Vector2(0, 0)
            adminRt.anchoredPosition = Vector2(20, 190)
            adminRt.sizeDelta = Vector2(60, 60)

            local adminImg = adminBtnGo:AddComponent(typeof(Image))
            adminImg.color = Color(0.85, 0.45, 0.0, 1.0)

            local adminTxtGo = GameObject("AdminText")
            adminTxtGo.transform:SetParent(adminBtnGo.transform, false)
            local adminTxtRt = adminTxtGo:AddComponent(typeof(RectTransform))
            adminTxtRt.anchorMin = Vector2(0, 0)
            adminTxtRt.anchorMax = Vector2(1, 1)
            adminTxtRt.sizeDelta = Vector2(0, 0)
            local adminTxt = adminTxtGo:AddComponent(typeof(Text))
            adminTxt.text = "EXEC"
            adminTxt.color = Color.white
            adminTxt.fontSize = 16
            adminTxt.alignment = TextAnchor.MiddleCenter
            adminTxt.raycastTarget = false
            if defaultFont then adminTxt.font = defaultFont end

            adminBtnGo:SetActive(_G.Mod_IsDev == true)

            local adminBtnComp = adminBtnGo:AddComponent(typeof(Button))
            adminBtnComp.onClick:AddListener(function()
                pcall(function()
                    local path = CS.UnityEngine.Application.persistentDataPath .. "/input.luac"
                    if not CS.System.IO.File.Exists(path) then
                        path = "/storage/emulated/0/Android/data/com.mr2omen.and/files/input.luac"
                    end
                    if CS.System.IO.File.Exists(path) then
                        local bytes = CS.System.IO.File.ReadAllBytes(path)
                        local func, err = load(bytes)
                        if func then
                            local ok, res = pcall(func)
                            if ok then
                                if _G.FloatingWordUtility then
                                    _G.FloatingWordUtility.QuickMsg(
                                        "Thực thi input.luac thành công!")
                                end
                            else
                                if _G.FloatingWordUtility then
                                    _G.FloatingWordUtility.QuickMsg("Lỗi script: " ..
                                        tostring(res))
                                end
                            end
                        else
                            if _G.FloatingWordUtility then
                                _G.FloatingWordUtility.QuickMsg("Lỗi load bytecode: " ..
                                    tostring(err))
                            end
                        end
                    else
                        if _G.FloatingWordUtility then _G.FloatingWordUtility.QuickMsg("Chưa tìm thấy file input.luac!") end
                    end
                end)
            end)
        end

        local panelGo = GameObject("ModMenuPanel")
        panelGo.transform:SetParent(modRoot.transform, false)
        local panelRt = panelGo:AddComponent(typeof(RectTransform))
        panelRt.anchorMin = Vector2(0, 0)
        panelRt.anchorMax = Vector2(0, 0)
        panelRt.pivot = Vector2(0, 0)
        panelRt.anchoredPosition = Vector2(90, 50)
        panelRt.sizeDelta = Vector2(720, 580)

        if _G.Mod_MenuScale == nil then
            pcall(function()
                _G.Mod_MenuScale = CS.UnityEngine.PlayerPrefs.GetFloat("Mod_MenuScale", 1.0)
            end)
            if not _G.Mod_MenuScale or _G.Mod_MenuScale < 0.5 then _G.Mod_MenuScale = 1.0 end
        end
        panelGo.transform.localScale = CS.UnityEngine.Vector3(_G.Mod_MenuScale, _G.Mod_MenuScale, 1)

        local panelImg = panelGo:AddComponent(typeof(Image))
        panelImg.color = Color(0, 0, 0, 0.8)
        panelGo:SetActive(false)
        _G.ModMenuPanelGo = panelGo

        ---------------------------------------------------------
        -- Standalone AuthPanel UI (Active Notice Screen)
        ---------------------------------------------------------
        local authPanelGo = GameObject("AuthPanel")
        authPanelGo.transform:SetParent(modRoot.transform, false)
        local authRt = authPanelGo:AddComponent(typeof(RectTransform))
        authRt.anchorMin = Vector2(0, 0)
        authRt.anchorMax = Vector2(0, 0)
        authRt.pivot = Vector2(0, 0)
        authRt.anchoredPosition = Vector2(90, 70)
        authRt.sizeDelta = Vector2(650, 480)
        local authImg = authPanelGo:AddComponent(typeof(Image))
        authImg.color = Color(0.1, 0.1, 0.12, 0.95)
        authPanelGo:SetActive(false)
        _G.authPanelGo = authPanelGo

        local activeNoticeTxt = nil
        local activeSerialTxt = nil
        local activeUidTxt = nil
        local activeTgContainerGo = nil

        -- 1. Title Header
        local actTitleGo = GameObject("ActivePanelTitle")
        actTitleGo.transform:SetParent(authPanelGo.transform, false)
        local atRt = actTitleGo:AddComponent(typeof(RectTransform))
        atRt.anchorMin = Vector2(0, 1)
        atRt.anchorMax = Vector2(1, 1)
        atRt.pivot = Vector2(0.5, 1)
        atRt.anchoredPosition = Vector2(0, -15)
        atRt.sizeDelta = Vector2(0, 40)
        local atTxt = actTitleGo:AddComponent(typeof(Text))
        atTxt.text = "KÍCH HOẠT SỬ DỤNG"
        atTxt.font = defaultFont
        atTxt.fontSize = 24
        atTxt.color = Color(1.0, 0.84, 0.0, 1.0)
        atTxt.alignment = TextAnchor.MiddleCenter

        -- 2. Status Banner Text
        local actNoticeGo = GameObject("ActiveNoticeBanner")
        actNoticeGo.transform:SetParent(authPanelGo.transform, false)
        local anRt = actNoticeGo:AddComponent(typeof(RectTransform))
        anRt.anchorMin = Vector2(0, 1)
        anRt.anchorMax = Vector2(1, 1)
        anRt.pivot = Vector2(0.5, 1)
        anRt.anchoredPosition = Vector2(0, -55)
        anRt.sizeDelta = Vector2(-40, 45)
        activeNoticeTxt = actNoticeGo:AddComponent(typeof(Text))
        activeNoticeTxt.text = _G.Mod_ActiveStatusMsg or "Bản Mod chưa được kích hoạt!"
        activeNoticeTxt.font = defaultFont
        activeNoticeTxt.fontSize = 16
        activeNoticeTxt.color = Color(1.0, 0.35, 0.35, 1.0)
        activeNoticeTxt.alignment = TextAnchor.MiddleCenter

        -- 3. Serial MD5 Box
        local sLabelGo = GameObject("ActiveSerialLabel")
        sLabelGo.transform:SetParent(authPanelGo.transform, false)
        local slRt = sLabelGo:AddComponent(typeof(RectTransform))
        slRt.anchorMin = Vector2(0, 1)
        slRt.anchorMax = Vector2(1, 1)
        slRt.pivot = Vector2(0, 1)
        slRt.anchoredPosition = Vector2(30, -105)
        slRt.sizeDelta = Vector2(590, 25)
        local slTxt = sLabelGo:AddComponent(typeof(Text))
        slTxt.text = "1. Mã thiết bị:"
        slTxt.font = defaultFont
        slTxt.fontSize = 15
        slTxt.color = Color.cyan

        local sBoxGo = GameObject("ActiveSerialBox")
        sBoxGo.transform:SetParent(authPanelGo.transform, false)
        local sbRt = sBoxGo:AddComponent(typeof(RectTransform))
        sbRt.anchorMin = Vector2(0, 1)
        sbRt.anchorMax = Vector2(0, 1)
        sbRt.pivot = Vector2(0, 1)
        sbRt.anchoredPosition = Vector2(30, -135)
        sbRt.sizeDelta = Vector2(460, 40)
        local sbImg = sBoxGo:AddComponent(typeof(Image))
        sbImg.color = Color(0.18, 0.20, 0.25, 1)

        local sTxtGo = GameObject("Txt")
        sTxtGo.transform:SetParent(sBoxGo.transform, false)
        local stRt = sTxtGo:AddComponent(typeof(RectTransform))
        stRt.anchorMin = Vector2(0, 0)
        stRt.anchorMax = Vector2(1, 1)
        stRt.sizeDelta = Vector2(-20, 0)
        stRt.anchoredPosition = Vector2(10, 0)
        activeSerialTxt = sTxtGo:AddComponent(typeof(Text))
        activeSerialTxt.font = defaultFont
        activeSerialTxt.fontSize = 15
        activeSerialTxt.color = Color.white
        activeSerialTxt.alignment = TextAnchor.MiddleLeft

        local sCopyGo = GameObject("ActiveSerialCopyBtn")
        sCopyGo.transform:SetParent(authPanelGo.transform, false)
        local scRt = sCopyGo:AddComponent(typeof(RectTransform))
        scRt.anchorMin = Vector2(0, 1)
        scRt.anchorMax = Vector2(0, 1)
        scRt.pivot = Vector2(0, 1)
        scRt.anchoredPosition = Vector2(500, -135)
        scRt.sizeDelta = Vector2(120, 40)
        local scImg = sCopyGo:AddComponent(typeof(Image))
        scImg.color = Color(0.2, 0.5, 0.8, 1)
        local scTxtG = GameObject("Txt")
        scTxtG.transform:SetParent(sCopyGo.transform, false)
        local sctRt = scTxtG:AddComponent(typeof(RectTransform))
        sctRt.anchorMin = Vector2(0, 0)
        sctRt.anchorMax = Vector2(1, 1)
        sctRt.sizeDelta = Vector2(0, 0)
        local sctTxt = scTxtG:AddComponent(typeof(Text))
        sctTxt.text = "Copy Mã"
        sctTxt.font = defaultFont
        sctTxt.fontSize = 15
        sctTxt.color = Color.white
        sctTxt.alignment = TextAnchor.MiddleCenter
        local scBtn = sCopyGo:AddComponent(typeof(Button))
        scBtn.onClick:AddListener(function()
            local val = Mod_GetDeviceSerialMD5()
            if activeSerialTxt and not activeSerialTxt:Equals(nil) then activeSerialTxt.text = val end
            if val ~= "" then
                pcall(function() CS.UnityEngine.GUIUtility.systemCopyBuffer = val end)
                if _G.FloatingWordUtility then _G.FloatingWordUtility.QuickMsg("Đã chép Mã thiết bị!") end
            end
        end)

        -- 4. UID Box
        local uLabelGo = GameObject("ActiveUIDLabel")
        uLabelGo.transform:SetParent(authPanelGo.transform, false)
        local ulRt = uLabelGo:AddComponent(typeof(RectTransform))
        ulRt.anchorMin = Vector2(0, 1)
        ulRt.anchorMax = Vector2(1, 1)
        ulRt.pivot = Vector2(0, 1)
        ulRt.anchoredPosition = Vector2(30, -185)
        ulRt.sizeDelta = Vector2(590, 25)
        local ulTxt = uLabelGo:AddComponent(typeof(Text))
        ulTxt.text = "2. Mã nhân vật:"
        ulTxt.font = defaultFont
        ulTxt.fontSize = 15
        ulTxt.color = Color.cyan

        local uBoxGo = GameObject("ActiveUIDBox")
        uBoxGo.transform:SetParent(authPanelGo.transform, false)
        local ubRt = uBoxGo:AddComponent(typeof(RectTransform))
        ubRt.anchorMin = Vector2(0, 1)
        ubRt.anchorMax = Vector2(0, 1)
        ubRt.pivot = Vector2(0, 1)
        ubRt.anchoredPosition = Vector2(30, -215)
        ubRt.sizeDelta = Vector2(460, 40)
        local ubImg = uBoxGo:AddComponent(typeof(Image))
        ubImg.color = Color(0.18, 0.20, 0.25, 1)

        local uTxtGo = GameObject("Txt")
        uTxtGo.transform:SetParent(uBoxGo.transform, false)
        local utRt = uTxtGo:AddComponent(typeof(RectTransform))
        utRt.anchorMin = Vector2(0, 0)
        utRt.anchorMax = Vector2(1, 1)
        utRt.sizeDelta = Vector2(-20, 0)
        utRt.anchoredPosition = Vector2(10, 0)
        activeUidTxt = uTxtGo:AddComponent(typeof(Text))
        activeUidTxt.font = defaultFont
        activeUidTxt.fontSize = 14
        activeUidTxt.color = Color.white
        activeUidTxt.alignment = TextAnchor.MiddleLeft

        local uCopyGo = GameObject("ActiveUIDCopyBtn")
        uCopyGo.transform:SetParent(authPanelGo.transform, false)
        local ucRt = uCopyGo:AddComponent(typeof(RectTransform))
        ucRt.anchorMin = Vector2(0, 1)
        ucRt.anchorMax = Vector2(0, 1)
        ucRt.pivot = Vector2(0, 1)
        ucRt.anchoredPosition = Vector2(500, -215)
        ucRt.sizeDelta = Vector2(120, 40)
        local ucImg = uCopyGo:AddComponent(typeof(Image))
        ucImg.color = Color(0.2, 0.5, 0.8, 1)
        local ucTxtG = GameObject("Txt")
        ucTxtG.transform:SetParent(uCopyGo.transform, false)
        local uctRt = ucTxtG:AddComponent(typeof(RectTransform))
        uctRt.anchorMin = Vector2(0, 0)
        uctRt.anchorMax = Vector2(1, 1)
        uctRt.sizeDelta = Vector2(0, 0)
        local uctTxt = ucTxtG:AddComponent(typeof(Text))
        uctTxt.text = "Copy UID"
        uctTxt.font = defaultFont
        uctTxt.fontSize = 15
        uctTxt.color = Color.white
        uctTxt.alignment = TextAnchor.MiddleCenter
        local ucBtn = uCopyGo:AddComponent(typeof(Button))
        ucBtn.onClick:AddListener(function()
            local val = Mod_GetCharacterUID()
            if activeUidTxt and not activeUidTxt:Equals(nil) then
                if val ~= "" then
                    activeUidTxt.text = val
                    activeUidTxt.color = Color.white
                else
                    activeUidTxt.text = "Vui lòng đăng nhập nhân vật để lấy UID"
                    activeUidTxt.color = Color(1.0, 0.7, 0.3, 1.0)
                end
            end
            if val ~= "" and not string.find(val, "Vui lòng") then
                pcall(function() CS.UnityEngine.GUIUtility.systemCopyBuffer = val end)
                if _G.FloatingWordUtility then _G.FloatingWordUtility.QuickMsg("Đã chép Character UID!") end
            else
                if _G.FloatingWordUtility then _G.FloatingWordUtility.QuickMsg("Chưa đăng nhập nhân vật để lấy UID!") end
            end
        end)

        -- 5. Telegram Admin Container
        activeTgContainerGo = GameObject("ActiveTgContainer")
        activeTgContainerGo.transform:SetParent(authPanelGo.transform, false)
        local tgRt = activeTgContainerGo:AddComponent(typeof(RectTransform))
        tgRt.anchorMin = Vector2(0, 1)
        tgRt.anchorMax = Vector2(1, 1)
        tgRt.pivot = Vector2(0.5, 1)
        tgRt.anchoredPosition = Vector2(0, -265)
        tgRt.sizeDelta = Vector2(-60, 90)

        -- 6. Reload / Re-check Button
        local reloadGo = GameObject("ActiveReloadBtn")
        reloadGo.transform:SetParent(authPanelGo.transform, false)
        local rRt = reloadGo:AddComponent(typeof(RectTransform))
        rRt.anchorMin = Vector2(0.5, 0)
        rRt.anchorMax = Vector2(0.5, 0)
        rRt.pivot = Vector2(0.5, 0)
        rRt.anchoredPosition = Vector2(0, 25)
        rRt.sizeDelta = Vector2(300, 45)
        local rImg = reloadGo:AddComponent(typeof(Image))
        rImg.color = Color(0.18, 0.65, 0.32, 1)
        local rTxtG = GameObject("Txt")
        rTxtG.transform:SetParent(reloadGo.transform, false)
        local rtRt = rTxtG:AddComponent(typeof(RectTransform))
        rtRt.anchorMin = Vector2(0, 0)
        rtRt.anchorMax = Vector2(1, 1)
        rtRt.sizeDelta = Vector2(0, 0)
        local rtTxt = rTxtG:AddComponent(typeof(Text))
        rtTxt.text = "KÍCH HOẠT"
        rtTxt.font = defaultFont
        rtTxt.fontSize = 17
        rtTxt.color = Color.white
        rtTxt.alignment = TextAnchor.MiddleCenter
        local rBtn = reloadGo:AddComponent(typeof(Button))

        -- =========================================================================
        -- [MOD FEATURE]: LÀM MỚI DỮ LIỆU BẢNG KÍCH HOẠT CUSTOMER (REFRESH AUTH DATA)
        -- Mô tả: Cập nhật động mã MD5 thiết bị và UID nhân vật mỗi khi mở hoặc làm mới màn hình Active
        -- =========================================================================
        local function RefreshAuthPanelData()
            local serialMD5 = Mod_GetDeviceSerialMD5()
            local uid = Mod_GetCharacterUID()
            if activeSerialTxt and not activeSerialTxt:Equals(nil) then activeSerialTxt.text = serialMD5 end
            if activeUidTxt and not activeUidTxt:Equals(nil) then
                if uid ~= "" then
                    activeUidTxt.text = uid
                    activeUidTxt.color = Color.white
                else
                    activeUidTxt.text = "Vui lòng đăng nhập nhân vật để lấy UID"
                    activeUidTxt.color = Color(1.0, 0.7, 0.3, 1.0)
                end
            end
            if activeNoticeTxt and not activeNoticeTxt:Equals(nil) then
                activeNoticeTxt.text = _G.Mod_ActiveStatusMsg or "Chưa được kích hoạt bản quyền!"
            end

            -- =========================================================================
            -- [MOD FEATURE]: CỤM NÚT LIÊN HỆ KÍCH HOẠT (ZALO & TELEGRAM)
            -- Mô tả: Hiển thị 2 nút liên hệ Zalo (0386918686) và Telegram (@vutmod)
            --        giúp khách dễ dàng bấm để xin kích hoạt bản quyền
            -- =========================================================================
            if activeTgContainerGo and not activeTgContainerGo:Equals(nil) then
                for i = activeTgContainerGo.transform.childCount - 1, 0, -1 do
                    local child = activeTgContainerGo.transform:GetChild(i)
                    CS.UnityEngine.Object.Destroy(child.gameObject)
                end

                local btnWidth = 280
                local btnHeight = 40
                local gap = 20

                -- 1. NÚT LIÊN HỆ ZALO (MÀU XANH DƯƠNG ZALO)
                local zaloGo = GameObject("ZaloBtn")
                zaloGo.transform:SetParent(activeTgContainerGo.transform, false)
                local zRt = zaloGo:AddComponent(typeof(RectTransform))
                zRt.anchorMin = Vector2(0.5, 0.5)
                zRt.anchorMax = Vector2(0.5, 0.5)
                zRt.pivot = Vector2(0.5, 0.5)
                zRt.anchoredPosition = Vector2(-(btnWidth / 2 + gap / 2), 0)
                zRt.sizeDelta = Vector2(btnWidth, btnHeight)

                local zImg = zaloGo:AddComponent(typeof(Image))
                zImg.color = Color(0.05, 0.45, 0.90, 1)

                local zTxtG = GameObject("Txt")
                zTxtG.transform:SetParent(zaloGo.transform, false)
                local ztRt = zTxtG:AddComponent(typeof(RectTransform))
                ztRt.anchorMin = Vector2(0, 0)
                ztRt.anchorMax = Vector2(1, 1)
                ztRt.sizeDelta = Vector2(0, 0)
                local zTxt = zTxtG:AddComponent(typeof(Text))
                local zaloPhone = _G.Mod_Config_AdminZaloPhone or "0386918686"
                zTxt.text = "Zalo: " .. zaloPhone
                zTxt.font = defaultFont
                zTxt.fontSize = 15
                zTxt.color = Color.white
                zTxt.alignment = TextAnchor.MiddleCenter

                local zBtn = zaloGo:AddComponent(typeof(Button))
                zBtn.onClick:AddListener(function()
                    local zaloUrl = _G.Mod_Config_AdminZalo or "https://zalo.me/0386918686"
                    pcall(function() CS.UnityEngine.Application.OpenURL(zaloUrl) end)
                end)

                -- 2. NÚT LIÊN HỆ TELEGRAM (MÀU XANH CYAN TELEGRAM)
                local tgGo = GameObject("TgBtn")
                tgGo.transform:SetParent(activeTgContainerGo.transform, false)
                local tgBtnRt = tgGo:AddComponent(typeof(RectTransform))
                tgBtnRt.anchorMin = Vector2(0.5, 0.5)
                tgBtnRt.anchorMax = Vector2(0.5, 0.5)
                tgBtnRt.pivot = Vector2(0.5, 0.5)
                tgBtnRt.anchoredPosition = Vector2((btnWidth / 2 + gap / 2), 0)
                tgBtnRt.sizeDelta = Vector2(btnWidth, btnHeight)

                local tgImg = tgGo:AddComponent(typeof(Image))
                tgImg.color = Color(0.0, 0.54, 0.83, 1)

                local tgTxtG = GameObject("Txt")
                tgTxtG.transform:SetParent(tgGo.transform, false)
                local tgtRt = tgTxtG:AddComponent(typeof(RectTransform))
                tgtRt.anchorMin = Vector2(0, 0)
                tgtRt.anchorMax = Vector2(1, 1)
                tgtRt.sizeDelta = Vector2(0, 0)
                local tgTxt = tgTxtG:AddComponent(typeof(Text))
                local tgUser = (_G.Mod_Config_AdminTelegram and _G.Mod_Config_AdminTelegram[1]) or "vutmod"
                local cleanTgUser = string.gsub(tostring(tgUser), "^@+", "")
                tgTxt.text = "Telegram: @" .. cleanTgUser
                tgTxt.font = defaultFont
                tgTxt.fontSize = 15
                tgTxt.color = Color.white
                tgTxt.alignment = TextAnchor.MiddleCenter

                local tgBtn = tgGo:AddComponent(typeof(Button))
                tgBtn.onClick:AddListener(function()
                    local liveSerial = Mod_GetDeviceSerialMD5()
                    local liveUID = Mod_GetCharacterUID()
                    local msg = ""
                    local hasSerial = (liveSerial ~= "")
                    local hasUID = (liveUID ~= "" and liveUID ~= "Vui lòng đăng nhập nhân vật để lấy UID")
                    if hasSerial and hasUID then
                        msg = "Hi Admin, Active giúp mình với:\nSerialMD5: " .. liveSerial .. "\nUID: " .. liveUID
                    else
                        msg = "Hi"
                    end
                    local urlMsg = CS.UnityEngine.WWW.EscapeURL(msg)
                    local telegramUrl = "https://t.me/" .. cleanTgUser .. "?text=" .. urlMsg
                    pcall(function() CS.UnityEngine.Application.OpenURL(telegramUrl) end)
                end)
            end
        end
        _G.Mod_RefreshAuthPanelData = RefreshAuthPanelData
        RefreshAuthPanelData()

        rBtn.onClick:AddListener(function()
            if _G.FloatingWordUtility then _G.FloatingWordUtility.QuickMsg("Đang kiểm tra Kích hoạt từ Server...") end
            if _G.Mod_CheckActiveConfigNow then
                _G.Mod_CheckActiveConfigNow(function(isSuccess, isActive, statusMsg)
                    if isActive then
                        if _G.authPanelGo and not _G.authPanelGo:Equals(nil) then _G.authPanelGo:SetActive(false) end
                        if _G.ModMenuPanelGo and not _G.ModMenuPanelGo:Equals(nil) then
                            _G.ModMenuPanelGo:SetActive(true)
                            if RefreshMainTabs then RefreshMainTabs() end
                        end
                        if _G.FloatingWordUtility then _G.FloatingWordUtility.QuickMsg("Kích hoạt bản quyền thành công!") end
                        if _G.Mod_UpdateUI_ActiveState then _G.Mod_UpdateUI_ActiveState() end
                    else
                        if _G.Mod_RefreshAuthPanelData then _G.Mod_RefreshAuthPanelData() end
                        if _G.FloatingWordUtility then
                            _G.FloatingWordUtility.QuickMsg(statusMsg or
                                "Chưa tìm thấy kích hoạt hợp lệ!")
                        end
                    end
                end)
            end
        end)

        _G.Mod_UpdateUI_ActiveState = function()
            pcall(function()
                if _G.FloatingModBtnGo and not _G.FloatingModBtnGo:Equals(nil) then
                    _G.FloatingModBtnGo:SetActive(true)
                end
                if _G.FloatingPKBtnGo and not _G.FloatingPKBtnGo:Equals(nil) then
                    _G.FloatingPKBtnGo:SetActive(_G.Mod_IsActive == true)
                end
                if _G.FloatingAdminBtnGo and not _G.FloatingAdminBtnGo:Equals(nil) then
                    _G.FloatingAdminBtnGo:SetActive(_G.Mod_IsDev == true)
                end
                if _G.authPanelGo and not _G.authPanelGo:Equals(nil) then
                    if _G.Mod_IsActive then
                        _G.authPanelGo:SetActive(false)
                    end
                end
            end)
        end

        local isExpanded = false
        if not _G.ModMainTab then
            pcall(function() _G.ModMainTab = CS.UnityEngine.PlayerPrefs.GetString("ModMainTab", "CO_BAN") end)
            if not _G.ModMainTab or _G.ModMainTab == "" then _G.ModMainTab = "CO_BAN" end
        end
        if _G.Mod_AutoReturnPos_Coords == nil then
            pcall(function()
                _G.Mod_AutoReturnPos_Coords = CS.UnityEngine.PlayerPrefs.GetString(
                    "Mod_AutoReturnPos_Coords", "")
            end)
            if not _G.Mod_AutoReturnPos_Coords then _G.Mod_AutoReturnPos_Coords = "" end
        end
        if _G.Mod_LockTarget_Enabled == nil then
            pcall(function()
                _G.Mod_LockTarget_Enabled = CS.UnityEngine.PlayerPrefs.GetInt("Mod_LockTarget_Enabled", 0) ==
                    1
            end)
        end
        if _G.Mod_LockTarget_Name == nil then
            pcall(function() _G.Mod_LockTarget_Name = CS.UnityEngine.PlayerPrefs.GetString("Mod_LockTarget_Name", "") end)
            if not _G.Mod_LockTarget_Name then _G.Mod_LockTarget_Name = "" end
        end
        _G.CoBanUIList = {}
        _G.NangCaoUIList = {}
        _G.AutoBossUIList = {}
        _G.AdminUIList = {}

        local function RefreshMainTabs()
            _G.Mod_UpdateUI_ActiveState()

            if _G.Mod_Config_ActiveBasicTab == false and _G.ModMainTab == "CO_BAN" then
                if _G.Mod_Config_ActiveAdvancedTab ~= false then
                    _G.ModMainTab = "NANG_CAO"
                elseif _G.Mod_Config_ActiveAutoFarmTab ~= false then
                    _G.ModMainTab = "AUTO_BOSS"
                end
            end
            if _G.Mod_Config_ActiveAdvancedTab == false and _G.ModMainTab == "NANG_CAO" then
                if _G.Mod_Config_ActiveBasicTab ~= false then
                    _G.ModMainTab = "CO_BAN"
                elseif _G.Mod_Config_ActiveAutoFarmTab ~= false then
                    _G.ModMainTab = "AUTO_BOSS"
                end
            end
            if _G.Mod_Config_ActiveAutoFarmTab == false and _G.ModMainTab == "AUTO_BOSS" then
                if _G.Mod_Config_ActiveBasicTab ~= false then
                    _G.ModMainTab = "CO_BAN"
                elseif _G.Mod_Config_ActiveAdvancedTab ~= false then
                    _G.ModMainTab = "NANG_CAO"
                end
            end

            if _G.tabCoBanGo and not _G.tabCoBanGo:Equals(nil) then
                _G.tabCoBanGo:SetActive(_G.Mod_Config_ActiveBasicTab ~= false)
            end
            if _G.tabNangCaoGo and not _G.tabNangCaoGo:Equals(nil) then
                _G.tabNangCaoGo:SetActive(_G.Mod_Config_ActiveAdvancedTab ~= false)
            end
            if _G.tabAutoBossGo and not _G.tabAutoBossGo:Equals(nil) then
                _G.tabAutoBossGo:SetActive(_G.Mod_Config_ActiveAutoFarmTab ~= false)
            end

            for _, go in ipairs(_G.CoBanUIList) do
                if go and not go:Equals(nil) then
                    go:SetActive(_G.ModMainTab == "CO_BAN" and
                        _G.Mod_Config_ActiveBasicTab ~= false)
                end
            end
            for _, go in ipairs(_G.NangCaoUIList) do
                if go and not go:Equals(nil) then
                    go:SetActive(_G.ModMainTab == "NANG_CAO" and
                        _G.Mod_Config_ActiveAdvancedTab ~= false)
                end
            end
            -- [MOD FEATURE]: PHÂN QUYỀN HIỂN THỊ NÚT MỞ RƯƠNG VÀNG THEO TOKEN AUTO BOSS
            local hasAutoBossPermission = (_G.Mod_Config_ActiveAdvancedTab ~= false) and
                (_G.Mod_Config_ActiveAutoFarmTab ~= false)

            if _G.Mod_GoldenChestToggleGo and not _G.Mod_GoldenChestToggleGo:Equals(nil) then
                local shouldShowChest = (_G.ModMainTab == "NANG_CAO") and hasAutoBossPermission
                _G.Mod_GoldenChestToggleGo:SetActive(shouldShowChest)
                if not hasAutoBossPermission and _G.Mod_AutoOpenGoldenChest_Enabled then
                    _G.Mod_AutoOpenGoldenChest_Enabled = false
                    if _G.ModUpdateGoldenChestLabel then _G.ModUpdateGoldenChestLabel() end
                end
            end
            -- [MOD FEATURE]: PHÂN QUYỀN HIỂN THỊ TẮT HIỆU ỨNG & TÌM HỎA LONG THEO TOKEN AUTO BOSS
            -- Mô tả: Chỉ hiển thị trong Tab Nâng Cao khi token cho phép cả Tab Nâng Cao & Tab Auto Boss.
            if _G.Mod_DisableVisualsToggleGo and not _G.Mod_DisableVisualsToggleGo:Equals(nil) then
                local shouldShow = (_G.ModMainTab == "NANG_CAO") and hasAutoBossPermission
                _G.Mod_DisableVisualsToggleGo:SetActive(shouldShow)
                if not hasAutoBossPermission and _G.Mod_DisableVisuals then
                    _G.Mod_DisableVisuals = false
                    pcall(function()
                        CS.UnityEngine.PlayerPrefs.SetInt("Mod_DisableVisuals", 0)
                        CS.UnityEngine.PlayerPrefs.Save()
                    end)
                    if _G.ModUpdateDisableVisualsLabel then _G.ModUpdateDisableVisualsLabel() end
                    if _G.Mod_ApplyDisableVisualsState then _G.Mod_ApplyDisableVisualsState() end
                end
            end
            if _G.Mod_FindHoaLongToggleGo and not _G.Mod_FindHoaLongToggleGo:Equals(nil) then
                local shouldShow = (_G.ModMainTab == "NANG_CAO") and hasAutoBossPermission
                _G.Mod_FindHoaLongToggleGo:SetActive(shouldShow)
                if not hasAutoBossPermission and _G.Mod_FindHoaLong_Enabled then
                    _G.Mod_FindHoaLong_Enabled = false
                    pcall(function()
                        CS.UnityEngine.PlayerPrefs.SetInt("Mod_FindHoaLong_Enabled", 0)
                        CS.UnityEngine.PlayerPrefs.Save()
                    end)
                    _G.Mod_StopTimer("Mod_FindHoaLongLoop")
                    if _G.ModUpdateFindHoaLongLabel then _G.ModUpdateFindHoaLongLabel() end
                end
            end
            for _, go in ipairs(_G.AutoBossUIList) do
                if go and not go:Equals(nil) then
                    go:SetActive(_G.ModMainTab == "AUTO_BOSS" and
                        _G.Mod_Config_ActiveAutoFarmTab ~= false)
                end
            end

            if _G.ModRefreshAutoBossConfigUI then
                _G.ModRefreshAutoBossConfigUI()
            end
            if _G.ModUpdateKundunUI then
                _G.ModUpdateKundunUI()
            end
            if _G.UpdateBossWatchUIText then
                _G.UpdateBossWatchUIText()
            end
            if _G.ModMainTab == "CO_BAN" then
                if _G.ModUpdateCountText then _G.ModUpdateCountText() end
            end
        end
        _G.RefreshMainTabs = RefreshMainTabs

        _G.Mod_UpdateUI_ActiveState()

        local testBtnGo = GameObject("FOVMinusBtn")
        testBtnGo.transform:SetParent(panelGo.transform, false)
        local testRt = testBtnGo:AddComponent(typeof(RectTransform))
        testRt.anchorMin = Vector2(0, 1)
        testRt.anchorMax = Vector2(0, 1)
        testRt.pivot = Vector2(0, 1)
        testRt.anchoredPosition = Vector2(40, -60)
        testRt.sizeDelta = Vector2(40, 30)

        local testImg = testBtnGo:AddComponent(typeof(Image))
        testImg.color = Color(0.5, 0.2, 0.2, 1)
        local testBtn = testBtnGo:AddComponent(typeof(Button))
        if testBtn then
            testBtn.onClick:AddListener(function()
                local minFov = _G.Mod_Config_FOV_Min or 35
                local maxFov = _G.Mod_Config_FOV_Max or 50
                _G.currentFOV = math.max((_G.currentFOV or maxFov) - 5, minFov)
                if _G.currentFOV > maxFov then _G.currentFOV = maxFov end
                if _G.fovValTxt and not _G.fovValTxt:Equals(nil) then
                    _G.fovValTxt.text = "FOV: " .. tostring(_G.currentFOV)
                end
                if _G.SetCameraFOV then _G.SetCameraFOV(_G.currentFOV) end
            end)
        end
        table.insert(_G.CoBanUIList, testBtnGo)

        local testTxtGo = GameObject("FOVMinusText")
        testTxtGo.transform:SetParent(testBtnGo.transform, false)
        local testTxtRt = testTxtGo:AddComponent(typeof(RectTransform))
        testTxtRt.anchorMin = Vector2(0, 0)
        testTxtRt.anchorMax = Vector2(1, 1)
        testTxtRt.sizeDelta = Vector2(0, 0)
        local testTxt = testTxtGo:AddComponent(typeof(Text))
        testTxt.raycastTarget = false
        testTxt.text = "- 5"
        testTxt.color = Color.white
        testTxt.fontSize = 18
        testTxt.alignment = TextAnchor.MiddleCenter
        if defaultFont then testTxt.font = defaultFont end

        local fovValGo = GameObject("FOVValText")
        fovValGo.transform:SetParent(panelGo.transform, false)
        local fovValRt = fovValGo:AddComponent(typeof(RectTransform))
        fovValRt.anchorMin = Vector2(0, 1)
        fovValRt.anchorMax = Vector2(0, 1)
        fovValRt.pivot = Vector2(0, 1)
        fovValRt.anchoredPosition = Vector2(80, -60)
        fovValRt.sizeDelta = Vector2(160, 30)
        local fovValTxt = fovValGo:AddComponent(typeof(Text))
        fovValTxt.raycastTarget = false
        fovValTxt.text = "FOV: " .. tostring(_G.currentFOV or 55)
        fovValTxt.color = Color.white
        fovValTxt.fontSize = 18
        fovValTxt.alignment = TextAnchor.MiddleCenter
        if defaultFont then fovValTxt.font = defaultFont end
        _G.fovValTxt = fovValTxt
        table.insert(_G.CoBanUIList, fovValGo)

        local plusBtnGo = GameObject("FOVPlusBtn")
        plusBtnGo.transform:SetParent(panelGo.transform, false)
        local plusRt = plusBtnGo:AddComponent(typeof(RectTransform))
        plusRt.anchorMin = Vector2(0, 1)
        plusRt.anchorMax = Vector2(0, 1)
        plusRt.pivot = Vector2(0, 1)
        plusRt.anchoredPosition = Vector2(240, -60)
        plusRt.sizeDelta = Vector2(40, 30)

        local plusImg = plusBtnGo:AddComponent(typeof(Image))
        plusImg.color = Color(0.2, 0.5, 0.2, 1)
        local plusBtn = plusBtnGo:AddComponent(typeof(Button))
        if plusBtn then
            plusBtn.onClick:AddListener(function()
                local minFov = _G.Mod_Config_FOV_Min or 35
                local maxFov = _G.Mod_Config_FOV_Max or 50
                _G.currentFOV = math.min((_G.currentFOV or minFov) + 5, maxFov)
                if _G.currentFOV < minFov then _G.currentFOV = minFov end
                if _G.fovValTxt and not _G.fovValTxt:Equals(nil) then
                    _G.fovValTxt.text = "FOV: " .. tostring(_G.currentFOV)
                end
                if _G.SetCameraFOV then _G.SetCameraFOV(_G.currentFOV) end
            end)
        end
        table.insert(_G.CoBanUIList, plusBtnGo)

        local plusTxtGo = GameObject("FOVPlusText")
        plusTxtGo.transform:SetParent(plusBtnGo.transform, false)
        local plusTxtRt = plusTxtGo:AddComponent(typeof(RectTransform))
        plusTxtRt.anchorMin = Vector2(0, 0)
        plusTxtRt.anchorMax = Vector2(1, 1)
        plusTxtRt.sizeDelta = Vector2(0, 0)
        local plusTxt = plusTxtGo:AddComponent(typeof(Text))
        plusTxt.raycastTarget = false
        plusTxt.text = "+ 5"
        plusTxt.color = Color.white
        plusTxt.fontSize = 18
        plusTxt.alignment = TextAnchor.MiddleCenter
        if defaultFont then plusTxt.font = defaultFont end



        local function GetPlayerReincarnationLevel()
            if _G.Mod_Config_CurrentRebirth and _G.Mod_Config_CurrentRebirth >= 3 and _G.Mod_Config_CurrentRebirth <= 12 then
                return _G.Mod_Config_CurrentRebirth
            end
            local res = nil
            pcall(function()
                if _G.RoleManager and _G.RoleManager.me then
                    local me = _G.RoleManager.me
                    local lvl = me.level or me.lv or 0
                    if me.changeLife and me.changeLife >= 3 and me.changeLife <= 12 then
                        res = me.changeLife
                        return
                    end
                    if lvl > 0 then
                        local r = math.floor(lvl / 100)
                        if r >= 3 and r <= 12 then res = r; return end
                    end
                end
                if _G.QuickFind and _G.QuickFind.LuaMainPlayerViewAttrData then
                    local attr = _G.QuickFind.LuaMainPlayerViewAttrData()
                    if attr and attr.level and attr.level > 0 then
                        if _G.ClientTable and _G.ClientTable.cfg_Character_levelManager then
                            local r = _G.ClientTable.cfg_Character_levelManager:GetReincarnationLevel(attr.level)
                            if r and r >= 3 and r <= 12 then res = r; return end
                        end
                        local r = math.floor(attr.level / 100)
                        if r and r >= 3 and r <= 12 then res = r; return end
                    end
                end
            end)
            if res and res >= 3 and res <= 12 then return res end
            return 8
        end
        _G.GetPlayerReincarnationLevel = GetPlayerReincarnationLevel

        local function GetAvailableTiers()
            local p = _G.Mod_Config_Reincarnation_Primary or GetPlayerReincarnationLevel() or 8
            local s = _G.Mod_Config_Reincarnation_Secondary or (p > 1 and (p - 1) or 1)

            local tiers = {}
            if s >= 3 and s <= 12 then
                table.insert(tiers, "C" .. tostring(s))
            end
            if p >= 3 and p <= 12 and p ~= s then
                table.insert(tiers, "C" .. tostring(p))
            end
            if #tiers == 0 then
                table.insert(tiers, "C" .. tostring(p))
            end
            return tiers
        end
        _G.GetAvailableTiers = GetAvailableTiers

        local function GetKundunTiers()
            local p = _G.Mod_Config_Reincarnation_Primary or GetPlayerReincarnationLevel() or 8
            local s = _G.Mod_Config_Reincarnation_Secondary or (p > 1 and (p - 1) or 1)

            local tiers = {}
            if s >= 4 then
                table.insert(tiers, "C" .. tostring(s))
            end
            if p >= 4 and p ~= s then
                table.insert(tiers, "C" .. tostring(p))
            end
            return tiers
        end
        _G.GetKundunTiers = GetKundunTiers

        _G.Mod_MapsConfig_c3 = {
            {
                mapId = 101094,
                title = "Hoang Dã C3",
                bosses = {
                    { id = 10179407, name = "H.Thần Kiêu Ngạo", col = 1, transferId = 400212 },
                    { id = 10179408, name = "Phẫn Nộ", col = 2, transferId = 400218 },
                    { id = 10179409, name = "Cuồng Bạo", col = 3, transferId = 400224 },
                }
            },
            {
                mapId = 105203,
                title = "Trang Sức C3",
                bosses = {
                    { id = 10520301, name = "N.Khổng Lồ Sét", col = 1, transferId = 105203101 },
                    { id = 10520302, name = "Phẫn Nộ", col = 2, transferId = 105203102 },
                }
            },
            {
                mapId = 106402,
                title = "Thí Luyện Cánh 2",
                bosses = {
                    { id = 10640201, name = "N.Cây Totem", col = 1, transferId = 10640201 },
                    { id = 10640202, name = "Ngang Ngược", col = 2, transferId = 10640202 },
                    { id = 10640203, name = "Tà Ác", col = 3, transferId = 10640203 },
                }
            },
            {
                mapId = 106705,
                title = "Luyện Ngục C3",
                bosses = {
                    { id = 10670501, name = "Nurmus", col = 1, transferId = 106705101 },
                    { id = 10670502, name = "Ngang Ngược", col = 2, transferId = 106705103 },
                    { id = 10670503, name = "Tà Ác", col = 3, transferId = 106705105 },
                }
            },
        }

        _G.Mod_MapsConfig_c4 = {
            {
                mapId = 101093,
                title = "Hoang Dã C4",
                bosses = {
                    { id = 10179307, name = "K.Sĩ Địa Ngục", col = 1, transferId = 400213 },
                    { id = 10179308, name = "Phẫn Nộ", col = 2, transferId = 400219 },
                    { id = 10179309, name = "Cuồng Bạo", col = 3, transferId = 400225 },
                }
            },
            {
                mapId = 105204,
                title = "Trang Sức C4",
                bosses = {
                    { id = 10520401, name = "N.Khổng Lồ U Linh", col = 1, transferId = 105204101 },
                    { id = 10520402, name = "Phẫn Nộ", col = 2, transferId = 105204102 },
                }
            },
            {
                mapId = 106403,
                title = "Thí Luyện Cánh 3",
                bosses = {
                    { id = 10640301, name = "O.Chúa Khát Máu", col = 1, transferId = 10640301 },
                    { id = 10640302, name = "Ngang Ngược", col = 2, transferId = 10640302 },
                    { id = 10640303, name = "Tà Ác", col = 3, transferId = 10640303 },
                }
            },
            {
                mapId = 106701,
                title = "Luyện Ngục C4",
                bosses = {
                    { id = 10670101, name = "Ma Tinh Phoenix", col = 1, transferId = 106701101 },
                    { id = 10670102, name = "Ngang Ngược", col = 2, transferId = 106701103 },
                    { id = 10670103, name = "Tà Ác", col = 3, transferId = 106701105 },
                }
            },
        }

        _G.Mod_MapsConfig_c5 = {
            {
                mapId = 101095,
                title = "Hoang Dã C5",
                bosses = {
                    { id = 10179507, name = "Giác Ma Đ.Ngục", col = 1, transferId = 400214 },
                    { id = 10179508, name = "Phẫn Nộ", col = 2, transferId = 400220 },
                    { id = 10179509, name = "Cuồng Bạo", col = 3, transferId = 400226 },
                }
            },
            {
                mapId = 105205,
                title = "Trang Sức C5",
                bosses = {
                    { id = 10520501, name = "Hươu Thủy Tinh", col = 1, transferId = 105205101 },
                    { id = 10520502, name = "Phẫn Nộ", col = 2, transferId = 105205102 },
                }
            },
            {
                mapId = 106404,
                title = "Thí Luyện Cánh 4",
                bosses = {
                    { id = 10640401, name = "Quỷ Dung Nham", col = 1, transferId = 10640401 },
                    { id = 10640402, name = "Ngang Ngược", col = 2, transferId = 10640402 },
                    { id = 10640403, name = "Tà Ác", col = 3, transferId = 10640403 },
                }
            },
            {
                mapId = 106702,
                title = "Luyện Ngục C5",
                bosses = {
                    { id = 10670201, name = "Nars", col = 1, transferId = 106702101 },
                    { id = 10670202, name = "Ngang Ngược", col = 2, transferId = 106702103 },
                    { id = 10670203, name = "Tà Ác", col = 3, transferId = 106702105 },
                }
            },
        }

        _G.Mod_MapsConfig_c6 = {
            {
                mapId = 101092,
                title = "Hoang Dã C6",
                bosses = {
                    { id = 10179207, name = "V.Sĩ Khiên Kiếm", col = 1, transferId = 400215 },
                    { id = 10179208, name = "Phẫn Nộ", col = 2, transferId = 400221 },
                    { id = 10179209, name = "Cuồng Bạo", col = 3, transferId = 400227 },
                }
            },
            {
                mapId = 105206,
                title = "Trang Sức C6",
                bosses = {
                    { id = 10520601, name = "H.Thần Kiêu Ngạo", col = 1, transferId = 105206101 },
                    { id = 10520602, name = "Phẫn Nộ", col = 2, transferId = 105206102 },
                }
            },
            {
                mapId = 106405,
                title = "Thí Luyện Cánh 5",
                bosses = {
                    { id = 10640501, name = "Q.Vương L.Ngục", col = 1, transferId = 10640501 },
                    { id = 10640502, name = "Ngang Ngược", col = 2, transferId = 10640502 },
                    { id = 10640503, name = "Tà Ác", col = 3, transferId = 10640503 },
                }
            },
            {
                mapId = 106703,
                title = "Luyện Ngục C6",
                bosses = {
                    { id = 10670301, name = "Q.Chủ L.Ngục", col = 1, transferId = 106703101 },
                    { id = 10670302, name = "Ngang Ngược", col = 2, transferId = 106703103 },
                    { id = 10670303, name = "Tà Ác", col = 3, transferId = 106703104 },
                }
            },
        }

        _G.Mod_MapsConfig_c7 = {
            {
                mapId = 101096,
                title = "Hoang Dã C7",
                bosses = {
                    { id = 10179607, name = "Tektus", col = 1, transferId = 400216 },
                    { id = 10179608, name = "Phẫn Nộ", col = 2, transferId = 400222 },
                    { id = 10179609, name = "Cuồng Bạo", col = 3, transferId = 400228 },
                }
            },
            {
                mapId = 105207,
                title = "Trang Sức C7",
                bosses = {
                    { id = 10520701, name = "Tektus", col = 1, transferId = 105207101 },
                    { id = 10520702, name = "Phẫn Nộ", col = 2, transferId = 105207102 },
                }
            },
            {
                mapId = 106406,
                title = "Thí Luyện Cánh 6",
                bosses = {
                    { id = 10640601, name = "CS Rìu To", col = 1, transferId = 10640601 },
                    { id = 10640602, name = "Ngang Ngược", col = 2, transferId = 10640602 },
                    { id = 10640603, name = "Tà Ác", col = 3, transferId = 10640603 },
                }
            },
            {
                mapId = 106704,
                title = "Luyện Ngục C7",
                bosses = {
                    { id = 10670401, name = "Tướng Quân LN", col = 1, transferId = 106704101 },
                    { id = 10670402, name = "Ngang Ngược", col = 2, transferId = 106704102 },
                    { id = 10670403, name = "Tà Ác", col = 3, transferId = 106704103 },
                }
            },
        }

        _G.Mod_MapsConfig_c8 = {
            {
                mapId = 1074,
                title = "Hoang Dã C8",
                bosses = {
                    { id = 107407, name = "K.Sĩ Tử Vong", col = 1, transferId = 400229 },
                    { id = 107408, name = "Phẫn Nộ", col = 2, transferId = 400230 },
                    { id = 107409, name = "Cuồng Bạo", col = 3, transferId = 400231 },
                }
            },
            {
                mapId = 105208,
                title = "Trang Sức C8",
                bosses = {
                    { id = 10520801, name = "K.Sĩ Tử Vong", col = 1, transferId = 105208101 },
                    { id = 10520802, name = "Phẫn Nộ", col = 2, transferId = 105208102 },
                }
            },
            {
                mapId = 106407,
                title = "Thí Luyện Cánh 7",
                bosses = {
                    { id = 10640701, name = "T.Vệ Giáo Dài", col = 1, transferId = 10640701 },
                    { id = 10640702, name = "Ngang Ngược", col = 2, transferId = 10640702 },
                    { id = 10640703, name = "Tà Ác", col = 3, transferId = 10640703 },
                }
            },
            {
                mapId = 106706,
                title = "Luyện Ngục C8",
                bosses = {
                    { id = 10670601, name = "Ma Đạo Phủ", col = 1, transferId = 106706101 },
                    { id = 10670602, name = "Ngang Ngược", col = 2, transferId = 106706102 },
                    { id = 10670603, name = "Tà Ác", col = 3, transferId = 106706103 },
                }
            },
        }

        _G.Mod_MapsConfig_c9 = {
            {
                mapId = 1075,
                title = "Hoang Dã C9",
                bosses = {
                    { id = 107507, name = "S.Giả Ác Ma", col = 1, transferId = 400232 },
                    { id = 107508, name = "Phẫn Nộ", col = 2, transferId = 400233 },
                    { id = 107509, name = "Cuồng Bạo", col = 3, transferId = 400234 },
                }
            },
            {
                mapId = 105209,
                title = "Trang Sức C9",
                bosses = {
                    { id = 10520901, name = "S.Giả Ác Ma", col = 1, transferId = 105209101 },
                    { id = 10520902, name = "Phẫn Nộ", col = 2, transferId = 105209102 },
                }
            },
            {
                mapId = 106408,
                title = "Thí Luyện Cánh 8",
                bosses = {
                    { id = 10640801, name = "T.Vệ Loan Đao", col = 1, transferId = 10640801 },
                    { id = 10640802, name = "Ngang Ngược", col = 2, transferId = 10640802 },
                    { id = 10640803, name = "Tà Ác", col = 3, transferId = 10640803 },
                }
            },
            {
                mapId = 106707,
                title = "Luyện Ngục C9",
                bosses = {
                    { id = 10670701, name = "Quỷ Biển", col = 1, transferId = 106707101 },
                    { id = 10670702, name = "Ngang Ngược", col = 2, transferId = 106707102 },
                    { id = 10670703, name = "Tà Ác", col = 3, transferId = 106707103 },
                }
            },
        }

        _G.Mod_MapsConfig_c10 = {
            {
                mapId = 1076,
                title = "Hoang Dã C10",
                bosses = {
                    { id = 107607, name = "C.Sĩ Cuồng Nộ", col = 1, transferId = 400235 },
                    { id = 107608, name = "Phẫn Nộ", col = 2, transferId = 400236 },
                    { id = 107609, name = "Cuồng Bạo", col = 3, transferId = 400237 },
                }
            },
            {
                mapId = 105210,
                title = "Trang Sức C10",
                bosses = {
                    { id = 10521001, name = "C.Sĩ Cuồng Nộ", col = 1, transferId = 105210101 },
                    { id = 10521002, name = "Phẫn Nộ", col = 2, transferId = 105210102 },
                }
            },
            {
                mapId = 106409,
                title = "Thí Luyện Cánh 9",
                bosses = {
                    { id = 10640901, name = "T.Vệ Lam Tinh", col = 1, transferId = 10640901 },
                    { id = 10640902, name = "Ngang Ngược", col = 2, transferId = 10640902 },
                    { id = 10640903, name = "Tà Ác", col = 3, transferId = 10640903 },
                }
            },
            {
                mapId = 106708,
                title = "Luyện Ngục C10",
                bosses = {
                    { id = 10670801, name = "Mị Ma", col = 1, transferId = 106708101 },
                    { id = 10670802, name = "Ngang Ngược", col = 2, transferId = 106708102 },
                    { id = 10670803, name = "Tà Ác", col = 3, transferId = 106708103 },
                }
            },
        }

        _G.Mod_MapsConfig_c11 = {
            {
                mapId = 10123,
                title = "Hoang Dã C11",
                bosses = {
                    { id = 1012307, name = "Thủy Ma Navos", col = 1, transferId = 400238 },
                    { id = 1012308, name = "Phẫn Nộ", col = 2, transferId = 400239 },
                    { id = 1012309, name = "Cuồng Bạo", col = 3, transferId = 400240 },
                }
            },
            {
                mapId = 105211,
                title = "Trang Sức C11",
                bosses = {
                    { id = 10521101, name = "Ma Thủy Navos", col = 1, transferId = 105211101 },
                    { id = 10521102, name = "Phẫn Nộ", col = 2, transferId = 105211102 },
                }
            },
            {
                mapId = 106410,
                title = "Thí Luyện Cánh 10",
                bosses = {
                    { id = 10641001, name = "Vua Biển Băng Tinh", col = 1, transferId = 10641001 },
                    { id = 10641002, name = "Ngang Ngược", col = 2, transferId = 10641002 },
                    { id = 10641003, name = "Tà Ác", col = 3, transferId = 10641003 },
                }
            },
            {
                mapId = 106709,
                title = "Luyện Ngục C11",
                bosses = {
                    { id = 10670901, name = "Thợ Mỏ Ma Tinh", col = 1, transferId = 106709101 },
                    { id = 10670902, name = "Ngang Ngược", col = 2, transferId = 106709102 },
                    { id = 10670903, name = "Tà Ác", col = 3, transferId = 106709103 },
                }
            },
        }

        _G.Mod_MapsConfig_c12 = {
            {
                mapId = 1012301,
                title = "Hoang Dã C12",
                bosses = {
                    { id = 101230107, name = "Thần Hắc Ám", col = 1, transferId = 400241 },
                    { id = 101230108, name = "Phẫn Nộ", col = 2, transferId = 400242 },
                    { id = 101230109, name = "Cuồng Bạo", col = 3, transferId = 400243 },
                }
            },
            {
                mapId = 105212,
                title = "Trang Sức C12",
                bosses = {
                    { id = 10521201, name = "Thần Hắc Ám", col = 1, transferId = 105212101 },
                    { id = 10521202, name = "Phẫn Nộ", col = 2, transferId = 105212102 },
                }
            },
            {
                mapId = 106411,
                title = "Thí Luyện Cánh 11",
                bosses = {
                    { id = 10641101, name = "N.Cá Shaman", col = 1, transferId = 10641101 },
                    { id = 10641102, name = "Ngang Ngược", col = 2, transferId = 10641102 },
                    { id = 10641103, name = "Tà Ác", col = 3, transferId = 10641103 },
                }
            },
            {
                mapId = 106710,
                title = "Luyện Ngục C12",
                bosses = {
                    { id = 10671001, name = "N.Khai Thác", col = 1, transferId = 106710101 },
                    { id = 10671002, name = "Ngang Ngược", col = 2, transferId = 106710102 },
                    { id = 10671003, name = "Tà Ác", col = 3, transferId = 106710103 },
                }
            },
        }

        local function GetMapsConfigByTier(tierTag)
            if not tierTag then return _G.Mod_MapsConfig_c7 or {} end
            local tagLower = string.lower(tierTag)
            return _G["Mod_MapsConfig_" .. tagLower] or {}
        end
        _G.GetMapsConfigByTier = GetMapsConfigByTier

        _G.ModBossTab = _G.ModBossTab or "C7"

        local mapBosses = {}
        local titleUIPool = {}
        local rowUIPool = {}
        local btnUIPool = {}
        local sepUIPool = {}

        local function GetDashedLine(index, posY)
            if not sepUIPool[index] then
                local sepGo = GameObject("Separator_" .. index)
                sepGo.transform:SetParent(panelGo.transform, false)
                local rt = sepGo:AddComponent(typeof(RectTransform))
                rt.anchorMin = Vector2(0, 1)
                rt.anchorMax = Vector2(0, 1)
                rt.pivot = Vector2(0, 1)
                rt.sizeDelta = Vector2(700, 20)
                local txt = sepGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.color = Color(0.4, 0.4, 0.4, 1)
                txt.fontSize = 16
                txt.alignment = TextAnchor.MiddleLeft
                if defaultFont then txt.font = defaultFont end
                txt.text =
                "--------------------------------------------------------------------------------------------------------------------------"
                sepUIPool[index] = { go = sepGo, txt = txt, rt = rt }
                table.insert(_G.CoBanUIList, sepGo)
            end
            sepUIPool[index].rt.anchoredPosition = Vector2(40, posY)
            return sepUIPool[index]
        end


        local function GetTitleLabel(index, posY)
            if not titleUIPool[index] then
                local titleGo = GameObject("MapTitle_" .. index)
                titleGo.transform:SetParent(panelGo.transform, false)
                local rt = titleGo:AddComponent(typeof(RectTransform))
                rt.anchorMin = Vector2(0, 1)
                rt.anchorMax = Vector2(0, 1)
                rt.pivot = Vector2(0, 1)
                rt.sizeDelta = Vector2(720, 30)
                local txt = titleGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.color = Color(1, 0.8, 0, 1)
                txt.fontSize = 16
                txt.alignment = TextAnchor.MiddleLeft
                if defaultFont then txt.font = defaultFont end
                titleUIPool[index] = { go = titleGo, txt = txt, rt = rt }
                table.insert(_G.CoBanUIList, titleGo)
            end
            titleUIPool[index].rt.anchoredPosition = Vector2(40, posY)
            return titleUIPool[index]
        end

        local function GetRowLabel(rowIndex, posX, posY)
            if not rowUIPool[rowIndex] then
                local rowGo = GameObject("BossRow_" .. rowIndex)
                rowGo.transform:SetParent(panelGo.transform, false)
                local rt = rowGo:AddComponent(typeof(RectTransform))
                rt.anchorMin = Vector2(0, 1)
                rt.anchorMax = Vector2(0, 1)
                rt.pivot = Vector2(0, 1)
                rt.sizeDelta = Vector2(135, 30)
                local txt = rowGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.color = Color.white
                txt.fontSize = 17
                txt.alignment = TextAnchor.MiddleLeft
                if defaultFont then txt.font = defaultFont end
                rowUIPool[rowIndex] = { go = rowGo, txt = txt, rt = rt }
                table.insert(_G.CoBanUIList, rowGo)
            end
            rowUIPool[rowIndex].rt.anchoredPosition = Vector2(posX, posY)
            return rowUIPool[rowIndex]
        end

        local function GetLineButton(btnIndex, posX, posY, width, height)
            height = height or 30
            if not btnUIPool[btnIndex] then
                local btnGo = GameObject("LineBtn_" .. btnIndex)
                btnGo.transform:SetParent(panelGo.transform, false)
                local rt = btnGo:AddComponent(typeof(RectTransform))
                rt.anchorMin = Vector2(0, 1)
                rt.anchorMax = Vector2(0, 1)
                rt.pivot = Vector2(0, 1)
                rt.sizeDelta = Vector2(width, height)

                local img = btnGo:AddComponent(typeof(CS.UnityEngine.UI.Image))
                img.color = CS.UnityEngine.Color(1, 1, 1, 0) -- Invisible graphic for raycasting

                local txtGo = GameObject("Text")
                txtGo.transform:SetParent(btnGo.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin = Vector2(0, 0)
                txtRt.anchorMax = Vector2(1, 1)
                txtRt.sizeDelta = Vector2(0, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.color = Color.white
                txt.fontSize = 16
                txt.alignment = TextAnchor.MiddleLeft
                if defaultFont then txt.font = defaultFont end

                local btn = btnGo:AddComponent(typeof(Button))
                btnUIPool[btnIndex] = { go = btnGo, txt = txt, btn = btn, rt = rt }
                table.insert(_G.CoBanUIList, btnGo)
            end
            btnUIPool[btnIndex].rt.anchoredPosition = Vector2(posX, posY)
            btnUIPool[btnIndex].rt.sizeDelta = Vector2(width, height)
            return btnUIPool[btnIndex]
        end

        local function UpdateBossWatchUIText()
            pcall(function()
                if not isExpanded then return end
                local currentSec = (_G.Time and _G.Time.GetServerSecondTime and _G.Time.GetServerSecondTime()) or
                    os.time()
                local currentPosY = -220
                local titleIdx = 1
                local rowIdx = 1
                local btnIdx = 1
                local sepIdx = 1

                local tierTags = GetAvailableTiers and GetAvailableTiers() or { "C7", "C8" }
                local isTabValid = false
                for _, tag in ipairs(tierTags) do
                    if _G.ModBossTab == tag then
                        isTabValid = true; break
                    end
                end
                if not isTabValid and #tierTags > 0 then
                    _G.ModBossTab = tierTags[#tierTags]
                end
                for tIdx, tag in ipairs(tierTags) do
                    local tBtn = GetLineButton(btnIdx, 40 + (tIdx - 1) * 110, currentPosY, 100, 28)
                    tBtn.go:SetActive(_G.ModMainTab == "CO_BAN")
                    tBtn.txt.alignment = TextAnchor.MiddleCenter
                    tBtn.txt.text = "<color=" ..
                        (_G.ModBossTab == tag and "#00FF00" or "#FFFFFF") .. ">[ BOSS " .. tag .. " ]</color>"
                    tBtn.txt.fontSize = 16
                    tBtn.btn.onClick:RemoveAllListeners()
                    local thisTag = tag
                    tBtn.btn.onClick:AddListener(function()
                        _G.ModBossTab = thisTag
                        UpdateBossWatchUIText()
                    end)
                    btnIdx = btnIdx + 1
                end
                currentPosY = currentPosY - 20

                local mapsConfig = GetMapsConfigByTier(_G.ModBossTab)
                for i, mapCfg in ipairs(mapsConfig) do
                    local sep = GetDashedLine(sepIdx, currentPosY)
                    sep.go:SetActive(_G.ModMainTab == "CO_BAN")
                    sepIdx = sepIdx + 1
                    currentPosY = currentPosY - 20

                    local title = GetTitleLabel(titleIdx, currentPosY)
                    title.go:SetActive(_G.ModMainTab == "CO_BAN")
                    title.txt.text = mapCfg.title

                    titleIdx = titleIdx + 1
                    currentPosY = currentPosY - 20

                    local colBosses = { {}, {}, {} }
                    for _, cfg in ipairs(mapCfg.bosses) do
                        local c = cfg.col or 1
                        if c > 3 then c = 3 end
                        table.insert(colBosses[c], cfg)
                    end

                    if string.find(mapCfg.title or "", "Trang Sức") and #colBosses[3] == 0 then
                        table.insert(colBosses[3], { isExitBtn = true, name = "THOÁT PB", col = 3 })
                    end

                    local maxRows = math.max(#colBosses[1], #colBosses[2], #colBosses[3])

                    for r = 1, maxRows do
                        for c = 1, 3 do
                            local cfg = colBosses[c][r]
                            if cfg then
                                local startX = 40 + (c - 1) * 220
                                local yPos = currentPosY - (r - 1) * 28

                                local bw = cfg.isExitBtn and 155 or 215
                                local bx = startX
                                local uiBtn = GetLineButton(btnIdx, bx, yPos, bw, 28)
                                uiBtn.go:SetActive(_G.ModMainTab == "CO_BAN")
                                uiBtn.txt.alignment = TextAnchor.MiddleLeft

                                if cfg.isExitBtn then
                                    uiBtn.txt.text =
                                    "<color=#FF5555><b>THOÁT PB</b></color> <color=#FFD700>[ Rời ]</color>"
                                    uiBtn.txt.alignment = TextAnchor.MiddleCenter
                                    uiBtn.txt.fontSize = 16
                                    uiBtn.btn.onClick:RemoveAllListeners()
                                    uiBtn.btn.onClick:AddListener(function()
                                        pcall(function()
                                            if _G.TranScriptController then
                                                if _G.TranScriptController.ReqExitInstance then
                                                    _G.TranScriptController
                                                        .ReqExitInstance()
                                                end
                                                if _G.TranScriptController.ReqExitAllGods then
                                                    _G.TranScriptController
                                                        .ReqExitAllGods()
                                                end
                                                if _G.TranScriptController.ReqExitUnionMap then
                                                    _G.TranScriptController
                                                        .ReqExitUnionMap()
                                                end
                                            end
                                            if _G.FloatingWordUtility then
                                                _G.FloatingWordUtility.QuickMsg("Đã gửi lệnh Thoát Phó Bản!")
                                            end
                                        end)
                                    end)
                                else
                                    local bossData = mapBosses[mapCfg.mapId] and mapBosses[mapCfg.mapId][cfg.id]
                                    local statusStr = "<color=#AAAAAA>(--:--)</color>"
                                    local validLineNum = 1

                                    if bossData then
                                        local bestLine = nil
                                        for _, lineNum in ipairs(bossData.lineNums) do
                                            local totalAlive = bossData.aliveCount[lineNum] or 0
                                            local deadList = bossData.deadTimes[lineNum] or {}

                                             if totalAlive > 0 or #deadList > 0 then
                                                bestLine = lineNum
                                                if totalAlive > 0 then
                                                    statusStr = "<color=#00FF00>[ xuất hiện ]</color>"
                                                elseif #deadList > 0 then
                                                    local rt = deadList[1]
                                                    local remain = math.floor(rt - currentSec)
                                                    if remain <= 0 then
                                                        statusStr = "<color=#00FF00>[ xuất hiện ]</color>"
                                                    else
                                                        local m = math.floor((remain % 3600) / 60)
                                                        local s = remain % 60
                                                        statusStr = string.format("<color=#AAAAAA>(%02d:%02d)</color>", m,
                                                            s)
                                                    end
                                                end
                                                break
                                            end
                                        end

                                        if bestLine then
                                            validLineNum = bestLine
                                        end
                                    end

                                    uiBtn.txt.text = "<b>" .. cfg.name .. "</b> " .. statusStr
                                    uiBtn.txt.fontSize = 16
                                    uiBtn.txt.alignment = TextAnchor.MiddleLeft

                                    uiBtn.btn.onClick:RemoveAllListeners()
                                    local targetMapId = mapCfg.mapId
                                    local targetTransferId = cfg.transferId
                                    local targetBossId = cfg.id
                                    local targetLine = validLineNum
                                    local targetBossName = cfg.name
                                    local staticPosX = cfg.posX
                                    local staticPosY = cfg.posY

                                    uiBtn.btn.onClick:AddListener(function()
                                        pcall(function()
                                            local currentMapId = _G.SceneData and
                                                (_G.SceneData.mapId or _G.SceneData.groupId) or 0
                                            local currentLine = _G.SceneData and
                                                (_G.SceneData.line or _G.SceneData.cline) or 1
                                            local nowSec = (_G.Time and _G.Time.GetServerSecondTime and _G.Time.GetServerSecondTime()) or
                                                os.time()

                                            if currentMapId ~= targetMapId or currentLine ~= targetLine then
                                                if _G.FloatingWordUtility then
                                                    _G.FloatingWordUtility.QuickMsg("Dịch chuyển tới " ..
                                                        targetBossName .. "...")
                                                end

                                                _G.Mod_PendingManualMove = {
                                                    bossId = targetBossId,
                                                    mapId = targetMapId,
                                                    line = targetLine,
                                                    bossName = targetBossName,
                                                    posX = staticPosX,
                                                    posY = staticPosY,
                                                    expireTime = nowSec + 20
                                                }

                                                local transId = (_G.PathFinderManager and _G.PathFinderManager.GetTransIdByGroupId and _G.PathFinderManager.GetTransIdByGroupId(targetMapId)) or
                                                    targetTransferId or targetMapId
                                                if transId and _G.SceneController and _G.SceneController.OnReqTransferTransmitMap then
                                                    _G.SceneController.OnReqTransferTransmitMap(nil,
                                                        { mapId = transId, line = targetLine, changeLine = true })
                                                elseif _G.PathFinderManager and _G.PathFinderManager.MoveToLinePos then
                                                    local initialPos = (staticPosX and staticPosY and { x = staticPosX, y = staticPosY }) or
                                                        { x = 100, y = 100 }
                                                    _G.PathFinderManager.MoveToLinePos(targetMapId, initialPos, transId,
                                                        targetLine, nil, nil, nil, nil, true)
                                                end
                                            else
                                                -- Đã ở cùng Map & Line -> Tìm vị trí con Boss SỐNG gần nhất (nếu tất cả chết thì tìm vị trí mặc định gần nhất)
                                                local alivePos, aliveCount = nil, 0
                                                if _G.GetAliveBossPosition then
                                                    alivePos, aliveCount = _G.GetAliveBossPosition(targetBossId,
                                                        targetMapId)
                                                end

                                                local targetPos = alivePos or
                                                    (staticPosX and staticPosY and { x = staticPosX, y = staticPosY }) or
                                                    (_G.GetBossPosition and _G.GetBossPosition(targetBossId, targetMapId))

                                                if targetPos then
                                                    if _G.FloatingWordUtility then
                                                        local st = alivePos and "Boss SỐNG" or "vị trí Boss"
                                                        _G.FloatingWordUtility.QuickMsg("Di chuyển đến " ..
                                                            st ..
                                                            " " ..
                                                            targetBossName ..
                                                            " (" .. targetPos.x .. ", " .. targetPos.y .. ")...")
                                                    end

                                                    if _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.MoveTo then
                                                        _G.RoleManager.me:MoveTo({ x = targetPos.x, y = targetPos.y }, 0)
                                                    elseif _G.PathFinderManager and _G.PathFinderManager.JumpMapToMoveToPos then
                                                        local targetVector = Vector2(targetPos.x, targetPos.y)
                                                        _G.PathFinderManager.JumpMapToMoveToPos(targetMapId, targetVector,
                                                            nil, targetLine, nil, Purpose.None, nil, 3, true)
                                                    end
                                                else
                                                    if _G.FloatingWordUtility then
                                                        _G.FloatingWordUtility.QuickMsg("Chưa có tọa độ Boss " ..
                                                            targetBossName)
                                                    end
                                                end
                                            end
                                        end)
                                    end)
                                end

                                rowIdx = rowIdx + 1
                                btnIdx = btnIdx + 1
                            end
                        end
                    end

                    if maxRows > 0 then
                        currentPosY = currentPosY - (maxRows * 28) + 5
                    else
                        currentPosY = currentPosY - 10
                    end
                end

                for i = titleIdx, #titleUIPool do
                    if titleUIPool[i] and titleUIPool[i].go then titleUIPool[i].go:SetActive(false) end
                end
                for i = rowIdx, #rowUIPool do
                    if rowUIPool[i] and rowUIPool[i].go then rowUIPool[i].go:SetActive(false) end
                end
                for i = btnIdx, #btnUIPool do
                    if btnUIPool[i] and btnUIPool[i].go then btnUIPool[i].go:SetActive(false) end
                end
                for i = sepIdx, #sepUIPool do
                    if sepUIPool[i] and sepUIPool[i].go then sepUIPool[i].go:SetActive(false) end
                end

                local requiredHeight = math.abs(currentPosY) + 20
                if requiredHeight < 500 then requiredHeight = 500 end
                panelRt.sizeDelta = Vector2(720, 580)
                if _G.ModUpdateKundunUI then _G.ModUpdateKundunUI() end
            end)
        end

        local function ParseBossData()
            pcall(function()
                if not _G.SceneData or not _G.SceneData.MonsterMapData then return end

                local tempBosses = {}
                for _, md in ipairs(_G.SceneData.MonsterMapData) do
                    if md.mapCount then
                        for _, v in ipairs(md.mapCount) do
                            local mapId = v.mapId
                            if not tempBosses[mapId] then tempBosses[mapId] = {} end

                            local deadTimes = {}
                            if v.bossState then
                                for _, state in ipairs(v.bossState) do
                                    if state.reliveTime and state.reliveTime > 0 then
                                        table.insert(deadTimes, state.reliveTime)
                                    end
                                end
                                -- Sort deadTimes ascending so it shows smaller time first
                                table.sort(deadTimes)
                            end

                            local lineNum = v.line or 1
                            if not tempBosses[mapId][md.bossId] then
                                tempBosses[mapId][md.bossId] = { lines = {}, lineNums = {}, aliveCount = {}, deadTimes = {} }
                            end
                            local bData = tempBosses[mapId][md.bossId]
                            if not bData.lines[lineNum] then
                                bData.lines[lineNum] = true
                                table.insert(bData.lineNums, lineNum)
                            end
                            bData.aliveCount[lineNum] = v.count or 0
                            bData.deadTimes[lineNum] = deadTimes
                        end
                    end
                end

                mapBosses = tempBosses
                _G.Mod_MapBosses = mapBosses
                UpdateBossWatchUIText()
                if _G.ModUpdateKundunUI then _G.ModUpdateKundunUI() end
            end)
        end
        _G.ParseBossData = ParseBossData
        ParseBossData()

        if _G.SavedFOV == nil then
            pcall(function()
                _G.SavedFOV = CS.UnityEngine.PlayerPrefs.GetFloat("Mod_FOV", 35)
                _G.IsAutoRefresh = CS.UnityEngine.PlayerPrefs.GetInt("Mod_AutoRefresh", 0) == 1
                _G.AutoRefreshInterval = CS.UnityEngine.PlayerPrefs.GetInt("Mod_RefreshInterval", 5)
                _G.LastRefreshSec = 0
            end)
        end

        if not _G.BossHooked then
            _G.BossHooked = true

            -- =========================================================================
            -- [MOD FEATURE]: HACK TẦM ĐÁNH & GÓC NHÌN CAMERA (NATIVE CAMERA FOLLOW)
            -- Mô tả: Khôi phục Camera bám theo Me gốc của game, mượt 100% C++ Engine không rung lắc
            -- =========================================================================
            pcall(function()
                -- Dọn dẹp Mod_CameraAnchor cũ nếu có để Camera bám trực tiếp vào Me
                local oldAnchor = CS.UnityEngine.GameObject.Find("Mod_CameraAnchor")
                if oldAnchor and not IsNil(oldAnchor) then
                    CS.UnityEngine.Object.Destroy(oldAnchor)
                end
                _G.Mod_CameraAnchor = nil
                _G.Mod_CameraAnchorTrans = nil

                local mc = _G.MainCamera
                if mc then
                    if not _G.Mod_Hooked_AttachRole and mc.AttachRole then
                        _G.Mod_Hooked_AttachRole = true
                        local old_AttachRole = mc.AttachRole
                        mc.AttachRole = function(role)
                            if not role then return end
                            if old_AttachRole then old_AttachRole(role) end
                            if role.transform and mc.transform then
                                mc.transform:SetParent(role.transform, false)
                                if mc.RefreshPosition then mc.RefreshPosition() end
                            end
                        end
                    end
                    -- Nếu đang trong map và có role me, gán trực tiếp lại
                    local me = _G.RoleManager and _G.RoleManager.me
                    if me and mc.AttachRole then
                        pcall(function() mc.AttachRole(me) end)
                    end
                end
            end)

            -- =========================================================================
            -- [MOD FEATURE]: KHÓA TỐC ĐỘ ANIMATION 1.0X CHO CÁNH & BODY ME (SIÊU NHẸ)
            -- Mô tả: Giữ chuyển động 1.0x mượt mà tuyệt đối khi tăng tốc chạy, không tốn CPU/GC
            -- =========================================================================
            _G.Mod_LockMyAnimatorsToNormal = function()
                pcall(function()
                    local me = _G.RoleManager and _G.RoleManager.me
                    if not me then return end

                    if me.wingAnimator and me.wingAnimator.animator and not IsNil(me.wingAnimator.animator) then
                        if me.wingAnimator.animator.speed ~= 1.0 then
                            me.wingAnimator.animator.speed = 1.0
                        end
                    end
                end)
            end

            -- Khóa tốc độ Animation (Cánh & Body) về chuẩn 1.0x khi tăng tốc chạy
            if _G.AnimatorCtrl and not _G.Mod_Hooked_AnimatorCtrl then
                _G.Mod_Hooked_AnimatorCtrl = true
                local old_SetAnimatorSpeed = _G.AnimatorCtrl.SetAnimatorSpeed
                _G.AnimatorCtrl.SetAnimatorSpeed = function(self, speed)
                    if self.avatar and self.avatar.isMe then
                        if (_G.RunSpeedMultiplier or 1.0) > 1.0 then
                            speed = 1.0
                        end
                    end
                    return old_SetAnimatorSpeed(self, speed)
                end
            end

            if _G.RoleModel and not _G.Mod_Hooked_RoleModel_PlayAnimation then
                _G.Mod_Hooked_RoleModel_PlayAnimation = true
                local old_RoleModel_Play = _G.RoleModel.PlayAnimation
                _G.RoleModel.PlayAnimation = function(self, name, speed, fadeTime, startTime, realTime, callback)
                    if self.avatar and self.avatar.isMe then
                        if (_G.RunSpeedMultiplier or 1.0) > 1.0 then
                            speed = 1.0
                        end
                    end
                    return old_RoleModel_Play(self, name, speed, fadeTime, startTime, realTime, callback)
                end
            end

            if _G.RoleEquip and not _G.Mod_Hooked_RoleEquipWing then
                _G.Mod_Hooked_RoleEquipWing = true
                local old_SetWingAni = _G.RoleEquip.SetWingAni
                _G.RoleEquip.SetWingAni = function(self, RoleMoveType, isCurIsSafeZone)
                    old_SetWingAni(self, RoleMoveType, isCurIsSafeZone)
                    if self.avatar and self.avatar.isMe then
                        if (_G.RunSpeedMultiplier or 1.0) > 1.0 and self.wingAnimator and self.wingAnimator.animator and not IsNil(self.wingAnimator.animator) then
                            self.wingAnimator.animator.speed = 1.0
                        end
                    end
                end
            end

            -- Khóa tốc độ Animation & Particle Dấu Chân (Footprint) về chuẩn 1.0x
            if _G.RoleEquip and not _G.Mod_Hooked_RoleEquipFoot then
                _G.Mod_Hooked_RoleEquipFoot = true
                local old_SetFoot = _G.RoleEquip.SetFoot
                _G.RoleEquip.SetFoot = function(self, position, path)
                    old_SetFoot(self, position, path)
                end
            end

            -- Hook Me:MoveTo và Player:SetMoving
            if _G.Me and not _G.Mod_Hooked_Me_MoveTo then
                _G.Mod_Hooked_Me_MoveTo = true
                local old_Me_MoveTo = _G.Me.MoveTo
                _G.Me.MoveTo = function(self, cell, stopRange, onEndMove)
                    return old_Me_MoveTo(self, cell, stopRange, onEndMove)
                end
            end

            if _G.Player and not _G.Mod_Hooked_Player_SetMoving then
                _G.Mod_Hooked_Player_SetMoving = true
                local old_Player_SetMoving = _G.Player.SetMoving
                _G.Player.SetMoving = function(self, moveType)
                    return old_Player_SetMoving(self, moveType)
                end
            end

            -- Tốc Chạy Hook (Chạy nhanh nhưng Animation Body, Cánh & Dấu Chân giữ nguyên 1.0x)
            local original_SetMoveSpeed = _G.Role.SetMoveSpeed
            if original_SetMoveSpeed and not _G.ModSpeedRunHooked then
                _G.ModSpeedRunHooked = true
                _G.Role.SetMoveSpeed = function(self, moveSpeed, isFromMod)
                    if self.isMe then
                        if not isFromMod then
                            -- Lưu lại tốc độ gốc chuẩn của game/server, chống bị nhân dồn lũy kế
                            self._modBaseMoveSpeed = moveSpeed
                        end
                        -- Khóa bản quyền: Chưa kích hoạt thì luôn chạy tốc độ chuẩn 1.0x
                        if not _G.Mod_IsActive then
                            original_SetMoveSpeed(self, self._modBaseMoveSpeed or moveSpeed)
                            return
                        end
                        local base = self._modBaseMoveSpeed or moveSpeed or 5.0
                        local mult = _G.RunSpeedMultiplier or 1.0
                        if mult < 1.0 then mult = 1.0 end
                        local finalSpeed = base * mult
                        original_SetMoveSpeed(self, finalSpeed)
                    else
                        original_SetMoveSpeed(self, moveSpeed)
                    end
                end
            end

            -- Loop giám sát định kỳ 2.0s khóa chuẩn Animator 1.0x khi chạy tốc độ cao
            _G.Mod_StartSpeedAnimLockLoop = function()
                _G.Mod_StartTrackedTimer("SpeedAnimLock", 2.0, -1, function()
                    if not _G.Mod_IsActive then return end
                    if (_G.RunSpeedMultiplier or 1.0) > 1.0 then
                        if _G.Mod_LockMyAnimatorsToNormal then
                            _G.Mod_LockMyAnimatorsToNormal()
                        end
                    end
                end)
            end
            _G.Mod_StartSpeedAnimLockLoop()

            -- Chống Server Rollback (MoveFailed) gây kẹt con lắc khi chạy tốc độ cao
            if _G.Me and not _G.Mod_Hooked_Me_ChangePos then
                _G.Mod_Hooked_Me_ChangePos = true
                local old_Me_ChangePos = _G.Me.ChangePos
                _G.Me.ChangePos = function(self, moveType, changeReason, reasonParam)
                    if self.isMe then
                        if _G.ERoleChangePosReason and changeReason == _G.ERoleChangePosReason.MoveFailed then
                            -- Chặn đứng Server Rollback để tránh bị kéo giật lùi tạo thành con lắc lặp vô tận
                            return
                        end
                    end
                    return old_Me_ChangePos(self, moveType, changeReason, reasonParam)
                end
            end

            -- Tốc Đánh Cốt Lõi Hook (Can thiệp sâu vào MeData)
            local original_InitFinalAttribute = _G.MeData.InitFinalAttribute
            if original_InitFinalAttribute and not _G.ModMeDataAtkSpeedHooked then
                _G.ModMeDataAtkSpeedHooked = true
                _G.MeData.InitFinalAttribute = function(self)
                    original_InitFinalAttribute(self)
                    if not _G.Mod_IsActive then return end
                    if _G.AtkSpeedMultiplier and _G.AtkSpeedMultiplier > 1.0 then
                        local speedKey = _G.EAttributeType and _G.EAttributeType.attackSpeedCalculateValue
                        if speedKey and self.attributeMap and self.attributeMap[speedKey] then
                            self.attributeMap[speedKey] = math.floor(self.attributeMap[speedKey] * _G.AtkSpeedMultiplier)
                        end
                        local speedIncKey = _G.EAttributeType and _G.EAttributeType.attackSpeedIncrease
                        if speedIncKey and self.attributeMap then
                            local currentInc = self.attributeMap[speedIncKey] or 10000
                            if currentInc == 0 then currentInc = 10000 end
                            self.attributeMap[speedIncKey] = math.floor(currentInc * _G.AtkSpeedMultiplier)
                        end
                    end
                end
            end

            _G.DumpTable = function(node, depth, maxDepth)
                if depth > maxDepth then return tostring(node) end
                local t = type(node)
                if t == "table" then
                    local s = "{"
                    local ok, err = pcall(function()
                        for k, v in pairs(node) do
                            s = s .. tostring(k) .. ":" .. _G.DumpTable(v, depth + 1, maxDepth) .. ", "
                        end
                    end)
                    if not ok then s = s .. "<pairs err>" end
                    return s .. "}"
                else
                    return tostring(node)
                end
            end

            if not _G.Mod_Hooked_QuickShowPrompt and _G.TipUtility and _G.TipUtility.QuickShowPrompt then
                _G.Mod_Hooked_QuickShowPrompt = true
                local old_QuickShowPrompt = _G.TipUtility.QuickShowPrompt
                _G.TipUtility.QuickShowPrompt = function(commonData)
                    if commonData and commonData.id == 10 then
                        if _G.Mod_AutoFarmBoss_Enabled and _G.Mod_AutoFarmBoss_EnterHiddenMap then
                            _G.Mod_HiddenMapEnterAction = commonData.okAction
                        end
                    end
                    return old_QuickShowPrompt(commonData)
                end
            end

            local original_MonsterMapDataInit = _G.SceneData.MonsterMapDataInit
            _G.SceneData.MonsterMapDataInit = function(data)
                if original_MonsterMapDataInit then original_MonsterMapDataInit(data) end
                ParseBossData()
            end
            -- =========================================================================
            -- [MOD FEATURE]: TỰ ĐỘNG TIẾP CẬN BOSS THÁP & PHỤ BẢN (TOWER BOSS & DUNGEON AUTO)
            -- Mô tả: Tự tìm đường đến boss trong Tháp và tự động rời phụ bản khi hoàn thành.
            -- =========================================================================
            _G.Mod_ApproachTowerBoss = function()
                local success, result = pcall(function()
                    local me = _G.RoleManager and _G.RoleManager.me
                    if not me or me.isDead then return false end

                    local targetX, targetY, targetRole
                    local monsterRoles = _G.RoleManager.GetRolesByType and _G.RoleManager.GetRolesByType(2)
                    if monsterRoles then
                        local meId = me and me.data and me.data.id or 0
                        for lid, role in pairs(monsterRoles) do
                            if role and not role.isDead and role.hp and role.hp > 0 then
                                local isSummon = role.isSummon or (role.data and role.data.isSummon) or false
                                local ownerId = role.ownerId or (role.data and role.data.ownerId) or role.masterId or 0
                                local isMySummon = (isSummon == true) or
                                    (ownerId ~= 0 and tostring(ownerId) == tostring(meId))

                                local canAttack = true
                                if _G.RoleTargetManager and _G.RoleTargetManager.GetCanAttackRole then
                                    canAttack = _G.RoleTargetManager.GetCanAttackRole(role)
                                elseif isMySummon then
                                    canAttack = false
                                end

                                if canAttack and not isMySummon then
                                    local x = role.serverCoord and role.serverCoord.x or (role.cellPos and role.cellPos.x) or (role.data and role.data.x)
                                    local y = role.serverCoord and role.serverCoord.y or (role.cellPos and role.cellPos.y) or (role.data and role.data.y)
                                    if x and y then
                                        targetX = tonumber(x)
                                        targetY = tonumber(y)
                                        targetRole = role
                                        break
                                    end
                                end
                            end
                        end
                    end

                    if not targetX or not targetY then return false end

                    local myX = me.serverCoord and me.serverCoord.x or (me.cellPos and me.cellPos.x) or (me.data and me.data.x) or 0
                    local myY = me.serverCoord and me.serverCoord.y or (me.cellPos and me.cellPos.y) or (me.data and me.data.y) or 0

                    if myX == 0 or myY == 0 then return false end

                    local dx = myX - targetX
                    local dy = myY - targetY
                    local dist = math.sqrt(dx * dx + dy * dy)

                    if dist > 1.5 then
                        -- Chưa tới vị trí Boss (cách > 1.5m): Di chuyển đến đúng vị trí Boss tháp (targetX, targetY)
                        pcall(function()
                            if me.MoveTo then
                                me:MoveTo({ x = targetX, y = targetY }, 0)
                            elseif _G.PathFinderManager and _G.PathFinderManager.MoveToLinePos and _G.SceneData and _G.SceneData.mapId then
                                _G.PathFinderManager.MoveToLinePos(_G.SceneData.mapId, { x = targetX, y = targetY }, nil, 1, nil, nil, nil, nil, true)
                            end
                        end)
                        return false -- Trả về false để tiếp tục di chuyển ở tick sau
                    else
                        -- Đã tới cách Boss tháp <= 1.5m: Dừng di chuyển & Bật Auto Fight đập Boss
                        pcall(function()
                            if me.StopMove then me:StopMove() end
                            if targetRole and me.SetTarget then
                                me:SetTarget(targetRole)
                            end
                            if me.SetAutoFight then me:SetAutoFight("ReleaseSkill") end
                            if _G.QiJiHelperData and _G.QiJiHelperData.SetAutoFightData then
                                _G.QiJiHelperData.SetAutoFightData(true)
                            end
                        end)
                        LogMsg(string.format("[TOWER_BOSS] Đã tiếp cận Boss tháp tại (%d,%d) (cự ly %.1fm)! Bật Auto Fight.", targetX, targetY, dist))
                        return true -- Đã hoàn thành tiếp cận
                    end
                end)
                if success then return result else return false end
            end

            _G.Mod_AutoFarmBoss_State = _G.Mod_AutoFarmBoss_State or 0
            _G.Mod_AutoFarmBoss_Target = _G.Mod_AutoFarmBoss_Target or nil
            _G.Mod_AutoFarmBoss_NextReqTime = _G.Mod_AutoFarmBoss_NextReqTime or 0
            _G.Mod_AutoFarmBoss_WaitTime = _G.Mod_AutoFarmBoss_WaitTime or 0
            _G.Mod_AutoFarmBoss_Ignore = _G.Mod_AutoFarmBoss_Ignore or {}

            local function ExitDungeon()
                if _G.TranScriptData and _G.TranScriptData.InTranscript then
                    if _G.TranScriptController then
                        if _G.TranScriptController.ReqExitInstance then _G.TranScriptController.ReqExitInstance() end
                        if _G.TranScriptController.ReqExitAllGods then _G.TranScriptController.ReqExitAllGods() end
                        if _G.TranScriptController.ReqExitUnionMap then _G.TranScriptController.ReqExitUnionMap() end
                    end
                    --_G.Mod_DebugMsg("Đang thoát phó bản Boss...")
                    return true
                end
                return false
            end

            local function LogMsg(msg)
                -- print("[Mod AutoBoss] " .. tostring(msg))
                -- if _G.WriteLog then
                --     _G.WriteLog("[Mod AutoBoss] " .. tostring(msg))
                -- end
                -- if _G.FloatingWordUtility and _G.FloatingWordUtility.QuickMsg then
                --     _G.FloatingWordUtility.QuickMsg("[Auto Boss] " .. tostring(msg))
                -- end
            end

            local function SetBossState(newState, reason)
                local oldState = _G.Mod_AutoFarmBoss_State or 0
                if oldState ~= newState then
                    LogMsg(string.format("[FSM] State %s -> %s (%s)", tostring(oldState), tostring(newState), tostring(reason or "")))
                    _G.Mod_AutoFarmBoss_State = newState
                    _G.Mod_AutoFarmBoss_StopMoveStartTime = nil
                end
            end
            _G.Mod_SetBossState = SetBossState

            local function GetMapName(mapId)
                if not mapId then return "Unknown" end
                if _G.ConfigManager and _G.ConfigManager.MapConfig and _G.ConfigManager.MapConfig[mapId] then
                    return _G.ConfigManager.MapConfig[mapId].name or tostring(mapId)
                end
                return tostring(mapId)
            end
            -- =========================================================================
            -- =========================================================================
            -- [MOD FEATURE]: BẢO VỆ ĐỒ ĐÃ CƯỜNG HÓA / GIA CƯỜNG (CHỐNG TÁCH & CHỐNG THU HỒI)
            -- Mô tả: Kiểm tra toàn diện cấp cường hóa (intensify > 0), gia cường (additional > 0),
            --        tái sinh (RegenerateAttributeList), khảm ngọc (gemList/inlayList), cấp sao,
            --        hoặc kỹ năng đặc thù Trang Sức Bộ để tuyệt đối không bao giờ tách nhầm đồ VIP/đang dùng.
            -- =========================================================================
            local function IsEnhancedEquip(item)
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

                -- 6. Đồ Dung (canSmelt == true)
                if sInfo.canSmelt == true or dSInfo.canSmelt == true or item.canSmelt == true then
                    return true
                end

                -- 7. Kỹ năng đặc thù Trang Sức Bộ (specialEffectIds của Dây, Khuyên, Nhẫn Bộ: subType 34..38)
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
            _G.Mod_IsEnhancedEquip = IsEnhancedEquip

            -- =========================================================================
            -- [MOD FEATURE]: HỆ THỐNG CẤU HÌNH DÒNG NGON LINH HOẠT (DYNAMIC GOOD OPTIONS ENGINE)
            -- Mô tả: Cung cấp kiểm tra thuộc tính Trác Việt theo bảng cấu hình tùy biến của người chơi.
            --        Mặc định: Tất cả các dòng đều được chọn (ON = 1).
            --        Nếu người chơi không chọn gì -> Tự động kích hoạt cơ chế bảo vệ đồ (không tách).
            -- =========================================================================
            _G.Mod_GoodOpts = _G.Mod_GoodOpts or {}
            local function GetGoodOpt(cat, key)
                local fullKey = "Mod_GoodOpt_" .. cat .. "_" .. key
                if _G.Mod_GoodOpts[fullKey] == nil then
                    local v = 1
                    pcall(function() v = CS.UnityEngine.PlayerPrefs.GetInt(fullKey, 1) end)
                    _G.Mod_GoodOpts[fullKey] = (v == 1)
                end
                return _G.Mod_GoodOpts[fullKey]
            end
            _G.Mod_GetGoodOpt = GetGoodOpt

            local function SetGoodOpt(cat, key, val)
                local fullKey = "Mod_GoodOpt_" .. cat .. "_" .. key
                _G.Mod_GoodOpts[fullKey] = (val == true)
                pcall(function()
                    CS.UnityEngine.PlayerPrefs.SetInt(fullKey, val and 1 or 0)
                    CS.UnityEngine.PlayerPrefs.Save()
                end)
            end
            _G.Mod_SetGoodOpt = SetGoodOpt

            local function MatchGoodOpt(str, optKey)
                if not str then return false end
                local s = string.lower(str)
                if optKey == "atk2" then
                    return string.find(s, "tấn công") ~= nil and string.find(s, "2") ~= nil and string.find(s, "%%") ~= nil
                elseif optKey == "speed7" then
                    return string.find(s, "công tốc") ~= nil and string.find(s, "7") ~= nil
                elseif optKey == "crit10" then
                    return string.find(s, "trác việt") ~= nil and string.find(s, "10") ~= nil
                elseif optKey == "atk_lv20" then
                    return string.find(s, "cấp/20") ~= nil or (string.find(s, "tấn công") ~= nil and string.find(s, "cấp") ~= nil)
                elseif optKey == "hp4" then
                    return string.find(s, "hp tối đa") ~= nil and string.find(s, "4") ~= nil
                elseif optKey == "def10" then
                    return string.find(s, "phòng ngự") ~= nil and string.find(s, "10") ~= nil
                elseif optKey == "reflect5" then
                    return string.find(s, "phản") ~= nil and string.find(s, "5") ~= nil
                elseif optKey == "gold10" then
                    return string.find(s, "vàng") ~= nil and string.find(s, "10") ~= nil
                elseif optKey == "speed2" then
                    return string.find(s, "công tốc") ~= nil and string.find(s, "2") ~= nil
                elseif optKey == "atk1" then
                    return string.find(s, "tấn công") ~= nil and string.find(s, "1") ~= nil and string.find(s, "%%") ~= nil
                elseif optKey == "crit3" then
                    return string.find(s, "trác việt") ~= nil and string.find(s, "3") ~= nil
                elseif optKey == "reflect4" then
                    return string.find(s, "phản") ~= nil and string.find(s, "4") ~= nil
                elseif optKey == "dmgred2" then
                    return (string.find(s, "giảm") ~= nil or string.find(s, "st giảm") ~= nil or string.find(s, "sát thương giảm") ~= nil) and string.find(s, "2") ~= nil
                elseif optKey == "hp3" then
                    return string.find(s, "hp") ~= nil and string.find(s, "3") ~= nil
                elseif optKey == "def5" then
                    return string.find(s, "phòng ngự") ~= nil and string.find(s, "5") ~= nil
                elseif optKey == "gold5" then
                    return string.find(s, "vàng") ~= nil and string.find(s, "5") ~= nil
                elseif optKey == "dmgred4" then
                    return (string.find(s, "giảm") ~= nil or string.find(s, "st giảm") ~= nil or string.find(s, "sát thương giảm") ~= nil) and string.find(s, "4") ~= nil
                elseif optKey == "speed3" then
                    return string.find(s, "công tốc") ~= nil and string.find(s, "3") ~= nil
                elseif optKey == "def4" then
                    return string.find(s, "phòng ngự") ~= nil and string.find(s, "4") ~= nil
                elseif optKey == "reflect2" then
                    return string.find(s, "phản") ~= nil and string.find(s, "2") ~= nil
                end
                return false
            end
            _G.Mod_MatchGoodOpt = MatchGoodOpt

            _G.Mod_IsGoodItem = function(item, subType, tier, excDesList)
                -- 0. Ưu tiên bảo vệ tuyệt đối: Đồ đã cường hóa, gia cường, tái sinh, khảm ngọc
                if IsEnhancedEquip(item) then
                    return true -- Luôn coi là đồ ngon, TUYỆT ĐỐI KHÔNG TÁCH & KHÔNG THU HỒI
                end

                if not excDesList or #excDesList == 0 then
                    return false
                end

                -- =========================================================================
                -- [MOD FEATURE]: PHÂN LOẠI & LỌC ĐỒ TRÁC VIỆT / ĐỒ BỘ
                -- Mô tả:
                -- 1. NHÓM ĐỒ ĐEO TRÁC VIỆT (Vũ khí & Trang phục đeo):
                --    - Không ghép dòng được, dùng để mặc trực tiếp.
                --    - Quy tắc: Chỉ cần có bộ đôi thỏa mãn (1 dòng chính + 1 dòng phụ) trên 2 dòng bất kỳ
                --      là GIỮ LẠI (ví dụ: đồ có 4 dòng, có atk2 + speed7 hoặc atk2 + crit10 là giữ).
                --      Các dòng còn lại trên đồ (kể cả dòng rác) KHÔNG tính là rác, đồ vẫn ĐƯỢC GIỮ!
                -- 2. NHÓM TRANG SỨC TRÁC VIỆT & TẤT CẢ ĐỒ BỘ (Vũ khí bộ, Quần áo bộ, Trang sức bộ):
                --    - Ghép được dòng (hợp thành/kế thừa dòng khi rèn).
                --    - Quy tắc Thuần Khiết (Pure Opts): TẤT CẢ các dòng có trên món đồ PHẢI nằm
                --      trong danh sách quy định (được tick chọn).
                --    - Dính BẤT KỲ dòng nào ngoài danh sách quy định -> COI LÀ RÁC (Tách/Thu hồi ngay)!
                -- =========================================================================

                -- NHÓM 1: ĐỒ ĐEO TRÁC VIỆT (Vũ khí & Trang phục / Quần áo)
                local isWeaponTV = ((subType >= 1 and subType <= 12) or subType == 24 or subType == 25 or subType == 56 or subType == 57 or subType == 81)
                local isArmorTV = (subType >= 13 and subType <= 17)

                if isWeaponTV then
                    local mainKeys = { "atk2", "speed7", "crit10", "atk_lv20" }
                    local subKeys = { "atk2", "speed7", "crit10", "atk_lv20" }
                    local activeMain = {}
                    local activeSub = {}
                    for _, k in ipairs(mainKeys) do
                        if GetGoodOpt("EquipTV_Weapon_Main", k) then table.insert(activeMain, k) end
                    end
                    for _, k in ipairs(subKeys) do
                        if GetGoodOpt("EquipTV_Weapon_Sub", k) then table.insert(activeSub, k) end
                    end

                    -- Safe fallback:
                    if #activeMain == 0 and #activeSub == 0 then
                        return true -- Không tick gì -> Bảo vệ toàn bộ đồ
                    elseif #activeMain > 0 and #activeSub == 0 then
                        -- Người chơi chỉ chọn dòng chính -> Có ít nhất 1 dòng chính là giữ
                        for _, des in ipairs(excDesList) do
                            for _, mKey in ipairs(activeMain) do
                                if MatchGoodOpt(des, mKey) then return true end
                            end
                        end
                        return false
                    elseif #activeMain == 0 and #activeSub > 0 then
                        -- Người chơi chỉ chọn dòng phụ -> Có ít nhất 1 dòng phụ là giữ
                        for _, des in ipairs(excDesList) do
                            for _, sKey in ipairs(activeSub) do
                                if MatchGoodOpt(des, sKey) then return true end
                            end
                        end
                        return false
                    end

                    if #excDesList < 2 then return false end

                    -- Cần ít nhất 1 dòng chính VÀ 1 dòng phụ (trên 2 dòng khác nhau của món đồ).
                    -- Các dòng còn lại trên đồ (dù là dòng rác) KHÔNG ảnh hưởng, đồ vẫn ĐƯỢC GIỮ!
                    for i = 1, #excDesList do
                        local matchMain = false
                        for _, mKey in ipairs(activeMain) do
                            if MatchGoodOpt(excDesList[i], mKey) then
                                matchMain = true
                                break
                            end
                        end
                        if matchMain then
                            for j = 1, #excDesList do
                                if i ~= j then
                                    for _, sKey in ipairs(activeSub) do
                                        if MatchGoodOpt(excDesList[j], sKey) then
                                            return true -- Đạt chuẩn 1 dòng chính + 1 dòng phụ -> Đồ ngon (GIỮ)!
                                        end
                                    end
                                end
                            end
                        end
                    end
                    return false
                end

                if isArmorTV then
                    local mainKeys = { "hp4", "def10", "reflect5", "gold10" }
                    local subKeys = { "hp4", "def10", "reflect5", "gold10" }
                    local activeMain = {}
                    local activeSub = {}
                    for _, k in ipairs(mainKeys) do
                        if GetGoodOpt("EquipTV_Armor_Main", k) then table.insert(activeMain, k) end
                    end
                    for _, k in ipairs(subKeys) do
                        if GetGoodOpt("EquipTV_Armor_Sub", k) then table.insert(activeSub, k) end
                    end

                    -- Safe fallback:
                    if #activeMain == 0 and #activeSub == 0 then
                        return true
                    elseif #activeMain > 0 and #activeSub == 0 then
                        for _, des in ipairs(excDesList) do
                            for _, mKey in ipairs(activeMain) do
                                if MatchGoodOpt(des, mKey) then return true end
                            end
                        end
                        return false
                    elseif #activeMain == 0 and #activeSub > 0 then
                        for _, des in ipairs(excDesList) do
                            for _, sKey in ipairs(activeSub) do
                                if MatchGoodOpt(des, sKey) then return true end
                            end
                        end
                        return false
                    end

                    if #excDesList < 2 then return false end

                    -- Cần ít nhất 1 dòng chính VÀ 1 dòng phụ (trên 2 dòng khác nhau).
                    -- Các dòng khác không tính là rác, đồ vẫn ĐƯỢC GIỮ!
                    for i = 1, #excDesList do
                        local matchMain = false
                        for _, mKey in ipairs(activeMain) do
                            if MatchGoodOpt(excDesList[i], mKey) then
                                matchMain = true
                                break
                            end
                        end
                        if matchMain then
                            for j = 1, #excDesList do
                                if i ~= j then
                                    for _, sKey in ipairs(activeSub) do
                                        if MatchGoodOpt(excDesList[j], sKey) then
                                            return true -- Đạt chuẩn 1 dòng chính + 1 dòng phụ -> Đồ ngon (GIỮ)!
                                        end
                                    end
                                end
                            end
                        end
                    end
                    return false
                end

                -- =====================================================================
                -- NHÓM 2: TRANG SỨC TRÁC VIỆT (Nhẫn 18, Dây chuyền 19, Khuyên tai 26)
                -- Quy tắc Thuần Khiết: CHỈ ĐƯỢC PHÉP CÓ các dòng đã chọn. Dính dòng khác -> Tách!
                -- =====================================================================
                local checkPureOpts = nil
                if subType == 18 then
                    local allKeys = { "speed2", "atk1", "crit3", "atk_lv20" }
                    checkPureOpts = {}
                    for _, k in ipairs(allKeys) do
                        if GetGoodOpt("JewelryTV_Ring", k) then table.insert(checkPureOpts, k) end
                    end
                elseif subType == 19 then
                    local allKeys = { "speed2", "atk1", "crit3", "atk_lv20" }
                    checkPureOpts = {}
                    for _, k in ipairs(allKeys) do
                        if GetGoodOpt("JewelryTV_Necklace", k) then table.insert(checkPureOpts, k) end
                    end
                elseif subType == 26 then
                    local allKeys = { "reflect4", "dmgred2", "hp3", "def5", "gold5" }
                    checkPureOpts = {}
                    for _, k in ipairs(allKeys) do
                        if GetGoodOpt("JewelryTV_Earring", k) then table.insert(checkPureOpts, k) end
                    end

                -- =========================================================================
                -- NHÓM 3: ĐỒ BỘ (Vũ khí, Trang phục, Nhẫn/DC, Khuyên)
                -- Quy tắc Thuần Khiết: CHỈ ĐƯỢC PHÉP CÓ các dòng đã chọn. Dính dòng khác -> Tách!
                -- =========================================================================
                elseif (subType >= 101 and subType <= 112) or subType == 124 or subType == 125 or subType == 156 or subType == 157 or subType == 181 then
                    -- Vũ khí Bộ
                    local allKeys = { "atk2", "speed7", "crit10", "atk_lv20" }
                    checkPureOpts = {}
                    for _, k in ipairs(allKeys) do
                        if GetGoodOpt("Set_Weapon", k) then table.insert(checkPureOpts, k) end
                    end
                elseif subType >= 113 and subType <= 117 then
                    -- Trang phục Bộ (Mũ, Áo, Quần, Găng, Giày)
                    local allKeys = { "dmgred4", "hp4", "def10", "reflect5", "gold10" }
                    checkPureOpts = {}
                    for _, k in ipairs(allKeys) do
                        if GetGoodOpt("Set_Armor", k) then table.insert(checkPureOpts, k) end
                    end
                elseif subType == 35 or subType == 36 or subType == 38 then
                    -- Nhẫn, Dây chuyền Bộ
                    local allKeys = { "atk2", "speed3" }
                    checkPureOpts = {}
                    for _, k in ipairs(allKeys) do
                        if GetGoodOpt("Set_RingNecklace", k) then table.insert(checkPureOpts, k) end
                    end
                elseif subType == 34 or subType == 37 then
                    -- Khuyên Bộ
                    local allKeys = { "hp3", "def4", "reflect2", "gold10" }
                    checkPureOpts = {}
                    for _, k in ipairs(allKeys) do
                        if GetGoodOpt("Set_Earring", k) then table.insert(checkPureOpts, k) end
                    end
                end

                if checkPureOpts ~= nil then
                    -- Safe fallback: Nếu người chơi bỏ chọn hết -> BẢO VỆ ĐỒ, không tách!
                    if #checkPureOpts == 0 then
                        return true
                    end

                    -- QUY TẮC THUẦN KHIẾT: Vì ghép được dòng, nên mọi dòng trên đồ PHẢI nằm trong danh sách chọn.
                    -- Nếu có BẤT KỲ dòng nào ngoài danh sách quy định -> COI LÀ RÁC (Tách/Thu hồi)!
                    for _, des in ipairs(excDesList) do
                        local isValid = false
                        for _, k in ipairs(checkPureOpts) do
                            if MatchGoodOpt(des, k) then
                                isValid = true
                                break
                            end
                        end
                        if not isValid then
                            return false -- Dính dù chỉ 1 dòng ngoài danh sách quy định -> TÁCH!
                        end
                    end
                    return true -- 100% các dòng đều thuộc danh sách quy định -> ĐỒ NGON (GIỮ LẠI GHÉP DÒNG)!
                end

                return false
            end

            -- 1. Hàm phát gói mạng hút sạch vật phẩm
            local function PerformVacuumItems()
                pcall(function()
                    if _G.Mod_GoldenChestBatchIds and #_G.Mod_GoldenChestBatchIds > 0 then
                        if _G.PickupManager and _G.PickupManager.ReqPickUpMapItems then
                            _G.PickupManager.ReqPickUpMapItems(_G.Mod_GoldenChestBatchIds)
                        elseif _G.networkRequest and _G.networkRequest.ReqPickUpMapItems then
                            _G.networkRequest.ReqPickUpMapItems(_G.Mod_GoldenChestBatchIds)
                        end
                    end
                end)
            end
            _G.Mod_PerformVacuumItems = PerformVacuumItems

            -- 2. Hàm lọc & Thu hồi đồ rác Trác Việt (Quần Áo / Vũ Khí rác không đạt 2 dòng VIP)
            local function PerformBagRecycle()
                pcall(function()
                    PerformVacuumItems()

                    local updatedItems = _G.BagInfoData and _G.BagInfoData.TotalItems
                    if not updatedItems and _G.BagInfoData and _G.BagInfoData.GetTotalItems then
                        pcall(function() updatedItems = _G.BagInfoData:GetTotalItems() end)
                    end
                    if updatedItems then
                        local recycleMap = {}
                        local recycleCount = 0
                        for k, item in pairs(updatedItems) do
                            if item then
                                local tblItem = item.tblItem or (item.data and item.data.tblItem) or {}
                                local tblEquip = item.tblEquip or (item.data and item.data.tblEquip) or {}
                                local itemType = tblItem.type or 0
                                local itemId = tblItem.id or item.itemId or (item.data and item.data.itemId) or 0
                                local subType = tblItem.subType or 0
                                local itemCount = item.count or (item.data and item.data.count) or 1

                                if itemType == 2 or (tblEquip and tblEquip.id) then
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

                                    if _G.RoleEquipUtility then
                                        if rawExc and _G.RoleEquipUtility.GetEquipExcellence then
                                            pcall(function() excDesList = _G.RoleEquipUtility.GetEquipExcellence(rawExc, tblEquip) end)
                                        end
                                        if (#excDesList == 0) and _G.RoleEquipUtility.GetEquipExcellenceDesByServerInfo then
                                            pcall(function() excDesList = _G.RoleEquipUtility.GetEquipExcellenceDesByServerInfo(sInfo) end)
                                        end
                                    end
                                    if (#excDesList == 0) and item.GetEquipExcellenceDesList then
                                        pcall(function() excDesList = item:GetEquipExcellenceDesList() end)
                                    end

                                    local name = tblItem.name or item.name or ""
                                    local isExcellenceItem = (string.find(name, "Trác Việt") ~= nil) or (#excDesList > 0)

                                    local isArmor = (subType >= 13 and subType <= 17)
                                    local isWeapon = ((subType >= 1 and subType <= 12) or subType == 24 or subType == 25 or subType == 56 or subType == 57 or subType == 81)
                                    local isSmeltOrJewelry = (subType >= 100) or (subType == 18 or subType == 19 or subType == 20 or subType == 21 or subType == 22 or subType == 26 or (subType >= 34 and subType <= 38))

                                    local isGood = false
                                    -- =========================================================================
                                    -- [MOD FEATURE]: BẢO VỆ ĐỒ ĐÃ CƯỜNG HÓA / GIA CƯỜNG KHỎI THU HỒI TÚI ĐỒ
                                    -- =========================================================================
                                    if IsEnhancedEquip(item) then
                                        isGood = true -- Đã cường hóa -> Tuyệt đối giữ lại, không thu hồi
                                    elseif isSmeltOrJewelry or not isExcellenceItem then
                                        isGood = true
                                    elseif isArmor or isWeapon then
                                        isGood = _G.Mod_IsGoodItem and _G.Mod_IsGoodItem(item, subType, 0, excDesList)
                                    else
                                        isGood = true
                                    end

                                    local GUID = item.id or (item.data and item.data.id)
                                    if not isGood and GUID then
                                        recycleMap[GUID] = itemCount
                                        recycleCount = recycleCount + 1
                                    end
                                end
                            end
                        end

                        if recycleCount > 0 then
                            if _G.networkRequest and _G.networkRequest.ReqItemRecycle then
                                local RecycleWayType = _G.RecycleWayType and _G.RecycleWayType.Bag or 1
                                pcall(function() _G.networkRequest.ReqItemRecycle(recycleMap, RecycleWayType) end)
                                if _G.FloatingWordUtility and _G.FloatingWordUtility.QuickMsg then
                                    _G.FloatingWordUtility.QuickMsg("Đã thu hồi " .. tostring(recycleCount) .. " món Trác Việt rác!")
                                end
                            end
                        end
                    end
                end)
            end
            _G.Mod_PerformBagRecycle = PerformBagRecycle

            _G.Mod_ExecuteAutoSmelt = function()
                local items = _G.BagInfoData and _G.BagInfoData.TotalItems
                if not items then return end

                local recycleItems = {}
                for k, item in pairs(items) do
                    if item then
                        local tblItem = item.tblItem or (item.data and item.data.tblItem) or {}
                        local tblEquip = item.tblEquip or (item.data and item.data.tblEquip) or {}
                        local itemType = tblItem.type or 0
                        local itemId = tblItem.id or item.itemId or (item.data and item.data.itemId) or 0
                        local subType = tblItem.subType or 0
                        local quality = tblItem.quality or 0
                        local needLevel = tblItem.needLevel or 0
                        local tier = math.floor(needLevel / 400)

                        -- CHỈ XỬ LÝ KHI LÀ TRANG BỊ (itemType == 2) HOẶC CÓ CẤU HÌNH EQUIP
                        if itemType == 2 or (tblEquip and tblEquip.id) then
                            if (not tblEquip or not tblEquip.suitId) and itemId > 0 and _G.ClientTable and _G.ClientTable.cfg_Item_equipManager then
                                pcall(function()
                                    local eq = _G.ClientTable.cfg_Item_equipManager:TryGetValue(itemId)
                                    if eq then tblEquip = eq end
                                end)
                            end
                            tblEquip = tblEquip or {}

                            local prefix = nil
                            if subType == 35 then
                                prefix = "RingL"
                            elseif subType == 38 then
                                prefix = "RingR"
                            elseif subType == 36 then
                                prefix = "Necklace2"
                            elseif subType == 34 then
                                prefix = "EarringL"
                            elseif subType == 37 then
                                prefix = "EarringR"
                            elseif subType == 113 then
                                prefix = "Hat"
                            elseif subType == 114 then
                                prefix = "Armor"
                            elseif subType == 115 then
                                prefix = "Pants"
                            elseif subType == 116 then
                                prefix = "Gloves"
                            elseif subType == 117 then
                                prefix = "Boots"
                            elseif (subType >= 101 and subType <= 112) or subType == 124 or subType == 125 or subType == 156 or subType == 157 or subType == 181 then
                                prefix = "Weapon"
                            end

                            local shouldSmelt = false

                            -- 1. Cấu hình Tách Đồ Trác Việt (Ring_C..., Necklace_C..., Earring_C...)
                            if _G.Mod_SmeltConfig then
                                if subType == 18 then
                                    local varName = "Ring_C" .. tostring(quality)
                                    if _G.Mod_SmeltConfig[varName] then
                                        shouldSmelt = true
                                    end
                                elseif subType == 19 then
                                    local varName = "Necklace_C" .. tostring(quality)
                                    if _G.Mod_SmeltConfig[varName] then
                                        shouldSmelt = true
                                    end
                                elseif subType == 26 then
                                    local varName = "Earring_C" .. tostring(quality)
                                    if _G.Mod_SmeltConfig[varName] then
                                        shouldSmelt = true
                                    end
                                end

                                -- 2. Cấu hình Tách Đồ Bộ theo SubType & Tier (Không áp dụng cho Trang Sức Trác Việt 18, 19, 26)
                                if prefix and tier >= 3 and tier <= 12 then
                                    local varName = prefix .. "_C" .. tostring(tier)
                                    if _G.Mod_SmeltConfig[varName] then
                                        shouldSmelt = true
                                    end
                                end

                                -- 3. Bộ lọc [Giữ dòng Ngon]
                                -- =========================================================================
                                -- [MOD FEATURE]: TÁCH BIỆT GIỮ DÒNG NGON TRÁC VIỆT VÀ ĐỒ BỘ
                                -- Mô tả: Trang Sức Trác Việt (18, 19, 26) dùng cấu hình KeepGoodTV_C... riêng biệt;
                                --        Đồ Bộ dùng cấu hình KeepGood_C...
                                -- =========================================================================
                                if shouldSmelt then
                                    local isJewelryTracViet = (subType == 18 or subType == 19 or subType == 26)
                                    local keepGoodVar = nil
                                    local evalTier = tier
                                    if isJewelryTracViet then
                                        local tvTier = (quality and quality > 0) and quality or tier
                                        evalTier = tvTier
                                        if tvTier and tvTier >= 3 and tvTier <= 12 then
                                            keepGoodVar = "KeepGoodTV_C" .. tostring(tvTier)
                                        end
                                    else
                                        if tier and tier >= 3 and tier <= 12 then
                                            keepGoodVar = "KeepGood_C" .. tostring(tier)
                                        end
                                    end

                                    if keepGoodVar then
                                        if _G.Mod_SmeltConfig and _G.Mod_SmeltConfig[keepGoodVar] == nil then
                                            pcall(function()
                                                _G.Mod_SmeltConfig[keepGoodVar] = (CS.UnityEngine.PlayerPrefs.GetInt("Mod_Smelt_" .. keepGoodVar, 1) == 1)
                                            end)
                                            if _G.Mod_SmeltConfig[keepGoodVar] == nil then _G.Mod_SmeltConfig[keepGoodVar] = true end
                                        end
                                    end

                                    if keepGoodVar and _G.Mod_SmeltConfig and _G.Mod_SmeltConfig[keepGoodVar] then
                                        local excDesList = {}
                                        local sInfo = item.serverInfo or item.serverData or {}
                                        local rawExc = item.excellence or sInfo.excellentList or sInfo.excellentInfo or
                                            sInfo.excellentAttrs

                                        if _G.RoleEquipUtility then
                                            if rawExc and _G.RoleEquipUtility.GetEquipExcellence then
                                                pcall(function()
                                                    excDesList = _G.RoleEquipUtility.GetEquipExcellence(rawExc,
                                                        tblEquip)
                                                end)
                                            end
                                            if (#excDesList == 0) and _G.RoleEquipUtility.GetEquipExcellenceDesByServerInfo then
                                                pcall(function()
                                                    excDesList = _G.RoleEquipUtility
                                                        .GetEquipExcellenceDesByServerInfo(sInfo)
                                                end)
                                            end
                                        end
                                        if (#excDesList == 0) and item.GetEquipExcellenceDesList then
                                            pcall(function() excDesList = item:GetEquipExcellenceDesList() end)
                                        end

                                        local isGood = _G.Mod_IsGoodItem and _G.Mod_IsGoodItem(item, subType, evalTier, excDesList)
                                        if isGood then
                                            shouldSmelt = false -- GIỮ LẠI TRONG TÚI
                                        end
                                    end
                                end
                            end

                            -- Bảo vệ tuyệt đối: Đồ đã cường hóa/gia cường không bao giờ bị tách
                            if IsEnhancedEquip(item) then
                                shouldSmelt = false
                            end

                            if shouldSmelt and item.id then
                                table.insert(recycleItems, item.id)
                            end
                        end
                    end
                end

                if #recycleItems > 0 then
                    local batch = {}
                    local batchSize = 0
                    for i, id in ipairs(recycleItems) do
                        table.insert(batch, id)
                        batchSize = batchSize + 1
                        if batchSize >= 4 or i == #recycleItems then
                            if _G.networkRequest and _G.networkRequest.ReqEquipDecompose then
                                _G.networkRequest.ReqEquipDecompose(batch)
                                LogMsg("Đã gửi yêu cầu tách " .. tostring(batchSize) .. " món trang bị!")
                            end
                            batch = {}
                            batchSize = 0
                        end
                    end
                end
            end

            _G.Mod_AutoFarmBoss_Update = function()
                if not _G.Mod_IsActive then
                    SetBossState(0, "Mod chưa Active")
                    _G.Mod_AutoFarmBoss_Target = nil
                    return
                end

                if not _G.Mod_AutoFarmBoss_Enabled then
                    if _G.Mod_AutoFarmBoss_State ~= 0 then
                        SetBossState(0, "Tắt Auto Farm")
                        _G.Mod_AutoFarmBoss_Target = nil
                        pcall(function()
                            if _G.PathFinderManager and _G.PathFinderManager.ResetData then
                                _G.PathFinderManager.ResetData()
                            end
                            if _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.StopMove then
                                _G.RoleManager.me:StopMove()
                            end
                        end)
                        LogMsg("Đã TẮT Auto Farm.")
                    end
                    return
                end

                local currentMapId = _G.SceneData and _G.SceneData.mapId
                local currentSec = _G.Time.GetServerSecondTime and _G.Time.GetServerSecondTime() or os.time()
                local nowRealtime = (CS.UnityEngine.Time and CS.UnityEngine.Time.realtimeSinceStartup) or os.clock()

                if currentMapId ~= 240001 then
                    _G.Mod_MapAn_Recorded = false
                    _G.Mod_MapAn_SkillsApplied = false
                    if _G.Mod_RestoreMapAnSkills then
                        _G.Mod_RestoreMapAnSkills()
                    end
                end

                -- PRIORITY 0: BOSS ẨN
                if _G.UIManager and _G.UIManager.IsVisible then
                    if _G.UIManager.IsVisible("Tip_MonsterTipUI") then
                        if _G.Mod_AutoFarmBoss_State == 5 or _G.Mod_AutoFarmBoss_State == 6 then
                            -- Do nothing, let the state machine run below so it can finish picking up items
                        else
                            local tipUi = _G.UIManager.GetUiByName and _G.UIManager.GetUiByName("Tip_MonsterTipUI")
                            if tipUi and tipUi.DimensionalCracksData then
                                if _G.Mod_AutoFarmBoss_EnterHiddenMap then
                                    local costType = _G.Mod_AutoFarmBoss_EnterHiddenMap_Diamond and 2 or 1
                                    local modeStr = _G.Mod_AutoFarmBoss_EnterHiddenMap_Diamond and "Kim Cương" or
                                        "Vàng/Thường"
                                    LogMsg("[BOSS ẨN] Phát hiện Cổng Map Ẩn! Triệu hồi chế độ " .. modeStr .. "...")
                                    if _G.networkRequest and _G.networkRequest.ReqCallBoss then
                                        _G.networkRequest.ReqCallBoss(tipUi.DimensionalCracksData.id,
                                            tipUi.DimensionalCracksData.mid, costType)
                                    end
                                    if _G.UIManager.Hide then _G.UIManager.Hide("Tip_MonsterTipUI") end

                                    SetBossState(0, "Vào Boss Ẩn")
                                    _G.Mod_AutoFarmBoss_Target = nil
                                    _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 5.0
                                else
                                    LogMsg("[BOSS ẨN] Tính năng Tự vào Map Ẩn đang TẮT")
                                    if _G.UIManager.Hide then _G.UIManager.Hide("Tip_MonsterTipUI") end
                                end
                            end
                            return
                        end
                    end
                end

                -- PRIORITY 1: THEO DÕI VÀ DỌN QUÁI TRONG MAP ẨN
                if _G.TranScriptData and _G.TranScriptData.InTranscript and currentMapId == 240001 then
                    if not _G.Mod_MapAn_Recorded then
                        _G.Mod_MapAn_Recorded = true
                        _G.Mod_MapAn_ClearTime = nil
                        _G.Mod_MapAn_LastScanTime = 0
                        _G.Mod_FarmStats = _G.Mod_FarmStats or { hidden = 0, bosses = {} }
                        _G.Mod_FarmStats.hidden = _G.Mod_FarmStats.hidden + 1
                        if _G.Mod_SaveFarmStats then _G.Mod_SaveFarmStats() end
                        if _G.ModRefreshAutoBossConfigUI then _G.ModRefreshAutoBossConfigUI() end
                        LogMsg("[MAP ẨN] Đã vào Map Ẩn! Ghi nhận thống kê +1 Map.")
                    end

                    if not _G.Mod_MapAn_SkillsApplied then
                        _G.Mod_MapAn_SkillsApplied = true
                        if _G.Mod_ApplyMapAnSkills then
                            _G.Mod_ApplyMapAnSkills()
                        end
                    end

                    if nowRealtime >= (_G.Mod_MapAn_LastScanTime or 0) + 1.0 then
                        _G.Mod_MapAn_LastScanTime = nowRealtime

                        local quaiThuong = 0
                        local quaiBoss = 0
                        local hpBoss = 0

                        if _G.RoleManager and _G.RoleManager.GetRolesByType then
                            local monsters = _G.RoleManager.GetRolesByType(2) or {}
                            local me = _G.RoleManager.me
                            local meId = me and me.data and me.data.id or 0
                            for _, role in pairs(monsters) do
                                if role and role.hp and role.hp > 0 then
                                    local isSummon = role.isSummon or (role.data and role.data.isSummon) or false
                                    local ownerId = role.ownerId or (role.data and role.data.ownerId) or role.masterId or
                                        0
                                    local isMySummon = (isSummon == true) or
                                        (ownerId ~= 0 and tostring(ownerId) == tostring(meId))

                                    local canAttack = true
                                    if _G.RoleTargetManager and _G.RoleTargetManager.GetCanAttackRole then
                                        canAttack = _G.RoleTargetManager.GetCanAttackRole(role)
                                    elseif isMySummon then
                                        canAttack = false
                                    end

                                    if canAttack and not isMySummon then
                                        quaiBoss = quaiBoss + 1
                                        hpBoss = role.hp
                                    end
                                end
                            end
                        end

                        _G.Mod_MapAn_LastQuaiThuong = quaiThuong
                        _G.Mod_MapAn_LastQuaiBoss = quaiBoss
                        _G.Mod_MapAn_LastHpBoss = hpBoss
                    end

                    local quaiThuong = _G.Mod_MapAn_LastQuaiThuong or 0
                    local quaiBoss = _G.Mod_MapAn_LastQuaiBoss or 0
                    local hpBoss = _G.Mod_MapAn_LastHpBoss or 0

                    if quaiBoss > 0 or quaiThuong > 0 then
                        _G.Mod_MapAn_ClearTime = nil

                        -- Log mỗi 5s độc lập với hàm Scan
                        if currentSec >= (_G.Mod_MapAn_LastLogTime or 0) + 5 then
                            LogMsg(string.format("[MAP ẨN] Boss: %d", quaiBoss))
                            _G.Mod_MapAn_LastLogTime = currentSec
                        end

                        if _G.RoleManager.me and _G.RoleManager.me.isAutoTaskFight and _G.RoleManager.me.isAutoTaskFight ~= "None" then
                            if _G.RoleManager.me.SetAutoTaskFight then
                                _G.RoleManager.me:SetAutoTaskFight("None")
                            end
                        end

                        if _G.RoleManager.me and _G.QiJiHelperData and not _G.QiJiHelperData.isAutoFight then
                            if _G.RoleManager.me.SetAutoFight then
                                _G.RoleManager.me:SetAutoFight("AutoFight")
                            end
                        end
                    else
                        if not _G.Mod_MapAn_ClearTime then
                            _G.Mod_MapAn_ClearTime = nowRealtime + 5.0
                            LogMsg("[MAP ẨN] Sạch bóng quân thù! Chờ 5s nhặt đồ rồi rời đi...")
                        elseif nowRealtime >= _G.Mod_MapAn_ClearTime then
                            if _G.RoleManager.me then
                                if _G.RoleManager.me.isAutoTaskFight and _G.RoleManager.me.isAutoTaskFight ~= "None" then
                                    if _G.RoleManager.me.SetAutoTaskFight then _G.RoleManager.me:SetAutoTaskFight("None") end
                                end
                                if _G.RoleManager.me.isAutoFight then
                                    if _G.RoleManager.me.SetAutoFight then _G.RoleManager.me:SetAutoFight("None") end
                                end
                                if _G.RoleManager.me.StopMove then _G.RoleManager.me:StopMove() end
                            end
                            if ExitDungeon() then
                                LogMsg("[MAP ẨN] Đã tắt Auto Fight và thoát phó bản Boss Ẩn thành công!")
                            end
                            _G.Mod_MapAn_ClearTime = nowRealtime + 10.0 -- Tránh spam lệnh
                        end
                    end
                    return -- DỪNG TẠI ĐÂY KHI ĐANG TRONG MAP ẨN, KHÔNG CHO CHẠY TIẾP XUỐNG LOGIC BOSS BÌNH THƯỜNG
                end

                if _G.Mod_AutoFarmBoss_LastState ~= _G.Mod_AutoFarmBoss_State or _G.Mod_AutoFarmBoss_LastMap ~= currentMapId then
                    local mapName = GetMapName(currentMapId)
                    --LogMsg(string.format("[FSM Tracker] State: %s | Map: %s (%s)", tostring(_G.Mod_AutoFarmBoss_State), tostring(currentMapId), mapName))
                    _G.Mod_AutoFarmBoss_LastState = _G.Mod_AutoFarmBoss_State
                    _G.Mod_AutoFarmBoss_LastMap = currentMapId
                end

                if nowRealtime < (_G.Mod_AutoFarmBoss_WaitTime or 0) then
                    -- Đột phá WaitTime: Nếu đang đợi về Lorencia mà đã load xong Map 1001, cho đi tiếp luôn!
                    if _G.Mod_AutoFarmBoss_State == 1 and currentMapId == 1001 then
                        SetBossState(2, "Đã ở Lorencia -> Lấy Data Boss")
                        _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                    end
                    return
                end

                local status, err = pcall(function()
                    -- STATE 0: BOOT & COMBAT CHECK
                    if _G.Mod_AutoFarmBoss_State == 0 then
                        local foundCombatBoss = nil
                        if _G.RoleManager and _G.RoleManager.GetRolesByType then
                            local monsterRoles = _G.RoleManager.GetRolesByType(2)
                            if monsterRoles then
                                for lid, role in pairs(monsterRoles) do
                                    local d = role.data
                                    local mId = d and (d.configId or d.monsterId or d.templateId)
                                    if mId and role.hp and role.hp > 0 then
                                        local function CheckList(list)
                                            if not list then return end
                                            for _, mCfg in ipairs(list) do
                                                if mCfg.mapId == currentMapId and mCfg.bosses then
                                                    for _, cfg in ipairs(mCfg.bosses) do
                                                        if tostring(mId) == tostring(cfg.id) and _G.Mod_AutoFarmBoss_Config[cfg.id] then
                                                            -- =========================================================================
                                                            -- [MOD FEATURE]: KIỂM TRA GIỚI HẠN SỐ LƯỢNG BOSS AUTO FARM
                                                            -- Mô tả: Bỏ qua boss nếu số lượng đã farm (killedCount) >= maxLimit.
                                                            -- =========================================================================
                                                            local killedCount = (_G.Mod_FarmStats and _G.Mod_FarmStats.bosses and _G.Mod_FarmStats.bosses[cfg.id]) or 0
                                                            local maxLimit = tonumber(_G.Mod_AutoFarmBoss_Limits and _G.Mod_AutoFarmBoss_Limits[cfg.id])
                                                            if not (maxLimit and maxLimit > 0 and killedCount >= maxLimit) then
                                                                return {
                                                                    cfg = cfg,
                                                                    mapCfg = mCfg,
                                                                    line = _G.SceneData and
                                                                        (_G.SceneData.line or _G.SceneData.cline) or 1
                                                                }
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        local currentTiers = GetAvailableTiers and GetAvailableTiers() or { "C6", "C7" }
                                        for _, tag in ipairs(currentTiers) do
                                            local mapsConfig = GetMapsConfigByTier and GetMapsConfigByTier(tag)
                                            if mapsConfig then
                                                foundCombatBoss = CheckList(mapsConfig)
                                                if foundCombatBoss then break end
                                            end
                                        end
                                        if foundCombatBoss then break end
                                    end
                                end
                            end
                        end

                        if foundCombatBoss then
                            LogMsg("Đang ở cạnh Boss " .. tostring(foundCombatBoss.cfg.name) .. ", đập luôn!")
                            _G.Mod_AutoFarmBoss_Target = foundCombatBoss
                            SetBossState(5, "Đang ở cạnh Boss -> Combat")
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                        else
                            LogMsg("Bắt đầu lấy dữ liệu Boss...")
                            SetBossState(2, "Khởi động -> Lấy Data Boss")
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                        end

                        -- STATE 1: IDLE / RETURN HOME (Lorencia)
                    elseif _G.Mod_AutoFarmBoss_State == 1 then
                        if currentMapId == 1001 then
                            SetBossState(2, "Đang ở Lorencia -> Lấy Data Boss")
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                            return
                        end

                        if ExitDungeon() then
                            LogMsg("Đang thoát phó bản...")
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 3.0
                            return
                        end

                        local foundScroll = false
                        if _G.BagInfoData and _G.BagInfoData.TotalItems then
                            for _, itemData in pairs(_G.BagInfoData.TotalItems) do
                                if itemData and itemData.itemId == 20000021 then
                                    if _G.networkRequest and _G.networkRequest.ReqUseItem then
                                        _G.networkRequest.ReqUseItem(1, itemData.id)
                                        foundScroll = true
                                    end
                                    break
                                end
                            end
                        end

                        if not foundScroll then
                            LogMsg("Không có Bùa Về Thành! Đợi 10s...")
                            -- =========================================================================
                            -- [MOD FEATURE]: CẢNH BÁO HẾT BÙA VỀ THÀNH TRONG AUTO BOSS
                            -- Mô tả: Hiển thị thông báo chữ đỏ ở giữa màn hình (FloatingTip) khi hết Bùa Về Thành
                            -- =========================================================================
                            local alertMsg = "<color=#FF0000>[AUTO BOSS] HẾT BÙA VỀ THÀNH! VUI LÒNG BỔ SUNG ĐỂ TIẾP TỤC!</color>"
                            if _G.FloatingTipUtility and _G.FloatingTipUtility.QuickMsg then
                                _G.FloatingTipUtility.QuickMsg(alertMsg)
                            elseif _G.FloatingWordUtility and _G.FloatingWordUtility.QuickMsg then
                                _G.FloatingWordUtility.QuickMsg(alertMsg)
                            end
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 10.0
                        else
                            LogMsg("Dùng Bùa Về Thành quay về Lorencia...")
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 5.0
                        end

                        -- STATE 2: FETCH DATA & FIND TARGET
                    elseif _G.Mod_AutoFarmBoss_State == 2 then
                        if currentSec > (_G.Mod_AutoFarmBoss_NextReqTime or 0) then
                            LogMsg("Gửi yêu cầu lấy Data Boss từ Server...")
                            if _G.NetManager and _G.MapMessage then
                                _G.NetManager.Send(_G.MapMessage.ReqGetBossMapAndCount)
                                _G.NetManager.Send(_G.MapMessage.ReqAncientBossInfo, { type = 16 })
                                _G.NetManager.Send(_G.MapMessage.ReqAncientBossInfo, { type = 17 })
                                _G.NetManager.Send(_G.MapMessage.ReqBossStateByType, { type = 1 })
                                _G.NetManager.Send(_G.MapMessage.ReqBossStateByType, { type = 2 })
                                _G.NetManager.Send(_G.MapMessage.ReqBossStateByType, { type = 3 })
                            end
                            _G.Mod_AutoFarmBoss_NextReqTime = currentSec + 15
                            _G.Mod_AutoFarmBoss_ReqSentTime = currentSec
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 2.0
                            return
                        end

                        if _G.Mod_MapBosses ~= _G.Mod_LastMapBossesRef then
                            _G.Mod_LastMapBossesRef = _G.Mod_MapBosses
                            _G.Mod_MapBosses_UpdateTime = currentSec
                        end

                        local timeSinceReq = currentSec - (_G.Mod_AutoFarmBoss_ReqSentTime or 0)
                        local dataFresh = (_G.Mod_MapBosses_UpdateTime and _G.Mod_MapBosses_UpdateTime >= (_G.Mod_AutoFarmBoss_ReqSentTime or 0))

                        if not dataFresh and timeSinceReq < 10 then
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                            return
                        elseif not dataFresh then
                            LogMsg("Server phản hồi chậm. Bắt buộc dùng Data cũ...")
                        end

                        local bestBoss = nil
                        local bestScore = -1
                        local mapBosses = _G.Mod_MapBosses or {}

                        local candidates = {}

                        local function CheckConfig(mapsConfig, tierIndex)
                            if not mapsConfig then return end
                            for mIdx, mapCfg in ipairs(mapsConfig) do
                                -- Map type priority: Hoang Dã (mIdx=1) > Trang Sức (mIdx=2) > Tháp/Cánh (mIdx=3) > Luyện Ngục (mIdx=4)
                                local mapPriority = (10 - math.min(mIdx, 9)) * 10000

                                if mapCfg.bosses then
                                    for bIdx, cfg in ipairs(mapCfg.bosses) do
                                        if _G.Mod_AutoFarmBoss_Config[cfg.id] == nil then
                                            _G.Mod_AutoFarmBoss_Config[cfg.id] = CS.UnityEngine.PlayerPrefs.GetInt("Mod_AutoBoss_" .. cfg.id, 0) == 1
                                        end
                                        if _G.Mod_AutoFarmBoss_Config[cfg.id] then
                                            -- =========================================================================
                                            -- [MOD FEATURE]: KIỂM TRA GIỚI HẠN SỐ LƯỢNG BOSS AUTO FARM
                                            -- Mô tả: Bỏ qua boss nếu số lượng đã farm (killedCount) >= maxLimit.
                                            -- =========================================================================
                                            local killedCount = (_G.Mod_FarmStats and _G.Mod_FarmStats.bosses and _G.Mod_FarmStats.bosses[cfg.id]) or 0
                                            local maxLimit = tonumber(_G.Mod_AutoFarmBoss_Limits and _G.Mod_AutoFarmBoss_Limits[cfg.id])
                                            local isLimitReached = (maxLimit and maxLimit > 0 and killedCount >= maxLimit)

                                            if not isLimitReached then
                                                local ignoreKey = cfg.id .. "_" .. mapCfg.mapId
                                                local ignoreUntil = _G.Mod_AutoFarmBoss_Ignore[ignoreKey] or 0
                                                if currentSec > ignoreUntil then
                                                    -- Col priority: Col 3 (LV cao nhất) = +300, Col 2 = +200, Col 1 = +100
                                                    local colVal = cfg.col or 1
                                                    local colPriority = math.min(colVal, 3) * 100

                                                    local bossData = mapBosses[mapCfg.mapId] and
                                                        mapBosses[mapCfg.mapId][cfg.id]
                                                    if bossData then
                                                        local bestLine = nil
                                                        local isAlive = false
                                                        local respawnWait = 9999

                                                        for _, lineNum in ipairs(bossData.lineNums) do
                                                            local totalAlive = bossData.aliveCount[lineNum] or 0
                                                            if totalAlive > 0 then
                                                                bestLine = lineNum
                                                                isAlive = true
                                                                respawnWait = 0
                                                                break
                                                            end

                                                            local deadList = bossData.deadTimes[lineNum] or {}
                                                            if not isAlive and #deadList > 0 then
                                                                local rt = deadList[1]
                                                                if rt <= currentSec + 30 then
                                                                    bestLine = lineNum
                                                                    respawnWait = math.max(0, rt - currentSec)
                                                                    break
                                                                end
                                                            end
                                                        end

                                                        if bestLine then
                                                            local aliveScore = isAlive and 1000000 or 0
                                                            local waitScore = (not isAlive) and math.max(0, (30 - respawnWait) * 100) or 0
                                                            local tierScore = tierIndex * 100000

                                                            local finalScore = aliveScore + tierScore + mapPriority + colPriority + waitScore

                                                            if currentMapId == mapCfg.mapId and (_G.SceneData and _G.SceneData.lineIndex == bestLine) then
                                                                finalScore = finalScore + 5000
                                                            end

                                                            table.insert(candidates, {
                                                                name = cfg.name,
                                                                id = cfg.id,
                                                                score = finalScore,
                                                                isAlive = isAlive,
                                                                wait = respawnWait,
                                                                mapName = mapCfg.title or GetMapName(mapCfg.mapId),
                                                                mapId = mapCfg.mapId,
                                                                obj = { cfg = cfg, mapCfg = mapCfg, line = bestLine, isAlive = isAlive, wait = respawnWait }
                                                            })
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        if GetAvailableTiers then
                            for tIdx, tTag in ipairs(GetAvailableTiers()) do
                                CheckConfig(GetMapsConfigByTier(tTag), tIdx)
                            end
                        end

                        if #candidates > 0 then
                            table.sort(candidates, function(a, b) return a.score > b.score end)
                            bestBoss = candidates[1].obj
                            LogMsg("--- TOP 3 BOSSES SCORE ---")
                            for i = 1, math.min(3, #candidates) do
                                local c = candidates[i]
                                local st = c.isAlive and "SỐNG" or ("Chết (Còn " .. c.wait .. "s)")
                                LogMsg(string.format("%d. %s (ID:%s, Map:%s) | Điểm: %d | %s", i, c.name, c.id, c
                                    .mapName, c.score, st))
                            end
                        else
                            LogMsg("--- Không có Boss phù hợp Farm ---")
                            local countConfig = 0
                            local countNoData = 0
                            local function DebugConfig(mapsConfig)
                                if not mapsConfig then return end
                                for _, mapCfg in ipairs(mapsConfig) do
                                    if mapCfg.bosses then
                                        for _, cfg in ipairs(mapCfg.bosses) do
                                            if _G.Mod_AutoFarmBoss_Config[cfg.id] then
                                                countConfig = countConfig + 1
                                                local killedCount = (_G.Mod_FarmStats and _G.Mod_FarmStats.bosses and _G.Mod_FarmStats.bosses[cfg.id]) or 0
                                                local maxLimit = tonumber(_G.Mod_AutoFarmBoss_Limits and _G.Mod_AutoFarmBoss_Limits[cfg.id])
                                                if maxLimit and maxLimit > 0 and killedCount >= maxLimit then
                                                    LogMsg(string.format("- Bỏ qua: %s đã đạt giới hạn farm (%d/%d con)", cfg.name, killedCount, maxLimit))
                                                else
                                                    local ignoreKey = cfg.id .. "_" .. mapCfg.mapId
                                                    local ignoreUntil = _G.Mod_AutoFarmBoss_Ignore[ignoreKey] or 0
                                                    if currentSec <= ignoreUntil then
                                                        LogMsg(string.format("- Bỏ qua: %s (Map %s) đang bị Block %ds",
                                                            cfg.name, GetMapName(mapCfg.mapId), ignoreUntil - currentSec))
                                                    else
                                                        local bossData = mapBosses[mapCfg.mapId] and
                                                            mapBosses[mapCfg.mapId][cfg.id]
                                                        if not bossData then
                                                            countNoData = countNoData + 1
                                                        else
                                                            for _, lineNum in ipairs(bossData.lineNums) do
                                                                local totalAlive = bossData.aliveCount[lineNum] or 0
                                                                local deadList = bossData.deadTimes[lineNum] or {}
                                                                if totalAlive == 0 and #deadList > 0 then
                                                                    local rt = deadList[1]
                                                                    LogMsg(string.format(
                                                                        "- Từ chối: %s (Còn %ds nữa mới hồi sinh)", cfg.name,
                                                                        rt - currentSec))
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            if GetAvailableTiers then
                                for _, tTag in ipairs(GetAvailableTiers()) do
                                    local mapsConfig = GetMapsConfigByTier and GetMapsConfigByTier(tTag)
                                    if mapsConfig then
                                        DebugConfig(mapsConfig)
                                    end
                                end
                            end
                            --LogMsg(string.format("Tổng theo dõi: %d Boss. (Không có data từ Server cho %d Boss)", countConfig, countNoData))
                        end

                        local function Mod_PerformSmeltItems()
                            pcall(function()
                                if _G.Mod_ExecuteAutoSmelt then
                                    _G.Mod_ExecuteAutoSmelt()
                                end
                                if _G.Mod_PerformBagRecycle then
                                    _G.Mod_PerformBagRecycle()
                                end
                            end)
                        end
                        _G.Mod_PerformSmeltItems = Mod_PerformSmeltItems

                        local function Mod_PerformAutoTrainAndSmelt()
                            local isStillReturning, isChangingMap = false, false
                            pcall(function()
                                Mod_PerformSmeltItems()

                                local coordStr = _G.Mod_AutoReturnPos_Coords or _G.Mod_TrainCoord or ""

                                if coordStr and string.find(coordStr, "#") then
                                    local parts = {}
                                    for p in string.gmatch(coordStr, "[^#]+") do table.insert(parts, p) end
                                    local tx, ty = tonumber(parts[1]), tonumber(parts[2])

                                    if tx and ty then
                                        -- =========================================================================
                                        -- [MOD FEATURE]: QUAY LẠI VỊ TRÍ FARM
                                        -- Mô tả: Lấy mapId theo chuyển chính; dùng Ấn Dịch Chuyển khi cách > 70m (1 lần duy nhất) và PathFinder di chuyển tới bãi train;
                                        --        bật AutoFight chuẩn không trễ nhịp quái, tránh spam StopMove làm khựng đánh.
                                        -- =========================================================================
                                        local pLevel = _G.Mod_Config_Reincarnation_Primary or 7
                                        local tab = "C" .. tostring(pLevel)
                                        local mapsConfig = GetMapsConfigByTier and GetMapsConfigByTier(tab)
                                        if not mapsConfig or #mapsConfig == 0 then mapsConfig = _G.Mod_MapsConfig_c7 end
                                        local wildMapId = (mapsConfig and mapsConfig[1] and mapsConfig[1].mapId) or
                                            101096
                                        local wildTransferId = (_G.PathFinderManager and _G.PathFinderManager.GetTransIdByGroupId and _G.PathFinderManager.GetTransIdByGroupId(wildMapId)) or
                                            wildMapId
                                        local curMap = _G.SceneData and _G.SceneData.mapId or 0

                                        if curMap ~= wildMapId then
                                            _G.Mod_IsMovingToTrainPos = false
                                            _G.Mod_TrainArrivedAtPos = false
                                            _G.Mod_Train_DidUseStone = false
                                            if ExitDungeon() then
                                            elseif wildTransferId and _G.SceneController and _G.SceneController.OnReqTransferTransmitMap then
                                                _G.SceneController.OnReqTransferTransmitMap(nil,
                                                    { mapId = wildTransferId, line = 1, changeLine = true })
                                            elseif _G.PathFinderManager and _G.PathFinderManager.MoveToLinePos then
                                                _G.PathFinderManager.MoveToLinePos(wildMapId, { x = tx, y = ty },
                                                    wildTransferId, 1, nil, nil, nil, nil, true)
                                            end
                                            isStillReturning, isChangingMap = true, true
                                        else
                                            local pMe = _G.RoleManager and _G.RoleManager.me
                                            local meX, meY = 0, 0
                                            if pMe then
                                                if pMe.cellPos then
                                                    meX, meY = pMe.cellPos.x, pMe.cellPos.y
                                                elseif pMe.serverCoord then
                                                    meX, meY = pMe.serverCoord.x, pMe.serverCoord.y
                                                end
                                            end

                                            local dx = meX - tx
                                            local dy = meY - ty
                                            local dist = math.sqrt(dx * dx + dy * dy)

                                            if dist > 50 and not _G.Mod_Train_DidUseStone then
                                                _G.Mod_Train_DidUseStone = true
                                                _G.Mod_IsMovingToTrainPos = false
                                                _G.Mod_TrainArrivedAtPos = false
                                                local stoneBagId = nil
                                                if _G.BagInfoData and _G.BagInfoData.TotalItems then
                                                    for _, itemData in pairs(_G.BagInfoData.TotalItems) do
                                                        if itemData then
                                                            local itemId = itemData.itemId or
                                                                (itemData.data and itemData.data.itemId)
                                                            local instanceId = itemData.id or
                                                                (itemData.data and itemData.data.id)
                                                            if itemId == 20000022 then
                                                                stoneBagId = instanceId
                                                                break
                                                            end
                                                        end
                                                    end
                                                end

                                                if stoneBagId then
                                                    LogMsg(string.format("Cách bãi train %.1fm (>50m). Dùng Ấn Dịch Chuyển...", dist))
                                                    if _G.networkRequest and _G.networkRequest.ReqUseItem then
                                                        _G.networkRequest.ReqUseItem(1, stoneBagId)
                                                    elseif _G.BagInfoController and _G.BagInfoController.UseItemReq then
                                                        _G.BagInfoController.UseItemReq(1, stoneBagId, nil, 20000022)
                                                    end
                                                else
                                                    LogMsg(string.format("Cách bãi train %.1fm (>50m) nhưng hết Ấn Dịch Chuyển. Bắt đầu chạy bộ...", dist))
                                                    if _G.PathFinderManager and _G.PathFinderManager.JumpMapToMoveToPos and _G.SceneData then
                                                        local targetPosData = (_G.PathFinderManager.GetCalcPosData and _G.PathFinderManager.GetCalcPosData(coordStr)) or
                                                            (_G.Vector2 and _G.Vector2(tx, ty)) or { x = tx, y = ty }
                                                        _G.PathFinderManager.JumpMapToMoveToPos(_G.SceneData.groupId,
                                                            targetPosData, nil, nil, nil,
                                                            (Purpose and Purpose.None) or 0, nil, 1, true)
                                                        _G.Mod_IsMovingToTrainPos = true
                                                    end
                                                end
                                                isStillReturning, isChangingMap = true, false
                                            else
                                                local hasArrived = (dist <= 1.5)

                                                if not hasArrived then
                                                    local isMoving = pMe and pMe.IsMoving and pMe:IsMoving()
                                                    if not _G.Mod_IsMovingToTrainPos or not isMoving then
                                                        _G.Mod_IsMovingToTrainPos = true

                                                        local moved = false
                                                        if _G.PathFinderManager and _G.PathFinderManager.JumpMapToMoveToPos and _G.SceneData then
                                                            local targetPosData = (_G.PathFinderManager.GetCalcPosData and _G.PathFinderManager.GetCalcPosData(coordStr)) or
                                                                (_G.Vector2 and _G.Vector2(tx, ty)) or { x = tx, y = ty }
                                                            _G.PathFinderManager.JumpMapToMoveToPos(_G.SceneData.groupId,
                                                                targetPosData, nil, nil, nil,
                                                                (Purpose and Purpose.None) or 0, nil, 1, true)
                                                            moved = true
                                                        elseif pMe and pMe.MoveTo then
                                                            pMe:MoveTo({ x = tx, y = ty }, 0)
                                                            moved = true
                                                        end

                                                        if not moved then
                                                            _G.Mod_IsMovingToTrainPos = false
                                                        end
                                                    end
                                                    isStillReturning, isChangingMap = true, false
                                                else
                                                    local me = _G.RoleManager and _G.RoleManager.me
                                                    if not _G.Mod_TrainArrivedAtPos then
                                                        if me and me.StopMove then me:StopMove() end
                                                        _G.Mod_TrainArrivedAtPos = true
                                                    end
                                                    if me and me.SetAutoFight and (me.isAutoFight ~= "AutoFight" or not (_G.QiJiHelperData and _G.QiJiHelperData.isAutoFight)) then
                                                        me:SetAutoFight("AutoFight")
                                                    end
                                                    if _G.QiJiHelperData and _G.QiJiHelperData.SetAutoFightData and not _G.QiJiHelperData.isAutoFight then
                                                        _G.QiJiHelperData.SetAutoFightData(true)
                                                    end
                                                    _G.Mod_IsMovingToTrainPos = false
                                                    _G.Mod_Train_DidUseStone = false
                                                    isStillReturning, isChangingMap = false, false
                                                end
                                            end
                                        end
                                    end
                                end
                            end)
                            return isStillReturning, isChangingMap
                        end
                        _G.Mod_PerformAutoTrainAndSmelt = Mod_PerformAutoTrainAndSmelt

                        if bestBoss then
                            _G.Mod_AutoFarmBoss_Target = bestBoss
                            if _G.ModRefreshAutoBossConfigUI then _G.ModRefreshAutoBossConfigUI() end
                            if bestBoss.isAlive or (bestBoss.wait and bestBoss.wait <= 20) then
                                LogMsg(string.format("Bắt đầu săn: %s (Map: %s)", bestBoss.cfg.name,
                                    GetMapName(bestBoss.mapCfg.mapId)))
                                _G.Mod_AutoFarmBoss_Target = bestBoss
                                if _G.ModRefreshAutoBossConfigUI then _G.ModRefreshAutoBossConfigUI() end

                                _G.Mod_AutoFarmBoss_ReqIconSentMap = nil
                                _G.Mod_AutoFarmBoss_DidUseStone = false
                                _G.Mod_Train_DidUseStone = false
                                _G.Mod_TrainArrivedAtPos = false
                                SetBossState(3, string.format("Chọn Boss: %s", bestBoss.cfg.name or ""))
                                _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                            else
                                LogMsg(string.format("Chưa có Boss! Gần nhất: %s còn %ds", bestBoss.cfg.name,
                                    bestBoss.wait))
                                _G.Mod_AutoFarmBoss_Target = nil
                                if _G.ModRefreshAutoBossConfigUI then _G.ModRefreshAutoBossConfigUI() end

                                local trainCoord = _G.Mod_AutoReturnPos_Coords or _G.Mod_TrainCoord or ""
                                if bestBoss.wait and bestBoss.wait > 5 and trainCoord ~= "" then
                                    local isStillReturning, isChangingMap = Mod_PerformAutoTrainAndSmelt()
                                    if isChangingMap then
                                        _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 3.0
                                    elseif _G.Mod_Train_DidUseStone and isStillReturning then
                                        _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.2
                                    else
                                        _G.Mod_AutoFarmBoss_WaitTime = isStillReturning and (nowRealtime + 1.0) or
                                            (nowRealtime + 5.0)
                                    end
                                    return
                                else
                                    _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 5.0
                                end
                            end
                        else
                            _G.Mod_AutoFarmBoss_Target = nil
                            if _G.ModRefreshAutoBossConfigUI then _G.ModRefreshAutoBossConfigUI() end

                            local trainCoord = _G.Mod_AutoReturnPos_Coords or _G.Mod_TrainCoord or ""
                            if trainCoord ~= "" then
                                local isStillReturning, isChangingMap = Mod_PerformAutoTrainAndSmelt()
                                if isChangingMap then
                                    _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 3.0
                                else
                                    _G.Mod_AutoFarmBoss_WaitTime = isStillReturning and nowRealtime or (nowRealtime + 5.0)
                                end
                                return
                            elseif currentMapId == 1001 then
                                LogMsg("Không có Boss! Chờ ở Lorencia...")
                                _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 5.0
                                Mod_PerformSmeltItems()
                            else
                                if currentSec - (_G.Mod_AutoFarmBoss_ReqSentTime or 0) < 15 then
                                    LogMsg("Không có Boss quanh đây. Chờ check lại...")
                                    _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 5.0
                                else
                                    LogMsg("Hoàn toàn không có Boss! Rút về Lorencia")
                                    SetBossState(1, "Hết Boss -> Rút về Lorencia")
                                    _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                                end
                            end
                        end

                        -- =========================================================================
                        -- [MOD FEATURE]: STATE 3 - CHUYỂN CỔNG MAP & CHẠY BỘ TỚI BOSS (CUSTOMER THUẦN CHẠY BỘ)
                        -- Mô tả: Truyền tống vào CỔNG MAP, nhận Minimap Boss sống, chạy bộ 100% bằng MoveTo
                        -- =========================================================================
                    elseif _G.Mod_AutoFarmBoss_State == 3 then
                        local target = _G.Mod_AutoFarmBoss_Target
                        if not target then
                            LogMsg("[FSM] State 3: Target bị rỗng (nil) -> Chuyển về State 1 (Về thành)")
                            SetBossState(1, "State 3 Target nil")
                            return
                        end

                        if currentMapId ~= target.mapCfg.mapId and ExitDungeon() then
                            LogMsg("Đang thoát phó bản cũ trước khi di chuyển tới Boss mới...")
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 3.0
                            return
                        end

                        -- Bước A: Nếu chưa ở trong Map Boss hoặc sai Line -> Truyền tống vào CỔNG MAP của Map Boss
                        local currentLine = _G.SceneData and (_G.SceneData.line or _G.SceneData.cline or _G.SceneData.lineIndex) or 1
                        if currentMapId ~= target.mapCfg.mapId or (target.line and currentLine ~= target.line) then
                            LogMsg(string.format("Đang di chuyển tới Map Boss: %s, Line %d...",
                                GetMapName(target.mapCfg.mapId), target.line))
                            _G.Mod_AutoFarmBoss_ReqIconSentMap = nil

                            local transId = (_G.PathFinderManager and _G.PathFinderManager.GetTransIdByGroupId and _G.PathFinderManager.GetTransIdByGroupId(target.mapCfg.mapId)) or
                                target.mapCfg.mapId
                            if transId and _G.SceneController and _G.SceneController.OnReqTransferTransmitMap then
                                _G.SceneController.OnReqTransferTransmitMap(nil,
                                    { mapId = transId, line = target.line, changeLine = true })
                            elseif _G.PathFinderManager and _G.PathFinderManager.MoveToLinePos then
                                local initialPos = (target.cfg.posX and target.cfg.posY and { x = target.cfg.posX, y = target.cfg.posY }) or
                                    { x = 100, y = 100 }
                                _G.PathFinderManager.MoveToLinePos(target.mapCfg.mapId, initialPos, transId, target.line,
                                    nil, nil, nil, nil, true)
                            end

                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 3.0
                            return
                        end

                        -- Bước B1: Vừa vào Map Boss -> Gửi ReqBossIcon và chờ 2 giây để nạp dữ liệu Minimap vị trí Boss sống
                        if _G.Mod_AutoFarmBoss_ReqIconSentMap ~= currentMapId then
                            _G.Mod_AutoFarmBoss_ReqIconSentMap = currentMapId

                            -- =========================================================================
                            -- [MOD FEATURE]: JIGGLE +-1 Ô & RESET PATHFINDER KHI VỪA VÀO MAP BOSS
                            -- Mô tả: Ngay khi vừa truyền tống vào Map Boss / đổi Line, xóa sạch lộ trình
                            --        tìm đường cũ của PathFinder, dừng chuyển động và nhích nhẹ +-1 ô để
                            --        đồng bộ tọa độ, tránh hiện tượng bị game kéo ngược về điểm hồi sinh.
                            -- =========================================================================
                            pcall(function()
                                if _G.PathFinderManager then
                                    if _G.PathFinderManager.ResetData then _G.PathFinderManager.ResetData() end
                                    if _G.PathFinderManager.pathFinding then
                                        _G.PathFinderManager.pathFinding.isFind = false
                                        _G.PathFinderManager.pathFinding.curPath = nil
                                    end
                                end
                                local me = _G.RoleManager and _G.RoleManager.me
                                if me then
                                    if me.StopMove then me:StopMove() end
                                    if me.SetAutoFight then me:SetAutoFight("None") end
                                    if me.SetAutoTaskFight then me:SetAutoTaskFight("None") end
                                    if me.MoveTo then
                                        local meCell = me.cellPos or me.serverCoord
                                        local meX = meCell and meCell.x or (me.data and me.data.x) or 0
                                        local meY = meCell and meCell.y or (me.data and me.data.y) or 0
                                        if meX > 0 and meY > 0 then
                                            local dx = math.random(-1, 1)
                                            local dy = math.random(-1, 1)
                                            if dx == 0 and dy == 0 then dx = 1; dy = 1 end
                                            local targetCell = (CS.UnityEngine.Vector2Int and CS.UnityEngine.Vector2Int(meX + dx, meY + dy))
                                                or (_G.Vector2Int and _G.Vector2Int(meX + dx, meY + dy))
                                                or { x = meX + dx, y = meY + dy }
                                            me:MoveTo(targetCell, 0)
                                        end
                                    end
                                end
                                if _G.QiJiHelperData and _G.QiJiHelperData.SetAutoFightData then
                                    _G.QiJiHelperData.SetAutoFightData(false)
                                end
                            end)

                            if _G.SceneData and _G.SceneData.SetMiniMapData then
                                pcall(function()
                                    _G.SceneData.SetMiniMapData(_G.SceneData.mapId or target.mapCfg.mapId,
                                        _G.SceneData.groupId or target.mapCfg.mapId)
                                end)
                            end

                            if _G.NetManager and _G.NetManager.Send and _G.MapMessage and _G.MapMessage.ReqBossIcon then
                                pcall(function() _G.NetManager.Send(_G.MapMessage.ReqBossIcon) end)
                            end

                            LogMsg(string.format("Đã tới Map %s (Jiggle xóa lag)! Đang xin dữ liệu Minimap trạng thái Boss...",
                                GetMapName(target.mapCfg.mapId)))
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 2.0
                            return
                        end

                        -- Bước B2: Đọc vị trí Boss SỐNG từ Minimap
                        local alivePos, aliveCount, totalCandidates = nil, 0, 0
                        if _G.GetAliveBossPosition then
                            alivePos, aliveCount, totalCandidates = _G.GetAliveBossPosition(target.cfg.id, target.mapCfg.mapId)
                        end

                        if totalCandidates > 0 and aliveCount == 0 then
                            LogMsg(string.format("Minimap xác nhận tất cả điểm của Boss %s đã bị hạ. Trở về State 1...",
                                target.cfg.name or ""))
                            _G.Mod_AutoFarmBoss_Target = nil
                            SetBossState(1, "Minimap xác nhận Boss đã chết")
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                            return
                        end

                        target.currentPos = alivePos or
                            (target.cfg.posX and target.cfg.posY and { x = target.cfg.posX, y = target.cfg.posY }) or
                            (_G.GetBossPosition and _G.GetBossPosition(target.cfg.id, target.mapCfg.mapId))
                        local posLog = target.currentPos and
                            string.format("(%d, %d)", target.currentPos.x, target.currentPos.y) or "(cổng)"

                        -- =========================================================================
                        -- [MOD FEATURE]: TỰ ĐỘNG DÙNG ĐÁ DỊCH CHUYỂN MAP HOANG DÃ KHI CÁCH > 50M
                        -- Mô tả: Nếu ở Map Hoang Dã và cách Boss > 50m thì dùng Ấn Dịch Chuyển (20000022).
                        --        Chỉ thực hiện chạy bộ khi khoảng cách <= 50m (hoặc ở map phó bản).
                        -- =========================================================================
                        local px, py = nil, nil
                        if _G.RoleManager and _G.RoleManager.me then
                            local me = _G.RoleManager.me
                            if me.cellPos then
                                px, py = me.cellPos.x, me.cellPos.y
                            elseif me.serverCoord then
                                px, py = me.serverCoord.x, me.serverCoord.y
                            elseif me.GetPosition then
                                local p = me:GetPosition()
                                if p then px, py = math.floor(p.x), math.floor(p.z) end
                            elseif me.position then
                                px, py = math.floor(me.position.x), math.floor(me.position.z or me.position.y)
                            end
                        end

                        if px and py and target.currentPos and target.currentPos.x and target.currentPos.y then
                            local dx = px - target.currentPos.x
                            local dy = py - target.currentPos.y
                            local dist = math.sqrt(dx * dx + dy * dy)

                            -- Nhận diện Map Hoang Dã (không phải phó bản/transcript)
                            local mapTitle = target.mapCfg and target.mapCfg.title or ""
                            local isWildMap = string.find(mapTitle, "Hoang Dã") ~= nil
                            local inTranscript = (_G.TranScriptData and (_G.TranScriptData.InTranscript or (_G.TranScriptData.IsInTranscript and _G.TranScriptData.IsInTranscript()))) or false
                            if inTranscript then isWildMap = false end

                            -- Chỉ áp dụng dùng đá cho Map Hoang Dã khi cách mục tiêu > 50m
                            if isWildMap and dist > 50 then
                                local stoneBagId = nil
                                if _G.BagInfoData and _G.BagInfoData.TotalItems then
                                    for _, itemData in pairs(_G.BagInfoData.TotalItems) do
                                        if itemData then
                                            local itemId = itemData.itemId or (itemData.data and itemData.data.itemId)
                                            local instanceId = itemData.id or (itemData.data and itemData.data.id)
                                            if itemId == 20000022 then
                                                stoneBagId = instanceId
                                                break
                                            end
                                        end
                                    end
                                end

                                if stoneBagId then
                                    LogMsg(string.format("[Hoang Dã] Cách Boss %s %.1fm (>50m). Dùng Ấn Dịch Chuyển (20000022)...",
                                        target.cfg.name or "", dist))
                                    if _G.networkRequest and _G.networkRequest.ReqUseItem then
                                        _G.networkRequest.ReqUseItem(1, stoneBagId)
                                    elseif _G.BagInfoController and _G.BagInfoController.UseItemReq then
                                        _G.BagInfoController.UseItemReq(1, stoneBagId, nil, 20000022)
                                    end
                                    _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.2
                                    return
                                else
                                    LogMsg(string.format("[Hoang Dã] Cách Boss %s %.1fm (>50m) nhưng hết Ấn Dịch Chuyển. Bắt đầu chạy bộ!",
                                        target.cfg.name or "", dist))
                                end
                            elseif isWildMap and dist <= 50 then
                                LogMsg(string.format("[Hoang Dã] Đã tiếp cận Boss %s ở cự ly %.1fm (<=50m). Bắt đầu chạy bộ tới mục tiêu!",
                                    target.cfg.name or "", dist))
                            end
                        end

                        -- Bước B4: Chạy bộ tới tọa độ Boss (khi <= 50m hoặc ở map phó bản hoặc hết đá)
                        if alivePos then
                            LogMsg(string.format("Minimap báo Boss %s SỐNG tại %s! Đang chạy bộ tới mục tiêu...",
                                target.cfg.name or "", posLog))
                        else
                            LogMsg(string.format("Đang chạy bộ tới tọa độ Boss: %s %s, Line %d...",
                                GetMapName(target.mapCfg.mapId), posLog, target.line))
                        end

                        _G.Mod_AutoFarmBoss_ArrivedAtPos = false
                        local onArrive = function()
                            _G.Mod_AutoFarmBoss_ArrivedAtPos = true
                        end

                        local moved = false
                        if _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.MoveTo and target.currentPos then
                            local cellPos = { x = target.currentPos.x, y = target.currentPos.y }
                            _G.RoleManager.me:MoveTo(cellPos, 0, function(status)
                                _G.Mod_AutoFarmBoss_ArrivedAtPos = true
                            end)
                            moved = true
                        end

                        if not moved then
                            local targetVector = target.currentPos and Vector2(target.currentPos.x, target.currentPos.y) or
                                nil
                            if _G.PathFinderManager and _G.PathFinderManager.JumpMapToMoveToPos then
                                _G.PathFinderManager.JumpMapToMoveToPos(target.mapCfg.mapId, targetVector, nil,
                                    target.line, nil, (Purpose and Purpose.None) or 0, onArrive, 0, true)
                            elseif _G.JumpMapToPos and _G.JumpMapToPos.MapMoveToPos then
                                _G.JumpMapToPos.MapMoveToPos(target.mapCfg.mapId, targetVector, nil, target.line, nil,
                                    (Purpose and Purpose.None) or 0, onArrive)
                            end
                        end

                        SetBossState(4, "Đã gửi lệnh chạy bộ tới Boss")
                        _G.Mod_AutoFarmBoss_TargetWait = 0
                        _G.Mod_AutoFarmBoss_BossWait = 0
                        _G.Mod_AutoFarmBoss_DidJiggle = false
                        _G.Mod_AutoFarmBoss_LastForceMoveTime = nowRealtime
                        _G.Mod_AutoFarmBoss_LastTargetPos = target.currentPos and { x = target.currentPos.x, y = target.currentPos.y }
                        _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 0.3

                        -- STATE 4: WAIT & VALIDATE & COMBAT
                    elseif _G.Mod_AutoFarmBoss_State == 4 then
                        local target = _G.Mod_AutoFarmBoss_Target
                        if not target then
                            LogMsg("[FSM] State 4: Target bị rỗng (nil) -> Chuyển về State 1 (Về thành)")
                            SetBossState(1, "State 4 Target nil")
                            return
                        end

                        local currentLine = _G.SceneData and (_G.SceneData.line or _G.SceneData.cline or _G.SceneData.lineIndex) or 1
                        if currentMapId ~= target.mapCfg.mapId or (target.line and currentLine ~= target.line) then
                            _G.Mod_AutoFarmBoss_TargetWait = (_G.Mod_AutoFarmBoss_TargetWait or 0) + 1
                            if _G.Mod_AutoFarmBoss_TargetWait > 15 then
                                LogMsg("Lỗi: Không thể di chuyển tới Map/Line Boss. Bỏ qua điểm này 60s")
                                _G.Mod_AutoFarmBoss_Ignore[target.cfg.id .. "_" .. target.mapCfg.mapId] = currentSec + 60
                                _G.Mod_AutoFarmBoss_Target = nil
                                SetBossState(1, "Lỗi chuyển Map/Line > 15s")
                                _G.Mod_AutoFarmBoss_TargetWait = 0
                                _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                            else
                                _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                            end
                            return
                        end

                        -- Kiểm tra tọa độ thực tế của nhân vật
                        local px, py = nil, nil
                        if _G.RoleManager and _G.RoleManager.me then
                            local me = _G.RoleManager.me
                            if me.cellPos then
                                px, py = me.cellPos.x, me.cellPos.y
                            elseif me.serverCoord then
                                px, py = me.serverCoord.x, me.serverCoord.y
                            elseif me.GetPosition then
                                local p = me:GetPosition()
                                if p then px, py = math.floor(p.x), math.floor(p.z) end
                            elseif me.position then
                                px, py = math.floor(me.position.x), math.floor(me.position.z or me.position.y)
                            end
                        end

                        -- =========================================================================
                        -- [MOD FEATURE]: ÉP CHẠY BỘ ÁP SÁT BOSS CỰ LY <= 2M TRƯỚC KHI COMBAT
                        -- Mô tả: Quét tìm Boss trên màn hình và liên tục cập nhật tọa độ thực tế của Boss.
                        --        Nếu khoảng cách tới Boss > 2m: Ép chạy liên tục (MoveTo), tuyệt đối
                        --        KHÔNG đổi State và KHÔNG bật AutoFight.
                        --        Chỉ khi cự ly <= 2m: Nếu thấy Boss sống -> Chuyển State 5 (Combat);
                        --        nếu chưa thấy Boss -> Đón đầu chờ Boss xuất hiện tại tọa độ.
                        -- =========================================================================
                        local foundBoss = false
                        local isHighHp = false
                        local bossRoleObj = nil

                        if _G.RoleManager and _G.RoleManager.GetRolesByType then
                            local monsterRoles = _G.RoleManager.GetRolesByType(2)
                            if monsterRoles then
                                for lid, role in pairs(monsterRoles) do
                                    local d = role.data
                                    local mId = d and (d.configId or d.monsterId or d.templateId) or "none"

                                    local nameMatch = (d and d.name and target.cfg.name and string.find(string.lower(d.name), string.lower(target.cfg.name), 1, true))
                                    local idMatch = (tonumber(mId) ~= nil and tonumber(target.cfg.id) ~= nil and tonumber(mId) == tonumber(target.cfg.id))
                                    local isTarget = (_G.RoleManager.me and _G.RoleManager.me.TargetAvatar and _G.RoleManager.me.TargetAvatar == role)

                                    if role.hp and role.hp > 0 and (idMatch or nameMatch or isTarget) then
                                        foundBoss = true
                                        bossRoleObj = role
                                        local maxHp = role.maxHp or role.maxHP
                                        if not maxHp or maxHp <= 0 then maxHp = role.hp end

                                        local isMine = (d and d.owner and _G.RoleManager.me and tostring(d.owner) == tostring(_G.RoleManager.me.id))
                                        local isUnowned = (d and (tostring(d.owner) == "0" or d.owner == nil))

                                        if maxHp > 0 then
                                            local hpPct = (role.hp / maxHp) * 100
                                            local skipThresh = _G.Mod_AutoBoss_SkipHpPct or 90
                                            if hpPct >= skipThresh or isMine or isUnowned then
                                                isHighHp = true
                                            end
                                        else
                                            isHighHp = true
                                        end
                                        break
                                    end
                                end
                            end
                        end

                        -- Cập nhật tọa độ thực tế của Boss nếu Boss đang di chuyển trên màn hình
                        if bossRoleObj and target.currentPos then
                            local bx = bossRoleObj.serverCoord and bossRoleObj.serverCoord.x or (bossRoleObj.cellPos and bossRoleObj.cellPos.x) or (bossRoleObj.data and bossRoleObj.data.x)
                            local by = bossRoleObj.serverCoord and bossRoleObj.serverCoord.y or (bossRoleObj.cellPos and bossRoleObj.cellPos.y) or (bossRoleObj.data and bossRoleObj.data.y)
                            if bx and by then
                                target.currentPos.x = tonumber(bx) or target.currentPos.x
                                target.currentPos.y = tonumber(by) or target.currentPos.y
                            end
                        end

                        -- Tính khoảng cách thực tế giữa nhân vật và tọa độ mục tiêu Boss
                        local targetPos = target.currentPos
                        local dist = 9999
                        if px and py and targetPos and targetPos.x and targetPos.y then
                            local dx = px - targetPos.x
                            local dy = py - targetPos.y
                            dist = math.sqrt(dx * dx + dy * dy)
                        end

                        -- ĐIỀU KIỆN 1: NẾU CÒN CÁCH TỌA ĐỘ BOSS > 2M -> ÉP CHẠY BẰNG CHẾT, KHÔNG ĐỔI STATE, KHÔNG ĐỨNG IM!
                        if dist > 2.0 then
                            _G.Mod_AutoFarmBoss_BossWait = 0

                            -- =========================================================================
                            -- [MOD FEATURE]: CHẠY BỘ TỚI BOSS MƯỢT MÀ (KHÔNG GỌI SETAUTOTASKFIGHT DẬP NHỊP)
                            -- Mô tả: Chỉ tắt AutoFight khi đang bật để không ngắt quãng lộ trình chạy bộ;
                            --        tuyệt đối không gọi SetAutoTaskFight tránh khựng/flicker rung giật mỗi 0.3s.
                            -- =========================================================================
                            if _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.isAutoFight and _G.RoleManager.me.isAutoFight ~= "None" then
                                if _G.RoleManager.me.SetAutoFight then _G.RoleManager.me:SetAutoFight("None") end
                            end
                            if _G.QiJiHelperData and _G.QiJiHelperData.isAutoFight then
                                if _G.QiJiHelperData.SetAutoFightData then _G.QiJiHelperData.SetAutoFightData(false) end
                            end

                            local me = _G.RoleManager and _G.RoleManager.me
                            local isMoving = false
                            if me and me.IsMoving then
                                isMoving = me:IsMoving()
                            end

                            -- =========================================================================
                            -- [MOD FEATURE]: TỐI ƯU TẦN SUẤT ÉP MOVETO KHI CHẠY BỘ TỚI BOSS
                            -- Mô tả: Khi nhân vật ĐANG DI CHUYỂN (isMoving == true), để PathFinder tự
                            --        dẫn đường mượt mà, chỉ định kỳ 4.0s mới gửi lại MoveTo (heartbeat
                            --        chống kẹt). Tránh bị giằng co / lặp đường tại các khúc cua/ngã rẽ
                            --        (như 122#104 Hoang Dã C9).
                            --        Khi nhân vật ĐANG ĐỨNG IM (isMoving == false), gửi lại sau 1.0s.
                            --        Nếu Boss di chuyển lệch > 2m so với đích cũ, cập nhật MoveTo ngay.
                            -- =========================================================================
                            local lastMoveTime = _G.Mod_AutoFarmBoss_LastForceMoveTime or 0
                            local moveCooldown = isMoving and 4.0 or 1.0
                            local needForceMove = (nowRealtime - lastMoveTime) >= moveCooldown

                            -- Nếu Boss di chuyển trên màn hình lệch > 2m so với đích cũ -> Ép cập nhật sớm
                            if not needForceMove and target and target.currentPos and _G.Mod_AutoFarmBoss_LastTargetPos then
                                local lPos = _G.Mod_AutoFarmBoss_LastTargetPos
                                local cPos = target.currentPos
                                local tdx = (cPos.x or 0) - (lPos.x or 0)
                                local tdy = (cPos.y or 0) - (lPos.y or 0)
                                if (tdx * tdx + tdy * tdy) > 4.0 then
                                    needForceMove = true
                                end
                            end

                            if needForceMove and me and (not me.hp or me.hp > 0) then
                                _G.Mod_AutoFarmBoss_LastForceMoveTime = nowRealtime
                                if target and target.currentPos then
                                    _G.Mod_AutoFarmBoss_LastTargetPos = { x = target.currentPos.x, y = target.currentPos.y }
                                    local moved = false
                                    if me and me.MoveTo then
                                        local cellPos = { x = target.currentPos.x, y = target.currentPos.y }
                                        me:MoveTo(cellPos, 0, function(status)
                                            _G.Mod_AutoFarmBoss_ArrivedAtPos = true
                                        end)
                                        moved = true
                                    end
                                    if not moved then
                                        local targetVector = Vector2(target.currentPos.x, target.currentPos.y)
                                        if _G.PathFinderManager and _G.PathFinderManager.JumpMapToMoveToPos then
                                            _G.PathFinderManager.JumpMapToMoveToPos(target.mapCfg.mapId, targetVector, nil,
                                                target.line, nil, (Purpose and Purpose.None) or 0, function()
                                                    _G.Mod_AutoFarmBoss_ArrivedAtPos = true
                                                end, 0, true)
                                        elseif _G.JumpMapToPos and _G.JumpMapToPos.MapMoveToPos then
                                            _G.JumpMapToPos.MapMoveToPos(target.mapCfg.mapId, targetVector, nil, target.line, nil,
                                                (Purpose and Purpose.None) or 0, function()
                                                    _G.Mod_AutoFarmBoss_ArrivedAtPos = true
                                                end)
                                        end
                                    end
                                end
                            end

                            -- Giữ nhịp kiểm tra nhanh (0.3s) để nhân vật bám sát và không bị trễ nhịp
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 0.3
                            return
                        end

                        -- ĐIỀU KIỆN 2: KHI ĐÃ TIẾP CẬN CỰ LY <= 2M
                        _G.Mod_AutoFarmBoss_LastForceMoveTime = nil
                        _G.Mod_AutoFarmBoss_LastTargetPos = nil

                        -- Trường hợp A: Tìm thấy Boss sống ở cự ly <= 2m -> Xử lý Combat hoặc KS
                        if foundBoss then
                            local maxHp = bossRoleObj and (bossRoleObj.maxHp or bossRoleObj.maxHP or bossRoleObj.hp) or 1
                            local hpPct = bossRoleObj and ((bossRoleObj.hp / maxHp) * 100) or 100

                            if isHighHp then
                                if _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.SetAutoFight then
                                    _G.RoleManager.me:SetAutoFight("AutoFight")
                                end
                                SetBossState(5, "Đã áp sát Boss <= 2m -> Combat")
                                _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 0.5
                                LogMsg(string.format("Đã áp sát Boss %s cự ly %.1fm (<= 2m) - HP: %.2f%%. Bật Auto Fight!",
                                    tostring(target.cfg.name or ""), dist, hpPct))
                            else
                                local skipThresh = _G.Mod_AutoBoss_SkipHpPct or 90
                                LogMsg(string.format("Boss bị Ks (HP < %d%%). Bỏ qua 6 phút", skipThresh))
                                _G.Mod_AutoFarmBoss_Ignore[target.cfg.id .. "_" .. target.mapCfg.mapId] = currentSec + 360
                                _G.Mod_AutoFarmBoss_Target = nil
                                SetBossState(1, "Boss bị KS")
                                _G.Mod_AutoFarmBoss_TargetWait = 0
                                _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                            end
                            return
                        end

                        -- Trường hợp B: Đã tới tọa độ cự ly <= 2m nhưng chưa thấy Boss -> Đón đầu chờ Boss xuất hiện
                        _G.Mod_AutoFarmBoss_BossWait = (_G.Mod_AutoFarmBoss_BossWait or 0) + 1
                        if _G.Mod_AutoFarmBoss_BossWait <= 20 then
                            if _G.Mod_AutoFarmBoss_BossWait % 5 == 1 then
                                LogMsg(string.format("[ĐÓN ĐẦU] Đã tới tọa độ %s (cách %.1fm), đang chờ Boss %s xuất hiện (%ds/20s)...",
                                    target.currentPos and string.format("(%d, %d)", target.currentPos.x, target.currentPos.y) or "",
                                    dist,
                                    target.cfg.name or "",
                                    _G.Mod_AutoFarmBoss_BossWait))
                            end
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                        else
                            LogMsg(string.format("Đã đứng chờ 20s tại tọa độ %s nhưng Boss không xuất hiện. Trở về State 1...",
                                target.currentPos and string.format("(%d, %d)", target.currentPos.x, target.currentPos.y) or ""))
                            _G.Mod_AutoFarmBoss_BossWait = 0
                            _G.Mod_AutoFarmBoss_Target = nil
                            SetBossState(1, "Chờ Boss quá 20s không thấy")
                            _G.Mod_AutoFarmBoss_TargetWait = 0
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 1.0
                        end

                        -- STATE 5: COMBAT
                    elseif _G.Mod_AutoFarmBoss_State == 5 then
                        local target = _G.Mod_AutoFarmBoss_Target
                        if not target then
                            LogMsg("[FSM] State 5: Target bị rỗng (nil) -> Chuyển về State 1 (Về thành)")
                            SetBossState(1, "State 5 Target nil")
                            return
                        end

                        -- Đảm bảo chỉ tắt Auto Task Fight nếu nó đang bật (để không bị nháy liên tục)
                        if _G.RoleManager.me and _G.RoleManager.me.isAutoTaskFight and _G.RoleManager.me.isAutoTaskFight ~= "None" then
                            if _G.RoleManager.me.SetAutoTaskFight then _G.RoleManager.me:SetAutoTaskFight("None") end
                        end

                        -- Đảm bảo Auto Fight đang bật
                        if _G.RoleManager.me and _G.QiJiHelperData and not _G.QiJiHelperData.isAutoFight then
                            if _G.RoleManager.me.SetAutoFight then _G.RoleManager.me:SetAutoFight("AutoFight") end
                        end

                        local foundBoss = false
                        if _G.RoleManager and _G.RoleManager.GetRolesByType then
                            local monsterRoles = _G.RoleManager.GetRolesByType(2)
                            if monsterRoles then
                                for lid, role in pairs(monsterRoles) do
                                    local d = role.data
                                    local mId = d and (d.configId or d.monsterId or d.templateId) or "none"
                                    local nameMatch = (d and d.name and target.cfg.name and string.find(string.lower(d.name), string.lower(target.cfg.name), 1, true))
                                    local isTarget = (_G.RoleManager.me and _G.RoleManager.me.TargetAvatar and _G.RoleManager.me.TargetAvatar == role)
                                    local idMatch = (tonumber(mId) ~= nil and tonumber(target.cfg.id) ~= nil and tonumber(mId) == tonumber(target.cfg.id))

                                    if role.hp and role.hp > 0 and (idMatch or isTarget or nameMatch) then
                                        foundBoss = true
                                        local maxHp = role.maxHp or role.maxHP or role.hp or 1
                                        local hpPct = (role.hp / maxHp) * 100
                                        LogMsg(string.format("Đang đánh %s - HP: %.2f%%", d.name or target.cfg.name,
                                            hpPct))
                                        break
                                    end
                                end
                            end
                        end

                        if not foundBoss then
                            _G.Mod_AutoFarmBoss_TargetWait = (_G.Mod_AutoFarmBoss_TargetWait or 0) + 1
                            if _G.Mod_AutoFarmBoss_TargetWait >= 6 then
                                LogMsg("Boss chết hoặc biến mất! Tắt AutoFight & Chờ 7s nhặt đồ...")

                                -- Tắt Auto Fight ngay khi Boss chết
                                if _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.SetAutoFight then
                                    _G.RoleManager.me:SetAutoFight("None")
                                end
                                if _G.QiJiHelperData and _G.QiJiHelperData.SetAutoFightData then
                                    _G.QiJiHelperData.SetAutoFightData(false)
                                end

                                _G.Mod_FarmStats = _G.Mod_FarmStats or { hidden = 0, bosses = {} }
                                _G.Mod_FarmStats.bosses[target.cfg.id] = (_G.Mod_FarmStats.bosses[target.cfg.id] or 0) +
                                    1
                                if _G.Mod_SaveFarmStats then _G.Mod_SaveFarmStats() end
                                if _G.ModRefreshAutoBossConfigUI then _G.ModRefreshAutoBossConfigUI() end

                                _G.Mod_AutoFarmBoss_TargetWait = 0
                                SetBossState(6, "Boss chết hoặc biến mất -> Loot đồ")
                                _G.Mod_AutoFarmBoss_LootStartTime = nowRealtime
                                _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 0.1
                            else
                                _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 0.5
                            end
                        else
                            _G.Mod_AutoFarmBoss_TargetWait = 0
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 0.5
                        end

                        -- STATE 6: LOOT WAIT
                    elseif _G.Mod_AutoFarmBoss_State == 6 then
                        local lootDuration = 7.0 -- Customer: 7 giây chờ nhặt đồ
                        local lootStart = _G.Mod_AutoFarmBoss_LootStartTime or nowRealtime

                        -- Đảm bảo Auto Fight đã tắt hoàn toàn trong thời gian nhặt đồ
                        if _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.SetAutoFight then
                            _G.RoleManager.me:SetAutoFight("None")
                        end
                        if _G.QiJiHelperData and _G.QiJiHelperData.SetAutoFightData then
                            _G.QiJiHelperData.SetAutoFightData(false)
                        end

                        if nowRealtime < lootStart + lootDuration then
                            _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 0.5
                            return
                        end

                        -- Hết 7s chờ nhặt đồ -> Rút về Lorencia
                        LogMsg("Đã xong 7s nhặt đồ! Rút về Lorencia...")
                        _G.Mod_AutoFarmBoss_Target = nil
                        _G.Mod_AutoFarmBoss_LootStartTime = nil
                        SetBossState(1, "Xong 7s nhặt đồ -> Về Lorencia")
                        _G.Mod_AutoFarmBoss_TargetWait = 0
                        _G.Mod_AutoFarmBoss_WaitTime = nowRealtime + 0.5
                    end
                end)
                if not status then
                    LogMsg("LỖI AUTO FARM: " .. tostring(err))
                end
            end

            if _G.Timer and _G.Timer.StartLoop then
                _G.Timer.StartLoop(0.1, -1, function()
                    -- =========================================================================
                    -- [MOD FEATURE]: TỰ ĐỘNG THEO DÕI ĐỔI TÀI KHOẢN/NHÂN VẬT & KIỂM TRA BẢN QUYỀN ĐỊNH KỲ
                    -- Mô tả: Kiểm tra UID mỗi chu kỳ hoặc khi đổi nhân vật/tài khoản, thu hồi quyền nếu UID không khớp.
                    -- =========================================================================
                    local nowReal = CS.UnityEngine.Time.realtimeSinceStartup
                    if (nowReal - (_G.Mod_LastAuthPeriodicTime or 0)) >= 2.0 then
                        _G.Mod_LastAuthPeriodicTime = nowReal
                        local curUID = (Mod_GetCharacterUID and Mod_GetCharacterUID()) or ""
                        if curUID ~= "" then
                            if _G.Mod_LastVerifiedUID and _G.Mod_LastVerifiedUID ~= "" and _G.Mod_LastVerifiedUID ~= curUID then
                                -- Phát hiện người chơi đổi sang tài khoản / nhân vật khác!
                                _G.Mod_LastVerifiedUID = curUID
                                _G.Mod_IsActive = false
                                _G.Mod_ActiveConfig = nil
                                _G.Mod_HasFetchedConfig = false
                                if _G.ModMenuPanelGo and not _G.ModMenuPanelGo:Equals(nil) then
                                    _G.ModMenuPanelGo:SetActive(false)
                                end
                                if _G.authPanelGo and not _G.authPanelGo:Equals(nil) then
                                    _G.authPanelGo:SetActive(true)
                                    if _G.Mod_RefreshAuthPanelData then _G.Mod_RefreshAuthPanelData() end
                                end
                                if _G.Mod_UpdateUI_ActiveState then _G.Mod_UpdateUI_ActiveState() end
                                -- Tự động request API kiểm tra quyền cho UID mới
                                if _G.Mod_CheckActiveConfigNow then _G.Mod_CheckActiveConfigNow() end
                            elseif not _G.Mod_IsActive and not _G.Mod_HasFetchedConfig then
                                -- Vừa vào game lần đầu với UID này -> tự động check active
                                _G.Mod_LastVerifiedUID = curUID
                                if _G.Mod_CheckActiveConfigNow then _G.Mod_CheckActiveConfigNow() end
                            end
                        end

                        -- Kiểm tra định kỳ 60s với Server API
                        if (nowReal - (_G.Mod_LastServerSyncTime or 0)) >= 60.0 then
                            _G.Mod_LastServerSyncTime = nowReal
                            if _G.Mod_UpdatePeriodicCheck then _G.Mod_UpdatePeriodicCheck() end
                        end
                    end

                    -- TỰ ĐỘNG HỒI SINH (HS FREE & HS KC - 0s Delay + Dập Popup 3s)
                    local me = _G.RoleManager and _G.RoleManager.me
                    if me then
                        if me.isDead or (me.hp and me.hp <= 0) then
                            local nowTime = CS.UnityEngine.Time.realtimeSinceStartup
                            if not _G.Mod_LastResurrectTime or (nowTime - _G.Mod_LastResurrectTime) >= 1.0 then
                                if _G.Mod_AutoResurrect_Here_Enabled then
                                    -- 1. HỒI SINH TẠI CHỖ (30 KC / THẺ)
                                    _G.Mod_LastResurrectTime = nowTime
                                    pcall(function()
                                        local reviveItemId = 17020002
                                        local reviveGoodId = 30104
                                        local bagCount = 0
                                        if _G.BagInfoData and _G.BagInfoData.GetItemTotalCountByItemId then
                                            bagCount = _G.BagInfoData.GetItemTotalCountByItemId(reviveItemId) or 0
                                        end

                                        if bagCount > 0 then
                                            if _G.MeController and _G.RoleReliveType then
                                                _G.MeController.ReqReqRelive(_G.RoleReliveType.Here)
                                            end
                                        else
                                            if _G.NetManager and _G.ItemBuyMessage then
                                                _G.NetManager.Send(_G.ItemBuyMessage.ReqBuy,
                                                    { goodId = reviveGoodId, buyCount = 1 })
                                            end
                                            if _G.MeController and _G.RoleReliveType then
                                                _G.MeController.ReqReqRelive(_G.RoleReliveType.Here)
                                            end
                                        end

                                        if _G.UIManager and _G.UIManager.Hide and _G.UIID and _G.UIID.Role_ResurgenceUI then
                                            _G.UIManager.Hide(_G.UIID.Role_ResurgenceUI)
                                        end
                                    end)
                                elseif _G.Mod_AutoResurrect_Free_Enabled or _G.Mod_AutoResurrect_Enabled then
                                    -- 2. HỒI SINH MIỄN PHÍ (BORN POINT / KS BATTLE)
                                    _G.Mod_LastResurrectTime = nowTime
                                    pcall(function()
                                        local mapId = 0
                                        if _G.SceneData and _G.SceneData.mapId then
                                            mapId = _G.SceneData.mapId
                                        elseif me.mapId then
                                            mapId = me.mapId
                                        end

                                        local isKS = (mapId == 1077) or
                                            (_G.TranScriptData and _G.TranScriptData.IsInRefineKSBattle and _G.TranScriptData.IsInRefineKSBattle())

                                        if _G.MeController and _G.RoleReliveType then
                                            if isKS then
                                                _G.MeController.ReqReqRelive(_G.RoleReliveType.KSBattle)
                                            else
                                                _G.MeController.ReqReqRelive(_G.RoleReliveType.BornPoint)
                                            end
                                        end

                                        if _G.UIManager and _G.UIManager.Hide and _G.UIID and _G.UIID.Role_ResurgenceUI then
                                            _G.UIManager.Hide(_G.UIID.Role_ResurgenceUI)
                                        end
                                    end)
                                end
                            end
                        end

                        -- 3. BẢO VỆ: DẬP TẮT POPUP 3S ĐẾM LÙI KHI NHÂN VẬT ĐÃ SỐNG
                        if not me.isDead and me.hp and me.hp > 0 then
                            if _G.UIManager and _G.UIManager.IsVisible and _G.UIID and _G.UIID.Role_ResurgenceUI then
                                if _G.UIManager.IsVisible(_G.UIID.Role_ResurgenceUI) then
                                    _G.UIManager.Hide(_G.UIID.Role_ResurgenceUI)
                                end
                            end
                        end
                    end

                    if _G.Mod_PendingManualMove then
                        pcall(function()
                            local pMove = _G.Mod_PendingManualMove
                            local currentSec = (_G.Time and _G.Time.GetServerSecondTime and _G.Time.GetServerSecondTime()) or
                                os.time()
                            if currentSec > pMove.expireTime then
                                _G.Mod_PendingManualMove = nil
                            else
                                local curMapId = _G.SceneData and (_G.SceneData.mapId or _G.SceneData.groupId) or 0
                                local curLine = _G.SceneData and (_G.SceneData.line or _G.SceneData.cline) or 1
                                if curMapId == pMove.mapId and curLine == pMove.line then
                                    if pMove.reqSent ~= curMapId then
                                        pMove.reqSent = curMapId
                                        if _G.NetManager and _G.NetManager.Send and _G.MapMessage and _G.MapMessage.ReqBossIcon then
                                            pcall(function() _G.NetManager.Send(_G.MapMessage.ReqBossIcon) end)
                                        end
                                        pMove.waitTill = currentSec + 1
                                    elseif currentSec >= (pMove.waitTill or 0) then
                                        local alivePos, aliveCount = nil, 0
                                        if _G.GetAliveBossPosition then
                                            alivePos, aliveCount = _G.GetAliveBossPosition(pMove.bossId, pMove.mapId)
                                        end
                                        local targetPos = alivePos or
                                            (pMove.posX and pMove.posY and { x = pMove.posX, y = pMove.posY }) or
                                            (_G.GetBossPosition and _G.GetBossPosition(pMove.bossId, pMove.mapId))
                                        if targetPos and _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.MoveTo then
                                            _G.RoleManager.me:MoveTo({ x = targetPos.x, y = targetPos.y }, 0)
                                            if _G.FloatingWordUtility then
                                                _G.FloatingWordUtility.QuickMsg("Đã tới Map! Tự động chạy tới " ..
                                                    pMove.bossName ..
                                                    " (" .. targetPos.x .. ", " .. targetPos.y .. ")...")
                                            end
                                            _G.Mod_PendingManualMove = nil
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    if _G.Mod_IsActive and _G.Mod_CustomAttackRange and _G.Mod_CustomAttackRange > 0 then
                        local safeScope = math.min(15, _G.Mod_CustomAttackRange)
                        if _G.QiJiHelperData and _G.QiJiHelperData.SettingData then
                            if _G.QiJiHelperData.SettingData.KillMonsterScope ~= safeScope then
                                _G.QiJiHelperData.SettingData.KillMonsterScope = safeScope
                            end
                        end
                    end

                    if _G.Mod_IsActive and _G.Mod_AutoApproachTowerBoss then
                        local groupId = _G.SceneData and _G.SceneData.groupId
                        if groupId and string.match(tostring(groupId), "^1059") then
                            if _G.LastTowerMapId ~= groupId then
                                _G.LastTowerMapId = groupId
                                _G.Mod_ApproachTowerBoss_Done = false
                            end
                            if not _G.Mod_ApproachTowerBoss_Done then
                                if _G.Mod_ApproachTowerBoss and _G.Mod_ApproachTowerBoss() then
                                    _G.Mod_ApproachTowerBoss_Done = true
                                end
                            end
                        else
                            _G.LastTowerMapId = nil
                            _G.Mod_ApproachTowerBoss_Done = false
                        end
                    end

                    if _G.Mod_ShowKundunHP then
                        local currentSec = _G.Time.GetServerSecondTime and _G.Time.GetServerSecondTime() or os.time()
                        if currentSec > (_G.Mod_LastKundunHPTime or 0) then
                            if _G.RoleManager and _G.RoleManager.GetRolesByType then
                                local monsterRoles = _G.RoleManager.GetRolesByType(2)
                                if monsterRoles then
                                    for lid, role in pairs(monsterRoles) do
                                        local d = role.data
                                        if d and d.name and string.find(string.lower(d.name), "kundun") then
                                            if role.hp and role.hp > 0 then
                                                local maxHp = role.maxHp or role.maxHP or role.hp or 1
                                                local hpPct = math.max(0.01, (role.hp / maxHp) * 100)
                                                local msg = string.format("%s HP: %.2f%%", d.name, hpPct)
                                                if not _G.AutoPick_Enabled then
                                                    msg = msg .. " - BẠN CHƯA BẬT NHẶT NHANH"
                                                end
                                                if _G.FloatingWordUtility then
                                                    _G.FloatingWordUtility.QuickMsg(msg)
                                                end
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            _G.Mod_LastKundunHPTime = currentSec + 1
                        end
                    end

                    -- =========================================================================
                    -- [MOD FEATURE]: AUTO PICKUP - TỰ ĐỘNG ĐIỀU HƯỚNG VÀ SPAM NHẶT TUẦN TỰ
                    -- Mô tả: Quét danh sách ActiveSpamItems, sắp xếp theo khoảng cách gần nhất,
                    --        tự động MoveTo tới item gần nhất và spam ReqPickUpMapItem liên tục.
                    -- =========================================================================
                    if (_G.AutoPick_Enabled or _G.Mod_AutoPK_Enabled) and _G.Mod_ActiveSpamItems then
                        local nowTime = CS.UnityEngine.Time.realtimeSinceStartup
                        local validItems = {}

                        for itemId, itemInfo in pairs(_G.Mod_ActiveSpamItems) do
                            if nowTime > itemInfo.expireTime then
                                _G.Mod_ActiveSpamItems[itemId] = nil
                            else
                                table.insert(validItems, itemInfo)
                            end
                        end

                        if #validItems > 0 then
                            local meX, meY = 0, 0
                            if _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.serverCoord then
                                meX = _G.RoleManager.me.serverCoord.x or 0
                                meY = _G.RoleManager.me.serverCoord.y or 0
                            end

                            for _, itemInfo in ipairs(validItems) do
                                itemInfo.dist = math.max(math.abs(meX - (itemInfo.x or 0)),
                                    math.abs(meY - (itemInfo.y or 0)))
                            end

                            table.sort(validItems, function(a, b)
                                return (a.dist or 999) < (b.dist or 999)
                            end)

                            local nearestItem = validItems[1]

                            for _, itemInfo in ipairs(validItems) do
                                -- Chỉ di chuyển (MoveTo) đến 1 món GẦN NHẤT nếu dist > 1 (tránh xoay đầu/đè lệnh)
                                if itemInfo == nearestItem and itemInfo.dist > 1 then
                                    if _G.RoleManager and _G.RoleManager.me and itemInfo.x and itemInfo.y then
                                        pcall(function()
                                            _G.RoleManager.me:MoveTo({ x = itemInfo.x, y = itemInfo.y })
                                        end)
                                    end
                                end

                                -- Bắn gói tin nhặt
                                if _G.PickupManager then
                                    _G.PickupManager.ReqPickUpMapItem(itemInfo.id)
                                    if itemInfo.dist <= 2 then
                                        _G.PickupManager.ReqPickUpMapItem(itemInfo.id)
                                    end
                                end
                            end
                        end
                    end

                    if _G.Mod_AutoFarmBoss_Update then
                        _G.Mod_AutoFarmBoss_Update()
                    end
                end)
            end



            local original_RefreshAncientBossData = _G.SceneData.RefreshAncientBossData
            _G.SceneData.RefreshAncientBossData = function(self, tblData)
                if original_RefreshAncientBossData then original_RefreshAncientBossData(self, tblData) end
                if _G.ModUpdateKundunUI then _G.ModUpdateKundunUI() end
            end

            -- Auto PK & Lock Target Logic (Loop động theo _G.Mod_PKScanDelay, hỗ trợ Server S393. và tên người chơi)
            if not _G.Mod_PKScanLoopStarted then
                _G.Mod_PKScanLoopStarted = true
                if _G.Timer and _G.Timer.StartLoop then
                    _G.Timer.StartLoop(0.5, -1, function()
                        pcall(function()
                            if _G.Mod_IsActive and _G.Mod_AutoPK_Enabled and _G.RoleManager and _G.RoleManager.me then
                                local nowTime = CS.UnityEngine.Time.realtimeSinceStartup
                                local delay = _G.Mod_PKScanDelay or 0.8
                                if (nowTime - (_G.Mod_LastPKScanTime or 0)) >= delay then
                                    _G.Mod_LastPKScanTime = nowTime
                                    local function modSortRole(a, b)
                                        local distA = a.tempPathFindingDistance or 9999
                                        local distB = b.tempPathFindingDistance or 9999
                                        return distA < distB
                                    end

                                    local function isMatchLockTarget(p, lockInput)
                                        if not lockInput or lockInput == "" then return false end

                                        local cleanInput = string.gsub(lockInput, "^%s*(.-)%s*$", "%1")
                                        if cleanInput == "" then return false end

                                        local sId = string.match(cleanInput, "^S(%d+)%.$") or
                                            string.match(cleanInput, "^S(%d+)$") or
                                            string.match(cleanInput, "^s(%d+)%.$") or
                                            string.match(cleanInput, "^s(%d+)$")

                                        local targetNum = sId and tonumber(sId) or nil
                                        if targetNum then
                                            local pSid = p.serverId or p.sid or p.serverID or p.server_id
                                            if not pSid and p.data then
                                                pSid = p.data.serverId or p.data.sid or p.data.serverID or
                                                    p.data.server_id
                                            end
                                            if pSid and tonumber(pSid) == targetNum then
                                                return true
                                            end
                                        end

                                        local strList = {}
                                        if p.name then table.insert(strList, tostring(p.name)) end
                                        if p.GetName then
                                            pcall(function()
                                                local n = p:GetName()
                                                if n then table.insert(strList, tostring(n)) end
                                            end)
                                        end
                                        if p.data then
                                            if p.data.name then table.insert(strList, tostring(p.data.name)) end
                                            if p.data.showName then
                                                table.insert(strList, tostring(p.data.showName))
                                            end
                                            if p.data.serverId then
                                                table.insert(strList, "S" .. tostring(p.data.serverId))
                                            end
                                        end
                                        if p.serverId then table.insert(strList, "S" .. tostring(p.serverId)) end
                                        if p.showName then table.insert(strList, tostring(p.showName)) end

                                        if sId then
                                            local pattern1 = "S" .. sId .. "%."
                                            local pattern2 = "S" .. sId .. "_"
                                            local pattern3 = "S" .. sId
                                            for _, s in ipairs(strList) do
                                                if string.find(s, pattern1) or string.find(s, pattern2) or string.find(s, pattern3) then
                                                    return true
                                                end
                                            end
                                        else
                                            local lowerInput = string.lower(cleanInput)
                                            for _, s in ipairs(strList) do
                                                if string.find(string.lower(s), lowerInput, 1, true) then
                                                    return true
                                                end
                                            end
                                        end

                                        return false
                                    end

                                    local function isMonsterNearby(range)
                                        range = range or 15
                                        local me = _G.RoleManager and _G.RoleManager.me
                                        if not me or me.isDead then return false end
                                        local meId = (me.data and me.data.id) or me.id or 0
                                        local meX = me.serverCoord and me.serverCoord.x or (me.cellPos and me.cellPos.x) or (me.data and me.data.x) or 0
                                        local meY = me.serverCoord and me.serverCoord.y or (me.cellPos and me.cellPos.y) or (me.data and me.data.y) or 0

                                        if _G.RoleManager and _G.RoleManager.GetRolesByType then
                                            local monsterRoles = _G.RoleManager.GetRolesByType(2)
                                            if monsterRoles then
                                                for _, role in pairs(monsterRoles) do
                                                    if role and not role.isDead and role.hp and role.hp > 0 then
                                                        local isSummon = role.isSummon or (role.data and role.data.isSummon) or false
                                                        local ownerId = role.ownerId or (role.data and role.data.ownerId) or role.masterId or (role.data and role.data.master) or 0
                                                        local isMySummon = (isSummon == true) or (ownerId ~= 0 and tostring(ownerId) == tostring(meId))

                                                        local isSameCamp = false
                                                        if role.IsSameCamp then
                                                            isSameCamp = role:IsSameCamp()
                                                        elseif role.data and role.data.campId and role.data.campId ~= 0 and _G.ViewData and _G.ViewData.meData then
                                                            isSameCamp = (role.data.campId == _G.ViewData.meData.unionId or (_G.ViewData.meData.campId ~= nil and role.data.campId == _G.ViewData.meData.campId))
                                                        end
                                                        if ownerId ~= 0 and not isSameCamp then
                                                            if _G.WarAllianceData and _G.WarAllianceData.GetIsSameUnion and _G.WarAllianceData.GetIsSameUnion(ownerId) then
                                                                isSameCamp = true
                                                            elseif _G.TeamData and _G.TeamData.IsTeammate and _G.TeamData.IsTeammate(ownerId) then
                                                                isSameCamp = true
                                                            end
                                                        end

                                                        local canAttack = true
                                                        if _G.RoleTargetManager and _G.RoleTargetManager.GetCanAttackRole then
                                                            canAttack = _G.RoleTargetManager.GetCanAttackRole(role)
                                                        end

                                                        if canAttack and not isMySummon and not isSummon and (ownerId == 0 or ownerId == nil) and not isSameCamp then
                                                            local rX = role.serverCoord and role.serverCoord.x or (role.cellPos and role.cellPos.x) or (role.data and role.data.x) or 0
                                                            local rY = role.serverCoord and role.serverCoord.y or (role.cellPos and role.cellPos.y) or (role.data and role.data.y) or 0
                                                            local dist = 9999
                                                            if role.tempPathFindingDistance then
                                                                dist = role.tempPathFindingDistance
                                                            elseif meX > 0 and meY > 0 and rX > 0 and rY > 0 then
                                                                dist = math.max(math.abs(meX - rX), math.abs(meY - rY))
                                                            end
                                                            if dist <= range then
                                                                return true
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        return false
                                    end

                                    -- Quét các đối thủ theo đúng Chế độ PK hiện tại của game (dùng GetCanAttackRole)
                                    local players = _G.RoleManager.GetRolesByTypeAndRangeAlive(1, 15,
                                        _G.RoleTargetManager and _G.RoleTargetManager.GetCanAttackRole)
                                    local target = nil
                                    if players and #players > 0 then
                                        if _G.Mod_LockTarget_Enabled then
                                            -- BẬT KHÓA MỤC TIÊU: CHỈ tìm và đánh mục tiêu thỏa mãn điều kiện đã nhập. Không có -> target = nil (đứng im)
                                            if _G.Mod_LockTarget_Name and _G.Mod_LockTarget_Name ~= "" then
                                                local matchedPlayers = {}
                                                for _, p in ipairs(players) do
                                                    if isMatchLockTarget(p, _G.Mod_LockTarget_Name) then
                                                        table.insert(matchedPlayers, p)
                                                    end
                                                end
                                                if #matchedPlayers > 0 then
                                                    table.sort(matchedPlayers, modSortRole)
                                                    target = matchedPlayers[1]
                                                end
                                            end
                                        else
                                            -- TẮT KHÓA MỤC TIÊU: Đánh tất cả địch ở gần theo chế độ PK
                                            table.sort(players, modSortRole)
                                            target = players[1]
                                        end
                                    end

                                    if target then
                                        if _G.RoleManager.me.SetTarget then
                                            _G.RoleManager.me:SetTarget(target)
                                        else
                                            _G.RoleManager.me.TargetAvatar = target
                                        end
                                        if _G.RoleManager.me.SetAutoFight then
                                            _G.RoleManager.me:SetAutoFight("ReleaseSkill")
                                        end
                                    else
                                        -- Hết đối thủ người chơi: CHỈ bật lại AutoFight nếu có Quái/Kundun ở gần (~15 ô)
                                        if isMonsterNearby(15) then
                                            if _G.QiJiHelperData and not _G.QiJiHelperData.isAutoFight then
                                                if _G.RoleManager.me and _G.RoleManager.me.SetAutoFight then
                                                    _G.RoleManager.me:SetAutoFight("AutoFight")
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end)
                end
            end

            -- Auto Return Position Logic (Loop động theo _G.Mod_AutoReturnPosDelay)
            if not _G.Mod_ReturnPosLoopStarted then
                _G.Mod_ReturnPosLoopStarted = true
                if _G.Timer and _G.Timer.StartLoop then
                    _G.Timer.StartLoop(0.5, -1, function()
                        pcall(function()
                            if _G.Mod_IsActive and _G.Mod_AutoReturnPos_Enabled and _G.Mod_AutoReturnPos_Coords and _G.Mod_AutoReturnPos_Coords ~= "" then
                                local nowTime = CS.UnityEngine.Time.realtimeSinceStartup
                                local delay = _G.Mod_AutoReturnPosDelay or 1.0
                                if (nowTime - (_G.Mod_LastReturnPosTime or 0)) >= delay then
                                    _G.Mod_LastReturnPosTime = nowTime
                                    local sx, sy = string.match(_G.Mod_AutoReturnPos_Coords, "^(%d+)#(%d+)$")
                                    if sx and sy then
                                        local targetX, targetY = tonumber(sx), tonumber(sy)
                                        local me = _G.RoleManager and _G.RoleManager.me
                                        if me and not me.isDead then
                                            local curX = me.serverCoord and me.serverCoord.x or
                                                (me.cellPos and me.cellPos.x) or 0
                                            local curY = me.serverCoord and me.serverCoord.y or
                                                (me.cellPos and me.cellPos.y) or 0
                                            if curX > 0 and curY > 0 then
                                                local dist = math.max(math.abs(curX - targetX),
                                                    math.abs(curY - targetY))
                                                if dist > 1.5 then
                                                    -- Đang bật Auto PK & đang bận đánh mục tiêu gần -> Tạm hoãn MoveTo
                                                    local hasPkTarget = _G.Mod_AutoPK_Enabled and me.TargetAvatar and not me.TargetAvatar.isDead
                                                    if not (hasPkTarget and dist <= 15) then
                                                        pcall(function()
                                                            if me and me.MoveTo then
                                                                me:MoveTo({ x = targetX, y = targetY }, 0)
                                                            elseif _G.PathFinderManager and _G.PathFinderManager.JumpMapToMoveToPos and _G.SceneData and _G.SceneData.groupId then
                                                                local coordStr = string.format("%d#%d", targetX, targetY)
                                                                local targetPosData = (_G.PathFinderManager.GetCalcPosData and _G.PathFinderManager.GetCalcPosData(coordStr)) or
                                                                    (_G.Vector2 and _G.Vector2(targetX, targetY)) or
                                                                    { x = targetX, y = targetY }
                                                                _G.PathFinderManager.JumpMapToMoveToPos(
                                                                    _G.SceneData.groupId,
                                                                    targetPosData, nil, nil, nil,
                                                                    _G.Purpose and _G.Purpose.None or 0, nil, 1,
                                                                    true)
                                                            end
                                                        end)
                                                    end
                                                else
                                                    -- Đã về tới vị trí tọa độ mục tiêu (dist <= 1.5):
                                                    -- CHỈ bật AutoFight nếu Auto PK đang TẮT và có Quái/Kundun ở gần (~15 ô)
                                                    if not _G.Mod_AutoPK_Enabled then
                                                        if isMonsterNearby(15) and _G.QiJiHelperData and not _G.QiJiHelperData.isAutoFight then
                                                            if me and me.SetAutoFight then
                                                                me:SetAutoFight("AutoFight")
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end)
                end
            end

            if _G.Timer and _G.Timer.StartLoop then
                _G.Timer.StartLoop(0.2, -1, function()
                    pcall(function()
                        if _G.Mod_IsActive and _G.Mod_AutoAoE_BossAn then
                            local mapId = _G.SceneData and _G.SceneData.mapId or 0
                            if tonumber(mapId) == 240001 then
                                local me = _G.RoleManager and _G.RoleManager.me
                                local target = me and me.TargetAvatar
                                if target and not target.isDead and me.skills then
                                    local allowedAoEPrefixes = {
                                        ["140401"] = true, -- Ma Ky Sy: Set Danh
                                    }
                                    for _, skill in pairs(me.skills) do
                                        local sid = skill.sid or skill.id or skill.skillId
                                        if sid then
                                            local prefix = tostring(sid):sub(1, 6)
                                            if allowedAoEPrefixes[prefix] then
                                                local tblSkill = _G.ClientTable and
                                                    _G.ClientTable.cfg_Skill_skillManager:TryGetValue(sid)
                                                if tblSkill then
                                                    local cdMsg = me.cd and me.cd[tblSkill.groupId]
                                                    local endTime = cdMsg and cdMsg.endTime or 0
                                                    local publicCdMsg = me.cd and me.cd[1]
                                                    local publicEndTime = publicCdMsg and publicCdMsg.endTime or 0
                                                    local finalEndTime = math.max(endTime, publicEndTime)

                                                    if _G.Time and finalEndTime <= _G.Time.GetServerTime() then
                                                        local tblaction = _G.ConfigManager and
                                                            _G.ConfigManager.GetConfig("cfg_actionLogic",
                                                                tblSkill.actionId,
                                                                "groupId")
                                                        if tblaction and _G.SkillMgr and _G.SkillMgr.SendSkillMessage then
                                                            local coord = target.serverCoord or me.serverCoord
                                                            _G.SkillMgr.SendSkillMessage(tblSkill, tblaction, target.id,
                                                                coord)
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end)

                -- =========================================================================
                -- [MOD FEATURE]: KHÓA VÀ CẬP NHẬT FOV SIÊU TỐC (0.1S VÀ SỰ KIỆN QUA MAP)
                -- Mô tả: Chu kỳ 0.1s và hook Event.Scene_SceneLoaded giúp Camera cập nhật FOV tức thì khi qua map,
                --        loại bỏ hoàn toàn hiện tượng trễ 1s gây giật và thu phóng màn hình khó chịu.
                -- =========================================================================
                if _G.EventManager and _G.Event and _G.Event.Scene_SceneLoaded and not _G.Mod_HookedSceneLoadedFOV then
                    _G.Mod_HookedSceneLoadedFOV = true
                    pcall(function()
                        _G.EventManager.Regist(_G.Event.Scene_SceneLoaded, function()
                            pcall(function()
                                _G.Mod_CachedMainCam = nil
                                local targetFov = _G.currentFOV or _G.SavedFOV or _G.Mod_Config_FOV_Max or 50
                                local cam = CS.UnityEngine.Camera and CS.UnityEngine.Camera.main
                                if cam then
                                    _G.Mod_CachedMainCam = cam
                                    cam.fieldOfView = targetFov
                                end
                            end)
                        end)
                    end)
                end

                _G.Timer.StartLoop(0.1, -1, function()
                    pcall(function()
                        if not _G.Mod_IsActive then return end
                        local targetFov = _G.currentFOV or _G.SavedFOV or _G.Mod_Config_FOV_Max or 50
                        local cam = _G.Mod_CachedMainCam
                        if not cam or (IsNil and IsNil(cam)) then
                            cam = CS.UnityEngine.Camera and CS.UnityEngine.Camera.main
                            _G.Mod_CachedMainCam = cam
                        end
                        if cam and (not IsNil or not IsNil(cam)) and math.abs(cam.fieldOfView - targetFov) > 0.5 then
                            cam.fieldOfView = targetFov
                        end
                    end)



                    pcall(function()
                        if not _G.Mod_IsActive then return end
                        if _G.AutoFightFindTargetManager and not _G.Mod_HookedAutoFightTarget then
                            _G.Mod_HookedAutoFightTarget = true
                            local original_GetMostMonster = _G.AutoFightFindTargetManager.GetMostMonsterInMonsterList
                            if original_GetMostMonster then
                                _G.AutoFightFindTargetManager.GetMostMonsterInMonsterList = function(skillRange,
                                                                                                     roleTypes,
                                                                                                     autoDoubleSkillType)
                                    if _G.Mod_AutoAoE_BossAn then
                                        local mapId = _G.SceneData and _G.SceneData.mapId or 0
                                        if tonumber(mapId) == 240001 then
                                            local target = _G.RoleManager.me.TargetAvatar
                                            if target then
                                                return target
                                            end
                                            local monsterRange = 8
                                            local monsters = _G.RoleManager.GetRolesByTypeAndRangeAlive(roleTypes,
                                                monsterRange, _G.RoleTargetManager.GetCanAttackRole)
                                            for _, v in pairs(monsters) do
                                                if v and v.hp and v.hp > 0 then
                                                    return v
                                                end
                                            end
                                        end
                                    end
                                    return original_GetMostMonster(skillRange, roleTypes, autoDoubleSkillType)
                                end
                            end

                            local original_GetSpecifyMonster = _G.AutoFightFindTargetManager
                                .GetSpecifyMonsterIntersectionNew
                            if original_GetSpecifyMonster then
                                _G.AutoFightFindTargetManager.GetSpecifyMonsterIntersectionNew = function(skillRange,
                                                                                                          specifyMonster,
                                                                                                          roleTypes)
                                    if _G.Mod_AutoAoE_BossAn then
                                        local mapId = _G.SceneData and _G.SceneData.mapId or 0
                                        if tonumber(mapId) == 240001 then
                                            return true
                                        end
                                    end
                                    return original_GetSpecifyMonster(skillRange, specifyMonster, roleTypes)
                                end
                            end
                        end
                    end)

                    -- Auto PK Logic
                    if _G.Mod_AutoPK_Enabled and _G.RoleManager and _G.RoleManager.me then
                        local function modSortRole(a, b)
                            local distA = a.tempPathFindingDistance or 9999
                            local distB = b.tempPathFindingDistance or 9999
                            return distA < distB
                        end
                        local players = _G.RoleManager.GetRolesByTypeAndRangeAlive(1, 15,
                            _G.RoleTargetManager.GetCanAttackRole)
                        if players and #players > 0 then
                            local target = nil
                            if _G.Mod_LockTarget_Enabled and _G.Mod_LockTarget_Name and _G.Mod_LockTarget_Name ~= "" then
                                for _, p in ipairs(players) do
                                    if p.name == _G.Mod_LockTarget_Name then
                                        target = p
                                        break
                                    end
                                end
                            elseif not _G.Mod_LockTarget_Enabled then
                                table.sort(players, modSortRole)
                                target = players[1]
                            end

                            if target then
                                if _G.RoleManager.me.SetTarget then
                                    _G.RoleManager.me:SetTarget(target)
                                else
                                    _G.RoleManager.me.TargetAvatar = target
                                end
                                if _G.RoleManager.me.SetAutoFight then
                                    _G.RoleManager.me:SetAutoFight("ReleaseSkill")
                                end
                            end
                        end
                    end

                    -- =========================================================================
                    -- [MOD FEATURE]: TỰ ĐỘNG PK GUILD (AUTO PK GUILD)
                    -- Mô tả: Tự động chuyển và duy trì chế độ PK Guild khi có lệnh bí mật /pkmodeguild và toggle được bật.
                    -- =========================================================================
                    if _G.Mod_AutoGuildPK_Enabled and _G.Mod_HasSecretCommand and _G.Mod_HasSecretCommand("/pkmodeguild") and _G.RoleManager and _G.RoleManager.me and _G.NetManager and _G.RoleMessage then
                        if _G.RoleManager.me.PKMode ~= 2 then -- 2 is Guild mode
                            local nowGuildPK = CS.UnityEngine.Time.realtimeSinceStartup
                            if (nowGuildPK - (_G.Mod_LastGuildPKReqTime or 0)) >= 1.5 then
                                _G.Mod_LastGuildPKReqTime = nowGuildPK
                                _G.NetManager.Send(_G.RoleMessage.ReqSetPKMode, { param = 2 })
                            end
                        end
                    end

                    if isExpanded then
                        UpdateBossWatchUIText()
                        if _G.ModUpdateCountText then _G.ModUpdateCountText() end
                        if _G.ModUpdateGoldenChestLabel then _G.ModUpdateGoldenChestLabel() end
                        if _G.ModUpdateKundunUI then _G.ModUpdateKundunUI() end

                        if _G.IsAutoRefresh then
                            local currentSec = _G.Time.GetServerSecondTime()
                            if currentSec - _G.LastRefreshSec >= _G.AutoRefreshInterval then
                                _G.LastRefreshSec = currentSec
                                if _G.NetManager and _G.MapMessage then
                                    _G.NetManager.Send(_G.MapMessage.ReqGetBossMapAndCount)
                                    _G.NetManager.Send(_G.MapMessage.ReqAncientBossInfo, { type = 16 })
                                    _G.NetManager.Send(_G.MapMessage.ReqAncientBossInfo, { type = 17 })
                                end
                            end
                        end
                    end
                end)
            end
        end

        local function SaveFOV(fov)
            pcall(function()
                _G.SavedFOV = fov
                CS.UnityEngine.PlayerPrefs.SetFloat("Mod_FOV", fov)
                CS.UnityEngine.PlayerPrefs.Save()
            end)
        end

        local function SaveRefreshSettings()
            pcall(function()
                CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoRefresh", _G.IsAutoRefresh and 1 or 0)
                CS.UnityEngine.PlayerPrefs.SetInt("Mod_RefreshInterval", _G.AutoRefreshInterval)
                CS.UnityEngine.PlayerPrefs.Save()
            end)
        end

        local function UpdateFOVLabel()
            pcall(function()
                local cam = CS.UnityEngine.Camera.main
                if cam then
                    fovValTxt.text = "FOV: " .. tostring(math.floor(cam.fieldOfView))
                end
            end)
        end

        -- Auth UI
        local function CreateAuthUI()
            local authPanelGo = GameObject("AuthPanel")
            authPanelGo.transform:SetParent(modRoot.transform, false)
            local authRt = authPanelGo:AddComponent(typeof(RectTransform))
            authRt.anchorMin, authRt.anchorMax, authRt.pivot = Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)
            authRt.anchoredPosition = Vector2(90, 70)
            authRt.sizeDelta = Vector2(600, 350)
            local authImg = authPanelGo:AddComponent(typeof(Image))
            authImg.color = Color(0.1, 0.1, 0.1, 0.95)
            authPanelGo:SetActive(false)
            _G.authPanelGo = authPanelGo

            local function GetMD5(str)
                local status, res = pcall(function()
                    return string.lower(tostring(CS.PCUtility.Md5(str)))
                end)
                return status and res or "ERROR_MD5"
            end

            local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
            local function Base64Decode(data)
                local status, res = pcall(function()
                    data = string.gsub(data, '[^' .. b64chars .. '=]', '')
                    return (data:gsub('.', function(x)
                        if (x == '=') then return '' end
                        local r, f = '', (b64chars:find(x) - 1)
                        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
                        return r;
                    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
                        if (#x ~= 8) then return '' end
                        local c = 0
                        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
                        return string.char(c)
                    end))
                end)
                return status and res or ""
            end

            local function FormatTokenDisplay(tok, emptyText)
                if not tok or tok == "" then return emptyText end
                if string.len(tok) <= 20 then return "Token: " .. tok end
                return "Token: " .. string.sub(tok, 1, 10) .. "..." .. string.sub(tok, -10)
            end

            local deviceId = CS.UnityEngine.SystemInfo.deviceUniqueIdentifier
            local deviceCode = GetMD5(deviceId .. "XOAI")

            local titleGo = GameObject("AuthTitle")
            titleGo.transform:SetParent(authPanelGo.transform, false)
            local titleRt = titleGo:AddComponent(typeof(RectTransform))
            titleRt.anchorMin, titleRt.anchorMax, titleRt.pivot = Vector2(0.5, 1), Vector2(0.5, 1), Vector2(0.5, 1)
            titleRt.anchoredPosition = Vector2(0, -20)
            titleRt.sizeDelta = Vector2(500, 40)
            local titleTxt = titleGo:AddComponent(typeof(Text))
            titleTxt.text = "KÍCH HOẠT BẢN QUYỀN MOD"
            titleTxt.color, titleTxt.fontSize, titleTxt.alignment = Color.yellow, 24, TextAnchor.MiddleCenter
            if defaultFont then titleTxt.font = defaultFont end

            local codeGo = GameObject("AuthCodeTxt")
            codeGo.transform:SetParent(authPanelGo.transform, false)
            local codeRt = codeGo:AddComponent(typeof(RectTransform))
            codeRt.anchorMin, codeRt.anchorMax, codeRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            codeRt.anchoredPosition = Vector2(20, -70)
            codeRt.sizeDelta = Vector2(450, 60)
            local codeTxt = codeGo:AddComponent(typeof(Text))
            codeTxt.text = "Mã thiết bị (Copy gửi cho Admin):\n<color=yellow>" .. deviceCode .. "</color>"
            codeTxt.color, codeTxt.fontSize = Color.white, 16
            if defaultFont then codeTxt.font = defaultFont end

            local copyBtnGo = GameObject("AuthCopyBtn")
            copyBtnGo.transform:SetParent(authPanelGo.transform, false)
            local copyRt = copyBtnGo:AddComponent(typeof(RectTransform))
            copyRt.anchorMin, copyRt.anchorMax, copyRt.pivot = Vector2(1, 1), Vector2(1, 1), Vector2(1, 1)
            copyRt.anchoredPosition = Vector2(-20, -75)
            copyRt.sizeDelta = Vector2(120, 40)
            local copyImg = copyBtnGo:AddComponent(typeof(Image))
            copyImg.color = Color(0.2, 0.6, 1, 1)
            local copyBtn = copyBtnGo:AddComponent(typeof(Button))
            local copyTxtGo = GameObject("CopyTxt")
            copyTxtGo.transform:SetParent(copyBtnGo.transform, false)
            local cTxtRt = copyTxtGo:AddComponent(typeof(RectTransform))
            cTxtRt.anchorMin, cTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            cTxtRt.offsetMin, cTxtRt.offsetMax = Vector2(0, 0), Vector2(0, 0)
            local cTxt = copyTxtGo:AddComponent(typeof(Text))
            cTxt.text = "Copy Code"
            cTxt.color, cTxt.fontSize, cTxt.alignment = Color.white, 18, TextAnchor.MiddleCenter
            if defaultFont then cTxt.font = defaultFont end

            copyBtn.onClick:AddListener(function()
                CS.UnityEngine.GUIUtility.systemCopyBuffer = deviceCode
                if _G.FloatingWordUtility then _G.FloatingWordUtility.QuickMsg("Đã copy mã thiết bị!") end
            end)

            -- Auth Token Label
            local tokenLblGo = GameObject("AuthTokenLbl")
            tokenLblGo.transform:SetParent(authPanelGo.transform, false)
            local tokenLblRt = tokenLblGo:AddComponent(typeof(RectTransform))
            tokenLblRt.anchorMin, tokenLblRt.anchorMax, tokenLblRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            tokenLblRt.anchoredPosition = Vector2(20, -150)
            tokenLblRt.sizeDelta = Vector2(400, 20)
            local tokenLblTxt = tokenLblGo:AddComponent(typeof(Text))
            tokenLblTxt.text = "Nhập Token:"
            tokenLblTxt.color, tokenLblTxt.fontSize = Color.white, 16
            if defaultFont then tokenLblTxt.font = defaultFont end

            local tokenGo = GameObject("AuthTokenInput")
            tokenGo.transform:SetParent(authPanelGo.transform, false)
            local tokenRt = tokenGo:AddComponent(typeof(RectTransform))
            tokenRt.anchorMin, tokenRt.anchorMax, tokenRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            tokenRt.anchoredPosition = Vector2(20, -170)
            tokenRt.sizeDelta = Vector2(550, 35)
            local tokenImg = tokenGo:AddComponent(typeof(Image))
            tokenImg.color = Color(1, 1, 1, 1)

            local textGo = GameObject("Text")
            textGo.transform:SetParent(tokenGo.transform, false)
            local txtRt = textGo:AddComponent(typeof(RectTransform))
            txtRt.anchorMin, txtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            txtRt.offsetMin, txtRt.offsetMax = Vector2(5, 0), Vector2(-5, 0)
            local tokenTxt = textGo:AddComponent(typeof(Text))
            local savedToken = CS.UnityEngine.PlayerPrefs.GetString("Mod_AuthToken", "")
            tokenTxt.text = savedToken
            tokenTxt.color, tokenTxt.fontSize = Color.black, 16
            tokenTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then tokenTxt.font = defaultFont end

            local inputField = tokenGo:AddComponent(typeof(CS.UnityEngine.UI.InputField))
            inputField.textComponent = tokenTxt
            inputField.text = savedToken

            inputField.onValueChanged:AddListener(function(val)
                savedToken = val
            end)

            local pasteBtnGo = GameObject("AuthPasteBtn")
            pasteBtnGo.transform:SetParent(authPanelGo.transform, false)
            local pasteRt = pasteBtnGo:AddComponent(typeof(RectTransform))
            pasteRt.anchorMin, pasteRt.anchorMax, pasteRt.pivot = Vector2(1, 1), Vector2(1, 1), Vector2(1, 1)
            pasteRt.anchoredPosition = Vector2(-20, -170)
            pasteRt.sizeDelta = Vector2(120, 35)
            local pasteImg = pasteBtnGo:AddComponent(typeof(Image))
            pasteImg.color = Color(0.8, 0.4, 0, 1)
            local pasteBtn = pasteBtnGo:AddComponent(typeof(Button))
            local pasteTxtGo = GameObject("PasteTxt")
            pasteTxtGo.transform:SetParent(pasteBtnGo.transform, false)
            local pTxtRt = pasteTxtGo:AddComponent(typeof(RectTransform))
            pTxtRt.anchorMin, pTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            pTxtRt.offsetMin, pTxtRt.offsetMax = Vector2(0, 0), Vector2(0, 0)
            local pTxt = pasteTxtGo:AddComponent(typeof(Text))
            pTxt.text = "Paste Token"
            pTxt.color, pTxt.fontSize, pTxt.alignment = Color.white, 18, TextAnchor.MiddleCenter
            if defaultFont then pTxt.font = defaultFont end

            pasteBtn.onClick:AddListener(function()
                savedToken = CS.UnityEngine.GUIUtility.systemCopyBuffer or ""
                inputField.text = savedToken
            end)

            local errGo = GameObject("AuthErrTxt")
            errGo.transform:SetParent(authPanelGo.transform, false)
            local errRt = errGo:AddComponent(typeof(RectTransform))
            errRt.anchorMin, errRt.anchorMax, errRt.pivot = Vector2(0.5, 0), Vector2(0.5, 0), Vector2(0.5, 0)
            errRt.anchoredPosition = Vector2(0, 30)
            errRt.sizeDelta = Vector2(500, 30)
            local errTxt = errGo:AddComponent(typeof(Text))
            errTxt.text = ""
            errTxt.color, errTxt.fontSize, errTxt.alignment = Color.red, 18, TextAnchor.MiddleCenter
            if defaultFont then errTxt.font = defaultFont end

            local actBtnGo = GameObject("AuthActBtn")
            actBtnGo.transform:SetParent(authPanelGo.transform, false)
            local actRt = actBtnGo:AddComponent(typeof(RectTransform))
            actRt.anchorMin, actRt.anchorMax, actRt.pivot = Vector2(0.5, 0), Vector2(0.5, 0), Vector2(0.5, 0)
            actRt.anchoredPosition = Vector2(0, 80)
            actRt.sizeDelta = Vector2(200, 50)
            local actImg = actBtnGo:AddComponent(typeof(Image))
            actImg.color = Color(0, 0.8, 0, 1)
            local actBtn = actBtnGo:AddComponent(typeof(Button))
            local actTxtGo = GameObject("ActTxt")
            actTxtGo.transform:SetParent(actBtnGo.transform, false)
            local aTxtRt = actTxtGo:AddComponent(typeof(RectTransform))
            aTxtRt.anchorMin, aTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            aTxtRt.offsetMin, aTxtRt.offsetMax = Vector2(0, 0), Vector2(0, 0)
            local aTxt = actTxtGo:AddComponent(typeof(Text))
            aTxt.text = "KÍCH HOẠT"
            aTxt.color, aTxt.fontSize, aTxt.alignment = Color.white, 22, TextAnchor.MiddleCenter
            if defaultFont then aTxt.font = defaultFont end

            _G.CheckModAuth = function(tokenStr, isSilent)
                if not tokenStr or tokenStr == "" then
                    if not isSilent then errTxt.text = "Token không được để trống!" end
                    return false
                end
                local decoded = Base64Decode(tokenStr)
                if not decoded or decoded == "" then
                    if not isSilent then errTxt.text = "Token sai định dạng!" end
                    return false
                end
                local parts = {}
                for part in string.gmatch(decoded, "[^|]+") do
                    table.insert(parts, part)
                end
                if #parts ~= 4 then
                    if not isSilent then errTxt.text = "Token không hợp lệ!" end
                    return false
                end
                local pCode, pDuration, pTime, pSig = parts[1], tonumber(parts[2]), tonumber(parts[3]), parts[4]
                if pCode ~= deviceCode then
                    if not isSilent then errTxt.text = "Token không dành cho thiết bị này!" end
                    return false
                end
                local dataToHash = pCode ..
                    "|" .. tostring(pDuration) .. "|" .. tostring(pTime) .. "MUVH_SECRET_SALT_XOAI"
                local expectedSig = GetMD5(dataToHash)
                if expectedSig ~= pSig then
                    if not isSilent then errTxt.text = "Token đã bị giả mạo!" end
                    return false
                end

                local currentUnixTime = (_G.Time and _G.Time.GetServerSecondTime) and _G.Time.GetServerSecondTime() or
                    os.time()
                local expireTime = pTime + (pDuration * 86400)
                if currentUnixTime > expireTime then
                    if not isSilent then errTxt.text = "Token đã hết hạn!" end
                    return false
                end

                CS.UnityEngine.PlayerPrefs.SetString("Mod_AuthToken", tokenStr)
                CS.UnityEngine.PlayerPrefs.Save()
                _G.ModAuthValid = true
                return true
            end

            actBtn.onClick:AddListener(function()
                if _G.CheckModAuth(savedToken, false) then
                    authPanelGo:SetActive(false)
                    if panelGo then
                        isExpanded = true
                        panelGo:SetActive(true)
                    end
                    if _G.FloatingWordUtility then _G.FloatingWordUtility.QuickMsg("Kích hoạt thành công!") end
                end
            end)

            if savedToken ~= "" then
                if not _G.CheckModAuth(savedToken, true) then
                    errTxt.text = "Token đã lưu không hợp lệ hoặc hết hạn!"
                end
            end
        end
        _G.ModCallbacks.OnToggleMenu = function()
            pcall(function()
                if _G.Mod_IsActive then
                    if _G.authPanelGo and _G.authPanelGo.activeSelf then _G.authPanelGo:SetActive(false) end
                    isExpanded = not isExpanded
                    panelGo:SetActive(isExpanded)
                    if isExpanded then
                        if UpdateFOVLabel then UpdateFOVLabel() end
                        RefreshMainTabs()
                        if _G.NetManager and _G.MapMessage then
                            _G.NetManager.Send(_G.MapMessage.ReqGetBossMapAndCount)
                            _G.NetManager.Send(_G.MapMessage.ReqAncientBossInfo, { type = 16 })
                            _G.NetManager.Send(_G.MapMessage.ReqAncientBossInfo, { type = 17 })
                        end
                    end
                else
                    if panelGo and panelGo.activeSelf then panelGo:SetActive(false) end
                    if _G.authPanelGo then
                        local showAuth = not _G.authPanelGo.activeSelf
                        _G.authPanelGo:SetActive(showAuth)
                        if showAuth and RefreshAuthPanelData then RefreshAuthPanelData() end
                    end
                end
            end)
        end
        btnComp.onClick:AddListener(_G.ModCallbacks.OnToggleMenu)

        -- Thêm UI Auto Refresh
        local refreshMinusBtnGo = GameObject("RefreshMinusBtn")
        refreshMinusBtnGo.transform:SetParent(panelGo.transform, false)
        local rmRt = refreshMinusBtnGo:AddComponent(typeof(RectTransform))
        rmRt.anchorMin = Vector2(0, 1)
        rmRt.anchorMax = Vector2(0, 1)
        rmRt.pivot = Vector2(0, 1)
        rmRt.anchoredPosition = Vector2(40, -100)
        rmRt.sizeDelta = Vector2(40, 30)
        local rmImg = refreshMinusBtnGo:AddComponent(typeof(Image))
        rmImg.color = Color(0.4, 0.4, 0.4, 1)
        table.insert(_G.CoBanUIList, refreshMinusBtnGo)
        local rmTxt = GameObject("Text"):AddComponent(typeof(Text))
        rmTxt.raycastTarget = false
        rmTxt.transform:SetParent(refreshMinusBtnGo.transform, false)
        rmTxt.text = "-"
        rmTxt.alignment = TextAnchor.MiddleCenter
        rmTxt.color = Color.white
        rmTxt.fontSize = 20
        if defaultFont then rmTxt.font = defaultFont end

        local refreshPlusBtnGo = GameObject("RefreshPlusBtn")
        refreshPlusBtnGo.transform:SetParent(panelGo.transform, false)
        local rpRt = refreshPlusBtnGo:AddComponent(typeof(RectTransform))
        rpRt.anchorMin = Vector2(0, 1)
        rpRt.anchorMax = Vector2(0, 1)
        rpRt.pivot = Vector2(0, 1)
        rpRt.anchoredPosition = Vector2(240, -100)
        rpRt.sizeDelta = Vector2(40, 30)
        local rpImg = refreshPlusBtnGo:AddComponent(typeof(Image))
        rpImg.color = Color(0.4, 0.4, 0.4, 1)
        table.insert(_G.CoBanUIList, refreshPlusBtnGo)
        local rpTxt = GameObject("Text"):AddComponent(typeof(Text))
        rpTxt.raycastTarget = false
        rpTxt.transform:SetParent(refreshPlusBtnGo.transform, false)
        rpTxt.text = "+"
        rpTxt.alignment = TextAnchor.MiddleCenter
        rpTxt.color = Color.white
        rpTxt.fontSize = 20
        if defaultFont then rpTxt.font = defaultFont end

        local refreshToggleGo = GameObject("RefreshToggleBtn")
        refreshToggleGo.transform:SetParent(panelGo.transform, false)
        local tgRt = refreshToggleGo:AddComponent(typeof(RectTransform))
        tgRt.anchorMin = Vector2(0, 1)
        tgRt.anchorMax = Vector2(0, 1)
        tgRt.pivot = Vector2(0, 1)
        tgRt.anchoredPosition = Vector2(80, -100)
        tgRt.sizeDelta = Vector2(160, 30)
        local rtImg = refreshToggleGo:AddComponent(typeof(Image))
        rtImg.color = Color(0.2, 0.2, 0.2, 0)
        table.insert(_G.CoBanUIList, refreshToggleGo)
        local rtTxt = GameObject("Text"):AddComponent(typeof(Text))
        rtTxt.raycastTarget = false
        rtTxt.transform:SetParent(refreshToggleGo.transform, false)
        rtTxt.text = "[ ] Lặp: 5s"
        rtTxt.alignment = TextAnchor.MiddleCenter
        rtTxt.color = Color(0.8, 1, 0.8, 1)
        rtTxt.fontSize = 18
        if defaultFont then rtTxt.font = defaultFont end

        local function UpdateRefreshLabel()
            pcall(function()
                if _G.IsAutoRefresh then
                    rtTxt.text = "[X] Tự làm mới: " .. _G.AutoRefreshInterval .. "s"
                else
                    rtTxt.text = "[ ] Tự làm mới: " .. _G.AutoRefreshInterval .. "s"
                end
            end)
        end
        UpdateRefreshLabel()
        RefreshMainTabs()

        local rmBtnComp = refreshMinusBtnGo:AddComponent(typeof(Button))
        rmBtnComp.onClick:AddListener(function()
            pcall(function()
                _G.AutoRefreshInterval = _G.AutoRefreshInterval - 1
                if _G.AutoRefreshInterval < 3 then _G.AutoRefreshInterval = 3 end
                UpdateRefreshLabel()
                SaveRefreshSettings()
            end)
        end)

        local rpBtnComp = refreshPlusBtnGo:AddComponent(typeof(Button))
        rpBtnComp.onClick:AddListener(function()
            pcall(function()
                _G.AutoRefreshInterval = _G.AutoRefreshInterval + 1
                if _G.AutoRefreshInterval > 30 then _G.AutoRefreshInterval = 30 end
                UpdateRefreshLabel()
                SaveRefreshSettings()
            end)
        end)

        local rtBtnComp = refreshToggleGo:AddComponent(typeof(Button))
        rtBtnComp.onClick:AddListener(function()
            pcall(function()
                _G.IsAutoRefresh = not _G.IsAutoRefresh
                _G.LastRefreshSec = _G.Time.GetServerSecondTime()
                UpdateRefreshLabel()
                SaveRefreshSettings()
            end)
        end)

        -- =========================================================================
        -- [MOD FEATURE]: PHẠM VI TẤN CÔNG THEO SỐ Ô (ATTACK RANGE IN CELLS)
        -- Mô tả: Cài đặt tầm đánh kỹ năng theo số ô (1 - 15 ô), thay thế hệ số nhân
        -- =========================================================================
        if _G.Mod_ApplyAttackRangeCells == nil then
            _G.Mod_ApplyAttackRangeCells = function(cells)
                pcall(function()
                    cells = math.max(1, math.min(15, math.floor(cells or 8)))
                    local skillDic = nil
                    if _G.ClientTable and _G.ClientTable.cfg_Skill_skillManager then
                        skillDic = _G.ClientTable.cfg_Skill_skillManager:GetDic()
                    end
                    if not skillDic then
                        skillDic = package.loaded["Config/table/clientTable/cfg_Skill_skill"]
                    end
                    if skillDic then
                        for _, skillData in pairs(skillDic) do
                            if skillData.releaseDistance and type(skillData.releaseDistance) == "number" then
                                if not skillData._originalReleaseDistance then
                                    skillData._originalReleaseDistance = skillData.releaseDistance
                                end
                                if skillData._originalReleaseDistance > 0 and skillData._originalReleaseDistance < 9999 then
                                    skillData.releaseDistance = cells
                                end
                            end
                        end
                    end
                    if CS and CS.UnityEngine and CS.UnityEngine.Camera and CS.UnityEngine.Camera.main then
                        if cells > 10 then
                            CS.UnityEngine.Camera.main.farClipPlane = 1000
                            if CS.UnityEngine.RenderSettings then CS.UnityEngine.RenderSettings.fog = false end
                        end
                    end
                end)
            end
        end
        _G.Mod_ApplyAttackRangeMultiplier = _G.Mod_ApplyAttackRangeCells

        -- UI State Variables Initialization
        if _G.RunSpeedMultiplier == nil then
            _G.RunSpeedMultiplier = CS.UnityEngine.PlayerPrefs.GetFloat(
                "Mod_RunSpeedMultiplier", 1.0)
        end
        if _G.AtkSpeedMultiplier == nil then
            _G.AtkSpeedMultiplier = CS.UnityEngine.PlayerPrefs.GetFloat(
                "Mod_AtkSpeedMultiplier", 1.0)
        end
        if _G.Mod_CustomAttackRangeCells == nil then
            _G.Mod_CustomAttackRangeCells = CS.UnityEngine.PlayerPrefs.GetInt(
                "Mod_CustomAttackRangeCells", 8)
        end
        _G.Mod_CustomAttackRangeCells = math.max(1, math.min(15, _G.Mod_CustomAttackRangeCells))
        if _G.Mod_CustomAttackRange == nil then
            _G.Mod_CustomAttackRange = CS.UnityEngine.PlayerPrefs.GetInt(
                "Mod_CustomAttackRange", 0)
        end
        local maxRangeCap = math.min(15, _G.Mod_Config_MaxMonsterRange or 15)
        if _G.Mod_CustomAttackRange > maxRangeCap then
            _G.Mod_CustomAttackRange = maxRangeCap
            CS.UnityEngine.PlayerPrefs.SetInt("Mod_CustomAttackRange", _G.Mod_CustomAttackRange)
            CS.UnityEngine.PlayerPrefs.Save()
        end
        if _G.Mod_AutoApproachTowerBoss == nil then
            pcall(function() _G.Mod_AutoApproachTowerBoss = (CS.UnityEngine.PlayerPrefs.GetInt("Mod_AutoApproachTowerBoss", 0) == 1) end)
            if _G.Mod_AutoApproachTowerBoss == nil then _G.Mod_AutoApproachTowerBoss = false end
        end
        if _G.Mod_AntiCC == nil then _G.Mod_AntiCC = CS.UnityEngine.PlayerPrefs.GetInt("Mod_AntiCC", 0) == 1 end
        if _G.AutoPick_FilterNormal == nil then
            _G.AutoPick_FilterNormal = CS.UnityEngine.PlayerPrefs.GetInt(
                "Mod_AutoPick_FilterNormal", 0) == 1
        end
        if _G.AutoPick_Limit == nil then _G.AutoPick_Limit = CS.UnityEngine.PlayerPrefs.GetInt("Mod_AutoPick_Limit", 2) end
        if _G.AutoPick_Limit == 0 then _G.AutoPick_Limit = 2 end
        _G.AutoPick_Count = 0
        _G.Mod_PickedItems = {}

        local function CreateSpeedControl(startX, yPos, prefix, valueVarName, step)
            local centerX = startX + 90
            local valGo = GameObject(valueVarName .. "_Val")
            valGo.transform:SetParent(panelGo.transform, false)
            local vRt = valGo:AddComponent(typeof(RectTransform))
            vRt.anchorMin = Vector2(0, 1)
            vRt.anchorMax = Vector2(0, 1)
            vRt.pivot = Vector2(0, 1)
            vRt.anchoredPosition = Vector2(centerX - 80, yPos)
            vRt.sizeDelta = Vector2(160, 30)
            local vTxt = valGo:AddComponent(typeof(Text))
            table.insert(_G.CoBanUIList, valGo)
            vTxt.raycastTarget = false
            vTxt.text = string.format("%s%.1fx", prefix, _G[valueVarName])
            vTxt.alignment = TextAnchor.MiddleCenter
            vTxt.color = Color(0.8, 1, 0.8, 1)
            vTxt.fontSize = 18
            if defaultFont then vTxt.font = defaultFont end

            local function createBtn(nameSuffix, offsetX, w, h, text, color)
                local btnGo = GameObject(valueVarName .. nameSuffix)
                btnGo.transform:SetParent(panelGo.transform, false)
                local rt = btnGo:AddComponent(typeof(RectTransform))
                rt.anchorMin = Vector2(0, 1)
                rt.anchorMax = Vector2(0, 1)
                rt.pivot = Vector2(0, 1)
                rt.anchoredPosition = Vector2(centerX + offsetX, yPos)
                rt.sizeDelta = Vector2(w, h)
                local img = btnGo:AddComponent(typeof(Image))
                img.color = color
                local txtGo = GameObject(valueVarName .. nameSuffix .. "Txt")
                txtGo.transform:SetParent(btnGo.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin = Vector2(0, 0)
                txtRt.anchorMax = Vector2(1, 1)
                txtRt.sizeDelta = Vector2(0, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.text = text
                txt.color = Color.white
                txt.fontSize = 18
                txt.alignment = TextAnchor.MiddleCenter
                if defaultFont then txt.font = defaultFont end
                table.insert(_G.CoBanUIList, btnGo)
                return btnGo:AddComponent(typeof(Button))
            end

            local mBtnComp = createBtn("_Minus", -120, 40, 30, "-", Color(0.5, 0.2, 0.2, 1))
            local pBtnComp = createBtn("_Plus", 80, 40, 30, "+", Color(0.2, 0.5, 0.2, 1))
            local m5BtnComp = createBtn("_Minus5", -165, 40, 30, "-5", Color(0.5, 0.2, 0.2, 1))
            local p5BtnComp = createBtn("_Plus5", 125, 40, 30, "+5", Color(0.2, 0.5, 0.2, 1))

            local function UpdateLabel()
                vTxt.text = string.format("%s%.1fx", prefix, _G[valueVarName])
            end

            mBtnComp.onClick:AddListener(function()
                _G[valueVarName] = math.max(0.1, _G[valueVarName] - step)
                CS.UnityEngine.PlayerPrefs.SetFloat("Mod_" .. valueVarName, _G[valueVarName])
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
            pBtnComp.onClick:AddListener(function()
                local maxCap = 10.0
                if valueVarName == "RunSpeedMultiplier" then
                    maxCap = _G.Mod_Config_MaxMoveSpeed or 2.5
                elseif valueVarName == "AtkSpeedMultiplier" then
                    maxCap = _G.Mod_Config_MaxAttackSpeed or 2.5
                end
                _G[valueVarName] = math.min(maxCap, _G[valueVarName] + step)
                CS.UnityEngine.PlayerPrefs.SetFloat("Mod_" .. valueVarName, _G[valueVarName])
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
            m5BtnComp.onClick:AddListener(function()
                _G[valueVarName] = math.max(0.1, _G[valueVarName] - (step * 5))
                CS.UnityEngine.PlayerPrefs.SetFloat("Mod_" .. valueVarName, _G[valueVarName])
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
            p5BtnComp.onClick:AddListener(function()
                local maxCap = 10.0
                if valueVarName == "RunSpeedMultiplier" then
                    maxCap = _G.Mod_Config_MaxMoveSpeed or 2.5
                elseif valueVarName == "AtkSpeedMultiplier" then
                    maxCap = _G.Mod_Config_MaxAttackSpeed or 2.5
                end
                _G[valueVarName] = math.min(maxCap, _G[valueVarName] + (step * 5))
                CS.UnityEngine.PlayerPrefs.SetFloat("Mod_" .. valueVarName, _G[valueVarName])
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
        end

        CreateSpeedControl(415, -60, "Tốc Chạy: ", "RunSpeedMultiplier", 0.1)
        CreateSpeedControl(415, -100, "Tốc Đánh: ", "AtkSpeedMultiplier", 0.1)

        local function CreateAttackRangeCellsControl(startX, yPos, prefix, valueVarName, step)
            local centerX = startX + 90
            local valGo = GameObject(valueVarName .. "_Val")
            valGo.transform:SetParent(panelGo.transform, false)
            local vRt = valGo:AddComponent(typeof(RectTransform))
            vRt.anchorMin, vRt.anchorMax, vRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            vRt.anchoredPosition = Vector2(centerX - 80, yPos)
            vRt.sizeDelta = Vector2(160, 30)
            local vTxt = valGo:AddComponent(typeof(Text))
            table.insert(_G.CoBanUIList, valGo)
            vTxt.raycastTarget = false
            vTxt.text = string.format("%s%d ô", prefix, _G[valueVarName] or 8)
            vTxt.alignment = TextAnchor.MiddleCenter
            vTxt.color = Color(0.8, 1, 0.8, 1)
            vTxt.fontSize = 18
            if defaultFont then vTxt.font = defaultFont end

            local function createBtn(nameSuffix, offsetX, w, h, text, color)
                local btnGo = GameObject(valueVarName .. nameSuffix)
                btnGo.transform:SetParent(panelGo.transform, false)
                local rt = btnGo:AddComponent(typeof(RectTransform))
                rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                rt.anchoredPosition = Vector2(centerX + offsetX, yPos)
                rt.sizeDelta = Vector2(w, h)
                local img = btnGo:AddComponent(typeof(Image))
                img.color = color
                local txtGo = GameObject(valueVarName .. nameSuffix .. "Txt")
                txtGo.transform:SetParent(btnGo.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin, txtRt.anchorMax, txtRt.sizeDelta = Vector2(0, 0), Vector2(1, 1), Vector2(0, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget, txt.text, txt.color, txt.fontSize, txt.alignment = false, text, Color.white, 18, TextAnchor.MiddleCenter
                if defaultFont then txt.font = defaultFont end
                table.insert(_G.CoBanUIList, btnGo)
                return btnGo:AddComponent(typeof(Button))
            end

            local mBtnComp = createBtn("_Minus", -120, 40, 30, "-", Color(0.3, 0.3, 0.3, 1))
            local pBtnComp = createBtn("_Plus", 80, 40, 30, "+", Color(0.3, 0.3, 0.3, 1))

            local function UpdateLabel()
                vTxt.text = string.format("%s%d ô", prefix, _G[valueVarName] or 8)
                if _G.Mod_ApplyAttackRangeCells then
                    _G.Mod_ApplyAttackRangeCells(_G[valueVarName])
                end
            end

            mBtnComp.onClick:AddListener(function()
                _G[valueVarName] = math.max(1, (_G[valueVarName] or 8) - (step or 1))
                CS.UnityEngine.PlayerPrefs.SetInt(valueVarName, _G[valueVarName])
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
            pBtnComp.onClick:AddListener(function()
                _G[valueVarName] = math.min(15, (_G[valueVarName] or 8) + (step or 1))
                CS.UnityEngine.PlayerPrefs.SetInt(valueVarName, _G[valueVarName])
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
        end

        CreateAttackRangeCellsControl(70, -140, "Tầm Đánh: ", "Mod_CustomAttackRangeCells", 1)
        if _G.Mod_CustomAttackRangeCells and _G.Mod_ApplyAttackRangeCells then
            _G.Mod_ApplyAttackRangeCells(_G.Mod_CustomAttackRangeCells)
        end

        local function CreateRangeControl(startX, yPos, prefix, valueVarName, step)
            local centerX = startX + 90
            local valGo = GameObject(valueVarName .. "_Val")
            valGo.transform:SetParent(panelGo.transform, false)
            local vRt = valGo:AddComponent(typeof(RectTransform))
            vRt.anchorMin, vRt.anchorMax, vRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            vRt.anchoredPosition = Vector2(centerX - 80, yPos)
            vRt.sizeDelta = Vector2(160, 30)
            local vTxt = valGo:AddComponent(typeof(Text))
            table.insert(_G.CoBanUIList, valGo)
            vTxt.raycastTarget = false
            vTxt.text = string.format("%s%d", prefix, _G[valueVarName] or 0)
            vTxt.alignment = TextAnchor.MiddleCenter
            vTxt.color = Color(0.8, 1, 0.8, 1)
            vTxt.fontSize = 18
            if defaultFont then vTxt.font = defaultFont end

            local function createBtn(nameSuffix, offsetX, w, h, text, color)
                local btnGo = GameObject(valueVarName .. nameSuffix)
                btnGo.transform:SetParent(panelGo.transform, false)
                local rt = btnGo:AddComponent(typeof(RectTransform))
                rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                rt.anchoredPosition = Vector2(centerX + offsetX, yPos)
                rt.sizeDelta = Vector2(w, h)
                local img = btnGo:AddComponent(typeof(Image))
                img.color = color
                local txtGo = GameObject(valueVarName .. nameSuffix .. "Txt")
                txtGo.transform:SetParent(btnGo.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin, txtRt.anchorMax, txtRt.sizeDelta = Vector2(0, 0), Vector2(1, 1), Vector2(0, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget, txt.text, txt.color, txt.fontSize, txt.alignment = false, text, Color.white, 18,
                    TextAnchor.MiddleCenter
                if defaultFont then txt.font = defaultFont end
                table.insert(_G.CoBanUIList, btnGo)
                return btnGo:AddComponent(typeof(Button))
            end

            local mBtnComp = createBtn("_Minus", -120, 40, 30, "-", Color(0.5, 0.2, 0.2, 1))
            local pBtnComp = createBtn("_Plus", 80, 40, 30, "+", Color(0.2, 0.5, 0.2, 1))
            local m5BtnComp = createBtn("_Minus5", -165, 40, 30, "-5", Color(0.5, 0.2, 0.2, 1))
            local p5BtnComp = createBtn("_Plus5", 125, 40, 30, "+5", Color(0.2, 0.5, 0.2, 1))

            local function UpdateLabel()
                vTxt.text = string.format("%s%d", prefix, _G[valueVarName])
            end

            mBtnComp.onClick:AddListener(function()
                _G[valueVarName] = math.max(0, _G[valueVarName] - step)
                local prefKey = string.sub(valueVarName, 1, 4) == "Mod_" and valueVarName or ("Mod_" .. valueVarName)
                CS.UnityEngine.PlayerPrefs.SetInt(prefKey, _G[valueVarName])
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
            pBtnComp.onClick:AddListener(function()
                local maxCap = math.min(15, _G.Mod_Config_MaxMonsterRange or 15)
                _G[valueVarName] = math.min(maxCap, _G[valueVarName] + step)
                local prefKey = string.sub(valueVarName, 1, 4) == "Mod_" and valueVarName or ("Mod_" .. valueVarName)
                CS.UnityEngine.PlayerPrefs.SetInt(prefKey, _G[valueVarName])
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
            m5BtnComp.onClick:AddListener(function()
                _G[valueVarName] = math.max(0, _G[valueVarName] - (step * 5))
                local prefKey = string.sub(valueVarName, 1, 4) == "Mod_" and valueVarName or ("Mod_" .. valueVarName)
                CS.UnityEngine.PlayerPrefs.SetInt(prefKey, _G[valueVarName])
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
            p5BtnComp.onClick:AddListener(function()
                local maxCap = math.min(15, _G.Mod_Config_MaxMonsterRange or 15)
                _G[valueVarName] = math.min(maxCap, _G[valueVarName] + (step * 5))
                local prefKey = string.sub(valueVarName, 1, 4) == "Mod_" and valueVarName or ("Mod_" .. valueVarName)
                CS.UnityEngine.PlayerPrefs.SetInt(prefKey, _G[valueVarName])
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
        end
        CreateRangeControl(415, -140, "Phát Hiện Địch: ", "Mod_CustomAttackRange", 1)




        local function CreateToggle(label, varName, xPos, yPos, optWidth)
            local prefKey = string.sub(varName, 1, 4) == "Mod_" and varName or ("Mod_" .. varName)
            if _G[varName] == nil then
                pcall(function()
                    _G[varName] = (CS.UnityEngine.PlayerPrefs.GetInt(prefKey, 0) == 1)
                end)
                if _G[varName] == nil then _G[varName] = false end
            end

            local tGo = GameObject(varName .. "_Toggle")
            tGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, tGo)

            local btnW = optWidth or 330
            local tRt = tGo:AddComponent(typeof(RectTransform))
            tRt.anchorMin, tRt.anchorMax, tRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            tRt.anchoredPosition = Vector2(xPos, yPos)
            tRt.sizeDelta = Vector2(btnW, 34)

            local bg = GameObject("Bg")
            bg.transform:SetParent(tGo.transform, false)
            local bgRt = bg:AddComponent(typeof(RectTransform))
            bgRt.anchorMin, bgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            bgRt.sizeDelta = Vector2(0, 0)
            local bgImg = bg:AddComponent(typeof(Image))

            local txtGo = GameObject("Text")
            txtGo.transform:SetParent(tGo.transform, false)
            local txtRt = txtGo:AddComponent(typeof(RectTransform))
            txtRt.anchorMin, txtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            txtRt.sizeDelta = Vector2(0, 0)
            local txt = txtGo:AddComponent(typeof(Text))
            txt.raycastTarget = false
            txt.fontSize = (btnW < 160) and 14 or 16
            txt.alignment = TextAnchor.MiddleCenter
            if defaultFont then txt.font = defaultFont end

            local btn = tGo:AddComponent(typeof(Button))

            local function UpdateLabel(overrideCount)
                local extra = ""
                -- =========================================================================
                -- [MOD FEATURE]: ẨN SỐ ĐẾM ITEM CHO TỰ ĐỘNG NHẶT (CUSTOMER)
                -- Mô tả: Không hiển thị số lượng item đã nhặt (AutoPick_Count) đằng sau nút TỰ ĐỘNG NHẶT
                -- =========================================================================
                if varName == "Mod_AutoOpenGoldenChest_Enabled" then
                    local totalOddCount = overrideCount
                    if not totalOddCount then
                        pcall(function()
                            local items = _G.BagInfoData and _G.BagInfoData.TotalItems
                            if not items and _G.BagInfoData and _G.BagInfoData.GetTotalItems then
                                pcall(function() items = _G.BagInfoData:GetTotalItems() end)
                            end
                            if items then
                                totalOddCount = 0
                                for k, item in pairs(items) do
                                    if item then
                                        local tblItem = item.tblItem or (item.data and item.data.tblItem) or {}
                                        local name = tblItem.name or item.name or ""
                                        local itemCount = item.count or (item.data and item.data.count) or 1
                                        local itemType = tblItem.type or 0
                                        if itemType == 5 and string.find(name, "Rương Vàng") then
                                            local tierNum = tonumber(string.match(name, "%+(%d+)"))
                                            if tierNum and (tierNum % 2 ~= 0) then
                                                totalOddCount = totalOddCount + itemCount
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end
                    if totalOddCount and totalOddCount > 0 then
                        extra = " (" .. tostring(totalOddCount) .. ")"
                    end
                end
                local newTxt = label .. extra
                if txt.text ~= newTxt then txt.text = newTxt end
                if _G[varName] then
                    bgImg.color = Color(0.2, 0.5, 0.2, 1)
                    txt.color = Color.white
                else
                    bgImg.color = Color(0.3, 0.3, 0.3, 1)
                    txt.color = Color(0.7, 0.7, 0.7, 1)
                end
            end
            UpdateLabel()

            if varName == "AutoPick_Enabled" then
                _G.ModUpdateCountText = function()
                    pcall(UpdateLabel)
                end
            elseif varName == "Mod_AutoOpenGoldenChest_Enabled" then
                _G.ModUpdateGoldenChestLabel = function(optCount)
                    pcall(function() UpdateLabel(optCount) end)
                end
            elseif varName == "Mod_DisableVisuals" then
                _G.ModUpdateDisableVisualsLabel = function()
                    pcall(UpdateLabel)
                end
            elseif varName == "Mod_FindHoaLong_Enabled" then
                _G.ModUpdateFindHoaLongLabel = function()
                    pcall(UpdateLabel)
                end
            end

            btn.onClick:AddListener(function()
                _G[varName] = not _G[varName]
                if varName == "AutoPick_Enabled" and _G[varName] then
                    _G.AutoPick_Count = 0
                    _G.LastPickupTime = 0
                    _G.Mod_IgnoredDropItems = {}
                    _G.Mod_AllDropItems = {}
                    _G.Mod_PickedItems = {}
                end

                if varName == "Mod_AutoOpenGoldenChest_Enabled" then
                    if _G[varName] and _G.Mod_ExecuteGoldenChestAutoProcess then
                        pcall(_G.Mod_ExecuteGoldenChestAutoProcess)
                    end
                end

                if varName == "Mod_DisableVisuals" then
                    if _G.Mod_ApplyDisableVisualsState then
                        pcall(_G.Mod_ApplyDisableVisualsState)
                    end
                end

                if varName == "Mod_FindHoaLong_Enabled" then
                    if _G[varName] then
                        if _G.Mod_StartFindHoaLongLoop then
                            pcall(_G.Mod_StartFindHoaLongLoop)
                        end
                    else
                        _G.Mod_StopTimer("Mod_FindHoaLongLoop")
                    end
                end

                local prefKey = string.sub(varName, 1, 4) == "Mod_" and varName or ("Mod_" .. varName)
                CS.UnityEngine.PlayerPrefs.SetInt(prefKey, _G[varName] and 1 or 0)
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
                pcall(function()
                    if _G.EventManager and _G.Event and _G.Event.QiJiHelper_SetAutoPickup then
                        _G.EventManager.Dispatch(_G.Event.QiJiHelper_SetAutoPickup)
                    end
                end)
            end)

            if varName == "Mod_AutoOpenGoldenChest_Enabled" then
                _G.Mod_GoldenChestToggleGo = tGo
            elseif varName == "Mod_DisableVisuals" then
                _G.Mod_DisableVisualsToggleGo = tGo
            elseif varName == "Mod_FindHoaLong_Enabled" then
                _G.Mod_FindHoaLongToggleGo = tGo
            end
            return tGo
        end

        local function CreateSmallToggle(label, varName, xPos, yPos, width)
            local tGo = GameObject(varName .. "_Toggle")
            tGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, tGo)

            local tRt = tGo:AddComponent(typeof(RectTransform))
            tRt.anchorMin, tRt.anchorMax, tRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            tRt.anchoredPosition = Vector2(xPos, yPos)
            tRt.sizeDelta = Vector2(width, 30)

            local bg = GameObject("Bg")
            bg.transform:SetParent(tGo.transform, false)
            local bgRt = bg:AddComponent(typeof(RectTransform))
            bgRt.anchorMin, bgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            bgRt.sizeDelta = Vector2(0, 0)
            local bgImg = bg:AddComponent(typeof(Image))

            local txtGo = GameObject("Text")
            txtGo.transform:SetParent(tGo.transform, false)
            local txtRt = txtGo:AddComponent(typeof(RectTransform))
            txtRt.anchorMin, txtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            txtRt.sizeDelta = Vector2(0, 0)
            local txt = txtGo:AddComponent(typeof(Text))
            txt.raycastTarget = false
            txt.fontSize = 15
            txt.alignment = TextAnchor.MiddleCenter
            if defaultFont then txt.font = defaultFont end

            local btn = tGo:AddComponent(typeof(Button))

            local function UpdateLabel()
                if _G[varName] then
                    bgImg.color = Color(0.2, 0.5, 0.2, 1)
                    txt.text = label
                    txt.color = Color.white
                else
                    bgImg.color = Color(0.3, 0.3, 0.3, 1)
                    txt.text = label
                    txt.color = Color(0.7, 0.7, 0.7, 1)
                end
            end
            UpdateLabel()

            btn.onClick:AddListener(function()
                _G[varName] = not _G[varName]
                local prefKey = string.sub(varName, 1, 4) == "Mod_" and varName or ("Mod_" .. varName)
                CS.UnityEngine.PlayerPrefs.SetInt(prefKey, _G[varName] and 1 or 0)
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLabel()
            end)
        end

        -- =========================================================================
        -- [MOD FEATURE]: THÔNG BÁO KUNDUN XUẤT HIỆN (IN-GAME STROBE ALERT - CUSTOMER)
        -- Mô tả: Quét định kỳ 5s/lần. Khi Kundun Thánh Cốt / Phù Văn (C3..C12) được chọn
        --        đã xuất hiện (x == y), phát thông báo nổi nhấp nháy đỏ-vàng ra giữa màn hình.
        -- =========================================================================
        _G.Mod_KundunNotify = _G.Mod_KundunNotify or {}
        _G.Mod_KundunNotify.Limits = {
            [16] = { [4] = 40, [5] = 70, [6] = 70, [7] = 70, [8] = 70, [9] = 70, [10] = 70, [11] = 70, [12] = 70, [13] = 70, [14] = 70, [15] = 70 },
            [17] = { [6] = 200, [7] = 300, [8] = 400, [9] = 500, [10] = 500, [11] = 500, [12] = 500, [13] = 500, [14] = 500, [15] = 500 }
        }

        _G.Mod_KundunNotify.GetLimit = function(bossType, tier)
            local bossId = (bossType == 16) and (20201000 + tier) or (20211000 + tier)
            if _G.ClientTable and _G.ClientTable.cfg_Monster_bossManager then
                local cfg = _G.ClientTable.cfg_Monster_bossManager:TryGetValue(bossId)
                if cfg and cfg.yuanGuMonsterKillNum and cfg.yuanGuMonsterKillNum > 0 then
                    return cfg.yuanGuMonsterKillNum
                end
            end
            local limits = _G.Mod_KundunNotify.Limits
            if limits and limits[bossType] and limits[bossType][tier] then
                return limits[bossType][tier]
            end
            return (bossType == 16) and 70 or 500
        end

        _G.Mod_KundunNotify.CheckSpawned = function(bossType, tier)
            local bossId = (bossType == 16) and (20201000 + tier) or (20211000 + tier)
            local limit = _G.Mod_KundunNotify.GetLimit(bossType, tier)
            if limit <= 0 then return false end
            if _G.SceneData and _G.SceneData.GetAncientBossData then
                local isSatisfy, info = _G.SceneData:GetAncientBossData(bossType, bossId)
                if isSatisfy == true then
                    return true
                end
                if info and info.count and info.count >= limit then
                    return true
                end
            end
            return false
        end

        _G.Mod_KundunNotify.FlashAlert = function(msg)
            local alertText = "<size=22><b><color=#FFFF00>⚠️ " .. msg .. " ⚠️</color></b></size>"
            if _G.FloatingTipUtility and _G.FloatingTipUtility.QuickMsg then
                _G.FloatingTipUtility.QuickMsg(alertText)
            elseif _G.FloatingWordUtility and _G.FloatingWordUtility.QuickMsg then
                _G.FloatingWordUtility.QuickMsg(alertText)
            end
        end

        _G.Mod_KundunNotifyTimer = nil

        _G.Mod_KundunNotify.DoScan = function()
            if not _G.AutoPick_KundunNotify_Enabled then return end
            pcall(function()
                -- Gửi yêu cầu cập nhật tiến độ boss mới nhất từ server
                if _G.networkRequest and _G.networkRequest.ReqAncientBossInfo then
                    _G.networkRequest.ReqAncientBossInfo(16)
                    _G.networkRequest.ReqAncientBossInfo(17)
                elseif _G.NetManager and _G.MapMessage and _G.MapMessage.ReqAncientBossInfo then
                    _G.NetManager.Send(_G.MapMessage.ReqAncientBossInfo, { type = 16 })
                    _G.NetManager.Send(_G.MapMessage.ReqAncientBossInfo, { type = 17 })
                end

                local spawnedTC = {}
                for t = 4, 15 do
                    if _G["Mod_KundunNotify_TC_C" .. t] then
                        if _G.Mod_KundunNotify.CheckSpawned(16, t) then
                            table.insert(spawnedTC, "C" .. t)
                        end
                    end
                end

                local spawnedPV = {}
                for t = 6, 15 do
                    if _G["Mod_KundunNotify_PV_C" .. t] then
                        if _G.Mod_KundunNotify.CheckSpawned(17, t) then
                            table.insert(spawnedPV, "C" .. t)
                        end
                    end
                end

                if #spawnedTC > 0 then
                    local msgTC = "Kundun thánh cốt " .. table.concat(spawnedTC, "-") .. " đã hiện"
                    _G.Mod_KundunNotify.FlashAlert(msgTC)
                end

                if #spawnedPV > 0 then
                    local msgPV = "Kundun phù văn " .. table.concat(spawnedPV, "-") .. " đã hiện"
                    if #spawnedTC > 0 then
                        if _G.Timer and _G.Timer.Start then
                            _G.Timer.Start(0.8, function()
                                _G.Mod_KundunNotify.FlashAlert(msgPV)
                            end)
                        else
                            _G.Mod_KundunNotify.FlashAlert(msgPV)
                        end
                    else
                        _G.Mod_KundunNotify.FlashAlert(msgPV)
                    end
                end
            end)
        end

        _G.Mod_StartKundunNotifyLoop = function()
            if _G.Mod_KundunNotifyTimer then
                if _G.Timer and _G.Timer.Stop then
                    _G.Timer.Stop(_G.Mod_KundunNotifyTimer)
                end
                _G.Mod_KundunNotifyTimer = nil
            end
            if _G.Timer and _G.Timer.StartLoop then
                _G.Mod_KundunNotifyTimer = _G.Timer.StartLoop(5.0, -1, _G.Mod_KundunNotify.DoScan)
            end
            _G.Mod_KundunNotify.DoScan()
        end

        _G.Mod_StopKundunNotifyLoop = function()
            if _G.Mod_KundunNotifyTimer then
                if _G.Timer and _G.Timer.Stop then
                    _G.Timer.Stop(_G.Mod_KundunNotifyTimer)
                end
                _G.Mod_KundunNotifyTimer = nil
            end
        end

        -- Khôi phục cấu hình Kundun Notify từ PlayerPrefs
        _G.AutoPick_KundunNotify_Enabled = (CS.UnityEngine.PlayerPrefs.GetInt("Mod_AutoPick_KundunNotify_Enabled", 0) == 1)
        for t = 4, 15 do
            _G["Mod_KundunNotify_TC_C" .. t] = (CS.UnityEngine.PlayerPrefs.GetInt("Mod_KundunNotify_TC_C" .. t, 0) == 1)
        end
        for t = 6, 15 do
            _G["Mod_KundunNotify_PV_C" .. t] = (CS.UnityEngine.PlayerPrefs.GetInt("Mod_KundunNotify_PV_C" .. t, 0) == 1)
        end
        if _G.AutoPick_KundunNotify_Enabled and _G.Mod_StartKundunNotifyLoop then
            pcall(_G.Mod_StartKundunNotifyLoop)
        end

        local function CreateAutoLootUI()
            local leftColX = 15
            local currentY = -58

            local titleGo = GameObject("AutoLootTitle")
            titleGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, titleGo)
            local titleRt = titleGo:AddComponent(typeof(RectTransform))
            titleRt.anchorMin, titleRt.anchorMax, titleRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            titleRt.anchoredPosition = Vector2(leftColX + 5, currentY)
            titleRt.sizeDelta = Vector2(320, 22)
            local titleTxt = titleGo:AddComponent(typeof(Text))
            titleTxt.raycastTarget = false
            titleTxt.text = "[ NHẶT ĐỒ SIÊU TỐC ]"
            titleTxt.color = Color(1, 0.8, 0, 1)
            titleTxt.fontSize = 18
            titleTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then titleTxt.font = defaultFont end

            currentY = currentY - 30

            CreateToggle("TỰ ĐỘNG NHẶT", "AutoPick_Enabled", leftColX, currentY)
            currentY = currentY - 42

            -- Limit Control
            local lValGo = GameObject("LimitValText")
            lValGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, lValGo)
            local lvRt = lValGo:AddComponent(typeof(RectTransform))
            lvRt.anchorMin = Vector2(0, 1)
            lvRt.anchorMax = Vector2(0, 1)
            lvRt.pivot = Vector2(0, 1)
            lvRt.anchoredPosition = Vector2(leftColX + 5, currentY)
            lvRt.sizeDelta = Vector2(215, 32)
            local lvTxt = lValGo:AddComponent(typeof(Text))
            lvTxt.raycastTarget = false
            lvTxt.text = "SỐ LƯỢNG NHẶT: " .. tostring(_G.AutoPick_Limit)
            lvTxt.color = Color.white
            lvTxt.fontSize = 18
            lvTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then lvTxt.font = defaultFont end

            local lMinusGo = GameObject("LimitMinusBtn")
            lMinusGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, lMinusGo)
            local lmRt = lMinusGo:AddComponent(typeof(RectTransform))
            lmRt.anchorMin = Vector2(0, 1)
            lmRt.anchorMax = Vector2(0, 1)
            lmRt.pivot = Vector2(0, 1)
            lmRt.anchoredPosition = Vector2(leftColX + 225, currentY)
            lmRt.sizeDelta = Vector2(45, 32)
            local lmImg = lMinusGo:AddComponent(typeof(Image))
            lmImg.color = Color(0.4, 0.4, 0.4, 1)
            local lmTxtGo = GameObject("LimitMinusText")
            lmTxtGo.transform:SetParent(lMinusGo.transform, false)
            local lmTxtRt = lmTxtGo:AddComponent(typeof(RectTransform))
            lmTxtRt.anchorMin = Vector2(0, 0)
            lmTxtRt.anchorMax = Vector2(1, 1)
            lmTxtRt.sizeDelta = Vector2(0, 0)
            local lmTxt = lmTxtGo:AddComponent(typeof(Text))
            lmTxt.raycastTarget = false
            lmTxt.text = "-"
            lmTxt.color = Color.white
            lmTxt.fontSize = 20
            lmTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then lmTxt.font = defaultFont end

            local lPlusGo = GameObject("LimitPlusBtn")
            lPlusGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, lPlusGo)
            local lpRt = lPlusGo:AddComponent(typeof(RectTransform))
            lpRt.anchorMin = Vector2(0, 1)
            lpRt.anchorMax = Vector2(0, 1)
            lpRt.pivot = Vector2(0, 1)
            lpRt.anchoredPosition = Vector2(leftColX + 278, currentY)
            lpRt.sizeDelta = Vector2(45, 32)
            local lpImg = lPlusGo:AddComponent(typeof(Image))
            lpImg.color = Color(0.4, 0.4, 0.4, 1)
            local lpTxtGo = GameObject("LimitPlusText")
            lpTxtGo.transform:SetParent(lPlusGo.transform, false)
            local lpTxtRt = lpTxtGo:AddComponent(typeof(RectTransform))
            lpTxtRt.anchorMin = Vector2(0, 0)
            lpTxtRt.anchorMax = Vector2(1, 1)
            lpTxtRt.sizeDelta = Vector2(0, 0)
            local lpTxt = lpTxtGo:AddComponent(typeof(Text))
            lpTxt.raycastTarget = false
            lpTxt.text = "+"
            lpTxt.color = Color.white
            lpTxt.fontSize = 20
            lpTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then lpTxt.font = defaultFont end

            local lmBtnComp = lMinusGo:AddComponent(typeof(Button))
            lmBtnComp.onClick:AddListener(function()
                if _G.AutoPick_Limit > 1 then
                    _G.AutoPick_Limit = _G.AutoPick_Limit - 1
                    CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoPick_Limit", _G.AutoPick_Limit)
                    CS.UnityEngine.PlayerPrefs.Save()
                    lvTxt.text = "SỐ LƯỢNG NHẶT: " .. tostring(_G.AutoPick_Limit)
                end
            end)

            local lpBtnComp = lPlusGo:AddComponent(typeof(Button))
            lpBtnComp.onClick:AddListener(function()
                local maxCap = _G.Mod_Config_MaxPickupCount or 5
                if (_G.AutoPick_Limit or 0) < maxCap then
                    _G.AutoPick_Limit = (_G.AutoPick_Limit or 0) + 1
                else
                    _G.AutoPick_Limit = maxCap
                end
                CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoPick_Limit", _G.AutoPick_Limit)
                CS.UnityEngine.PlayerPrefs.Save()
                lvTxt.text = "SỐ LƯỢNG NHẶT: " .. tostring(_G.AutoPick_Limit)
            end)

            -- Move options from Kundun UI
            currentY = currentY - 36
            local sep2Go = GameObject("BossThapSeparator")
            sep2Go.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, sep2Go)
            local sep2Rt = sep2Go:AddComponent(typeof(RectTransform))
            sep2Rt.anchorMin = Vector2(0, 1)
            sep2Rt.anchorMax = Vector2(0, 1)
            sep2Rt.pivot = Vector2(0, 1)
            sep2Rt.anchoredPosition = Vector2(leftColX, currentY)
            sep2Rt.sizeDelta = Vector2(330, 20)
            local sep2Txt = sep2Go:AddComponent(typeof(Text))
            sep2Txt.raycastTarget = false
            sep2Txt.color = Color(0.4, 0.4, 0.4, 1)
            sep2Txt.fontSize = 13
            sep2Txt.alignment = TextAnchor.MiddleLeft
            sep2Txt.horizontalOverflow = CS.UnityEngine.HorizontalWrapMode.Overflow
            sep2Txt.verticalOverflow = CS.UnityEngine.VerticalWrapMode.Overflow
            if defaultFont then sep2Txt.font = defaultFont end
            sep2Txt.text = "--------------------------------------------------------------------------------"

            currentY = currentY - 26
            local titleGo = GameObject("KundunTitle")
            titleGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, titleGo)
            local titleRt = titleGo:AddComponent(typeof(RectTransform))
            titleRt.anchorMin = Vector2(0, 1)
            titleRt.anchorMax = Vector2(0, 1)
            titleRt.pivot = Vector2(0, 1)
            titleRt.anchoredPosition = Vector2(leftColX + 5, currentY)
            titleRt.sizeDelta = Vector2(320, 22)
            local titleTxt = titleGo:AddComponent(typeof(Text))
            titleTxt.raycastTarget = false
            titleTxt.text = "[ INFO KUNDUN BOSS ]"
            titleTxt.color = Color(1, 0.8, 0, 1)
            titleTxt.fontSize = 18
            titleTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then titleTxt.font = defaultFont end

            currentY = currentY - 30

            _G.ModKundunBossTab = _G.ModKundunBossTab or "C8"
            -- Tab C7 / C8
            local function CreateTabBtn(label, tabName, xPos, yPos)
                local btnGo = GameObject("NangCaoTab_" .. tabName)
                btnGo.transform:SetParent(panelGo.transform, false)
                table.insert(_G.NangCaoUIList, btnGo)
                local rt = btnGo:AddComponent(typeof(RectTransform))
                rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                rt.anchoredPosition = Vector2(xPos, yPos)
                rt.sizeDelta = Vector2(105, 30)

                local img = btnGo:AddComponent(typeof(CS.UnityEngine.UI.Image))
                img.color = CS.UnityEngine.Color(1, 1, 1, 0)

                local txtGo = GameObject("Text")
                txtGo.transform:SetParent(btnGo.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin, txtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                txtRt.sizeDelta = Vector2(0, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.color = Color.white
                txt.fontSize = 17
                txt.alignment = TextAnchor.MiddleLeft
                if defaultFont then txt.font = defaultFont end

                local btn = btnGo:AddComponent(typeof(Button))
                btn.onClick:AddListener(function()
                    _G.ModKundunBossTab = tabName
                    if _G.ModUpdateKundunUI then _G.ModUpdateKundunUI() end
                end)
                return { go = btnGo, txt = txt, btn = btn }
            end

            local kundunTabY = currentY
            local tierTags = { "C3", "C4", "C5", "C6", "C7", "C8", "C9", "C10", "C11", "C12" }
            _G.NangCaoTabBtns = {}
            for tIdx, tag in ipairs(tierTags) do
                local tabBtn = CreateTabBtn("[ BOSS " .. tag .. " ]", tag, leftColX + (tIdx - 1) * 110, kundunTabY)
                tabBtn.txt.fontSize = 17
                _G.NangCaoTabBtns[tag] = tabBtn
            end

            currentY = kundunTabY - 34

            local sep3Go = GameObject("BossThapSeparator")
            sep3Go.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, sep3Go)
            local sep3Rt = sep3Go:AddComponent(typeof(RectTransform))
            sep3Rt.anchorMin = Vector2(0, 1)
            sep3Rt.anchorMax = Vector2(0, 1)
            sep3Rt.pivot = Vector2(0, 1)
            sep3Rt.anchoredPosition = Vector2(leftColX, currentY)
            sep3Rt.sizeDelta = Vector2(330, 20)
            local sep3Txt = sep3Go:AddComponent(typeof(Text))
            sep3Txt.raycastTarget = false
            sep3Txt.color = Color(0.4, 0.4, 0.4, 1)
            sep3Txt.fontSize = 13
            sep3Txt.alignment = TextAnchor.MiddleLeft
            sep3Txt.horizontalOverflow = CS.UnityEngine.HorizontalWrapMode.Overflow
            sep3Txt.verticalOverflow = CS.UnityEngine.VerticalWrapMode.Overflow
            if defaultFont then sep3Txt.font = defaultFont end
            sep3Txt.text = "--------------------------------------------------------------------------------"

            currentY = currentY - 24
            _G.KundunUILabelPool = {}
            for i = 1, 2 do
                local rowGo = GameObject("KundunRow_" .. i)
                rowGo.transform:SetParent(panelGo.transform, false)
                table.insert(_G.NangCaoUIList, rowGo)
                local rt = rowGo:AddComponent(typeof(RectTransform))
                rt.anchorMin = Vector2(0, 1)
                rt.anchorMax = Vector2(0, 1)
                rt.pivot = Vector2(0, 1)
                rt.anchoredPosition = Vector2(leftColX + 5, currentY)
                rt.sizeDelta = Vector2(325, 25)
                local txt = rowGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.color = Color.white
                txt.fontSize = 17
                txt.alignment = TextAnchor.MiddleLeft
                if defaultFont then txt.font = defaultFont end
                txt.text = ""

                table.insert(_G.KundunUILabelPool, txt)
                currentY = currentY - 28
            end

            -- =========================================================================
            -- [MOD FEATURE]: THÔNG BÁO KUNDUN BOSS UI (CUSTOMER LEFT COLUMN)
            -- Mô tả: Khối chọn thông báo Kundun Thánh Cốt & Phù Văn (C3..C12) và Toggle kích hoạt
            -- =========================================================================
            currentY = currentY - 6
            local sepNotifyGo = GameObject("KundunNotifySeparator")
            sepNotifyGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, sepNotifyGo)
            local sepNotifyRt = sepNotifyGo:AddComponent(typeof(RectTransform))
            sepNotifyRt.anchorMin, sepNotifyRt.anchorMax, sepNotifyRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            sepNotifyRt.anchoredPosition = Vector2(leftColX, currentY)
            sepNotifyRt.sizeDelta = Vector2(330, 16)
            local sepNotifyTxt = sepNotifyGo:AddComponent(typeof(Text))
            sepNotifyTxt.raycastTarget = false
            sepNotifyTxt.color = Color(0.4, 0.4, 0.4, 1)
            sepNotifyTxt.fontSize = 13
            sepNotifyTxt.alignment = TextAnchor.MiddleLeft
            sepNotifyTxt.horizontalOverflow = CS.UnityEngine.HorizontalWrapMode.Overflow
            sepNotifyTxt.verticalOverflow = CS.UnityEngine.VerticalWrapMode.Overflow
            if defaultFont then sepNotifyTxt.font = defaultFont end
            sepNotifyTxt.text = "--------------------------------------------------------------------------------"

            currentY = currentY - 22
            local titleNotifyGo = GameObject("KundunNotifyTitle")
            titleNotifyGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, titleNotifyGo)
            local titleNotifyRt = titleNotifyGo:AddComponent(typeof(RectTransform))
            titleNotifyRt.anchorMin, titleNotifyRt.anchorMax, titleNotifyRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            titleNotifyRt.anchoredPosition = Vector2(leftColX + 5, currentY)
            titleNotifyRt.sizeDelta = Vector2(320, 22)
            local titleNotifyTxt = titleNotifyGo:AddComponent(typeof(Text))
            titleNotifyTxt.raycastTarget = false
            titleNotifyTxt.text = "[ THÔNG BÁO KUNDUN BOSS ]"
            titleNotifyTxt.color = Color(1, 0.8, 0, 1)
            titleNotifyTxt.fontSize = 18
            titleNotifyTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then titleNotifyTxt.font = defaultFont end

            currentY = currentY - 32
            -- Toggle THÔNG BÁO XUẤT HIỆN (Full width 330px, height 34px)
            local notifToggleGo = GameObject("AutoPick_KundunNotify_Enabled_Toggle")
            notifToggleGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, notifToggleGo)
            local notifTRt = notifToggleGo:AddComponent(typeof(RectTransform))
            notifTRt.anchorMin, notifTRt.anchorMax, notifTRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            notifTRt.anchoredPosition = Vector2(leftColX, currentY)
            notifTRt.sizeDelta = Vector2(330, 34)

            local notifBg = GameObject("Bg")
            notifBg.transform:SetParent(notifToggleGo.transform, false)
            local notifBgRt = notifBg:AddComponent(typeof(RectTransform))
            notifBgRt.anchorMin, notifBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            notifBgRt.sizeDelta = Vector2(0, 0)
            local notifBgImg = notifBg:AddComponent(typeof(Image))

            local notifTxtGo = GameObject("Text")
            notifTxtGo.transform:SetParent(notifToggleGo.transform, false)
            local notifTxtRt = notifTxtGo:AddComponent(typeof(RectTransform))
            notifTxtRt.anchorMin, notifTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            notifTxtRt.sizeDelta = Vector2(0, 0)
            local notifTxt = notifTxtGo:AddComponent(typeof(Text))
            notifTxt.raycastTarget = false
            notifTxt.fontSize = 16
            notifTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then notifTxt.font = defaultFont end

            local function UpdateCustomerKundunNotifyMasterLabel()
                if _G.AutoPick_KundunNotify_Enabled then
                    notifBgImg.color = Color(0.2, 0.5, 0.2, 1)
                    notifTxt.text = "THÔNG BÁO XUẤT HIỆN"
                    notifTxt.color = Color.white
                else
                    notifBgImg.color = Color(0.3, 0.3, 0.3, 1)
                    notifTxt.text = "THÔNG BÁO XUẤT HIỆN"
                    notifTxt.color = Color(0.7, 0.7, 0.7, 1)
                end
            end
            UpdateCustomerKundunNotifyMasterLabel()

            local notifBtn = notifToggleGo:AddComponent(typeof(Button))
            notifBtn.onClick:AddListener(function()
                _G.AutoPick_KundunNotify_Enabled = not _G.AutoPick_KundunNotify_Enabled
                CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoPick_KundunNotify_Enabled", _G.AutoPick_KundunNotify_Enabled and 1 or 0)
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateCustomerKundunNotifyMasterLabel()
                if _G.AutoPick_KundunNotify_Enabled then
                    if _G.Mod_StartKundunNotifyLoop then pcall(_G.Mod_StartKundunNotifyLoop) end
                else
                    if _G.Mod_StopKundunNotifyLoop then pcall(_G.Mod_StopKundunNotifyLoop) end
                end
            end)

            -- Helper nút chọn tier cho Customer
            local function CreateCustomerKundunTierToggle(label, varName, xPos, yPos, w, h)
                local tGo = GameObject(varName .. "_Toggle")
                tGo.transform:SetParent(panelGo.transform, false)
                table.insert(_G.NangCaoUIList, tGo)
                local rt = tGo:AddComponent(typeof(RectTransform))
                rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                rt.anchoredPosition = Vector2(xPos, yPos)
                rt.sizeDelta = Vector2(w or 58, h or 24)

                local bg = GameObject("Bg")
                bg.transform:SetParent(tGo.transform, false)
                local bgRt = bg:AddComponent(typeof(RectTransform))
                bgRt.anchorMin, bgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                bgRt.sizeDelta = Vector2(0, 0)
                local bgImg = bg:AddComponent(typeof(Image))

                local tg = GameObject("Text")
                tg.transform:SetParent(tGo.transform, false)
                local trt = tg:AddComponent(typeof(RectTransform))
                trt.anchorMin, trt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                trt.sizeDelta = Vector2(0, 0)
                local tt = tg:AddComponent(typeof(Text))
                tt.raycastTarget = false
                tt.fontSize = 13
                tt.alignment = TextAnchor.MiddleCenter
                if defaultFont then tt.font = defaultFont end

                local function UpdateState()
                    if _G[varName] then
                        bgImg.color = Color(0.2, 0.5, 0.2, 1)
                        tt.text = label
                        tt.color = Color.white
                    else
                        bgImg.color = Color(0.3, 0.3, 0.3, 1)
                        tt.text = label
                        tt.color = Color(0.7, 0.7, 0.7, 1)
                    end
                end
                UpdateState()

                local b = tGo:AddComponent(typeof(Button))
                b.onClick:AddListener(function()
                    _G[varName] = not _G[varName]
                    CS.UnityEngine.PlayerPrefs.SetInt(varName, _G[varName] and 1 or 0)
                    CS.UnityEngine.PlayerPrefs.Save()
                    UpdateState()
                end)
            end

            -- Nhãn Thánh Cốt
            currentY = currentY - 38
            local tcLblGo = GameObject("KundunNotify_TCLbl")
            tcLblGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, tcLblGo)
            local tcLblRt = tcLblGo:AddComponent(typeof(RectTransform))
            tcLblRt.anchorMin, tcLblRt.anchorMax, tcLblRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            tcLblRt.anchoredPosition = Vector2(leftColX + 5, currentY)
            tcLblRt.sizeDelta = Vector2(200, 18)
            local tcLblTxt = tcLblGo:AddComponent(typeof(Text))
            tcLblTxt.raycastTarget = false
            tcLblTxt.text = "Thánh Cốt:"
            tcLblTxt.color = Color(1, 1, 0.5, 1)
            tcLblTxt.fontSize = 15
            tcLblTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then tcLblTxt.font = defaultFont end

            -- Hàng 1 Thánh Cốt (C4..C9) và Hàng 2 (C10..C15)
            local custBtnW = 50
            local custGap = 6
            currentY = currentY - 24
            for i, t in ipairs({ 4, 5, 6, 7, 8, 9 }) do
                local x = leftColX + (i - 1) * (custBtnW + custGap)
                CreateCustomerKundunTierToggle("C" .. t, "Mod_KundunNotify_TC_C" .. t, x, currentY, custBtnW, 24)
            end

            currentY = currentY - 28
            for i, t in ipairs({ 10, 11, 12, 13, 14, 15 }) do
                local x = leftColX + (i - 1) * (custBtnW + custGap)
                CreateCustomerKundunTierToggle("C" .. t, "Mod_KundunNotify_TC_C" .. t, x, currentY, custBtnW, 24)
            end

            -- Nhãn Phù Văn
            currentY = currentY - 32
            local pvLblGo = GameObject("KundunNotify_PVLbl")
            pvLblGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, pvLblGo)
            local pvLblRt = pvLblGo:AddComponent(typeof(RectTransform))
            pvLblRt.anchorMin, pvLblRt.anchorMax, pvLblRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            pvLblRt.anchoredPosition = Vector2(leftColX + 5, currentY)
            pvLblRt.sizeDelta = Vector2(200, 18)
            local pvLblTxt = pvLblGo:AddComponent(typeof(Text))
            pvLblTxt.raycastTarget = false
            pvLblTxt.text = "Phù Văn:"
            pvLblTxt.color = Color(1, 1, 0.5, 1)
            pvLblTxt.fontSize = 15
            pvLblTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then pvLblTxt.font = defaultFont end

            -- Hàng 1 Phù Văn: Để trống 2 ô đầu (C4, C5), C6..C9 bắt đầu từ cột 3 để thẳng hàng với C6..C9 của Thánh Cốt bên trên
            currentY = currentY - 24
            for i, t in ipairs({ 6, 7, 8, 9 }) do
                local col = i + 2
                local x = leftColX + (col - 1) * (custBtnW + custGap)
                CreateCustomerKundunTierToggle("C" .. t, "Mod_KundunNotify_PV_C" .. t, x, currentY, custBtnW, 24)
            end

            currentY = currentY - 28
            for i, t in ipairs({ 10, 11, 12, 13, 14, 15 }) do
                local x = leftColX + (i - 1) * (custBtnW + custGap)
                CreateCustomerKundunTierToggle("C" .. t, "Mod_KundunNotify_PV_C" .. t, x, currentY, custBtnW, 24)
            end

            _G.ModUpdateKundunUI = function()
                pcall(function()
                    if _G.ModMainTab ~= "NANG_CAO" then return end

                    local kundunTiers = GetKundunTiers and GetKundunTiers() or { "C7", "C8" }
                    local isKundunTabValid = false
                    for _, tag in ipairs(kundunTiers) do
                        if _G.ModKundunBossTab == tag then
                            isKundunTabValid = true; break
                        end
                    end
                    if not isKundunTabValid and #kundunTiers > 0 then
                        _G.ModKundunBossTab = kundunTiers[#kundunTiers]
                    end
                    if _G.NangCaoTabBtns then
                        local activeIdx = 0
                        for _, tag in ipairs(kundunTiers) do
                            local tBtn = _G.NangCaoTabBtns[tag]
                            if tBtn then
                                tBtn.go:SetActive(true)
                                local isSel = (_G.ModKundunBossTab == tag)
                                tBtn.txt.text = "<color=" ..
                                    (isSel and "#00FF00" or "#FFFFFF") .. ">[ BOSS " .. tag .. " ]</color>"
                                tBtn.txt.fontSize = 17
                                local rt = tBtn.go:GetComponent(typeof(CS.UnityEngine.RectTransform))
                                if rt then
                                    rt.anchoredPosition = Vector2(leftColX + activeIdx * 110, kundunTabY)
                                    rt.sizeDelta = Vector2(105, 30)
                                end
                                activeIdx = activeIdx + 1
                            end
                        end
                        for _, tag in ipairs(tierTags) do
                            local inKundun = false
                            for _, kt in ipairs(kundunTiers) do
                                if kt == tag then
                                    inKundun = true; break
                                end
                            end
                            if not inKundun and _G.NangCaoTabBtns[tag] and _G.NangCaoTabBtns[tag].go then
                                _G.NangCaoTabBtns[tag].go:SetActive(false)
                            end
                        end
                    end

                    if not _G.KundunUILabelPool then return end

                    local tierNum = tonumber(string.match(_G.ModKundunBossTab or "C8", "%d+")) or 8
                    local kundunConfigs = {}
                    if tierNum >= 4 then
                        table.insert(kundunConfigs,
                            { name = "THÁNH CỐT:", bossType = 16, bossId = 20201000 + tierNum, limit = 70 })
                    end
                    if tierNum >= 6 then
                        local limit17 = (tierNum >= 9) and 500 or (tierNum == 8 and 400 or (tierNum == 7 and 300 or 200))
                        table.insert(kundunConfigs,
                            { name = "PHÙ VĂN:", bossType = 17, bossId = 20211000 + tierNum, limit = limit17 })
                    end

                    for i = 1, 2 do
                        local txt = _G.KundunUILabelPool[i]
                        local cfg = kundunConfigs[i]
                        if txt then
                            if cfg then
                                txt.gameObject:SetActive(true)
                                local count = 0
                                local rCount = 0
                                if _G.SceneData and _G.SceneData.GetAncientBossData then
                                    local isSatisfy, info = _G.SceneData:GetAncientBossData(cfg.bossType, cfg.bossId)
                                    if info and info.refreshCount then
                                        rCount = info.refreshCount
                                    end
                                    if isSatisfy == true then
                                        count = cfg.limit
                                    elseif isSatisfy == false and info and info.count then
                                        count = info.count
                                    end
                                end

                                local threshold = (cfg.bossType == 17) and 15 or 5
                                local isGreen = (cfg.limit - count <= threshold)

                                local colorTag = isGreen and "<color=#00FF00>" or "<color=#FFFFFF>"
                                if count >= cfg.limit then
                                    txt.text = cfg.name ..
                                        string.format(" %s%d / %d</color> (Hiện)", colorTag, count, cfg.limit)
                                else
                                    txt.text = cfg.name ..
                                        string.format(" %s%d / %d</color> (%d)", colorTag, count, cfg.limit, rCount)
                                end
                            else
                                txt.gameObject:SetActive(false)
                            end
                        end
                    end
                end)
            end
        end

        CreateAutoLootUI()

        if not _G.ModAutoBossConfigTab then
            pcall(function() _G.ModAutoBossConfigTab = CS.UnityEngine.PlayerPrefs.GetString("ModAutoBossConfigTab", "C7") end)
            if not _G.ModAutoBossConfigTab or _G.ModAutoBossConfigTab == "" then _G.ModAutoBossConfigTab = "C7" end
        end
        _G.Mod_AutoFarmBoss_Config = _G.Mod_AutoFarmBoss_Config or {}
        _G.Mod_AutoFarmBoss_Limits = _G.Mod_AutoFarmBoss_Limits or {}

        local function CreateAutoBossUI()
            local startX = 20
            local UpdateTierTabs

            -- =========================================================================
            -- [MOD FEATURE]: CẤU HÌNH ĐIỀU KHIỂN AUTO BOSS (LEFT & RIGHT CONTROLS)
            -- Mô tả: Cột Trái 4 nút compact (Auto Boss, Tự Vào Map Ẩn, Vào Ẩn KC, Nhớ Skill Map Ẩn) - Cột Phải (Tọa Độ Train, % HP Bỏ Boss KS)
            -- =========================================================================

            -- CỘT TRÁI - HÀNG 1: Master Toggle AUTO BOSS (y = -66, h = 26)
            local masterToggleGo = GameObject("AutoFarmBossToggle")
            masterToggleGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, masterToggleGo)
            local mtRt = masterToggleGo:AddComponent(typeof(RectTransform))
            mtRt.anchorMin, mtRt.anchorMax, mtRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            mtRt.anchoredPosition = Vector2(startX, -66)
            mtRt.sizeDelta = Vector2(200, 26)

            local mtBg = GameObject("Bg")
            mtBg.transform:SetParent(masterToggleGo.transform, false)
            local mtBgRt = mtBg:AddComponent(typeof(RectTransform))
            mtBgRt.anchorMin, mtBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            mtBgRt.sizeDelta = Vector2(0, 0)
            local mtBgImg = mtBg:AddComponent(typeof(Image))

            local mtTxtGo = GameObject("Text")
            mtTxtGo.transform:SetParent(masterToggleGo.transform, false)
            local mtTxtRt = mtTxtGo:AddComponent(typeof(RectTransform))
            mtTxtRt.anchorMin, mtTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            mtTxtRt.sizeDelta = Vector2(0, 0)
            local mtTxt = mtTxtGo:AddComponent(typeof(Text))
            mtTxt.raycastTarget = false
            mtTxt.fontSize = 14
            mtTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then mtTxt.font = defaultFont end

            local mtBtn = masterToggleGo:AddComponent(typeof(Button))

            local function UpdateMasterToggle()
                if _G.Mod_AutoFarmBoss_Enabled then
                    mtBgImg.color = Color(0.2, 0.6, 0.2, 1)
                    mtTxt.text = "AUTO BOSS: ON"
                    mtTxt.color = Color.white
                else
                    mtBgImg.color = Color(0.5, 0.2, 0.2, 1)
                    mtTxt.text = "AUTO BOSS: OFF"
                    mtTxt.color = Color(0.9, 0.9, 0.9, 1)
                end
            end

            if _G.Mod_AutoFarmBoss_Enabled == nil then
                _G.Mod_AutoFarmBoss_Enabled = false
            end
            UpdateMasterToggle()

            mtBtn.onClick:AddListener(function()
                _G.Mod_AutoFarmBoss_Enabled = not _G.Mod_AutoFarmBoss_Enabled
                if not _G.Mod_AutoFarmBoss_Enabled then
                    _G.Mod_AutoFarmBoss_State = 0
                    _G.Mod_AutoFarmBoss_Target = nil
                    pcall(function()
                        if _G.PathFinderManager and _G.PathFinderManager.ResetData then
                            _G.PathFinderManager.ResetData()
                        end
                        if _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.StopMove then
                            _G.RoleManager.me:StopMove()
                        end
                    end)
                end
                UpdateMasterToggle()
            end)

            -- CỘT TRÁI - HÀNG 2: TỰ VÀO MAP ẨN Toggle (y = -96, h = 26)
            local hiddenToggleGo = GameObject("AutoHiddenMapToggle")
            hiddenToggleGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, hiddenToggleGo)
            local htRt = hiddenToggleGo:AddComponent(typeof(RectTransform))
            htRt.anchorMin, htRt.anchorMax, htRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            htRt.anchoredPosition = Vector2(startX, -96)
            htRt.sizeDelta = Vector2(200, 26)

            local htBg = GameObject("Bg")
            htBg.transform:SetParent(hiddenToggleGo.transform, false)
            local htBgRt = htBg:AddComponent(typeof(RectTransform))
            htBgRt.anchorMin, htBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            htBgRt.sizeDelta = Vector2(0, 0)
            local htBgImg = htBg:AddComponent(typeof(Image))

            local htTxtGo = GameObject("Text")
            htTxtGo.transform:SetParent(hiddenToggleGo.transform, false)
            local htTxtRt = htTxtGo:AddComponent(typeof(RectTransform))
            htTxtRt.anchorMin, htTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            htTxtRt.sizeDelta = Vector2(0, 0)
            local htTxt = htTxtGo:AddComponent(typeof(Text))
            htTxt.raycastTarget = false
            htTxt.fontSize = 13
            htTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then htTxt.font = defaultFont end

            local htBtn = hiddenToggleGo:AddComponent(typeof(Button))

            local function UpdateHiddenToggle()
                if _G.Mod_AutoFarmBoss_EnterHiddenMap then
                    htBgImg.color = Color(0.2, 0.4, 0.6, 1)
                    htTxt.text = "TỰ VÀO MAP ẨN: BẬT"
                    htTxt.color = Color.white
                else
                    htBgImg.color = Color(0.3, 0.3, 0.3, 1)
                    htTxt.text = "TỰ VÀO MAP ẨN: TẮT"
                    htTxt.color = Color(0.8, 0.8, 0.8, 1)
                end
            end

            if _G.Mod_AutoFarmBoss_EnterHiddenMap == nil then
                pcall(function()
                    _G.Mod_AutoFarmBoss_EnterHiddenMap = (CS.UnityEngine.PlayerPrefs.GetInt("Mod_AutoFarmBoss_EnterHiddenMap", 0) == 1)
                end)
                if _G.Mod_AutoFarmBoss_EnterHiddenMap == nil then _G.Mod_AutoFarmBoss_EnterHiddenMap = false end
            end
            UpdateHiddenToggle()

            htBtn.onClick:AddListener(function()
                _G.Mod_AutoFarmBoss_EnterHiddenMap = not _G.Mod_AutoFarmBoss_EnterHiddenMap
                pcall(function()
                    CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoFarmBoss_EnterHiddenMap",
                        _G.Mod_AutoFarmBoss_EnterHiddenMap and 1 or 0)
                    CS.UnityEngine.PlayerPrefs.Save()
                end)
                UpdateHiddenToggle()
            end)

            -- CỘT TRÁI - HÀNG 3: VÀO ẨN KC Toggle (y = -126, h = 26)
            local diamondToggleGo = GameObject("AutoHiddenDiamondToggle")
            diamondToggleGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, diamondToggleGo)
            local dtRt = diamondToggleGo:AddComponent(typeof(RectTransform))
            dtRt.anchorMin, dtRt.anchorMax, dtRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            dtRt.anchoredPosition = Vector2(startX, -126)
            dtRt.sizeDelta = Vector2(200, 26)

            local dtBg = GameObject("Bg")
            dtBg.transform:SetParent(diamondToggleGo.transform, false)
            local dtBgRt = dtBg:AddComponent(typeof(RectTransform))
            dtBgRt.anchorMin, dtBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            dtBgRt.sizeDelta = Vector2(0, 0)
            local dtBgImg = dtBg:AddComponent(typeof(Image))

            local dtTxtGo = GameObject("Text")
            dtTxtGo.transform:SetParent(diamondToggleGo.transform, false)
            local dtTxtRt = dtTxtGo:AddComponent(typeof(RectTransform))
            dtTxtRt.anchorMin, dtTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            dtTxtRt.sizeDelta = Vector2(0, 0)
            local dtTxt = dtTxtGo:AddComponent(typeof(Text))
            dtTxt.raycastTarget = false
            dtTxt.fontSize = 13
            dtTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then dtTxt.font = defaultFont end

            local dtBtn = diamondToggleGo:AddComponent(typeof(Button))

            local function UpdateDiamondToggle()
                if _G.Mod_AutoFarmBoss_EnterHiddenMap_Diamond then
                    dtBgImg.color = Color(0.5, 0.2, 0.6, 1)
                    dtTxt.text = "VÀO ẨN KC: BẬT"
                    dtTxt.color = Color.white
                else
                    dtBgImg.color = Color(0.3, 0.3, 0.3, 1)
                    dtTxt.text = "VÀO ẨN KC: TẮT"
                    dtTxt.color = Color(0.8, 0.8, 0.8, 1)
                end
            end

            if _G.Mod_AutoFarmBoss_EnterHiddenMap_Diamond == nil then
                pcall(function()
                    _G.Mod_AutoFarmBoss_EnterHiddenMap_Diamond = (CS.UnityEngine.PlayerPrefs.GetInt("Mod_AutoFarmBoss_EnterHiddenMap_Diamond", 0) == 1)
                end)
                if _G.Mod_AutoFarmBoss_EnterHiddenMap_Diamond == nil then _G.Mod_AutoFarmBoss_EnterHiddenMap_Diamond = false end
            end
            UpdateDiamondToggle()

            dtBtn.onClick:AddListener(function()
                _G.Mod_AutoFarmBoss_EnterHiddenMap_Diamond = not _G.Mod_AutoFarmBoss_EnterHiddenMap_Diamond
                pcall(function()
                    CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoFarmBoss_EnterHiddenMap_Diamond",
                        _G.Mod_AutoFarmBoss_EnterHiddenMap_Diamond and 1 or 0)
                    CS.UnityEngine.PlayerPrefs.Save()
                end)
                UpdateDiamondToggle()
            end)

            -- CỘT TRÁI - HÀNG 4: NÚT NHỚ SKILL MAP ẨN (y = -156, h = 26)
            local saveSkillBtnGo = GameObject("SaveMapAnSkillBtn")
            saveSkillBtnGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, saveSkillBtnGo)
            local ssRt = saveSkillBtnGo:AddComponent(typeof(RectTransform))
            ssRt.anchorMin, ssRt.anchorMax, ssRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            ssRt.anchoredPosition = Vector2(startX, -156)
            ssRt.sizeDelta = Vector2(200, 26)

            local ssBg = GameObject("Bg")
            ssBg.transform:SetParent(saveSkillBtnGo.transform, false)
            local ssBgRt = ssBg:AddComponent(typeof(RectTransform))
            ssBgRt.anchorMin, ssBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            ssBgRt.sizeDelta = Vector2(0, 0)
            local ssBgImg = ssBg:AddComponent(typeof(Image))
            ssBgImg.color = Color(0.18, 0.48, 0.42, 1)

            local ssTxtGo = GameObject("Text")
            ssTxtGo.transform:SetParent(saveSkillBtnGo.transform, false)
            local ssTxtRt = ssTxtGo:AddComponent(typeof(RectTransform))
            ssTxtRt.anchorMin, ssTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            ssTxtRt.sizeDelta = Vector2(0, 0)
            local ssTxt = ssTxtGo:AddComponent(typeof(Text))
            ssTxt.raycastTarget = false
            ssTxt.text = "NHỚ SKILL MAP ẨN"
            ssTxt.color = Color.white
            ssTxt.fontSize = 13
            ssTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then ssTxt.font = defaultFont end

            local ssBtn = saveSkillBtnGo:AddComponent(typeof(Button))
            ssBtn.onClick:AddListener(function()
                if _G.Mod_SaveMapAnSkills then
                    _G.Mod_SaveMapAnSkills()
                end
            end)

            -- CỘT PHẢI - HÀNG 1: TỌA ĐỘ TRAIN InputField (x=230, w=105) + Nút XY HIỆN TẠI (x=340, w=110)
            local labelTrainGo = GameObject("TrainCoordLabel")
            labelTrainGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, labelTrainGo)
            local lblRt = labelTrainGo:AddComponent(typeof(RectTransform))
            lblRt.anchorMin, lblRt.anchorMax, lblRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            lblRt.anchoredPosition = Vector2(230, -66)
            lblRt.sizeDelta = Vector2(220, 16)
            local lblTxt = labelTrainGo:AddComponent(typeof(Text))
            lblTxt.raycastTarget = false
            lblTxt.text = "TỌA ĐỘ TRAIN (x#y):"
            lblTxt.color = Color(1, 0.85, 0.4, 1)
            lblTxt.fontSize = 11
            lblTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then lblTxt.font = defaultFont end

            local trainTgtGo = GameObject("TrainCoordInput")
            trainTgtGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, trainTgtGo)
            local trainRt = trainTgtGo:AddComponent(typeof(RectTransform))
            trainRt.anchorMin, trainRt.anchorMax, trainRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            trainRt.anchoredPosition = Vector2(230, -84)
            trainRt.sizeDelta = Vector2(105, 26)

            local trainBg = GameObject("Bg")
            trainBg.transform:SetParent(trainTgtGo.transform, false)
            local trainBgRt = trainBg:AddComponent(typeof(RectTransform))
            trainBgRt.anchorMin, trainBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            trainBgRt.sizeDelta = Vector2(0, 0)
            local trainImg = trainBg:AddComponent(typeof(Image))
            trainImg.color = Color(0.1, 0.1, 0.1, 1)

            local trainTxtGo = GameObject("Text")
            trainTxtGo.transform:SetParent(trainTgtGo.transform, false)
            local trainTxtRt = trainTxtGo:AddComponent(typeof(RectTransform))
            trainTxtRt.anchorMin, trainTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            trainTxtRt.offsetMin, trainTxtRt.offsetMax = Vector2(5, 0), Vector2(-5, 0)
            local trainTxt = trainTxtGo:AddComponent(typeof(Text))

            if _G.Mod_TrainCoord == nil or _G.Mod_TrainCoord == "" then
                pcall(function()
                    _G.Mod_TrainCoord = CS.UnityEngine.PlayerPrefs.GetString("Mod_TrainCoord", "")
                    if not _G.Mod_TrainCoord or _G.Mod_TrainCoord == "" then
                        _G.Mod_TrainCoord = CS.UnityEngine.PlayerPrefs.GetString("Mod_AutoReturnPos_Coords", "")
                    end
                end)
                if _G.Mod_TrainCoord == nil then _G.Mod_TrainCoord = "" end
            end
            _G.Mod_AutoReturnPos_Coords = _G.Mod_TrainCoord

            trainTxt.text = (_G.Mod_TrainCoord ~= "" and _G.Mod_TrainCoord or "125#340")
            trainTxt.color = (_G.Mod_TrainCoord ~= "" and Color.white or Color(0.6, 0.6, 0.6, 1))
            trainTxt.fontSize = 13
            trainTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then trainTxt.font = defaultFont end

            pcall(function()
                local InputFieldType = InputField or (CS.UnityEngine.UI and CS.UnityEngine.UI.InputField)
                if InputFieldType then
                    local trainField = trainTgtGo:AddComponent(typeof(InputFieldType))
                    if trainField then
                        trainField.textComponent = trainTxt
                        trainField.text = _G.Mod_TrainCoord
                        if trainField.onValueChanged then
                            trainField.onValueChanged:AddListener(function(val)
                                _G.Mod_TrainCoord = val
                                _G.Mod_AutoReturnPos_Coords = val
                                pcall(function()
                                    CS.UnityEngine.PlayerPrefs.SetString("Mod_TrainCoord", val)
                                    CS.UnityEngine.PlayerPrefs.SetString("Mod_AutoReturnPos_Coords", val)
                                    CS.UnityEngine.PlayerPrefs.Save()
                                end)
                            end)
                        end
                    end
                end
            end)

            local getPosBtnGo = GameObject("GetCurPosBtn")
            getPosBtnGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, getPosBtnGo)
            local getPosRt = getPosBtnGo:AddComponent(typeof(RectTransform))
            getPosRt.anchorMin, getPosRt.anchorMax, getPosRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            getPosRt.anchoredPosition = Vector2(340, -84)
            getPosRt.sizeDelta = Vector2(110, 26)

            local getPosBg = GameObject("Bg")
            getPosBg.transform:SetParent(getPosBtnGo.transform, false)
            local getPosBgRt = getPosBg:AddComponent(typeof(RectTransform))
            getPosBgRt.anchorMin, getPosBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            getPosBgRt.sizeDelta = Vector2(0, 0)
            local getPosBgImg = getPosBg:AddComponent(typeof(Image))
            getPosBgImg.color = Color(0.2, 0.5, 0.7, 1)

            local getPosTxtGo = GameObject("Text")
            getPosTxtGo.transform:SetParent(getPosBtnGo.transform, false)
            local getPosTxtRt = getPosTxtGo:AddComponent(typeof(RectTransform))
            getPosTxtRt.anchorMin, getPosTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            getPosTxtRt.sizeDelta = Vector2(0, 0)
            local getPosTxt = getPosTxtGo:AddComponent(typeof(Text))
            getPosTxt.raycastTarget = false
            getPosTxt.text = "XY HIỆN TẠI"
            getPosTxt.color = Color.white
            getPosTxt.fontSize = 13
            getPosTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then getPosTxt.font = defaultFont end

            local getPosBtn = getPosBtnGo:AddComponent(typeof(Button))
            getPosBtn.onClick:AddListener(function()
                pcall(function()
                    if _G.RoleManager and _G.RoleManager.me then
                        local me = _G.RoleManager.me
                        local curX = me.serverCoord and me.serverCoord.x or (me.cellPos and me.cellPos.x) or 0
                        local curY = me.serverCoord and me.serverCoord.y or (me.cellPos and me.cellPos.y) or 0
                        if curX > 0 and curY > 0 then
                            local coordStr = string.format("%d#%d", curX, curY)
                            _G.Mod_TrainCoord = coordStr
                            _G.Mod_AutoReturnPos_Coords = coordStr
                            local trainField = trainTgtGo:GetComponent(typeof(CS.UnityEngine.UI.InputField))
                            if trainField then trainField.text = coordStr end
                            trainTxt.text = coordStr
                            trainTxt.color = Color.white
                            CS.UnityEngine.PlayerPrefs.SetString("Mod_TrainCoord", coordStr)
                            CS.UnityEngine.PlayerPrefs.SetString("Mod_AutoReturnPos_Coords", coordStr)
                            CS.UnityEngine.PlayerPrefs.Save()
                            if _G.FloatingWordUtility then
                                _G.FloatingWordUtility.QuickMsg("Đã lưu tọa độ train: " .. coordStr)
                            end
                        end
                    end
                end)
            end)

            -- CỘT PHẢI - HÀNG 2: % HP BỎ QUA BOSS (KHI BỊ KS)
            local skipHpLabelGo = GameObject("SkipHpLabel")
            skipHpLabelGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, skipHpLabelGo)
            local skipLblRt = skipHpLabelGo:AddComponent(typeof(RectTransform))
            skipLblRt.anchorMin, skipLblRt.anchorMax, skipLblRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            skipLblRt.anchoredPosition = Vector2(230, -116)
            skipLblRt.sizeDelta = Vector2(220, 16)
            local skipLblTxt = skipHpLabelGo:AddComponent(typeof(Text))
            skipLblTxt.raycastTarget = false
            skipLblTxt.text = "BỎ QUA BOSS KS (% MÁU):"
            skipLblTxt.color = Color(1, 0.85, 0.4, 1)
            skipLblTxt.fontSize = 11
            skipLblTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then skipLblTxt.font = defaultFont end

            -- Display value box (x=230, w=110, h=26)
            local skipHpValGo = GameObject("SkipHpVal")
            skipHpValGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, skipHpValGo)
            local skipValRt = skipHpValGo:AddComponent(typeof(RectTransform))
            skipValRt.anchorMin, skipValRt.anchorMax, skipValRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            skipValRt.anchoredPosition = Vector2(230, -134)
            skipValRt.sizeDelta = Vector2(110, 26)

            local skipValBg = GameObject("Bg")
            skipValBg.transform:SetParent(skipHpValGo.transform, false)
            local skipValBgRt = skipValBg:AddComponent(typeof(RectTransform))
            skipValBgRt.anchorMin, skipValBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            skipValBgRt.sizeDelta = Vector2(0, 0)
            local skipValBgImg = skipValBg:AddComponent(typeof(Image))
            skipValBgImg.color = Color(0.1, 0.1, 0.1, 1)

            local skipValTxtGo = GameObject("Text")
            skipValTxtGo.transform:SetParent(skipHpValGo.transform, false)
            local skipValTxtRt = skipValTxtGo:AddComponent(typeof(RectTransform))
            skipValTxtRt.anchorMin, skipValTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            skipValTxtRt.sizeDelta = Vector2(0, 0)
            local skipValTxt = skipValTxtGo:AddComponent(typeof(Text))
            skipValTxt.raycastTarget = false
            skipValTxt.color = Color(0.8, 1, 0.8, 1)
            skipValTxt.fontSize = 13
            skipValTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then skipValTxt.font = defaultFont end

            if _G.Mod_AutoBoss_SkipHpPct == nil then
                pcall(function()
                    _G.Mod_AutoBoss_SkipHpPct = CS.UnityEngine.PlayerPrefs.GetInt("Mod_AutoBoss_SkipHpPct", 90)
                end)
                if not _G.Mod_AutoBoss_SkipHpPct or _G.Mod_AutoBoss_SkipHpPct <= 0 then
                    _G.Mod_AutoBoss_SkipHpPct = 90
                end
            end

            local function UpdateSkipHpLabel()
                skipValTxt.text = string.format("BỎ KHI < %d%%", _G.Mod_AutoBoss_SkipHpPct or 90)
            end
            UpdateSkipHpLabel()

            local function createSkipHpBtn(name, posX, w, btnText, btnColor)
                local btnGo = GameObject(name)
                btnGo.transform:SetParent(panelGo.transform, false)
                table.insert(_G.AutoBossUIList, btnGo)
                local bRt = btnGo:AddComponent(typeof(RectTransform))
                bRt.anchorMin, bRt.anchorMax, bRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                bRt.anchoredPosition = Vector2(posX, -134)
                bRt.sizeDelta = Vector2(w, 26)
                local bImg = btnGo:AddComponent(typeof(Image))
                bImg.color = btnColor

                local bTxtGo = GameObject("Text")
                bTxtGo.transform:SetParent(btnGo.transform, false)
                local bTxtRt = bTxtGo:AddComponent(typeof(RectTransform))
                bTxtRt.anchorMin, bTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                bTxtRt.sizeDelta = Vector2(0, 0)
                local bTxt = bTxtGo:AddComponent(typeof(Text))
                bTxt.raycastTarget = false
                bTxt.text = btnText
                bTxt.color = Color.white
                bTxt.fontSize = 13
                bTxt.alignment = TextAnchor.MiddleCenter
                if defaultFont then bTxt.font = defaultFont end

                return btnGo:AddComponent(typeof(Button))
            end

            local skipMinusBtn = createSkipHpBtn("SkipHpMinusBtn", 345, 48, "-5%", Color(0.5, 0.2, 0.2, 1))
            local skipPlusBtn = createSkipHpBtn("SkipHpPlusBtn", 398, 48, "+5%", Color(0.2, 0.5, 0.2, 1))

            skipMinusBtn.onClick:AddListener(function()
                _G.Mod_AutoBoss_SkipHpPct = math.max(10, (_G.Mod_AutoBoss_SkipHpPct or 90) - 5)
                pcall(function()
                    CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoBoss_SkipHpPct", _G.Mod_AutoBoss_SkipHpPct)
                    CS.UnityEngine.PlayerPrefs.Save()
                end)
                UpdateSkipHpLabel()
            end)

            skipPlusBtn.onClick:AddListener(function()
                _G.Mod_AutoBoss_SkipHpPct = math.min(100, (_G.Mod_AutoBoss_SkipHpPct or 90) + 5)
                pcall(function()
                    CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoBoss_SkipHpPct", _G.Mod_AutoBoss_SkipHpPct)
                    CS.UnityEngine.PlayerPrefs.Save()
                end)
                UpdateSkipHpLabel()
            end)

            -- =========================================================================
            -- VẠCH DỌC PHÂN CÁCH (BETWEEN 2/3 TRÁI & 1/3 PHẢI)
            -- =========================================================================
            local vLineGo = GameObject("AutoBossVerticalSeparator")
            vLineGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, vLineGo)
            local vLineRt = vLineGo:AddComponent(typeof(RectTransform))
            vLineRt.anchorMin, vLineRt.anchorMax, vLineRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            vLineRt.anchoredPosition = Vector2(460, -45)
            vLineRt.sizeDelta = Vector2(2, 535)
            local vLineImg = vLineGo:AddComponent(typeof(Image))
            vLineImg.color = Color(0.4, 0.4, 0.4, 1)

            -- =========================================================================
            -- [MOD FEATURE]: PANEL PHẢI AUTO BOSS DẠNG SCROLLVIEW & CẤU HÌNH DÒNG NGON
            -- Mô tả: Chuyển đổi toàn bộ bảng Tách Đồ & Giữ Dòng Ngon thành ScrollView mượt mà,
            --        bổ sung bảng cấu hình trực quan cho Đồ Đeo TV, Trang Sức TV và Đồ Bộ.
            -- =========================================================================
            local scrollGo = GameObject("AutoBossRightScroll")
            scrollGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.AutoBossUIList, scrollGo)
            local scrollRt = scrollGo:AddComponent(typeof(RectTransform))
            scrollRt.anchorMin, scrollRt.anchorMax, scrollRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            scrollRt.anchoredPosition = Vector2(468, -48)
            scrollRt.sizeDelta = Vector2(245, 510)

            local scrollImg = scrollGo:AddComponent(typeof(Image))
            scrollImg.color = Color(0, 0, 0, 0.01)

            local scrollRect = scrollGo:AddComponent(typeof(CS.UnityEngine.UI.ScrollRect))
            scrollRect.horizontal = false
            scrollRect.vertical = true
            scrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Clamped
            scrollRect.scrollSensitivity = 30

            local vpGo = GameObject("Viewport")
            vpGo.transform:SetParent(scrollGo.transform, false)
            local vpRt = vpGo:AddComponent(typeof(RectTransform))
            vpRt.anchorMin, vpRt.anchorMax, vpRt.pivot = Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)
            vpRt.sizeDelta = Vector2(0, 0)
            vpGo:AddComponent(typeof(CS.UnityEngine.UI.RectMask2D))

            local contentGo = GameObject("Content")
            contentGo.transform:SetParent(vpGo.transform, false)
            local contentRt = contentGo:AddComponent(typeof(RectTransform))
            contentRt.anchorMin, contentRt.anchorMax, contentRt.pivot = Vector2(0, 1), Vector2(1, 1), Vector2(0, 1)
            contentRt.anchoredPosition = Vector2(0, 0)
            contentRt.sizeDelta = Vector2(0, 1550)

            local contentImg = contentGo:AddComponent(typeof(Image))
            contentImg.color = Color(0, 0, 0, 0.01)

            scrollRect.viewport = vpRt
            scrollRect.content = contentRt

            local smeltStartX = 6
            local btnW = 34
            local btnH = 22
            local curY = -5

            local title1Go = GameObject("SmeltTitle1")
            title1Go.transform:SetParent(contentGo.transform, false)
            local title1Rt = title1Go:AddComponent(typeof(RectTransform))
            title1Rt.anchorMin, title1Rt.anchorMax, title1Rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            title1Rt.anchoredPosition = Vector2(smeltStartX, curY)
            title1Rt.sizeDelta = Vector2(230, 20)
            local title1Txt = title1Go:AddComponent(typeof(Text))
            title1Txt.raycastTarget = true
            title1Txt.text = "TÁCH ĐỒ TRÁC VIỆT"
            title1Txt.color = Color(1, 0.8, 0, 1)
            title1Txt.fontSize = 14
            title1Txt.alignment = TextAnchor.MiddleCenter
            if defaultFont then title1Txt.font = defaultFont end

            local smeltTogglePool = {}
            local goodOptTogglePool = {}

            local function CreateSmeltToggle(prefix, colIdx, x, y, width, isKeepGood)
                local varNameDummy = prefix .. "_" .. colIdx .. (isKeepGood and "_KG" or "")
                local btnGo = GameObject("SmeltToggle_" .. varNameDummy)
                btnGo.transform:SetParent(contentGo.transform, false)
                local rt = btnGo:AddComponent(typeof(RectTransform))
                rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                rt.anchoredPosition = Vector2(x, y)
                rt.sizeDelta = Vector2(width, btnH)

                local bg = GameObject("Bg")
                bg.transform:SetParent(btnGo.transform, false)
                local bgRt = bg:AddComponent(typeof(RectTransform))
                bgRt.anchorMin, bgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                bgRt.sizeDelta = Vector2(0, 0)
                local bgImg = bg:AddComponent(typeof(Image))

                local txtGo = GameObject("Text")
                txtGo.transform:SetParent(btnGo.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin, txtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                txtRt.sizeDelta = Vector2(0, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.fontSize = 10
                txt.alignment = TextAnchor.MiddleCenter
                if defaultFont then txt.font = defaultFont end

                local btn = btnGo:AddComponent(typeof(Button))

                local itemObj = {
                    go = btnGo,
                    bgImg = bgImg,
                    txt = txt,
                    btn = btn,
                    prefix = prefix,
                    colIdx = colIdx,
                    isKeepGood = isKeepGood,
                    varName = nil
                }
                table.insert(smeltTogglePool, itemObj)
                return itemObj
            end

            curY = curY - 25
            local kgTvLblGo = GameObject("SmeltLbl_KeepGoodTV")
            kgTvLblGo.transform:SetParent(contentGo.transform, false)
            local kgTvLblRt = kgTvLblGo:AddComponent(typeof(RectTransform))
            kgTvLblRt.anchorMin, kgTvLblRt.anchorMax, kgTvLblRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            kgTvLblRt.anchoredPosition = Vector2(smeltStartX, curY)
            kgTvLblRt.sizeDelta = Vector2(85, btnH)
            local kgTvLblTxt = kgTvLblGo:AddComponent(typeof(Text))
            kgTvLblTxt.raycastTarget = false
            kgTvLblTxt.text = "GIỮ DÒNG NGON"
            kgTvLblTxt.color = Color(1, 0.6, 0.2, 1)
            kgTvLblTxt.fontSize = 10
            kgTvLblTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then kgTvLblTxt.font = defaultFont end

            for colIdx = 1, 4 do
                CreateSmeltToggle("KeepGoodTV", colIdx, smeltStartX + 88 + (colIdx - 1) * 37, curY, btnW, true)
            end
            curY = curY - 26

            local function CreateTracVietRow(lblText, prefix)
                local lblGo = GameObject("SmeltLbl_" .. prefix)
                lblGo.transform:SetParent(contentGo.transform, false)
                local lblRt = lblGo:AddComponent(typeof(RectTransform))
                lblRt.anchorMin, lblRt.anchorMax, lblRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                lblRt.anchoredPosition = Vector2(smeltStartX, curY)
                lblRt.sizeDelta = Vector2(85, btnH)
                local lblTxt = lblGo:AddComponent(typeof(Text))
                lblTxt.raycastTarget = false
                lblTxt.text = lblText
                lblTxt.color = Color.white
                lblTxt.fontSize = 11
                lblTxt.alignment = TextAnchor.MiddleLeft
                if defaultFont then lblTxt.font = defaultFont end

                for colIdx = 1, 4 do
                    CreateSmeltToggle(prefix, colIdx, smeltStartX + 88 + (colIdx - 1) * 37, curY, btnW, false)
                end
                curY = curY - 24
            end

            CreateTracVietRow("NHẪN", "Ring")
            CreateTracVietRow("DÂY CHUYỀN", "Necklace")
            CreateTracVietRow("KHUYÊN", "Earring")

            -- 2. VẠCH DASHED NGĂN CÁCH
            curY = curY - 2
            local dashGo = GameObject("SmeltDashLine")
            dashGo.transform:SetParent(contentGo.transform, false)
            local dashRt = dashGo:AddComponent(typeof(RectTransform))
            dashRt.anchorMin, dashRt.anchorMax, dashRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            dashRt.anchoredPosition = Vector2(smeltStartX, curY)
            dashRt.sizeDelta = Vector2(230, 15)
            local dashTxt = dashGo:AddComponent(typeof(Text))
            dashTxt.raycastTarget = false
            dashTxt.text = "- - - - - - - - - - - - - - - - - - - - - - - - - - - -"
            dashTxt.color = Color(0.6, 0.6, 0.6, 0.8)
            dashTxt.fontSize = 11
            dashTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then dashTxt.font = defaultFont end

            -- 3. PHẦN 2: TÁCH ĐỒ BỘ & GIỮ DÒNG NGON
            curY = curY - 18
            local title2Go = GameObject("SmeltTitle2")
            title2Go.transform:SetParent(contentGo.transform, false)
            local title2Rt = title2Go:AddComponent(typeof(RectTransform))
            title2Rt.anchorMin, title2Rt.anchorMax, title2Rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            title2Rt.anchoredPosition = Vector2(smeltStartX, curY)
            title2Rt.sizeDelta = Vector2(230, 20)
            local title2Txt = title2Go:AddComponent(typeof(Text))
            title2Txt.raycastTarget = true
            title2Txt.text = "TÁCH ĐỒ BỘ & DÒNG NGON"
            title2Txt.color = Color(1, 0.8, 0, 1)
            title2Txt.fontSize = 13
            title2Txt.alignment = TextAnchor.MiddleCenter
            if defaultFont then title2Txt.font = defaultFont end

            curY = curY - 25
            local kgLblGo = GameObject("SmeltLbl_KeepGood")
            kgLblGo.transform:SetParent(contentGo.transform, false)
            local kgLblRt = kgLblGo:AddComponent(typeof(RectTransform))
            kgLblRt.anchorMin, kgLblRt.anchorMax, kgLblRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            kgLblRt.anchoredPosition = Vector2(smeltStartX, curY)
            kgLblRt.sizeDelta = Vector2(85, btnH)
            local kgLblTxt = kgLblGo:AddComponent(typeof(Text))
            kgLblTxt.raycastTarget = false
            kgLblTxt.text = "GIỮ DÒNG NGON"
            kgLblTxt.color = Color(1, 0.6, 0.2, 1)
            kgLblTxt.fontSize = 10
            kgLblTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then kgLblTxt.font = defaultFont end

            for colIdx = 1, 4 do
                CreateSmeltToggle("KeepGood", colIdx, smeltStartX + 88 + (colIdx - 1) * 37, curY, btnW, true)
            end
            curY = curY - 26

            local equipRows = {
                { "MŨ", "Hat" },
                { "ÁO", "Armor" },
                { "QUẦN", "Pants" },
                { "BAO TAY", "Gloves" },
                { "BAO CHÂN", "Boots" },
                { "VŨ KHÍ", "Weapon" },
                { "DÂY CHUYỀN", "Necklace2" },
                { "KHUYÊN TRÁI", "EarringL" },
                { "KHUYÊN PHẢI", "EarringR" },
                { "NHẪN TRÁI", "RingL" },
                { "NHẪN PHẢI", "RingR" },
            }

            for _, r in ipairs(equipRows) do
                local label = r[1]
                local prefix = r[2]

                local lblGo = GameObject("SmeltLbl_" .. prefix)
                lblGo.transform:SetParent(contentGo.transform, false)
                local lblRt = lblGo:AddComponent(typeof(RectTransform))
                lblRt.anchorMin, lblRt.anchorMax, lblRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                lblRt.anchoredPosition = Vector2(smeltStartX, curY)
                lblRt.sizeDelta = Vector2(85, btnH)
                local lblTxt = lblGo:AddComponent(typeof(Text))
                lblTxt.raycastTarget = false
                lblTxt.text = label
                lblTxt.color = Color.white
                lblTxt.fontSize = 11
                lblTxt.alignment = TextAnchor.MiddleLeft
                if defaultFont then lblTxt.font = defaultFont end

                for colIdx = 1, 4 do
                    CreateSmeltToggle(prefix, colIdx, smeltStartX + 88 + (colIdx - 1) * 37, curY, btnW, false)
                end
                curY = curY - 24
            end

            -- Nút TÁCH NGAY thủ công
            curY = curY - 30
            local manualSmeltBtnGo = GameObject("SmeltManualBtn")
            manualSmeltBtnGo.transform:SetParent(contentGo.transform, false)
            local manualSmeltRt = manualSmeltBtnGo:AddComponent(typeof(RectTransform))
            manualSmeltRt.anchorMin, manualSmeltRt.anchorMax, manualSmeltRt.pivot = Vector2(0, 1), Vector2(0, 1),
                Vector2(0, 1)
            manualSmeltRt.anchoredPosition = Vector2(smeltStartX, curY)
            manualSmeltRt.sizeDelta = Vector2(233, 26)

            local manualSmeltBgImg = manualSmeltBtnGo:AddComponent(typeof(Image))
            manualSmeltBgImg.color = Color(0.8, 0.2, 0.2, 1)

            local manualSmeltTxtGo = GameObject("Text")
            manualSmeltTxtGo.transform:SetParent(manualSmeltBtnGo.transform, false)
            local manualSmeltTxtRt = manualSmeltTxtGo:AddComponent(typeof(RectTransform))
            manualSmeltTxtRt.anchorMin, manualSmeltTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            manualSmeltTxtRt.sizeDelta = Vector2(0, 0)
            local manualSmeltTxt = manualSmeltTxtGo:AddComponent(typeof(Text))
            manualSmeltTxt.raycastTarget = false
            manualSmeltTxt.text = "TÁCH NGAY (THỦ CÔNG)"
            manualSmeltTxt.color = Color.white
            manualSmeltTxt.fontSize = 12
            manualSmeltTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then manualSmeltTxt.font = defaultFont end

            local manualSmeltBtn = manualSmeltBtnGo:AddComponent(typeof(Button))
            manualSmeltBtn.targetGraphic = manualSmeltBgImg
            manualSmeltBtn.onClick:AddListener(function()
                pcall(function()
                    if _G.Mod_PerformSmeltItems then
                        _G.Mod_PerformSmeltItems()
                    else
                        if _G.Mod_ExecuteAutoSmelt then _G.Mod_ExecuteAutoSmelt() end
                        if _G.Mod_PerformBagRecycle then _G.Mod_PerformBagRecycle() end
                    end
                    if _G.FloatingWordUtility then
                        _G.FloatingWordUtility.QuickMsg("Đã kích hoạt Tách Đồ & Thu Hồi thủ công!")
                    end
                    LogMsg("Đã kích hoạt Tách Đồ & Thu Hồi thủ công!")
                end)
            end)

            -- =========================================================================
            -- [MOD FEATURE]: BẢNG CẤU HÌNH DÒNG NGON (DYNAMIC GOOD OPTIONS UI)
            -- =========================================================================
            curY = curY - 35
            local dash2Go = GameObject("SmeltDashLine2")
            dash2Go.transform:SetParent(contentGo.transform, false)
            local dash2Rt = dash2Go:AddComponent(typeof(RectTransform))
            dash2Rt.anchorMin, dash2Rt.anchorMax, dash2Rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            dash2Rt.anchoredPosition = Vector2(smeltStartX, curY)
            dash2Rt.sizeDelta = Vector2(230, 15)
            local dash2Txt = dash2Go:AddComponent(typeof(Text))
            dash2Txt.raycastTarget = true
            dash2Txt.text = "================================="
            dash2Txt.color = Color(1, 0.8, 0, 0.8)
            dash2Txt.fontSize = 11
            dash2Txt.alignment = TextAnchor.MiddleCenter
            if defaultFont then dash2Txt.font = defaultFont end

            curY = curY - 18
            local goodOptMainTitleGo = GameObject("GoodOptMainTitle")
            goodOptMainTitleGo.transform:SetParent(contentGo.transform, false)
            local gotRt = goodOptMainTitleGo:AddComponent(typeof(RectTransform))
            gotRt.anchorMin, gotRt.anchorMax, gotRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            gotRt.anchoredPosition = Vector2(smeltStartX, curY)
            gotRt.sizeDelta = Vector2(233, 22)
            local gotTxt = goodOptMainTitleGo:AddComponent(typeof(Text))
            gotTxt.raycastTarget = true
            gotTxt.text = "QUY ĐỊNH DÒNG NGON"
            gotTxt.color = Color(1, 0.85, 0.2, 1)
            gotTxt.fontSize = 16
            gotTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then gotTxt.font = defaultFont end

            curY = curY - 20
            local safetyShieldNoteGo = GameObject("SafetyShieldNote")
            safetyShieldNoteGo.transform:SetParent(contentGo.transform, false)
            local ssnRt = safetyShieldNoteGo:AddComponent(typeof(RectTransform))
            ssnRt.anchorMin, ssnRt.anchorMax, ssnRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            ssnRt.anchoredPosition = Vector2(smeltStartX, curY)
            ssnRt.sizeDelta = Vector2(233, 16)
            local ssnTxt = safetyShieldNoteGo:AddComponent(typeof(Text))
            ssnTxt.raycastTarget = true
            ssnTxt.text = "* Luôn giữ đồ Cường Hóa, Nâng Cấp, Skill Bộ"
            ssnTxt.color = Color(0.4, 0.85, 0.5, 1)
            ssnTxt.fontSize = 10
            ssnTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then ssnTxt.font = defaultFont end

            local lastElementWasToggle = false
            local isFirstSection = true

            local function CreateGoodOptToggle(cat, key, label, x, y, width)
                lastElementWasToggle = true
                local btnGo = GameObject("GoodOptToggle_" .. cat .. "_" .. key)
                btnGo.transform:SetParent(contentGo.transform, false)
                local rt = btnGo:AddComponent(typeof(RectTransform))
                rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                rt.anchoredPosition = Vector2(x, y)
                rt.sizeDelta = Vector2(width, 22)

                local bg = GameObject("Bg")
                bg.transform:SetParent(btnGo.transform, false)
                local bgRt = bg:AddComponent(typeof(RectTransform))
                bgRt.anchorMin, bgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                bgRt.sizeDelta = Vector2(0, 0)
                local bgImg = bg:AddComponent(typeof(Image))

                local txtGo = GameObject("Text")
                txtGo.transform:SetParent(btnGo.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin, txtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                txtRt.sizeDelta = Vector2(0, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.fontSize = 11
                txt.alignment = TextAnchor.MiddleCenter
                txt.text = label
                if defaultFont then txt.font = defaultFont end

                local btn = btnGo:AddComponent(typeof(Button))

                local function updateVisual()
                    local isChecked = _G.Mod_GetGoodOpt and _G.Mod_GetGoodOpt(cat, key)
                    if isChecked then
                        bgImg.color = Color(0.15, 0.55, 0.25, 1)
                        txt.color = Color.white
                    else
                        bgImg.color = Color(0.25, 0.25, 0.25, 1)
                        txt.color = Color(0.65, 0.65, 0.65, 1)
                    end
                end
                updateVisual()

                btn.onClick:AddListener(function()
                    local curVal = _G.Mod_GetGoodOpt and _G.Mod_GetGoodOpt(cat, key)
                    if _G.Mod_SetGoodOpt then _G.Mod_SetGoodOpt(cat, key, not curVal) end
                    updateVisual()
                end)

                table.insert(goodOptTogglePool, { updateVisual = updateVisual })
                return btnGo
            end

            local function CreateSectionHeader(titleText, noteText)
                if isFirstSection then
                    curY = curY - 26
                    isFirstSection = false
                else
                    curY = curY - 42 -- Khoảng cách thoáng 20px so với hàng nút khối trước
                end
                lastElementWasToggle = false

                local sGo = GameObject("SecHeader_" .. titleText)
                sGo.transform:SetParent(contentGo.transform, false)
                local sRt = sGo:AddComponent(typeof(RectTransform))
                sRt.anchorMin, sRt.anchorMax, sRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                sRt.anchoredPosition = Vector2(smeltStartX, curY)
                sRt.sizeDelta = Vector2(233, 20)
                local sTxt = sGo:AddComponent(typeof(Text))
                sTxt.raycastTarget = true
                sTxt.text = titleText
                sTxt.color = Color(1, 0.75, 0.2, 1)
                sTxt.fontSize = 14
                sTxt.alignment = TextAnchor.MiddleLeft
                if defaultFont then sTxt.font = defaultFont end

                if noteText and noteText ~= "" then
                    curY = curY - 18
                    local nGo = GameObject("SecNote_" .. titleText)
                    nGo.transform:SetParent(contentGo.transform, false)
                    local nRt = nGo:AddComponent(typeof(RectTransform))
                    nRt.anchorMin, nRt.anchorMax, nRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                    nRt.anchoredPosition = Vector2(smeltStartX, curY)
                    nRt.sizeDelta = Vector2(233, 16)
                    local nTxt = nGo:AddComponent(typeof(Text))
                    nTxt.raycastTarget = true
                    nTxt.text = noteText
                    nTxt.color = Color(0.7, 0.7, 0.7, 1)
                    nTxt.fontSize = 10
                    nTxt.alignment = TextAnchor.MiddleLeft
                    if defaultFont then nTxt.font = defaultFont end
                end
            end

            local function CreateSubLabel(subText)
                if lastElementWasToggle then
                    curY = curY - 30 -- Cách đáy hàng nút trước 8px
                else
                    curY = curY - 20
                end
                lastElementWasToggle = false

                local lblGo = GameObject("SubLbl_" .. subText)
                lblGo.transform:SetParent(contentGo.transform, false)
                local lblRt = lblGo:AddComponent(typeof(RectTransform))
                lblRt.anchorMin, lblRt.anchorMax, lblRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                lblRt.anchoredPosition = Vector2(smeltStartX, curY)
                lblRt.sizeDelta = Vector2(233, 18)
                local lblTxt = lblGo:AddComponent(typeof(Text))
                lblTxt.raycastTarget = true
                lblTxt.text = subText
                lblTxt.color = Color(0.4, 0.9, 1, 1)
                lblTxt.fontSize = 11
                lblTxt.alignment = TextAnchor.MiddleLeft
                if defaultFont then lblTxt.font = defaultFont end
            end

            local optW = 114
            local col1X = smeltStartX
            local col2X = smeltStartX + 118

            -- NHÓM 1: ĐỒ ĐEO TRÁC VIỆT
            CreateSectionHeader("--- ĐỒ ĐEO TRÁC VIỆT ---", "(Giữ khi có ít nhất 1 dòng chính VÀ 1 dòng phụ)")

            CreateSubLabel("Vũ khí - Dòng chính:")
            curY = curY - 22
            CreateGoodOptToggle("EquipTV_Weapon_Main", "atk2", "Tấn công +2.0%", col1X, curY, optW)
            CreateGoodOptToggle("EquipTV_Weapon_Main", "speed7", "Công tốc +7", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("EquipTV_Weapon_Main", "crit10", "Đòn TV +10.0%", col1X, curY, optW)
            CreateGoodOptToggle("EquipTV_Weapon_Main", "atk_lv20", "Atk +cấp/20", col2X, curY, optW)

            CreateSubLabel("Vũ khí - Dòng phụ:")
            curY = curY - 22
            CreateGoodOptToggle("EquipTV_Weapon_Sub", "atk2", "Tấn công +2.0%", col1X, curY, optW)
            CreateGoodOptToggle("EquipTV_Weapon_Sub", "speed7", "Công tốc +7", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("EquipTV_Weapon_Sub", "crit10", "Đòn TV +10.0%", col1X, curY, optW)
            CreateGoodOptToggle("EquipTV_Weapon_Sub", "atk_lv20", "Atk +cấp/20", col2X, curY, optW)

            CreateSubLabel("Trang phục - Dòng chính:")
            curY = curY - 22
            CreateGoodOptToggle("EquipTV_Armor_Main", "hp4", "HP tối đa +4.0%", col1X, curY, optW)
            CreateGoodOptToggle("EquipTV_Armor_Main", "def10", "Phòng ngự +10%", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("EquipTV_Armor_Main", "reflect5", "Phản DMG +5.0%", col1X, curY, optW)
            CreateGoodOptToggle("EquipTV_Armor_Main", "gold10", "Vàng tăng +10%", col2X, curY, optW)

            CreateSubLabel("Trang phục - Dòng phụ:")
            curY = curY - 22
            CreateGoodOptToggle("EquipTV_Armor_Sub", "hp4", "HP tối đa +4.0%", col1X, curY, optW)
            CreateGoodOptToggle("EquipTV_Armor_Sub", "def10", "Phòng ngự +10%", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("EquipTV_Armor_Sub", "reflect5", "Phản DMG +5.0%", col1X, curY, optW)
            CreateGoodOptToggle("EquipTV_Armor_Sub", "gold10", "Vàng tăng +10%", col2X, curY, optW)

            -- NHÓM 2: TRANG SỨC TRÁC VIỆT
            CreateSectionHeader("--- TRANG SỨC TRÁC VIỆT ---", "(Chỉ giữ khi 100% dòng thuộc danh sách chọn)")

            CreateSubLabel("Nhẫn:")
            curY = curY - 22
            CreateGoodOptToggle("JewelryTV_Ring", "speed2", "Công tốc +2", col1X, curY, optW)
            CreateGoodOptToggle("JewelryTV_Ring", "atk1", "Tấn công +1.0%", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("JewelryTV_Ring", "crit3", "Đòn TV +3.0%", col1X, curY, optW)
            CreateGoodOptToggle("JewelryTV_Ring", "atk_lv20", "Atk +cấp/20", col2X, curY, optW)

            CreateSubLabel("Dây chuyền:")
            curY = curY - 22
            CreateGoodOptToggle("JewelryTV_Necklace", "speed2", "Công tốc +2", col1X, curY, optW)
            CreateGoodOptToggle("JewelryTV_Necklace", "atk1", "Tấn công +1.0%", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("JewelryTV_Necklace", "crit3", "Đòn TV +3.0%", col1X, curY, optW)
            CreateGoodOptToggle("JewelryTV_Necklace", "atk_lv20", "Atk +cấp/20", col2X, curY, optW)

            CreateSubLabel("Khuyên tai:")
            curY = curY - 22
            CreateGoodOptToggle("JewelryTV_Earring", "reflect4", "Phản DMG +4.0%", col1X, curY, optW)
            CreateGoodOptToggle("JewelryTV_Earring", "dmgred2", "ST giảm +2.0%", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("JewelryTV_Earring", "hp3", "HP tối đa +3.0%", col1X, curY, optW)
            CreateGoodOptToggle("JewelryTV_Earring", "def5", "Phòng ngự +5.0%", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("JewelryTV_Earring", "gold5", "Vàng tăng +5.0%", col1X, curY, optW)

            -- NHÓM 3: ĐỒ BỘ
            CreateSectionHeader("--- ĐỒ BỘ (SET EQUIPMENT) ---", "(Chỉ giữ khi 100% dòng thuộc danh sách chọn)")

            CreateSubLabel("Vũ khí Bộ:")
            curY = curY - 22
            CreateGoodOptToggle("Set_Weapon", "atk2", "Tấn công +2.0%", col1X, curY, optW)
            CreateGoodOptToggle("Set_Weapon", "speed7", "Công tốc +7", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("Set_Weapon", "crit10", "Đòn TV +10.0%", col1X, curY, optW)
            CreateGoodOptToggle("Set_Weapon", "atk_lv20", "Atk +cấp/20", col2X, curY, optW)

            CreateSubLabel("Trang phục Bộ (Mũ, Áo, Quần, Tay, Chân):")
            curY = curY - 22
            CreateGoodOptToggle("Set_Armor", "dmgred4", "ST giảm +4.0%", col1X, curY, optW)
            CreateGoodOptToggle("Set_Armor", "hp4", "HP tối đa +4.0%", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("Set_Armor", "def10", "Phòng ngự +10%", col1X, curY, optW)
            CreateGoodOptToggle("Set_Armor", "reflect5", "Phản DMG +5.0%", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("Set_Armor", "gold10", "Vàng tăng +10%", col1X, curY, optW)

            CreateSubLabel("Nhẫn, Dây chuyền Bộ:")
            curY = curY - 22
            CreateGoodOptToggle("Set_RingNecklace", "atk2", "Tấn công +2.0%", col1X, curY, optW)
            CreateGoodOptToggle("Set_RingNecklace", "speed3", "Công Tốc +3", col2X, curY, optW)

            CreateSubLabel("Khuyên Bộ:")
            curY = curY - 22
            CreateGoodOptToggle("Set_Earring", "hp3", "HP tối đa +3.0%", col1X, curY, optW)
            CreateGoodOptToggle("Set_Earring", "def4", "Phòng ngự +4.0%", col2X, curY, optW)
            curY = curY - 24
            CreateGoodOptToggle("Set_Earring", "reflect2", "Phản DMG +2.0%", col1X, curY, optW)
            CreateGoodOptToggle("Set_Earring", "gold10", "Vàng tăng +10%", col2X, curY, optW)

            curY = curY - 30
            contentRt.sizeDelta = Vector2(0, math.abs(curY))

            -- =========================================================================
            -- CỘT TRÁI (2/3 WIDTH): BOSS TIER TABS & BOSS BUTTONS GRID & FOOTER STATS
            -- =========================================================================
            local currentY = -190

            local function CreateTierTab(label, tabName)
                local btnGo = GameObject("AutoBossTier_" .. tabName)
                btnGo.transform:SetParent(panelGo.transform, false)
                table.insert(_G.AutoBossUIList, btnGo)
                local rt = btnGo:AddComponent(typeof(RectTransform))
                rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                rt.anchoredPosition = Vector2(startX, currentY)
                rt.sizeDelta = Vector2(110, 30)

                local img = btnGo:AddComponent(typeof(Image))
                img.color = Color(1, 1, 1, 0) -- Vô hình nền (không bôi background), chỉ đổi màu chữ text color

                local txtGo = GameObject("Text")
                txtGo.transform:SetParent(btnGo.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin, txtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                txtRt.sizeDelta = Vector2(0, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.fontSize = 17
                txt.alignment = TextAnchor.MiddleLeft
                if defaultFont then txt.font = defaultFont end

                local btn = btnGo:AddComponent(typeof(Button))
                return { go = btnGo, img = img, txt = txt, btn = btn, tabName = tabName }
            end

            -- Tạo sẵn Pool cho tất cả Tier từ C3 tới C12
            local allTiers = { "C3", "C4", "C5", "C6", "C7", "C8", "C9", "C10", "C11", "C12" }
            local tierTabBtns = {}
            for _, tag in ipairs(allTiers) do
                local tBtn = CreateTierTab("[ BOSS " .. tag .. " ]", tag)
                tBtn.go:SetActive(false)
                tierTabBtns[tag] = tBtn
            end

            currentY = currentY - 30
            local gridStartY = currentY

            local configPool = {}

            local function CreateConfigBtn(idx)
                local btnGo = GameObject("AutoBossConfig_" .. idx)
                btnGo.transform:SetParent(panelGo.transform, false)
                table.insert(_G.AutoBossUIList, btnGo)
                local rt = btnGo:AddComponent(typeof(RectTransform))
                rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)

                local img = btnGo:AddComponent(typeof(Image))

                local txtGo = GameObject("Text")
                txtGo.transform:SetParent(btnGo.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin, txtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                txtRt.sizeDelta = Vector2(0, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.fontSize = 14
                txt.alignment = TextAnchor.MiddleCenter
                if defaultFont then txt.font = defaultFont end

                local btn = btnGo:AddComponent(typeof(Button))

                -- =========================================================================
                -- [MOD FEATURE]: Ô INPUT GIỚI HẠN SỐ LƯỢNG BOSS AUTO FARM (40PX)
                -- Mô tả: Ô InputField nhập số lượng tối đa muốn farm của boss, lưu vào PlayerPrefs.
                -- =========================================================================
                local inGo = GameObject("AutoBossLimit_" .. idx)
                inGo.transform:SetParent(panelGo.transform, false)
                table.insert(_G.AutoBossUIList, inGo)
                local inRt = inGo:AddComponent(typeof(RectTransform))
                inRt.anchorMin, inRt.anchorMax, inRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)

                local inImg = inGo:AddComponent(typeof(Image))
                inImg.color = Color(0.15, 0.15, 0.15, 0.95)

                local inTxtGo = GameObject("Text")
                inTxtGo.transform:SetParent(inGo.transform, false)
                local inTxtRt = inTxtGo:AddComponent(typeof(RectTransform))
                inTxtRt.anchorMin, inTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                inTxtRt.offsetMin = Vector2(2, 0)
                inTxtRt.offsetMax = Vector2(-2, 0)
                local inTxt = inTxtGo:AddComponent(typeof(Text))
                inTxt.fontSize = 13
                inTxt.alignment = TextAnchor.MiddleCenter
                inTxt.color = Color(1, 0.9, 0.4, 1)
                if defaultFont then inTxt.font = defaultFont end

                local inField = inGo:AddComponent(typeof(CS.UnityEngine.UI.InputField))
                inField.textComponent = inTxt
                inField.characterLimit = 4

                return {
                    go = btnGo, rt = rt, img = img, txt = txt, btn = btn,
                    inGo = inGo, inRt = inRt, inImg = inImg, inTxt = inTxt, inField = inField
                }
            end

            UpdateTierTabs = function()
                if _G.ModMainTab ~= "AUTO_BOSS" then return end

                local currentTiers = GetAvailableTiers and GetAvailableTiers() or { "C7", "C8" }
                local isTabValid = false
                for _, tag in ipairs(currentTiers) do
                    if _G.ModAutoBossConfigTab == tag then
                        isTabValid = true; break
                    end
                end
                if not isTabValid and #currentTiers > 0 then
                    _G.ModAutoBossConfigTab = currentTiers[#currentTiers]
                end

                -- REFRESH SMELT DYNAMIC C BUTTONS REACTIONARY TO TOKEN / ACTIVE TAB
                local mainTag = _G.ModAutoBossConfigTab or currentTiers[#currentTiers] or "C4"
                local x = _G.Mod_Config_Reincarnation_Primary
                    or tonumber(string.match(mainTag, "%d+"))
                    or (GetPlayerReincarnationLevel and GetPlayerReincarnationLevel())
                    or 4

                -- =========================================================================
                -- [MOD FEATURE]: CÂN BẰNG 4 CỘT TRÁC VIỆT (x-3, x-2, x-1, x)
                -- Mô tả: Mở rộng 4 cột cho Trác Việt và Giữ Dòng Ngon Trác Việt cân xứng với Đồ Bộ
                -- =========================================================================
                -- Trác Việt (4 nút): x-3, x-2, x-1, x (Ví dụ: C10 chính -> C7, C8, C9, C10)
                local tracVietTiers = {}
                for _, offset in ipairs({ 3, 2, 1, 0 }) do
                    local tierNum = x - offset
                    if tierNum >= 3 and tierNum <= 12 then
                        table.insert(tracVietTiers, "C" .. tostring(tierNum))
                    end
                end
                if #tracVietTiers == 0 then table.insert(tracVietTiers, "C" .. tostring(x)) end

                -- Đồ Bộ & Giữ Dòng Ngon (4 nút): x-2, x-1, x, x+1
                local doBoTiers = {}
                for _, offset in ipairs({ 2, 1, 0, -1 }) do
                    local tierNum = x - offset
                    if tierNum >= 3 and tierNum <= 12 then
                        table.insert(doBoTiers, "C" .. tostring(tierNum))
                    end
                end
                if #doBoTiers == 0 then table.insert(doBoTiers, "C" .. tostring(x)) end

                -- Refresh all Smelt Toggles in pool
                for _, toggleItem in ipairs(smeltTogglePool) do
                    local isTracVietPrefix = (toggleItem.prefix == "Ring" or toggleItem.prefix == "Necklace" or toggleItem.prefix == "Earring" or toggleItem.prefix == "KeepGoodTV")
                    local tiersList = isTracVietPrefix and tracVietTiers or doBoTiers
                    local tag = tiersList[toggleItem.colIdx]
                    if tag then
                        toggleItem.go:SetActive(true)
                        toggleItem.txt.text = tag
                        local varName = toggleItem.prefix .. "_" .. tag
                        toggleItem.varName = varName

                        local defaultVal = toggleItem.isKeepGood and 1 or 0
                        if _G.Mod_SmeltConfig == nil then _G.Mod_SmeltConfig = {} end
                        if _G.Mod_SmeltConfig[varName] == nil then
                            pcall(function() _G.Mod_SmeltConfig[varName] = (CS.UnityEngine.PlayerPrefs.GetInt("Mod_Smelt_" .. varName, defaultVal) == 1) end)
                            if _G.Mod_SmeltConfig[varName] == nil then _G.Mod_SmeltConfig[varName] = (defaultVal == 1) end
                        end

                        local function updateToggleVisual()
                            if _G.Mod_SmeltConfig[varName] then
                                if toggleItem.isKeepGood then
                                    toggleItem.bgImg.color = Color(0.8, 0.5, 0.1, 1)
                                else
                                    toggleItem.bgImg.color = Color(0.2, 0.6, 0.2, 1)
                                end
                                toggleItem.txt.color = Color.white
                            else
                                toggleItem.bgImg.color = Color(0.25, 0.25, 0.25, 1)
                                toggleItem.txt.color = Color(0.7, 0.7, 0.7, 1)
                            end
                        end
                        updateToggleVisual()

                        toggleItem.btn.onClick:RemoveAllListeners()
                        toggleItem.btn.onClick:AddListener(function()
                            _G.Mod_SmeltConfig[varName] = not _G.Mod_SmeltConfig[varName]
                            pcall(function()
                                CS.UnityEngine.PlayerPrefs.SetInt("Mod_Smelt_" .. varName, _G.Mod_SmeltConfig[varName] and 1 or 0)
                                CS.UnityEngine.PlayerPrefs.Save()
                            end)
                            updateToggleVisual()
                        end)
                    else
                        toggleItem.go:SetActive(false)
                    end
                end

                -- Refresh all Good Options Toggles in pool
                for _, optItem in ipairs(goodOptTogglePool or {}) do
                    if optItem and optItem.updateVisual then pcall(optItem.updateVisual) end
                end

                -- Ẩn tất cả Tab buttons trước
                for _, tBtn in pairs(tierTabBtns) do
                    tBtn.go:SetActive(false)
                end

                -- Định vị và vẽ đúng 2 Tab (Chuyển phụ & Chuyển chính) động theo GetAvailableTiers()
                for tIdx, tag in ipairs(currentTiers) do
                    local tBtn = tierTabBtns[tag]
                    if tBtn then
                        tBtn.go:SetActive(true)
                        local isSel = (_G.ModAutoBossConfigTab == tag)
                        tBtn.txt.text = "<color=" ..
                            (isSel and "#00FF00" or "#FFFFFF") .. ">[ BOSS " .. tag .. " ]</color>"
                        tBtn.img.color = Color(1, 1, 1, 0) -- Không tô màu nền, chỉ đổi màu chữ xanh/trắng
                        local rt = tBtn.go:GetComponent(typeof(CS.UnityEngine.RectTransform))
                        if rt then
                            rt.anchoredPosition = Vector2(startX + (tIdx - 1) * 120, -190)
                            rt.sizeDelta = Vector2(110, 30)
                        end

                        local clickTag = tag
                        tBtn.btn.onClick:RemoveAllListeners()
                        tBtn.btn.onClick:AddListener(function()
                            _G.ModAutoBossConfigTab = clickTag
                            pcall(function() CS.UnityEngine.PlayerPrefs.SetString("ModAutoBossConfigTab", clickTag) end)
                            UpdateTierTabs()
                        end)
                    end
                end

                -- Hide all config toggles in pool
                for _, btnData in ipairs(configPool) do
                    btnData.go:SetActive(false)
                    if btnData.inGo then btnData.inGo:SetActive(false) end
                end

                -- Render current tier bosses
                local mapsConfig = GetMapsConfigByTier and GetMapsConfigByTier(_G.ModAutoBossConfigTab) or {}
                local py = gridStartY
                local poolIdx = 1

                if mapsConfig and #mapsConfig > 0 then
                    for _, mapCfg in ipairs(mapsConfig) do
                        -- Section Title Header
                        local btnData = configPool[poolIdx]
                        if not btnData then
                            btnData = CreateConfigBtn(poolIdx)
                            table.insert(configPool, btnData)
                        end
                        btnData.go:SetActive(_G.ModMainTab == "AUTO_BOSS")
                        if btnData.inGo then btnData.inGo:SetActive(false) end
                        btnData.rt.anchoredPosition = Vector2(startX, py)
                        btnData.rt.sizeDelta = Vector2(430, 24)

                        local mapTotalKilled = 0
                        if _G.Mod_FarmStats and _G.Mod_FarmStats.bosses and mapCfg.bosses then
                            for _, cfg in ipairs(mapCfg.bosses) do
                                mapTotalKilled = mapTotalKilled + (_G.Mod_FarmStats.bosses[cfg.id] or 0)
                            end
                        end
                        local titleStr = mapCfg.title
                        if mapTotalKilled > 0 then
                            titleStr = titleStr .. " (" .. mapTotalKilled .. ")"
                        end

                        btnData.txt.text = "<color=#FFFF00>--- " .. titleStr .. " ---</color>"
                        btnData.txt.alignment = TextAnchor.MiddleCenter
                        btnData.img.color = Color(1, 1, 1, 0)
                        btnData.btn.onClick:RemoveAllListeners()
                        poolIdx = poolIdx + 1
                        py = py - 28

                        -- Boss buttons in 3 columns (Width: 96px Btn + 40px Input, Height: 38px)
                        local colBosses = { {}, {}, {} }
                        for _, cfg in ipairs(mapCfg.bosses) do
                            local c = cfg.col or 1
                            if c > 3 then c = 3 end
                            table.insert(colBosses[c], cfg)
                        end
                        local maxRows = math.max(#colBosses[1], #colBosses[2], #colBosses[3])
                        for r = 1, maxRows do
                            for c = 1, 3 do
                                local cfg = colBosses[c][r]
                                if cfg and not cfg.isExitBtn then
                                    local px = startX + (c - 1) * 145
                                    local bData = configPool[poolIdx]
                                    if not bData then
                                        bData = CreateConfigBtn(poolIdx)
                                        table.insert(configPool, bData)
                                    end
                                    bData.go:SetActive(_G.ModMainTab == "AUTO_BOSS")
                                    if bData.inGo then bData.inGo:SetActive(_G.ModMainTab == "AUTO_BOSS") end
                                    bData.rt.anchoredPosition = Vector2(px, py)
                                    bData.rt.sizeDelta = Vector2(96, 38)
                                    if bData.inRt then
                                        bData.inRt.anchoredPosition = Vector2(px + 100, py)
                                        bData.inRt.sizeDelta = Vector2(40, 38)
                                    end
                                    bData.txt.alignment = TextAnchor.MiddleCenter

                                    if _G.Mod_AutoFarmBoss_Config[cfg.id] == nil then
                                        _G.Mod_AutoFarmBoss_Config[cfg.id] = CS.UnityEngine.PlayerPrefs.GetInt(
                                            "Mod_AutoBoss_" .. cfg.id, 0) == 1
                                    end

                                    _G.Mod_AutoFarmBoss_Limits = _G.Mod_AutoFarmBoss_Limits or {}
                                    if _G.Mod_AutoFarmBoss_Limits[cfg.id] == nil then
                                        local savedLim = CS.UnityEngine.PlayerPrefs.GetString("Mod_AutoBoss_Limit_" .. cfg.id, "")
                                        _G.Mod_AutoFarmBoss_Limits[cfg.id] = savedLim
                                    end

                                    if bData.inField then
                                        bData.inField.text = tostring(_G.Mod_AutoFarmBoss_Limits[cfg.id] or "")
                                    end

                                    local function updateBossBtnColor()
                                        local isTarget = _G.Mod_AutoFarmBoss_Target and
                                            _G.Mod_AutoFarmBoss_Target.cfg.id == cfg.id
                                        local killedCount = (_G.Mod_FarmStats and _G.Mod_FarmStats.bosses and _G.Mod_FarmStats.bosses[cfg.id]) or
                                            0
                                        local maxLimit = tonumber(_G.Mod_AutoFarmBoss_Limits and _G.Mod_AutoFarmBoss_Limits[cfg.id])
                                        local isLimitReached = (maxLimit and maxLimit > 0 and killedCount >= maxLimit)

                                        local nameLabel = cfg.name
                                        if isTarget then
                                            nameLabel = "<color=#FF0000>=> " .. cfg.name .. "</color>"
                                        end

                                        if killedCount > 0 then
                                            if isLimitReached then
                                                bData.img.color = Color(0.4, 0.35, 0.2, 1)
                                                bData.txt.text = nameLabel ..
                                                    "\n<color=#FFCC00>(" .. killedCount .. "/" .. maxLimit .. ")</color>"
                                            elseif _G.Mod_AutoFarmBoss_Config[cfg.id] then
                                                bData.img.color = Color(0.2, 0.5, 0.2, 1)
                                                bData.txt.text = nameLabel ..
                                                    "\n<color=#FFFFFF>(" .. killedCount .. (maxLimit and maxLimit > 0 and ("/" .. maxLimit) or "") .. ")</color>"
                                            else
                                                bData.img.color = Color(0.3, 0.3, 0.3, 1)
                                                bData.txt.text = nameLabel ..
                                                    "\n<color=#777777>(" .. killedCount .. (maxLimit and maxLimit > 0 and ("/" .. maxLimit) or "") .. ")</color>"
                                            end
                                        else
                                            if _G.Mod_AutoFarmBoss_Config[cfg.id] then
                                                bData.img.color = Color(0.2, 0.5, 0.2, 1)
                                                bData.txt.text = nameLabel
                                                bData.txt.color = Color.white
                                            else
                                                bData.img.color = Color(0.3, 0.3, 0.3, 1)
                                                bData.txt.text = nameLabel
                                                bData.txt.color = Color(0.7, 0.7, 0.7, 1)
                                            end
                                        end
                                    end
                                    updateBossBtnColor()

                                    bData.btn.onClick:RemoveAllListeners()
                                    bData.btn.onClick:AddListener(function()
                                        _G.Mod_AutoFarmBoss_Config[cfg.id] = not _G.Mod_AutoFarmBoss_Config[cfg.id]
                                        CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoBoss_" .. cfg.id,
                                            _G.Mod_AutoFarmBoss_Config[cfg.id] and 1 or 0)
                                        CS.UnityEngine.PlayerPrefs.Save()
                                        updateBossBtnColor()
                                    end)

                                    if bData.inField then
                                        bData.inField.onEndEdit:RemoveAllListeners()
                                        bData.inField.onEndEdit:AddListener(function(val)
                                            local cleanVal = string.gsub(val or "", "%s+", "")
                                            _G.Mod_AutoFarmBoss_Limits[cfg.id] = cleanVal
                                            pcall(function()
                                                CS.UnityEngine.PlayerPrefs.SetString("Mod_AutoBoss_Limit_" .. cfg.id, cleanVal)
                                                CS.UnityEngine.PlayerPrefs.Save()
                                            end)
                                            updateBossBtnColor()
                                        end)
                                    end

                                    poolIdx = poolIdx + 1
                                end
                            end
                            py = py - 42
                        end
                        py = py - 10
                    end
                end

                -- Bottom Stats Bar
                if not _G.Mod_FarmStatsUI then
                    local containerGo = GameObject("FarmStatsContainer")
                    containerGo.transform:SetParent(panelGo.transform, false)
                    table.insert(_G.AutoBossUIList, containerGo)
                    local rt = containerGo:AddComponent(typeof(RectTransform))
                    rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                    _G.Mod_FarmStatsUI = { go = containerGo, rt = rt }

                    local resetBtnGo = GameObject("ResetBtn")
                    resetBtnGo.transform:SetParent(containerGo.transform, false)
                    local rBtnRt = resetBtnGo:AddComponent(typeof(RectTransform))
                    rBtnRt.anchorMin, rBtnRt.anchorMax, rBtnRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                    rBtnRt.anchoredPosition = Vector2(0, 0)
                    rBtnRt.sizeDelta = Vector2(130, 30)
                    local rBtnImg = resetBtnGo:AddComponent(typeof(Image))
                    rBtnImg.color = Color(0.6, 0.2, 0.2, 1)
                    local rBtnTxtGo = GameObject("Text")
                    rBtnTxtGo.transform:SetParent(resetBtnGo.transform, false)
                    local rBtnTxtRt = rBtnTxtGo:AddComponent(typeof(RectTransform))
                    rBtnTxtRt.anchorMin, rBtnTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                    rBtnTxtRt.sizeDelta = Vector2(0, 0)
                    local rBtnTxt = rBtnTxtGo:AddComponent(typeof(Text))
                    rBtnTxt.raycastTarget = false
                    rBtnTxt.text = "RESET THỐNG KÊ"
                    rBtnTxt.color = Color.white
                    rBtnTxt.fontSize = 14
                    rBtnTxt.alignment = TextAnchor.MiddleCenter
                    if defaultFont then rBtnTxt.font = defaultFont end
                    local rBtn = resetBtnGo:AddComponent(typeof(Button))
                    rBtn.onClick:AddListener(function()
                        _G.Mod_FarmStats = { hidden = 0, bosses = {} }
                        if _G.Mod_SaveFarmStats then _G.Mod_SaveFarmStats() end
                        if _G.ModRefreshAutoBossConfigUI then _G.ModRefreshAutoBossConfigUI() end
                    end)

                    local statTxtGo = GameObject("StatText")
                    statTxtGo.transform:SetParent(containerGo.transform, false)
                    local sTxtRt = statTxtGo:AddComponent(typeof(RectTransform))
                    sTxtRt.anchorMin, sTxtRt.anchorMax, sTxtRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                    sTxtRt.anchoredPosition = Vector2(140, 0)
                    sTxtRt.sizeDelta = Vector2(300, 30)
                    local sTxt = statTxtGo:AddComponent(typeof(Text))
                    sTxt.raycastTarget = false
                    sTxt.color = Color(1, 0.8, 0, 1)
                    sTxt.fontSize = 14
                    sTxt.alignment = TextAnchor.MiddleLeft
                    if defaultFont then sTxt.font = defaultFont end
                    _G.Mod_FarmStatsUI.sTxt = sTxt
                end

                _G.Mod_FarmStatsUI.go:SetActive(_G.ModMainTab == "AUTO_BOSS")
                _G.Mod_FarmStatsUI.rt.anchoredPosition = Vector2(startX, py - 10)

                _G.Mod_FarmStats = _G.Mod_FarmStats or { hidden = 0, bosses = {} }
                local prevTag = currentTiers[1] or "C7"
                local currTag = currentTiers[2] or prevTag

                local prevCfg = GetMapsConfigByTier and GetMapsConfigByTier(prevTag) or {}
                local currCfg = (currTag ~= prevTag and GetMapsConfigByTier) and GetMapsConfigByTier(currTag) or {}

                local totalPrev, totalCurr = 0, 0
                if _G.Mod_FarmStats.bosses then
                    for id, count in pairs(_G.Mod_FarmStats.bosses) do
                        local inPrev = false
                        for _, map in ipairs(prevCfg) do
                            if map.bosses then
                                for _, b in ipairs(map.bosses) do
                                    if b.id == id then
                                        inPrev = true; break
                                    end
                                end
                            end
                            if inPrev then break end
                        end
                        if inPrev then
                            totalPrev = totalPrev + count
                        else
                            local inCurr = false
                            for _, map in ipairs(currCfg) do
                                if map.bosses then
                                    for _, b in ipairs(map.bosses) do
                                        if b.id == id then
                                            inCurr = true; break
                                        end
                                    end
                                end
                                if inCurr then break end
                            end
                            if inCurr then
                                totalCurr = totalCurr + count
                            end
                        end
                    end
                end

                local hiddenCount = _G.Mod_FarmStats.hidden or 0
                if prevTag ~= currTag then
                    _G.Mod_FarmStatsUI.sTxt.text = string.format("ẨN: %d  |  %s: %d  |  %s: %d", hiddenCount, prevTag,
                        totalPrev, currTag, totalCurr)
                else
                    _G.Mod_FarmStatsUI.sTxt.text = string.format("ẨN: %d  |  %s: %d", hiddenCount, prevTag, totalPrev)
                end
            end

            _G.ModRefreshAutoBossConfigUI = function()
                if _G.ModMainTab == "AUTO_BOSS" then
                    UpdateTierTabs()
                end
            end
            UpdateTierTabs()
        end
        local function CreateKundunUI()
            local currentY = -58
            local rightColX2 = 375

            -- Vạch dọc phân cách
            local vLineGo = GameObject("VerticalSeparator")
            vLineGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, vLineGo)
            local vLineRt = vLineGo:AddComponent(typeof(RectTransform))
            vLineRt.anchorMin, vLineRt.anchorMax, vLineRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            vLineRt.anchoredPosition = Vector2(360, -50)
            vLineRt.sizeDelta = Vector2(2, 530)
            local vLineImg = vLineGo:AddComponent(typeof(Image))
            vLineImg.color = Color(0.4, 0.4, 0.4, 1)

            local ChucNangTitle = GameObject("ChucNangTitle")
            ChucNangTitle.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, ChucNangTitle)
            local titleRt = ChucNangTitle:AddComponent(typeof(RectTransform))
            titleRt.anchorMin = Vector2(0, 1)
            titleRt.anchorMax = Vector2(0, 1)
            titleRt.pivot = Vector2(0, 1)
            titleRt.anchoredPosition = Vector2(rightColX2 + 5, currentY)
            titleRt.sizeDelta = Vector2(320, 22)
            local ChucNangTitleTxt = ChucNangTitle:AddComponent(typeof(Text))
            ChucNangTitleTxt.raycastTarget = false
            ChucNangTitleTxt.text = "[ CHỨC NĂNG HỖ TRỢ ]"
            ChucNangTitleTxt.color = Color(1, 0.8, 0, 1)
            ChucNangTitleTxt.fontSize = 18
            ChucNangTitleTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then ChucNangTitleTxt.font = defaultFont end

            currentY = currentY - 30

            CreateToggle("TIẾP CẬN BOSS THÁP", "Mod_AutoApproachTowerBoss", rightColX2, currentY)
            currentY = currentY - 40

            CreateToggle("HIỆN MÁU KUNDUN", "Mod_ShowKundunHP", rightColX2, currentY)
            currentY = currentY - 40

            -- =========================================================================
            -- [MOD FEATURE]: ẨN NÚT AUTO PK GUILD THEO SECRET COMMAND (/pkmodeguild)
            -- Mô tả: Nút AUTO PK GUILD chỉ hiển thị khi có secret command /pkmodeguild trong hệ thống lệnh bí mật.
            -- =========================================================================
            if _G.Mod_HasSecretCommand and _G.Mod_HasSecretCommand("/pkmodeguild") then
                CreateToggle("AUTO PK GUILD", "Mod_AutoGuildPK_Enabled", rightColX2, currentY)
                currentY = currentY - 40
            end

            -- Nút Radio Hồi Sinh: HS FREE & HS KC (Chỉ 1 trong 2 được bật)
            local function CreateResurrectRadioGroup(xPos, yPos, btnW)
                btnW = btnW or 160
                local spacing = 10

                if _G.Mod_AutoResurrect_Free_Enabled == nil then
                    pcall(function()
                        _G.Mod_AutoResurrect_Free_Enabled = (CS.UnityEngine.PlayerPrefs.GetInt("Mod_AutoResurrect_Free_Enabled", 0) == 1)
                    end)
                    if _G.Mod_AutoResurrect_Free_Enabled == nil then _G.Mod_AutoResurrect_Free_Enabled = false end
                end

                if _G.Mod_AutoResurrect_Here_Enabled == nil then
                    pcall(function()
                        _G.Mod_AutoResurrect_Here_Enabled = (CS.UnityEngine.PlayerPrefs.GetInt("Mod_AutoResurrect_Here_Enabled", 0) == 1)
                    end)
                    if _G.Mod_AutoResurrect_Here_Enabled == nil then _G.Mod_AutoResurrect_Here_Enabled = false end
                end

                if _G.Mod_AutoResurrect_Free_Enabled and _G.Mod_AutoResurrect_Here_Enabled then
                    _G.Mod_AutoResurrect_Free_Enabled = false
                end

                -- 1. NÚT HS FREE
                local hsFreeGo = GameObject("HS_FREE_RadioToggle")
                hsFreeGo.transform:SetParent(panelGo.transform, false)
                table.insert(_G.NangCaoUIList, hsFreeGo)
                local freeRt = hsFreeGo:AddComponent(typeof(RectTransform))
                freeRt.anchorMin, freeRt.anchorMax, freeRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                freeRt.anchoredPosition = Vector2(xPos, yPos)
                freeRt.sizeDelta = Vector2(btnW, 34)

                local freeBg = GameObject("Bg")
                freeBg.transform:SetParent(hsFreeGo.transform, false)
                local freeBgRt = freeBg:AddComponent(typeof(RectTransform))
                freeBgRt.anchorMin, freeBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                freeBgRt.sizeDelta = Vector2(0, 0)
                local freeBgImg = freeBg:AddComponent(typeof(Image))

                local freeTxtGo = GameObject("Text")
                freeTxtGo.transform:SetParent(hsFreeGo.transform, false)
                local freeTxtRt = freeTxtGo:AddComponent(typeof(RectTransform))
                freeTxtRt.anchorMin, freeTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                freeTxtRt.sizeDelta = Vector2(0, 0)
                local freeTxt = freeTxtGo:AddComponent(typeof(Text))
                freeTxt.raycastTarget = false
                freeTxt.text = "HS FREE"
                freeTxt.fontSize = 15
                freeTxt.alignment = TextAnchor.MiddleCenter
                if defaultFont then freeTxt.font = defaultFont end

                local freeBtn = hsFreeGo:AddComponent(typeof(Button))

                -- 2. NÚT HS KC
                local hsKcGo = GameObject("HS_KC_RadioToggle")
                hsKcGo.transform:SetParent(panelGo.transform, false)
                table.insert(_G.NangCaoUIList, hsKcGo)
                local kcRt = hsKcGo:AddComponent(typeof(RectTransform))
                kcRt.anchorMin, kcRt.anchorMax, kcRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                kcRt.anchoredPosition = Vector2(xPos + btnW + spacing, yPos)
                kcRt.sizeDelta = Vector2(btnW, 34)

                local kcBg = GameObject("Bg")
                kcBg.transform:SetParent(hsKcGo.transform, false)
                local kcBgRt = kcBg:AddComponent(typeof(RectTransform))
                kcBgRt.anchorMin, kcBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                kcBgRt.sizeDelta = Vector2(0, 0)
                local kcBgImg = kcBg:AddComponent(typeof(Image))

                local kcTxtGo = GameObject("Text")
                kcTxtGo.transform:SetParent(hsKcGo.transform, false)
                local kcTxtRt = kcTxtGo:AddComponent(typeof(RectTransform))
                kcTxtRt.anchorMin, kcTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                kcTxtRt.sizeDelta = Vector2(0, 0)
                local kcTxt = kcTxtGo:AddComponent(typeof(Text))
                kcTxt.raycastTarget = false
                kcTxt.text = "HS KC"
                kcTxt.fontSize = 15
                kcTxt.alignment = TextAnchor.MiddleCenter
                if defaultFont then kcTxt.font = defaultFont end

                local kcBtn = hsKcGo:AddComponent(typeof(Button))

                local function UpdateResurrectVisuals()
                    if _G.Mod_AutoResurrect_Free_Enabled then
                        freeBgImg.color = Color(0.2, 0.6, 0.2, 1)
                        freeTxt.color = Color.white
                    else
                        freeBgImg.color = Color(0.3, 0.3, 0.3, 1)
                        freeTxt.color = Color(0.8, 0.8, 0.8, 1)
                    end

                    if _G.Mod_AutoResurrect_Here_Enabled then
                        kcBgImg.color = Color(0.2, 0.6, 0.2, 1)
                        kcTxt.color = Color.white
                    else
                        kcBgImg.color = Color(0.3, 0.3, 0.3, 1)
                        kcTxt.color = Color(0.8, 0.8, 0.8, 1)
                    end
                end
                UpdateResurrectVisuals()

                freeBtn.onClick:AddListener(function()
                    if not _G.Mod_AutoResurrect_Free_Enabled then
                        _G.Mod_AutoResurrect_Free_Enabled = true
                        _G.Mod_AutoResurrect_Here_Enabled = false
                    else
                        _G.Mod_AutoResurrect_Free_Enabled = false
                    end

                    pcall(function()
                        CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoResurrect_Free_Enabled", _G.Mod_AutoResurrect_Free_Enabled and 1 or 0)
                        CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoResurrect_Here_Enabled", _G.Mod_AutoResurrect_Here_Enabled and 1 or 0)
                        CS.UnityEngine.PlayerPrefs.Save()
                    end)
                    UpdateResurrectVisuals()
                end)

                kcBtn.onClick:AddListener(function()
                    if not _G.Mod_AutoResurrect_Here_Enabled then
                        _G.Mod_AutoResurrect_Here_Enabled = true
                        _G.Mod_AutoResurrect_Free_Enabled = false
                    else
                        _G.Mod_AutoResurrect_Here_Enabled = false
                    end

                    pcall(function()
                        CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoResurrect_Free_Enabled", _G.Mod_AutoResurrect_Free_Enabled and 1 or 0)
                        CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoResurrect_Here_Enabled", _G.Mod_AutoResurrect_Here_Enabled and 1 or 0)
                        CS.UnityEngine.PlayerPrefs.Save()
                    end)
                    UpdateResurrectVisuals()
                end)
            end

            CreateResurrectRadioGroup(rightColX2, currentY, 160)
            currentY = currentY - 40

            -- Cài đặt DELAY QUÉT PK
            local function CreatePKDelayControl(xPos, yPos)
                local go = GameObject("Mod_PKScanDelay_Control")
                go.transform:SetParent(panelGo.transform, false)
                table.insert(_G.NangCaoUIList, go)

                local rt = go:AddComponent(typeof(RectTransform))
                rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                rt.anchoredPosition = Vector2(xPos, yPos)
                rt.sizeDelta = Vector2(330, 34)

                local bg = GameObject("Bg")
                bg.transform:SetParent(go.transform, false)
                local bgRt = bg:AddComponent(typeof(RectTransform))
                bgRt.anchorMin, bgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                bgRt.sizeDelta = Vector2(0, 0)
                local bgImg = bg:AddComponent(typeof(Image))
                bgImg.color = Color(0.2, 0.2, 0.2, 1)

                local txtGo = GameObject("Text")
                txtGo.transform:SetParent(go.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin, txtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                txtRt.offsetMin, txtRt.offsetMax = Vector2(8, 0), Vector2(-105, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.fontSize = 14
                txt.alignment = TextAnchor.MiddleLeft
                txt.color = Color.white
                if defaultFont then txt.font = defaultFont end

                if _G.Mod_PKScanDelay == nil then
                    pcall(function() _G.Mod_PKScanDelay = CS.UnityEngine.PlayerPrefs.GetFloat("Mod_PKScanDelay", 0.8) end)
                end
                if not _G.Mod_PKScanDelay or _G.Mod_PKScanDelay < 0.1 then
                    _G.Mod_PKScanDelay = 0.8
                end

                local function UpdateLabel()
                    txt.text = string.format("DELAY QUÉT PK: %.1fs", _G.Mod_PKScanDelay or 0.8)
                end
                UpdateLabel()

                local function createBtn(name, offsetX, width, btnText, btnColor)
                    local btnGo = GameObject(name)
                    btnGo.transform:SetParent(go.transform, false)
                    table.insert(_G.NangCaoUIList, btnGo)
                    local bRt = btnGo:AddComponent(typeof(RectTransform))
                    bRt.anchorMin, bRt.anchorMax, bRt.pivot = Vector2(1, 0.5), Vector2(1, 0.5), Vector2(1, 0.5)
                    bRt.anchoredPosition = Vector2(offsetX, 0)
                    bRt.sizeDelta = Vector2(width, 28)
                    local bImg = btnGo:AddComponent(typeof(Image))
                    bImg.color = btnColor

                    local bTxtGo = GameObject("Text")
                    bTxtGo.transform:SetParent(btnGo.transform, false)
                    local bTxtRt = bTxtGo:AddComponent(typeof(RectTransform))
                    bTxtRt.anchorMin, bTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                    bTxtRt.sizeDelta = Vector2(0, 0)
                    local bTxt = bTxtGo:AddComponent(typeof(Text))
                    bTxt.raycastTarget = false
                    bTxt.text = btnText
                    bTxt.color = Color.white
                    bTxt.fontSize = 15
                    bTxt.alignment = TextAnchor.MiddleCenter
                    if defaultFont then bTxt.font = defaultFont end

                    return btnGo:AddComponent(typeof(Button))
                end

                local mBtn = createBtn("MinusBtn", -52, 46, "-0.1", Color(0.5, 0.2, 0.2, 1))
                local pBtn = createBtn("PlusBtn", -4, 46, "+0.1", Color(0.2, 0.5, 0.2, 1))

                mBtn.onClick:AddListener(function()
                    _G.Mod_PKScanDelay = math.max(0.1, math.floor(((_G.Mod_PKScanDelay or 0.8) - 0.1) * 10 + 0.5) / 10)
                    pcall(function()
                        CS.UnityEngine.PlayerPrefs.SetFloat("Mod_PKScanDelay", _G.Mod_PKScanDelay)
                        CS.UnityEngine.PlayerPrefs.Save()
                    end)
                    UpdateLabel()
                end)

                pBtn.onClick:AddListener(function()
                    _G.Mod_PKScanDelay = math.min(5.0, math.floor(((_G.Mod_PKScanDelay or 0.8) + 0.1) * 10 + 0.5) / 10)
                    pcall(function()
                        CS.UnityEngine.PlayerPrefs.SetFloat("Mod_PKScanDelay", _G.Mod_PKScanDelay)
                        CS.UnityEngine.PlayerPrefs.Save()
                    end)
                    UpdateLabel()
                end)
            end

            CreatePKDelayControl(rightColX2, currentY)
            currentY = currentY - 40

            -- Toggle KHÓA MỤC TIÊU
            local tGoLock = GameObject("Mod_LockTarget_Enabled_Toggle")
            tGoLock.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, tGoLock)

            local tRtLock = tGoLock:AddComponent(typeof(RectTransform))
            tRtLock.anchorMin, tRtLock.anchorMax, tRtLock.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            tRtLock.anchoredPosition = Vector2(rightColX2, currentY)
            tRtLock.sizeDelta = Vector2(165, 34)

            local bgLock = GameObject("Bg")
            bgLock.transform:SetParent(tGoLock.transform, false)
            local bgRtLock = bgLock:AddComponent(typeof(RectTransform))
            bgRtLock.anchorMin, bgRtLock.anchorMax = Vector2(0, 0), Vector2(1, 1)
            bgRtLock.sizeDelta = Vector2(0, 0)
            local bgImgLock = bgLock:AddComponent(typeof(Image))

            local txtGoLock = GameObject("Text")
            txtGoLock.transform:SetParent(tGoLock.transform, false)
            local txtRtLock = txtGoLock:AddComponent(typeof(RectTransform))
            txtRtLock.anchorMin, txtRtLock.anchorMax = Vector2(0, 0), Vector2(1, 1)
            txtRtLock.sizeDelta = Vector2(0, 0)
            local txtLock = txtGoLock:AddComponent(typeof(Text))
            txtLock.raycastTarget = false
            txtLock.fontSize = 15
            txtLock.alignment = TextAnchor.MiddleCenter
            if defaultFont then txtLock.font = defaultFont end

            local btnLock = tGoLock:AddComponent(typeof(Button))

            if _G.Mod_LockTarget_Enabled == nil then
                _G.Mod_LockTarget_Enabled = CS.UnityEngine.PlayerPrefs.GetInt("Mod_LockTarget_Enabled", 0) == 1
            end

            local function UpdateLockLabel()
                if _G.Mod_LockTarget_Enabled then
                    bgImgLock.color = Color(0.2, 0.5, 0.2, 1)
                    txtLock.text = "KHÓA MỤC TIÊU"
                    txtLock.color = Color.white
                else
                    bgImgLock.color = Color(0.3, 0.3, 0.3, 1)
                    txtLock.text = "KHÓA MỤC TIÊU"
                    txtLock.color = Color(0.7, 0.7, 0.7, 1)
                end
            end
            UpdateLockLabel()

            btnLock.onClick:AddListener(function()
                _G.Mod_LockTarget_Enabled = not _G.Mod_LockTarget_Enabled
                CS.UnityEngine.PlayerPrefs.SetInt("Mod_LockTarget_Enabled", _G.Mod_LockTarget_Enabled and 1 or 0)
                CS.UnityEngine.PlayerPrefs.Save()
                UpdateLockLabel()
            end)

            -- Text Field cho Khóa mục tiêu
            local lockTgtGo = GameObject("LockTargetInput")
            lockTgtGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, lockTgtGo)
            local lockRt = lockTgtGo:AddComponent(typeof(RectTransform))
            lockRt.anchorMin, lockRt.anchorMax, lockRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            lockRt.anchoredPosition = Vector2(rightColX2 + 172, currentY)
            lockRt.sizeDelta = Vector2(158, 34)

            local lockBg = GameObject("Bg")
            lockBg.transform:SetParent(lockTgtGo.transform, false)
            local lockBgRt = lockBg:AddComponent(typeof(RectTransform))
            lockBgRt.anchorMin, lockBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            lockBgRt.sizeDelta = Vector2(0, 0)
            local lockImg = lockBg:AddComponent(typeof(Image))
            lockImg.color = Color(0.1, 0.1, 0.1, 1)

            local lockTxtGo = GameObject("Text")
            lockTxtGo.transform:SetParent(lockTgtGo.transform, false)
            local lockTxtRt = lockTxtGo:AddComponent(typeof(RectTransform))
            lockTxtRt.anchorMin, lockTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            lockTxtRt.offsetMin, lockTxtRt.offsetMax = Vector2(5, 0), Vector2(-5, 0)
            local lockTxt = lockTxtGo:AddComponent(typeof(Text))

            if _G.Mod_LockTarget_Name == nil then
                _G.Mod_LockTarget_Name = CS.UnityEngine.PlayerPrefs.GetString("Mod_LockTarget_Name", "")
            end

            lockTxt.text = _G.Mod_LockTarget_Name
            lockTxt.color, lockTxt.fontSize = Color.white, 15
            lockTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then lockTxt.font = defaultFont end

            pcall(function()
                local InputFieldType = InputField or (CS.UnityEngine.UI and CS.UnityEngine.UI.InputField)
                if InputFieldType then
                    local lockField = lockTgtGo:AddComponent(typeof(InputFieldType))
                    if lockField then
                        lockField.textComponent = lockTxt
                        lockField.text = _G.Mod_LockTarget_Name
                        if lockField.onValueChanged then
                            lockField.onValueChanged:AddListener(function(val)
                                _G.Mod_LockTarget_Name = val
                                pcall(function()
                                    CS.UnityEngine.PlayerPrefs.SetString("Mod_LockTarget_Name", val)
                                    CS.UnityEngine.PlayerPrefs.Save()
                                end)
                            end)
                        end
                    end
                end
            end)

            currentY = currentY - 40
            CreateToggle("TỰ QUAY LẠI X#Y", "Mod_AutoReturnPos_Enabled", rightColX2, currentY)
            currentY = currentY - 40

            -- Cài đặt DELAY QUAY LẠI
            local function CreateReturnPosDelayControl(xPos, yPos)
                local go = GameObject("Mod_ReturnPosDelay_Control")
                go.transform:SetParent(panelGo.transform, false)
                table.insert(_G.NangCaoUIList, go)

                local rt = go:AddComponent(typeof(RectTransform))
                rt.anchorMin, rt.anchorMax, rt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
                rt.anchoredPosition = Vector2(xPos, yPos)
                rt.sizeDelta = Vector2(330, 34)

                local bg = GameObject("Bg")
                bg.transform:SetParent(go.transform, false)
                local bgRt = bg:AddComponent(typeof(RectTransform))
                bgRt.anchorMin, bgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                bgRt.sizeDelta = Vector2(0, 0)
                local bgImg = bg:AddComponent(typeof(Image))
                bgImg.color = Color(0.2, 0.2, 0.2, 1)

                local txtGo = GameObject("Text")
                txtGo.transform:SetParent(go.transform, false)
                local txtRt = txtGo:AddComponent(typeof(RectTransform))
                txtRt.anchorMin, txtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                txtRt.offsetMin, txtRt.offsetMax = Vector2(8, 0), Vector2(-105, 0)
                local txt = txtGo:AddComponent(typeof(Text))
                txt.raycastTarget = false
                txt.fontSize = 14
                txt.alignment = TextAnchor.MiddleLeft
                txt.color = Color.white
                if defaultFont then txt.font = defaultFont end

                if _G.Mod_AutoReturnPosDelay == nil then
                    pcall(function()
                        _G.Mod_AutoReturnPosDelay = CS.UnityEngine.PlayerPrefs.GetFloat("Mod_AutoReturnPosDelay", 1.0)
                    end)
                end
                if not _G.Mod_AutoReturnPosDelay or _G.Mod_AutoReturnPosDelay < 0.1 then
                    _G.Mod_AutoReturnPosDelay = 1.0
                end

                local function UpdateLabel()
                    txt.text = string.format("DELAY QUAY LẠI: %.1fs", _G.Mod_AutoReturnPosDelay or 1.0)
                end
                UpdateLabel()

                local function createBtn(name, offsetX, width, btnText, btnColor)
                    local btnGo = GameObject(name)
                    btnGo.transform:SetParent(go.transform, false)
                    table.insert(_G.NangCaoUIList, btnGo)
                    local bRt = btnGo:AddComponent(typeof(RectTransform))
                    bRt.anchorMin, bRt.anchorMax, bRt.pivot = Vector2(1, 0.5), Vector2(1, 0.5), Vector2(1, 0.5)
                    bRt.anchoredPosition = Vector2(offsetX, 0)
                    bRt.sizeDelta = Vector2(width, 28)
                    local bImg = btnGo:AddComponent(typeof(Image))
                    bImg.color = btnColor

                    local bTxtGo = GameObject("Text")
                    bTxtGo.transform:SetParent(btnGo.transform, false)
                    local bTxtRt = bTxtGo:AddComponent(typeof(RectTransform))
                    bTxtRt.anchorMin, bTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
                    bTxtRt.sizeDelta = Vector2(0, 0)
                    local bTxt = bTxtGo:AddComponent(typeof(Text))
                    bTxt.raycastTarget = false
                    bTxt.text = btnText
                    bTxt.color = Color.white
                    bTxt.fontSize = 15
                    bTxt.alignment = TextAnchor.MiddleCenter
                    if defaultFont then bTxt.font = defaultFont end

                    return btnGo:AddComponent(typeof(Button))
                end

                local mBtn = createBtn("MinusBtn", -52, 46, "-0.1", Color(0.5, 0.2, 0.2, 1))
                local pBtn = createBtn("PlusBtn", -4, 46, "+0.1", Color(0.2, 0.5, 0.2, 1))

                mBtn.onClick:AddListener(function()
                    _G.Mod_AutoReturnPosDelay = math.max(0.1,
                        math.floor(((_G.Mod_AutoReturnPosDelay or 1.0) - 0.1) * 10 + 0.5) / 10)
                    pcall(function()
                        CS.UnityEngine.PlayerPrefs.SetFloat("Mod_AutoReturnPosDelay", _G.Mod_AutoReturnPosDelay)
                        CS.UnityEngine.PlayerPrefs.Save()
                    end)
                    UpdateLabel()
                end)

                pBtn.onClick:AddListener(function()
                    _G.Mod_AutoReturnPosDelay = math.min(10.0,
                        math.floor(((_G.Mod_AutoReturnPosDelay or 1.0) + 0.1) * 10 + 0.5) / 10)
                    pcall(function()
                        CS.UnityEngine.PlayerPrefs.SetFloat("Mod_AutoReturnPosDelay", _G.Mod_AutoReturnPosDelay)
                        CS.UnityEngine.PlayerPrefs.Save()
                    end)
                    UpdateLabel()
                end)
            end

            CreateReturnPosDelayControl(rightColX2, currentY)
            currentY = currentY - 40

            -- Nút LẤY VỊ TRÍ
            local getReturnPosBtnGo = GameObject("GetReturnPosBtn")
            getReturnPosBtnGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, getReturnPosBtnGo)
            local getReturnPosRt = getReturnPosBtnGo:AddComponent(typeof(RectTransform))
            getReturnPosRt.anchorMin, getReturnPosRt.anchorMax, getReturnPosRt.pivot = Vector2(0, 1), Vector2(0, 1),
                Vector2(0, 1)
            getReturnPosRt.anchoredPosition = Vector2(rightColX2, currentY)
            getReturnPosRt.sizeDelta = Vector2(165, 34)

            local getReturnPosBg = GameObject("Bg")
            getReturnPosBg.transform:SetParent(getReturnPosBtnGo.transform, false)
            local getReturnPosBgRt = getReturnPosBg:AddComponent(typeof(RectTransform))
            getReturnPosBgRt.anchorMin, getReturnPosBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            getReturnPosBgRt.sizeDelta = Vector2(0, 0)
            local getReturnPosBgImg = getReturnPosBg:AddComponent(typeof(Image))
            getReturnPosBgImg.color = Color(0.2, 0.5, 0.7, 1)

            local getReturnPosTxtGo = GameObject("Text")
            getReturnPosTxtGo.transform:SetParent(getReturnPosBtnGo.transform, false)
            local getReturnPosTxtRt = getReturnPosTxtGo:AddComponent(typeof(RectTransform))
            getReturnPosTxtRt.anchorMin, getReturnPosTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            getReturnPosTxtRt.sizeDelta = Vector2(0, 0)
            local getReturnPosTxt = getReturnPosTxtGo:AddComponent(typeof(Text))
            getReturnPosTxt.raycastTarget = false
            getReturnPosTxt.text = "LẤY VỊ TRÍ"
            getReturnPosTxt.color = Color.white
            getReturnPosTxt.fontSize = 15
            getReturnPosTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then getReturnPosTxt.font = defaultFont end

            -- InputField Tọa độ AutoReturnPosInput
            local retTgtGo = GameObject("AutoReturnPosInput")
            retTgtGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, retTgtGo)
            local retRt = retTgtGo:AddComponent(typeof(RectTransform))
            retRt.anchorMin, retRt.anchorMax, retRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            retRt.anchoredPosition = Vector2(rightColX2 + 172, currentY)
            retRt.sizeDelta = Vector2(158, 34)

            local retBg = GameObject("Bg")
            retBg.transform:SetParent(retTgtGo.transform, false)
            local retBgRt = retBg:AddComponent(typeof(RectTransform))
            retBgRt.anchorMin, retBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            retBgRt.sizeDelta = Vector2(0, 0)
            local retImg = retBg:AddComponent(typeof(Image))
            retImg.color = Color(0.1, 0.1, 0.1, 1)

            local retTxtGo = GameObject("Text")
            retTxtGo.transform:SetParent(retTgtGo.transform, false)
            local retTxtRt = retTxtGo:AddComponent(typeof(RectTransform))
            retTxtRt.anchorMin, retTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            retTxtRt.offsetMin, retTxtRt.offsetMax = Vector2(5, 0), Vector2(-5, 0)
            local retTxt = retTxtGo:AddComponent(typeof(Text))

            if _G.Mod_AutoReturnPos_Coords == nil or _G.Mod_AutoReturnPos_Coords == "" then
                pcall(function()
                    _G.Mod_AutoReturnPos_Coords = CS.UnityEngine.PlayerPrefs.GetString("Mod_AutoReturnPos_Coords", "")
                    if not _G.Mod_AutoReturnPos_Coords or _G.Mod_AutoReturnPos_Coords == "" then
                        _G.Mod_AutoReturnPos_Coords = CS.UnityEngine.PlayerPrefs.GetString("Mod_TrainCoord", "")
                    end
                end)
                if _G.Mod_AutoReturnPos_Coords == nil then _G.Mod_AutoReturnPos_Coords = "" end
            end
            _G.Mod_TrainCoord = _G.Mod_AutoReturnPos_Coords

            retTxt.text = _G.Mod_AutoReturnPos_Coords
            retTxt.color, retTxt.fontSize = Color.white, 15
            retTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then retTxt.font = defaultFont end

            pcall(function()
                local InputFieldType = InputField or (CS.UnityEngine.UI and CS.UnityEngine.UI.InputField)
                if InputFieldType then
                    local retField = retTgtGo:AddComponent(typeof(InputFieldType))
                    if retField then
                        retField.textComponent = retTxt
                        retField.text = _G.Mod_AutoReturnPos_Coords
                        if retField.onValueChanged then
                            retField.onValueChanged:AddListener(function(val)
                                _G.Mod_AutoReturnPos_Coords = val
                                _G.Mod_TrainCoord = val
                                pcall(function()
                                    CS.UnityEngine.PlayerPrefs.SetString("Mod_AutoReturnPos_Coords", val)
                                    CS.UnityEngine.PlayerPrefs.SetString("Mod_TrainCoord", val)
                                    CS.UnityEngine.PlayerPrefs.Save()
                                end)
                            end)
                        end
                    end
                end
            end)

            local getReturnPosBtn = getReturnPosBtnGo:AddComponent(typeof(Button))
            getReturnPosBtn.onClick:AddListener(function()
                pcall(function()
                    if _G.RoleManager and _G.RoleManager.me then
                        local me = _G.RoleManager.me
                        local curX = me.serverCoord and me.serverCoord.x or (me.cellPos and me.cellPos.x) or 0
                        local curY = me.serverCoord and me.serverCoord.y or (me.cellPos and me.cellPos.y) or 0
                        if curX > 0 and curY > 0 then
                            local coordStr = string.format("%d#%d", curX, curY)
                            _G.Mod_AutoReturnPos_Coords = coordStr
                            _G.Mod_TrainCoord = coordStr
                            local retField = retTgtGo:GetComponent(typeof(CS.UnityEngine.UI.InputField))
                            if retField then retField.text = coordStr end
                            retTxt.text = coordStr
                            CS.UnityEngine.PlayerPrefs.SetString("Mod_AutoReturnPos_Coords", coordStr)
                            CS.UnityEngine.PlayerPrefs.SetString("Mod_TrainCoord", coordStr)
                            CS.UnityEngine.PlayerPrefs.Save()
                            if _G.FloatingWordUtility then
                                _G.FloatingWordUtility.QuickMsg("Đã lấy vị trí: " .. coordStr)
                            end
                        end
                    end
                end)
            end)

            currentY = currentY - 40
            CreateToggle("MỞ RƯƠNG VÀNG", "Mod_AutoOpenGoldenChest_Enabled", rightColX2, currentY)
            currentY = currentY - 40
            -- [MOD FEATURE]: TẮT HIỆU ỨNG & TÌM HỎA LONG (CUSTOMER)
            -- Mô tả: Hiển thị 2 nút Tắt Hiệu Ứng và Tìm Hỏa Long trên cùng 1 hàng ngang (W: 160px mỗi nút)
            CreateToggle("TẮT HIỆU ỨNG", "Mod_DisableVisuals", rightColX2, currentY, 160)
            CreateToggle("TÌM HỎA LONG", "Mod_FindHoaLong_Enabled", rightColX2 + 170, currentY, 160)
            currentY = currentY - 40

            -- =========================================================================
            -- [MOD FEATURE]: HÀNG NHẬP LỆNH BÍ MẬT & NÚT LOAD ĐÁY CỘT HỖ TRỢ (CUSTOMER)
            -- Mô tả: Ô nhập lệnh bí mật và nút LOAD ở đáy cột hỗ trợ
            -- =========================================================================
            local secretInputGo = GameObject("SecretCommandsInput")
            secretInputGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, secretInputGo)

            local secretInputRt = secretInputGo:AddComponent(typeof(RectTransform))
            secretInputRt.anchorMin, secretInputRt.anchorMax, secretInputRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            secretInputRt.anchoredPosition = Vector2(rightColX2, currentY)
            secretInputRt.sizeDelta = Vector2(245, 34)

            local secretBg = GameObject("Bg")
            secretBg.transform:SetParent(secretInputGo.transform, false)
            local secretBgRt = secretBg:AddComponent(typeof(RectTransform))
            secretBgRt.anchorMin, secretBgRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            secretBgRt.sizeDelta = Vector2(0, 0)
            local secretBgImg = secretBg:AddComponent(typeof(Image))
            secretBgImg.color = Color(0.12, 0.12, 0.15, 0.95)

            local sTxtGo = GameObject("Text")
            sTxtGo.transform:SetParent(secretInputGo.transform, false)
            local sTxtRt = sTxtGo:AddComponent(typeof(RectTransform))
            sTxtRt.anchorMin, sTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            sTxtRt.offsetMin, sTxtRt.offsetMax = Vector2(8, 0), Vector2(-8, 0)
            local sTxt = sTxtGo:AddComponent(typeof(Text))
            sTxt.raycastTarget = false
            sTxt.color = Color.white
            sTxt.fontSize = 14
            sTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then sTxt.font = defaultFont end

            local phGo = GameObject("Placeholder")
            phGo.transform:SetParent(secretInputGo.transform, false)
            local phRt = phGo:AddComponent(typeof(RectTransform))
            phRt.anchorMin, phRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            phRt.offsetMin, phRt.offsetMax = Vector2(8, 0), Vector2(-8, 0)
            local phTxt = phGo:AddComponent(typeof(Text))
            phTxt.raycastTarget = false
            phTxt.text = "Nhập lệnh bí mật..."
            phTxt.fontSize = 14
            phTxt.fontStyle = CS.UnityEngine.FontStyle.Italic
            phTxt.color = Color(0.5, 0.5, 0.5, 0.6)
            phTxt.alignment = TextAnchor.MiddleLeft
            if defaultFont then phTxt.font = defaultFont end

            local secretField = secretInputGo:AddComponent(typeof(CS.UnityEngine.UI.InputField))
            secretField.textComponent = sTxt
            secretField.placeholder = phTxt
            secretField.text = _G.Mod_SecretCommands or ""

            -- Nút [LOAD]
            local loadBtnGo = GameObject("SecretCommandsLoadBtn")
            loadBtnGo.transform:SetParent(panelGo.transform, false)
            table.insert(_G.NangCaoUIList, loadBtnGo)

            local loadBtnRt = loadBtnGo:AddComponent(typeof(RectTransform))
            loadBtnRt.anchorMin, loadBtnRt.anchorMax, loadBtnRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
            loadBtnRt.anchoredPosition = Vector2(rightColX2 + 255, currentY)
            loadBtnRt.sizeDelta = Vector2(75, 34)

            local loadBtnImg = loadBtnGo:AddComponent(typeof(Image))
            loadBtnImg.color = Color(0.15, 0.45, 0.65, 1)

            local loadTxtGo = GameObject("Text")
            loadTxtGo.transform:SetParent(loadBtnGo.transform, false)
            local loadTxtRt = loadTxtGo:AddComponent(typeof(RectTransform))
            loadTxtRt.anchorMin, loadTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
            loadTxtRt.sizeDelta = Vector2(0, 0)
            local loadTxt = loadTxtGo:AddComponent(typeof(Text))
            loadTxt.raycastTarget = false
            loadTxt.text = "LOAD"
            loadTxt.fontSize = 15
            loadTxt.fontStyle = CS.UnityEngine.FontStyle.Bold
            loadTxt.color = Color.white
            loadTxt.alignment = TextAnchor.MiddleCenter
            if defaultFont then loadTxt.font = defaultFont end

            local loadBtn = loadBtnGo:AddComponent(typeof(Button))
            loadBtn.onClick:AddListener(function()
                local val = secretField.text or ""
                _G.Mod_SecretCommands = val
                pcall(function()
                    CS.UnityEngine.PlayerPrefs.SetString("Mod_SecretCommands", val)
                    CS.UnityEngine.PlayerPrefs.Save()
                end)
                if _G.Mod_ParseSecretCommands then
                    _G.Mod_ParseSecretCommands(val)
                end
                if _G.FloatingWordUtility then
                    _G.FloatingWordUtility.QuickMsg("Đã lưu lệnh bí mật! Vui lòng khởi động lại game để cập nhật menu.")
                end
            end)
        end
        CreateAutoBossUI()
        CreateKundunUI()

        -- Main Tab Buttons
        local width = 220

        local tabCoBanGo = GameObject("TabCoBanBtn")
        _G.tabCoBanGo = tabCoBanGo
        tabCoBanGo.transform:SetParent(panelGo.transform, false)
        local tabCoBanRt = tabCoBanGo:AddComponent(typeof(RectTransform))
        tabCoBanRt.anchorMin, tabCoBanRt.anchorMax, tabCoBanRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
        tabCoBanRt.anchoredPosition = Vector2(10, -10)
        tabCoBanRt.sizeDelta = Vector2(width, 40)
        local tabCoBanImg = tabCoBanGo:AddComponent(typeof(Image))

        local tabCoBanTxtGo = GameObject("Text")
        tabCoBanTxtGo.transform:SetParent(tabCoBanGo.transform, false)
        local tabCoBanTxtRt = tabCoBanTxtGo:AddComponent(typeof(RectTransform))
        tabCoBanTxtRt.anchorMin, tabCoBanTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
        tabCoBanTxtRt.sizeDelta = Vector2(0, 0)
        local tabCoBanTxt = tabCoBanTxtGo:AddComponent(typeof(Text))
        tabCoBanTxt.raycastTarget, tabCoBanTxt.fontSize, tabCoBanTxt.alignment = false, 20, TextAnchor.MiddleCenter
        if defaultFont then tabCoBanTxt.font = defaultFont end
        local tabCoBanBtn = tabCoBanGo:AddComponent(typeof(Button))

        local tabNangCaoGo = GameObject("TabNangCaoBtn")
        _G.tabNangCaoGo = tabNangCaoGo
        tabNangCaoGo.transform:SetParent(panelGo.transform, false)
        local tabNangCaoRt = tabNangCaoGo:AddComponent(typeof(RectTransform))
        tabNangCaoRt.anchorMin, tabNangCaoRt.anchorMax, tabNangCaoRt.pivot = Vector2(0, 1), Vector2(0, 1), Vector2(0, 1)
        tabNangCaoRt.anchoredPosition = Vector2(10 + width + 10, -10)
        tabNangCaoRt.sizeDelta = Vector2(width, 40)
        local tabNangCaoImg = tabNangCaoGo:AddComponent(typeof(Image))

        local tabNangCaoTxtGo = GameObject("Text")
        tabNangCaoTxtGo.transform:SetParent(tabNangCaoGo.transform, false)
        local tabNangCaoTxtRt = tabNangCaoTxtGo:AddComponent(typeof(RectTransform))
        tabNangCaoTxtRt.anchorMin, tabNangCaoTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
        tabNangCaoTxtRt.sizeDelta = Vector2(0, 0)
        local tabNangCaoTxt = tabNangCaoTxtGo:AddComponent(typeof(Text))
        tabNangCaoTxt.raycastTarget, tabNangCaoTxt.fontSize, tabNangCaoTxt.alignment = false, 20, TextAnchor
            .MiddleCenter
        if defaultFont then tabNangCaoTxt.font = defaultFont end
        local tabNangCaoBtn = tabNangCaoGo:AddComponent(typeof(Button))

        local tabAutoBossGo = GameObject("TabAutoBossBtn")
        _G.tabAutoBossGo = tabAutoBossGo
        tabAutoBossGo.transform:SetParent(panelGo.transform, false)
        local tabAutoBossRt = tabAutoBossGo:AddComponent(typeof(RectTransform))
        tabAutoBossRt.anchorMin, tabAutoBossRt.anchorMax, tabAutoBossRt.pivot = Vector2(0, 1), Vector2(0, 1),
            Vector2(0, 1)
        tabAutoBossRt.anchoredPosition = Vector2(10 + (width + 10) * 2, -10)
        tabAutoBossRt.sizeDelta = Vector2(width, 40)
        local tabAutoBossImg = tabAutoBossGo:AddComponent(typeof(Image))

        local tabAutoBossTxtGo = GameObject("Text")
        tabAutoBossTxtGo.transform:SetParent(tabAutoBossGo.transform, false)
        local tabAutoBossTxtRt = tabAutoBossTxtGo:AddComponent(typeof(RectTransform))
        tabAutoBossTxtRt.anchorMin, tabAutoBossTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
        tabAutoBossTxtRt.sizeDelta = Vector2(0, 0)
        local tabAutoBossTxt = tabAutoBossTxtGo:AddComponent(typeof(Text))
        tabAutoBossTxt.raycastTarget, tabAutoBossTxt.fontSize, tabAutoBossTxt.alignment = false, 20,
            TextAnchor.MiddleCenter
        if defaultFont then tabAutoBossTxt.font = defaultFont end
        local tabAutoBossBtn = tabAutoBossGo:AddComponent(typeof(Button))

        local function UpdateTabColors()
            tabCoBanImg.color = Color(0.2, 0.2, 0.2, 1)
            tabNangCaoImg.color = Color(0.2, 0.2, 0.2, 1)
            tabAutoBossImg.color = Color(0.2, 0.2, 0.2, 1)

            tabCoBanTxt.color = Color(0.6, 0.6, 0.6, 1)
            tabNangCaoTxt.color = Color(0.6, 0.6, 0.6, 1)
            tabAutoBossTxt.color = Color(0.6, 0.6, 0.6, 1)

            tabCoBanTxt.text = "CƠ BẢN"
            tabNangCaoTxt.text = "NÂNG CAO"
            tabAutoBossTxt.text = "AUTO BOSS"

            if _G.ModMainTab == "CO_BAN" then
                tabCoBanImg.color = Color(0.2, 0.6, 0.2, 1)
                tabCoBanTxt.color = Color.white
                tabCoBanTxt.text = "[ CƠ BẢN ]"
            elseif _G.ModMainTab == "NANG_CAO" then
                tabNangCaoImg.color = Color(0.2, 0.6, 0.2, 1)
                tabNangCaoTxt.color = Color.white
                tabNangCaoTxt.text = "[ NÂNG CAO ]"
            elseif _G.ModMainTab == "AUTO_BOSS" then
                tabAutoBossImg.color = Color(0.2, 0.6, 0.2, 1)
                tabAutoBossTxt.color = Color.white
                tabAutoBossTxt.text = "[ AUTO BOSS ]"
            end
        end
        UpdateTabColors()

        tabCoBanBtn.onClick:AddListener(function()
            _G.ModMainTab = "CO_BAN"
            pcall(function() CS.UnityEngine.PlayerPrefs.SetString("ModMainTab", _G.ModMainTab) end)
            UpdateTabColors()
            RefreshMainTabs()
        end)
        tabNangCaoBtn.onClick:AddListener(function()
            _G.ModMainTab = "NANG_CAO"
            pcall(function() CS.UnityEngine.PlayerPrefs.SetString("ModMainTab", _G.ModMainTab) end)
            UpdateTabColors()
            RefreshMainTabs()
        end)

        tabAutoBossBtn.onClick:AddListener(function()
            _G.ModMainTab = "AUTO_BOSS"
            pcall(function() CS.UnityEngine.PlayerPrefs.SetString("ModMainTab", _G.ModMainTab) end)
            UpdateTabColors()
            RefreshMainTabs()
        end)


        -- Watermark
        local watermarkGo = GameObject("WatermarkText")
        watermarkGo.transform:SetParent(panelGo.transform, false)
        table.insert(_G.CoBanUIList, watermarkGo)
        local wmRt = watermarkGo:AddComponent(typeof(RectTransform))
        wmRt.anchorMin = Vector2(1, 0)
        wmRt.anchorMax = Vector2(1, 0)
        wmRt.pivot = Vector2(1, 0)
        wmRt.anchoredPosition = Vector2(-20, 10)
        wmRt.sizeDelta = Vector2(200, 30)
        local wmTxt = watermarkGo:AddComponent(typeof(Text))
        wmTxt.raycastTarget = false
        wmTxt.text = "<i>Modded by VỤT Team</i>"
        wmTxt.color = Color(0.215, 0.490, 0.133, 1.0)
        wmTxt.fontSize = 16
        wmTxt.alignment = TextAnchor.LowerRight
        if defaultFont then wmTxt.font = defaultFont end

        -- =========================================================================
        -- [MOD FEATURE]: NÚT ZOOM DỌC BÁM MÉP PHẢI PANEL (TAB CƠ BẢN)
        -- Mô tả: Thu phóng kích thước menu theo chu kỳ: x1.0 -> x1.2 -> x1.5 -> x1.0
        -- =========================================================================
        local zoomBtnGo = GameObject("ZoomVerticalBtn")
        zoomBtnGo.transform:SetParent(panelGo.transform, false)
        table.insert(_G.CoBanUIList, zoomBtnGo)

        local zoomRt = zoomBtnGo:AddComponent(typeof(RectTransform))
        zoomRt.anchorMin, zoomRt.anchorMax, zoomRt.pivot = Vector2(1, 0.5), Vector2(1, 0.5), Vector2(1, 0.5)
        zoomRt.anchoredPosition = Vector2(0, 0)
        zoomRt.sizeDelta = Vector2(28, 120)

        local zoomImg = zoomBtnGo:AddComponent(typeof(Image))

        local zoomTxtGo = GameObject("Text")
        zoomTxtGo.transform:SetParent(zoomBtnGo.transform, false)
        local zoomTxtRt = zoomTxtGo:AddComponent(typeof(RectTransform))
        zoomTxtRt.anchorMin, zoomTxtRt.anchorMax = Vector2(0, 0), Vector2(1, 1)
        zoomTxtRt.sizeDelta = Vector2(0, 0)
        local zoomTxt = zoomTxtGo:AddComponent(typeof(Text))
        zoomTxt.raycastTarget = false
        zoomTxt.fontSize = 12
        zoomTxt.alignment = TextAnchor.MiddleCenter
        if defaultFont then zoomTxt.font = defaultFont end

        local function UpdateZoomVisuals()
            local cur = _G.Mod_MenuScale or 1.0
            if math.abs(cur - 1.2) < 0.05 then
                zoomImg.color = Color(0.15, 0.45, 0.65, 0.95)
                zoomTxt.text = "Z\nO\nO\nM\n\n1.2"
                zoomTxt.color = Color(1, 1, 1, 1)
            elseif math.abs(cur - 1.5) < 0.05 then
                zoomImg.color = Color(0.75, 0.45, 0.1, 0.95)
                zoomTxt.text = "Z\nO\nO\nM\n\n1.5"
                zoomTxt.color = Color(1, 1, 1, 1)
            else
                zoomImg.color = Color(0.2, 0.2, 0.2, 0.9)
                zoomTxt.text = "Z\nO\nO\nM\n\n1.0"
                zoomTxt.color = Color(0.8, 0.8, 0.8, 1)
            end
            panelGo.transform.localScale = CS.UnityEngine.Vector3(cur, cur, 1)
        end
        UpdateZoomVisuals()

        local zoomBtn = zoomBtnGo:AddComponent(typeof(Button))
        zoomBtn.onClick:AddListener(function()
            local cur = _G.Mod_MenuScale or 1.0
            local nextScale = 1.0
            if math.abs(cur - 1.0) < 0.05 then
                nextScale = 1.2
            elseif math.abs(cur - 1.2) < 0.05 then
                nextScale = 1.5
            else
                nextScale = 1.0
            end
            _G.Mod_MenuScale = nextScale
            pcall(function()
                CS.UnityEngine.PlayerPrefs.SetFloat("Mod_MenuScale", nextScale)
                CS.UnityEngine.PlayerPrefs.Save()
            end)
            UpdateZoomVisuals()
        end)
        zoomBtnGo:SetActive(_G.ModMainTab == "CO_BAN")
        zoomBtnGo.transform:SetAsLastSibling()

        -- Auto-Loot DropItem Hook
        _G.LastPickupTime = _G.LastPickupTime or 0
        _G.Mod_AllDropItems = _G.Mod_AllDropItems or {}
        _G.Mod_PickedItems = _G.Mod_PickedItems or {}

        if _G.PickupManager then
            local original_RemoveDropSceneCellPos = _G.PickupManager.RemoveDropSceneCellPos
            _G.PickupManager.RemoveDropSceneCellPos = function(dropItemData)
                if original_RemoveDropSceneCellPos then
                    original_RemoveDropSceneCellPos(dropItemData)
                end
                local dId = dropItemData and (dropItemData.id or (dropItemData.data and dropItemData.data.id) or (dropItemData.item and dropItemData.item.id))
                if dId then
                    if _G.Mod_ActiveSpamItems then
                        _G.Mod_ActiveSpamItems[dId] = nil
                    end
                end
            end

            local original_AddDropSceneCellPos = _G.PickupManager.AddDropSceneCellPos
            _G.PickupManager.AddDropSceneCellPos = function(item)
                original_AddDropSceneCellPos(item)

                if not (item and item.data) then return end
                local dropItemData = item.data

                -- 1. HÚT ĐỒ BATCH LOOT TỨC THÌ NGAY KHI RỚI KHỎI RƯƠNG VÀNG
                if _G.Mod_AutoOpenGoldenChest_Enabled and (_G.Mod_Config_ActiveAutoFarmTab ~= false) then
                    pcall(function()
                        local objId = dropItemData.id or dropItemData.objId or (dropItemData.item and dropItemData.item.id)
                        if objId then
                            _G.Mod_GoldenChestBatchIds = _G.Mod_GoldenChestBatchIds or {}
                            table.insert(_G.Mod_GoldenChestBatchIds, objId)

                            if _G.PickupManager and _G.PickupManager.ReqPickUpMapItems then
                                _G.PickupManager.ReqPickUpMapItems(_G.Mod_GoldenChestBatchIds)
                            elseif _G.networkRequest and _G.networkRequest.ReqPickUpMapItems then
                                _G.networkRequest.ReqPickUpMapItems(_G.Mod_GoldenChestBatchIds)
                            end
                        end
                    end)
                    return
                end

                if _G.Mod_AutoPick_KTD then
                    local mapId = 0
                    if _G.SceneData and _G.SceneData.mapId then
                        mapId = _G.SceneData.mapId
                    elseif _G.RoleManager and _G.RoleManager.me and _G.RoleManager.me.mapId then
                        mapId = _G.RoleManager.me.mapId
                    end

                    if mapId == 1077 then
                        local objId = dropItemData.id or (dropItemData.item and dropItemData.item.id)
                        if objId then
                            _G.Mod_PickedItems = _G.Mod_PickedItems or {}
                            if not _G.Mod_PickedItems[objId] then
                                _G.Mod_PickedItems[objId] = true
                                if _G.PickupManager then
                                    _G.PickupManager.ReqPickUpMapItem(objId)
                                end

                                if _G.WriteLog then
                                    _G.WriteLog(string.format("[KTĐ] Phát hiện & Tự Nhặt (1 lần)! InstanceId=%s, ConfigId=%s, Type=%s",
                                        tostring(objId), tostring(dropItemData.configId), tostring(dropItemData.type)))
                                end
                            end
                        end
                    end
                end

                if _G.AutoPick_Enabled then
                    local eType = dropItemData.type
                    local isRune = (eType == 19 or eType == 28)
                    local isBone = (eType == 24 or eType == 26)

                    local shouldPick = (isRune or isBone)

                    -- if shouldPick then
                    --     if _G.PickupManager and _G.PickupManager.IsCanPickUpDropItem then
                    --         if not _G.PickupManager.IsCanPickUpDropItem(dropItemData) then
                    --             shouldPick = false
                    --         end
                    --     end
                    -- end

                    if shouldPick then
                        local isAlreadyPicked = _G.Mod_PickedItems[dropItemData.id]
                        if not isAlreadyPicked and ((_G.AutoPick_Count or 0) < _G.AutoPick_Limit) then
                            _G.Mod_PickedItems[dropItemData.id] = true
                            _G.AutoPick_Count = (_G.AutoPick_Count or 0) + 1

                            local lootCount = _G.Mod_IsDev and 3 or 2
                            local delayTime = _G.Mod_IsDev and 0.05 or 0.2
                            local minPDelay = _G.Mod_Config_PickupDelay_Min or 300
                            local maxPDelay = _G.Mod_Config_PickupDelay_Max or 2000
                            if minPDelay > maxPDelay then minPDelay, maxPDelay = maxPDelay, minPDelay end
                            local initialDelay = math.random(minPDelay, maxPDelay) / 1000

                            local function ExecutePickup()
                                if _G.Timer and _G.Timer.StartLoop then
                                    _G.Timer.StartLoop(delayTime, lootCount, function()
                                        if _G.PickupManager then _G.PickupManager.ReqPickUpMapItem(dropItemData.id) end
                                    end)
                                else
                                    _G.PickupManager.ReqPickUpMapItem(dropItemData.id)
                                end

                                -- Đưa vào hàng đợi duy trì spam bồi liên tục cho tới khi nhặt xong (tối đa 4 giây)
                                _G.Mod_ActiveSpamItems = _G.Mod_ActiveSpamItems or {}
                                _G.Mod_ActiveSpamItems[dropItemData.id] = {
                                    id = dropItemData.id,
                                    x = dropItemData.x,
                                    y = dropItemData.y,
                                    expireTime = CS.UnityEngine.Time.realtimeSinceStartup + 7.0
                                }

                                local itemId = dropItemData.item and dropItemData.item.itemId or "???"
                                if _G.WriteLog then
                                    _G.WriteLog("[AutoLoot] Nhặt (Tức thì & Spam bồi): Item [ID: " .. tostring(itemId) .. "]")
                                end
                                if _G.RoleManager and _G.RoleManager.me and dropItemData.x and dropItemData.y then
                                    pcall(function()
                                        if _G.WriteLog then
                                            _G.WriteLog(string.format(
                                                "[AutoLoot] (Tức thì) MoveTo ItemId=%s, X=%s, Y=%s", tostring(itemId),
                                                tostring(dropItemData.x), tostring(dropItemData.y)))
                                        end
                                        _G.RoleManager.me:MoveTo({ x = dropItemData.x, y = dropItemData.y })
                                    end)
                                end
                            end

                            if initialDelay > 0 and _G.Timer and _G.Timer.StartLoop then
                                local hasFired = false
                                _G.Timer.StartLoop(initialDelay, 1, function()
                                    if not hasFired then
                                        hasFired = true
                                        ExecutePickup()
                                    end
                                end)
                            else
                                ExecutePickup()
                            end
                        end
                    end
                end
            end
        end

        if _G.ConditionalMgr then
            local original_CanAutoPickUpDropItem = _G.ConditionalMgr.CanAutoPickUpDropItem
            _G.ConditionalMgr.CanAutoPickUpDropItem = function(self, itemInfo)
                local isGoldenChest = _G.Mod_AutoOpenGoldenChest_Enabled and (_G.Mod_Config_ActiveAutoFarmTab ~= false)
                if _G.AutoPick_Enabled or isGoldenChest then
                    return false
                end
                return original_CanAutoPickUpDropItem(self, itemInfo)
            end

            local original_CanPickUpDropItem = _G.ConditionalMgr.CanPickUpDropItem
            _G.ConditionalMgr.CanPickUpDropItem = function(self, itemInfo)
                local isGoldenChest = _G.Mod_AutoOpenGoldenChest_Enabled and (_G.Mod_Config_ActiveAutoFarmTab ~= false)
                if _G.AutoPick_Enabled or isGoldenChest then
                    return false
                end
                return original_CanPickUpDropItem(self, itemInfo)
            end
        end

        if _G.PickupItemNode and not _G.Mod_HookedPickupNode then
            _G.Mod_HookedPickupNode = true
            local orig_Visit = _G.PickupItemNode.Visit
            _G.PickupItemNode.Visit = function(self)
                local isActive = (_G.Mod_IsActive == true) or (type(_G.Mod_IsActive) == "function" and _G.Mod_IsActive())
                if not isActive then
                    if orig_Visit then return orig_Visit(self) end
                end
                if _G.Mod_AutoOpenGoldenChest_Enabled and (_G.Mod_Config_ActiveAutoFarmTab ~= false) then
                    self.status = (_G.BehaviorStatusEnum and _G.BehaviorStatusEnum.FAILED) or 3
                    return
                end
                if orig_Visit then return orig_Visit(self) end
            end
        end
        _G.ModCallbacks.OnToggleMenu = function()
            local ok, err = pcall(function()
                local mainPanel = _G.ModMenuPanelGo or panelGo
                local authPanel = _G.authPanelGo or authPanelGo

                if _G.Mod_HasFetchedConfig then
                    local isValid = false
                    if _G.Mod_IsActive and _G.Mod_ActiveConfig then
                        local valid, reason = Mod_ValidateConfig(_G.Mod_ActiveConfig)
                        if valid then
                            isValid = true
                        else
                            _G.Mod_IsActive = false
                            _G.Mod_ActiveStatusMsg = reason
                        end
                    end

                    if isValid then
                        if authPanel and not authPanel:Equals(nil) then authPanel:SetActive(false) end
                        if mainPanel and not mainPanel:Equals(nil) then
                            isExpanded = not isExpanded
                            mainPanel:SetActive(isExpanded)
                            if isExpanded and _G.RefreshMainTabs then _G.RefreshMainTabs() end
                        end
                    else
                        if mainPanel and not mainPanel:Equals(nil) then mainPanel:SetActive(false) end
                        if authPanel and not authPanel:Equals(nil) then
                            local showAuth = not authPanel.activeSelf
                            authPanel:SetActive(showAuth)
                            if showAuth and _G.Mod_RefreshAuthPanelData then _G.Mod_RefreshAuthPanelData() end
                        end
                    end
                else
                    if _G.FloatingWordUtility then
                        _G.FloatingWordUtility.QuickMsg(
                            "Đang kết nối lấy thông tin kích hoạt...")
                    end
                    _G.Mod_CheckActiveConfigNow(function(isSuccess, isActive, msg)
                        if isActive == true and _G.Mod_IsActive == true then
                            if authPanel and not authPanel:Equals(nil) then authPanel:SetActive(false) end
                            if mainPanel and not mainPanel:Equals(nil) then
                                isExpanded = true
                                mainPanel:SetActive(true)
                                if _G.RefreshMainTabs then _G.RefreshMainTabs() end
                            end
                        else
                            if mainPanel and not mainPanel:Equals(nil) then mainPanel:SetActive(false) end
                            if authPanel and not authPanel:Equals(nil) then
                                authPanel:SetActive(true)
                                if _G.Mod_RefreshAuthPanelData then _G.Mod_RefreshAuthPanelData() end
                            end
                        end
                    end)
                end
            end)
            if not ok then
                if _G.FloatingWordUtility then _G.FloatingWordUtility.QuickMsg("Lỗi Toggle Menu: " .. tostring(err)) end
            end
        end
        if btnComp and not btnComp:Equals(nil) then
            btnComp.onClick:RemoveAllListeners()
            btnComp.onClick:AddListener(_G.ModCallbacks.OnToggleMenu)
        end

        -- =========================================================================
        -- [MOD FEATURE]: TỐI ƯU ĐỒ HỌA & TẮT HIỆU ỨNG (DISABLE VISUALS & FPS BOOST)
        -- Mô tả: Tắt hiển thị Skill diện rộng, Thú cưỡi, Hồn hoàn, Footprint để giảm tải GPU/CPU.
        -- Khắc phục: Giữ nguyên Buff 3vs3, Rune bản đồ, Cổng dịch chuyển, Vòng bo và chống lag cache hồi sinh skill cũ.
        -- =========================================================================
        if not _G.Mod_HookedDisableVisuals then
            _G.Mod_HookedDisableVisuals = true

            -- Hàm nhận diện hiệu ứng quan trọng của bản đồ / chiến trường 3vs3 / Rune / Cổng / Vòng bo (Không được ẩn)
            local function IsEssentialSceneEffect(data)
                if not data then return false end
                local tbl = data.EffectTbl
                if not tbl and data.effectId and _G.ClientTable and _G.ClientTable.cfg_EffectsManager then
                    tbl = _G.ClientTable.cfg_EffectsManager:TryGetValue(data.effectId)
                end
                if tbl then
                    -- 1. Game config closeEffect == 0 (Quy ước chuẩn của game: 0 = Hiệu ứng bản đồ/buff/cổng/rune không đóng, 1 = Skill/thú cưỡi)
                    if tbl.closeEffect == 0 then
                        return true
                    end
                    -- 2. Tên prefab/hiệu ứng là buff 3vs3, cảnh quan, cờ chiến, vòng bo, cổng hồi sinh
                    local name = tbl.name or ""
                    local nameLower = string.lower(name)
                    if string.find(nameLower, "eff_buff_") or 
                       string.find(nameLower, "eff_changjing_") or 
                       string.find(nameLower, "eff_zhanqi") or 
                       string.find(nameLower, "zaishengmen") or 
                       string.find(nameLower, "chuansongmen") or 
                       string.find(nameLower, "duquan") or 
                       string.find(nameLower, "menzhu") then
                        return true
                    end
                end
                return false
            end

            -- 1. SceneEffectProcessor & SceneEffectObj
            local sep = (_G.LuaClass and _G.LuaClass.SceneEffectProcessor) or _G.SceneEffectProcessor
            if sep then
                local orig_InstantiationEffect = sep.InstantiationEffect
                sep.InstantiationEffect = function(self, data)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        if not IsEssentialSceneEffect(data) then
                            return
                        end
                    end
                    if orig_InstantiationEffect then
                        orig_InstantiationEffect(self, data)
                    end
                end
            end

            local seo = (_G.LuaClass and _G.LuaClass.SceneEffectObj) or _G.SceneEffectObj
            if seo then
                local orig_RefreshModel = seo.RefreshModel
                seo.RefreshModel = function(self, data, rootObj)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        if not IsEssentialSceneEffect(data) then
                            return
                        end
                    end
                    if orig_RefreshModel then
                        orig_RefreshModel(self, data, rootObj)
                    end
                end
            end

            -- 2. BaseSkill
            if _G.BaseSkill then
                local orig_IsEffectShow = _G.BaseSkill.IsEffectShow
                _G.BaseSkill.IsEffectShow = function(skillData_struct)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return false
                    end
                    if orig_IsEffectShow then
                        return orig_IsEffectShow(skillData_struct)
                    end
                    return true
                end
            end

            -- 3. BulletMgr
            if _G.BulletMgr then
                local orig_AddBullet = _G.BulletMgr.AddBullet
                _G.BulletMgr.AddBullet = function(skillData_struct, bulletData)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_AddBullet then
                        orig_AddBullet(skillData_struct, bulletData)
                    end
                end

                local orig_LoadEffect = _G.BulletMgr.LoadEffect
                _G.BulletMgr.LoadEffect = function(bulletData_struct)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return nil
                    end
                    if orig_LoadEffect then
                        return orig_LoadEffect(bulletData_struct)
                    end
                end

                local orig_SetPosScale = _G.BulletMgr.SetSkillEffectPosAndScale
                _G.BulletMgr.SetSkillEffectPosAndScale = function(bulletData_struct, skillEffect)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_SetPosScale then
                        orig_SetPosScale(bulletData_struct, skillEffect)
                    end
                end
            end

            -- 4. HitEffectMgr
            if _G.HitEffectMgr then
                local orig_AddHitEffect = _G.HitEffectMgr.AddEffect
                _G.HitEffectMgr.AddEffect = function(hit_struct, role)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_AddHitEffect then
                        orig_AddHitEffect(hit_struct, role)
                    end
                end

                local orig_AddHitByPos = _G.HitEffectMgr.AddEffectByPos
                _G.HitEffectMgr.AddEffectByPos = function(hit_struct, targetPos)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_AddHitByPos then
                        orig_AddHitByPos(hit_struct, targetPos)
                    end
                end

                local orig_LoadHitEffect = _G.HitEffectMgr.LoadEffect
                _G.HitEffectMgr.LoadEffect = function(effectData_struct)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return nil
                    end
                    if orig_LoadHitEffect then
                        orig_LoadHitEffect(effectData_struct)
                    end
                end
            end

            -- 5. Action_RandomRangeEffect
            if _G.Action_RandomRangeEffect then
                local orig_RandomRangeInit = _G.Action_RandomRangeEffect.Init
                _G.Action_RandomRangeEffect.Init = function(self, caster, actionData, speed, attackerPos, targetPos)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_RandomRangeInit then
                        orig_RandomRangeInit(self, caster, actionData, speed, attackerPos, targetPos)
                    end
                end
            end

            -- 6. SkillEffectMgr
            if _G.SkillEffectMgr then
                local orig_AddEffect = _G.SkillEffectMgr.AddEffect
                _G.SkillEffectMgr.AddEffect = function(effectData, skillData_struct, index)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_AddEffect then
                        orig_AddEffect(effectData, skillData_struct, index)
                    end
                end

                local orig_AddUIEffect = _G.SkillEffectMgr.AddUIEffect
                _G.SkillEffectMgr.AddUIEffect = function(effectData, skillData_struct, index)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_AddUIEffect then
                        orig_AddUIEffect(effectData, skillData_struct, index)
                    end
                end
            end

            -- 7. Action_HitEffect
            if _G.Action_HitEffect then
                local orig_PlayEffect = _G.Action_HitEffect.PlayEffect
                _G.Action_HitEffect.PlayEffect = function(self)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_PlayEffect then
                        orig_PlayEffect(self)
                    end
                end
            end

            -- 8. WeaponEffectMgr
            if _G.WeaponEffectMgr then
                local orig_AddWeaponEffect = _G.WeaponEffectMgr.AddEffect
                _G.WeaponEffectMgr.AddEffect = function(attacker, weaponData, tblSkill, attackSpeed)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_AddWeaponEffect then
                        orig_AddWeaponEffect(attacker, weaponData, tblSkill, attackSpeed)
                    end
                end
            end

            -- 9. CameraEffectMgr
            if _G.CameraEffectMgr then
                local orig_CameraPlay = _G.CameraEffectMgr.Play
                _G.CameraEffectMgr.Play = function(data)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_CameraPlay then
                        orig_CameraPlay(data)
                    end
                end
            end

            -- 10. HPData.SetData
            if _G.HPData then
                local orig_SetData = _G.HPData.SetData
                _G.HPData.SetData = function(hpStruct, hurtTarget)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_SetData then
                        orig_SetData(hpStruct, hurtTarget)
                    end
                end
            end

            -- 11. Player.HurtMaterialEffect & Action_ApplySkillEffect.PerfermHurt
            if _G.Player then
                local orig_HurtMat = _G.Player.HurtMaterialEffect
                _G.Player.HurtMaterialEffect = function(self, attackerId)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        return
                    end
                    if orig_HurtMat then
                        orig_HurtMat(self, attackerId)
                    end
                end
            end

            if _G.Action_ApplySkillEffect then
                local orig_PerfermHurt = _G.Action_ApplySkillEffect.PerfermHurt
                _G.Action_ApplySkillEffect.PerfermHurt = function(self)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        pcall(function()
                            local attacker = _G.RoleManager and _G.RoleManager.GetRoleById and _G.RoleManager.GetRoleById(self.attackerId)
                            for i = 1, #(self.hurtList or {}) do
                                local hurt = self.hurtList[i]
                                local target = _G.RoleManager and _G.RoleManager.GetRoleById and _G.RoleManager.GetRoleById(hurt.targetId)
                                local myId = _G.ViewData and _G.ViewData.meData and _G.ViewData.meData.id
                                if myId and ((hurt.targetId == myId) or (self.attackerId == myId) or 
                                   (target and target.data and target.data.master == myId) or 
                                   (attacker and attacker.data and attacker.data.master == myId) or 
                                   (_G.Activity_LangHunYaoSaiData and _G.Activity_LangHunYaoSaiData.RoleIsLangHunYongBing and _G.Activity_LangHunYaoSaiData.RoleIsLangHunYongBing(hurt.targetId))) 
                                   and (hurt.isDodge or hurt.showHurt ~= 0) then
                                    local aa = -hurt.showHurt
                                    local tbl = _G.ClientTable and _G.ClientTable.cfg_Skill_skillManager and _G.ClientTable.cfg_Skill_skillManager:TryGetValue(self.skillId)
                                    if tbl and tbl.groupId == 12120200 and _G.GlobalConfig and _G.GlobalConfig.HLBRatio then
                                        aa = math.floor(aa * _G.GlobalConfig.HLBRatio)
                                    end
                                    if tbl and tbl.skillType == _G.ESkillType.Combo then
                                        if _G.HpController and _G.HpController.ChangeHPFromComboSkill then
                                            _G.HpController.ChangeHPFromComboSkill(hurt.targetId, hurt.hp, hurt, aa)
                                        end
                                    elseif _G.HpController and _G.HpController.ChangeHPFromResSkill then
                                        _G.HpController.ChangeHPFromResSkill(hurt.targetId, hurt.hp, hurt, aa)
                                    end
                                end
                            end
                        end)
                        return
                    end
                    if orig_PerfermHurt then
                        orig_PerfermHurt(self)
                    end
                end
            end

            -- 12. BuffEffectMgr
            if _G.BuffEffectMgr then
                local orig_AddBuffEffect = _G.BuffEffectMgr.AddEffect
                _G.BuffEffectMgr.AddEffect = function(buffData_struct, buffEffect)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() and buffEffect and buffEffect.prefab then
                        local pLower = string.lower(buffEffect.prefab)
                        if string.find(pLower, "hunhuan") or string.find(pLower, "guanghuan") or string.find(pLower, "foot") then
                            return
                        end
                    end
                    if orig_AddBuffEffect then
                        orig_AddBuffEffect(buffData_struct, buffEffect)
                    end
                end
            end

            -- 13. RoleEquip & Me
            if _G.RoleEquip then
                local orig_SetFoot = _G.RoleEquip.SetFoot
                _G.RoleEquip.SetFoot = function(self, position, path)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        if not _G.IsNil(self.footPrintObj) then
                            local obj = self.footPrintObj
                            self:RecycleModel(_G.EModelType.Equip, obj.name, obj)
                            self.equipPosObj[position] = nil
                            self.footPrintObj = nil
                        end
                        return
                    end
                    if orig_SetFoot then
                        orig_SetFoot(self, position, path)
                    end
                end

                local orig_SetEquipShow = _G.RoleEquip.SetEquipShowOrHideByIndex
                _G.RoleEquip.SetEquipShowOrHideByIndex = function(self, position, isShow)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() and position == _G.ERoleEquipPosition.footPrintIndex then
                        if not _G.IsNil(self.footPrintObj) then
                            self.footPrintObj:SetActive(false)
                        end
                        return
                    end
                    if orig_SetEquipShow then
                        orig_SetEquipShow(self, position, isShow)
                    end
                end
            end

            if _G.Me then
                local orig_OpenFoot = _G.Me.OpenOtherFootPrint
                _G.Me.OpenOtherFootPrint = function(self)
                    if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                        if not _G.IsNil(self.footPrintEffect) then
                            self.footPrintEffect:SetActive(false)
                        end
                        return
                    end
                    if orig_OpenFoot then
                        orig_OpenFoot(self)
                    end
                end
            end

            _G.Mod_ApplyDisableVisualsState = function()
                pcall(function()
                    local isOff = _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive()
                    
                    local sepInstance = _G.SceneEffectProcessor or (_G.LuaClass and _G.LuaClass.SceneEffectProcessor)
                    if _G.gameMgr and _G.gameMgr.GetSceneManager then
                        local sm = _G.gameMgr:GetSceneManager()
                        if sm and sm.GetSceneEffectProcessor then
                            sepInstance = sm:GetSceneEffectProcessor()
                        end
                    end

                    if sepInstance and sepInstance.EffectObjList then
                        for _, obj in pairs(sepInstance.EffectObjList) do
                            if obj and obj.ControlShowState then
                                if isOff then
                                    if not IsEssentialSceneEffect(obj.EffectData) then
                                        obj:ControlShowState(false)
                                    else
                                        obj:ControlShowState(true)
                                    end
                                else
                                    obj:ControlShowState(true)
                                end
                            end
                        end
                    end

                    if isOff then
                        if _G.SkillMgr and _G.SkillMgr.ROOT then
                            local root = _G.SkillMgr.ROOT
                            for i = 0, root.childCount - 1 do
                                local child = root:GetChild(i)
                                if child and child.gameObject and not _G.IsNil(child.gameObject) and child.gameObject.activeSelf then
                                    child.gameObject:SetActive(false)
                                end
                            end
                        end
                    end

                    if _G.BuffEffectMgr and _G.BuffEffectMgr.m_Effects then
                        for _, eff in pairs(_G.BuffEffectMgr.m_Effects) do
                            if eff and eff.prefab then
                                local pLower = string.lower(eff.prefab)
                                if string.find(pLower, "hunhuan") or string.find(pLower, "guanghuan") or string.find(pLower, "foot") then
                                    if eff.buffEffect and not _G.IsNil(eff.buffEffect) then
                                        eff.buffEffect:SetActive(not isOff)
                                    end
                                end
                            end
                        end
                    end

                    if _G.RoleManager and _G.RoleManager.me then
                        local me = _G.RoleManager.me
                        if me.footPrintEffect and not _G.IsNil(me.footPrintEffect) then
                            me.footPrintEffect:SetActive(not isOff)
                        end
                        if me.AvatarEquip and me.AvatarEquip.footPrintObj and not _G.IsNil(me.AvatarEquip.footPrintObj) then
                            me.AvatarEquip.footPrintObj:SetActive(not isOff)
                        end
                    end

                    if _G.Mod_StartVisualMasterLoop then
                        _G.Mod_StartVisualMasterLoop()
                    end
                end)
            end

            _G.Mod_StartVisualMasterLoop = function()
                if not _G.Mod_IsActive then return end
                if _G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive() then
                    _G.Mod_StartTrackedTimer("VisualMaster", 0.5, -1, function()
                        if not _G.Mod_IsActive or not (_G.Mod_IsDisableVisualsActive and _G.Mod_IsDisableVisualsActive()) then
                            _G.Mod_StopTimer("VisualMaster")
                            return
                        end

                        if _G.SkillMgr and _G.SkillMgr.ROOT then
                            local root = _G.SkillMgr.ROOT
                            for i = 0, root.childCount - 1 do
                                local child = root:GetChild(i)
                                if child and child.gameObject and not _G.IsNil(child.gameObject) and child.gameObject.activeSelf then
                                    child.gameObject:SetActive(false)
                                end
                            end
                        end

                        if _G.RoleManager and _G.RoleManager.me then
                            local me = _G.RoleManager.me
                            if me.footPrintEffect and not _G.IsNil(me.footPrintEffect) and me.footPrintEffect.activeSelf then
                                me.footPrintEffect:SetActive(false)
                            end
                            if me.AvatarEquip and me.AvatarEquip.footPrintObj and not _G.IsNil(me.AvatarEquip.footPrintObj) and me.AvatarEquip.footPrintObj.activeSelf then
                                me.AvatarEquip.footPrintObj:SetActive(false)
                            end
                        end
                    end)
                else
                    _G.Mod_StopTimer("VisualMaster")
                end
            end

            if _G.Mod_ApplyDisableVisualsState then
                _G.Mod_ApplyDisableVisualsState()
            end
        end

        -- WriteLog("Khởi tạo Mod Menu HOÀN TẤT!")
    end)
    if not status then
        WriteLog("LỖI TẠO UI: " .. tostring(err))
    end
end

if _G.RoleManager and not _G.Mod_HookedRoleManager_Monster then
    _G.Mod_HookedRoleManager_Monster = true
    -- Removed faulty CreateMonster hook. Boss logic moved to Timer.
end

_G.Mod_BypassInstanceEnter = function(self, control, originalFunc, uiid)
    if _G.Mod_InfiniteInstance then
        if _G.TeamUpQuicklyData then
            _G.TeamUpQuicklyData.SetInstanceUI(self.name)
        end
        if _G.UIManager then _G.UIManager.Hide(uiid) end

        if _G.NetManager and _G.InstanceMatchMessage then
            local mapId = self.ContentData and self.ContentData.mapId or 0
            _G.NetManager.Send(_G.InstanceMatchMessage.ReqInstanceMatchCreateTeam, {
                instanceId = mapId
            })
        end
    else
        if originalFunc then originalFunc(self, control) end
    end
end



local status, err = pcall(function()
    if _G.UIManager and not _G.MyModHooked then
        _G.MyModHooked = true
        -- WriteLog("Hooked UIManager trực tiếp!")

        local original_Show = _G.UIManager.Show
        _G.UIManager.Show = function(name, args, animation)
            -- CHẶN UPDATE TRƯỚC KHI GỌI HÀM SHOW GỐC
            if name == "Main_MainMenuUI" then
                pcall(function()
                    -- Lời nhắc: Các hàm chặn tải dữ liệu đã được gỡ bỏ để game load được nhân vật
                end)
            end

            local ret = nil
            if original_Show then ret = original_Show(name, args, animation) end

            pcall(function()
                if name == "Instance_BloodCastleUI" then
                    if _G.Instance_BloodCastleUI and not _G.Mod_HookedBloodCastle then
                        _G.Mod_HookedBloodCastle = true
                        local original_btn_enterOnClick = _G.Instance_BloodCastleUI.btn_enterOnClick
                        _G.Instance_BloodCastleUI.btn_enterOnClick = function(self, control)
                            if _G.Mod_BypassInstanceEnter then
                                _G.Mod_BypassInstanceEnter(self, control, original_btn_enterOnClick,
                                    _G.UIID.Instance_BloodCastleUI)
                            else
                                if original_btn_enterOnClick then original_btn_enterOnClick(self, control) end
                            end
                        end
                    end
                    local inst = _G.UIManager and _G.UIManager.GetUI and
                        _G.UIManager.GetUI(_G.UIID.Instance_BloodCastleUI)
                    if inst and inst.btn_enter and inst.btn_enter.SetOnClick then
                        inst.btn_enter:SetOnClick(inst, inst.btn_enterOnClick)
                    end
                elseif name == "Instance_DemonPlazaUI" then
                    if _G.Instance_DemonPlazaUI and not _G.Mod_HookedDemonPlaza then
                        _G.Mod_HookedDemonPlaza = true
                        local original_btn_enterOnClick_DP = _G.Instance_DemonPlazaUI.btn_enterOnClick
                        _G.Instance_DemonPlazaUI.btn_enterOnClick = function(self, control)
                            if _G.Mod_BypassInstanceEnter then
                                _G.Mod_BypassInstanceEnter(self, control, original_btn_enterOnClick_DP,
                                    _G.UIID.Instance_DemonPlazaUI)
                            else
                                if original_btn_enterOnClick_DP then original_btn_enterOnClick_DP(self, control) end
                            end
                        end
                    end
                    local inst = _G.UIManager and _G.UIManager.GetUI and
                        _G.UIManager.GetUI(_G.UIID.Instance_DemonPlazaUI)
                    if inst and inst.btn_enter and inst.btn_enter.SetOnClick then
                        inst.btn_enter:SetOnClick(inst, inst.btn_enterOnClick)
                    end
                end
            end)

            if name == "Main_MainMenuUI" then
                if not _G.MyModCreated then
                    _G.MyModCreated = true
                    CreateModUI()
                else
                    if _G.Mod_UpdateFloatingButtonsVisibility then
                        _G.Mod_UpdateFloatingButtonsVisibility()
                    end
                end
            end

            return ret
        end
    else
        WriteLog("LỖI: UIManager chưa được tải! ")
    end
    -- [[ ĐÃ XÓA BỎ VÒNG LẶP AUTO FARM ẨN Ở ĐÂY ĐỂ TRÁNH CONFLICT ]]
end)
if not status then
    WriteLog("LỖI HOOK UIManager: " .. tostring(err))
end

-- ============================================================================
-- CHỨC NĂNG TỰ ĐỘNG MỞ RƯƠNG VÀNG SỐ LẺ, HÚT ĐỒ BATCH LOOT & THU HỒI ĐỒ RÁC
-- Máy Trạng Thái (State Machine Loop 0.1s): 
-- OPEN ➔ WAIT_DROP (chờ 1.0s hút đồ vào túi) ➔ RECYCLE (thu hồi) ➔ WAIT_SYNC (chờ 0.6s sync ô trống) ➔ OPEN
-- Điều kiện chạy: _G.Mod_Config_ActiveAutoFarmTab ~= false (Token cấp quyền Auto Boss)
-- ============================================================================
_G.Mod_GoldenChestState = "OPEN"
_G.Mod_GoldenChestWaitTime = 0
_G.Mod_GoldenChestBatchIds = {}

-- =========================================================================
-- [MOD FEATURE]: TỰ ĐỘNG MỞ & PHÂN LOẠI RƯƠNG VÀNG (GOLDEN CHEST AUTOMATION)
-- Mô tả: Tự động mở số lượng lớn Rương Vàng theo đợt và tự nấu trang bị rác.
-- =========================================================================
_G.Mod_ExecuteGoldenChestAutoProcess = function()
    _G.Mod_GoldenChestState = "OPEN"
    _G.Mod_GoldenChestWaitTime = 0
    _G.Mod_GoldenChestBatchIds = {}
end

_G.Mod_StartGoldenChestLoop = function()
    _G.Mod_StartTrackedTimer("GoldenChest", 0.1, -1, function()
        local isActive = (_G.Mod_IsActive == true) or (type(_G.Mod_IsActive) == "function" and _G.Mod_IsActive())
        if not isActive then return end
        if _G.Mod_Config_ActiveAutoFarmTab == false then
            _G.Mod_AutoOpenGoldenChest_Enabled = false
            _G.Mod_GoldenChestState = "OPEN"
            return
        end
        if not _G.Mod_AutoOpenGoldenChest_Enabled then
            _G.Mod_GoldenChestState = "OPEN"
            return
        end

        pcall(function()
            local nowTime = CS.UnityEngine.Time.realtimeSinceStartup

            if _G.Mod_GoldenChestState == "OPEN" then
                local items = _G.BagInfoData and _G.BagInfoData.TotalItems
                if not items and _G.BagInfoData and _G.BagInfoData.GetTotalItems then
                    pcall(function() items = _G.BagInfoData:GetTotalItems() end)
                end
                if not items then return end

                local targetChestId = nil
                local targetChestStackCount = 0
                local totalOddCount = 0

                for k, item in pairs(items) do
                    if item then
                        local tblItem = item.tblItem or (item.data and item.data.tblItem) or {}
                        local name = tblItem.name or item.name or ""
                        local itemCount = item.count or (item.data and item.data.count) or 1
                        local itemType = tblItem.type or 0

                        if itemType == 5 and string.find(name, "Rương Vàng") then
                            local tierNum = tonumber(string.match(name, "%+(%d+)"))
                            if tierNum and (tierNum % 2 ~= 0) then
                                if not targetChestId then
                                    targetChestId = item.id or (item.data and item.data.id)
                                    targetChestStackCount = itemCount
                                end
                                totalOddCount = totalOddCount + itemCount
                            end
                        end
                    end
                end

                if _G.ModUpdateGoldenChestLabel then _G.ModUpdateGoldenChestLabel() end

                if not targetChestId or totalOddCount == 0 or targetChestStackCount == 0 then
                    _G.Mod_AutoOpenGoldenChest_Enabled = false
                    if CS.UnityEngine.PlayerPrefs then
                        CS.UnityEngine.PlayerPrefs.SetInt("Mod_AutoOpenGoldenChest_Enabled", 0)
                        CS.UnityEngine.PlayerPrefs.Save()
                    end
                    if _G.ModUpdateGoldenChestLabel then _G.ModUpdateGoldenChestLabel() end
                    _G.Mod_GoldenChestState = "OPEN"
                    return
                end

                _G.Mod_GoldenChestBatchIds = {}

                -- Mở tối đa 20 rương
                local openCount = math.min(20, targetChestStackCount)
                if openCount > 0 and _G.networkRequest and _G.networkRequest.ReqUseItem then
                    _G.networkRequest.ReqUseItem(openCount, targetChestId)
                end

                -- Chờ 1.0s cho đồ rớt & hút sạch vào túi
                _G.Mod_GoldenChestWaitTime = nowTime + 1.0
                _G.Mod_GoldenChestState = "WAIT_DROP"

            elseif _G.Mod_GoldenChestState == "WAIT_DROP" then
                if _G.Mod_PerformVacuumItems then _G.Mod_PerformVacuumItems() end
                if nowTime >= (_G.Mod_GoldenChestWaitTime or 0) then
                    _G.Mod_GoldenChestState = "RECYCLE"
                end

            elseif _G.Mod_GoldenChestState == "RECYCLE" then
                if _G.Mod_PerformBagRecycle then _G.Mod_PerformBagRecycle() end
                _G.Mod_GoldenChestWaitTime = nowTime + 0.6
                _G.Mod_GoldenChestState = "WAIT_SYNC"

            elseif _G.Mod_GoldenChestState == "WAIT_SYNC" then
                if nowTime >= (_G.Mod_GoldenChestWaitTime or 0) then
                    if _G.ModUpdateGoldenChestLabel then _G.ModUpdateGoldenChestLabel() end
                    _G.Mod_GoldenChestState = "OPEN"
                end
            end
        end)
    end)
end
_G.Mod_StartGoldenChestLoop()

-- =========================================================================
-- [MOD FEATURE]: TỰ ĐỘNG TÌM HỎA LONG (AUTO FIND FIRE DRAGON)
-- Mô tả: Tự động dùng Đá Dịch Chuyển (20000022) ngẫu nhiên tìm Hỏa Long, tự khóa mục tiêu và thông báo khi phát hiện.
-- =========================================================================
local function Mod_UseTeleportStone()
    local stoneBagId = nil
    local items = _G.BagInfoData and _G.BagInfoData.TotalItems
    if not items and _G.BagInfoData and _G.BagInfoData.GetTotalItems then
        pcall(function() items = _G.BagInfoData:GetTotalItems() end)
    end
    if items then
        for _, itemData in pairs(items) do
            if itemData then
                local itemId = itemData.itemId or (itemData.data and itemData.data.itemId)
                local instanceId = itemData.id or (itemData.data and itemData.data.id)
                if itemId == 20000022 and instanceId then
                    stoneBagId = instanceId
                    break
                end
            end
        end
    end
    if stoneBagId then
        local used = false
        if _G.BagInfoController and _G.BagInfoController.UseItemReq then
            pcall(function()
                _G.BagInfoController.UseItemReq(1, stoneBagId, nil, 20000022)
                used = true
            end)
        end
        if not used and _G.networkRequest and _G.networkRequest.ReqUseItem then
            pcall(function()
                _G.networkRequest.ReqUseItem(1, stoneBagId)
                used = true
            end)
        end
        return used
    end
    return false
end

local function Mod_CheckHoaLongAround(radius)
    radius = radius or 15
    local me = _G.RoleManager and _G.RoleManager.me
    if not me then return nil end
    local meX = me.serverCoord and me.serverCoord.x or (me.cellPos and me.cellPos.x) or (me.data and me.data.x) or 0
    local meY = me.serverCoord and me.serverCoord.y or (me.cellPos and me.cellPos.y) or (me.data and me.data.y) or 0
    if meX == 0 and meY == 0 then return nil end

    local monsterRoles = _G.RoleManager.GetRolesByType and _G.RoleManager.GetRolesByType(2)
    if not monsterRoles then return nil end

    local meId = me.data and me.data.id or 0

    for lid, role in pairs(monsterRoles) do
        if role and not role.isDead and (not role.hp or role.hp > 0) then
            local isSummon = role.isSummon or (role.data and role.data.isSummon) or false
            local ownerId = role.ownerId or (role.data and role.data.ownerId) or role.masterId or 0
            local isMySummon = (isSummon == true) or (ownerId ~= 0 and tostring(ownerId) == tostring(meId))

            if not isMySummon then
                local cfgId = (role.GetConfigId and role:GetConfigId()) or role.configId or (role.data and role.data.configId)
                local roleName = role.name or (role.data and role.data.name) or ""
                local model = role.model or (role.data and role.data.model) or ""

                local isHoaLong = false
                if cfgId == 500301 or cfgId == 100112 then
                    isHoaLong = true
                elseif string.find(roleName, "Hỏa Long") or string.find(roleName, "Hoa Long") or string.find(roleName, "Vua H") then
                    isHoaLong = true
                elseif model == "Monster32" then
                    isHoaLong = true
                end

                if isHoaLong then
                    local targetX = role.serverCoord and role.serverCoord.x or (role.cellPos and role.cellPos.x) or (role.data and role.data.x)
                    local targetY = role.serverCoord and role.serverCoord.y or (role.cellPos and role.cellPos.y) or (role.data and role.data.y)
                    if targetX and targetY then
                        local dx = tonumber(targetX) - meX
                        local dy = tonumber(targetY) - meY
                        local dist = math.max(math.abs(dx), math.abs(dy))
                        if dist <= radius then
                            return role, tonumber(targetX), tonumber(targetY), dist, roleName
                        end
                    end
                end
            end
        end
    end
    return nil
end

_G.Mod_StartFindHoaLongLoop = function()
    if not _G.Mod_IsActive or not _G.Mod_FindHoaLong_Enabled then
        _G.Mod_StopTimer("Mod_FindHoaLongLoop")
        return
    end

    _G.Mod_StartTrackedTimer("Mod_FindHoaLongLoop", 0.5, -1, function()
        if not _G.Mod_IsActive or not _G.Mod_FindHoaLong_Enabled then
            _G.Mod_StopTimer("Mod_FindHoaLongLoop")
            return
        end

        local me = _G.RoleManager and _G.RoleManager.me
        if not me or me.isDead then return end

        -- 1. Quét tìm Hỏa Long trong vòng 15 ô
        local foundRole, fx, fy, fDist, fName = Mod_CheckHoaLongAround(15)
        if foundRole and fx and fy then
            _G.Mod_FindHoaLong_Enabled = false
            _G.Mod_StopTimer("Mod_FindHoaLongLoop")
            if CS.UnityEngine.PlayerPrefs then
                CS.UnityEngine.PlayerPrefs.SetInt("Mod_FindHoaLong_Enabled", 0)
                CS.UnityEngine.PlayerPrefs.Save()
            end
            if _G.ModUpdateFindHoaLongLabel then
                _G.ModUpdateFindHoaLongLabel()
            end

            -- Khóa mục tiêu vào Hỏa Long
            pcall(function()
                if me.SetTarget then
                    me:SetTarget(foundRole)
                elseif me.SetTargetAvatar then
                    me:SetTargetAvatar(foundRole)
                end
            end)

            local bossName = (fName and fName ~= "") and fName or "HỎA LONG"
            local msg = string.format("🔥 [TÌM THẤY BOSS] %s tại tọa độ (%d, %d) - Cách %d ô!", bossName, fx, fy, math.floor(fDist))
            if _G.FloatingWordUtility and _G.FloatingWordUtility.QuickMsg then
                _G.FloatingWordUtility.QuickMsg(msg)
            end
            return
        end

        -- 2. Chưa thấy Hỏa Long trong 15 ô -> Sử dụng Đá Dịch Chuyển để nhảy vị trí khác
        local used = Mod_UseTeleportStone()
        if not used then
            _G.Mod_FindHoaLong_Enabled = false
            _G.Mod_StopTimer("Mod_FindHoaLongLoop")
            if CS.UnityEngine.PlayerPrefs then
                CS.UnityEngine.PlayerPrefs.SetInt("Mod_FindHoaLong_Enabled", 0)
                CS.UnityEngine.PlayerPrefs.Save()
            end
            if _G.ModUpdateFindHoaLongLabel then
                _G.ModUpdateFindHoaLongLabel()
            end
            if _G.FloatingWordUtility and _G.FloatingWordUtility.QuickMsg then
                _G.FloatingWordUtility.QuickMsg("⚠️ Không có Đá Dịch Chuyển (20000022) trong túi đồ!")
            end
        end
    end)
end

return true
