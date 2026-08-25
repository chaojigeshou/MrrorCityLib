--!nolint
--[[═══════════════════════════════════════════════════════════════════════════
    ███╗   ███╗██████╗ ██████╗  ██████╗ ██████╗  ██████╗ ██╗████████╗██╗   ██╗
    ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗██║╚══██╔══╝╚██╗ ██╔╝
    ██╔████╔██║██████╔╝██████╔╝██║   ██║██████╔╝██║   ██║██║   ██║    ╚████╔╝
    ██║╚██╔╝██║██╔══██╗██╔══██╗██║   ██║██╔══██╗██║   ██║██║   ██║     ╚██╔╝
    ██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╔╝██║  ██║╚██████╔╝██║   ██║      ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝   ╚═╝      ╚═╝

    MrrorCityLib v0.8.0
    Roblox 脚本 UI 库 · 深色玻璃感 · 简洁圆角
    设计参考: LinoriaLib / Kavo / Orion (取各家优点, 见 README.md)

    - 仅依赖 Roblox 原生 API, Studio 与执行器均可运行
    - 单文件分发: loadstring(game:HttpGet("...source.lua", true))()
    - 特性: 双列布局 / 主题切换 / 配置多档案 / 通知(类型化+队列上限+点击回调) / 水印
          多选下拉(搜索/全选) / OptGroup 分组下拉 / 窗口缩放 / 分辨率适配 / Tab 图标滚动
          自定义控件注册 / 字体字号全局设置 / 动画开关 / 可折叠分组 / 勾选组 / 单选组
          Tooltip / 表格(Table) / 事件总线 / 全控件搜索过滤 / 多行输入 / 密码输入
          ColorPicker 透明度与预设色板
    - 配置升级: 版本迁移链 (_ConfigVersion + RegisterConfigMigration, 旧档自动升级)
═══════════════════════════════════════════════════════════════════════════]]

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--═══════════════════════════════════════════════════════════════════════════
-- 库对象
--═══════════════════════════════════════════════════════════════════════════

local Library = {}
Library.Version = "0.8.0"

--═══════════════════════════════════════════════════════════════════════════
-- 基础工具
--═══════════════════════════════════════════════════════════════════════════

-- 全局字体/字号/动画设置 (Library:SetStyle / Library:SetAnimation 可调整, 即时刷新)
Library.Fonts = { Text = Enum.Font.Gotham, Bold = Enum.Font.GothamBold }
Library.Settings = {
	TextSize = 13,
	SubSize = 12,
	SmallSize = 11,
	TitleSize = 14,
	HeaderSize = 12,
	Animate = true,
	ANIM = 0.15,
	MaxScreenRatio = 0.9, -- 窗口初始尺寸不超过视口比例 (分辨率适配)
	MaxNotifications = 5, -- 通知队列上限, 超过自动回收最旧
}

local function new(className, props, parent)
	local inst = Instance.new(className)
	if props then
		for key, value in pairs(props) do
			inst[key] = value
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

local function mapValue(value, inMin, inMax, outMin, outMax)
	return outMin + (value - inMin) / (inMax - inMin) * (outMax - outMin)
end

local function round(value, decimals)
	decimals = decimals or 0
	local factor = 10 ^ decimals
	return math.floor(value * factor + 0.5) / factor
end

local function formatNumber(value)
	if math.floor(value) == value then
		return tostring(math.floor(value))
	end
	local text = string.format("%.2f", value)
	text = text:gsub("0+$", ""):gsub("%.$", "")
	return text
end

local function getTextSize(text, size, font)
	return TextService:GetTextSize(text, size, font, Vector2.new(100000, 100000))
end

-- 复制字符串表 (防止配置/回调共享引用被外部改动)
local function cloneStrings(src)
	local out = {}
	if type(src) == "table" then
		for i = 1, #src do
			out[i] = tostring(src[i])
		end
	end
	return out
end

-- 文本过滤: object 自身或其任一后代文字层包含关键词 (不区分大小写, 普通子串匹配)
local function objectTextsMatch(object, keyword)
	if not object then
		return true
	end
	if keyword == "" then
		return true
	end
	local function matchText(txt)
		return type(txt) == "string" and string.find(string.lower(txt), keyword, 1, true) ~= nil
	end
	if matchText(object.Text) then
		return true
	end
	for _, desc in ipairs(object:GetDescendants()) do
		local cls = desc.ClassName
		if cls == "TextLabel" or cls == "TextButton" or cls == "TextBox" then
			if matchText(desc.Text) then
				return true
			end
		end
	end
	return false
end

-- 鼠标屏幕坐标(像素), 兼容无 GetMouseLocation 的旧环境
local function getMouseLocation()
	if UserInputService.GetMouseLocation then
		return UserInputService:GetMouseLocation()
	end
	local mouse = LocalPlayer and LocalPlayer:GetMouse()
	if mouse then
		return Vector2.new(mouse.X, mouse.Y)
	end
	return Vector2.zero
end

-- 当前视口像素尺寸 (无相机时回退 1920x1080)
local function getViewportSize()
	local camera = workspace and workspace.CurrentCamera
	return (camera and camera.ViewportSize) or Vector2.new(1920, 1080)
end

--═══════════════════════════════════════════════════════════════════════════
-- 颜色工具: Color3 <-> hex / HSV
--═══════════════════════════════════════════════════════════════════════════

local function hexToColor(value)
	if type(value) == "number" then
		local v = math.floor(value)
		return Color3.fromRGB(math.floor(v / 65536) % 256, math.floor(v / 256) % 256, v % 256)
	end
	local str = tostring(value):gsub("#", "")
	if #str == 6 then
		return Color3.fromRGB(
			tonumber(str:sub(1, 2), 16) or 255,
			tonumber(str:sub(3, 4), 16) or 255,
			tonumber(str:sub(5, 6), 16) or 255
		)
	end
	return Color3.new(1, 1, 1)
end

local function colorToHex(color)
	return string.format("#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function rgbToHsv(color)
	local r, g, b = color.R, color.G, color.B
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local delta = max - min
	local h = 0
	if delta ~= 0 then
		if max == r then
			h = ((g - b) / delta) % 6
		elseif max == g then
			h = (b - r) / delta + 2
		else
			h = (r - g) / delta + 4
		end
		h = h / 6
		if h < 0 then
			h = h + 1
		end
	end
	local s = (max == 0) and 0 or (delta / max)
	return h, s, max
end

local function hsvToRgb(h, s, v)
	h = h - math.floor(h)
	local i = math.floor(h * 6) % 6
	local f = h * 6 - math.floor(h * 6)
	local p = v * (1 - s)
	local q = v * (1 - s * f)
	local t = v * (1 - s * (1 - f))
	local r, g, b
	if i == 0 then
		r, g, b = v, t, p
	elseif i == 1 then
		r, g, b = q, v, p
	elseif i == 2 then
		r, g, b = p, v, t
	elseif i == 3 then
		r, g, b = p, q, v
	elseif i == 4 then
		r, g, b = t, p, v
	else
		r, g, b = v, p, q
	end
	return Color3.new(r, g, b)
end

-- 色相光谱渐变 (供色相条使用, 无需任何图片资源)
local HUE_SEQUENCE = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
	ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
})

--═══════════════════════════════════════════════════════════════════════════
-- 主题
--═══════════════════════════════════════════════════════════════════════════

-- 所有颜色都来自这里: 控件里禁止写死颜色, 主题切换/用户自定义才做得干净
Library.Themes = {
	Dark = {
		Name = "深色玻璃",
		-- 窗口
		Window = Color3.fromRGB(17, 18, 23),
		WindowTransparency = 0.06,
		Border = Color3.fromRGB(255, 255, 255),
		BorderTransparency = 0.88,
		Corner = 10,
		ElementCorner = 7,
		TitleText = Color3.fromRGB(240, 241, 248),
		SubtitleText = Color3.fromRGB(120, 125, 140),
		Divider = Color3.fromRGB(255, 255, 255),
		DividerTransparency = 0.93,
		-- 标签页
		TabSelected = Color3.fromRGB(0, 200, 255),
		TabSelectedText = Color3.fromRGB(12, 15, 22),
		TabUnselected = Color3.fromRGB(38, 41, 50),
		TabUnselectedTransparency = 0.55,
		TabUnselectedText = Color3.fromRGB(146, 151, 166),
		-- 分组
		Group = Color3.fromRGB(32, 34, 42),
		GroupTransparency = 0.25,
		GroupHeader = Color3.fromRGB(155, 160, 176),
		-- 控件
		Control = Color3.fromRGB(46, 49, 60),
		ControlTransparency = 0.38,
		ControlHover = Color3.fromRGB(58, 62, 75),
		ControlHoverTransparency = 0.22,
		ControlActive = Color3.fromRGB(66, 71, 85),
		ControlActiveTransparency = 0.28,
		Label = Color3.fromRGB(226, 229, 238),
		LabelSub = Color3.fromRGB(142, 147, 162),
		Accent = Color3.fromRGB(0, 200, 255),
		AccentDark = Color3.fromRGB(0, 152, 200),
		OnAccent = Color3.fromRGB(10, 13, 20),
		Danger = Color3.fromRGB(255, 86, 96),
		Success = Color3.fromRGB(70, 220, 130),
		Warning = Color3.fromRGB(255, 180, 60),
		Disabled = Color3.fromRGB(12, 13, 17),
		DisabledTransparency = 0.45,
		-- 通知
		Notify = Color3.fromRGB(24, 26, 33),
		NotifyTransparency = 0.08,
		NotifyText = Color3.fromRGB(235, 238, 246),
		-- 下拉/取色面板
		Dropdown = Color3.fromRGB(28, 30, 37),
		DropdownTransparency = 0.10,
	},
	Light = {
		Name = "浅色玻璃",
		Window = Color3.fromRGB(244, 246, 250),
		WindowTransparency = 0.05,
		Border = Color3.fromRGB(255, 255, 255),
		BorderTransparency = 0.80,
		Corner = 10,
		ElementCorner = 7,
		TitleText = Color3.fromRGB(30, 32, 40),
		SubtitleText = Color3.fromRGB(110, 115, 128),
		Divider = Color3.fromRGB(30, 32, 40),
		DividerTransparency = 0.90,
		TabSelected = Color3.fromRGB(0, 170, 230),
		TabSelectedText = Color3.fromRGB(255, 255, 255),
		TabUnselected = Color3.fromRGB(220, 224, 232),
		TabUnselectedTransparency = 0.60,
		TabUnselectedText = Color3.fromRGB(90, 95, 108),
		Group = Color3.fromRGB(233, 236, 242),
		GroupTransparency = 0.30,
		GroupHeader = Color3.fromRGB(105, 110, 122),
		Control = Color3.fromRGB(222, 226, 234),
		ControlTransparency = 0.45,
		ControlHover = Color3.fromRGB(208, 213, 224),
		ControlHoverTransparency = 0.30,
		ControlActive = Color3.fromRGB(198, 204, 216),
		ControlActiveTransparency = 0.30,
		Label = Color3.fromRGB(38, 40, 48),
		LabelSub = Color3.fromRGB(112, 117, 130),
		Accent = Color3.fromRGB(0, 170, 230),
		AccentDark = Color3.fromRGB(0, 130, 180),
		OnAccent = Color3.fromRGB(255, 255, 255),
		Danger = Color3.fromRGB(230, 70, 80),
		Success = Color3.fromRGB(45, 180, 100),
		Warning = Color3.fromRGB(230, 150, 40),
		Disabled = Color3.fromRGB(235, 237, 241),
		DisabledTransparency = 0.40,
		Notify = Color3.fromRGB(250, 251, 253),
		NotifyTransparency = 0.10,
		NotifyText = Color3.fromRGB(38, 40, 48),
		Dropdown = Color3.fromRGB(238, 240, 245),
		DropdownTransparency = 0.12,
	},
}
Library.Theme = Library.Themes.Dark

-- 全局样式: 字体/字号/动画时长 (合并进 Library.Fonts / Library.Settings, 即时刷新)
--   Library:SetStyle({ Font = Enum.Font.LuaGothic, FontBold = Enum.Font.LuaGothicBold,
--                      TextSize = 13, SubSize = 12, ANIM = 0.15 })
function Library:SetStyle(style)
	style = style or {}
	if style.Font ~= nil then
		Library.Fonts.Text = style.Font
	end
	if style.FontBold ~= nil then
		Library.Fonts.Bold = style.FontBold
	end
	for key, value in pairs(style) do
		if key ~= "Font" and key ~= "FontBold" then
			Library.Settings[key] = value
		end
	end
	-- 即时刷新: 控件 UpdateTheme 会重设字体/字号
	for _, element in ipairs(Library.Registry) do
		if element.UpdateTheme then
			element:UpdateTheme()
		end
	end
	-- [Lite10] 刷新全部窗口(主+子)
	if Library._Windows then
		for _, w in ipairs(Library._Windows) do
			if w._UpdateTheme then
				pcall(w._UpdateTheme, w)
			end
		end
	elseif Library._WindowRef and Library._WindowRef._UpdateTheme then
		Library._WindowRef:_UpdateTheme()
	end
end

-- 全局动画开关: false = 所有 Tween 立即落位
function Library:SetAnimation(enabled)
	Library.Settings.Animate = not not enabled
end

function Library:GetTheme()
	return Library.Theme
end

-- 切换主题: 字符串名 或 主题表
function Library:SetTheme(theme)
	if type(theme) == "string" then
		theme = Library.Themes[theme] or Library.Themes.Dark
	end
	if not theme then
		theme = Library.Themes.Dark
	end
	-- 字段缺失回退: 用深色主题补全, 防止 nil 赋值崩溃 (用户自定义主题可只写想改的字段)
	local base = Library.Themes.Dark
	if theme ~= base then
		for key, value in pairs(base) do
			if theme[key] == nil then
				theme[key] = value
			end
		end
	end
	Library.Theme = theme
	-- 自动记录主题名, 随配置持久化
	if type(theme) == "table" and theme.Name then
		for name, t in pairs(Library.Themes) do
			if t == theme then
				Library.Config._Theme = name
				break
			end
		end
	end
	-- 刷新所有控件
	for _, element in ipairs(Library.Registry) do
		if element.UpdateTheme then
			element:UpdateTheme()
		end
	end
	-- 刷新窗口本体
	if Library._Windows then
		for _, w in ipairs(Library._Windows) do
			if w._UpdateTheme then
				pcall(w._UpdateTheme, w)
			end
		end
	elseif Library._WindowRef and Library._WindowRef._UpdateTheme then
		Library._WindowRef:_UpdateTheme()
	end
	Library:fire("theme:changed", Library.Theme and Library.Theme.Name or "custom")
end

-- [Lite10] 动态主题: SetDynamicTheme(fn) — fn(时间/节日) 返回主题名或主题表
--   Library:SetDynamicTheme(function() return "Light" end)  — 返回"Dark"/"Light"或用主题表
--   Library:SetDynamicTheme(nil) 关闭
Library._DynamicTheme = nil
Library._DynamicThemeTimer = nil

function Library:SetDynamicTheme(fn)
	Library._DynamicTheme = type(fn) == "function" and fn or nil
	if Library._DynamicThemeTimer then
		task.cancel(Library._DynamicThemeTimer)
		Library._DynamicThemeTimer = nil
	end
	if not Library._DynamicTheme then
		return
	end
	-- 立即应用一次, 并每分钟刷新
	local function apply()
		if not Library._DynamicTheme then
			return
		end
		local ok, result = pcall(Library._DynamicTheme)
		if ok and result then
			Library:SetTheme(result)
		end
	end
	apply()
	Library._DynamicThemeTimer = task.spawn(function()
		while Library._DynamicTheme do
			task.wait(60)
			apply()
		end
	end)
end

--═══════════════════════════════════════════════════════════════════════════
-- 小工具: Tween / 鼠标 / 拖拽
--═══════════════════════════════════════════════════════════════════════════

function Library:Tween(object, goal, time, style, direction)
	-- 动画开关: 关闭时直接落位 (低端设备/追求利落)
	if Library.Settings.Animate == false then
		for key, value in pairs(goal) do
			object[key] = value
		end
		return nil
	end
	local tween = TweenService:Create(object,
		TweenInfo.new(time or Library.Settings.ANIM, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

function Library:IsMouseOver(object, padding)
	local mouse = getMouseLocation()
	local abs = object.AbsolutePosition
	local size = object.AbsoluteSize
	padding = padding or 0
	return mouse.X >= abs.X - padding
		and mouse.X <= abs.X + size.X + padding
		and mouse.Y >= abs.Y - padding
		and mouse.Y <= abs.Y + size.Y + padding
end

-- [Lite7] 通用交互动画: 给任意 GuiObject 挂 hover 背景过渡 (MouseEnter 提亮 / MouseLeave 还原)
--   hoverColor/hoverTransparency 可省略, 默认用主题 ControlHover / ControlHoverTransparency
--   动画时长 0.1s; Animate 关闭时直接落位. 返回一个可断开的连接表(Unload 自动清理由 Registry 负责).
function Library:AddHoverFx(frame, hoverColor, hoverTransparency, duration)
	if not frame or not frame:IsA("GuiObject") then
		return nil
	end
	local baseColor = frame.BackgroundColor3
	local baseTrans = frame.BackgroundTransparency
	local hColor = hoverColor or (Library.Theme.ControlHover or baseColor)
	local hTrans = hoverTransparency or (Library.Theme.ControlHoverTransparency or baseTrans)
	local dur = duration or 0.1
	if not Library.Settings.Animate then
		dur = 0
	end
	local enter = frame.MouseEnter:Connect(function()
		Library:Tween(frame, { BackgroundColor3 = hColor, BackgroundTransparency = hTrans }, dur)
	end)
	local leave = frame.MouseLeave:Connect(function()
		Library:Tween(frame, { BackgroundColor3 = baseColor, BackgroundTransparency = baseTrans }, dur)
	end)
	local conns = { enter, leave }
	table.insert(Library._GlobalConnections, enter)
	table.insert(Library._GlobalConnections, leave)
	return conns
end

-- [Lite10] 平滑滚动: 鼠标滚轮驱动 ScrollingFrame 平滑滚动 (tween 速度, 0.1 加速系数)
--   AddSmoothScroll(scrollingFrame, speed?) — speed 默认 40(像素/滚格), 自动夹紧 Canvas
local _smoothScrollConns = {}
function Library:AddSmoothScroll(scrollingFrame, speed)
	if not scrollingFrame or not scrollingFrame:IsA("ScrollingFrame") then
		return nil
	end
	speed = speed or 40
	local target = scrollingFrame.CanvasPosition.Y
	local curr = target
	local stepper = nil
	local function applyTarget()
		local maxY = math.max(0, scrollingFrame.AbsoluteCanvasSize.Y - scrollingFrame.AbsoluteSize.Y)
		target = math.clamp(target, 0, maxY)
	end
	local relConn = scrollingFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		applyTarget()
	end)
	local scrollConn = scrollingFrame.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end
		applyTarget()
		target = target - (input.Position.Z or 0) * speed
		applyTarget()
		if not stepper then
			stepper = task.spawn(function()
				while math.abs(curr - target) > 0.5 do
					curr = curr + (target - curr) * 0.25
					scrollingFrame.CanvasPosition = Vector2.new(scrollingFrame.CanvasPosition.X, curr)
					task.wait()
				end
				curr = target
				scrollingFrame.CanvasPosition = Vector2.new(scrollingFrame.CanvasPosition.X, curr)
				stepper = nil
			end)
		end
	end)
	table.insert(_smoothScrollConns, relConn)
	table.insert(_smoothScrollConns, scrollConn)
	table.insert(Library._GlobalConnections, relConn)
	table.insert(Library._GlobalConnections, scrollConn)
	return { relConn, scrollConn }
end

function Library:DisableSmoothScrolls()
	for _, c in ipairs(_smoothScrollConns) do
		pcall(function() c:Disconnect() end)
	end
	_smoothScrollConns = {}
end

-- 通用拖拽跟踪: onBegin(按下时的鼠标位置) -> onMove(每次移动) -> onEnd(松开)
-- isAllowed(可选): 返回 false 时不启动拖拽(例如避开子按钮)
function Library:TrackDrag(dragFrame, onBegin, onMove, onEnd, isAllowed)
	dragFrame.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if isAllowed and not isAllowed() then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		local mouse = getMouseLocation()
		if onBegin then
			onBegin(mouse)
		end
		local moved = UserInputService.InputChanged:Connect(function(ev)
			if ev.UserInputType == Enum.UserInputType.MouseMovement then
				if onMove then
					onMove(getMouseLocation())
				end
			end
		end)
		local ended = UserInputService.InputEnded:Connect(function(ev)
			if ev.UserInputType == Enum.UserInputType.MouseButton1 then
				-- [修复] 窗口/实例销毁时 ended/moved 可能已被前置断开或置 nil, 加防错
				if moved then
					moved:Disconnect()
					moved = nil
				end
				if ended then
					ended:Disconnect()
					ended = nil
				end
				if onEnd then
					onEnd()
				end
			end
		end)
	end)
end

