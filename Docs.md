# MrrorCityLib API 参考

> 版本: v0.8.0 · 所有方法均为 Luau 语法, 支持 `:` 与 `.` 调用

## 1. 加载

```lua
local Library = loadstring(game:HttpGet(".../source.lua", true))()
```

返回的 `Library` 表同时是入口与配置容器。重复加载会自动回收旧实例（防重复注入）。

## 2. 库级方法

| 方法 | 说明 |
| --- | --- |
| `Library:CreateWindow(opts)` | 创建窗口。opts: `Title` `Subtitle` `Size`(UDim2) `Parent`(默认 CoreGui, 失败退 PlayerGui) |
| `Library:SetTheme(themeOrName)` | 切换主题 `"Dark"`/`"Light"`/自定义表; 自动写 `Config._Theme` 持久化; 缺字段用深色主题补全 |
| `Library:SetStyle(style)` | 全局字体/字号/动画时长: `{Font, FontBold, TextSize, SubSize, SmallSize, TitleSize, HeaderSize, ANIM}`; 已创建控件即时刷新 |
| `Library:SetAnimation(bool)` | 全局动画开关; false 时所有 Tween 立即落位 |
| `Library:GetTheme()` | 当前主题表 |
| `Library:Toggle()` | 隐藏/显示主窗口 |
| `Library:Notify(text, seconds)` | 通知。也支持 `Notify({Title, Content, Duration, Type, OnClick})`; Type: `"success"`/`"error"`/`"warning"`/`"info"`; OnClick 点击回调(v0.6); 队列上限 `Settings.MaxNotifications=5`, 超出自动回收最旧 |
| `Library:Toast(text, seconds)` | **Lite10** 居中大字提示。`Toast({Content, Subtitle, Type, Duration, OnClick})` — Type 上色(auto/failed/warning/success), 点击关闭 |
| `Library:DebugLog(msg, level)` | **Lite10** 记入调试日志(level: info/warn/error), 存最近 200 条; `Library:ShowDebugLog()` 弹出子窗口看最近 60 条; `CloseDebugLog()` 关闭 |
| `Library:LogError(err, step)` / `Library:pcallSafe(fn, step)` | **Lite10** 全局错误记录(DebugLog+fire("error")) / 安全 pcall(自动记录错误) |
| `Library:RegisterPlugin(plugin)` | **Lite10** 插件系统: `{Name, Version, OnInstall(window), OnUninstall}`; 主窗口创建自动安装, 库卸载自动 OnUninstall |
| `Library:InstallPlugins(win?)` / `Library:UninstallPlugins()` | **Lite10** 手动安装/卸载插件 |
| `Library:SetDynamicTheme(fn)` | **Lite10** 动态主题: `fn()` 返回主题名/表, 立即应用+每分钟刷新; `SetDynamicTheme(nil)` 关闭 |
| `Library:AddSmoothScroll(scrollingFrame, speed?)` | **Lite10** 鼠标滚轮平滑滚动(默认 speed=40); 内容区自动接入; `DisableSmoothScrolls()` 关闭 |
| `Library:ExportConfig()` / `Library:ImportConfig(jsonText)` | **Lite10** 配置导出(JSON 文本) / 导入(JSON 解析+恢复+保存) |
| `Library:AddHoverFx(frame, ...)` | **Lite10** 通用 hover 背景过渡工具 |
| `Library:SetWatermark(text)` / `:SetWatermarkVisibility(bool)` | 水印 |
| `Library:SaveConfig(name?)` / `:LoadConfig(name?)` | 多档案配置存储: `MrrorCityLib/config_<档案>.json`; 缺省档案 = `default` |
| `Library:ResetConfig(name?)` | 全部控件恢复默认值 → 写盘 → 通知「配置已重置」 |
| `Library:RegisterConfigMigration(from, to, fn)` | **v0.8** 配置版本迁移: 旧档加载自动按序执行, `fn(cfg)` 原地改或返回新表 |
| `Library:OnConfigLoaded(cb)` | 配置加载完成回调 |
| `Library:OnUnload(cb)` | 卸载回调 |
| `Library:Unload()` | 断开全部监听 + 销毁所有 UI |
| `Library:RegisterCustomControl(name, build)` | 注册自定义控件; `build(content, options, keyPrefix)` 返回 element |
| `Library:AddTooltip(guiObject, text)` | 挂 Hover 提示: 字符串 或 `{Title, Content}`; 跟随鼠标/夹紧屏幕/点击关闭 |
| `Library:on(event, cb)` / `once` / `off` / `fire(event, ...)` | 事件总线: `library:unload` `window:created` `theme:changed` `notify` `config:loaded` `config:saved` `config:reset` `element:changed` |
| `Library:IsMouseOver(guiObject)` / `Library:Tween(...)` / `Library:ConvertColor(v)` | 工具 |

