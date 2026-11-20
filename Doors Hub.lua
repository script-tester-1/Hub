-- Doors Mode Script Hub

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local ALL_GUI_NAMES = {
    "Doors-Mode-Hub",
    "Doors-Mode-HubFloatingGUI",
    "Doors-Mode-HubRainbowFPS",
    "Voorpr0DiscordServerScript",
    "Voorpr0DiscordServerScriptFloatingGUI",
    "DoorsModeHub",
    "DoorsModeFloatingGUI"
}

for _, guiName in ipairs(ALL_GUI_NAMES) do
    local existing = CoreGui:FindFirstChild(guiName)
    if existing then
        existing:Destroy()
    end
end

-- ==================== NGÔN NGỮ & LƯU CẤU HÌNH ====================
local LANG_CONFIG_FILE = "DoorsModeHub_Lang.txt"
local RAINBOW_HUD_CONFIG_FILE = "DoorsModeHub_RainbowHUD.txt"
local FLOAT_POS_CONFIG_FILE = "DoorsModeHub_FloatPos.txt"
local FLOAT_BTN_SIZE = 50
local SCREEN_EDGE_MARGIN = 6

local Locales = {
    vi = {
        tab_doors = "Doors Mode",
        tab_discord = "ScriptIFoundItInDiscord",
        tab_unknown = "Unknown Doors Script",
        tab_misc = "Misc",
        tab_settings = "Settings",
        stat_loading = "Đang tải...",
        stat_fps = "⚡FPS:",
        stat_ping = "📶 Ping:",
        stat_health = "❤️ Health:",
        stat_speed = "🏃Speed:",
        not_spawned = "Chưa hồi sinh",
        hub_ready = "Doors-Mode-Hub đã sẵn sàng!",
        lang_btn = "VI",
        err_run_script = "Lỗi khi chạy script %s: %s",
        err_normal_mode = "Chế độ thường thất bại (%s): %s",
        err_reposted_mode = "Chế độ đăng lại thất bại (%s): %s",
        mini_title = "⚠️ Nhật ký lỗi",
        mini_clear = "Xóa",
        hud_fps_ping = "FPS: %d | Ping: %d ms",
        toggle_rainbow_hud = "🌈 FPS & Ping cầu vồng",
        toggle_mini_log = "📋 Bảng nhật ký lỗi mini",
        setting_language = "🌐 Ngôn ngữ (EN / VI)",
        hud_pos_bottom = "↕ Vị trí FPS & Ping: Dưới (20px)",
        hud_pos_top = "↕ Vị trí FPS & Ping: Trên (20px)",
        hud_size_normal = "🔤 Cỡ chữ FPS & Ping: Vừa (16)",
        hud_size_large = "🔤 Cỡ chữ FPS & Ping: Lớn (22)",
        btn_reset_float = "🎯 Đặt lại vị trí nút nổi",
        action_reset = "Đặt lại",
        state_on = "BẬT",
        state_off = "TẮT",
        confirm_title = "⚠️ Xác nhận xóa",
        confirm_msg = "Bạn có chắc muốn xóa toàn bộ Hub không?",
        confirm_yes = "Xóa",
        confirm_no = "Hủy"
    },
    en = {
        tab_doors = "Doors Mode",
        tab_discord = "ScriptIFoundItInDiscord",
        tab_unknown = "Unknown Doors Script",
        tab_misc = "Misc",
        tab_settings = "Settings",
        stat_loading = "Loading...",
        stat_fps = "⚡FPS:",
        stat_ping = "📶 Ping:",
        stat_health = "❤️ Health:",
        stat_speed = "🏃Speed:",
        not_spawned = "Not Spawned",
        hub_ready = "Doors-Mode-Hub is ready!",
        lang_btn = "EN",
        err_run_script = "Error running script %s: %s",
        err_normal_mode = "Normal Mode failed (%s): %s",
        err_reposted_mode = "Reposted Mode failed (%s): %s",
        mini_title = "⚠️ Error Log",
        mini_clear = "Clear",
        hud_fps_ping = "FPS: %d | Ping: %d ms",
        toggle_rainbow_hud = "🌈 Rainbow FPS & Ping",
        toggle_mini_log = "📋 Mini Error Log Popup",
        setting_language = "🌐 Language (EN / VI)",
        hud_pos_bottom = "↕ FPS & Ping Position: Bottom (20px)",
        hud_pos_top = "↕ FPS & Ping Position: Top (20px)",
        hud_size_normal = "🔤 FPS & Ping Font Size: Normal (16)",
        hud_size_large = "🔤 FPS & Ping Font Size: Large (22)",
        btn_reset_float = "🎯 Reset Float Button Position",
        action_reset = "Reset",
        state_on = "ON",
        state_off = "OFF",
        confirm_title = "⚠️ Confirm Delete",
        confirm_msg = "Are you sure you want to completely delete the Hub?",
        confirm_yes = "Delete",
        confirm_no = "Cancel"
    }
}

local function safeRead(fileName)
    if type(isfile) == "function" and type(readfile) == "function" then
        local ok, data = pcall(function()
            return isfile(fileName) and tostring(readfile(fileName)) or nil
        end)
        if ok then return data end
    end
    return nil
end

local function safeWrite(fileName, content)
    if type(writefile) == "function" then
        pcall(function() writefile(fileName, tostring(content)) end)
    end
end

local function getViewportSize()
    local cam = workspace.CurrentCamera
    if cam and cam.ViewportSize.X > 0 and cam.ViewportSize.Y > 0 then
        return cam.ViewportSize
    end
    return Vector2.new(1280, 720)
end

local function clampToViewport(udim, itemWidth, itemHeight)
    local vp = getViewportSize()
    local absX = udim.X.Scale * vp.X + udim.X.Offset
    local absY = udim.Y.Scale * vp.Y + udim.Y.Offset
    local maxX = math.max(SCREEN_EDGE_MARGIN, vp.X - itemWidth - SCREEN_EDGE_MARGIN)
    local maxY = math.max(SCREEN_EDGE_MARGIN, vp.Y - itemHeight - SCREEN_EDGE_MARGIN)
    return UDim2.fromOffset(
        math.clamp(math.floor(absX + 0.5), SCREEN_EDGE_MARGIN, maxX),
        math.clamp(math.floor(absY + 0.5), SCREEN_EDGE_MARGIN, maxY)
    )
