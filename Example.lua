--[[═══════════════════════════════════════════════════════════════════════════
    MrrorCityLib v0.2 使用示例
    把本文件内容粘贴到 执行器 / Studio LocalScript 即可运行
    发布时把 source.lua 传到 GitHub 并用 raw 链接替换下面的 URL
═══════════════════════════════════════════════════════════════════════════]]

-- 0) 加载失败友好提示 (可选, 推荐)
local Library = (function()
	local ok, res = pcall(function()
		return loadstring(game:HttpGet("https://你要发布的位置/MrrorCityLib/source.lua", true))()
	end)
	if not ok then
		warn("MrrorCityLib 加载失败: " .. tostring(res))
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "MrrorCityLib",
			Text = "加载失败, 检查网络或链接",
			Duration = 5,
		})
		return nil
	end
	return res
end)()
if not Library then
	return
end

-- 1) 创建窗口 (自动记忆位置/尺寸, 防重复注入; Searchable = 顶部控件搜索框)
local Window = Library:CreateWindow({
	Title = "MrrorCityLib",
	Subtitle = "v" .. Library.Version,
	Size = UDim2.fromOffset(600, 540),
	Searchable = true,
})

-- 事件总线示例
Library:on("window:created", function(win)
	print("窗口已创建:", win.Gui.Name)
end)
Library:once("config:loaded", function()
	print("配置加载完成")
end)

-- 分辨率适配: 确保窗口不超过当前视口 (初始尺寸也会自动适配)
Window:FitToScreen()

-- 通知点击回调 + 队列上限 (Settings.MaxNotifications = 5)
Library:Notify({ Title = "点我", Content = "这是一个可点击的通知", Duration = 5, OnClick = function()
	print("通知被点击了")
end })

-- 2) 标签页 (Icon 支持字形前缀 "⚙" 或 "rbxassetid://..." 图片)
local Main = Window:AddTab({ Name = "主页面", Icon = "⚙" })
local Settings = Window:AddTab({ Name = "设置", Icon = "⚙" })

-- 3) 双列分组
local Combat = Main:AddLeftGroupbox("战斗")
local Misc = Main:AddRightGroupbox("杂项")

-- 按钮 (Tooltip = 自动挂 Hover 提示)
Combat:AddButton({ Name = "执行", Tooltip = "点击后执行一次脚本主流程", Callback = function()
	Library:Notify("执行完成", 3)
end })

-- 开关
local Toggle = Combat:AddToggle({ Name = "自动攻击", Default = false, Callback = function(Value)
	print("自动攻击:", Value)
end })

-- 滑条
local Slider = Combat:AddSlider({ Name = "攻击范围", Min = 10, Max = 100, Default = 50, Suffix = " 格", Callback = function(Value)
	print("攻击范围:", Value)
end })

-- 单选下拉 (>6 个选项自动出现搜索框)
local Dropdown = Combat:AddDropdown({ Name = "模式", Options = { "正常", "狂暴", "闪避" }, Default = "正常", Callback = function(Value)
	print("模式:", Value)
end })

-- 多选下拉 (全选/清空/搜索, 返回表; 品质/物品多选场景)
local Multi = Combat:AddDropdown({
	Name = "品质多选",
	Multi = true,
	Options = { "普通", "优秀", "稀有", "史诗", "传说", "神话", "神器", "圣物", "混沌", "创世" },
	Default = { "史诗", "传说" },
	Callback = function(Value)
		print("已选品质:", table.concat(Value, ", "))
	end,
})
Multi:OnChanged(function(Value) -- 运行时动态追加回调
	print("品质发生变化:", table.concat(Value, ", "))
end)

-- 区间滑块 / 步进器 / 进度条
local Range = Combat:AddRangeSlider({ Name = "品格区间", Min = 1, Max = 10, DefaultLow = 2, DefaultHigh = 8, Callback = function(Range)
	print("区间:", Range[1], "-", Range[2])
end })
local Stepper = Misc:AddStepper({ Name = "连击次数", Min = 1, Max = 50, Default = 5, Step = 1, Callback = function(Value)
	print("连击:", Value)
end })
local Progress = Misc:AddProgressBar({ Name = "执行进度" })
Progress:SetValue(0.5) -- 0~1, 自动显示百分比

-- 文本输入
Misc:AddInput({ Name = "自定义文本", PlaceholderText = "输入后回车", Callback = function(Value)
	print("输入:", Value)
end })

-- 热键绑定 / 取色器
local Keybind = Misc:AddKeybind({ Name = "功能热键", Default = Enum.KeyCode.V, Callback = function(Key)
	print("热键:", Key.Name)
end })
local Color = Misc:AddColorPicker({ Name = "自定义颜色", Default = Color3.fromRGB(255, 80, 90), Callback = function(Value)
	print("颜色:", Value)
end })

-- 段落 / 标签 / 分隔线
Misc:AddParagraph({ Title = "设计参考", Content = "取 Linoria 的双列/主题/配置、Kavo 的圆角简洁、Orion 的轻量易用。\n全部颜色走主题表, 零硬编码。" })
Misc:AddLabel({ Text = "测试 Section" })
Misc:AddDivider()

