-- Doors-Mode-Hub (Compact & Low-End Mobile Optimized)
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local FLOAT_BTN_SIZE, SCREEN_EDGE_MARGIN = 50, 6
local LANG_FILE, HUD_FILE, POS_FILE = "DoorsModeHub_Lang.txt", "DoorsModeHub_RainbowHUD.txt", "DoorsModeHub_FloatPos.txt"

local ALL_GUI_NAMES = {
	"Doors-Mode-Hub", "Doors-Mode-HubFloatingGUI", "Doors-Mode-HubRainbowFPS",
	"Voorpr0DiscordServerScript", "Voorpr0DiscordServerScriptFloatingGUI", "DoorsModeHub", "DoorsModeFloatingGUI"
}

local function cleanupGuis()
	for _, n in ipairs(ALL_GUI_NAMES) do
		local g = CoreGui:FindFirstChild(n)
		if g then g:Destroy() end
	end
end
cleanupGuis()

local Locales = {
	vi = {
		tab_doors = "Doors Mode", tab_discord = "ScriptIFoundItInDiscord", tab_unknown = "Unknown Doors Script",
		tab_misc = "Misc", tab_settings = "Settings", stat_loading = "Đang tải...", stat_fps = "⚡FPS:",
		stat_ping = "📶 Ping:", stat_health = "❤️ Health:", stat_speed = "🏃Speed:", not_spawned = "Chưa hồi sinh",
		hub_ready = "Doors-Mode-Hub đã sẵn sàng!", lang_btn = "VI", err_run = "Lỗi chạy %s: %s",
		err_norm = "Thường lỗi (%s): %s", err_repo = "Đăng lại lỗi (%s): %s", mini_title = "⚠️ Nhật ký lỗi",
		mini_clear = "Xóa", hud_fmt = "FPS: %d | Ping: %d ms", tgl_hud = "🌈 FPS & Ping cầu vồng",
		tgl_log = "📋 Bảng nhật ký lỗi mini", set_lang = "🌐 Ngôn ngữ (EN / VI)", pos_bot = "↕ Vị trí FPS & Ping: Dưới (20px)",
		pos_top = "↕ Vị trí FPS & Ping: Trên (20px)", sz_norm = "🔤 Cỡ chữ FPS & Ping: Vừa (16)",
		sz_lg = "🔤 Cỡ chữ FPS & Ping: Lớn (22)", rst_float = "🎯 Đặt lại vị trí nút nổi", act_rst = "Đặt lại",
		on = "BẬT", off = "TẮT", del_t = "⚠️ Xác nhận xóa", del_m = "Bạn có chắc muốn xóa toàn bộ Hub không?",
		del_y = "Xóa", del_n = "Hủy"
	},
	en = {
		tab_doors = "Doors Mode", tab_discord = "ScriptIFoundItInDiscord", tab_unknown = "Unknown Doors Script",
		tab_misc = "Misc", tab_settings = "Settings", stat_loading = "Loading...", stat_fps = "⚡FPS:",
		stat_ping = "📶 Ping:", stat_health = "❤️ Health:", stat_speed = "🏃Speed:", not_spawned = "Not Spawned",
		hub_ready = "Doors-Mode-Hub is ready!", lang_btn = "EN", err_run = "Error running %s: %s",
		err_norm = "Normal failed (%s): %s", err_repo = "Reposted failed (%s): %s", mini_title = "⚠️ Error Log",
		mini_clear = "Clear", hud_fmt = "FPS: %d | Ping: %d ms", tgl_hud = "🌈 Rainbow FPS & Ping",
		tgl_log = "📋 Mini Error Log Popup", set_lang = "🌐 Language (EN / VI)", pos_bot = "↕ FPS & Ping Position: Bottom (20px)",
		pos_top = "↕ FPS & Ping Position: Top (20px)", sz_norm = "🔤 FPS & Ping Font Size: Normal (16)",
		sz_lg = "🔤 FPS & Ping Font Size: Large (22)", rst_float = "🎯 Reset Float Button Position", act_rst = "Reset",
		on = "ON", off = "OFF", del_t = "⚠️ Confirm Delete", del_m = "Are you sure you want to completely delete the Hub?",
		del_y = "Delete", del_n = "Cancel"
	}
}

local function readCfg(f)
	if type(isfile) == "function" and type(readfile) == "function" then
		local ok, v = pcall(function() return isfile(f) and tostring(readfile(f)) or nil end)
		if ok then return v end
	end
end

local function writeCfg(f, v)
	if type(writefile) == "function" then
		pcall(function() writefile(f, tostring(v)) end)
	end
end

local lang = (function()
	local c = (readCfg(LANG_FILE) or ""):lower():gsub("%s+", "")
	if c == "vi" or c == "en" then return c end
	local loc = ""
	pcall(function() loc = tostring(LocalPlayer.LocaleId or ""):lower() end)
	return loc:sub(1, 2) == "vi" and "vi" or "en"
end)()