end

local function getDefaultFloatPos()
    return clampToViewport(UDim2.new(1, -65, 0.5, -25), FLOAT_BTN_SIZE, FLOAT_BTN_SIZE)
end

local function saveFloatPos(udim)
    local clamped = clampToViewport(udim, FLOAT_BTN_SIZE, FLOAT_BTN_SIZE)
    safeWrite(FLOAT_POS_CONFIG_FILE, string.format(
        "%.6f,%.2f,%.6f,%.2f",
        clamped.X.Scale, clamped.X.Offset, clamped.Y.Scale, clamped.Y.Offset
    ))
end

local function loadFloatPos()
    local raw = safeRead(FLOAT_POS_CONFIG_FILE)
    if not raw then return getDefaultFloatPos() end
    local xs, xo, ys, yo = string.match(raw, "^%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*$")
    xs, xo, ys, yo = tonumber(xs), tonumber(xo), tonumber(ys), tonumber(yo)
    if xs and xo and ys and yo then
        return clampToViewport(UDim2.new(xs, xo, ys, yo), FLOAT_BTN_SIZE, FLOAT_BTN_SIZE)
    end
    return getDefaultFloatPos()
end

local function detectLang()
    local loc = ""
    pcall(function() loc = string.lower(tostring(LocalPlayer.LocaleId or "")) end)
    return string.sub(loc, 1, 2) == "vi" and "vi" or "en"
end

local currentLang = (function()
    local raw = safeRead(LANG_CONFIG_FILE)
    local c = raw and string.lower(string.gsub(raw, "%s+", "")) or ""
    return (c == "vi" or c == "en") and c or detectLang()
end)()

local rainbowHudEnabled = (function()
    local raw = safeRead(RAINBOW_HUD_CONFIG_FILE)
    local c = raw and string.lower(string.gsub(raw, "%s+", "")) or ""
    if c == "false" or c == "0" or c == "off" then return false end
    if c == "true" or c == "1" or c == "on" then return true end
    return true
end)()

local function tr(key)
    return (Locales[currentLang] and Locales[currentLang][key]) or Locales.en[key] or key
end

local function trFmt(key, ...)
    return string.format(tr(key), ...)
end

local langListeners = {}
local function onLangChanged(fn)
    table.insert(langListeners, fn)
    fn(currentLang)
end

local function setLang(lang)
    if not Locales[lang] then return end
    currentLang = lang
    safeWrite(LANG_CONFIG_FILE, lang)
    for _, fn in ipairs(langListeners) do
        pcall(fn, currentLang)
    end
end

-- ==================== UI HELPERS & RAINBOW STROKES ====================
local rainbowButtonStrokes = {}
local rainbowFrameStrokes = {}
local rainbowGlowImages = {}

local function addCorner(inst, px)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px)
    c.Parent = inst
    return c
end

local function addStroke(inst, color, thickness, bucket)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1.2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    if bucket then table.insert(bucket, s) end
    return s
end

local function makeDraggable(handle, target, onDragEnd, clampDims)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End and dragging then
                    dragging = false
                    if onDragEnd then onDragEnd(target.Position) end
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local nextPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            if clampDims then
                nextPos = clampToViewport(nextPos, clampDims.X, clampDims.Y)
            end
            target.Position = nextPos
        end
    end)
end

-- ==================== MAIN GUI & MINI ERROR LOG ====================
local MainScreen = Instance.new("ScreenGui")
MainScreen.Name = "Doors-Mode-Hub"
MainScreen.ResetOnSpawn = false
MainScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainScreen.Parent = CoreGui

local MiniFrame = Instance.new("Frame")
MiniFrame.Name = "MiniErrorTab"
MiniFrame.Size = UDim2.fromOffset(280, 145)
MiniFrame.Position = UDim2.new(1, -295, 1, -160)
MiniFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
MiniFrame.BorderSizePixel = 0
MiniFrame.Visible = false
MiniFrame.ZIndex = 50
MiniFrame.Parent = MainScreen
addCorner(MiniFrame, 8)
addStroke(MiniFrame, Color3.fromRGB(235, 80, 110), 1.2)

local MiniHeader = Instance.new("Frame")
MiniHeader.Size = UDim2.new(1, 0, 0, 28)
MiniHeader.BackgroundColor3 = Color3.fromRGB(30, 24, 36)
MiniHeader.BorderSizePixel = 0
MiniHeader.ZIndex = 51
MiniHeader.Parent = MiniFrame
addCorner(MiniHeader, 8)
makeDraggable(MiniHeader, MiniFrame)

local MiniTitle = Instance.new("TextLabel")
MiniTitle.Size = UDim2.new(1, -85, 1, 0)
MiniTitle.Position = UDim2.new(0, 10, 0, 0)
MiniTitle.BackgroundTransparency = 1
MiniTitle.Font = Enum.Font.GothamBold
MiniTitle.TextColor3 = Color3.fromRGB(255, 120, 140)
MiniTitle.TextSize = 12
MiniTitle.TextXAlignment = Enum.TextXAlignment.Left
MiniTitle.ZIndex = 52
MiniTitle.Parent = MiniHeader

local function makeHeaderBtn(text, xOffset, bgColor, textColor)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(text == "X" and 20 or 42, 20)
    b.Position = UDim2.new(1, xOffset, 0.5, -10)
    b.BackgroundColor3 = bgColor
    b.Font = Enum.Font.GothamBold
    b.Text = text
    b.TextColor3 = textColor
    b.TextSize = 11
    b.ZIndex = 52
    b.Parent = MiniHeader
    addCorner(b, 5)
    addStroke(b, Color3.fromRGB(150, 64, 214), 1, rainbowButtonStrokes)
    return b
end