-- 列表 (玩家/物品列表通用)
local Players = Misc:AddTable({
	Name = "玩家列表",
	Columns = { "玩家", "等级", "状态" },
	ColumnWidths = { 0.5, 0.25, 0.25 },
	Rows = { { "0B0", 100, "在线" }, { "Test", 3, "离线" } },
	Height = 110,
	Callback = function(row)
		Library:Notify("选中: " .. tostring(row and row[1] or "?"), 2)
	end,
})

-- 禁用示例: 打开自动攻击后才解锁品质多选
Toggle:OnChanged(function(Value)
	Multi:SetDisabled(not Value)
	Range:SetDisabled(not Value)
end)

-- 4) 设置页 (可折叠分组演示)
local General = Settings:AddGroupbox({ Name = "通用", Collapsible = true })
General:AddButton({ Name = "切换主题", Callback = function()
	local nextTheme = (Library.Theme.Name == "深色玻璃") and Library.Themes.Light or Library.Themes.Dark
	Library:SetTheme(nextTheme) -- 自动写入 Config._Theme 持久化
end })
General:AddButton({ Name = "重置配置", Callback = function()
	Library:ResetConfig() -- 恢复全部默认值并写盘
end })
General:AddButton({ Name = "卸载库", Callback = function()
	Library:Unload()
end })

-- 勾选组 / 单选组 (表格型多选/单选)
local Auto = Settings:AddRightGroupbox("自动化")
Auto:AddCheckboxGroup({ Name = "执行项", Options = { "钓鱼", "采集", "挖矿", "锻造" }, Default = { "钓鱼", "挖矿" }, Callback = function(Items)
	print("执行项:", table.concat(Items, ", "))
end })
Auto:AddRadioGroup({ Name = "工作模式", Options = { "安全", "激进", "自定义" }, Default = "安全", Callback = function(Value)
	print("模式:", Value)
end })

-- 字号/动画全局设置 (LuaGothic 等中文字体示例)
General:AddButton({ Name = "换中文字体", Callback = function()
	Library:SetStyle({
		Font = Enum.Font.LuaGothic,
		FontBold = Enum.Font.LuaGothicBold,
		TextSize = 13,
		SubSize = 12,
	})
end })
General:AddButton({ Name = "关闭动画", Callback = function()
	Library:SetAnimation(false) -- 所有 Tween 立即落位, 低端设备友好
end })

-- 5) 多配置档案
General:AddDropdown({
	Name = "配置档案",
	Options = { "default", "boss_farm", "afk" },
	Default = "default",
	Callback = function(name)
		Library:SaveConfig(name) -- 写入 MrrorCityLib/config_<name>.json
		Library:LoadConfig(name)
	end,
})

-- 6) 全局热键 / 水印 / 通知 (Type: success|error|warning|info)
Library.Config._ToggleKey = Enum.KeyCode.RightShift
Library:SetWatermark("MrrorCityLib " .. Library.Version .. " 已加载")
Library:Notify({ Title = "提示", Content = "按 RightShift 隐藏/显示窗口", Type = "info", Duration = 5 })

-- 6b) 配置版本迁移 (v0.8): 库升级改了配置结构时注册, 旧档自动升级
--    在第一次 LoadConfig 之前注册; cfg 可原地改或返回新表
-- Library:RegisterConfigMigration("1", "2", function(cfg)
--     cfg.OldKey = nil
--     cfg.NewKey = "new-default"
--     return cfg
-- end)

-- 7) 自定义控件注册 (第三方扩展入口)
Library:RegisterCustomControl("MarkdownText", function(container, opts)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 30)
	label.BackgroundTransparency = 1
	label.Text = opts.Text or ""
	label.TextColor3 = Library.Theme.LabelSub
	label.TextSize = 12
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = container
	return { Object = label }
end)
-- 之后任意分组里: Group:AddCustom("MarkdownText", { Text = "..." })

-- 8) 常用 API 速查
--   Library:SetTheme("Dark"/"Light"/自定义表) · Library:Notify(text,秒) 或 {Title,Content,Type,Duration}
--   Library:SetStyle({Font, FontBold, TextSize, SubSize, ANIM}) · Library:SetAnimation(bool)
--   Library:Toggle() · Library:SaveConfig(档案) / LoadConfig(档案) / ResetConfig()
--   Library:OnConfigLoaded(cb) · Library:OnUnload(cb) · Library:SetWatermark(文本)
--   控件: :SetValue(v, silent?) :GetValue() :SetVisible(bool) :SetDisabled(bool)
--         :OnChanged(cb) :Destroy()(通用)  · 默认配置键 = 标签页/分组/控件名
--   分组: :SetCollapsed(bool) :IsCollapsed()(需 Collapsible=true) · :AddCustom(名称, opts)
--   窗口: :AddTab({Name, Icon}) / :SetTitle / :SetSubtitle / :SetSize(w,h) / :Toggle
