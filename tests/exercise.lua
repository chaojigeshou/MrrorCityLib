-- 冒烟测试的"用法练习": 通过公开 API 完整构建一遍 (v0.4 覆盖)
-- 事件总线
local evWindow = 0
local evTheme = 0
local evCustom = 0
Library:on("window:created", function(w)
	evWindow = evWindow + 1
end)
Library:once("theme:changed", function(name)
	evTheme = evTheme + 1
end)
Library:on("custom:test", function(a, b)
	evCustom = evCustom + 1
end)
Library:fire("custom:test", 1, 2)

local Window = Library:CreateWindow({
	Title = "SmokeTest",
	Subtitle = "v" .. Library.Version,
	Size = UDim2.fromOffset(600, 540),
	Searchable = true,
})
local Tab = Window:AddTab("Main")
local Left = Tab:AddLeftGroupbox("左侧")
local Right = Tab:AddRightGroupbox("右侧")

Left:AddButton({ Name = "按钮", Tooltip = "这是按钮提示", Callback = function() end })
local Tog = Left:AddToggle({ Name = "开关", Default = true, Callback = function(v) end })
local Sld = Left:AddSlider({ Name = "滑条", Min = 0, Max = 100, Default = 50, Suffix = "%", Callback = function(v) end })
local Dd = Left:AddDropdown({ Name = "下拉", Options = { "A", "B", "C" }, Default = "B", Callback = function(v) end })
Dd:AddOption("D")
local GD = Left:AddDropdown({
	Name = "分组下拉",
	Options = { "普通" },
	Groups = {
		{ Title = "稀有度", Options = { "史诗", "传说" } },
		{ Title = "其他", Options = { "特殊" } },
	},
	Default = "史诗",
	Callback = function(v) end,
})
GD:AddGroup("新组", { "X", "Y" })
GD:AddOption("最后")
local Multi = Left:AddDropdown({
	Name = "多选",
	Multi = true,
	Options = { "Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7", "Q8", "Q9", "Q10" },
	Default = { "Q1", "Q3" },
	Callback = function(v) end,
})
local Range = Left:AddRangeSlider({ Name = "区间", Min = 1, Max = 10, DefaultLow = 2, DefaultHigh = 8, Callback = function(v) end })
local Step = Left:AddStepper({ Name = "步进", Min = 1, Max = 10, Default = 5, Step = 1, Callback = function(v) end })
local Prog = Left:AddProgressBar({ Name = "进度", Value = 0.35 })

local Inp = Right:AddInput({ Name = "输入", PlaceholderText = "x", Callback = function(v) end })
local InpMulti = Right:AddInput({ Name = "多行", Multiline = true, Height = 70, PlaceholderText = "多行文本", Callback = function(v) end })
local InpPwd = Right:AddInput({ Name = "密码", Password = true, PlaceholderText = "密码", Callback = function(v) end })
InpPwd:SetValue("secret123")
local Kb = Right:AddKeybind({ Name = "热键", Default = Enum.KeyCode.V, Callback = function(k) end })
local Cp = Right:AddColorPicker({ Name = "颜色", Default = Color3.fromRGB(255, 80, 90), Callback = function(c) end })
local CpA = Right:AddColorPicker({
	Name = "颜色+透明",
	Transparency = true,
	DefaultTransparency = 0.35,
	Presets = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 200, 255) },
	Callback = function(c, t) end,
})
CpA:SetValue({ Color = Color3.fromRGB(10, 20, 30), Transparency = 0.7 })
Right:AddLabel({ Text = "标签" })
Right:AddDivider()
Right:AddParagraph({ Title = "说明", Content = "这是一段多行说明文本" })

-- Table 列表
local Tbl = Right:AddTable({
	Name = "玩家列表",
	Columns = { "玩家", "等级" },
	Rows = { { "0B0", 100 }, { "Test", 3 } },
	Height = 100,
	Callback = function(row)
		evCustom = evCustom + 1
	end,
})
Tbl:AddRow({ "New", 1 })
Tbl:SetSelected(1)
Tbl:SetRows({ { "A", 1 }, { "B", 2 } })

-- 全控件搜索过滤 (Searchable 窗口 + tab:FilterControls)
Tab:FilterControls("开关")
Tab:FilterControls("")

-- Tooltip 直接挂载 (表格式: 标题+内容)
Library:AddTooltip(Tog.Object, { Title = "提示标题", Content = "提示内容" })

local Tab2 = Window:AddTab({ Name = "设置", Icon = "⚙" })
local G2 = Tab2:AddGroupbox({ Name = "通用", Side = 2 })
G2:AddButton({ Name = "切换主题", Callback = function() end })
Window:AddTab({ Name = "第三", Icon = "rbxassetid://123456789" })

-- 可折叠分组 + 勾选/单选组
local Coll = Tab:AddGroupbox({ Name = "折叠组", Side = 1, Collapsible = true, DefaultCollapsed = true })
Coll:AddToggle({ Name = "内部开关", Default = false, Callback = function(v) end })
Coll:SetCollapsed(false)
local CB = Right:AddCheckboxGroup({ Name = "勾选组", Options = { "A1", "B1", "C1" }, Default = { "A1" }, Callback = function(v) end })
CB:AddOption("D1")
local RB = Right:AddRadioGroup({ Name = "单选组", Options = { "X", "Y", "Z" }, Default = "Y", Callback = function(v) end })
RB:AddOption("W")