local ClearBtn = makeHeaderBtn("", -72, Color3.fromRGB(45, 35, 55), Color3.fromRGB(230, 230, 240))
local CloseMiniBtn = makeHeaderBtn("X", -25, Color3.fromRGB(235, 80, 110), Color3.fromRGB(255, 255, 255))

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size = UDim2.new(1, -12, 1, -34)
LogScroll.Position = UDim2.new(0, 6, 0, 31)
LogScroll.BackgroundTransparency = 1
LogScroll.BorderSizePixel = 0
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogScroll.ScrollBarThickness = 2
LogScroll.ZIndex = 51
LogScroll.Parent = MiniFrame

local LogLayout = Instance.new("UIListLayout")
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding = UDim.new(0, 4)
LogLayout.Parent = LogScroll

local refreshMiniLogToggleVisual

local function pushMiniError(msg)
    MiniFrame.Visible = true
    if refreshMiniLogToggleVisual then refreshMiniLogToggleVisual() end

    local item = Instance.new("TextLabel")
    item.Size = UDim2.new(1, -4, 0, 0)
    item.AutomaticSize = Enum.AutomaticSize.Y
    item.BackgroundColor3 = Color3.fromRGB(32, 26, 36)
    item.Font = Enum.Font.Gotham
    item.Text = "• " .. tostring(msg)
    item.TextColor3 = Color3.fromRGB(255, 190, 200)
    item.TextSize = 11
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.ZIndex = 52
    item.Parent = LogScroll
    addCorner(item, 4)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)
    pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
    pad.Parent = item
end

ClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(LogScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end)

CloseMiniBtn.MouseButton1Click:Connect(function()
    MiniFrame.Visible = false
    if refreshMiniLogToggleVisual then refreshMiniLogToggleVisual() end
end)

onLangChanged(function()
    MiniTitle.Text = tr("mini_title")
    ClearBtn.Text = tr("mini_clear")
end)

-- ==================== MAIN FRAME ====================
local normalFrameSize = UDim2.fromOffset(580, 340)
local isFullScreen = false
local allTabsHidden = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(0, 0)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = MainScreen
addCorner(MainFrame, 10)
addStroke(MainFrame, Color3.fromRGB(150, 64, 214), 1.8, rainbowFrameStrokes)

local GlowFrame = Instance.new("ImageLabel")
GlowFrame.Name = "GlowEffect"
GlowFrame.BackgroundTransparency = 1
GlowFrame.Size = UDim2.new(1, 30, 1, 30)
GlowFrame.Position = UDim2.new(0, -15, 0, -15)
GlowFrame.ZIndex = MainFrame.ZIndex - 1
GlowFrame.Image = "rbxassetid://6014261993"
GlowFrame.ImageColor3 = Color3.fromRGB(150, 64, 214)
GlowFrame.ImageTransparency = 0.35
GlowFrame.ScaleType = Enum.ScaleType.Slice
GlowFrame.SliceCenter = Rect.new(49, 49, 450, 450)
GlowFrame.Parent = MainFrame
addCorner(GlowFrame, 14)
addStroke(GlowFrame, Color3.fromRGB(150, 64, 214), 1.5, rainbowFrameStrokes)
table.insert(rainbowGlowImages, GlowFrame)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame
makeDraggable(TopBar, MainFrame)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -95, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "🚪 <font color='#9640d6'>Doors-Mode-Hub</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local LangBtn = Instance.new("TextButton")
LangBtn.Name = "LangButton"
LangBtn.Size = UDim2.fromOffset(64, 26)
LangBtn.Position = UDim2.new(1, -76, 0.5, -13)
LangBtn.BackgroundColor3 = Color3.fromRGB(40, 28, 55)
LangBtn.AutoButtonColor = false
LangBtn.Font = Enum.Font.GothamBold
LangBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LangBtn.TextSize = 12
LangBtn.Parent = TopBar
addCorner(LangBtn, 6)
addStroke(LangBtn, Color3.fromRGB(150, 64, 214), 1.2, rainbowButtonStrokes)

onLangChanged(function()
    LangBtn.Text = "🌐 " .. tr("lang_btn")
end)

LangBtn.MouseButton1Click:Connect(function()
    setLang(currentLang == "vi" and "en" or "vi")
end)

-- ==================== SIDEBAR, CONTROLS (-, +, x) & TABS ====================
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, 165, 1, -50)
Sidebar.Position = UDim2.new(0, 10, 0, 45)
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.ScrollBarThickness = 0
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.Parent = Sidebar

local sidePad = Instance.new("UIPadding")
sidePad.PaddingLeft, sidePad.PaddingTop, sidePad.PaddingBottom = UDim.new(0, 2), UDim.new(0, 2), UDim.new(0, 4)
sidePad.Parent = Sidebar

local ContainerHolder = Instance.new("Frame")
ContainerHolder.Size = UDim2.new(1, -190, 1, -50)
ContainerHolder.Position = UDim2.new(0, 180, 0, 45)
ContainerHolder.BackgroundTransparency = 1
ContainerHolder.Parent = MainFrame

local TabHeaderBar = Instance.new("Frame")
TabHeaderBar.Name = "TabControlsBar"
TabHeaderBar.Size = UDim2.new(1, 0, 0, 26)
TabHeaderBar.BackgroundTransparency = 1
TabHeaderBar.ZIndex = 10
TabHeaderBar.Parent = ContainerHolder

local ctrlLayout = Instance.new("UIListLayout")
ctrlLayout.FillDirection = Enum.FillDirection.Horizontal
ctrlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ctrlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ctrlLayout.SortOrder = Enum.SortOrder.LayoutOrder
ctrlLayout.Padding = UDim.new(0, 8)
ctrlLayout.Parent = TabHeaderBar

local TabBodyHolder = Instance.new("Frame")
TabBodyHolder.Name = "TabBodyHolder"
TabBodyHolder.Size = UDim2.new(1, 0, 1, -32)
TabBodyHolder.Position = UDim2.new(0, 0, 0, 32)
TabBodyHolder.BackgroundTransparency = 1
TabBodyHolder.Parent = ContainerHolder

local function createControlBtn(symbol, order, textColor)
    local btn = Instance.new("TextButton")
    btn.Name = "Control_" .. symbol
    btn.LayoutOrder = order
    btn.Size = UDim2.fromOffset(24, 24)
    btn.BackgroundColor3 = Color3.fromRGB(32, 26, 44)
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.Text = symbol
    btn.TextColor3 = textColor
    btn.TextSize = 14
    btn.ZIndex = 11
    btn.Parent = TabHeaderBar
    addCorner(btn, 6)
    addStroke(btn, Color3.fromRGB(150, 64, 214), 1.2, rainbowButtonStrokes)
    return btn
