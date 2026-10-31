-- =========================================================================
-- [MODULE]: mod_core_utils.lua
-- Mục đích: Quản lý Timer hệ thống, lưu PlayerPrefs, hiển thị thông báo & ghi output.txt
-- Tham chiếu code gốc:
--   - Timer.lua, CS.UnityEngine.PlayerPrefs, FloatingWordUtility.lua
--   - EmmyluaDebug.lua lines 500-550, 9600-9650
-- =========================================================================

local ModCoreUtils = {}

_G.Mod_ActiveTrackedTimers = _G.Mod_ActiveTrackedTimers or {}

--- Khởi tạo hoặc thay thế một Timer có theo dõi (Tracked Timer)
-- Đảm bảo không bao giờ bị đè trùng lặp nhiều timer cùng tên gây leak bộ nhớ hoặc spam lệnh
-- @param name string: Tên định danh của Timer (ví dụ "AutoDungeonMonitor", "AutoReturnTrain")
-- @param interval number: Chu kỳ lặp tính bằng giây (ví dụ 1.0)
-- @param count number: Số lần lặp (-1: Vô hạn)
-- @param func function: Hàm callback thực thi mỗi nhịp
-- @return userdata|table: Object Timer đã kích hoạt
function ModCoreUtils.StartTrackedTimer(name, interval, count, func)
    if not name or not func then return nil end
    interval = interval or 1.0
    count = count or -1

    -- 1. Hủy Timer cũ nếu đang tồn tại
    if _G.Mod_ActiveTrackedTimers[name] then
        pcall(function()
            _G.Mod_ActiveTrackedTimers[name]:Stop()
        end)
        _G.Mod_ActiveTrackedTimers[name] = nil
    end

    -- 2. Tạo Timer mới
    local newTimer = nil
    if _G.Timer and _G.Timer.New then
        pcall(function()
            newTimer = _G.Timer.New(func, interval, count)
            newTimer:Start()
            _G.Mod_ActiveTrackedTimers[name] = newTimer
        end)
    end

    return newTimer
end

--- Hủy một Tracked Timer theo tên
-- @param name string
function ModCoreUtils.StopTrackedTimer(name)
    if name and _G.Mod_ActiveTrackedTimers[name] then
        pcall(function()
            _G.Mod_ActiveTrackedTimers[name]:Stop()
        end)
        _G.Mod_ActiveTrackedTimers[name] = nil
        return true
    end
    return false
end

--- Lưu giá trị Boolean vào PlayerPrefs
-- @param key string, val boolean
function ModCoreUtils.SaveBool(key, val)
    if not key then return end
    pcall(function()
        CS.UnityEngine.PlayerPrefs.SetInt(key, val and 1 or 0)
        CS.UnityEngine.PlayerPrefs.Save()
    end)
end

--- Đọc giá trị Boolean từ PlayerPrefs
-- @param key string, defaultVal boolean
-- @return boolean
function ModCoreUtils.LoadBool(key, defaultVal)
    if not key then return defaultVal or false end
    local res = defaultVal
    pcall(function()
        local defInt = (defaultVal and 1 or 0)
        res = (CS.UnityEngine.PlayerPrefs.GetInt(key, defInt) == 1)
    end)
    return res
end

--- Lưu chuỗi String vào PlayerPrefs
function ModCoreUtils.SaveString(key, val)
    if not key then return end
    pcall(function()
        CS.UnityEngine.PlayerPrefs.SetString(key, tostring(val or ""))
        CS.UnityEngine.PlayerPrefs.Save()
    end)
end

--- Đọc chuỗi String từ PlayerPrefs
function ModCoreUtils.LoadString(key, defaultVal)
    if not key then return defaultVal or "" end
    local res = defaultVal or ""
    pcall(function()
        res = CS.UnityEngine.PlayerPrefs.GetString(key, defaultVal or "")
    end)
    return res
end

--- Hiển thị thông báo chữ nổi nhỏ (QuickMsg)
-- @param text string
function ModCoreUtils.ShowQuickMsg(text)
    if not text then return end
    if _G.FloatingWordUtility and _G.FloatingWordUtility.QuickMsg then
        pcall(function() _G.FloatingWordUtility.QuickMsg(text) end)
    end
end

--- Hiển thị thông báo chữ to cảnh báo giữa màn hình
-- @param text string: Hỗ trợ mã màu RichText ví dụ "<color=#FF3333>Cảnh báo!</color>"
function ModCoreUtils.ShowRedWarning(text)
    if not text then return end
    if _G.ShowDungeonRedWarning then
        pcall(function() _G.ShowDungeonRedWarning(text) end)
    else
        ModCoreUtils.ShowQuickMsg(text)
    end
end

--- Ghi nội dung nhật ký ra file persistentDataPath/output.txt cho script test
-- @param content string|table: Chuỗi hoặc mảng các dòng log
-- @return boolean: true nếu ghi thành công
function ModCoreUtils.WriteOutputFile(content)
    local outPath = CS.UnityEngine.Application.persistentDataPath .. "/output.txt"
    local strData = ""
    if type(content) == "table" then
        strData = table.concat(content, "\n")
    else
        strData = tostring(content or "")
    end

    local ok = pcall(function()
        local f = io.open(outPath, "w")
        if f then
            f:write(strData)
            f:close()
        end
    end)
    return ok
end

return ModCoreUtils