local rainbowHud = (function()
	local c = (readCfg(HUD_FILE) or ""):lower():gsub("%s+", "")
	if c == "false" or c == "0" or c == "off" then return false end
	if c == "true" or c == "1" or c == "on" then return true end
	return true
end)()

local function tr(k) return (Locales[lang] and Locales[lang][k]) or Locales.en[k] or k end
local function trf(k, ...) return string.format(tr(k), ...) end

local langCbs = {}
local function onLang(fn) table.insert(langCbs, fn); fn(lang) end
local function setLang(newLang)
	if not Locales[newLang] then return end
	lang = newLang
	writeCfg(LANG_FILE, lang)
	for _, fn in ipairs(langCbs) do pcall(fn, lang) end
end

local function getVp()
	local cam = workspace.CurrentCamera
	return (cam and cam.ViewportSize.X > 0 and cam.ViewportSize.Y > 0) and cam.ViewportSize or Vector2.new(1280, 720)
end

local function clampPos(udim, w, h)
	local vp = getVp()
	local x = math.clamp(math.floor(udim.X.Scale * vp.X + udim.X.Offset + 0.5), SCREEN_EDGE_MARGIN, math.max(SCREEN_EDGE_MARGIN, vp.X - w - SCREEN_EDGE_MARGIN))
	local y = math.clamp(math.floor(udim.Y.Scale * vp.Y + udim.Y.Offset + 0.5), SCREEN_EDGE_MARGIN, math.max(SCREEN_EDGE_MARGIN, vp.Y - h - SCREEN_EDGE_MARGIN))
	return UDim2.fromOffset(x, y)
end

local function defaultFloatPos()
	return clampPos(UDim2.new(1, -65, 0.5, -25), FLOAT_BTN_SIZE, FLOAT_BTN_SIZE)
end

local function saveFloatPos(udim)
	local c = clampPos(udim, FLOAT_BTN_SIZE, FLOAT_BTN_SIZE)
	writeCfg(POS_FILE, string.format("%.6f,%.2f,%.6f,%.2f", c.X.Scale, c.X.Offset, c.Y.Scale, c.Y.Offset))
end

local function loadFloatPos()
	local raw = readCfg(POS_FILE)
	if raw then
		local xs, xo, ys, yo = raw:match("^%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*$")
		xs, xo, ys, yo = tonumber(xs), tonumber(xo), tonumber(ys), tonumber(yo)
		if xs and xo and ys and yo then
			return clampPos(UDim2.new(xs, xo, ys, yo), FLOAT_BTN_SIZE, FLOAT_BTN_SIZE)
		end
	end
	return defaultFloatPos()
end

local btnStrokes, frameStrokes, glowImgs = {}, {}, {}
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p; return c end
local function stroke(p, col, th, list)
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness, s.ApplyStrokeMode, s.Parent = col, th or 1.2, Enum.ApplyStrokeMode.Border, p
	if list then table.insert(list, s) end
	return s
end

local function draggable(handle, target, onEnd, clampDims)
	local drag, inp, startP, startU
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag, startP, startU = true, i.Position, target.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End and drag then
					drag = false
					if onEnd then onEnd(target.Position) end
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then inp = i end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if i == inp and drag then
			local d = i.Position - startP
			local p = UDim2.new(startU.X.Scale, startU.X.Offset + d.X, startU.Y.Scale, startU.Y.Offset + d.Y)
			target.Position = clampDims and clampPos(p, clampDims.X, clampDims.Y) or p
		end
	end)
end

-- ==================== GUI & ERROR LOG ====================
local MainScreen = Instance.new("ScreenGui")
MainScreen.Name, MainScreen.ResetOnSpawn, MainScreen.ZIndexBehavior, MainScreen.Parent = "Doors-Mode-Hub", false, Enum.ZIndexBehavior.Sibling, CoreGui

local MiniFrame = Instance.new("Frame")
MiniFrame.Name, MiniFrame.Size, MiniFrame.Position, MiniFrame.BackgroundColor3, MiniFrame.Visible, MiniFrame.ZIndex, MiniFrame.Parent =
	"MiniErrorTab", UDim2.fromOffset(280, 145), UDim2.new(1, -295, 1, -160), Color3.fromRGB(20, 20, 26), false, 50, MainScreen
corner(MiniFrame, 8); stroke(MiniFrame, Color3.fromRGB(235, 80, 110), 1.2)

local MiniHeader = Instance.new("Frame")
MiniHeader.Size, MiniHeader.BackgroundColor3, MiniHeader.ZIndex, MiniHeader.Parent = UDim2.new(1, 0, 0, 28), Color3.fromRGB(30, 24, 36), 51, MiniFrame
corner(MiniHeader, 8); draggable(MiniHeader, MiniFrame)