end

local MinusBtn = createControlBtn("-", 1, Color3.fromRGB(220, 180, 255))
local PlusBtn = createControlBtn("+", 2, Color3.fromRGB(110, 220, 160))
local CloseXBtn = createControlBtn("x", 3, Color3.fromRGB(245, 90, 120))

-- Delete confirmation mini tab
local ConfirmMiniTab = Instance.new("Frame")
ConfirmMiniTab.Name = "DeleteConfirmMiniTab"
ConfirmMiniTab.Size = UDim2.fromOffset(270, 125)
ConfirmMiniTab.Position = UDim2.fromScale(0.5, 0.5)
ConfirmMiniTab.AnchorPoint = Vector2.new(0.5, 0.5)
ConfirmMiniTab.BackgroundColor3 = Color3.fromRGB(22, 18, 28)
ConfirmMiniTab.BorderSizePixel = 0
ConfirmMiniTab.Visible = false
ConfirmMiniTab.ZIndex = 100
ConfirmMiniTab.Parent = MainScreen
addCorner(ConfirmMiniTab, 10)
addStroke(ConfirmMiniTab, Color3.fromRGB(150, 64, 214), 1.6, rainbowFrameStrokes)

local ConfirmTitle = Instance.new("TextLabel")
ConfirmTitle.Size = UDim2.new(1, -20, 0, 26)
ConfirmTitle.Position = UDim2.new(0, 10, 0, 8)
ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Font = Enum.Font.GothamBold
ConfirmTitle.TextColor3 = Color3.fromRGB(255, 120, 145)
ConfirmTitle.TextSize = 13
ConfirmTitle.TextXAlignment = Enum.TextXAlignment.Left
ConfirmTitle.ZIndex = 101
ConfirmTitle.Parent = ConfirmMiniTab

local ConfirmMsg = Instance.new("TextLabel")
ConfirmMsg.Size = UDim2.new(1, -20, 0, 36)
ConfirmMsg.Position = UDim2.new(0, 10, 0, 36)
ConfirmMsg.BackgroundTransparency = 1
ConfirmMsg.Font = Enum.Font.Gotham
ConfirmMsg.TextColor3 = Color3.fromRGB(225, 225, 235)
ConfirmMsg.TextSize = 12
ConfirmMsg.TextWrapped = true
ConfirmMsg.TextXAlignment = Enum.TextXAlignment.Left
ConfirmMsg.ZIndex = 101
ConfirmMsg.Parent = ConfirmMiniTab

local function makeConfirmBtn(text, xScale, xOff, bg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -14, 0, 30)
    b.Position = UDim2.new(xScale, xOff, 1, -40)
    b.BackgroundColor3 = bg
    b.Font = Enum.Font.GothamBold
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 12
    b.ZIndex = 101
    b.Parent = ConfirmMiniTab
    addCorner(b, 7)
    addStroke(b, Color3.fromRGB(150, 64, 214), 1.2, rainbowButtonStrokes)
    return b
end

local YesDeleteBtn = makeConfirmBtn("", 0, 10, Color3.fromRGB(220, 65, 95))
local NoCancelBtn = makeConfirmBtn("", 0.5, 4, Color3.fromRGB(45, 38, 58))

onLangChanged(function()
    ConfirmTitle.Text = tr("confirm_title")
    ConfirmMsg.Text = tr("confirm_msg")
    YesDeleteBtn.Text = tr("confirm_yes")
    NoCancelBtn.Text = tr("confirm_no")
end)

local function getActiveTargetFrameSize()
    local vp = getViewportSize()
    local width = isFullScreen and math.max(320, vp.X - 20) or normalFrameSize.X.Offset
    if allTabsHidden then return UDim2.fromOffset(width, 76) end
    local height = isFullScreen and math.max(220, vp.Y - 20) or normalFrameSize.Y.Offset
    return UDim2.fromOffset(width, height)
end

MinusBtn.MouseButton1Click:Connect(function()
    allTabsHidden = not allTabsHidden
    Sidebar.Visible = not allTabsHidden
    TabBodyHolder.Visible = not allTabsHidden
    TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = getActiveTargetFrameSize()
    }):Play()
end)

PlusBtn.MouseButton1Click:Connect(function()
    if allTabsHidden then
        allTabsHidden = false
        Sidebar.Visible = true
        TabBodyHolder.Visible = true
    end
    isFullScreen = not isFullScreen
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = getActiveTargetFrameSize(),
        Position = UDim2.fromScale(0.5, 0.5)
    }):Play()
end)

CloseXBtn.MouseButton1Click:Connect(function() ConfirmMiniTab.Visible = true end)
NoCancelBtn.MouseButton1Click:Connect(function() ConfirmMiniTab.Visible = false end)
YesDeleteBtn.MouseButton1Click:Connect(function()
    for _, guiName in ipairs(ALL_GUI_NAMES) do
        local g = CoreGui:FindFirstChild(guiName)
        if g then g:Destroy() end
    end
end)

local tabs = {}
local currentTab = nil