--═══════════════════════════════════════════════════════════════════════════
-- 元素注册表 (主题刷新 / 配置恢复 / 卸载清理都靠它)
--═══════════════════════════════════════════════════════════════════════════

Library.Registry = {}
Library._GlobalConnections = {}
Library._GateListeners = {} -- 点击外部关闭下拉/取色面板的监听器
Library._OnUnloadCallbacks = {}
Library._ConfigLoadedCallbacks = {}
Library._BindingActive = false

function Library:Register(element)
	table.insert(Library.Registry, element)
	return element
end

function Library:Unregister(element)
	for i = #Library.Registry, 1, -1 do
		if Library.Registry[i] == element then
			table.remove(Library.Registry, i)
			return
		end
	end
end

-- 所有元素统一接口:
--   GetValue / SetVisible / Destroy / OnChanged / Emit / SetDisabled / UpdateTheme
local function newElement(typeName, object, callback)
	local el = {
		Type = typeName,
		Object = object,
		Callback = callback or nil,
		_Changed = {},
		Disabled = false,
		DefaultValue = nil, -- 工厂在创建时填入, ResetConfig 用
	}
	el.GetValue = function(self)
		return el.Value
	end
	el.SetVisible = function(self, visible)
		el.Object.Visible = visible
	end
	el.Destroy = function(self)
		Library:Unregister(el)
		if el.Object then
			el.Object:Destroy()
		end
	end
	-- 运行时追加回调: SetValue 非静默时触发 (与创建时 Callback 同语义)
	el.OnChanged = function(self, cb)
		table.insert(el._Changed, cb)
		return cb
	end
	-- 统一回调触发: 创建时 Callback + 运行时 OnChanged 全部调用
	el.Emit = function(self, value)
		if el.Callback then
			pcall(el.Callback, value)
		end
		for i = 1, #el._Changed do
			pcall(el._Changed[i], value)
		end
		Library:fire("element:changed", el.Type, value)
	end
	-- 禁用: 置灰遮罩 + 拦截输入 (各工厂在输入处理里检查 el.Disabled)
	el.SetDisabled = function(self, value)
		el.Disabled = not not value
		if el.Disabled then
			if not el._DisabledOverlay or not el._DisabledOverlay.Parent then
				el._DisabledOverlay = new("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = Library.Theme.Disabled,
					BackgroundTransparency = Library.Theme.DisabledTransparency,
					BorderSizePixel = 0,
					ZIndex = 50,
				}, el.Object)
				new("UICorner", { CornerRadius = UDim.new(0, Library.Theme.ElementCorner) }, el._DisabledOverlay)
			end
			el._DisabledOverlay.Visible = true
			el._DisabledOverlay.BackgroundColor3 = Library.Theme.Disabled
			el._DisabledOverlay.BackgroundTransparency = Library.Theme.DisabledTransparency
		elseif el._DisabledOverlay then
			el._DisabledOverlay.Visible = false
		end
	end
	Library:Register(el)
	return el
end

--═══════════════════════════════════════════════════════════════════════════
-- 自定义控件注册 (第三方扩展入口)
--   Library:RegisterCustomControl("MyControl", function(content, options, keyPrefix) return element end)
--   group:AddCustom("MyControl", {...})  或  group["AddMyControl"]({...})
--═══════════════════════════════════════════════════════════════════════════

Library._CustomControls = {}

function Library:RegisterCustomControl(controlName, build)
	if type(build) ~= "function" then
		warn("MrrorCityLib: RegisterCustomControl 需要 Build 函数")
		return nil
	end
	Library._CustomControls[controlName] = { Build = build }
	return controlName
end

-- [Lite10] 插件系统: 第三方扩展挂载 (tab/控件/事件)
--   Library:RegisterPlugin({Name="X", Version="1.0", OnInstall=function(window) ... end, OnUninstall=function() end})
--   窗口创建后自动安装; 库卸载时自动 OnUninstall
Library._Plugins = {}
Library._InstalledPlugins = {}

function Library:RegisterPlugin(plugin)
	if type(plugin) ~= "table" or type(plugin.Name) ~= "string" then
		warn("MrrorCityLib: RegisterPlugin 需要 {Name=..., ...}")
		return nil
	end
	table.insert(Library._Plugins, plugin)
	-- 若主窗口已存在, 立即安装
	if Library._WindowRef and type(plugin.OnInstall) == "function" then
		pcall(plugin.OnInstall, Library._WindowRef)
		Library._InstalledPlugins[plugin.Name] = true
	end
	Library:fire("plugin:registered", plugin)
	return plugin
end

function Library:InstallPlugins(win)
	win = win or Library._WindowRef
	if not win then
		return
	end
	for _, plugin in ipairs(Library._Plugins) do
		if not Library._InstalledPlugins[plugin.Name] and type(plugin.OnInstall) == "function" then
			pcall(plugin.OnInstall, win)
			Library._InstalledPlugins[plugin.Name] = true
		end
	end
end

function Library:UninstallPlugins()
	for name in pairs(Library._InstalledPlugins) do
		for _, plugin in ipairs(Library._Plugins) do
			if plugin.Name == name and type(plugin.OnUninstall) == "function" then
				pcall(plugin.OnUninstall)
			end
		end
	end
	Library._InstalledPlugins = {}
end

function Library:AddGateListener(fn)
	table.insert(Library._GateListeners, fn)
end

--═══════════════════════════════════════════════════════════════════════════
-- 事件总线: Library:on("event", cb) / once / off / fire
--   内置事件: "library:unload" "window:created" "theme:changed" "notify"
--             "config:loaded" "config:saved" "config:reset" "element:changed"
--═══════════════════════════════════════════════════════════════════════════

Library._EventBus = {}

function Library:on(eventName, callback)
	local list = Library._EventBus[eventName]
	if not list then
		list = {}
		Library._EventBus[eventName] = list
	end
	table.insert(list, callback)
	return callback
end

function Library:once(eventName, callback)
	local wrapped
	wrapped = function(...)
		Library:off(eventName, wrapped)
		callback(...)
	end
	return Library:on(eventName, wrapped)
end

function Library:off(eventName, callback)
	local list = Library._EventBus[eventName]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		if list[i] == callback then
			table.remove(list, i)
		end
	end
end

function Library:fire(eventName, ...)
	local list = Library._EventBus[eventName]
	if not list then
		return
	end
	for i = 1, #list do
		pcall(list[i], ...)
	end
end

--═══════════════════════════════════════════════════════════════════════════
-- 配置系统
--   运行时: Library.Config[配置键] = 值
--   保留键: _ToggleKey(全局显隐热键) / _WindowPosition(窗口位置) / _AutoSave
--   值只存可 JSON 序列化的类型: number / boolean / string / 纯表
--═══════════════════════════════════════════════════════════════════════════

Library.Config = {
	_ToggleKey = Enum.KeyCode.RightShift, -- [Lite7] 默认隐藏键: RightShift (可在UI芯片/SetToggleKey自定义)
	_Theme = "Dark",
	_WindowPosition = nil,
	_WindowSize = nil,
	_Profile = "default",
	_AutoSave = true,
	_Endpoint = nil, -- 可选: HTTP 配置后端 (GET 读取 / POST 保存)
	_ConfigVersion = nil, -- 配置格式版本 (由迁移系统维护, 见下)
}
Library.ConfigKeys = {}

function Library:RegisterConfigKey(key)
	Library.ConfigKeys[key] = true
end

--═══════════════════════════════════════════════════════════════════════════
-- 配置版本迁移 (向前兼容)
--   配置文件携带 _ConfigVersion 字段; 缺省(旧档无字段)视为 "1"
--   库升级导致配置结构变化时, 注册迁移链:
--     Library:RegisterConfigMigration("1", "2", function(cfg) ... return cfg end)
--   fn 可原地修改 cfg 或返回新表; LoadConfig/ImportConfig 时自动按序执行
--   迁移失败不阻断加载: LogError + 停在失败迁移 (已完成进度保留, 下次重试)
--═══════════════════════════════════════════════════════════════════════════

Library.ConfigVersion = "1" -- 当前配置格式版本 (独立于库版本; 结构变化才 bump)
Library._ConfigMigrations = {} -- { {From="1", To="2", Run=fn}, ... } From 升序

local function configVersionNum(v)
	local major, minor, patch = tostring(v):match("^(%d+)%.?(%d*)%.?(%d*)$")
	major = tonumber(major or "0") or 0
	minor = tonumber(minor or "0") or 0
	patch = tonumber(patch or "0") or 0
	return major * 1000000 + minor * 1000 + patch
end

-- 注册一条配置迁移: 老版本 From 的结构 → 新版本 To 的结构
function Library:RegisterConfigMigration(fromVersion, toVersion, run)
	if type(run) ~= "function" then
		warn("MrrorCityLib: RegisterConfigMigration 需要迁移函数 (3rd arg)")
		return false
	end
	local from, to = tostring(fromVersion), tostring(toVersion)
	if configVersionNum(from) >= configVersionNum(to) then
		warn("MrrorCityLib: RegisterConfigMigration 版本必须递增 (" .. from .. " → " .. to .. ")")
		return false
	end
	table.insert(Library._ConfigMigrations, { From = from, To = to, Run = run })
	table.sort(Library._ConfigMigrations, function(a, b)
		return configVersionNum(a.From) < configVersionNum(b.From)
	end)
	Library:fire("config:migrationRegistered", from, to)
	return true
end

-- 对解码后的配置表执行迁移; 返回 (cfg, 是否全部成功)
function Library:_ApplyConfigMigrations(data)
	if type(data) ~= "table" then
		return data, true
	end
	local oldVer = data._ConfigVersion
	if type(oldVer) ~= "string" or oldVer == "" then
		oldVer = "1"
	end
	local targetVer = Library.ConfigVersion or "1"
	if configVersionNum(oldVer) >= configVersionNum(targetVer) then
		data._ConfigVersion = targetVer -- 规范化字段 (旧档补写)
		return data, true
	end
	local ok = true
	for _, m in ipairs(Library._ConfigMigrations) do
		local fromNum, toNum = configVersionNum(m.From), configVersionNum(m.To)
		if fromNum >= configVersionNum(oldVer) and toNum <= configVersionNum(targetVer) then
			local runOk, res = pcall(m.Run, data)
			if runOk then
				if type(res) == "table" then
					data = res
				end
				data._ConfigVersion = m.To
				oldVer = m.To
				Library:fire("config:migrated", m.From, m.To)
			else
				Library:LogError("配置迁移 " .. m.From .. " → " .. m.To .. " 失败", res)
				ok = false
				break
			end
		end
	end
	if ok and configVersionNum(oldVer) < configVersionNum(targetVer) then
		-- 迁移链未覆盖到当前版本: 不虚报成功, 保留最后完成的版本号
		Library:fire("config:migrationGap", oldVer, targetVer)
	end
	return data, ok
end

local function hasWriteFile()
	return writefile ~= nil and readfile ~= nil and isfile ~= nil
end

-- 配置档案名规整 (只保留安全字符)
local function normalizeProfile(name)
	name = (name ~= nil) and tostring(name) or "default"
	name = name:gsub("[^%w_%-]", "_")
	if name == "" then
		name = "default"
	end
	return name
end

local function configPath(name)
	return "MrrorCityLib/config_" .. normalizeProfile(name) .. ".json"
end

local saveToken = 0

-- 防抖自动保存: 连续改动合并为一次写盘
function Library:_AutoSave()
	if not Library.Config._AutoSave then
		return
	end
	if not (hasWriteFile() or Library.Config._Endpoint) then
		return
	end
	saveToken = saveToken + 1
	local token = saveToken
	task.delay(0.6, function()
		if token == saveToken then
			Library:SaveConfig()
		end
	end)
end

function Library:SaveConfig(name)
	name = normalizeProfile(name)
	Library.Config._Profile = name
	local payload = {}
	for key, value in pairs(Library.Config) do
		if key:sub(1, 1) == "_" then
			if key == "_ToggleKey" and value ~= Enum.KeyCode.None then
				payload[key] = value.Name
			elseif key == "_ConfigVersion" and type(value) == "string" then
				payload[key] = value
			elseif key == "_WindowPosition" and type(value) == "table" then
				payload[key] = { x = value.x, y = value.y }
			elseif key == "_WindowSize" and type(value) == "table" then
				payload[key] = { w = value.w, h = value.h }
			elseif (key == "_Theme" or key == "_Profile") and type(value) == "string" then
				payload[key] = value
			end
		else
			payload[key] = value
		end
	end
	payload._ConfigVersion = payload._ConfigVersion or Library.ConfigVersion
	local json = HttpService:JSONEncode(payload)
	local ok = false
	if hasWriteFile() then
		ok = pcall(writefile, configPath(name), json)
	elseif Library.Config._Endpoint then
		ok = pcall(function()
			HttpService:RequestAsync({
				Url = Library.Config._Endpoint,
				Method = "POST",
				Body = json,
				Headers = { ["Content-Type"] = "application/json" },
			})
		end)
	end
	Library:fire("config:saved", ok)
	return ok
end

function Library:LoadConfig(name)
	name = normalizeProfile(name)
	local raw = nil
	if hasWriteFile() and isfile(configPath(name)) then
		raw = readfile(configPath(name))
	elseif Library.Config._Endpoint then
		pcall(function()
			local res = HttpService:RequestAsync({ Url = Library.Config._Endpoint, Method = "GET" })
			if res.Success then
				raw = res.Body
			end
		end)
	end
	if not raw then
		return false
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(data) ~= "table" then
		return false
	end

	-- [0) 配置版本迁移 (旧档 → 当前格式; 失败则不恢复, 保留旧档)
	local migrated, migrateOk = Library:_ApplyConfigMigrations(data)
	if not migrateOk then
		return false
	end
	data = migrated
	Library.Config._ConfigVersion = data._ConfigVersion

	-- 1) 逐个控件恢复(静默, 不触发回调), 记录变化
	local changes = {}
	for _, element in ipairs(Library.Registry) do
		local key = element.ConfigKey
		if key and data[key] ~= nil and element.SetValue then
			local before = element.Value
			element:SetValue(data[key], true)
			if element.Value ~= before then
				table.insert(changes, element)
			end
		end
	end

	-- 2) 窗口位置/尺寸
	local pos = data._WindowPosition
	if type(pos) == "table" and pos.x and pos.y and Library._WindowRef then
		Library._WindowRef.Object.Position = UDim2.fromOffset(pos.x, pos.y)
	end
	local sz = data._WindowSize
	if type(sz) == "table" and sz.w and sz.h and Library._WindowRef then
		Library._WindowRef:SetSize(sz.w, sz.h)
	end
	-- [Lite7] 窗口透明度恢复
	local trans = data._WindowTransparency
	if trans and Library._WindowRef then
		pcall(function()
			Library._WindowRef:SetTransparency(tonumber(trans) or 0)
		end)
	end

	-- 3) 全局热键
	local keyName = data._ToggleKey
	if type(keyName) == "string" then
		local keyOk, keyEnum = pcall(function()
			return Enum.KeyCode[keyName]
		end)
		if keyOk and keyEnum then
			Library.Config._ToggleKey = keyEnum
		end
	end

	-- 4) 主题
	if type(data._Theme) == "string" and Library.Themes[data._Theme] then
		Library:SetTheme(data._Theme)
	end

	-- 5) 值发生变化的控件依次回调一次 + 挂载 OnConfigLoaded
	for _, element in ipairs(changes) do
		if element.Callback then
			pcall(element.Callback, element.Value)
		end
		for i = 1, #element._Changed do
			pcall(element._Changed[i], element.Value)
		end
	end
	for _, cb in ipairs(Library._ConfigLoadedCallbacks) do
		pcall(cb)
	end
	Library:fire("config:loaded", true)
	return true
end

-- 恢复所有控件的默认值 (静默恢复, 变化者回调一次) 并保存
function Library:ResetConfig(name)
	local changes = {}
	for _, element in ipairs(Library.Registry) do
		if element.SetValue and element.DefaultValue ~= nil and element.ConfigKey then
			local before = element.Value
			element:SetValue(element.DefaultValue, true)
			if element.Value ~= before then
				table.insert(changes, element)
			end
		end
	end
	for _, element in ipairs(changes) do
		if element.Callback then
			pcall(element.Callback, element.Value)
		end
		for i = 1, #element._Changed do
			pcall(element._Changed[i], element.Value)
		end
	end
	Library:SaveConfig(name)
	Library:Notify("配置已重置", 3)
	Library:fire("config:reset", #changes)
	return #changes
end

function Library:OnConfigLoaded(callback)
	table.insert(Library._ConfigLoadedCallbacks, callback)
end

-- [Lite10] 配置导入/导出 (明文 JSON 文本, 可复制/粘贴分享):
--   ExportConfig(name) → 返回 JSON 字符串; ImportConfig(json, name) → 加载(与 LoadConfig 同路径)
--   纯文本 JSON, 含保留键(_ToggleKey/_Theme/_WindowPosition/_WindowSize/_WindowTransparency)
function Library:ExportConfig(name)
	name = name or Library.Config._Profile or "default"
	local payload = {
		_ConfigVersion = Library.Config._ConfigVersion or Library.ConfigVersion or "1",
	}
	for key, value in pairs(Library.Config) do
		if key:sub(1, 1) == "_" then
			if key == "_ToggleKey" and value ~= Enum.KeyCode.None then
				payload[key] = value.Name
			elseif key == "_ConfigVersion" then
				-- 已写入 header, 跳过
			elseif (key == "_Theme" or key == "_Profile") and type(value) == "string" then
				payload[key] = value
			elseif type(value) == "table" then
				payload[key] = value
			end
		else
			payload[key] = value
		end
	end
	local ok, json = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if ok and json then
		return json
	end
	return nil
end

function Library:ImportConfig(jsonText)
	if type(jsonText) ~= "string" or jsonText == "" then
		return false
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, jsonText)
	if not ok or type(data) ~= "table" then
		return false
	end
	-- 配置版本迁移 (与 LoadConfig 同路径; 失败则不导入)
	local migrated, migrateOk = Library:_ApplyConfigMigrations(data)
	if not migrateOk then
		return false
	end
	data = migrated
	-- 与 LoadConfig 相同恢复逻辑 (复用内部函数)
	local before = Library.Config
	Library.Config = before
	local changed = {}
	for key, value in pairs(data) do
		Library.Config[key] = value
	end
	-- 触发已注册控件; 窗口位置等由 LoadConfig 负责, 这里最小恢复
	if Library._WindowRef then
		local pos = data._WindowPosition
		if type(pos) == "table" and pos.x and pos.y then
			Library._WindowRef.Object.Position = UDim2.fromOffset(pos.x, pos.y)
		end
		local sz = data._WindowSize
		if type(sz) == "table" and sz.w and sz.h then
			pcall(function() Library._WindowRef:SetSize(sz.w, sz.h) end)
		end
		local trans = data._WindowTransparency
		if trans then
			pcall(function() Library._WindowRef:SetTransparency(tonumber(trans) or 0) end)
		end
	end
	local keyName = data._ToggleKey
	if type(keyName) == "string" then
		local keyOk, keyEnum = pcall(function() return Enum.KeyCode[keyName] end)
		if keyOk and keyEnum then
			Library.Config._ToggleKey = keyEnum
		end
	end
	if type(data._Theme) == "string" and Library.Themes[data._Theme] then
		Library:SetTheme(data._Theme)
	end
	-- 控件值恢复: 遍历 Registry 按 ConfigKey 匹配
	for _, element in ipairs(Library.Registry) do
		if element.ConfigKey and element.SetValue and Library.Config[element.ConfigKey] ~= nil then
			element:SetValue(Library.Config[element.ConfigKey], true)
		end
	end
	Library:SaveConfig()
	Library:fire("config:loaded", true)
	Library:Notify("配置已导入", 3)
	return true
end

--═══════════════════════════════════════════════════════════════════════════
-- 通知系统 (独立 ScreenGui, 窗口隐藏时通知仍然可见)
--═══════════════════════════════════════════════════════════════════════════

local NotifyGui = nil
local NotifyContainer = nil
local activeNotifies = {} -- 活跃通知队列 (FIFO, 超上限回收最旧)

local function removeFromNotifyQueue(group)
	for i = #activeNotifies, 1, -1 do
		if activeNotifies[i].Group == group then
			table.remove(activeNotifies, i)
			return
		end
	end
end

function Library:EnsureNotifyGui()
	if NotifyGui and NotifyGui.Parent then
		return
	end
	local parent = Library._Parent or CoreGui
	NotifyGui = new("ScreenGui", {
		Name = "MrrorCityLibNotifications",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	}, nil)
	local ok = pcall(function()
		NotifyGui.Parent = parent
	end)
	if not ok then
		NotifyGui.Parent = (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")) or CoreGui
	end
	NotifyContainer = new("Frame", {
		Name = "NotifyContainer",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(320, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, NotifyGui)
end

-- [Lite7] 通知位置切换: pos = "top-right" | "top-left" | "bottom-right" | "bottom-left"
Library.NotifyPositions = {
	["top-right"] = { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14) },
	["top-left"] = { AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 14, 0, 14) },
	["bottom-right"] = { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14) },
	["bottom-left"] = { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -14) },
}
function Library:SetNotifyPosition(pos)
	if not NotifyContainer then
		return false
	end
	local cfg = Library.NotifyPositions[pos or "top-right"]
	if not cfg then
		return false
	end
	NotifyContainer.AnchorPoint = cfg.AnchorPoint
	NotifyContainer.Position = cfg.Position
	return true
