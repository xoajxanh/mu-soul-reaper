---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global
---@diagnostic disable: duplicate-set-field
-- EmmyluaDebug.lua
-- Bắt buộc phải có để Main.lua gọi không bị lỗi
EmmyluaDebug = {}

-- =========================================================================
-- [MOD FEATURE]: KHỞI TẠO BIẾN TOÀN CỤC MOD (GLOBAL MOD INIT)
-- Mô tả: Gán cờ quyền Admin, Dev ngay từ khi nạp script
-- =========================================================================
_G.Mod_IsAdmin = true
_G.Mod_IsDev = true

-- =========================================================================
-- [MOD FEATURE]: KHỞI TẠO MOD & CHỐNG TẢI ĐÈ BUNDLES (ANTI-UPDATE & INIT)
-- Mô tả: Khởi tạo biến toàn cục mod và dọn dẹp file lua.mu2 cũ trong persistentDataPath
-- =========================================================================
function EmmyluaDebug.InitEmmyluaDebug(obj)
    _G.Mod_IsAdmin = true
    _G.Mod_IsDev = true

    pcall(function()
        local Application = CS.UnityEngine.Application
        local Directory = CS.System.IO.Directory
        local File = CS.System.IO.File

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
    end)
end

if _G.ModInitialized then return true end
_G.ModInitialized = true

-- =========================================================================
-- [MOD FEATURE]: KHỞI TẠO NÚT NỔI VỤT (FLOATING VUT BUTTON)
-- Mô tả: Tạo Canvas độc lập (DontDestroyOnLoad) và hiển thị nút nổi VỤT trên màn hình để test
-- =========================================================================
local function CreateModUI()
    local status, err = pcall(function()
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
        btnGo.transform:SetParent(modRoot.transform, false)
        local rt = btnGo:AddComponent(typeof(RectTransform))
        rt.anchorMin = Vector2(0, 0)
        rt.anchorMax = Vector2(0, 0)
        rt.pivot = Vector2(0, 0)
        rt.anchoredPosition = Vector2(1, 60)
        rt.sizeDelta = Vector2(60, 60)

        local img = btnGo:AddComponent(typeof(Image))
        img.color = Color(0.215, 0.490, 0.133, 1.0)

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
        if defaultFont then txt.font = defaultFont end

        local btnComp = btnGo:AddComponent(typeof(Button))
        btnComp.onClick:AddListener(function()
            if _G.FloatingWordUtility and _G.FloatingWordUtility.QuickMsg then
                _G.FloatingWordUtility.QuickMsg("Nút nổi VỤT hoạt động thành công!")
            end
        end)
    end)

    if not status then
        pcall(function()
            CS.UnityEngine.Debug.LogError("[MySuperMod] LỖI TẠO UI: " .. tostring(err))
        end)
    end
end

-- =========================================================================
-- [MOD FEATURE]: TẠO MOD UI NGAY TỪ MÀN HÌNH ĐĂNG NHẬP (LOGIN SCENE & IN-GAME)
-- Mô tả: Khởi tạo MySuperModCanvas và nút nổi VỤT ngay từ ngoài đăng nhập
-- =========================================================================
_G.Mod_CreateUIImmediately = function()
    if not _G.MyModCreated then
        pcall(function()
            _G.MyModCreated = true
            CreateModUI()
        end)
    end
end

-- Tạo ngay khi nạp script
_G.Mod_CreateUIImmediately()

if not _G.ModUIHeartbeat_Started then
    _G.ModUIHeartbeat_Started = true
    if _G.Timer and _G.Timer.StartLoopForever then
        _G.Timer.StartLoopForever(0.5, function()
            if not _G.MyModCreated then
                _G.Mod_CreateUIImmediately()
            end
        end)
    elseif _G.Timer and _G.Timer.StartLoop then
        _G.Timer.StartLoop(0.5, -1, function()
            if not _G.MyModCreated then
                _G.Mod_CreateUIImmediately()
            end
        end)
    end
end

pcall(function()
    if _G.UIManager and not _G.MyModHooked then
        _G.MyModHooked = true
        local original_Show = _G.UIManager.Show
        _G.UIManager.Show = function(name, args, animation)
            local ret = nil
            if original_Show then ret = original_Show(name, args, animation) end
            if name == "Main_MainMenuUI" then
                if not _G.MyModCreated then
                    _G.MyModCreated = true
                    CreateModUI()
                end
            end
            return ret
        end
    end
end)