### 主题表字段

`Window WindowTransparency Border BorderTransparency Corner ElementCorner TitleText SubtitleText Divider DividerTransparency
TabSelected TabSelectedText TabUnselected TabUnselectedTransparency TabUnselectedText
Group GroupTransparency GroupHeader Control ControlTransparency ControlHover ControlHoverTransparency
ControlActive ControlActiveTransparency Label LabelSub Accent AccentDark OnAccent Danger Success Warning
Disabled DisabledTransparency Notify NotifyTransparency NotifyText Dropdown DropdownTransparency`

字段可删减（自动回退深色主题值）。

## 3. Window 对象

| 方法 | 说明 |
| --- | --- |
| `Window:AddTab({ Name, Icon })` | 添加标签页。`Icon`: 字形前缀 `"⚙"` 或图片 `"rbxassetid://..."` |
| `Window:SetTitle` / `SetSubtitle` | 改标题 |
| `Window:SetSize(w, h)` | 改尺寸(与缩放手柄联动) |
| `Window:FitToScreen(ratio?)` | 分辨率适配: 尺寸夹紧到视口 `ratio`(默认 `Settings.MaxScreenRatio=0.9`) |
| `Window:SetVisible(bool)` / `Toggle()` | 显隐 |
| `Window:Destroy()` | 仅销毁窗口 |
| `Window:SetStatus(text)` | **Lite10** 底部状态栏文本(`CreateWindow({StatusBar=true, StatusText, ShowFPS})`) |
| `Window:SetStatusDot(color, tooltipText?)` | **Lite10** 标题栏状态点: `nil` 隐藏, Color3 显示+变色 |
| `Window:SetToggleKey(key)` / `GetToggleKey()` | **Lite7** 程序化设置/读取隐藏键(Enum 或键名字符串) |
| `Window:ResetWindowState()` | **Lite7** 恢复默认尺寸/位置/透明度 |

窗口右下角手柄可缩放; 位置与尺寸自动记忆。

## 4. Tab 对象

`Tab:AddGroupbox({ Name, Side = 1|2 })` · `Tab:AddLeftGroupbox(name)` · `Tab:AddRightGroupbox(name)`。
每个 Tab 的滚动位置独立保持。

| 方法 | 说明 |
| --- | --- |
| `Tab:SetBadge(text)` | **Lite10** Tab 按钮右侧徽标(未读/数量); `nil`/`""` 隐藏 |
| `Tab:FilterControls(query)` | 控件名过滤(需 `CreateWindow({Searchable=true})`) |

### 多窗口 (Lite10)

```lua
-- 子窗口 (独立 ScreenGui, 不占主窗口 _WindowRef; 同名子窗口自动清理)
local child = Library:CreateWindow({ Title = "掉落预览", Size = UDim2.fromOffset(340, 420), ChildKey = "dropFloat" })
child:Destroy()

-- 自定义 ScreenGui 名 (规避检测/多实例)
Library:CreateWindow({ Title = "X", Name = "MyGui_Custom" })

-- 所有窗口进 Library._Windows; SetTheme/Unload 自动遍历全部
```

## 5. Groupbox 对象