end

-- Library:Notify("文本", 5)
-- Library:Notify({ Title = "标题", Content = "内容", Duration = 5, Type = "success"|"error"|"warning"|"info" })
function Library:Notify(a, b)
	Library:EnsureNotifyGui()
	local text, duration, title, ntype
	if type(a) == "table" then
		title = a.Title
		text = a.Content or a.Text or ""
		duration = a.Duration or 5
		ntype = a.Type
	else
		text = a or ""
		duration = b or 5
	end

	local t = Library.Theme
	local typeColor = t.Accent
	if ntype == "success" then
		typeColor = t.Success
	elseif ntype == "error" then
		typeColor = t.Danger
	elseif ntype == "warning" then
		typeColor = t.Warning
	end
	local group = new("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 5,
	}, NotifyContainer)
	local inner = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = t.Notify,
		BackgroundTransparency = t.NotifyTransparency,
		BorderSizePixel = 0,
	}, group)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, inner)
	new("UIStroke", { Color = t.Border, Transparency = 0.90, Thickness = 1 }, inner)

	local row = new("Frame", {
		Size = UDim2.new(1, -48, 0, 0),
		Position = UDim2.new(0, 34, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, inner)
	local dot = new("Frame", {
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.new(0, 14, 0.5, -4),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = typeColor,
		BorderSizePixel = 0,
	}, inner)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2) }, row)
	if title then
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = t.NotifyText,
			TextSize = Library.Settings.TextSize,
			Font = Library.Fonts.Bold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		}, row)
	end
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = t.NotifyText,
		TextSize = Library.Settings.SubSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	}, row)
	new("UIPadding", { PaddingBottom = UDim.new(0, 10) }, inner)

	local scale = new("UIScale", { Scale = 0.96 }, group)
	Library:Tween(group, { GroupTransparency = 0 }, 0.3)
	Library:Tween(scale, { Scale = 1 }, 0.3)

	local function kill(immediately)
		removeFromNotifyQueue(group)
		if not group.Parent then
			return
		end
		Library:Tween(group, { GroupTransparency = 1 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(immediately and 0.02 or 0.28, function()
			if group.Parent then
				group:Destroy()
			end
		end)
	end

	table.insert(activeNotifies, { Group = group, Kill = kill })
	-- 队列上限: 超出则立即回收最旧的通知
	local maxNotify = Library.Settings.MaxNotifications or 5
	if #activeNotifies > maxNotify then
		local oldest = activeNotifies[1]
		removeFromNotifyQueue(oldest.Group)
		oldest.Kill(true)
	end

	group.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if type(a) == "table" and a.OnClick then
				pcall(a.OnClick)
			end
			kill(true)
		end
	end)
	task.delay(duration, function()
		kill()
	end)
	Library:fire("notify", text, ntype)
end

-- [Lite10] Toast: 居中大字提示 (重要操作反馈, 自动淡出, 点击立即消失)
local toastGui = nil
function Library:EnsureToastGui()
	if toastGui and toastGui.Parent then
		return toastGui
	end
	local parent = Library._Parent or CoreGui
	local ok = pcall(function()
		toastGui = new("ScreenGui", {
			Name = "MrrorCityLib_Toast",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
		}, parent)
	end)
	if not ok then
		toastGui = new("ScreenGui", {
			Name = "MrrorCityLib_Toast",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
		}, (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")) or CoreGui)
	end
	return toastGui
end
function Library:Toast(a, b)
	local gui = Library:EnsureToastGui()
	local text, subtitle, duration, ntype
	if type(a) == "table" then
		text = a.Content or a.Text or ""
		subtitle = a.Subtitle
		duration = a.Duration or 2.5
		ntype = a.Type
	else
		text = a or ""
		duration = b or 2.5
	end
	if text == "" then
		return
	end
	local t = Library.Theme
	local accent = Library.Theme.Accent
	if ntype == "error" then
		accent = Library.Theme.Danger
	elseif ntype == "warning" then
		accent = Library.Theme.Warning
	elseif ntype == "success" then
		accent = Library.Theme.Success
	end
	-- 居中大卡片
	local card = new("Frame", {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.38, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = t.Window,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ZIndex = 10,
	}, gui)
	new("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
	new("UIStroke", { Color = accent, Transparency = 0.35, Thickness = 2 }, card)
	new("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22) }, card)
	local txt = new("TextLabel", {
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = t.Label,
		TextSize = Library.Settings.TitleSize + 3,
		Font = Library.Fonts.Bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
		LayoutOrder = 1,
	}, card)
	if subtitle and subtitle ~= "" then
		new("TextLabel", {
			Size = UDim2.new(0, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = subtitle,
			TextColor3 = t.LabelSub,
			TextSize = Library.Settings.SubSize,
			Font = Library.Fonts.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			LayoutOrder = 2,
		}, card)
	end
	local cardScale = new("UIScale", { Scale = 0.9 }, card)
	local clickConn = card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if type(a) == "table" and a.OnClick then
				pcall(a.OnClick)
			end
			killToast()
		end
	end)
	local function killToast()
		if not card.Parent then
			return
		end
		pcall(function() clickConn:Disconnect() end)
		Library:Tween(cardScale, { Scale = 0.92 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Library:Tween(card, { BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.25, function()
			if card.Parent then
				card:Destroy()
			end
		end)
	end
	Library:Tween(cardScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay(duration, killToast)
	Library:fire("toast", text, ntype)
end

--═══════════════════════════════════════════════════════════════════════════
-- 水印 (属于主窗口, 隐藏窗口时一同隐藏)
--═══════════════════════════════════════════════════════════════════════════

local watermarkFrame = nil
local watermarkLabel = nil

function Library:SetWatermark(text)
	local win = Library._WindowRef
	if not win then
		return
	end
	if not watermarkFrame then
		watermarkFrame = new("Frame", {
			Size = UDim2.new(0, 0, 0, 14),
			Position = UDim2.new(0, 14, 0, 14),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
		}, win.Gui)
		local dot = new("Frame", {
			Size = UDim2.fromOffset(6, 6),
			Position = UDim2.new(0, 0, 0.5, -3),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Library.Theme.Accent,
			BorderSizePixel = 0,
			LayoutOrder = 1,
		}, watermarkFrame)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		watermarkLabel = new("TextLabel", {
			Size = UDim2.new(0, 0, 0, 14),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			TextSize = Library.Settings.SmallSize,
			Font = Library.Fonts.Text,
			TextColor3 = Library.Theme.LabelSub,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
		}, watermarkFrame)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Left, Padding = UDim.new(0, 8) }, watermarkFrame)
	end
	watermarkLabel.Text = text
end

function Library:SetWatermarkVisibility(visible)
	if watermarkFrame then
		watermarkFrame.Visible = visible
	end
end

--═══════════════════════════════════════════════════════════════════════════
-- [Lite10] 调试日志面板: Library:DebugLog(msg) 记录 | Library:ShowDebugLog() 弹出
--   独立小窗口(ChildKey 多窗口), 查看运行时消息, 供脚本排查
--═══════════════════════════════════════════════════════════════════════════

Library._DebugLogs = {}
Library._DebugLogGui = nil
Library._DebugLogContainer = nil

function Library:DebugLog(msg, level)
	local text = tostring(msg)
	local now = os.time()
	local stamp = os.date("%H:%M:%S", now)
	local entry = { time = stamp, text = text, level = level or "info" }
	table.insert(Library._DebugLogs, entry)
	-- 上限 200 条
	while #Library._DebugLogs > 200 do
		table.remove(Library._DebugLogs, 1)
	end
	if Library._DebugLogContainer then
		Library:RefreshDebugLogPanel()
	end
	Library:fire("debuglog", text, level)
end

function Library:RefreshDebugLogPanel()
	if not Library._DebugLogContainer then
		return
	end
	for _, c in ipairs(Library._DebugLogContainer:GetChildren()) do
		pcall(function() c:Destroy() end)
	end
	for i = #Library._DebugLogs, math.max(1, #Library._DebugLogs - 60), -1 do
		local e = Library._DebugLogs[i]
		local color = Library.Theme.LabelSub
		if e.level == "error" then
			color = Library.Theme.Danger
		elseif e.level == "warn" then
			color = Library.Theme.Warning
		end
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = e.time .. "  " .. e.text,
			TextColor3 = color,
			TextSize = Library.Settings.SmallSize,
			Font = Library.Fonts.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
		}, Library._DebugLogContainer)
	end
end

function Library:ShowDebugLog()
	if Library._DebugLogGui and Library._DebugLogGui.Gui and Library._DebugLogGui.Gui.Parent then
		pcall(function() Library._DebugLogGui:Destroy() end)
	end
	local win = Library:CreateWindow({
		Title = "调试日志",
		Subtitle = "DebugLog · 最近60条",
		Size = UDim2.fromOffset(420, 360),
		ChildKey = "debuglog",
	})
	Library._DebugLogGui = win
	local tab = win:AddTab({ Name = "日志" })
	local g = tab:AddLeftGroupbox("运行日志")
	Library._DebugLogContainer = g.Content
	Library:RefreshDebugLogPanel()
	win:SetVisible(true)
	return win
end

function Library:CloseDebugLog()
	if Library._DebugLogGui then
		pcall(function() Library._DebugLogGui:Destroy() end)
		Library._DebugLogGui = nil
	end
end

-- [Lite10] 全局错误记录: LogError(err, step) → DebugLog 面板 + fire("error") + 可选 Toast
function Library:LogError(err, step)
	local text = (step and ("[" .. tostring(step) .. "] ") or "") .. tostring(err)
	Library:DebugLog(text, "error")
	Library:fire("error", err, step)
	return text
end

-- [Lite10] pcallSafe: 带错误记录的 pcall (自动 LogError), 返回 ok, 结果...
function Library:pcallSafe(fn, step)
	local ok, res = pcall(fn)
	if not ok then
		Library:LogError(res, step)
	end
	return ok, res
end

--═══════════════════════════════════════════════════════════════════════════
-- Tooltip (Hover 提示): Library:AddTooltip(guiObject, text)
--   text 可为字符串 或 { Title = "标题", Content = "内容" }
--   跟随鼠标, 自动夹紧屏幕; 点击任意处隐藏; 挂 Tooltip 的元素被销毁后随点击收起
--═══════════════════════════════════════════════════════════════════════════

local TooltipGui = nil
local TooltipFrame = nil
local TooltipTitle = nil
local TooltipContent = nil
local TooltipTarget = nil

local function positionTooltip(mouse)
	if not TooltipFrame then
		return
	end
	local viewport = getViewportSize()
	local w = TooltipFrame.AbsoluteSize.X
	local h = TooltipFrame.AbsoluteSize.Y
	TooltipFrame.Position = UDim2.fromOffset(
		clamp(mouse.X + 18, 4, math.max(4, viewport.X - w - 4)),
		clamp(mouse.Y + 18, 4, math.max(4, viewport.Y - h - 4))
	)
end

function Library:EnsureTooltipGui()
	if TooltipGui and TooltipGui.Parent then
		return
	end
	local parent = Library._Parent or CoreGui
	TooltipGui = new("ScreenGui", {
		Name = "MrrorCityLibTooltip",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	}, nil)
	local ok = pcall(function()
		TooltipGui.Parent = parent
	end)
	if not ok then
		TooltipGui.Parent = (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")) or CoreGui
	end
	TooltipFrame = new("Frame", {
		Size = UDim2.fromOffset(240, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Library.Theme.Notify,
		BackgroundTransparency = Library.Theme.NotifyTransparency,
		BorderSizePixel = 0,
		ZIndex = 100,
		Visible = false,
	}, TooltipGui)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, TooltipFrame)
	new("UIStroke", { Color = Library.Theme.Border, Transparency = 0.85, Thickness = 1 }, TooltipFrame)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, TooltipFrame)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, TooltipFrame)
	TooltipTitle = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Library.Theme.NotifyText,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Bold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, TooltipFrame)
	TooltipContent = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Library.Theme.NotifyText,
		TextSize = Library.Settings.SubSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	}, TooltipFrame)
	-- 跟随鼠标 (全局仅连接一次)
	if not Library._TooltipConnected then
		Library._TooltipConnected = true
		local moveConn = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			if TooltipTarget and TooltipFrame and TooltipFrame.Visible then
				positionTooltip(getMouseLocation())
			end
		end)
		table.insert(Library._GlobalConnections, moveConn)
		local clickConn = UserInputService.InputBegan:Connect(function()
			if TooltipFrame and TooltipFrame.Visible then
				TooltipFrame.Visible = false
			end
		end)
		table.insert(Library._GlobalConnections, clickConn)
	end
end

function Library:AddTooltip(object, text)
	if not object then
		return
	end
	object.MouseEnter:Connect(function()
		TooltipTarget = object
		Library:EnsureTooltipGui()
		if type(text) == "table" then
			TooltipTitle.Text = text.Title or ""
			TooltipTitle.Visible = (text.Title ~= nil and text.Title ~= "")
			TooltipContent.Text = text.Content or ""
		else
			TooltipTitle.Text = ""
			TooltipTitle.Visible = false
			TooltipContent.Text = tostring(text or "")
		end
		TooltipFrame.Visible = true
		positionTooltip(getMouseLocation())
	end)
	object.MouseLeave:Connect(function()
		if TooltipTarget == object then
			TooltipTarget = nil
			if TooltipFrame then
				TooltipFrame.Visible = false
			end
		end
	end)
end

--═══════════════════════════════════════════════════════════════════════════
-- 卸载: 断开全局监听 + 销毁所有 UI
--═══════════════════════════════════════════════════════════════════════════

function Library:OnUnload(callback)
	table.insert(Library._OnUnloadCallbacks, callback)
end