local function createTab(tabKey)
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Name = tr(tabKey) .. "Content"
    TabContent.Size = UDim2.fromScale(1, 1)
    TabContent.BackgroundTransparency = 1
    TabContent.BorderSizePixel = 0
    TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabContent.ScrollBarThickness = 3
    TabContent.Visible = false
    TabContent.Parent = TabBodyHolder

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = TabContent

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 2), UDim.new(0, 4)
    pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 2), UDim.new(0, 4)
    pad.Parent = TabContent

    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, -4, 0, 34)
    TabBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    TabBtn.AutoButtonColor = false
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.Text = tr(tabKey)
    TabBtn.TextColor3 = Color3.fromRGB(150, 155, 170)
    TabBtn.TextSize = 12
    TabBtn.TextWrapped = true
    TabBtn.Parent = Sidebar
    addCorner(TabBtn, 8)

    local tabStroke = addStroke(TabBtn, Color3.fromRGB(150, 64, 214), 1.3, rainbowButtonStrokes)
    tabStroke.Transparency = 0.55

    onLangChanged(function() TabBtn.Text = tr(tabKey) end)

    TabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.content.Visible = false
            TweenService:Create(t.button, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(24, 24, 30),
                TextColor3 = Color3.fromRGB(150, 155, 170)
            }):Play()
            TweenService:Create(t.stroke, TweenInfo.new(0.2), {Transparency = 0.55}):Play()
        end
        TabContent.Visible = true
        TweenService:Create(TabBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 28, 55),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        TweenService:Create(tabStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
        currentTab = tabKey
    end)

    if not currentTab then
        TabContent.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(40, 28, 55)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabStroke.Transparency = 0
        currentTab = tabKey
    end

    tabs[tabKey] = {button = TabBtn, content = TabContent, stroke = tabStroke}
    return TabContent
end

local function createButton(targetTab, text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 36)
    Btn.BackgroundColor3 = Color3.fromRGB(35, 24, 52)
    Btn.Font = Enum.Font.GothamBold
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 13
    Btn.Parent = targetTab
    addCorner(Btn, 8)
    addStroke(Btn, Color3.fromRGB(150, 64, 214), 1.3, rainbowButtonStrokes)

    Btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then
            pushMiniError(trFmt("err_run_script", text, tostring(err)))
        end
    end)
end

local function populateUrlButtons(targetTab, entries)
    for _, entry in ipairs(entries) do
        local label, url, flag = entry[1], entry[2], entry[3]
        createButton(targetTab, label, function()
            if flag then
                loadstring(game:HttpGet(url, true))()
            else
                loadstring(game:HttpGet(url))()
            end
        end)
    end
end

-- ==================== TAB 1: DOORS MODE ====================
local DoorsModeTab = createTab("tab_doors")

populateUrlButtons(DoorsModeTab, {
    {"Hardcore Reignited", "https://raw.githubusercontent.com/Outernal/Doors/refs/heads/main/Hardcore-Reignited-Recreated", false},
    {"Doors Mode Script Hub", "https://raw.githubusercontent.com/Not-Guestly/Modes/refs/heads/main/GUESTLY-DOORS-MODE-HUB", false},
    {"Voidness Mode", "https://raw.githubusercontent.com/Not-Guestly/Modes/refs/heads/main/Voidness-Mode-Made-By-Guestly-Vuivuiviu2-And-Voorpr0", true},
    {"Fragmented Mode", "https://raw.githubusercontent.com/kethuacuoc190/fragemented/refs/heads/main/fullscript", false},
    {"Mayhem mode", "https://raw.githubusercontent.com/localplayerr/Doors-stuff/refs/heads/main/Mayhem%20mode%20recreate/Code", false},
    {"Cataclysmic mode", "https://raw.githubusercontent.com/GuestlyTheGreatestGuest/Modes/refs/heads/main/Cataclysmic-Mode-Made-by-Guestly-and-Vuivuiviu4", true},
    {"Dreamcore mode", "https://raw.githubusercontent.com/GuestlyTheGreatestGuest/Modes/refs/heads/main/Dreamcore-Mode-Made-by-Guestly-and-Voorpr0", true},
    {"Impossible mode Re-Degenerate", "https://raw.githubusercontent.com/GuestlyTheGreatestGuest/Modes/refs/heads/main/Dreamcore-Mode-Made-by-Guestly-and-Voorpr0", true},
    {"Ambush Mode", "https://pastefy.app/kuLssvSU/raw", false},
    {"Fog mode", "https://raw.githubusercontent.com/Ganyu06112/Fog-Mode/refs/heads/main/Fog-Mode.lua", false},
    {"Arctic mode", "https://raw.githubusercontent.com/Not-Guestly/Modes/refs/heads/main/Arctic-Mode-(Beta)-By-Guestly-And-Vuivuiviu2", false},
    {"Bissastant mode", "https://raw.githubusercontent.com/Guestly-Alt/Scripts/refs/heads/main/Bissastant-Mode", false}
})

createButton(DoorsModeTab, "Degenerate mode", function()
    task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Not-Guestly/Modes/refs/heads/main/Degenerate-Mode-Made-By-Guestly", true))()
        end)
        if not ok then pushMiniError(trFmt("err_normal_mode", "Degenerate mode", tostring(err))) end
    end)
    task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Not-Guestly/Modes/refs/heads/main/Degenerate-Mode-Reposted"))()
        end)
        if not ok then pushMiniError(trFmt("err_reposted_mode", "Degenerate mode", tostring(err))) end
    end)
end)

-- ==================== TAB 2: SCRIPT I FOUND IN DISCORD ====================
local DiscordTab = createTab("tab_discord")