| 方法 | 说明 |
| --- | --- |
| `AddButton` `AddToggle` `AddSlider` `AddDropdown` `AddInput` `AddKeybind` `AddColorPicker` | 基础控件 |
| `AddMultiSelect([])` = `AddDropdown({ Multi = true, ... })` | 多选 |
| `AddRangeSlider` `AddStepper` `AddProgressBar` | v0.2 扩展 |
| `AddCheckboxGroup` `AddRadioGroup` `AddTable` | 表格型多选/单选/列表 |
| `AddLabel` `AddDivider` `AddParagraph` | 展示类 |
| `AddCustom(controlName, opts)` | 自定义控件分发 |
| `group:SetCollapsed(bool)` / `group:IsCollapsed()` | 折叠控制（需 `AddGroupbox({Collapsible=true})`） |

所有 `AddXxx({..., Tooltip = "..."})` 自动挂 Hover 提示。

## 6. 控件

### 通用接口（所有控件）

`:SetValue(v, silent?)` — silent=true 不触发回调、不自动保存（配置恢复内部使用）
`:GetValue()` · `:SetVisible(bool)` · `:SetDisabled(bool)`（置灰+拦截输入）· `:OnChanged(cb)`（运行时追加回调）· `:Destroy()` · `:UpdateTheme()`

### Button
```lua
Group:AddButton({ Name = "执行", Callback = function() end })
```

### Toggle
```lua
Group:AddToggle({ Name = "自动攻击", Default = false, Callback = function(Value) end })
```

### Slider
```lua
Group:AddSlider({ Name = "范围", Min = 10, Max = 100, Default = 50, Suffix = " 格", Decimals = 1, Callback = function(Value) end })
```

### Dropdown（单选 / 多选 / 分组 OptGroup / 搜索）
```lua
-- 单选
local dd = Group:AddDropdown({ Name = "模式", Options = { "正常", "狂暴" }, Default = "正常", Callback = function(Value) end })
dd:AddOption("闪避"); dd:ClearOptions()

-- 分组下拉 (OptGroup): Groups 渲染为不可点的组头, 选中值是选项字符串
local gdd = Group:AddDropdown({
	Name = "物品分类",
	Options = { "全部" },
	Groups = {
		{ Title = "稀有度", Options = { "史诗", "传说" } },
		{ Title = "部位",   Options = { "武器", "护甲" } },
	},
	Default = "史诗",
	Callback = function(Value) end,
})
gdd:AddGroup("新增组", { "A", "B" })   -- 运行时追加分组
gdd:GetOptions()                        -- 全部可选值

-- 多选 (值 = 字符串表; >6 个选项自动出现搜索框)
local multi = Group:AddDropdown({
	Name = "品质", Multi = true,
	Options = { "史诗", "传说", "神话" },
	Default = { "史诗" },
	Callback = function(Items) print(#Items, "项") end,
})
multi:GetSelected()         -- 取选择副本
multi:SetValue({ "传说" })  -- 整组替换
```
搜索框对分组同样生效（组内无匹配时组头一并隐藏）。

### Input（多行 / 密码）
```lua
Group:AddInput({ Name = "文本", PlaceholderText = "输入后回车", Default = "", ClearTextOnFocus = false, Callback = function(Value) end })

-- 多行 (v0.5)
Group:AddInput({ Name = "备注", Multiline = true, Height = 80, Callback = function(Value) end })

-- 密码 (v0.5): 真实值存 el.Value / 配置, 显示为 ● 遮罩 (遮罩不抢焦点)
Group:AddInput({ Name = "密钥", Password = true, PasswordChar = "●", Callback = function(Value) end })
```
回车/失焦触发。别名 `:SetText(text)`。

### Keybind
```lua
Group:AddKeybind({ Name = "热键", Default = Enum.KeyCode.V, Callback = function(Key) end })
```
点击后按下按键绑定, Escape 取消。配置存键名字符串。