function Library:Unload()
	Library:fire("library:unload")
	if Library._BindingActive then
		Library._BindingActive = false
	end
	for _, conn in ipairs(Library._GlobalConnections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	Library._GlobalConnections = {}
	Library._GateListeners = {}
	-- [Lite10] 销毁全部窗口(主窗口 + 子窗口), 兼容旧 _WindowRef
	local windowsToKill = {}
	if Library._Windows then
		for _, w in ipairs(Library._Windows) do
			windowsToKill[#windowsToKill + 1] = w
		end
	elseif Library._WindowRef then
		windowsToKill[1] = Library._WindowRef
	end
	for _, w in ipairs(windowsToKill) do
		pcall(function()
			if w and w.Gui then
				w.Gui:Destroy()
			end
		end)
	end
	Library._Windows = {}
	Library._WindowRef = nil
	if NotifyGui then
		pcall(function()
			NotifyGui:Destroy()
		end)
		NotifyGui = nil
		NotifyContainer = nil
		activeNotifies = {}
	end
	if TooltipGui then
		pcall(function()
			TooltipGui:Destroy()
		end)
		TooltipGui = nil
		TooltipFrame = nil
		TooltipTitle = nil
		TooltipContent = nil
		TooltipTarget = nil
	end
	watermarkFrame = nil
	watermarkLabel = nil
	-- [Lite10] 卸载插件(OnUninstall 钩子)
	pcall(function()
		Library:UninstallPlugins()
	end)
	-- 允许下次 CreateWindow 重新注册全局连接
	Library._HotkeyConnected = nil
	Library._GateConnected = nil
	Library.Registry = {}
	for _, cb in ipairs(Library._OnUnloadCallbacks) do
		pcall(cb)
	end
	Library._OnUnloadCallbacks = {}
end

--═══════════════════════════════════════════════════════════════════════════
-- 切换窗口显隐 (配合全局热键)
--═══════════════════════════════════════════════════════════════════════════

function Library:Toggle()
	local win = Library._WindowRef
	if not win then
		return
	end
	local gui = win.Gui
	if not gui then
		return
	end
	-- [Lite7修复] 显隐动画: 用 UIScale 缩放过渡 (ScreenGui.GroupTransparency 部分客户端不支持)
	if gui.Enabled then
		-- 隐藏: 先缩到 0.9, 完后再关 Enabled
		if Library.Settings.Animate and win.Object then
			local ws = win.Object:FindFirstChildOfClass("UIScale")
			if not ws then
				ws = Instance.new("UIScale")
				ws.Parent = win.Object
			end
			pcall(function()
				Library:Tween(ws, { Scale = 0.9 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end)
			task.delay(0.16, function()
				if not win.Gui then return end
				win.Gui.Enabled = false
				pcall(function()
					ws.Scale = 1
				end)
				win._Visible = false
			end)
		else
			gui.Enabled = false
			win._Visible = false
		end
	else
		-- 显示: 缩到 0.9 再弹回 1
		gui.Enabled = true
		if Library.Settings.Animate and win.Object then
			local ws = win.Object:FindFirstChildOfClass("UIScale")
			if not ws then
				ws = Instance.new("UIScale")
				ws.Parent = win.Object
			end
			pcall(function()
				ws.Scale = 0.92
				Library:Tween(ws, { Scale = 1 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end)
		end
		win._Visible = true
	end
end

--═══════════════════════════════════════════════════════════════════════════
-- 颜色转换入口: 接受 Color3 / 数字 / "#RRGGBB"
--═══════════════════════════════════════════════════════════════════════════

function Library:ConvertColor(value)
	if typeof(value) == "Color3" then
		return value
	end
	return hexToColor(value)
end

--═══════════════════════════════════════════════════════════════════════════
-- 控件工厂
--   签名统一: factory(content, options, keyPrefix) -> element
--   keyPrefix = "标签页/分组", 用于生成默认配置键: 标签页/分组/控件名
--═══════════════════════════════════════════════════════════════════════════

-- ---- Button ----
local function addButton(content, options, keyPrefix)
	local name = options.Name or "Button"
	local root = new("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Library.Theme.Control,
		BackgroundTransparency = Library.Theme.ControlTransparency,
		BorderSizePixel = 0,
	}, content)
	new("UICorner", { CornerRadius = UDim.new(0, Library.Theme.ElementCorner) }, root)
	local label = new("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)

	local el = newElement("Button", root, options.Callback)
	el.Value = true

	root.MouseEnter:Connect(function()
		Library:Tween(root, {
			BackgroundColor3 = Library.Theme.ControlHover,
			BackgroundTransparency = Library.Theme.ControlHoverTransparency,
		})
	end)
	root.MouseLeave:Connect(function()
		Library:Tween(root, {
			BackgroundColor3 = Library.Theme.Control,
			BackgroundTransparency = Library.Theme.ControlTransparency,
		})
	end)
	root.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if el.Disabled then
			return
		end
		Library:Tween(root, { BackgroundColor3 = Library.Theme.AccentDark }, 0.08)
		task.delay(0.12, function()
			if root.Parent then
				Library:Tween(root, {
					BackgroundColor3 = Library.Theme.ControlHover,
					BackgroundTransparency = Library.Theme.ControlHoverTransparency,
				})
			end
		end)
		el:Emit()
	end)

	el.UpdateTheme = function(self)
		label.TextColor3 = Library.Theme.Label
		label.Font = Library.Fonts.Text
		label.TextSize = Library.Settings.TextSize
		root.BackgroundColor3 = Library.Theme.Control
		root.BackgroundTransparency = Library.Theme.ControlTransparency
	end
	return el
end

-- ---- Toggle ----
local function addToggle(content, options, keyPrefix)
	local name = options.Name or "Toggle"
	local root = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 }, content)
	-- [Lite7] 交互动画: 行 hover 轻微提亮 (透明基值, 悬停时染 ControlHover)
	do
		local baseColor, baseTrans = root.BackgroundColor3, root.BackgroundTransparency
		root.BackgroundColor3 = Library.Theme.ControlHover
		root.BackgroundTransparency = 1 -- 基值: 全透明
		local eEnter = root.MouseEnter:Connect(function()
			Library:Tween(root, { BackgroundColor3 = Library.Theme.ControlHover, BackgroundTransparency = Library.Theme.ControlHoverTransparency }, 0.08)
		end)
		local eLeave = root.MouseLeave:Connect(function()
			Library:Tween(root, { BackgroundColor3 = baseColor, BackgroundTransparency = 1 }, 0.08)
		end)
		table.insert(Library._GlobalConnections, eEnter)
		table.insert(Library._GlobalConnections, eLeave)
	end
	local label = new("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local bg = new("Frame", {
		Size = UDim2.fromOffset(40, 20),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Library.Theme.ControlActive,
		BackgroundTransparency = Library.Theme.ControlActiveTransparency,
		BorderSizePixel = 0,
	}, root)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, bg)
	local knob = new("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}, bg)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local el = newElement("Toggle", root, options.Callback)
	el.ConfigKey = options.ConfigKey or (keyPrefix .. "/" .. name)
	Library:RegisterConfigKey(el.ConfigKey)
	el.Value = false
	el.DefaultValue = not not (options.Default or false)

	local function paint()
		local on = el.Value
		Library:Tween(knob, { Position = UDim2.new(0, on and 22 or 2, 0.5, 0) })
		Library:Tween(bg, {
			BackgroundColor3 = on and Library.Theme.Accent or Library.Theme.ControlActive,
			BackgroundTransparency = on and 0 or Library.Theme.ControlActiveTransparency,
		})
	end
	el.SetValue = function(self, v, silent)
		el.Value = not not v
		paint()
		if el.ConfigKey then
			Library.Config[el.ConfigKey] = el.Value
		end
		if not silent then
			el:Emit(el.Value)
			Library:_AutoSave()
		end
	end
	root.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if el.Disabled then
			return
		end
		el:SetValue(not el.Value)
	end)
	el:SetValue(options.Default or false, true)

	el.UpdateTheme = function(self)
		label.TextColor3 = Library.Theme.Label
		label.Font = Library.Fonts.Text
		label.TextSize = Library.Settings.TextSize
		paint()
	end
	return el
end

-- ---- Slider ----
local function addSlider(content, options, keyPrefix)
	local name = options.Name or "Slider"
	local minV = options.Min or 0
	local maxV = options.Max or 100
	local defaultV = clamp((options.Default ~= nil) and options.Default or minV, minV, maxV)
	local suffix = options.Suffix or ""
	local decimals = options.Decimals

	local root = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 }, content)
	-- [Lite7] 交互动画: 行 hover 轻微提亮
	do
		local baseColor, baseTrans = root.BackgroundColor3, root.BackgroundTransparency
		root.BackgroundColor3 = Library.Theme.ControlHover
		local eEnter = root.MouseEnter:Connect(function()
			Library:Tween(root, { BackgroundColor3 = Library.Theme.ControlHover, BackgroundTransparency = Library.Theme.ControlHoverTransparency }, 0.08)
		end)
		local eLeave = root.MouseLeave:Connect(function()
			Library:Tween(root, { BackgroundColor3 = baseColor, BackgroundTransparency = baseTrans }, 0.08)
		end)
		table.insert(Library._GlobalConnections, eEnter)
		table.insert(Library._GlobalConnections, eLeave)
	end
	local label = new("TextLabel", {
		Size = UDim2.new(1, -90, 0, 20),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local valueText = new("TextLabel", {
		Size = UDim2.new(0, 80, 0, 20),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Library.Theme.LabelSub,
		TextSize = Library.Settings.SubSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local bar = new("Frame", {
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 0, 26),
		BackgroundColor3 = Library.Theme.ControlActive,
		BackgroundTransparency = Library.Theme.ControlActiveTransparency,
		BorderSizePixel = 0,
	}, root)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Library.Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, bar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	local handle = new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, bar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, handle)

	local el = newElement("Slider", root, options.Callback)
	el.ConfigKey = options.ConfigKey or (keyPrefix .. "/" .. name)
	Library:RegisterConfigKey(el.ConfigKey)
	el.Value = defaultV
	el.DefaultValue = defaultV

	local function getDisplay(v)
		if decimals then
			return formatNumber(round(v, decimals)) .. suffix
		end
		return formatNumber(v) .. suffix
	end
	local function paint()
		local pct = clamp((el.Value - minV) / (maxV - minV), 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		handle.Position = UDim2.new(pct, 0, 0.5, 0)
		valueText.Text = getDisplay(el.Value)
	end
	local function dragMove(mouse)
		local width = bar.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local pct = clamp((mouse.X - bar.AbsolutePosition.X) / width, 0, 1)
		el:SetValue(minV + pct * (maxV - minV))
	end
	el.SetValue = function(self, v, silent)
		v = clamp(tonumber(v) or minV, minV, maxV)
		el.Value = v
		paint()
		if el.ConfigKey then
			Library.Config[el.ConfigKey] = v
		end
		if not silent then
			el:Emit(v)
			Library:_AutoSave()
		end
	end
	Library:TrackDrag(bar, dragMove, dragMove, nil, function()
		return not el.Disabled
	end)
	el:SetValue(defaultV, true)

	el.UpdateTheme = function(self)
		label.TextColor3 = Library.Theme.Label
		label.Font = Library.Fonts.Text
		label.TextSize = Library.Settings.TextSize
		valueText.TextColor3 = Library.Theme.LabelSub
		valueText.Font = Library.Fonts.Text
		valueText.TextSize = Library.Settings.SubSize
		bar.BackgroundColor3 = Library.Theme.ControlActive
		bar.BackgroundTransparency = Library.Theme.ControlActiveTransparency
		fill.BackgroundColor3 = Library.Theme.Accent
		paint()
	end
	return el
end

-- ---- Dropdown (单选 / 多选 / 搜索 / 全选清空) ----
local function addDropdown(content, options, keyPrefix)
	local multi = options.Multi and true or false
	local name = options.Name or (multi and "多选" or "Dropdown")
	local root = new("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Library.Theme.Control,
		BackgroundTransparency = Library.Theme.ControlTransparency,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, content)
	new("UICorner", { CornerRadius = UDim.new(0, Library.Theme.ElementCorner) }, root)
	local label = new("TextLabel", {
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local valueText = new("TextLabel", {
		Size = UDim2.new(0, 76, 1, 0),
		Position = UDim2.new(1, -30, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Text = "选择...",
		TextColor3 = Library.Theme.LabelSub,
		TextSize = Library.Settings.SubSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local chevron = new("TextLabel", {
		Size = UDim2.fromOffset(14, 32),
		Position = UDim2.new(1, -22, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Text = "▾",
		TextColor3 = Library.Theme.LabelSub,
		TextSize = Library.Settings.SubSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local list = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 1, 4),
		Visible = false,
		BackgroundColor3 = Library.Theme.Dropdown,
		BackgroundTransparency = Library.Theme.DropdownTransparency,
		BorderSizePixel = 0,
		ZIndex = 20,
		ScrollBarThickness = 4,
		ScrollBarImageTransparency = 0.5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	}, root)
	new("UICorner", { CornerRadius = UDim.new(0, Library.Theme.ElementCorner) }, list)
	new("UIStroke", { Color = Library.Theme.Border, Transparency = 0.82, Thickness = 1 }, list)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, list)

	local optionItems = {}
	local displayList = {} -- { {Type="opt", Value=...}, {Type="header", Title=...}, ... }
	local optionButtons = {}
	local open = false
	local filterText = ""
	local searchBox = nil
	local actionRow = nil

	local el = newElement(multi and "MultiSelect" or "Dropdown", root, options.Callback)
	el.ConfigKey = options.ConfigKey or (keyPrefix .. "/" .. name)
	Library:RegisterConfigKey(el.ConfigKey)
	options.Options = options.Options or {}
	options.Groups = options.Groups or {}
	for _, opt in ipairs(options.Options) do
		local s = tostring(opt)
		table.insert(optionItems, s)
		table.insert(displayList, { Type = "opt", Value = s })
	end
	-- OptGroup: Groups = { {Title = "稀有度", Options = {"史诗","传说"}}, ... }
	for _, grp in ipairs(options.Groups) do
		local title = grp.Title or grp.Name or "Group"
		table.insert(displayList, { Type = "header", Title = title })
		for _, opt in ipairs(grp.Options or {}) do
			local s = tostring(opt)
			table.insert(optionItems, s)
			table.insert(displayList, { Type = "opt", Value = s })
		end
	end

	local function cloneList(src)
		local out = {}
		if type(src) == "table" then
			for i = 1, #src do
				out[i] = src[i]
			end
		end
		return out
	end
	local function isSelected(opt)
		if multi then
			for i = 1, #el.Value do
				if el.Value[i] == opt then
					return true
				end
			end
			return false
		end
		return el.Value == opt
	end
	local function getDisplayText()
		if multi then
			local n = #el.Value
			if n == 0 then
				return "未选择"
			end
			if n <= 2 then
				return table.concat(el.Value, "、")
			end
			return n .. " 项"
		end
		return (el.Value ~= nil) and tostring(el.Value) or "选择..."
	end
	local function restyle()
		valueText.Text = getDisplayText()
		for _, btn in ipairs(optionButtons) do
			local o = btn:GetAttribute("Opt")
			local selected = isSelected(o)
			btn.Text = (selected and "✓ " or "") .. tostring(o)
			btn.TextColor3 = selected and Library.Theme.Accent or Library.Theme.LabelSub
		end
	end

	local setOpen -- 前向声明, rebuild 的回调闭包要引用它

	-- [Lite7] 列表尺寸计算 (前向声明在 rebuild 之前, 避免 nil 调用)
	local function updateListSize()
		local extra = 0
		if searchBox then
			extra = extra + 26
		end
		if actionRow then
			extra = extra + 24
		end
		local contentH = renderedH + rowCount * 2 + 8 + extra
		if contentH > 168 then
			list.Size = UDim2.new(1, 0, 0, 168)
		else
			list.Size = UDim2.new(1, 0, 0, contentH)
		end
	end

	local function rebuild()
		-- 重建搜索框 / 操作行 / 选项 (数量变化时切换显示)
		if searchBox then
			searchBox:Destroy()
			searchBox = nil
		end
		if actionRow then
			actionRow:Destroy()
			actionRow = nil
		end
		for _, b in ipairs(optionButtons) do
			b:Destroy()
		end
		optionButtons = {}

		local hasSearch = (#optionItems > 6)
		if hasSearch then
			searchBox = new("TextBox", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Library.Theme.ControlActive,
				BackgroundTransparency = Library.Theme.ControlActiveTransparency,
				Text = filterText,
				PlaceholderText = "搜索...",
				TextSize = Library.Settings.SubSize,
				Font = Library.Fonts.Text,
				TextColor3 = Library.Theme.Label,
				PlaceholderColor3 = Library.Theme.LabelSub,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				LayoutOrder = 1,
			}, list)
			new("UICorner", { CornerRadius = UDim.new(0, 6) }, searchBox)
			new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, searchBox)
			-- [Lite7修复] 防御: searchBox 类型/存活校验后再连接 TextChanged, 防止销毁重建时报
			--   "TextChanged is not a valid member of TextBox" (执行器沙箱下偶发)
			pcall(function()
				if searchBox and searchBox:IsA("TextBox") and searchBox.Parent then
					searchBox.TextChanged:Connect(function()
						filterText = searchBox.Text or ""
						rebuild()
					end)
				end
			end)
		end

		if multi and #optionItems > 0 then
			actionRow = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 2 }, list)
			local allBtn = new("TextButton", {
				Size = UDim2.new(0.5, -3, 0, 22),
				Text = "全选",
				TextSize = Library.Settings.SmallSize,
				Font = Library.Fonts.Text,
				BackgroundColor3 = Library.Theme.ControlActive,
				BackgroundTransparency = Library.Theme.ControlActiveTransparency,
				TextColor3 = Library.Theme.LabelSub,
				AutoButtonColor = false,
				BorderSizePixel = 0,
			}, actionRow)
			new("UICorner", { CornerRadius = UDim.new(0, 6) }, allBtn)
			local noneBtn = new("TextButton", {
				Size = UDim2.new(0.5, -3, 0, 22),
				Position = UDim2.new(0.5, 3, 0, 0),
				Text = "清空",
				TextSize = Library.Settings.SmallSize,
				Font = Library.Fonts.Text,
				BackgroundColor3 = Library.Theme.ControlActive,
				BackgroundTransparency = Library.Theme.ControlActiveTransparency,
				TextColor3 = Library.Theme.LabelSub,
				AutoButtonColor = false,
				BorderSizePixel = 0,
			}, actionRow)
			new("UICorner", { CornerRadius = UDim.new(0, 6) }, noneBtn)
			allBtn.MouseButton1Click:Connect(function()
				el:SetValue(cloneList(optionItems))
			end)
			noneBtn.MouseButton1Click:Connect(function()
				el:SetValue({})
			end)
		end

		-- 过滤 + 重建选项 (支持分组头: 组内无匹配时组头一并隐藏)
		local lowerFilter = string.lower(filterText)
		local headerVisible = {}
		if lowerFilter ~= "" then
			local currentHeader = nil
			for _, item in ipairs(displayList) do
				if item.Type == "header" then
					currentHeader = item
				elseif item.Type == "opt" and currentHeader then
					if string.find(string.lower(item.Value), lowerFilter, 1, true) then
						headerVisible[currentHeader] = true
					end
				end
			end
		end
		local orderIndex = 2
		local renderedH = 0
		local rowCount = 0
		for _, item in ipairs(displayList) do
			if item.Type == "header" then
				if lowerFilter ~= "" and not headerVisible[item] then
					-- 组内无匹配项, 隐藏组头
				else
					orderIndex = orderIndex + 1
					renderedH = renderedH + 16
					rowCount = rowCount + 1
					new("TextLabel", {
						Size = UDim2.new(1, 0, 0, 16),
						BackgroundTransparency = 1,
						Text = item.Title,
						TextColor3 = Library.Theme.GroupHeader,
						TextSize = Library.Settings.SmallSize,
						Font = Library.Fonts.Bold,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
						TextTransparency = 0.3,
						LayoutOrder = orderIndex,
					}, list)
				end
			elseif lowerFilter == "" or string.find(string.lower(item.Value), lowerFilter, 1, true) then
				orderIndex = orderIndex + 1
				renderedH = renderedH + 24
				rowCount = rowCount + 1
				local opt = item.Value
				local btn = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 24),
					Text = opt,
					TextSize = Library.Settings.SubSize,
					Font = Library.Fonts.Text,
					BackgroundTransparency = 1,
					TextColor3 = Library.Theme.LabelSub,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					LayoutOrder = orderIndex,
				}, list)
				-- [修复] Roblox Instance 自定义属性须用 SetAttribute (._Opt 赋值会报 "not a valid member")
				btn:SetAttribute("Opt", opt)
				btn.MouseEnter:Connect(function()
					btn.TextColor3 = Library.Theme.Label
				end)
				btn.MouseLeave:Connect(function()
					if not isSelected(btn:GetAttribute("Opt")) then
						btn.TextColor3 = Library.Theme.LabelSub
					end
				end)
				btn.MouseButton1Click:Connect(function()
					if multi then
						local newSel = cloneList(el.Value)
						local hit = false
						for i = 1, #newSel do
							if newSel[i] == btn:GetAttribute("Opt") then
								table.remove(newSel, i)
								hit = true
								break
							end
						end
						if not hit then
							table.insert(newSel, btn:GetAttribute("Opt"))
						end
						el:SetValue(newSel)
					else
						el:SetValue(btn:GetAttribute("Opt"))
						setOpen(false)
					end
				end)
				table.insert(optionButtons, btn)
			end
		end

		local extra = 0
		if hasSearch then
			extra = extra + 26
		end
		if actionRow then
			extra = extra + 24
		end
		-- [Lite7修复] 选项为空时显示占位文本, 避免"打开一片空白/打不开"的观感
		if rowCount == 0 then
			local emptyLabel = new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = (filterText ~= "") and "无匹配选项" or "暂无选项",
				TextColor3 = Library.Theme.LabelSub,
				TextSize = Library.Settings.SubSize,
				Font = Library.Fonts.Text,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				LayoutOrder = orderIndex,
			}, list)
			renderedH = renderedH + 24
			rowCount = rowCount + 1
		end
		updateListSize()
		restyle()
	end

	local function setOpenImpl(value)
		open = value
		list.Visible = open
		root.ZIndex = open and 12 or 8
		if open then
			rebuild()
			restyle()
		end
	end
	setOpen = setOpenImpl

	el.SetValue = function(self, v, silent)
		if multi then
			local out = {}
			if type(v) == "table" then
				for i = 1, #v do
					local s = tostring(v[i])
					if s ~= "" then
						table.insert(out, s)
					end
				end
			elseif v ~= nil then
				table.insert(out, tostring(v))
			end
			el.Value = out
		else
			el.Value = (v ~= nil) and tostring(v) or nil
		end
		restyle()
		if el.ConfigKey then
			Library.Config[el.ConfigKey] = el.Value
		end
		if not silent then
			if multi then
				el:Emit(cloneList(el.Value))
			else
				el:Emit(el.Value)
			end
			Library:_AutoSave()
		end
	end
	if multi then
		el.GetSelected = function(self)
			return cloneList(el.Value)
		end
		el.DefaultValue = (type(options.Default) == "table") and cloneList(options.Default) or {}
	else
		el.DefaultValue = options.Default
	end
	el.AddOption = function(self, opt)
		local s = tostring(opt)
		table.insert(optionItems, s)
		table.insert(displayList, { Type = "opt", Value = s })
		if open then
			rebuild()
		else
			restyle()
		end
	end
	-- 运行时追加分组 (OptGroup)
	el.AddGroup = function(self, title, opts)
		table.insert(displayList, { Type = "header", Title = title })
		for _, opt in ipairs(opts or {}) do
			local s = tostring(opt)
			table.insert(optionItems, s)
			table.insert(displayList, { Type = "opt", Value = s })
		end
		if open then
			rebuild()
		end
	end
	el.GetOptions = function(self)
		return cloneList(optionItems)
	end
	el.ClearOptions = function(self)
		optionItems = {}
		displayList = {}
		el:SetValue(multi and {} or nil, true)
		if open then
			rebuild()
		end
	end

	root.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if el.Disabled then
			return
		end
		if open and Library:IsMouseOver(list) then
			return
		end
		setOpen(not open)
	end)
	Library:AddGateListener(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return false
		end
		if not open then
			return false
		end
		if Library:IsMouseOver(root) or Library:IsMouseOver(list) then
			return false
		end
		setOpen(false)
		return true
	end)

	if multi then
		el:SetValue(el.DefaultValue, true)
		el.Value = el.Value or {}
	elseif options.Default ~= nil then
		el:SetValue(options.Default, true)
	else
		restyle()
	end

	el.UpdateTheme = function(self)
		label.TextColor3 = Library.Theme.Label
		label.Font = Library.Fonts.Text
		label.TextSize = Library.Settings.TextSize
		valueText.TextColor3 = Library.Theme.LabelSub
		valueText.Font = Library.Fonts.Text
		valueText.TextSize = Library.Settings.SubSize
		chevron.TextColor3 = Library.Theme.LabelSub
		chevron.Font = Library.Fonts.Text
		chevron.TextSize = Library.Settings.SubSize
		root.BackgroundColor3 = Library.Theme.Control
		root.BackgroundTransparency = Library.Theme.ControlTransparency
		list.BackgroundColor3 = Library.Theme.Dropdown
		list.BackgroundTransparency = Library.Theme.DropdownTransparency
		restyle()
	end
	return el
end