populateUrlButtons(DiscordTab, {
    {"God is here", "https://pastefy.app/lAn7TCVE/raw", false},
    {"Meme Mode", "https://raw.githubusercontent.com/chubeteliet-cpu/meme-mode-m-p/refs/heads/main/Meme-mode-ma-hoa", true},
    {"Hardcore Mode Legacy", "https://raw.githubusercontent.com/NTTTTTTTT/upload/refs/heads/main/content/4937605c2f674748b008d2fced112c3b_obf.lua", true},
    {"Confusion mode", "https://raw.githubusercontent.com/UnknownRetrunz23/Question-mode-new/refs/heads/main/Yes%20this%20is%20my%20mode", false},
    {"Rocket Launcher", "https://raw.githubusercontent.com/persopoiu/scripts/refs/heads/main/RocketLauncher/script.lua", false},
    {"Trail Maniac Mode", "https://raw.githubusercontent.com/gonzalezmarrufoalexandersasuke-commits/Trail-Maniac-Mode/refs/heads/main/Maniac%20Mode", false},
    {"Moon Jug", "https://raw.githubusercontent.com/Guestly-Alt/Scripts/refs/heads/main/MoonJug", false},
    {"Spiral Jug", "https://raw.githubusercontent.com/Guestly-Alt/Scripts/refs/heads/main/Spiral-Jug", false},
    {"Viridis Rift", "https://raw.githubusercontent.com/Guestly-Alt/Scripts/refs/heads/main/Viridis-Rift", false},
    {"Mischievous Rift", "https://raw.githubusercontent.com/Guestly-Alt/Scripts/refs/heads/main/Mischievous-Rift", false},
    {"Glitch Rift", "https://raw.githubusercontent.com/Guestly-Alt/Scripts/refs/heads/main/Glitch-Rift", false},
    {"Viridislight Jug", "https://raw.githubusercontent.com/Not-Guestly/Scripts/refs/heads/main/Viridislight-Jug", false},
    {"Viridislight Bottle", "https://raw.githubusercontent.com/Not-Guestly/Scripts/refs/heads/main/Viridislight-Bottle", false},
    {"ChuBeTeLiet Mode", "https://raw.githubusercontent.com/NTTTTTTTT/upload/refs/heads/main/content/23043260e1ef4fd9978fab5b422273c3_obf.lua", true},
    {"Mega Hard Mode", "https://pastefy.app/jGU3jxSe/raw", false},
    {"Madness Mode(Beta)", "https://pastefy.app/9jWIjfE6/raw", false},
    {"Madness Mode v1.1", "https://pastefy.app/tD7aBKLf/raw", false},
    {"Madness Mode v1.2", "https://pastefy.app/VOny4364/raw", false},
    {"Threat Mode", "https://pastefy.app/HLvpvnAO/raw", false},
    {"Schizophrenia Mode", "https://raw.githubusercontent.com/tranthienhao872-ship-it/Schizophrenia-mode/refs/heads/main/Schizophrenia%20mode", false},
    {"Zombie Mode", "https://raw.githubusercontent.com/GrampyMods/ZombieMode/refs/heads/main/mode", false},
    {"Hard Mode", "https://pastefy.app/kLRWKtZN/raw", false},
    {"Maxwell Tool", "https://raw.githubusercontent.com/CastiSeek/Maxwell-the-cat-script/refs/heads/main/main.lua", false},
    {"Glitched Scanner", "https://raw.githubusercontent.com/Agadigas/Doors/refs/heads/main/Glitched%20Scanner%20by%20Custom%20Doors", false},
    {"Magic Runner", "https://raw.githubusercontent.com/skkenrgjt/HAHAHAH/refs/heads/main/MagicRunner", false},
    {"Purple Shake Light", "https://raw.githubusercontent.com/thelostw3r/Scripts/refs/heads/main/PurpleFlashlight.lua", false},
    {"Golden Shake Light", "https://raw.githubusercontent.com/aadyian9000/the-thing/main/GoldenGummyFlashlight.lua", true},
    {"Coffee Script", "https://pastefy.app/d61ZlCc1/raw", false},
    {"Guilding Light Candle", "https://raw.githubusercontent.com/Junbbinopro/Guiding-light-candle/refs/heads/main/Candle", false}
})

createButton(DiscordTab, "Egg", function()
    local tool = game:GetObjects("rbxassetid://74933357788345")[1]
    tool.Parent = LocalPlayer:WaitForChild("Backpack")

    local animationId = "rbxassetid://6516424098"
    local animTrack

    tool.Equipped:Connect(function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

        if animTrack then
            animTrack:Stop(0)
            animTrack:Destroy()
            animTrack = nil
        end

        local animation = Instance.new("Animation")
        animation.AnimationId = animationId
        animTrack = animator:LoadAnimation(animation)
        animTrack.Priority = Enum.AnimationPriority.Action4
        animTrack.Looped = true
        animTrack:Play(0, 1, 1)
        animTrack:AdjustWeight(1)
    end)

    tool.Unequipped:Connect(function()
        if animTrack then
            animTrack:Stop(0)
            animTrack:Destroy()
            animTrack = nil
        end
    end)
end)

-- ==================== TAB 3: UNKNOWN DOORS SCRIPT ====================
local UnknownDoorsTab = createTab("tab_unknown")

populateUrlButtons(UnknownDoorsTab, {
    {"Grace Entities Script", "https://raw.githubusercontent.com/IdkMyNameLoll/PublicScripts/refs/heads/main/GraceEntitiesScript", false},
    {"Retro+ mode", "https://rscripts.net/raw/brohax-for-door-retro_1756101656871_ygTRZ0NhO6.txt", true},
    {"Creepy Mode", "https://raw.githubusercontent.com/DripCapybara/Doors-Modes/refs/heads/main/CreepyMode/ObfuscatedMain.lua", false},
    {"Fragment Mode Remake", "https://raw.githubusercontent.com/thelostw3r/Mods/main/FragmentedModeRemake.lua", false},
    {"Overdoors", "https://raw.githubusercontent.com/chubeteliet-cpu/OVERDOORS-rework-ver/refs/heads/main/OVERDOORS%20entity%20finale%20upd", true},
    {"Ringer Mode", "https://raw.githubusercontent.com/chubeteliet-cpu/Ringer-doors/refs/heads/main/RINGER-DOORS-NEW!", true},
    {"Generator Hard Mode", "https://raw.githubusercontent.com/IdkMyNameLoll/PublicScripts/refs/heads/main/HardGenIThinkReupload", false},
    {"Psychotic Mode", "https://raw.githubusercontent.com/realbluedeptrai/Psychoti/refs/heads/main/Psychotic-remake.lua", true},
    {"Hollow Mode", "https://raw.githubusercontent.com/CastiSeek/Doors-Hollow-Mode/refs/heads/main/main.lua", false},
    {"Horror Mode", "https://raw.githubusercontent.com/thelostw3r/Mods/main/HorrorMode.lua", false},
    {"Room Low Detailed Mode", "https://raw.githubusercontent.com/eliazbp92-collab/Rooms-low-detailed-mode-doors/refs/heads/main/Script", false},
    {"Hardcore Reiginited Recreate Mode (by @OG HUNGER(Femboy) ", "https://raw.githubusercontent.com/eoyoustme/Hardcore/refs/heads/main/Hardcore%20Reiginited%20Recreate", false},
    {"Christmas Hardcore Mode", "https://pastefy.app/SJVcyyrV/raw", false},
    {"Broken Mode", "https://raw.githubusercontent.com/idkman60093/Doors-Modes/refs/heads/main/Broken-Mode-V1.8-Fixed-Version", false},
    {"Snuffer Mode", "https://raw.githubusercontent.com/Anctarus7105/My-Modes/refs/heads/main/SnufferV1.lua", false},
    {"Hardcore Mode Remastered", "https://raw.githubusercontent.com/Anctarus7105/Recreated-modes/refs/heads/main/Hardmode.lua", false},
    {"Inferno Mode", "https://raw.githubusercontent.com/Anctarus7105/My-Modes/refs/heads/main/Inferno.lua", false},
    {"Mayhem Mode Remake", "https://raw.githubusercontent.com/eoyoustme/Mayhem-Remake/refs/heads/main/Mayhem%20Remake", false},
    {"Ultra Hard Mode", "https://raw.githubusercontent.com/Junxd-03/UltraHardModeUpdate/refs/heads/main/UltraHardMode.lua", false},
    {"Older Hardcore Mode", "https://raw.githubusercontent.com/eliazbp92-collab/Oldest-hardcore-mode/refs/heads/main/Script", false},
    {"Hardcore Reiginited Recreate Mode (by @outernal)", "https://raw.githubusercontent.com/Guestly-Alt/Scripts/refs/heads/main/Hardcore-Reignited-(Recreated)", false},
    {"Particulate Mode", "https://rawscripts.net/raw/DOORS-Particulate-Mode-241450", false},
    {"Terminated Mode", "https://pastefy.app/hT2Q5AKa/raw", false}
})