### ColorPicker（透明度 / 预设色板, v0.5）
```lua
local cc = Group:AddColorPicker({ Name = "颜色", Default = Color3.fromRGB(255, 80, 90), Callback = function(Value, Transparency) end })

-- 透明度通道: 面板多一条透明度滑条, hex 行显示百分比
local cc2 = Group:AddColorPicker({
	Name = "颜色+透明", Transparency = true,
	DefaultTransparency = 0.35,               -- 0~1
	Presets = { Color3.fromRGB(255,255,255), Color3.fromRGB(0,200,255) },
	Callback = function(Color, Transparency) end,
})
cc2:SetValue({ Color = Color3.fromRGB(10,20,30), Transparency = 0.7 })
cc2:GetValue()          -- Color3
cc2.Alpha / :GetValue() -- 透明度取 cc2.Alpha
```
- 非透明度模式：回调第二参数恒为 0，行为与旧版完全兼容
- 透明度模式：配置存 `{ color = hex, transparency = 0~1 }`
- 拖动过程中回调仅在松手时触发一次

### RangeSlider（双值区间）
```lua
Group:AddRangeSlider({ Name = "品格区间", Min = 1, Max = 10, DefaultLow = 2, DefaultHigh = 8, Callback = function(Range) end })
```
值 = `{ Low, High }`；点击轨道就近吸附句柄; 拖动中连续回调。

### Stepper
```lua
Group:AddStepper({ Name = "连击次数", Min = 1, Max = 50, Default = 5, Step = 1, Suffix = "", Callback = function(Value) end })
```

### ProgressBar（不参与配置/重置）
```lua
local bar = Group:AddProgressBar({ Name = "进度", Value = 0.35, Suffix = "%" })
bar:SetValue(0.8)  -- 0~1
```

### CheckboxGroup / RadioGroup（表格型选择, v0.3）
```lua
local CB = Group:AddCheckboxGroup({ Name = "执行项",
	Options = { "钓鱼", "采集" }, Default = { "钓鱼" },
	Callback = function(Items) end })            -- Items = 字符串表
CB:AddOption("锻造"); CB:GetSelected()

local RB = Group:AddRadioGroup({ Name = "工作模式",
	Options = { "安全", "激进" }, Default = "安全",
	Callback = function(Value) end })            -- Value = 字符串
```

### 可折叠分组
```lua
local Coll = Tab:AddGroupbox({ Name = "高级选项", Side = 2, Collapsible = true, DefaultCollapsed = false })
Coll:SetCollapsed(true)   -- 程序化收起
```

### Table（列表/表格, v0.4）
```lua
local tbl = Group:AddTable({
	Name = "玩家列表",
	Columns = { "玩家", "等级", "状态" },
	ColumnWidths = { 0.5, 0.25, 0.25 },   -- 可选, 默认均分
	Rows = { { "0B0", 100, "在线" } },
	Height = 160,                          -- 可视高度, 超出滚动
	Callback = function(row) end,          -- 点击行回调(传行数据)
})
tbl:AddRow({ "Test", 3, "离线" })          -- 追加
tbl:SetRows({ ... })                      -- 全量替换
tbl:SetSelected(2) / tbl:GetSelected()    -- 选中高亮(左 accent 条)
tbl:ClearRows()                           -- 清空(显示"暂无数据")
```
运行时数据, 不参与配置保存/重置。

### 全控件搜索过滤（v0.4）
```lua
local Window = Library:CreateWindow({ Searchable = true, ... })  -- 顶部出现搜索框
Tab:FilterControls("品质")   -- 程序化过滤当前 Tab 控件(匹配控件内任意文字层)
Tab:FilterControls("")       -- 恢复
```
切 Tab 时自动应用当前关键词。

### 事件总线（v0.4）
```lua
local cb = Library:on("theme:changed", function(themeName) end)
Library:once("config:loaded", function() end)
Library:off("theme:changed", cb)
Library:fire("custom:event", 1, 2)
```
内置事件: `library:unload` / `window:created` / `theme:changed` / `notify` / `config:loaded` / `config:saved` / `config:reset` / `element:changed`(每个控件值变化, 高频慎用)。