-- ---- Input (TextBox) ----
local function addInput(content, options, keyPrefix)
	local name = options.Name or "输入框"
	local multiline = options.Multiline and true or false
	local password = options.Password and true or false
	local rootHeight = multiline and (options.Height or 70) or 32
	local root = new("Frame", {
		Size = UDim2.new(1, 0, 0, rootHeight),
		BackgroundColor3 = Library.Theme.Control,
		BackgroundTransparency = Library.Theme.ControlTransparency,
		BorderSizePixel = 0,
	}, content)
	new("UICorner", { CornerRadius = UDim.new(0, Library.Theme.ElementCorner) }, root)
	local stroke = new("UIStroke", { Color = Library.Theme.Accent, Transparency = 1, Thickness = 1 }, root)
	local box = new("TextBox", {
		Size = UDim2.new(1, -20, 1, -4),
		Position = UDim2.new(0, 10, 0, 2),
		BackgroundTransparency = 1,
		Text = (options.Default ~= nil) and tostring(options.Default) or "",
		PlaceholderText = options.PlaceholderText or name,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextColor3 = Library.Theme.Label,
		PlaceholderColor3 = Library.Theme.LabelSub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		TextWrapped = multiline,
		ClearTextOnFocus = options.ClearTextOnFocus or false,
	}, root)

	-- 密码模式: 真实文本存 el.Value, 显示用遮罩层 (Active=false 不抢焦点)
	local mask = nil
	if password then
		box.TextTransparency = 1
		mask = new("TextLabel", {
			Size = UDim2.new(1, -20, 1, -4),
			Position = UDim2.new(0, 10, 0, 2),
			BackgroundTransparency = 1,
			Text = "",
			TextColor3 = Library.Theme.Label,
			TextSize = Library.Settings.TextSize,
			Font = Library.Fonts.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
			Active = false,
		}, root)
		box.TextChanged:Connect(function()
			mask.Text = string.rep(options.PasswordChar or "●", #box.Text)
		end)
	end

	local el = newElement("Input", root, options.Callback)
	el.ConfigKey = options.ConfigKey or (keyPrefix .. "/" .. name)
	Library:RegisterConfigKey(el.ConfigKey)
	el.Value = box.Text
	el.DefaultValue = tostring(options.Default ~= nil and options.Default or "")

	box.Focused:Connect(function()
		if el.Disabled then
			return
		end
		Library:Tween(stroke, { Transparency = 0.25 }, 0.12)
		Library:Tween(root, {
			BackgroundColor3 = Library.Theme.ControlActive,
			BackgroundTransparency = Library.Theme.ControlActiveTransparency,
		}, 0.12)
	end)
	box.FocusLost:Connect(function()
		Library:Tween(stroke, { Transparency = 1 }, 0.2)
		Library:Tween(root, {
			BackgroundColor3 = Library.Theme.Control,
			BackgroundTransparency = Library.Theme.ControlTransparency,
		}, 0.2)
		if el.Disabled then
			return
		end
		el.Value = box.Text
		if el.ConfigKey then
			Library.Config[el.ConfigKey] = el.Value
		end
		el:Emit(el.Value)
		Library:_AutoSave()
	end)
	el.SetValue = function(self, v, silent)
		el.Value = tostring(v or "")
		box.Text = el.Value
		if el.ConfigKey then
			Library.Config[el.ConfigKey] = el.Value
		end
		if not silent then
			el:Emit(el.Value)
			Library:_AutoSave()
		end
	end
	el.SetText = el.SetValue

	el.UpdateTheme = function(self)
		root.BackgroundColor3 = Library.Theme.Control
		root.BackgroundTransparency = Library.Theme.ControlTransparency
		box.TextColor3 = Library.Theme.Label
		box.Font = Library.Fonts.Text
		box.TextSize = Library.Settings.TextSize
		box.PlaceholderColor3 = Library.Theme.LabelSub
		stroke.Color = Library.Theme.Accent
		if mask then
			mask.TextColor3 = Library.Theme.Label
			mask.Font = Library.Fonts.Text
			mask.TextSize = Library.Settings.TextSize
		end
	end
	return el
end

-- ---- Keybind ----
local function addKeybind(content, options, keyPrefix)
	local name = options.Name or "热键"
	local root = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 }, content)
	local label = new("TextLabel", {
		Size = UDim2.new(1, -110, 1, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local chip = new("TextButton", {
		Size = UDim2.fromOffset(92, 22),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "未绑定",
		TextSize = Library.Settings.SmallSize,
		Font = Library.Fonts.Text,
		BackgroundColor3 = Library.Theme.ControlActive,
		BackgroundTransparency = Library.Theme.ControlActiveTransparency,
		TextColor3 = Library.Theme.LabelSub,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, root)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, chip)

	local el = newElement("Keybind", root, options.Callback)
	el.ConfigKey = options.ConfigKey or (keyPrefix .. "/" .. name)
	Library:RegisterConfigKey(el.ConfigKey)
	el.Value = options.Default or Enum.KeyCode.None
	if type(el.Value) == "string" then
		local keyOk, keyEnum = pcall(function()
			return Enum.KeyCode[el.Value]
		end)
		el.Value = keyOk and keyEnum or Enum.KeyCode.None
	end
	el.DefaultValue = el.Value

	local function paint()
		chip.Text = (el.Value == Enum.KeyCode.None) and "未绑定" or el.Value.Name
	end
	el.SetValue = function(self, v, silent)
		if v == nil or v == Enum.KeyCode.None then
			el.Value = Enum.KeyCode.None
		elseif type(v) == "string" then
			local keyOk, keyEnum = pcall(function()
				return Enum.KeyCode[v]
			end)
			el.Value = keyOk and keyEnum or Enum.KeyCode.None
		else
			el.Value = v
		end
		paint()
		if el.ConfigKey then
			Library.Config[el.ConfigKey] = el.Value.Name
		end
		if not silent then
			el:Emit(el.Value)
			Library:_AutoSave()
		end
	end

	local binding = false
	local boundConn = nil
	local function cancelBind()
		binding = false
		Library._BindingActive = false
		paint()
	end
	chip.MouseButton1Click:Connect(function()
		if el.Disabled then
			return
		end
		if binding then
			if boundConn then
				boundConn:Disconnect()
			end
			cancelBind()
			return
		end
		binding = true
		Library._BindingActive = true
		chip.Text = "按下按键..."
		boundConn = UserInputService.InputBegan:Connect(function(input, processed)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			if processed then
				return
			end
			if input.KeyCode == Enum.KeyCode.Escape then
				boundConn:Disconnect()
				cancelBind()
				return
			end
			boundConn:Disconnect()
			binding = false
			Library._BindingActive = false
			el:SetValue(input.KeyCode)
		end)
		table.insert(Library._GlobalConnections, boundConn)
	end)

	el:SetValue(el.Value, true)
	el.UpdateTheme = function(self)
		label.TextColor3 = Library.Theme.Label
		label.Font = Library.Fonts.Text
		label.TextSize = Library.Settings.TextSize
		chip.BackgroundColor3 = Library.Theme.ControlActive
		chip.BackgroundTransparency = Library.Theme.ControlActiveTransparency
		chip.TextColor3 = Library.Theme.LabelSub
		chip.Font = Library.Fonts.Text
		chip.TextSize = Library.Settings.SmallSize
	end
	return el
end

-- ---- ColorPicker ----
local function addColorPicker(content, options, keyPrefix)
	local name = options.Name or "取色器"
	local el -- 前向声明, 色板点击回调需要引用
	local alphaEnabled = options.Transparency and true or false
	local presets = options.Presets or {}
	local squareH = alphaEnabled and 86 or 108
	local yHue = 10 + squareH + 8
	local yAlpha = alphaEnabled and (yHue + 22) or nil
	local yHex = (yAlpha or yHue) + 22
	local yPresets = yHex + 20
	local presetH = (#presets > 0) and 24 or 0
	local panelH = yPresets + presetH + 8
	local root = new("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Library.Theme.Control,
		BackgroundTransparency = Library.Theme.ControlTransparency,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, content)
	new("UICorner", { CornerRadius = UDim.new(0, Library.Theme.ElementCorner) }, root)
	local label = new("TextLabel", {
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local swatch = new("Frame", {
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -36, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, root)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, swatch)
	new("UIStroke", { Color = Library.Theme.Border, Transparency = 0.6, Thickness = 1 }, swatch)

	local panel = new("Frame", {
		Size = UDim2.new(1, 0, 0, panelH),
		Position = UDim2.new(0, 0, 1, 4),
		Visible = false,
		BackgroundColor3 = Library.Theme.Dropdown,
		BackgroundTransparency = Library.Theme.DropdownTransparency,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, root)
	new("UICorner", { CornerRadius = UDim.new(0, Library.Theme.ElementCorner) }, panel)
	new("UIStroke", { Color = Library.Theme.Border, Transparency = 0.82, Thickness = 1 }, panel)

	local square = new("Frame", {
		Size = UDim2.new(1, -20, 0, squareH),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Color3.new(1, 0, 0),
		BorderSizePixel = 0,
	}, panel)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, square)
	-- 横向: 白 -> 透明(饱和轴)
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1), 0),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1), 1),
		}),
	}, square)
	-- 纵向: 透明 -> 黑(明度轴)
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0), 1),
			ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0), 0),
		}),
	}, square)
	local thumb = new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, square)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, thumb)
	new("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.4, Thickness = 1 }, thumb)

	local hueBar = new("Frame", {
		Size = UDim2.new(1, -20, 0, 14),
		Position = UDim2.new(0, 10, 0, yHue),
		BackgroundColor3 = Color3.new(1, 0, 0),
		BorderSizePixel = 0,
	}, panel)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, hueBar)
	new("UIGradient", { Color = HUE_SEQUENCE }, hueBar)
	local hueThumb = new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, hueBar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, hueThumb)
	new("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.35, Thickness = 1 }, hueThumb)

	local alphaBar = nil
	local alphaThumb = nil
	if alphaEnabled then
		alphaBar = new("Frame", {
			Size = UDim2.new(1, -20, 0, 14),
			Position = UDim2.new(0, 10, 0, yAlpha),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, panel)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, alphaBar)
		-- 均匀白雾: 表示透明度通道 (数值显示在 hex 行)
		new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1), 0.6),
				ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1), 0.6),
			}),
		}, alphaBar)
		alphaThumb = new("Frame", {
			Size = UDim2.fromOffset(14, 14),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 2,
		}, alphaBar)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, alphaThumb)
		new("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.35, Thickness = 1 }, alphaThumb)
	end

	local hexLabel = new("TextLabel", {
		Size = UDim2.new(1, -20, 0, 16),
		Position = UDim2.new(0, 10, 0, yHex),
		BackgroundTransparency = 1,
		Text = "#FFFFFF",
		TextColor3 = Library.Theme.LabelSub,
		TextSize = Library.Settings.SmallSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, panel)

	-- 预设色板: 点击立即取色 (保留当前透明度)
	if #presets > 0 then
		local presetRow = new("Frame", {
			Size = UDim2.new(1, -20, 0, presetH),
			Position = UDim2.new(0, 10, 0, yPresets),
			BackgroundTransparency = 1,
		}, panel)
		local xOffset = 0
		for _, pc in ipairs(presets) do
			local pcColor = Library:ConvertColor(pc)
			local sw = new("Frame", {
				Size = UDim2.fromOffset(20, 20),
				Position = UDim2.new(0, xOffset, 0, 2),
				BackgroundColor3 = pcColor,
				BorderSizePixel = 0,
			}, presetRow)
			new("UICorner", { CornerRadius = UDim.new(0, 6) }, sw)
			new("UIStroke", { Color = Library.Theme.Border, Transparency = 0.5, Thickness = 1 }, sw)
			xOffset = xOffset + 24
			sw.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end
				if el.Disabled then
					return
				end
				el:SetValue(pcColor)
			end)
		end
	end

	el = newElement("ColorPicker", root, options.Callback)
	el.ConfigKey = options.ConfigKey or (keyPrefix .. "/" .. name)
	Library:RegisterConfigKey(el.ConfigKey)
	el.Value = Library:ConvertColor(options.Default or Color3.fromRGB(255, 0, 0))
	el.Alpha = clamp(options.DefaultTransparency or 0, 0, 1)
	el.DefaultValue = alphaEnabled
		and { Color = el.Value, Transparency = el.Alpha }
		or el.Value

	local h, s, v = rgbToHsv(el.Value)

	local function refresh()
		local c = hsvToRgb(h, s, v)
		square.BackgroundColor3 = hsvToRgb(h, 1, 1)
		thumb.Position = UDim2.new(s, 0, 1 - v, 0)
		hueThumb.Position = UDim2.new(h, 0, 0.5, 0)
		swatch.BackgroundColor3 = c
		if alphaBar then
			alphaBar.BackgroundColor3 = c
			alphaThumb.Position = UDim2.new(el.Alpha, 0, 0.5, 0)
		end
		if alphaEnabled then
			hexLabel.Text = colorToHex(c) .. "  ·  透明度 " .. math.floor(el.Alpha * 100 + 0.5) .. "%"
		else
			hexLabel.Text = colorToHex(c)
		end
	end
	local function updateConfig()
		if el.ConfigKey then
			if alphaEnabled then
				Library.Config[el.ConfigKey] = { color = colorToHex(el.Value), transparency = el.Alpha }
			else
				Library.Config[el.ConfigKey] = colorToHex(el.Value)
			end
		end
	end
	local function squareDrag(mouse)
		local w = square.AbsoluteSize.X
		local hh = square.AbsoluteSize.Y
		if w <= 0 or hh <= 0 then
			return
		end
		s = clamp((mouse.X - square.AbsolutePosition.X) / w, 0, 1)
		v = 1 - clamp((mouse.Y - square.AbsolutePosition.Y) / hh, 0, 1)
		el.Value = hsvToRgb(h, s, v)
		refresh()
		updateConfig()
	end
	local function hueDrag(mouse)
		local w = hueBar.AbsoluteSize.X
		if w <= 0 then
			return
		end
		h = clamp((mouse.X - hueBar.AbsolutePosition.X) / w, 0, 1)
		el.Value = hsvToRgb(h, s, v)
		refresh()
		updateConfig()
	end
	local function alphaDrag(mouse)
		local w = alphaBar.AbsoluteSize.X
		if w <= 0 then
			return
		end
		el.Alpha = clamp((mouse.X - alphaBar.AbsolutePosition.X) / w, 0, 1)
		refresh()
		updateConfig()
	end
	-- 回调: 非透明模式第二参数恒为 0
	local function emitColor(c, silent)
		if silent then
			return
		end
		if el.Callback then
			pcall(el.Callback, c, el.Alpha or 0)
		end
		for i = 1, #el._Changed do
			pcall(el._Changed[i], c, el.Alpha or 0)
		end
		Library:fire("element:changed", el.Type, c)
		Library:_AutoSave()
	end
	local function fireDone()
		emitColor(el.Value)
	end

	el.SetValue = function(self, input, silent)
		local c
		local a = el.Alpha or 0
		if type(input) == "table" and alphaEnabled then
			c = Library:ConvertColor(input.Color or input[1])
			a = clamp(tonumber(input.Transparency or input[2]) or a, 0, 1)
		else
			c = Library:ConvertColor(input)
		end
		h, s, v = rgbToHsv(c)
		el.Value = c
		el.Alpha = a
		refresh()
		updateConfig()
		emitColor(c, silent)
	end

	local open = false
	local function setOpen(value)
		open = value
		panel.Visible = open
		root.ZIndex = open and 12 or 8
	end
	root.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if el.Disabled then
			return
		end
		if open and Library:IsMouseOver(panel) then
			return
		end
		setOpen(not open)
	end)
	Library:AddGateListener(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return false
		end
		if not open then
			return false
		end
		if Library:IsMouseOver(root) or Library:IsMouseOver(panel) then
			return false
		end
		setOpen(false)
		return true
	end)

	Library:TrackDrag(square, squareDrag, squareDrag, fireDone, function()
		return not el.Disabled
	end)
	Library:TrackDrag(hueBar, hueDrag, hueDrag, fireDone, function()
		return not el.Disabled
	end)
	if alphaBar then
		Library:TrackDrag(alphaBar, alphaDrag, alphaDrag, fireDone, function()
			return not el.Disabled
		end)
	end
	el:SetValue(el.Value, true)

	el.UpdateTheme = function(self)
		label.TextColor3 = Library.Theme.Label
		label.Font = Library.Fonts.Text
		label.TextSize = Library.Settings.TextSize
		root.BackgroundColor3 = Library.Theme.Control
		root.BackgroundTransparency = Library.Theme.ControlTransparency
		panel.BackgroundColor3 = Library.Theme.Dropdown
		panel.BackgroundTransparency = Library.Theme.DropdownTransparency
		hexLabel.TextColor3 = Library.Theme.LabelSub
		hexLabel.Font = Library.Fonts.Text
		hexLabel.TextSize = Library.Settings.SmallSize
	end
	return el
end

-- ---- Label / Divider ----
local function addLabel(content, options)
	local label = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = options.Text or "",
		TextColor3 = Library.Theme.LabelSub,
		TextSize = Library.Settings.SubSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTransparency = options.TextTransparency or 0.35,
	}, content)
	local el = newElement("Label", label, nil)
	el.SetText = function(self, text)
		label.Text = text
	end
	el.UpdateTheme = function(self)
		label.TextColor3 = Library.Theme.LabelSub
		label.Font = Library.Fonts.Text
		label.TextSize = Library.Settings.SubSize
	end
	return el
end

local function addDivider(content)
	local line = new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Library.Theme.Divider,
		BackgroundTransparency = Library.Theme.DividerTransparency,
		BorderSizePixel = 0,
	}, content)
	local el = newElement("Divider", line, nil)
	el.UpdateTheme = function(self)
		line.BackgroundColor3 = Library.Theme.Divider
		line.BackgroundTransparency = Library.Theme.DividerTransparency
	end
	return el
end

-- ---- RangeSlider (双值范围) ----
local function addRangeSlider(content, options, keyPrefix)
	local name = options.Name or "范围"
	local minV = options.Min or 0
	local maxV = options.Max or 100
	local lowV = clamp(options.DefaultLow or (minV + (maxV - minV) * 0.25), minV, maxV)
	local highV = clamp(options.DefaultHigh or (minV + (maxV - minV) * 0.75), minV, maxV)
	if lowV > highV then
		lowV, highV = highV, lowV
	end
	local suffix = options.Suffix or ""
	local decimals = options.Decimals

	local root = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 }, content)
	local label = new("TextLabel", {
		Size = UDim2.new(1, -110, 0, 20),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local valueText = new("TextLabel", {
		Size = UDim2.new(0, 96, 0, 20),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Library.Theme.LabelSub,
		TextSize = Library.Settings.SmallSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local bar = new("Frame", {
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 0, 26),
		BackgroundColor3 = Library.Theme.ControlActive,
		BackgroundTransparency = Library.Theme.ControlActiveTransparency,
		BorderSizePixel = 0,
	}, root)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Library.Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, bar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	local lowHandle = new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, bar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, lowHandle)
	local highHandle = new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, bar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, highHandle)

	local el = newElement("RangeSlider", root, options.Callback)
	el.ConfigKey = options.ConfigKey or (keyPrefix .. "/" .. name)
	Library:RegisterConfigKey(el.ConfigKey)
	el.Value = { lowV, highV } -- {Low, High}
	el.DefaultValue = { lowV, highV }

	local function getDisplay(v)
		if decimals then
			return formatNumber(round(v, decimals)) .. suffix
		end
		return formatNumber(v) .. suffix
	end
	local function paint()
		local lp = clamp((el.Value[1] - minV) / (maxV - minV), 0, 1)
		local hp = clamp((el.Value[2] - minV) / (maxV - minV), 0, 1)
		fill.Position = UDim2.new(lp, 0, 0, 0)
		fill.Size = UDim2.new(hp - lp, 0, 1, 0)
		lowHandle.Position = UDim2.new(lp, 0, 0.5, 0)
		highHandle.Position = UDim2.new(hp, 0, 0.5, 0)
		valueText.Text = getDisplay(el.Value[1]) .. " - " .. getDisplay(el.Value[2])
	end
	local function valueFromMouse(mouse)
		local width = bar.AbsoluteSize.X
		if width <= 0 then
			return nil
		end
		local pct = clamp((mouse.X - bar.AbsolutePosition.X) / width, 0, 1)
		return minV + pct * (maxV - minV)
	end
	local function dragBy(mouse, which)
		local v = valueFromMouse(mouse)
		if not v then
			return
		end
		local lo, hi = el.Value[1], el.Value[2]
		if which == "low" then
			lo = math.min(v, hi)
		else
			hi = math.max(v, lo)
		end
		el:SetValue({ lo, hi })
	end

	el.SetValue = function(self, v, silent)
		local lo, hi
		if type(v) == "table" then
			lo = tonumber(v[1])
			hi = tonumber(v[2])
		end
		lo = clamp(lo or minV, minV, maxV)
		hi = clamp(hi or maxV, minV, maxV)
		if lo > hi then
			lo, hi = hi, lo
		end
		el.Value = { lo, hi }
		paint()
		if el.ConfigKey then
			Library.Config[el.ConfigKey] = { lo, hi }
		end
		if not silent then
			el:Emit({ lo, hi })
			Library:_AutoSave()
		end
	end

	local allowed = function()
		return not el.Disabled
	end
	Library:TrackDrag(lowHandle, nil, function(mouse)
		dragBy(mouse, "low")
	end, nil, allowed)
	Library:TrackDrag(highHandle, nil, function(mouse)
		dragBy(mouse, "high")
	end, nil, allowed)
	-- 点击轨道: 就近选择句柄并拖动
	local activeWhich = nil
	Library:TrackDrag(bar, function(mouse)
		local v = valueFromMouse(mouse)
		if v then
			activeWhich = (math.abs(v - el.Value[1]) <= math.abs(v - el.Value[2])) and "low" or "high"
		end
	end, function(mouse)
		if activeWhich then
			dragBy(mouse, activeWhich)
		end
	end, function()
		activeWhich = nil
	end, function()
		if not allowed() then
			return false
		end
		return not Library:IsMouseOver(lowHandle) and not Library:IsMouseOver(highHandle)
	end)
	el:SetValue(el.Value, true)

	el.UpdateTheme = function(self)
		label.TextColor3 = Library.Theme.Label
		label.Font = Library.Fonts.Text
		label.TextSize = Library.Settings.TextSize
		valueText.TextColor3 = Library.Theme.LabelSub
		valueText.Font = Library.Fonts.Text
		valueText.TextSize = Library.Settings.SmallSize
		bar.BackgroundColor3 = Library.Theme.ControlActive
		bar.BackgroundTransparency = Library.Theme.ControlActiveTransparency
		fill.BackgroundColor3 = Library.Theme.Accent
		paint()
	end
	return el
end

-- ---- Stepper (步进器 +/−) ----
local function addStepper(content, options, keyPrefix)
	local name = options.Name or "步进"
	local minV = options.Min or 0
	local maxV = options.Max or 100
	local step = options.Step or 1
	local defaultV = clamp(options.Default or minV, minV, maxV)
	local suffix = options.Suffix or ""
	local decimals = options.Decimals

	local root = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 }, content)
	local label = new("TextLabel", {
		Size = UDim2.new(1, -130, 1, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local minusBtn = new("TextButton", {
		Size = UDim2.fromOffset(24, 22),
		Position = UDim2.new(1, -116, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "−",
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Bold,
		BackgroundColor3 = Library.Theme.ControlActive,
		BackgroundTransparency = Library.Theme.ControlActiveTransparency,
		TextColor3 = Library.Theme.Label,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, root)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, minusBtn)
	local plusBtn = new("TextButton", {
		Size = UDim2.fromOffset(24, 22),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "+",
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Bold,
		BackgroundColor3 = Library.Theme.ControlActive,
		BackgroundTransparency = Library.Theme.ControlActiveTransparency,
		TextColor3 = Library.Theme.Label,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, root)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, plusBtn)
	local valueText = new("TextLabel", {
		Size = UDim2.new(0, 60, 1, 0),
		Position = UDim2.new(1, -90, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Library.Theme.LabelSub,
		TextSize = Library.Settings.SubSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)

	local el = newElement("Stepper", root, options.Callback)
	el.ConfigKey = options.ConfigKey or (keyPrefix .. "/" .. name)
	Library:RegisterConfigKey(el.ConfigKey)
	el.Value = defaultV
	el.DefaultValue = defaultV

	local function getDisplay(v)
		if decimals then
			return formatNumber(round(v, decimals)) .. suffix
		end
		return formatNumber(v) .. suffix
	end
	local function paint()
		valueText.Text = getDisplay(el.Value)
	end
	el.SetValue = function(self, v, silent)
		v = clamp(tonumber(v) or minV, minV, maxV)
		el.Value = v
		paint()
		if el.ConfigKey then
			Library.Config[el.ConfigKey] = v
		end
		if not silent then
			el:Emit(v)
			Library:_AutoSave()
		end
	end
	minusBtn.MouseButton1Click:Connect(function()
		if el.Disabled then
			return
		end
		el:SetValue(el.Value - step)
	end)
	plusBtn.MouseButton1Click:Connect(function()
		if el.Disabled then
			return
		end
		el:SetValue(el.Value + step)
	end)
	el.SetValue(defaultV, true)

	el.UpdateTheme = function(self)
		label.TextColor3 = Library.Theme.Label
		label.Font = Library.Fonts.Text
		label.TextSize = Library.Settings.TextSize
		valueText.TextColor3 = Library.Theme.LabelSub
		valueText.Font = Library.Fonts.Text
		valueText.TextSize = Library.Settings.SubSize
		minusBtn.BackgroundColor3 = Library.Theme.ControlActive
		minusBtn.BackgroundTransparency = Library.Theme.ControlActiveTransparency
		minusBtn.Font = Library.Fonts.Bold
		minusBtn.TextSize = Library.Settings.TextSize
		plusBtn.BackgroundColor3 = Library.Theme.ControlActive
		plusBtn.BackgroundTransparency = Library.Theme.ControlActiveTransparency
		plusBtn.Font = Library.Fonts.Bold
		plusBtn.TextSize = Library.Settings.TextSize
	end
	return el
end

-- ---- ProgressBar (进度条, 不参与配置) ----
local function addProgressBar(content, options)
	local name = options.Name or "进度"
	local value = clamp(options.Value or 0, 0, 1)
	local suffix = options.Suffix or "%"

	local root = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 }, content)
	local label = new("TextLabel", {
		Size = UDim2.new(1, -70, 0, 20),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local valueText = new("TextLabel", {
		Size = UDim2.new(0, 60, 0, 20),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Library.Theme.LabelSub,
		TextSize = Library.Settings.SubSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, root)
	local bar = new("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 0, 25),
		BackgroundColor3 = Library.Theme.ControlActive,
		BackgroundTransparency = Library.Theme.ControlActiveTransparency,
		BorderSizePixel = 0,
	}, root)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Library.Theme.Accent,
		BorderSizePixel = 0,
	}, bar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

	local el = newElement("ProgressBar", root, options.Callback)
	el.Value = value

	local function paint()
		valueText.Text = formatNumber(round(value * 100, 1)) .. suffix
		fill.Size = UDim2.new(clamp(value, 0, 1), 0, 1, 0)
	end
	el.SetValue = function(self, v, silent)
		value = clamp(tonumber(v) or 0, 0, 1)
		el.Value = value
		paint()
		if not silent and el.Callback then
			pcall(el.Callback, value)
		end
	end
	el.SetProgress = el.SetValue
	paint()

	el.UpdateTheme = function(self)
		label.TextColor3 = Library.Theme.Label
		label.Font = Library.Fonts.Text
		label.TextSize = Library.Settings.TextSize
		valueText.TextColor3 = Library.Theme.LabelSub
		valueText.Font = Library.Fonts.Text
		valueText.TextSize = Library.Settings.SubSize
		bar.BackgroundColor3 = Library.Theme.ControlActive
		bar.BackgroundTransparency = Library.Theme.ControlActiveTransparency
		fill.BackgroundColor3 = Library.Theme.Accent
	end
	return el
end

-- ---- Paragraph (段落: 标题 + 多行内容) ----
local function addParagraph(content, options)
	local frame = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, content)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
	local titleLabel = nil
	if options.Title and options.Title ~= "" then
		titleLabel = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = options.Title,
			TextColor3 = Library.Theme.GroupHeader,
			TextSize = Library.Settings.SubSize,
			Font = Library.Fonts.Bold,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
		}, frame)
	end
	local body = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = options.Content or "",
		TextColor3 = Library.Theme.LabelSub,
		TextSize = Library.Settings.SubSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		LayoutOrder = 2,
	}, frame)

	local el = newElement("Paragraph", frame, nil)
	el.SetText = function(self, text)
		body.Text = text
	end
	el.SetTitle = function(self, text)
		if titleLabel then
			titleLabel.Text = text
		end
	end
	el.UpdateTheme = function(self)
		if titleLabel then
			titleLabel.TextColor3 = Library.Theme.GroupHeader
			titleLabel.Font = Library.Fonts.Bold
			titleLabel.TextSize = Library.Settings.HeaderSize
		end
		body.TextColor3 = Library.Theme.LabelSub
		body.Font = Library.Fonts.Text
		body.TextSize = Library.Settings.SubSize
	end
	return el