-- ==================== TAB 4: MISC ====================
local MiscTab = createTab("tab_misc")

local function createStatBox(titleKey)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, 0, 0, 38)
    box.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    box.BorderSizePixel = 0
    box.Parent = MiscTab
    addCorner(box, 8)

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(0.6, -12, 1, 0)
    tLbl.Position = UDim2.new(0, 12, 0, 0)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamMedium
    tLbl.Text = tr(titleKey)
    tLbl.TextColor3 = Color3.fromRGB(210, 215, 230)
    tLbl.TextSize = 13
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = box

    local vLbl = Instance.new("TextLabel")
    vLbl.Size = UDim2.new(0.4, -12, 1, 0)
    vLbl.Position = UDim2.new(0.6, 0, 0, 0)
    vLbl.BackgroundTransparency = 1
    vLbl.Font = Enum.Font.GothamBold
    vLbl.Text = tr("stat_loading")
    vLbl.TextColor3 = Color3.fromRGB(150, 64, 214)
    vLbl.TextSize = 13
    vLbl.TextXAlignment = Enum.TextXAlignment.Right
    vLbl.Parent = box

    onLangChanged(function()
        tLbl.Text = tr(titleKey)
        if vLbl.Text == Locales.vi.stat_loading or vLbl.Text == Locales.en.stat_loading then
            vLbl.Text = tr("stat_loading")
        end
    end)

    return vLbl
end

local FpsVal = createStatBox("stat_fps")
local PingVal = createStatBox("stat_ping")
local HealthVal = createStatBox("stat_health")
local SpeedVal = createStatBox("stat_speed")

-- ==================== FLOATING IMAGE BUTTON ====================
local FloatGui = Instance.new("ScreenGui")
FloatGui.Name = "Doors-Mode-HubFloatingGUI"
FloatGui.ResetOnSpawn = false
FloatGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FloatGui.DisplayOrder = 1001
FloatGui.Parent = CoreGui

local FloatBtn = Instance.new("ImageButton")
FloatBtn.Name = "FloatButton"
FloatBtn.Size = UDim2.fromOffset(FLOAT_BTN_SIZE, FLOAT_BTN_SIZE)
FloatBtn.Position = loadFloatPos()
FloatBtn.BackgroundColor3 = Color3.fromRGB(35, 30, 48)
FloatBtn.AutoButtonColor = false
FloatBtn.Image = "rbxassetid://6556477120"
FloatBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
FloatBtn.ScaleType = Enum.ScaleType.Crop
FloatBtn.Parent = FloatGui
addCorner(FloatBtn, 25)
addStroke(FloatBtn, Color3.fromRGB(150, 64, 214), 2.2, rainbowButtonStrokes)
makeDraggable(FloatBtn, FloatBtn, saveFloatPos, Vector2.new(FLOAT_BTN_SIZE, FLOAT_BTN_SIZE))

local function bindViewportClamp()
    local cam = workspace.CurrentCamera
    if cam then
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if FloatBtn and FloatBtn.Parent then
                FloatBtn.Position = clampToViewport(FloatBtn.Position, FLOAT_BTN_SIZE, FLOAT_BTN_SIZE)
            end
        end)
    end
end
bindViewportClamp()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportClamp)

local hubVisible = false
FloatBtn.MouseButton1Click:Connect(function()
    hubVisible = not hubVisible
    if hubVisible then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.fromOffset(0, 0)
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = getActiveTargetFrameSize()
        }):Play()
        TweenService:Create(FloatBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(150, 64, 214)}):Play()
    else
        ConfirmMiniTab.Visible = false
        local tw = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(0, 0)
        })
        tw:Play()
        tw.Completed:Once(function() if not hubVisible then MainFrame.Visible = false end end)
        TweenService:Create(FloatBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 30, 48)}):Play()
    end
end)

-- ==================== TAB 5: SETTINGS & RAINBOW FPS/PING HUD ====================
local SettingsTab = createTab("tab_settings")

local FpsHudGui = Instance.new("ScreenGui")
FpsHudGui.Name = "Doors-Mode-HubRainbowFPS"
FpsHudGui.ResetOnSpawn = false
FpsHudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FpsHudGui.DisplayOrder = 1002
FpsHudGui.Enabled = rainbowHudEnabled
FpsHudGui.Parent = CoreGui