local MiniTitle = Instance.new("TextLabel")
MiniTitle.Size, MiniTitle.Position, MiniTitle.BackgroundTransparency, MiniTitle.Font, MiniTitle.TextColor3, MiniTitle.TextSize, MiniTitle.TextXAlignment, MiniTitle.ZIndex, MiniTitle.Parent =
	UDim2.new(1, -85, 1, 0), UDim2.new(0, 10, 0, 0), 1, Enum.Font.GothamBold, Color3.fromRGB(255, 120, 140), 12, Enum.TextXAlignment.Left, 52, MiniHeader

local function hdrBtn(txt, xOff, bg, tc)
	local b = Instance.new("TextButton")
	b.Size, b.Position, b.BackgroundColor3, b.Font, b.Text, b.TextColor3, b.TextSize, b.ZIndex, b.Parent =
		UDim2.fromOffset(txt == "X" and 20 or 42, 20), UDim2.new(1, xOff, 0.5, -10), bg, Enum.Font.GothamBold, txt, tc, 11, 52, MiniHeader
	corner(b, 5); stroke(b, Color3.fromRGB(150, 64, 214), 1, btnStrokes)
	return b
end

local ClearBtn = hdrBtn("", -72, Color3.fromRGB(45, 35, 55), Color3.fromRGB(230, 230, 240))
local CloseMiniBtn = hdrBtn("X", -25, Color3.fromRGB(235, 80, 110), Color3.fromRGB(255, 255, 255))

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size, LogScroll.Position, LogScroll.BackgroundTransparency, LogScroll.CanvasSize, LogScroll.AutomaticCanvasSize, LogScroll.ScrollBarThickness, LogScroll.ZIndex, LogScroll.Parent =
	UDim2.new(1, -12, 1, -34), UDim2.new(0, 6, 0, 31), 1, UDim2.new(0, 0, 0, 0), Enum.AutomaticSize.Y, 2, 51, MiniFrame
local logList = Instance.new("UIListLayout"); logList.SortOrder, logList.Padding, logList.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 4), LogScroll

local refreshMiniLog
local function pushErr(msg)
	MiniFrame.Visible = true
	if refreshMiniLog then refreshMiniLog() end
	local lbl = Instance.new("TextLabel")
	lbl.Size, lbl.AutomaticSize, lbl.BackgroundColor3, lbl.Font, lbl.Text, lbl.TextColor3, lbl.TextSize, lbl.TextWrapped, lbl.TextXAlignment, lbl.ZIndex, lbl.Parent =
		UDim2.new(1, -4, 0, 0), Enum.AutomaticSize.Y, Color3.fromRGB(32, 26, 36), Enum.Font.Gotham, "• " .. tostring(msg), Color3.fromRGB(255, 190, 200), 11, true, Enum.TextXAlignment.Left, 52, LogScroll
	corner(lbl, 4)
	local pad = Instance.new("UIPadding"); pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom, pad.Parent = UDim.new(0, 6), UDim.new(0, 6), UDim.new(0, 4), UDim.new(0, 4), lbl
end

ClearBtn.MouseButton1Click:Connect(function()
	for _, c in ipairs(LogScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
end)
CloseMiniBtn.MouseButton1Click:Connect(function() MiniFrame.Visible = false; if refreshMiniLog then refreshMiniLog() end end)
onLang(function() MiniTitle.Text = tr("mini_title"); ClearBtn.Text = tr("mini_clear") end)

-- ==================== MAIN FRAME ====================
local normalSize = UDim2.fromOffset(580, 340)
local fullScreen, tabsHidden = false, false

local MainFrame = Instance.new("Frame")
MainFrame.Name, MainFrame.Size, MainFrame.Position, MainFrame.AnchorPoint, MainFrame.BackgroundColor3, MainFrame.Visible, MainFrame.ClipsDescendants, MainFrame.Parent =
	"MainFrame", UDim2.fromOffset(0, 0), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), Color3.fromRGB(18, 18, 22), false, true, MainScreen
corner(MainFrame, 10); stroke(MainFrame, Color3.fromRGB(150, 64, 214), 1.8, frameStrokes)

local GlowFrame = Instance.new("ImageLabel")
GlowFrame.Name, GlowFrame.BackgroundTransparency, GlowFrame.Size, GlowFrame.Position, GlowFrame.ZIndex, GlowFrame.Image, GlowFrame.ImageColor3, GlowFrame.ImageTransparency, GlowFrame.ScaleType, GlowFrame.SliceCenter, GlowFrame.Parent =
	"GlowEffect", 1, UDim2.new(1, 30, 1, 30), UDim2.new(0, -15, 0, -15), MainFrame.ZIndex - 1, "rbxassetid://6014261993", Color3.fromRGB(150, 64, 214), 0.35, Enum.ScaleType.Slice, Rect.new(49, 49, 450, 450), MainFrame
corner(GlowFrame, 14); stroke(GlowFrame, Color3.fromRGB(150, 64, 214), 1.5, frameStrokes); table.insert(glowImgs, GlowFrame)