end

-- ---- CheckboxGroup (多选勾选组) ----
local function addCheckboxGroup(content, options, keyPrefix)
	local name = options.Name or "复选"
	local root = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, content)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, root)
	local title = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 1,
	}, root)

	local optionItems = {}
	local rowFrames = {}

	local el = newElement("CheckboxGroup", root, options.Callback)
	el.ConfigKey = options.ConfigKey or (keyPrefix .. "/" .. name)
	Library:RegisterConfigKey(el.ConfigKey)
	options.Options = options.Options or {}
	for _, opt in ipairs(options.Options) do
		table.insert(optionItems, tostring(opt))
	end
	el.Value = {}
	el.DefaultValue = (type(options.Default) == "table") and cloneStrings(options.Default) or {}

	local function isSelected(v)
		for i = 1, #el.Value do
			if el.Value[i] == v then
				return true
			end
		end
		return false
	end
	local function paintRow(row)
		local selected = isSelected(row._Opt)
		row.Box.BackgroundColor3 = selected and Library.Theme.Accent or Library.Theme.ControlActive
		row.Box.BackgroundTransparency = selected and 0 or Library.Theme.ControlActiveTransparency
		row.Tick.TextTransparency = selected and 0 or 1
		row.Text.TextColor3 = selected and Library.Theme.Label or Library.Theme.LabelSub
		row.Text.Font = Library.Fonts.Text
		row.Text.TextSize = Library.Settings.SubSize
	end
	local function rebuild()
		for _, r in ipairs(rowFrames) do
			r.Frame:Destroy()
		end
		rowFrames = {}
		for i, opt in ipairs(optionItems) do
			local row = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = i + 1 }, root)
			local text = new("TextLabel", {
				Size = UDim2.new(1, -40, 1, 0),
				BackgroundTransparency = 1,
				Text = opt,
				TextColor3 = Library.Theme.LabelSub,
				TextSize = Library.Settings.SubSize,
				Font = Library.Fonts.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
			}, row)
			local box = new("Frame", {
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Library.Theme.ControlActive,
				BackgroundTransparency = Library.Theme.ControlActiveTransparency,
				BorderSizePixel = 0,
			}, row)
			new("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
			local tick = new("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "✓",
				TextColor3 = Library.Theme.OnAccent,
				TextTransparency = 1,
				TextSize = Library.Settings.SmallSize,
				Font = Library.Fonts.Bold,
				TextYAlignment = Enum.TextYAlignment.Center,
			}, box)
			local obj = { _Opt = opt, Frame = row, Box = box, Tick = tick, Text = text }
			table.insert(rowFrames, obj)
			row.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end
				if el.Disabled then
					return
				end
				local newSel = cloneStrings(el.Value)
				local hit = false
				for j = 1, #newSel do
					if newSel[j] == opt then
						table.remove(newSel, j)
						hit = true
						break
					end
				end
				if not hit then
					table.insert(newSel, opt)
				end
				el:SetValue(newSel)
			end)
			paintRow(obj)
		end
	end

	el.SetValue = function(self, v, silent)
		local out = {}
		if type(v) == "table" then
			for i = 1, #v do
				local s = tostring(v[i])
				if s ~= "" then
					table.insert(out, s)
				end
			end
		elseif v ~= nil then
			table.insert(out, tostring(v))
		end
		el.Value = out
		for _, row in ipairs(rowFrames) do
			paintRow(row)
		end
		if el.ConfigKey then
			Library.Config[el.ConfigKey] = el.Value
		end
		if not silent then
			el:Emit(cloneStrings(el.Value))
			Library:_AutoSave()
		end
	end
	el.AddOption = function(self, opt)
		table.insert(optionItems, tostring(opt))
		rebuild()
	end
	el.ClearOptions = function(self)
		optionItems = {}
		el:SetValue({}, true)
		rebuild()
	end
	el.GetSelected = function(self)
		return cloneStrings(el.Value)
	end

	el:SetValue(el.DefaultValue, true)
	rebuild()

	el.UpdateTheme = function(self)
		title.TextColor3 = Library.Theme.Label
		title.Font = Library.Fonts.Text
		title.TextSize = Library.Settings.TextSize
		for _, row in ipairs(rowFrames) do
			paintRow(row)
		end
	end
	return el
end

-- ---- RadioGroup (单选组) ----
local function addRadioGroup(content, options, keyPrefix)
	local name = options.Name or "单选"
	local root = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, content)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, root)
	local title = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Library.Theme.Label,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 1,
	}, root)

	local optionItems = {}
	local rowFrames = {}

	local el = newElement("RadioGroup", root, options.Callback)
	el.ConfigKey = options.ConfigKey or (keyPrefix .. "/" .. name)
	Library:RegisterConfigKey(el.ConfigKey)
	options.Options = options.Options or {}
	for _, opt in ipairs(options.Options) do
		table.insert(optionItems, tostring(opt))
	end
	el.Value = (options.Default ~= nil) and tostring(options.Default) or nil
	el.DefaultValue = options.Default

	local function paintRow(row)
		local selected = (el.Value == row._Opt)
		row.Dot.Visible = selected
		row.Circle.BackgroundColor3 = selected and Library.Theme.Accent or Library.Theme.ControlActive
		row.Circle.BackgroundTransparency = selected and 0 or Library.Theme.ControlActiveTransparency
		row.Text.TextColor3 = selected and Library.Theme.Label or Library.Theme.LabelSub
		row.Text.Font = Library.Fonts.Text
		row.Text.TextSize = Library.Settings.SubSize
	end
	local function rebuild()
		for _, r in ipairs(rowFrames) do
			r.Frame:Destroy()
		end
		rowFrames = {}
		for i, opt in ipairs(optionItems) do
			local row = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = i + 1 }, root)
			local text = new("TextLabel", {
				Size = UDim2.new(1, -40, 1, 0),
				BackgroundTransparency = 1,
				Text = opt,
				TextColor3 = Library.Theme.LabelSub,
				TextSize = Library.Settings.SubSize,
				Font = Library.Fonts.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
			}, row)
			local circle = new("Frame", {
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Library.Theme.ControlActive,
				BackgroundTransparency = Library.Theme.ControlActiveTransparency,
				BorderSizePixel = 0,
			}, row)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, circle)
			local dot = new("Frame", {
				Size = UDim2.fromOffset(8, 8),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Library.Theme.OnAccent,
				BorderSizePixel = 0,
				Visible = false,
			}, circle)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
			local obj = { _Opt = opt, Frame = row, Circle = circle, Dot = dot, Text = text }
			table.insert(rowFrames, obj)
			row.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end
				if el.Disabled then
					return
				end
				el:SetValue(opt)
			end)
			paintRow(obj)
		end
	end

	el.SetValue = function(self, v, silent)
		el.Value = (v ~= nil) and tostring(v) or nil
		for _, row in ipairs(rowFrames) do
			paintRow(row)
		end
		if el.ConfigKey and el.Value ~= nil then
			Library.Config[el.ConfigKey] = el.Value
		end
		if not silent and el.Value ~= nil then
			el:Emit(el.Value)
			Library:_AutoSave()
		end
	end
	el.AddOption = function(self, opt)
		table.insert(optionItems, tostring(opt))
		rebuild()
	end
	el.ClearOptions = function(self)
		optionItems = {}
		el:SetValue(nil, true)
		rebuild()
	end
	el.GetSelected = function(self)
		return el.Value
	end

	el:SetValue(el.Value, true)
	rebuild()

	el.UpdateTheme = function(self)
		title.TextColor3 = Library.Theme.Label
		title.Font = Library.Fonts.Text
		title.TextSize = Library.Settings.TextSize
		for _, row in ipairs(rowFrames) do
			paintRow(row)
		end
	end
	return el
end

-- ---- Table (列表/表格: 玩家列表、物品列表通用; 运行时数据, 不参与配置) ----
local function addTable(content, options)
	local name = options.Name
	local columns = options.Columns or {}
	local rows = options.Rows or {}
	local height = options.Height or 160
	local rowHeight = options.RowHeight or 24
	local colWidths = options.ColumnWidths or nil

	local root = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, content)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, root)

	local title = nil
	if name and name ~= "" then
		title = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = Library.Theme.Label,
			TextSize = Library.Settings.TextSize,
			Font = Library.Fonts.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			LayoutOrder = 1,
		}, root)
	end

	-- 列宽比例 (默认均分, 可传 ColumnWidths = {0.3, 0.3, 0.4})
	local widths = {}
	local nCols = #columns
	if nCols > 0 then
		for i = 1, nCols do
			widths[i] = (colWidths and colWidths[i]) or (1 / nCols)
		end
	end
	local function cellSize(i)
		local x = 0
		for j = 1, i - 1 do
			x = x + widths[j]
		end
		local w = widths[i] or 1
		if i == nCols and nCols > 0 then
			w = 1 - x
		end
		return x, w
	end

	local headerRow = nil
	if nCols > 0 then
		headerRow = new("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 2 }, root)
		for i = 1, nCols do
			local x, w = cellSize(i)
			new("TextLabel", {
				Size = UDim2.new(w, 0, 1, 0),
				Position = UDim2.new(x, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = tostring(columns[i]),
				TextColor3 = Library.Theme.GroupHeader,
				TextSize = Library.Settings.SmallSize,
				Font = Library.Fonts.Bold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, headerRow)
		end
	end

	local rowScroll = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageTransparency = 0.5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
		LayoutOrder = 3,
	}, root)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, rowScroll)

	local el = newElement("Table", root, options.Callback)
	local rowRecords = {}
	local selectedIndex = nil

	local function buildCell(rowFrame, row, i)
		local x, w = cellSize(i)
		return new("TextLabel", {
			Size = UDim2.new(w, 0, 1, 0),
			Position = UDim2.new(x, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = (type(row) == "table") and tostring(row[i] or "") or tostring(row),
			TextColor3 = Library.Theme.LabelSub,
			TextSize = Library.Settings.SubSize,
			Font = Library.Fonts.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, rowFrame)
	end
	local function buildRow(row, index)
		local rowFrame = new("Frame", {
			Size = UDim2.new(1, -6, 0, rowHeight),
			BackgroundColor3 = Library.Theme.Control,
			BackgroundTransparency = Library.Theme.ControlTransparency,
			BorderSizePixel = 0,
			LayoutOrder = index,
		}, rowScroll)
		new("UICorner", { CornerRadius = UDim.new(0, 6) }, rowFrame)
		local accent = new("Frame", {
			Size = UDim2.fromOffset(3, 14),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Library.Theme.Accent,
			BorderSizePixel = 0,
			Visible = false,
		}, rowFrame)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, accent)
		local cells = {}
		if nCols > 0 then
			for i = 1, nCols do
				cells[i] = buildCell(rowFrame, row, i)
			end
		else
			cells[1] = buildCell(rowFrame, row, 1)
		end
		local record = { Frame = rowFrame, Cells = cells, Accent = accent, Index = index }
		rowFrame.MouseEnter:Connect(function()
			if selectedIndex ~= index then
				Library:Tween(rowFrame, { BackgroundColor3 = Library.Theme.ControlHover, BackgroundTransparency = Library.Theme.ControlHoverTransparency }, 0.1)
			end
		end)
		rowFrame.MouseLeave:Connect(function()
			if selectedIndex ~= index then
				Library:Tween(rowFrame, { BackgroundColor3 = Library.Theme.Control, BackgroundTransparency = Library.Theme.ControlTransparency }, 0.1)
			end
		end)
		rowFrame.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			if el.Disabled then
				return
			end
			el:SetSelected(index)
			el:Emit(rows[index])
		end)
		rowRecords[index] = record
		return record
	end
	local function restyleRows()
		for i, record in ipairs(rowRecords) do
			local selected = (i == selectedIndex)
			if selected then
				record.Frame.BackgroundColor3 = Library.Theme.ControlHover
				record.Frame.BackgroundTransparency = Library.Theme.ControlHoverTransparency
			else
				record.Frame.BackgroundColor3 = Library.Theme.Control
				record.Frame.BackgroundTransparency = Library.Theme.ControlTransparency
			end
			for _, cell in ipairs(record.Cells) do
				cell.TextColor3 = selected and Library.Theme.Label or Library.Theme.LabelSub
			end
		end
	end
	local function rebuild()
		for _, record in ipairs(rowRecords) do
			record.Frame:Destroy()
		end
		rowRecords = {}
		if #rows == 0 then
			local empty = new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				Text = "暂无数据",
				TextColor3 = Library.Theme.LabelSub,
				TextSize = Library.Settings.SubSize,
				Font = Library.Fonts.Text,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTransparency = 0.5,
				LayoutOrder = 1,
			}, rowScroll)
			rowRecords[1] = { Frame = empty, Cells = {}, Accent = nil, Index = nil, Empty = true }
		else
			for i, row in ipairs(rows) do
				buildRow(row, i)
			end
			restyleRows()
		end
	end

	el.SetRows = function(self, newRows)
		rows = newRows or {}
		selectedIndex = nil
		rebuild()
	end
	el.AddRow = function(self, row)
		table.insert(rows, row)
		rebuild()
	end
	el.ClearRows = function(self)
		rows = {}
		selectedIndex = nil
		rebuild()
	end
	el.SetSelected = function(self, index)
		selectedIndex = index
		restyleRows()
	end
	el.GetSelected = function(self)
		return rows[selectedIndex]
	end
	rebuild()

	el.UpdateTheme = function(self)
		if title then
			title.TextColor3 = Library.Theme.Label
			title.Font = Library.Fonts.Text
			title.TextSize = Library.Settings.TextSize
		end
		if headerRow then
			for _, label in ipairs(headerRow:GetChildren()) do
				if label.ClassName == "TextLabel" then
					label.TextColor3 = Library.Theme.GroupHeader
					label.Font = Library.Fonts.Bold
					label.TextSize = Library.Settings.SmallSize
				end
			end
		end
		for _, record in ipairs(rowRecords) do
			if not record.Empty then
				record.Frame.BackgroundColor3 = (record.Index == selectedIndex) and Library.Theme.ControlHover or Library.Theme.Control
				record.Frame.BackgroundTransparency = (record.Index == selectedIndex) and Library.Theme.ControlHoverTransparency or Library.Theme.ControlTransparency
				record.Accent.BackgroundColor3 = Library.Theme.Accent
				for _, cell in ipairs(record.Cells) do
					cell.TextColor3 = (record.Index == selectedIndex) and Library.Theme.Label or Library.Theme.LabelSub
					cell.Font = Library.Fonts.Text
					cell.TextSize = Library.Settings.SubSize
				end
			end
		end
	end
	return el
end

--═══════════════════════════════════════════════════════════════════════════
-- CreateWindow / Tab / Groupbox
--═══════════════════════════════════════════════════════════════════════════