local RainbowHudLabel = Instance.new("TextLabel")
RainbowHudLabel.Name = "RainbowHudLabel"
RainbowHudLabel.Size = UDim2.fromOffset(300, 30)
RainbowHudLabel.Position = UDim2.new(0.5, 0, 1, -20)
RainbowHudLabel.AnchorPoint = Vector2.new(0.5, 1)
RainbowHudLabel.BackgroundTransparency = 1
RainbowHudLabel.Font = Enum.Font.GothamBlack
RainbowHudLabel.Text = string.format(tr("hud_fps_ping"), 60, 0)
RainbowHudLabel.TextSize = 16
RainbowHudLabel.TextStrokeTransparency = 0.25
RainbowHudLabel.TextStrokeColor3 = Color3.fromRGB(10, 10, 14)
RainbowHudLabel.Parent = FpsHudGui

local function createSettingRow(labelWidthScale, btnText, btnBg, onClick, refreshFn)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    row.BorderSizePixel = 0
    row.Parent = SettingsTab
    addCorner(row, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(labelWidthScale, -12, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextColor3 = Color3.fromRGB(210, 215, 230)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(56, 24)
    btn.Position = UDim2.new(1, -68, 0.5, -12)
    btn.BackgroundColor3 = btnBg
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.Text = btnText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Parent = row
    addCorner(btn, 6)
    addStroke(btn, Color3.fromRGB(150, 64, 214), 1.2, rainbowButtonStrokes)

    local function update()
        refreshFn(lbl, btn)
    end
    onLangChanged(update)
    btn.MouseButton1Click:Connect(function()
        onClick()
        update()
    end)
    return update
end

-- 1. Toggle Rainbow FPS & Ping
createSettingRow(0.68, "", Color3.fromRGB(150, 64, 214), function()
    rainbowHudEnabled = not rainbowHudEnabled
    FpsHudGui.Enabled = rainbowHudEnabled
    safeWrite(RAINBOW_HUD_CONFIG_FILE, tostring(rainbowHudEnabled))
end, function(lbl, btn)
    lbl.Text = tr("toggle_rainbow_hud")
    btn.Text = rainbowHudEnabled and tr("state_on") or tr("state_off")
    btn.BackgroundColor3 = rainbowHudEnabled and Color3.fromRGB(150, 64, 214) or Color3.fromRGB(55, 48, 68)
end)

-- 2. Position (Bottom / Top 20px)
local rainbowAtBottom = true
createSettingRow(0.72, "↕", Color3.fromRGB(150, 64, 214), function()
    rainbowAtBottom = not rainbowAtBottom
    if rainbowAtBottom then
        RainbowHudLabel.Position = UDim2.new(0.5, 0, 1, -20)
        RainbowHudLabel.AnchorPoint = Vector2.new(0.5, 1)
    else
        RainbowHudLabel.Position = UDim2.new(0.5, 0, 0, 20)
        RainbowHudLabel.AnchorPoint = Vector2.new(0.5, 0)
    end
end, function(lbl)
    lbl.Text = rainbowAtBottom and tr("hud_pos_bottom") or tr("hud_pos_top")
end)

-- 3. Font Size (16 / 22)
local rainbowLargeFont = false
createSettingRow(0.72, "A+", Color3.fromRGB(150, 64, 214), function()
    rainbowLargeFont = not rainbowLargeFont
    RainbowHudLabel.TextSize = rainbowLargeFont and 22 or 16
end, function(lbl)
    lbl.Text = rainbowLargeFont and tr("hud_size_large") or tr("hud_size_normal")
end)

-- 4. Toggle Mini Error Log
refreshMiniLogToggleVisual = createSettingRow(0.68, "", Color3.fromRGB(150, 64, 214), function()
    MiniFrame.Visible = not MiniFrame.Visible
end, function(lbl, btn)
    lbl.Text = tr("toggle_mini_log")
    btn.Text = MiniFrame.Visible and tr("state_on") or tr("state_off")
    btn.BackgroundColor3 = MiniFrame.Visible and Color3.fromRGB(150, 64, 214) or Color3.fromRGB(55, 48, 68)
end)

-- 5. Language Switcher
createSettingRow(0.68, "", Color3.fromRGB(150, 64, 214), function()
    setLang(currentLang == "vi" and "en" or "vi")
end, function(lbl, btn)
    lbl.Text = tr("setting_language")
    btn.Text = tr("lang_btn")
end)

-- 6. Reset Float Button Position (clamped & saved)
createSettingRow(0.72, "", Color3.fromRGB(45, 35, 55), function()
    local targetPos = getDefaultFloatPos()
    saveFloatPos(targetPos)
    TweenService:Create(FloatBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()
end, function(lbl, btn)
    lbl.Text = tr("btn_reset_float")
    btn.Text = tr("action_reset")
end)

-- ==================== RENDER LOOP ====================
local rainbowHue, fpsAcc, frameCnt, currentFps, currentPing = 0, 0, 0, 60, 0

RunService.RenderStepped:Connect(function(dt)
    rainbowHue = (rainbowHue + dt * 0.28) % 1
    local rainbowColor = Color3.fromHSV(rainbowHue, 0.85, 1)

    for _, s in ipairs(rainbowButtonStrokes) do
        if s and s.Parent then s.Color = rainbowColor end
    end
    for _, s in ipairs(rainbowFrameStrokes) do
        if s and s.Parent then s.Color = rainbowColor end
    end
    for _, g in ipairs(rainbowGlowImages) do
        if g and g.Parent then g.ImageColor3 = rainbowColor end
    end
    if rainbowHudEnabled and FpsHudGui.Enabled then
        RainbowHudLabel.TextColor3 = rainbowColor
    end

    frameCnt += 1
    fpsAcc += dt
    if fpsAcc >= 0.25 then
        currentFps = math.floor(frameCnt / fpsAcc + 0.5)
        frameCnt, fpsAcc = 0, 0

        pcall(function()
            currentPing = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)

        FpsVal.Text = currentFps .. " FPS"
        PingVal.Text = currentPing .. " ms"
        if rainbowHudEnabled then
            RainbowHudLabel.Text = string.format(tr("hud_fps_ping"), currentFps, currentPing)
        end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            HealthVal.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
            SpeedVal.Text = math.floor(hum.WalkSpeed)
        elseif char then
            HealthVal.Text, SpeedVal.Text = "N/A", "N/A"
        else
            HealthVal.Text, SpeedVal.Text = tr("not_spawned"), "0"
        end
    end
end)

print(tr("hub_ready"))