local TopBar = Instance.new("Frame"); TopBar.Size, TopBar.BackgroundTransparency, TopBar.Parent = UDim2.new(1, 0, 0, 40), 1, MainFrame; draggable(TopBar, MainFrame)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size, TitleLabel.Position, TitleLabel.BackgroundTransparency, TitleLabel.Font, TitleLabel.Text, TitleLabel.RichText, TitleLabel.TextColor3, TitleLabel.TextSize, TitleLabel.TextXAlignment, TitleLabel.Parent =
	UDim2.new(1, -95, 1, 0), UDim2.new(0, 15, 0, 0), 1, Enum.Font.GothamBold, "🚪 <font color='#9640d6'>Doors-Mode-Hub</font>", true, Color3.fromRGB(240, 240, 245), 15, Enum.TextXAlignment.Left, TopBar

local LangBtn = Instance.new("TextButton")
LangBtn.Name, LangBtn.Size, LangBtn.Position, LangBtn.BackgroundColor3, LangBtn.AutoButtonColor, LangBtn.Font, LangBtn.TextColor3, LangBtn.TextSize, LangBtn.Parent =
	"LangButton", UDim2.fromOffset(64, 26), UDim2.new(1, -76, 0.5, -13), Color3.fromRGB(40, 28, 55), false, Enum.Font.GothamBold, Color3.fromRGB(255, 255, 255), 12, TopBar
corner(LangBtn, 6); stroke(LangBtn, Color3.fromRGB(150, 64, 214), 1.2, btnStrokes)
onLang(function() LangBtn.Text = "🌐 " .. tr("lang_btn") end)
LangBtn.MouseButton1Click:Connect(function() setLang(lang == "vi" and "en" or "vi") end)

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size, Sidebar.Position, Sidebar.BackgroundTransparency, Sidebar.CanvasSize, Sidebar.AutomaticCanvasSize, Sidebar.ScrollBarThickness, Sidebar.Parent =
	UDim2.new(0, 165, 1, -50), UDim2.new(0, 10, 0, 45), 1, UDim2.new(0, 0, 0, 0), Enum.AutomaticSize.Y, 0, MainFrame
local sideLayout = Instance.new("UIListLayout"); sideLayout.SortOrder, sideLayout.Padding, sideLayout.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 6), Sidebar
local sidePad = Instance.new("UIPadding"); sidePad.PaddingLeft, sidePad.PaddingTop, sidePad.PaddingBottom, sidePad.Parent = UDim.new(0, 2), UDim.new(0, 2), UDim.new(0, 4), Sidebar

local ContainerHolder = Instance.new("Frame"); ContainerHolder.Size, ContainerHolder.Position, ContainerHolder.BackgroundTransparency, ContainerHolder.Parent = UDim2.new(1, -190, 1, -50), UDim2.new(0, 180, 0, 45), 1, MainFrame
local TabHeaderBar = Instance.new("Frame"); TabHeaderBar.Name, TabHeaderBar.Size, TabHeaderBar.BackgroundTransparency, TabHeaderBar.ZIndex, TabHeaderBar.Parent = "TabControlsBar", UDim2.new(1, 0, 0, 26), 1, 10, ContainerHolder
local ctrlLayout = Instance.new("UIListLayout"); ctrlLayout.FillDirection, ctrlLayout.HorizontalAlignment, ctrlLayout.VerticalAlignment, ctrlLayout.SortOrder, ctrlLayout.Padding, ctrlLayout.Parent =
	Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center, Enum.SortOrder.LayoutOrder, UDim.new(0, 8), TabHeaderBar

local TabBodyHolder = Instance.new("Frame"); TabBodyHolder.Name, TabBodyHolder.Size, TabBodyHolder.Position, TabBodyHolder.BackgroundTransparency, TabBodyHolder.Parent = "TabBodyHolder", UDim2.new(1, 0, 1, -32), UDim2.new(0, 0, 0, 32), 1, ContainerHolder

local function ctrlBtn(sym, ord, col)
	local b = Instance.new("TextButton")
	b.Name, b.LayoutOrder, b.Size, b.BackgroundColor3, b.AutoButtonColor, b.Font, b.Text, b.TextColor3, b.TextSize, b.ZIndex, b.Parent =
		"Control_" .. sym, ord, UDim2.fromOffset(24, 24), Color3.fromRGB(32, 26, 44), false, Enum.Font.GothamBold, sym, col, 14, 11, TabHeaderBar
	corner(b, 6); stroke(b, Color3.fromRGB(150, 64, 214), 1.2, btnStrokes)
	return b
end

local MinusBtn = ctrlBtn("-", 1, Color3.fromRGB(220, 180, 255))
local PlusBtn = ctrlBtn("+", 2, Color3.fromRGB(110, 220, 160))
local CloseXBtn = ctrlBtn("x", 3, Color3.fromRGB(245, 90, 120))

local ConfirmMiniTab = Instance.new("Frame")
ConfirmMiniTab.Name, ConfirmMiniTab.Size, ConfirmMiniTab.Position, ConfirmMiniTab.AnchorPoint, ConfirmMiniTab.BackgroundColor3, ConfirmMiniTab.Visible, ConfirmMiniTab.ZIndex, ConfirmMiniTab.Parent =
	"DeleteConfirmMiniTab", UDim2.fromOffset(270, 125), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), Color3.fromRGB(22, 18, 28), false, 100, MainScreen