### 全局样式（字体/字号/动画）
```lua
Library:SetStyle({ Font = Enum.Font.LuaGothic, FontBold = Enum.Font.LuaGothicBold, TextSize = 13, SubSize = 12 })
Library:SetAnimation(false)  -- 低端设备一键去动画
```

### Paragraph / Label / Divider
```lua
Group:AddParagraph({ Title = "说明", Content = "多行文本\n第二行" })
Group:AddLabel({ Text = "小字说明" })
Group:AddDivider()
```

### 自定义控件
```lua
Library:RegisterCustomControl("MarkdownText", function(container, opts)
	local label = Instance.new("TextLabel")
	label.Text = opts.Text or ""
	label.Size = UDim2.new(1, 0, 0, 30)
	label.Parent = container
	return { Object = label }  -- 建议用统一接口: newElement(...), 见源码注释
end)
Group:AddCustom("MarkdownText", { Text = "你好" })
```

## 7. 配置

```lua
Library.Config._ToggleKey = Enum.KeyCode.RightShift -- 全局显隐热键
Library.Config._Theme = "Dark"                       -- 主题 (SetTheme 自动维护)
Library.Config._AutoSave = true                      -- 变更后防抖写盘(0.6s)
Library:SaveConfig("boss_farm")   -- 档案2
Library:LoadConfig("boss_farm")
Library:ResetConfig()             -- 恢复默认值并写盘
Library:OnConfigLoaded(function() end)
```

- 默认配置键 = `标签页/分组/控件名`，`ConfigKey` 可覆盖。
- 必须是 JSON 可序列化值: number/boolean/string/纯表（Keybind 存键名、Color 存 hex、Multi 存表）。
- 无 `writefile`（Studio）时自动降级内存配置；`Config._Endpoint` 可切 HTTP 后端。

### 配置版本迁移 (v0.8)

配置文件携带 `_ConfigVersion` 字段（缺省旧档视为 `"1"`）。库升级改了配置结构时，注册迁移链：

```lua
-- 注册: 从版本 "1" 升到 "2" 的迁移 (版本必须递增, 降级注册返回 false)
Library:RegisterConfigMigration("1", "2", function(cfg)
    cfg.OldKey = nil               -- 原地改
    cfg.NewKey = cfg.OldValue
    return cfg                     -- 或返回新表
end)

Library:LoadConfig()               -- 旧档自动按序迁移到当前 Library.ConfigVersion
```

- 迁移在 `LoadConfig` / `ImportConfig` 时自动执行，按注册顺序（From 升序）逐条应用。
- 迁移函数抛错 → 返回 false，`LoadConfig` 放弃该档（旧文件保留，不会半迁移写回）。
- 迁移成功链完成后 `_ConfigVersion` 写回配置，下次 SaveConfig 落盘。
- 当前格式版本: `Library.ConfigVersion`（默认 `"1"`）。库升级改结构时先 bump 它再注册迁移，不要改旧档语义。

## 8. 常见问题

**Q: 重复执行脚本出现两套 UI/两个热键？**
A: 不会。v0.2 用 `_G.__MrrorCityLib` 桥接，重载即完整回收上一套。

**Q: 多选下拉值变化频繁回调？**
A: 正常设计。`silent=true` 可跳过回调/自动保存；配置恢复时静默，结束后只对"值变化"的控件回调一次。

**Q: 主题字段写少了会崩吗？**
A: 不会。`SetTheme` 自动用深色主题补全缺失字段（写进你的主题表）。

**Q: Studio 里没有 writefile？**
A: 自动降级为内存配置，`SaveConfig` 返回 false 但不报错；可设 `Config._Endpoint` 走 HTTP。

**Q: 想加新控件？**
A: 用 `RegisterCustomControl`（ext) 或参照 `addToggle` 在源码里加工厂：`newElement(...)` 注册 → `el.SetValue(v, silent)`（写 Config + `el:Emit(v)` + `_AutoSave`）→ `el.UpdateTheme`（读 `Library.Theme`，禁止写死颜色）→ 在 Groupbox 挂 `AddXxx`。