function Library:CreateWindow(options)
	options = options or {}
	local theme = Library.Theme
	local size = options.Size or UDim2.fromOffset(600, 540)
	local sizeX, sizeY = size.X.Offset, size.Y.Offset
	if sizeX <= 0 then
		sizeX = 600
	end
	if sizeY <= 0 then
		sizeY = 540
	end
	-- 分辨率适配: 初始尺寸不超过视口的 MaxScreenRatio 比例
	local viewportInit = getViewportSize()
	local maxRatio = Library.Settings.MaxScreenRatio or 0.9
	local fitRatio = math.min(
		(viewportInit.X * maxRatio) / sizeX,
		(viewportInit.Y * maxRatio) / sizeY,
		1
	)
	if fitRatio < 1 then
		sizeX = math.floor(sizeX * fitRatio)
		sizeY = math.floor(sizeY * fitRatio)
	end
	local parent = options.Parent or Library._Parent or CoreGui

	-- [Lite10] 多窗口支持: ChildKey 可创建独立子窗口(浮动面板), 不占用主窗口 _WindowRef
	--   主窗口(无 ChildKey) = "MrrorCityLib"(同名清理保留); 子窗口 = "MrrorCityLib_"..ChildKey
	--   [Lite10] options.Name 可自定义 ScreenGui 名(规避检测/多实例), 默认如上
	local childKey = options.ChildKey
	local guiName = options.Name
		or (childKey and ("MrrorCityLib_" .. tostring(childKey)) or "MrrorCityLib")

	-- 清理同名旧 UI, 防止重复注入/重复开子窗口出现两份
	local old = parent:FindFirstChild(guiName)
	if old then
		pcall(function()
			old:Destroy()
		end)
	end

	local gui = new("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	}, nil)
	local ok = pcall(function()
		gui.Parent = parent
	end)
	local homeParent = parent
	if not ok then
		homeParent = (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")) or CoreGui
		gui.Parent = homeParent
	end
	Library._Parent = homeParent
	Library:EnsureNotifyGui()

	local windowFrame = new("Frame", {
		Size = UDim2.fromOffset(sizeX, sizeY),
		Position = UDim2.new(0.5, -sizeX / 2, 0.5, -sizeY / 2),
		BackgroundColor3 = theme.Window,
		BackgroundTransparency = theme.WindowTransparency,
		BorderSizePixel = 0,
	}, gui)
	new("UICorner", { CornerRadius = UDim.new(0, theme.Corner) }, windowFrame)
	local windowStroke = new("UIStroke", { Color = theme.Border, Transparency = theme.BorderTransparency, Thickness = 1 }, windowFrame)
	-- [Lite10] 玻璃渐变: 斜向微渐变(顶部亮/底部暗)增强玻璃感; 主题禁用时透明
	pcall(function()
		local grad = new("UIGradient", {
			Rotation = 45,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.55),
				NumberSequenceKeypoint.new(0.5, 0.0),
				NumberSequenceKeypoint.new(1, 0.35),
			}),
		}, windowFrame)
		windowFrame._GlassGradient = grad
	end)

	-- 标题栏
	local titleBar = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, windowFrame)
	local accentBar = new("Frame", {
		Size = UDim2.fromOffset(3, 16),
		Position = UDim2.new(0, 16, 0.5, -1),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
	}, titleBar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, accentBar)
	local titleLabel = new("TextLabel", {
		Size = UDim2.new(1, -210, 0, 36),
		Position = UDim2.new(0, 28, 0, 0),
		BackgroundTransparency = 1,
		Text = options.Title or "MrrorCityLib",
		TextColor3 = theme.TitleText,
		TextSize = Library.Settings.TitleSize,
		Font = Library.Fonts.Bold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, titleBar)
	-- [修复] 副标题: 紧跟标题文字右侧(按标题实测宽度定位), 不与标题/玩家信息重叠
	local function measureTitleWidth()
		local ts = game:GetService("TextService")
		local sz = ts:GetTextSize(
			titleLabel.Text or "",
			titleLabel.TextSize,
			titleLabel.Font,
			Vector2.new(1000, 36)
		)
		return sz.X
	end
	local subtitleLabel = new("TextLabel", {
		Size = UDim2.fromOffset(0, 36),
		Position = UDim2.new(0, 28 + measureTitleWidth() + 12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = options.Subtitle or "",
		TextColor3 = theme.SubtitleText,
		TextSize = Library.Settings.SmallSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, titleBar)
	-- [Lite10] 窗口状态点: 标题栏左侧小圆点, window:SetStatusDot(color, tooltipText) 控制
	local statusDot = new("Frame", {
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Library.Theme.Accent,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Visible = false,
	}, titleBar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, statusDot)
	-- [Lite8] 标题栏右上角: 玩家头像 + 玩家名 (常驻显示; 头像通过 rbxthumb 获取, 无外部请求)
	local localPlayer = Players.LocalPlayer
	local playerName = localPlayer and localPlayer.Name or "Unnamed"
	local function getHeadshotPath()
		local uid = localPlayer and localPlayer.UserId or 0
		return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(uid) .. "&w=48&h=48&format=png"
	end
	local playerInfo = new("Frame", {
		Size = UDim2.fromOffset(150, 28),
		Position = UDim2.new(1, -44, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
	}, titleBar)
	local playerAvatar = new("ImageLabel", {
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.new(1, -122, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Library.Theme.ControlActive,
		BackgroundTransparency = Library.Theme.ControlActiveTransparency,
		Image = getHeadshotPath(),
		ScaleType = Enum.ScaleType.Fit,
		BorderSizePixel = 0,
	}, playerInfo)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, playerAvatar)
	new("UIStroke", { Color = Library.Theme.Border, Transparency = 0.7, Thickness = 1 }, playerAvatar)
	local playerNameLabel = new("TextLabel", {
		Size = UDim2.new(1, -28, 1, 0),
		Position = UDim2.new(0, 28, 0, 0),
		BackgroundTransparency = 1,
		Text = playerName,
		TextColor3 = Library.Theme.LabelSub,
		TextSize = Library.Settings.SmallSize,
		Font = Library.Fonts.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, playerInfo)

	local closeButton = new("TextButton", {
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "",
		TextSize = Library.Settings.SubSize,
		Font = Library.Fonts.Bold,
		BackgroundTransparency = 1,
		TextColor3 = theme.LabelSub,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, titleBar)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, closeButton)
	-- [Lite8] 用代码绘制 X (避免字体不支持把 ✕ 显示成方框豆腐块):
	--   两条 9x2 的薄 Frame 各旋转 ±45°, 中心叠加成 X
	local closeX1 = new("Frame", {
		Size = UDim2.fromOffset(11, 2),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.LabelSub,
		BorderSizePixel = 0,
		Rotation = 45,
	}, closeButton)
	local closeX2 = new("Frame", {
		Size = UDim2.fromOffset(11, 2),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.LabelSub,
		BorderSizePixel = 0,
		Rotation = -45,
	}, closeButton)
	if closeX1:IsA("Frame") and closeX2:IsA("Frame") then
		pcall(function()
			closeX1.ZIndex = 2
			closeX2.ZIndex = 2
		end)
	end
	closeButton.MouseEnter:Connect(function()
		Library:Tween(closeButton, { BackgroundColor3 = Library.Theme.Danger, BackgroundTransparency = 0.15 }, 0.1)
		Library:Tween(closeX1, { BackgroundColor3 = Color3.new(1, 1, 1) }, 0.1)
		Library:Tween(closeX2, { BackgroundColor3 = Color3.new(1, 1, 1) }, 0.1)
	end)
	closeButton.MouseLeave:Connect(function()
		Library:Tween(closeButton, { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1 }, 0.1)
		Library:Tween(closeX1, { BackgroundColor3 = Library.Theme.LabelSub }, 0.1)
		Library:Tween(closeX2, { BackgroundColor3 = Library.Theme.LabelSub }, 0.1)
	end)
	closeButton.MouseButton1Click:Connect(function()
		Library:Toggle()
	end)

	-- 分隔线 / 标签栏
	new("Frame", {
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.new(0, 12, 0, 36),
		BackgroundColor3 = theme.Divider,
		BackgroundTransparency = theme.DividerTransparency,
		BorderSizePixel = 0,
	}, windowFrame)
	local tabBar = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 12, 0, 42),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.X,
	}, windowFrame)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabBar)
	new("Frame", {
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.new(0, 12, 0, 76),
		BackgroundColor3 = theme.Divider,
		BackgroundTransparency = theme.DividerTransparency,
		BorderSizePixel = 0,
	}, windowFrame)

	-- 内容区
	local contentFrame = new("Frame", {
		Size = UDim2.new(1, -24, 1, -110),
		Position = UDim2.new(0, 12, 0, 82),
		BackgroundTransparency = 1,
	}, windowFrame)

	-- [Lite10] 窗口状态栏: 底部常驻一条 text, window:SetStatus() 可更新; ShowFPS 时显示帧率
	local statusBar = nil
	local statusLabel = nil
	local fpsLabel = nil
	if options.StatusBar ~= false then
		statusBar = new("Frame", {
			Size = UDim2.new(1, -24, 0, 20),
			Position = UDim2.new(0, 12, 1, -24),
			BackgroundColor3 = Library.Theme.Control,
			BackgroundTransparency = Library.Theme.ControlTransparency,
			BorderSizePixel = 0,
		}, windowFrame)
		new("UICorner", { CornerRadius = UDim.new(0, 6) }, statusBar)
		statusLabel = new("TextLabel", {
			Size = UDim2.new(1, -70, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = options.StatusText or "就绪",
			TextColor3 = Library.Theme.LabelSub,
			TextSize = Library.Settings.SmallSize,
			Font = Library.Fonts.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, statusBar)
		if options.ShowFPS then
			fpsLabel = new("TextLabel", {
				Size = UDim2.fromOffset(56, 20),
				Position = UDim2.new(1, -64, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Text = "FPS: --",
				TextColor3 = Library.Theme.LabelSub,
				TextSize = Library.Settings.SmallSize,
				Font = Library.Fonts.Text,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Center,
			}, statusBar)
			task.spawn(function()
				local lastT, frames = os.clock(), 0
				while statusBar and statusBar.Parent do
					frames = frames + 1
					local dt = os.clock() - lastT
					if dt >= 0.5 then
						if fpsLabel then
							fpsLabel.Text = "FPS: " .. tostring(math.floor(frames / dt))
						end
						frames, lastT = 0, os.clock()
					end
					task.wait()
				end
			end)
		end
	end

	-- 全控件搜索过滤 (CreateWindow({Searchable = true}) 时启用, 作用于当前激活 Tab)
	local contentTop = 0
	local filterBox = nil
	if options.Searchable then
		contentTop = 28
		filterBox = new("TextBox", {
			Size = UDim2.fromOffset(150, 24),
			Position = UDim2.new(1, -4, 0, 0),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = theme.ControlActive,
			BackgroundTransparency = theme.ControlActiveTransparency,
			Text = "",
			PlaceholderText = "搜索控件...",
			TextSize = Library.Settings.SubSize,
			Font = Library.Fonts.Text,
			TextColor3 = Library.Theme.Label,
			PlaceholderColor3 = Library.Theme.LabelSub,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, contentFrame)
		new("UICorner", { CornerRadius = UDim.new(0, 6) }, filterBox)
		filterBox.TextChanged:Connect(function()
			if activeTab then
				activeTab:FilterControls(filterBox.Text)
			end
		end)
	end

	local window = { Object = windowFrame, Gui = gui, Tabs = {} }
	local activeTab = nil

	local function styleTab(tab)
		local t = Library.Theme
		local selected = (tab == activeTab)
		tab.Button.BackgroundColor3 = selected and t.TabSelected or t.TabUnselected
		tab.Button.BackgroundTransparency = selected and 0 or t.TabUnselectedTransparency
		tab.Button.TextColor3 = selected and t.TabSelectedText or t.TabUnselectedText
		tab.Button.Font = Library.Fonts.Text
		tab.Button.TextSize = Library.Settings.TextSize
	end

	-- 窗口拖拽 (仅标题栏, 避开关闭按钮 + 隐藏键芯片; IsLocked=true 时禁用)
	local grabOffset = nil
	Library:TrackDrag(titleBar, function(mouse)
		grabOffset = mouse - windowFrame.AbsolutePosition
	end, function(mouse)
		if not grabOffset then
			return
		end
		local viewport = getViewportSize()
		local maxX = math.max(8, viewport.X - sizeX - 8)
		local maxY = math.max(8, viewport.Y - sizeY - 8)
		local x = clamp(mouse.X - grabOffset.X, 8, maxX)
		local y = clamp(mouse.Y - grabOffset.Y, 8, maxY)
		windowFrame.Position = UDim2.fromOffset(x, y)
	end, function()
		grabOffset = nil
		Library.Config._WindowPosition = { x = windowFrame.Position.X.Offset, y = windowFrame.Position.Y.Offset }
		Library:_AutoSave()
	end, function()
		-- [Lite7] 窗口锁定时禁用拖拽; 并避开关闭按钮 (玩家信息区不拦拖拽)
		if window.IsLocked then
			return false
		end
		if Library:IsMouseOver(closeButton) then
			return false
		end
		return true
	end)

	-- 窗口缩放 (右下角手柄, 尺寸持久化到配置)
	local resizeStart = nil
	local resizeHandle = new("Frame", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
	}, windowFrame)
	local resizeIcon = new("TextLabel", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0.5, -6, 0.5, -7),
		BackgroundTransparency = 1,
		Text = "◢",
		TextSize = Library.Settings.SmallSize,
		Font = Library.Fonts.Text,
		TextColor3 = theme.SubtitleText,
	}, resizeHandle)
	Library:TrackDrag(resizeHandle, function(mouse)
		resizeStart = { x = mouse.X, y = mouse.Y, w = sizeX, h = sizeY }
	end, function(mouse)
		if not resizeStart then
			return
		end
		local viewport = getViewportSize()
		sizeX = clamp(resizeStart.w + (mouse.X - resizeStart.x), 380, math.max(380, viewport.X - 8))
		sizeY = clamp(resizeStart.h + (mouse.Y - resizeStart.y), 300, math.max(300, viewport.Y - 8))
		windowFrame.Size = UDim2.fromOffset(sizeX, sizeY)
	end, function()
		resizeStart = nil
		Library.Config._WindowSize = { w = sizeX, h = sizeY }
		Library:_AutoSave()
	end, function()
		-- [Lite7] 窗口锁定时禁用缩放
		return not window.IsLocked
	end)

	--══════════ 标签页 ══════════
	-- [Lite7] AddTab(info, opts): opts.isSettings=true 时该 Tab 固定排最后(库内置设置页用)
	--   普通 Tab LayoutOrder = 添加序号, 设置 Tab = 999999, UIListLayout 按 LayoutOrder 排 → 设置永远最后
	function window:AddTab(info, opts)
		info = info or {}
		opts = opts or {}
		local name = info.Name or ("Tab" .. (#window.Tabs + 1))
		local isSettings = opts.isSettings and true or false
		if isSettings and window._SettingsTab then
			return window._SettingsTab  -- 防止重复创建内置设置页
		end
		local scroll = new("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -contentTop),
			Position = UDim2.new(0, 0, 0, contentTop),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromOffset(0, 0),
			Visible = false,
		}, contentFrame)
		-- [Lite10] 内容区平滑滚动(鼠标滚轮)
		pcall(function() Library:AddSmoothScroll(scroll, 40) end)
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, scroll)
		local leftColumn = new("Frame", {
			Size = UDim2.new(0.5, -10, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, scroll)
		local rightColumn = new("Frame", {
			Size = UDim2.new(0.5, -10, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, scroll)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, leftColumn)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, rightColumn)

	-- Tab 图标: 传 "rbxassetid://..." 时用 ImageLabel, 其他文本视为字形前缀
	local icon = info.Icon
	local hasImageIcon = (type(icon) == "string") and (icon:find("^rbxassetid://") ~= nil)
	local buttonText = name
	if type(icon) == "string" and not hasImageIcon then
		buttonText = icon .. "  " .. name
	end
	local buttonWidth = getTextSize(buttonText, Library.Settings.TextSize, Library.Fonts.Text).X + 26
	local button = new("TextButton", {
		Size = UDim2.fromOffset(buttonWidth, 26),
		Text = buttonText,
		TextSize = Library.Settings.TextSize,
		Font = Library.Fonts.Text,
		BackgroundColor3 = theme.TabUnselected,
		BackgroundTransparency = theme.TabUnselectedTransparency,
		TextColor3 = theme.TabUnselectedText,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		-- [Lite7] 设置Tab固定最后, 普通Tab按序
		LayoutOrder = isSettings and 999999 or (#window.Tabs + 1),
	}, tabBar)
	new("UICorner", { CornerRadius = UDim.new(0, 7) }, button)
	if hasImageIcon then
		local iconLabel = new("ImageLabel", {
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.new(0, 8, 0.5, -7),
			BackgroundTransparency = 1,
			Image = icon,
			ZIndex = 2,
		}, button)
		iconLabel.ImageColor3 = theme.LabelSub
	end

		local tab = { Name = name, Object = scroll, Button = button, IsSettings = isSettings }
		-- [Lite10] Tab 徽标: 按钮右侧小圆角标, tab:SetBadge(text) 控制
		local tabBadge = new("TextLabel", {
			Size = UDim2.fromOffset(0, 14),
			Position = UDim2.new(1, -4, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Library.Theme.Danger,
			BackgroundTransparency = 0.05,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 9,
			Font = Library.Fonts.Bold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Visible = false,
			ZIndex = 3,
		}, button)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, tabBadge)
		tab.SetBadge = function(self, text)
			if not tabBadge then
				return
			end
			if text == nil or text == "" then
				tabBadge.Visible = false
				return
			end
			local ts = game:GetService("TextService")
			local sz = ts:GetTextSize(tostring(text), 9, Library.Fonts.Bold, Vector2.new(60, 14))
			tabBadge.Size = UDim2.fromOffset(math.max(14, sz.X + 8), 14)
			tabBadge.Text = tostring(text)
			tabBadge.Visible = true
		end
		table.insert(window.Tabs, tab)
		if isSettings then
			window._SettingsTab = tab
		end
		if not activeTab then
			activeTab = tab
		end
		tab.Object.Visible = (tab == activeTab)
		styleTab(tab)

		button.MouseEnter:Connect(function()
			if activeTab ~= tab then
				Library:Tween(button, {
					BackgroundColor3 = Library.Theme.ControlHover,
					BackgroundTransparency = Library.Theme.ControlHoverTransparency,
				})
			end
		end)
		button.MouseLeave:Connect(function()
			if activeTab ~= tab then
				Library:Tween(button, {
					BackgroundColor3 = Library.Theme.TabUnselected,
					BackgroundTransparency = Library.Theme.TabUnselectedTransparency,
				})
			end
		end)
		button.MouseButton1Click:Connect(function()
			if activeTab == tab then
				return
			end
			activeTab.Object.Visible = false
			activeTab = tab
			tab.Object.Visible = true
			for _, t in ipairs(window.Tabs) do
				styleTab(t)
			end
			if filterBox then
				activeTab:FilterControls(filterBox.Text)
			end
		end)

		local keyPrefix = name

		--══════════ 分组框 (左/右双列) ══════════
		function tab:AddGroupbox(gbInfo)
			gbInfo = gbInfo or {}
			local gbName = gbInfo.Name or "Group"
			local column = (gbInfo.Side == 2) and rightColumn or leftColumn
			local groupFrame = new("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = theme.Group,
				BackgroundTransparency = theme.GroupTransparency,
				BorderSizePixel = 0,
			}, column)
			new("UICorner", { CornerRadius = UDim.new(0, theme.ElementCorner) }, groupFrame)
			local groupStroke = new("UIStroke", { Color = theme.Border, Transparency = theme.BorderTransparency, Thickness = 1 }, groupFrame)
			new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, groupFrame)
			new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, groupFrame)
			-- 分组头: Collapsible = true 时带箭头, 点击折叠
			local isCollapsible = gbInfo.Collapsible and true or false
			local collapsed = isCollapsible and gbInfo.DefaultCollapsed and true or false
			local header = nil
			local headerFrame = nil
			local arrowLabel = nil
			if isCollapsible then
				headerFrame = new("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
				}, groupFrame)
				arrowLabel = new("TextLabel", {
					Size = UDim2.fromOffset(16, 18),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 1,
					Text = "▾",
					TextColor3 = theme.GroupHeader,
					TextSize = Library.Settings.SmallSize,
					Font = Library.Fonts.Text,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextYAlignment = Enum.TextYAlignment.Center,
				}, headerFrame)
				header = new("TextLabel", {
					Size = UDim2.new(1, -26, 0, 18),
					BackgroundTransparency = 1,
					Text = gbName,
					TextColor3 = theme.GroupHeader,
					TextSize = Library.Settings.HeaderSize,
					Font = Library.Fonts.Bold,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
				}, headerFrame)
			else
				header = new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text = gbName,
					TextColor3 = theme.GroupHeader,
					TextSize = Library.Settings.SubSize,
					Font = Library.Fonts.Bold,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				}, groupFrame)
			end
			local gbContent = new("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, groupFrame)
			new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, gbContent)

			local group = {
				Name = gbName,
				Object = groupFrame,
				Content = gbContent,
				_KeyPrefix = keyPrefix .. "/" .. gbName,
			}
			group.AddButton = function(self, opts)
				return addButton(gbContent, opts, group._KeyPrefix)
			end
			group.AddToggle = function(self, opts)
				return addToggle(gbContent, opts, group._KeyPrefix)
			end
			group.AddSlider = function(self, opts)
				return addSlider(gbContent, opts, group._KeyPrefix)
			end
			group.AddDropdown = function(self, opts)
				return addDropdown(gbContent, opts, group._KeyPrefix)
			end
			group.AddInput = function(self, opts)
				return addInput(gbContent, opts, group._KeyPrefix)
			end
			group.AddKeybind = function(self, opts)
				return addKeybind(gbContent, opts, group._KeyPrefix)
			end
			group.AddColorPicker = function(self, opts)
				return addColorPicker(gbContent, opts, group._KeyPrefix)
			end
			group.AddLabel = function(self, opts)
				return addLabel(gbContent, opts)
			end
			group.AddDivider = function(self)
				return addDivider(gbContent)
			end
			group.AddRangeSlider = function(self, opts)
				return addRangeSlider(gbContent, opts, group._KeyPrefix)
			end
			group.AddStepper = function(self, opts)
				return addStepper(gbContent, opts, group._KeyPrefix)
			end
			group.AddProgressBar = function(self, opts)
				return addProgressBar(gbContent, opts)
			end
			group.AddParagraph = function(self, opts)
				return addParagraph(gbContent, opts)
			end
			-- 自定义控件 (Library:RegisterCustomControl 注册后可用)
			group.AddCustom = function(self, controlName, opts)
				local info = Library._CustomControls[controlName]
				if not info then
					warn("MrrorCityLib: 未注册的自定义控件 '" .. tostring(controlName) .. "'")
					return nil
				end
				return info.Build(gbContent, opts, group._KeyPrefix)
			end
			group.AddCheckboxGroup = function(self, opts)
				return addCheckboxGroup(gbContent, opts, group._KeyPrefix)
			end
			group.AddRadioGroup = function(self, opts)
				return addRadioGroup(gbContent, opts, group._KeyPrefix)
			end
			group.AddTable = function(self, opts)
				return addTable(gbContent, opts)
			end
			-- 自动 Tooltip 支持: 所有 AddXxx({Tooltip="..."}) 自动挂提示
			for _, methodName in ipairs({
				"AddButton", "AddToggle", "AddSlider", "AddDropdown", "AddInput",
				"AddKeybind", "AddColorPicker", "AddRangeSlider", "AddStepper",
				"AddProgressBar", "AddCheckboxGroup", "AddRadioGroup", "AddLabel",
				"AddParagraph", "AddTable",
			}) do
				local inner = group[methodName]
				if inner then
					group[methodName] = function(self, opts)
						local el = inner(self, opts)
						if type(opts) == "table" and opts.Tooltip and el and el.Object then
							Library:AddTooltip(el.Object, opts.Tooltip)
						end
						return el
					end
				end
			end
			-- 折叠控制
			group.SetCollapsed = function(self, value)
				collapsed = not not value
				gbContent.Visible = not collapsed
				if arrowLabel then
					arrowLabel.Text = collapsed and "▸" or "▾"
				end
			end
			group.IsCollapsed = function(self)
				return collapsed
			end
			if isCollapsible then
				headerFrame.InputBegan:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
						return
					end
					group:SetCollapsed(not collapsed)
				end)
				headerFrame.MouseEnter:Connect(function()
					Library:Tween(headerFrame, { BackgroundColor3 = Library.Theme.ControlHover, BackgroundTransparency = 0.72 }, 0.1)
				end)
				headerFrame.MouseLeave:Connect(function()
					Library:Tween(headerFrame, { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1 }, 0.1)
				end)
				group:SetCollapsed(collapsed)
			end
			group.UpdateTheme = function(self)
				groupFrame.BackgroundColor3 = Library.Theme.Group
				groupFrame.BackgroundTransparency = Library.Theme.GroupTransparency
				groupStroke.Color = Library.Theme.Border
				groupStroke.Transparency = Library.Theme.BorderTransparency
				header.TextColor3 = Library.Theme.GroupHeader
				header.Font = Library.Fonts.Bold
				header.TextSize = Library.Settings.HeaderSize
				if arrowLabel then
					arrowLabel.TextColor3 = Library.Theme.GroupHeader
					arrowLabel.Font = Library.Fonts.Text
					arrowLabel.TextSize = Library.Settings.SmallSize
				end
				if headerFrame then
					headerFrame.BackgroundTransparency = 1
				end
			end
			Library:Register(group)
			return group
		end

		function tab:AddLeftGroupbox(name)
			return self:AddGroupbox({ Name = name, Side = 1 })
		end
		function tab:AddRightGroupbox(name)
			return self:AddGroupbox({ Name = name, Side = 2 })
		end
		-- 按关键词过滤本 Tab 内所有控件 (空串恢复全部; 匹配元素内任意文字层)
		function tab:FilterControls(keyword)
			keyword = (keyword ~= nil) and string.lower(tostring(keyword)) or ""
			for _, element in ipairs(Library.Registry) do
				local obj = element.Object
				if obj and obj:IsDescendantOf(scroll) then
					local visible = objectTextsMatch(obj, keyword)
					if element.SetVisible then
						element:SetVisible(visible)
					elseif obj.Visible ~= nil then
						obj.Visible = visible
					end
				end
			end
		end
		return tab
	end

	--══════════ 窗口方法 ══════════
	function window:SetTitle(text)
		titleLabel.Text = text
	end
	-- [Lite10] 状态栏文本更新 (CreateWindow({StatusBar=true}) 时有效)
	function window:SetStatus(text)
		if statusLabel then
			statusLabel.Text = tostring(text or "")
		end
	end
	-- [Lite10] 状态点: SetStatusDot(nil) 隐藏; SetStatusDot(Color3) 显示+变色; 第三参为 hover 提示
	function window:SetStatusDot(color, tooltipText)
		if not statusDot then
			return
		end
		if color == nil then
			statusDot.Visible = false
			return
		end
		statusDot.Visible = true
		statusDot.BackgroundColor3 = color
		if tooltipText and Library.AddTooltip then
			pcall(function() Library:AddTooltip(statusDot, tooltipText) end)
		end
	end
	function window:SetSubtitle(text)
		subtitleLabel.Text = text
	end
	function window:SetSize(w, h)
		sizeX = clamp(tonumber(w) or sizeX, 380, 4000)
		sizeY = clamp(tonumber(h) or sizeY, 300, 4000)
		windowFrame.Size = UDim2.fromOffset(sizeX, sizeY)
	end
	-- [Lite7] 窗口透明度 (0~0.8, 覆盖主题默认; 0 = 跟随主题) + 恢复默认尺寸/位置
	function window:SetTransparency(trans)
		trans = clamp(tonumber(trans) or 0, 0, 0.85)
		if trans <= 0 then
			-- 跟随主题
			windowFrame.BackgroundTransparency = Library.Theme.WindowTransparency
		else
			windowFrame.BackgroundTransparency = trans
		end
		Library.Config._WindowTransparency = trans
		Library:_AutoSave()
	end
	function window:ResetWindowState()
		local viewport = getViewportSize()
		sizeX = math.min(620, viewport.X * (Library.Settings.MaxScreenRatio or 0.9))
		sizeY = math.min(540, viewport.Y * (Library.Settings.MaxScreenRatio or 0.9))
		windowFrame.Size = UDim2.fromOffset(sizeX, sizeY)
		windowFrame.Position = UDim2.new(0.5, -sizeX / 2, 0.5, -sizeY / 2)
		Library.Config._WindowPosition = nil
		Library.Config._WindowSize = nil
		Library.Config._WindowTransparency = nil
		windowFrame.BackgroundTransparency = Library.Theme.WindowTransparency
		Library:_AutoSave()
	end
	-- 分辨率适配: 把窗口尺寸夹紧到视口比例内 (默认 MaxScreenRatio)
	function window:FitToScreen(ratio)
		local viewport = getViewportSize()
		ratio = ratio or (Library.Settings.MaxScreenRatio or 0.9)
		sizeX = clamp(sizeX, 380, math.max(380, viewport.X * ratio))
		sizeY = clamp(sizeY, 300, math.max(300, viewport.Y * ratio))
		windowFrame.Size = UDim2.fromOffset(sizeX, sizeY)
	end
	function window:SetVisible(visible)
		gui.Enabled = visible
	end
	-- [Lite7] 程序化设置隐藏键 (与标题栏芯片等价): 传 Enum.KeyCode 或键名字符串
	function window:SetToggleKey(key)
		if type(key) == "string" then
			local keyOk, keyEnum = pcall(function()
				return Enum.KeyCode[key]
			end)
			key = keyOk and keyEnum or Enum.KeyCode.None
		end
		if key == nil or key == Enum.KeyCode.None then
			Library.Config._ToggleKey = Enum.KeyCode.None
		else
			Library.Config._ToggleKey = key
		end
		Library:SaveConfig()
		paintHotkeyChip()
		Library:fire("togglekey:changed", Library.Config._ToggleKey)
	end
	function window:GetToggleKey()
		local k = Library.Config._ToggleKey
		return (k == nil or k == Enum.KeyCode.None) and nil or k
	end
	function window:Toggle()
		Library:Toggle()
	end
	function window:Destroy()
		if Library._WindowRef == window then
			Library._WindowRef = nil
		end
		-- [Lite10] 从 _Windows 集合移除
		if Library._Windows then
			for i = #Library._Windows, 1, -1 do
				if Library._Windows[i] == window then
					table.remove(Library._Windows, i)
				end
			end
		end
		pcall(function()
			gui:Destroy()
		end)
	end
	window._UpdateTheme = function(self)
		local t = Library.Theme
		windowFrame.BackgroundColor3 = t.Window
		windowFrame.BackgroundTransparency = t.WindowTransparency
		windowStroke.Color = t.Border
		windowStroke.Transparency = t.BorderTransparency
		accentBar.BackgroundColor3 = t.Accent
		titleLabel.TextColor3 = t.TitleText
		titleLabel.Font = Library.Fonts.Bold
		titleLabel.TextSize = Library.Settings.TitleSize
		subtitleLabel.TextColor3 = t.SubtitleText
		subtitleLabel.Font = Library.Fonts.Text
		subtitleLabel.TextSize = Library.Settings.SmallSize
		closeButton.TextColor3 = t.LabelSub
		closeButton.Font = Library.Fonts.Bold
		closeButton.TextSize = Library.Settings.SubSize
		resizeIcon.TextColor3 = t.SubtitleText
		resizeIcon.Font = Library.Fonts.Text
		resizeIcon.TextSize = Library.Settings.SmallSize
		for _, tab in ipairs(window.Tabs) do
			styleTab(tab)
		end
	end

	-- 恢复记忆的窗口位置/尺寸 (并夹紧到视口内)
	local savedPos = Library.Config._WindowPosition
	if savedPos and savedPos.x and savedPos.y then
		local viewport = getViewportSize()
		local px = clamp(savedPos.x, 0, math.max(0, viewport.X - sizeX))
		local py = clamp(savedPos.y, 0, math.max(0, viewport.Y - sizeY))
		windowFrame.Position = UDim2.fromOffset(px, py)
	end
	local savedSize = Library.Config._WindowSize
	if savedSize and savedSize.w and savedSize.h then
		sizeX, sizeY = savedSize.w, savedSize.h
		windowFrame.Size = UDim2.fromOffset(sizeX, sizeY)
	end

	-- 全局显隐热键 (只在首个窗口注册一次)
	if not Library._HotkeyConnected then
		Library._HotkeyConnected = true
		local hotkeyConn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			if Library._BindingActive then
				return
			end
			if Library.Config._ToggleKey ~= Enum.KeyCode.None and input.KeyCode == Library.Config._ToggleKey then
				Library:Toggle()
			end
		end)
		table.insert(Library._GlobalConnections, hotkeyConn)
	end

	-- 点击外部关闭下拉/取色面板
	if not Library._GateConnected then
		Library._GateConnected = true
		local gateConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			for _, fn in ipairs(Library._GateListeners) do
				fn(input)
			end
		end)
		table.insert(Library._GlobalConnections, gateConn)
	end

	--══════════ 库内置设置页 (自动创建, 永远排最后) ══════════
	-- [Lite7] 任何脚本调用 CreateWindow 后自动带一个"设置"Tab, 收纳库内置功能:
	--   主题切换 / 隐藏键 / 动画开关 / 配置保存加载重置 / 水印 / 卸载 / 版本
	--   脚本也可再调 Library:AddSettingsControls 补充自定义项, 设置Tab恒在最后.
	do
		local SettingsTab = window:AddTab({ Name = "设置" }, { isSettings = true })
		local GroupGeneral = SettingsTab:AddLeftGroupbox("通用")
		local GroupConfig = SettingsTab:AddRightGroupbox("配置")
		-- [Lite8] 玩家信息 (头像 + 名称, 常驻显示在设置页顶部)
		do
			local playerFrame = new("Frame", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = Library.Theme.Control,
				BackgroundTransparency = Library.Theme.ControlTransparency,
				BorderSizePixel = 0,
			}, GroupGeneral.Content)
			new("UICorner", { CornerRadius = UDim.new(0, Library.Theme.ElementCorner) }, playerFrame)
			local pAv = new("ImageLabel", {
				Size = UDim2.fromOffset(24, 24),
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Library.Theme.ControlActive,
				BackgroundTransparency = Library.Theme.ControlActiveTransparency,
				Image = getHeadshotPath(),
				ScaleType = Enum.ScaleType.Fit,
				BorderSizePixel = 0,
			}, playerFrame)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, pAv)
			new("UIStroke", { Color = Library.Theme.Border, Transparency = 0.7, Thickness = 1 }, pAv)
			new("TextLabel", {
				Size = UDim2.new(1, -48, 1, 0),
				Position = UDim2.new(0, 42, 0, 0),
				BackgroundTransparency = 1,
				Text = playerName,
				TextColor3 = Library.Theme.Label,
				TextSize = Library.Settings.TextSize,
				Font = Library.Fonts.Bold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, playerFrame)
			GroupGeneral._PlayerInfo = playerFrame
		end
		-- 主题
		GroupGeneral:AddDropdown({
			Name = "主题",
			Options = { "深色玻璃", "浅色玻璃" },
			Default = (Library.Theme.Name == "浅色玻璃" or Library.Config._Theme == "Light") and "浅色玻璃" or "深色玻璃",
			Callback = function(v)
				Library:SetTheme((v == "浅色玻璃") and "Light" or "Dark")
			end,
		})
		-- 隐藏键 (Keybind 控件, 点击绑定任意键; 与标题栏芯片双向同步)
		local settingsKeybind = GroupGeneral:AddKeybind({
			Name = "隐藏键",
			Default = Library.Config._ToggleKey or Enum.KeyCode.RightShift,
			Callback = function(key)
				Library.Config._ToggleKey = key
				Library:SaveConfig()
				Library:fire("togglekey:changed", key)
			end,
		})
		Library:on("togglekey:changed", function(key)
			if settingsKeybind and settingsKeybind.Value ~= key then
				pcall(function() settingsKeybind:SetValue(key, true) end)
			end
		end)
		-- 动画开关
		GroupGeneral:AddToggle({
			Name = "交互动画",
			Default = Library.Settings.Animate ~= false,
			Callback = function(v)
				Library.Settings.Animate = (v == true)
			end,
		})
		GroupGeneral:AddButton({
			Name = "显示水印",
			Callback = function()
				Library:SetWatermark("MrrorCityLib v" .. tostring(Library.Version) .. " 运行中")
			end,
		})
		GroupGeneral:AddButton({
			Name = "隐藏水印",
			Callback = function()
				Library:SetWatermarkVisibility(false)
			end,
		})
		-- [Lite7] 窗口透明度 (0=跟随主题, 1-85为自定义)
		GroupGeneral:AddSlider({
			Name = "窗口透明度",
			Min = 0,
			Max = 60,
			Default = (Library.Config._WindowTransparency or 0) * 100,
			Callback = function(v)
				local trans = tonumber(v) or 0
				window:SetTransparency(trans <= 0 and 0 or (trans / 100))
			end,
		})
		-- [Lite7] 通知位置
		GroupGeneral:AddDropdown({
			Name = "通知位置",
			Options = { "右上", "左上", "右下", "左下" },
			Default = "右上",
			Callback = function(v)
				local map = { ["右上"] = "top-right", ["左上"] = "top-left", ["右下"] = "bottom-right", ["左下"] = "bottom-left" }
				Library:SetNotifyPosition(map[v] or "top-right")
			end,
		})
		-- [Lite7] 窗口锁定 (禁用拖拽/缩放)
		GroupGeneral:AddToggle({
			Name = "窗口锁定(防误拖)",
			Default = false,
			Callback = function(v)
				window.IsLocked = (v == true)
			end,
		})
		GroupGeneral:AddButton({
			Name = "恢复默认窗口",
			Callback = function()
				window:ResetWindowState()
				Library:Notify({ Title = "窗口", Content = "已恢复默认尺寸/位置", Duration = 3 })
			end,
		})
		GroupGeneral:AddLabel({ Text = "版本: v" .. tostring(Library.Version or "?") })
		-- 配置
		GroupConfig:AddButton({
			Name = "保存配置",
			Callback = function()
				Library:SaveConfig()
				Library:Notify({ Title = "配置", Content = "已保存", Duration = 3 })
			end,
		})
		GroupConfig:AddButton({
			Name = "加载配置",
			Callback = function()
				Library:LoadConfig()
				Library:Notify({ Title = "配置", Content = "已加载", Duration = 3 })
			end,
		})
		GroupConfig:AddButton({
			Name = "重置配置",
			Callback = function()
				Library:ResetConfig()
				Library:Notify({ Title = "配置", Content = "已重置为默认", Duration = 3 })
			end,
		})
		GroupConfig:AddButton({
			Name = "卸载库",
			Callback = function()
				Library:Unload()
			end,
		})
		-- [Lite10] 调试/工具体验组
		GroupConfig:AddButton({
			Name = "复制配置JSON",
			Callback = function()
				local json = Library:ExportConfig()
				if json then
					Library:Toast({ Content = "配置已导出(详见调试日志)", Subtitle = "复制可用作导入", Type = "success", Duration = 3 })
					Library:DebugLog("配置JSON: " .. json:sub(1, 200) .. "...", "info")
				else
					Library:Toast("导出失败", 2, "error")
				end
			end,
		})
		GroupConfig:AddInput({
			Name = "导入配置JSON",
			PlaceholderText = "粘贴 JSON 后回车",
			Callback = function(v)
				if v and Library:ImportConfig(v) then
					Library:Toast("配置已导入", 2, "success")
				else
					Library:Toast("导入失败(JSON 无效)", 2, "error")
				end
			end,
		})
		GroupConfig:AddButton({
			Name = "打开调试日志",
			Callback = function()
				Library:ShowDebugLog()
			end,
		})
		GroupConfig:AddButton({
			Name = "测试状态点",
			Callback = function()
				window:SetStatusDot(Color3.fromRGB(0, 255, 0), "已连接(测试)")
				Library:Toast("状态点已显示(绿色)", 2, "success")
			end,
		})
		GroupConfig:AddButton({
			Name = "测试Tab徽标",
			Callback = function()
				if window.Tabs and window.Tabs[1] then
					window.Tabs[1]:SetBadge("3")
				end
			end,
		})
	end

	-- [Lite10] 多窗口注册: 主窗口设 _WindowRef(兼容旧逻辑), 子窗口只进 _Windows
	if not childKey then
		Library._WindowRef = window
	else
		window.IsChild = true
		window.ChildKey = childKey
	end
	if not Library._Windows then
		Library._Windows = {}
	end
	table.insert(Library._Windows, window)
	Library:fire("window:created", window, childKey)
	-- [Lite10] 窗口创建后自动安装已注册插件(主窗口才装; 子窗口独立)
	if not childKey and #Library._Plugins > 0 then
		Library:InstallPlugins(window)
	end

	-- [Lite7修复] 启动动画: 窗口缩放滑入 (UIScale + Position 上浮)
	--   ScreenGui.GroupTransparency 在部分客户端不支持, 改用 UIScale/Position (Frame 通用属性)
	if Library.Settings.Animate and gui and windowFrame then
		pcall(function()
			local winScale = windowFrame:FindFirstChildOfClass("UIScale")
			if not winScale then
				winScale = Instance.new("UIScale")
				winScale.Parent = windowFrame
			end
			local startPos = windowFrame.Position
			winScale.Scale = 0.9
			windowFrame.Position = UDim2.fromOffset(startPos.X.Offset, math.max(0, startPos.Y.Offset - 20))
			Library:Tween(winScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			Library:Tween(windowFrame, { Position = startPos }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		end)
	end

	-- 延后到本脚本执行完再恢复配置, 保证调用方紧接着添加的控件也被注册
	task.defer(function()
		Library:LoadConfig()
	end)

	return window
end

--═══════════════════════════════════════════════════════════════════════════
-- 防重复注入: 通过 _G 桥接表回收旧实例
--   同一脚本重复 loadstring 时, 旧库的全局热键/外部点击监听/通知 GUI 会被
--   Unload 干净拆除, 保证任何时刻只存在一套 UI 与一套全局监听
--═══════════════════════════════════════════════════════════════════════════

if type(_G.__MrrorCityLib) == "table" and type(_G.__MrrorCityLib.Unload) == "function" then
	pcall(_G.__MrrorCityLib.Unload)
end
_G.__MrrorCityLib = {
	Unload = function()
		Library:Unload()
	end,
}

return Library