corner(ConfirmMiniTab, 10); stroke(ConfirmMiniTab, Color3.fromRGB(150, 64, 214), 1.6, frameStrokes)

local ConfirmTitle = Instance.new("TextLabel"); ConfirmTitle.Size, ConfirmTitle.Position, ConfirmTitle.BackgroundTransparency, ConfirmTitle.Font, ConfirmTitle.TextColor3, ConfirmTitle.TextSize, ConfirmTitle.TextXAlignment, ConfirmTitle.ZIndex, ConfirmTitle.Parent =
	UDim2.new(1, -20, 0, 26), UDim2.new(0, 10, 0, 8), 1, Enum.Font.GothamBold, Color3.fromRGB(255, 120, 145), 13, Enum.TextXAlignment.Left, 101, ConfirmMiniTab
local ConfirmMsg = Instance.new("TextLabel"); ConfirmMsg.Size, ConfirmMsg.Position, ConfirmMsg.BackgroundTransparency, ConfirmMsg.Font, ConfirmMsg.TextColor3, ConfirmMsg.TextSize, ConfirmMsg.TextWrapped, ConfirmMsg.TextXAlignment, ConfirmMsg.ZIndex, ConfirmMsg.Parent =
	UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 36), 1, Enum.Font.Gotham, Color3.fromRGB(225, 225, 235), 12, true, Enum.TextXAlignment.Left, 101, ConfirmMiniTab

local function cfmBtn(xs, xo, bg)
	local b = Instance.new("TextButton")
	b.Size, b.Position, b.BackgroundColor3, b.Font, b.TextColor3, b.TextSize, b.ZIndex, b.Parent =
		UDim2.new(0.5, -14, 0, 30), UDim2.new(xs, xo, 1, -40), bg, Enum.Font.GothamBold, Color3.fromRGB(255, 255, 255), 12, 101, ConfirmMiniTab
	corner(b, 7); stroke(b, Color3.fromRGB(150, 64, 214), 1.2, btnStrokes)
	return b
end
local YesDeleteBtn = cfmBtn(0, 10, Color3.fromRGB(220, 65, 95))
local NoCancelBtn = cfmBtn(0.5, 4, Color3.fromRGB(45, 38, 58))
onLang(function() ConfirmTitle.Text, ConfirmMsg.Text, YesDeleteBtn.Text, NoCancelBtn.Text = tr("del_t"), tr("del_m"), tr("del_y"), tr("del_n") end)

local function targetFrameSize()
	local vp = getVp()
	local w = fullScreen and math.max(320, vp.X - 20) or normalSize.X.Offset
	if tabsHidden then return UDim2.fromOffset(w, 76) end
	return UDim2.fromOffset(w, fullScreen and math.max(220, vp.Y - 20) or normalSize.Y.Offset)
end

MinusBtn.MouseButton1Click:Connect(function()
	tabsHidden = not tabsHidden
	Sidebar.Visible, TabBodyHolder.Visible = not tabsHidden, not tabsHidden
	TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = targetFrameSize()}):Play()
end)

PlusBtn.MouseButton1Click:Connect(function()
	if tabsHidden then tabsHidden = false; Sidebar.Visible, TabBodyHolder.Visible = true, true end
	fullScreen = not fullScreen
	TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {Size = targetFrameSize(), Position = UDim2.fromScale(0.5, 0.5)}):Play()
end)

CloseXBtn.MouseButton1Click:Connect(function() ConfirmMiniTab.Visible = true end)
NoCancelBtn.MouseButton1Click:Connect(function() ConfirmMiniTab.Visible = false end)
YesDeleteBtn.MouseButton1Click:Connect(cleanupGuis)