-- 全局样式: 字体/字号/动画
Library:SetStyle({ TextSize = 14, SubSize = 13, ANIM = 0.05 })
Library:SetStyle({ TextSize = 13, SubSize = 12 })
Library:SetAnimation(false)
Library:SetAnimation(true)

-- 值修改路径 (SetValue + 静默恢复)
Tog:SetValue(true)
Sld:SetValue(25)
Dd:SetValue("C")
Multi:SetValue({ "Q2", "Q4", "Q7" })
Range:SetValue({ 3, 7 })
Step:SetValue(8)
Inp:SetValue("hello")
Kb:SetValue(Enum.KeyCode.RightShift)
Cp:SetValue(Color3.fromRGB(0, 200, 255))
Prog:SetValue(0.8)

-- OnChanged 运行时回调
Dd:OnChanged(function(v) end)
Multi:OnChanged(function(v) end)
Sld:OnChanged(function(v) end)

-- SetDisabled 置灰
Tog:SetDisabled(true)
Sld:SetDisabled(true)
Tog:SetDisabled(false)

-- 自定义控件注册
Library:RegisterCustomControl("NewControl", function(container, opts, keyPrefix)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(50, 20)
	frame.Parent = container
	local myEl = {}
	myEl.Object = frame
	return myEl
end)
G2:AddCustom("NewControl", { Name = "demo" })

-- 主题切换 (遍历 Registry 刷新)
Library:SetTheme(Library.Themes.Light)
Library:SetTheme("Dark")

-- 通知类型 / 水印 / 配置档案 / 重置 / 显隐 / 尺寸
Library:Notify("测试通知", 1)
Library:Notify({ Title = "警告", Content = "类型测试", Type = "warning", Duration = 1 })
Library:Notify({ Title = "点击", Content = "OnClick 测试", OnClick = function()
	evCustom = evCustom + 1
end })
for i = 1, 6 do
	Library:Notify("队列上限测试 #" .. i, 10)
end
Library:SetWatermark("Smoke 已加载")
Library:SaveConfig("档1")
Library:LoadConfig("档1")
Library:ResetConfig("档1")
Window:SetSize(640, 560)
Window:FitToScreen()
Library:Toggle()
Library:Toggle()

-- 配置版本迁移 (v0.8): 注册链 + 验证按序执行与失败保护
-- 模拟"库升级到 ConfigVersion=2": 旧档(1 / 无字段)应自动迁移到 2
local migLog = {}
Library.ConfigVersion = "2"
Library:RegisterConfigMigration("1", "2", function(cfg)
	cfg.OldKey = nil
	cfg.NewKey = "migrated-2"
	table.insert(migLog, "1->2")
	return cfg
end)
if Library.RegisterConfigMigration("2", "1", function() end) ~= false then
	error("MIGRATION_GUARD_FAILED: 降级版本不应被注册")
end
local migCfg, migOk = Library:_ApplyConfigMigrations({ _ConfigVersion = "1", OldKey = "x" })
if not migOk then
	error("MIGRATION_FAILED: 迁移链执行失败")
end
if migCfg._ConfigVersion ~= "2" then
	error("MIGRATION_VERSION_FAILED: " .. tostring(migCfg._ConfigVersion))
end
if migCfg.OldKey ~= nil or migCfg.NewKey ~= "migrated-2" then
	error("MIGRATION_DATA_FAILED: 迁移函数未生效")
end
-- 无版本旧档视为 "1", 应同样被执行
local oldCfg, oldOk = Library:_ApplyConfigMigrations({ OldKey = "y" })
if not oldOk or oldCfg._ConfigVersion ~= "2" or oldCfg.NewKey ~= "migrated-2" then
	error("MIGRATION_LEGACY_FAILED: 无版本旧档未迁移")
end
-- 已经是新版本的档: 不再执行迁移
local nowCfg, nowOk = Library:_ApplyConfigMigrations({ _ConfigVersion = "2", Lost = true })
if not nowOk or nowCfg._ConfigVersion ~= "2" or #migLog ~= 2 then
	error("MIGRATION_IDEMPOTENT_FAILED: 新档不应重复迁移 (log=" .. #migLog .. ")")
end
-- 迁移抛错: 返回失败但不抛异常 (回退旧档)
Library.ConfigVersion = "3"
Library:RegisterConfigMigration("2", "3", function()
	error("boom")
end)
local badCfg, badOk = Library:_ApplyConfigMigrations({ _ConfigVersion = "2" })
if badOk then
	error("MIGRATION_ERROR_FAILED: 抛错迁移应返回 false")
end
if badCfg._ConfigVersion ~= "2" then
	error("MIGRATION_STOP_FAILED: 失败后应保留最后完成版本")
end

-- 事件总线断言
if evWindow < 1 or evTheme < 1 or evCustom < 1 then
	error("EVENT_BUS_FAILED win=" .. evWindow .. " theme=" .. evTheme .. " custom=" .. evCustom)
end

-- 卸载与销毁
Window:Destroy()
Library:Unload()

print("SMOKE_DONE")