-- ==================== TABS & BUTTONS ====================
local tabs, activeTab = {}, nil
local function createTab(key)
	local sf = Instance.new("ScrollingFrame")
	sf.Name, sf.Size, sf.BackgroundTransparency, sf.CanvasSize, sf.AutomaticCanvasSize, sf.ScrollBarThickness, sf.Visible, sf.Parent =
		tr(key) .. "Content", UDim2.fromScale(1, 1), 1, UDim2.new(0, 0, 0, 0), Enum.AutomaticSize.Y, 3, false, TabBodyHolder
	local ll = Instance.new("UIListLayout"); ll.SortOrder, ll.Padding, ll.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 8), sf
	local pd = Instance.new("UIPadding"); pd.PaddingLeft, pd.PaddingRight, pd.PaddingTop, pd.PaddingBottom, pd.Parent = UDim.new(0, 2), UDim.new(0, 4), UDim.new(0, 2), UDim.new(0, 4), sf

	local tb = Instance.new("TextButton")
	tb.Size, tb.BackgroundColor3, tb.AutoButtonColor, tb.Font, tb.Text, tb.TextColor3, tb.TextSize, tb.TextWrapped, tb.Parent =
		UDim2.new(1, -4, 0, 34), Color3.fromRGB(24, 24, 30), false, Enum.Font.GothamMedium, tr(key), Color3.fromRGB(150, 155, 170), 12, true, Sidebar
	corner(tb, 8)
	local st = stroke(tb, Color3.fromRGB(150, 64, 214), 1.3, btnStrokes); st.Transparency = 0.55
	onLang(function() tb.Text = tr(key) end)

	tb.MouseButton1Click:Connect(function()
		for _, t in pairs(tabs) do
			t.content.Visible = false
			TweenService:Create(t.button, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(24, 24, 30), TextColor3 = Color3.fromRGB(150, 155, 170)}):Play()
			TweenService:Create(t.stroke, TweenInfo.new(0.18), {Transparency = 0.55}):Play()
		end
		sf.Visible = true
		TweenService:Create(tb, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(40, 28, 55), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		TweenService:Create(st, TweenInfo.new(0.18), {Transparency = 0}):Play()
		activeTab = key
	end)

	if not activeTab then
		sf.Visible, tb.BackgroundColor3, tb.TextColor3, st.Transparency, activeTab = true, Color3.fromRGB(40, 28, 55), Color3.fromRGB(255, 255, 255), 0, key
	end
	tabs[key] = {button = tb, content = sf, stroke = st}
	return sf
end

local function createBtn(tab, text, cb)
	local b = Instance.new("TextButton")
	b.Size, b.BackgroundColor3, b.Font, b.Text, b.TextColor3, b.TextSize, b.Parent =
		UDim2.new(1, 0, 0, 36), Color3.fromRGB(35, 24, 52), Enum.Font.GothamBold, text, Color3.fromRGB(255, 255, 255), 13, tab
	corner(b, 8); stroke(b, Color3.fromRGB(150, 64, 214), 1.3, btnStrokes)
	b.MouseButton1Click:Connect(function()
		local ok, err = pcall(cb)
		if not ok then pushErr(trf("err_run", text, tostring(err))) end
	end)
end

local function addUrlList(tab, list)
	for _, item in ipairs(list) do
		local lbl, url, flag = item[1], item[2], item[3]
		createBtn(tab, lbl, function()
			if flag then loadstring(game:HttpGet(url, true))() else loadstring(game:HttpGet(url))() end
		end)
	end
end

local DoorsTab = createTab("tab_doors")
addUrlList(DoorsTab, {
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

createBtn(DoorsTab, "Degenerate mode", function()
	task.spawn(function()
		local ok, err = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Not-Guestly/Modes/refs/heads/main/Degenerate-Mode-Made-By-Guestly", true))() end)
		if not ok then pushErr(trf("err_norm", "Degenerate mode", tostring(err))) end
	end)
	task.spawn(function()
		local ok, err = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Not-Guestly/Modes/refs/heads/main/Degenerate-Mode-Reposted"))() end)
		if not ok then pushErr(trf("err_repo", "Degenerate mode", tostring(err))) end
	end)
end)

local DiscordTab = createTab("tab_discord")
addUrlList(DiscordTab, {
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

createBtn(DiscordTab, "Egg", function()
	local tool = game:GetObjects("rbxassetid://74933357788345")[1]
	tool.Parent = LocalPlayer:WaitForChild("Backpack")
	local track
	tool.Equipped:Connect(function()
		local hum = (LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()):WaitForChild("Humanoid")
		local anim = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
		if track then track:Stop(0); track:Destroy() end
		local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://6516424098"
		track = anim:LoadAnimation(a); track.Priority, track.Looped = Enum.AnimationPriority.Action4, true
		track:Play(0, 1, 1); track:AdjustWeight(1)
	end)
	tool.Unequipped:Connect(function() if track then track:Stop(0); track:Destroy(); track = nil end end)
end)

local UnknownTab = createTab("tab_unknown")
addUrlList(UnknownTab, {
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

-- ==================== MISC & FLOAT BUTTON ====================
local MiscTab = createTab("tab_misc")
local function statRow(key)
	local f = Instance.new("Frame"); f.Size, f.BackgroundColor3, f.BorderSizePixel, f.Parent = UDim2.new(1, 0, 0, 38), Color3.fromRGB(28, 28, 35), 0, MiscTab; corner(f, 8)
	local tl = Instance.new("TextLabel"); tl.Size, tl.Position, tl.BackgroundTransparency, tl.Font, tl.Text, tl.TextColor3, tl.TextSize, tl.TextXAlignment, tl.Parent =
		UDim2.new(0.6, -12, 1, 0), UDim2.new(0, 12, 0, 0), 1, Enum.Font.GothamMedium, tr(key), Color3.fromRGB(210, 215, 230), 13, Enum.TextXAlignment.Left, f
	local vl = Instance.new("TextLabel"); vl.Size, vl.Position, vl.BackgroundTransparency, vl.Font, vl.Text, vl.TextColor3, vl.TextSize, vl.TextXAlignment, vl.Parent =
		UDim2.new(0.4, -12, 1, 0), UDim2.new(0.6, 0, 0, 0), 1, Enum.Font.GothamBold, tr("stat_loading"), Color3.fromRGB(150, 64, 214), 13, Enum.TextXAlignment.Right, f
	onLang(function()
		tl.Text = tr(key)
		if vl.Text == Locales.vi.stat_loading or vl.Text == Locales.en.stat_loading then vl.Text = tr("stat_loading") end
	end)
	return vl
end

local FpsVal, PingVal, HealthVal, SpeedVal = statRow("stat_fps"), statRow("stat_ping"), statRow("stat_health"), statRow("stat_speed")

local FloatGui = Instance.new("ScreenGui")
FloatGui.Name, FloatGui.ResetOnSpawn, FloatGui.ZIndexBehavior, FloatGui.DisplayOrder, FloatGui.Parent =
	"Doors-Mode-HubFloatingGUI", false, Enum.ZIndexBehavior.Sibling, 1001, CoreGui

local FloatBtn = Instance.new("ImageButton")
FloatBtn.Name, FloatBtn.Size, FloatBtn.Position, FloatBtn.BackgroundColor3, FloatBtn.AutoButtonColor, FloatBtn.Image, FloatBtn.ScaleType, FloatBtn.Parent =
	"FloatButton", UDim2.fromOffset(FLOAT_BTN_SIZE, FLOAT_BTN_SIZE), loadFloatPos(), Color3.fromRGB(35, 30, 48), false, "rbxassetid://6556477120", Enum.ScaleType.Crop, FloatGui
corner(FloatBtn, 25); stroke(FloatBtn, Color3.fromRGB(150, 64, 214), 2.2, btnStrokes)
draggable(FloatBtn, FloatBtn, saveFloatPos, Vector2.new(FLOAT_BTN_SIZE, FLOAT_BTN_SIZE))

local function hookVp()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if FloatBtn.Parent then FloatBtn.Position = clampPos(FloatBtn.Position, FLOAT_BTN_SIZE, FLOAT_BTN_SIZE) end
		end)
	end
end
hookVp(); workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookVp)

local hubOpen = false
FloatBtn.MouseButton1Click:Connect(function()
	hubOpen = not hubOpen
	if hubOpen then
		MainFrame.Visible, MainFrame.Size = true, UDim2.fromOffset(0, 0)
		TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = targetFrameSize()}):Play()
		TweenService:Create(FloatBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(150, 64, 214)}):Play()
	else
		ConfirmMiniTab.Visible = false
		local tw = TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 0)})
		tw:Play(); tw.Completed:Once(function() if not hubOpen then MainFrame.Visible = false end end)
		TweenService:Create(FloatBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(35, 30, 48)}):Play()
	end
end)

-- ==================== SETTINGS & HUD ====================
local SettingsTab = createTab("tab_settings")

local FpsHudGui = Instance.new("ScreenGui")
FpsHudGui.Name, FpsHudGui.ResetOnSpawn, FpsHudGui.ZIndexBehavior, FpsHudGui.DisplayOrder, FpsHudGui.Enabled, FpsHudGui.Parent =
	"Doors-Mode-HubRainbowFPS", false, Enum.ZIndexBehavior.Sibling, 1002, rainbowHud, CoreGui

local RainbowHudLabel = Instance.new("TextLabel")
RainbowHudLabel.Name, RainbowHudLabel.Size, RainbowHudLabel.Position, RainbowHudLabel.AnchorPoint, RainbowHudLabel.BackgroundTransparency, RainbowHudLabel.Font, RainbowHudLabel.Text, RainbowHudLabel.TextSize, RainbowHudLabel.TextStrokeTransparency, RainbowHudLabel.TextStrokeColor3, RainbowHudLabel.Parent =
	"RainbowHudLabel", UDim2.fromOffset(300, 30), UDim2.new(0.5, 0, 1, -20), Vector2.new(0.5, 1), 1, Enum.Font.GothamBlack, trf("hud_fmt", 60, 0), 16, 0.25, Color3.fromRGB(10, 10, 14), FpsHudGui

local function setRow(wScale, bTxt, bBg, fn, upd)
	local r = Instance.new("Frame"); r.Size, r.BackgroundColor3, r.BorderSizePixel, r.Parent = UDim2.new(1, 0, 0, 38), Color3.fromRGB(28, 28, 35), 0, SettingsTab; corner(r, 8)
	local l = Instance.new("TextLabel"); l.Size, l.Position, l.BackgroundTransparency, l.Font, l.TextColor3, l.TextSize, l.TextXAlignment, l.Parent =
		UDim2.new(wScale, -12, 1, 0), UDim2.new(0, 12, 0, 0), 1, Enum.Font.GothamMedium, Color3.fromRGB(210, 215, 230), 12, Enum.TextXAlignment.Left, r
	local b = Instance.new("TextButton"); b.Size, b.Position, b.BackgroundColor3, b.AutoButtonColor, b.Font, b.Text, b.TextColor3, b.TextSize, b.Parent =
		UDim2.fromOffset(56, 24), UDim2.new(1, -68, 0.5, -12), bBg, false, Enum.Font.GothamBold, bTxt, Color3.fromRGB(255, 255, 255), 11, r
	corner(b, 6); stroke(b, Color3.fromRGB(150, 64, 214), 1.2, btnStrokes)
	local function ref() upd(l, b) end
	onLang(ref)
	b.MouseButton1Click:Connect(function() fn(); ref() end)
	return ref
end

setRow(0.68, "", Color3.fromRGB(150, 64, 214), function()
	rainbowHud = not rainbowHud; FpsHudGui.Enabled = rainbowHud; writeCfg(HUD_FILE, tostring(rainbowHud))
end, function(l, b)
	l.Text, b.Text = tr("tgl_hud"), rainbowHud and tr("on") or tr("off")
	b.BackgroundColor3 = rainbowHud and Color3.fromRGB(150, 64, 214) or Color3.fromRGB(55, 48, 68)
end)

local atBot = true
setRow(0.72, "↕", Color3.fromRGB(150, 64, 214), function()
	atBot = not atBot
	RainbowHudLabel.Position = atBot and UDim2.new(0.5, 0, 1, -20) or UDim2.new(0.5, 0, 0, 20)
	RainbowHudLabel.AnchorPoint = atBot and Vector2.new(0.5, 1) or Vector2.new(0.5, 0)
end, function(l) l.Text = atBot and tr("pos_bot") or tr("pos_top") end)

local lgFont = false
setRow(0.72, "A+", Color3.fromRGB(150, 64, 214), function()
	lgFont = not lgFont; RainbowHudLabel.TextSize = lgFont and 22 or 16
end, function(l) l.Text = lgFont and tr("sz_lg") or tr("sz_norm") end)

refreshMiniLog = setRow(0.68, "", Color3.fromRGB(150, 64, 214), function()
	MiniFrame.Visible = not MiniFrame.Visible
end, function(l, b)
	l.Text, b.Text = tr("tgl_log"), MiniFrame.Visible and tr("on") or tr("off")
	b.BackgroundColor3 = MiniFrame.Visible and Color3.fromRGB(150, 64, 214) or Color3.fromRGB(55, 48, 68)
end)

setRow(0.68, "", Color3.fromRGB(150, 64, 214), function()
	setLang(lang == "vi" and "en" or "vi")
end, function(l, b) l.Text, b.Text = tr("set_lang"), tr("lang_btn") end)

setRow(0.72, "", Color3.fromRGB(45, 35, 55), function()
	local p = defaultFloatPos(); saveFloatPos(p)
	TweenService:Create(FloatBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = p}):Play()
end, function(l, b) l.Text, b.Text = tr("rst_float"), tr("act_rst") end)

-- ==================== LOOP ====================
local hue, colorAcc, fpsAcc, frames, fps, ping = 0, 0, 0, 0, 60, 0
local pingItem = StatsService and StatsService:FindFirstChild("Network") and StatsService.Network:FindFirstChild("ServerStatsItem") and StatsService.Network.ServerStatsItem:FindFirstChild("Data Ping")

RunService.RenderStepped:Connect(function(dt)
	hue = (hue + dt * 0.28) % 1
	colorAcc += dt
	if colorAcc >= 0.05 then
		colorAcc = 0
		local c = Color3.fromHSV(hue, 0.85, 1)
		for i = #btnStrokes, 1, -1 do local s = btnStrokes[i]; if s.Parent then s.Color = c else table.remove(btnStrokes, i) end end
		for i = #frameStrokes, 1, -1 do local s = frameStrokes[i]; if s.Parent then s.Color = c else table.remove(frameStrokes, i) end end
		for i = #glowImgs, 1, -1 do local g = glowImgs[i]; if g.Parent then g.ImageColor3 = c else table.remove(glowImgs, i) end end
		if rainbowHud and FpsHudGui.Enabled then RainbowHudLabel.TextColor3 = c end
	end

	frames += 1; fpsAcc += dt
	if fpsAcc >= 0.4 then
		fps = math.floor(frames / fpsAcc + 0.5); frames, fpsAcc = 0, 0
		if pingItem then pcall(function() ping = math.floor(pingItem:GetValue()) end) end
		FpsVal.Text, PingVal.Text = fps .. " FPS", ping .. " ms"
		if rainbowHud then RainbowHudLabel.Text = trf("hud_fmt", fps, ping) end

		local ch = LocalPlayer.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then
			HealthVal.Text, SpeedVal.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth), tostring(math.floor(hum.WalkSpeed))
		elseif ch then
			HealthVal.Text, SpeedVal.Text = "N/A", "N/A"
		else
			HealthVal.Text, SpeedVal.Text = tr("not_spawned"), "0"
		end
	end
end)

print(tr("hub_ready"))