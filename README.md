# MrrorCityLib 💠

**Roblox 脚本 UI 库 · 深色玻璃感 · 简洁圆角** · v0.8.0

单文件分发、零外部资源（取色器用纯 UIGradient 实现，不需要图片资产）、Studio 与执行器均可运行。
设计上吸收了该领域几个代表库的优点：**Linoria**（双列布局 / 主题系统 / 配置持久化 / 通知 / 水印）、**Kavo**（简洁圆角、API 直观）、**Orion**（轻量、好上手）。

## 特性一览

| 模块 | 说明 |
| --- | --- |
| 🪟 窗口 | 可拖拽（自动夹紧边界）、**右下角缩放**、记忆位置与尺寸、右上关闭（仅隐藏）、全局显隐热键、**状态栏/FPS**、**状态点**、**多窗口(ChildKey)**、**自定义 ScreenGui 名**、**玻璃渐变** |
| 🗂 标签页 | 顶部胶囊 Tab、**图标支持（字形/图片）**、**超出横向滚动**、**徽标(SetBadge)**、自动宽度 |
| 📐 双列布局 | `AddLeftGroupbox` / `AddRightGroupbox`，每页独立滚动与滚动位置记忆 |
| 🎛 控件 | Button / Toggle / Slider / **RangeSlider** / Dropdown(单选) / **Dropdown Multi 多选(搜索+全选清空)** / **OptGroup 分组下拉** / Input(**多行/密码**) / Keybind / ColorPicker(**透明度+预设色板**) / **Stepper** / **ProgressBar** / **Paragraph** / **CheckboxGroup** / **RadioGroup** / **Table** / Label / Divider |
| 🔗 通用接口 | 全控件 `:SetValue silent / GetValue / SetVisible / SetDisabled(置灰) / OnChanged(运行时回调) / Destroy / UpdateTheme` |
| 🧩 扩展性 | `Library:RegisterCustomControl` + `group:AddCustom` 第三方扩展入口；`Library:on/once/fire` 事件总线；**插件系统**(`RegisterPlugin`) |
| 🪧 信息提示 | **Tooltip**（`AddXxx({Tooltip="..."})` 或 `Library:AddTooltip`）、**Table 列表/表格**、**全控件搜索过滤**（`Searchable` 窗口）、**Toast 居中大字**、**调试日志面板**(`DebugLog/ShowDebugLog`) |
| 🎨 主题 | 深色/浅色玻璃 + 自定义主题（缺字段自动回退），`SetTheme` 实时刷新并**持久化**；`SetStyle` 全局字体/字号、`SetAnimation` 动画开关 |
| 📦 布局 | 双列 + **分组可折叠**（`AddGroupbox({Collapsible=true})`） |
| 💾 配置 | **多档案** `SaveConfig("档1")`、`ResetConfig()` 恢复默认、writefile / HTTP 双路径、防抖自动保存、**配置版本迁移**（`RegisterConfigMigration`，旧档自动升级） |
| 🔔 通知 | 右上堆叠、**类型化（success/error/warning/info 配色）**、标题/内容/时长、点击关闭 |
| ♻️ 生命周期 | `Unload()` 全断开全销毁、`OnUnload` 钩子、**防重复注入**（重载自动回收旧实例与旧监听） |

> 完整规格与状态表见 [FEATURE_SPEC.md](FEATURE_SPEC.md)；API 参考见 [Docs.md](Docs.md)。
## 快速开始

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/chaojigeshou/MrrorCityLib/main/source.lua", true))()

local Window = Library:CreateWindow({
    Title = "MrrorCityLib",
    Subtitle = "v" .. Library.Version,
    Size = UDim2.fromOffset(600, 540),
})

local Tab = Window:AddTab({ Name = "主页面", Icon = "⚙" })
local Group = Tab:AddLeftGroupbox("战斗")

Group:AddButton({ Name = "执行", Callback = function()
    Library:Notify({ Title = "完成", Content = "执行成功", Type = "success", Duration = 3 })
end })

local Toggle = Group:AddToggle({ Name = "自动攻击", Default = false, Callback = function(v)
    print("自动攻击:", v)
end })

local Multi = Group:AddDropdown({ Name = "品质多选", Multi = true,
    Options = { "史诗", "传说", "神话" }, Default = { "史诗" },
    Callback = function(items) print(#items) end })
```

完整示例见 [`Example.lua`](Example.lua)。

## 项目结构

```
MrrorCityLib/
├── source.lua              ← 库本体（单文件 4200+ 行，内部按模块分区）
├── Example.lua             ← 全控件使用示例（可直接粘贴运行）
├── README.md / Docs.md / SPEC.md
├── typings/MrrorCityLib.emmy.lua   ← EmmyLua 类型注解（VSCode 补全/检查）
├── tests/                  ← stub 环境冒烟测试（stub + exercise + build.js）
├── tools/check.ps1         ← 本地一键校验（下载官方 Luau CLI + 编译 + 冒烟）
└── .github/workflows/ci.yml ← push/PR 自动 CI
```

## 设计说明（写给二次开发）

- **颜色零硬编码**：所有颜色来自 `Library.Theme`，主题切换遍历 `Library.Registry` 调用 `UpdateTheme`。
  新增主题只需 COPY 一份改色（缺字段自动回退），不用碰控件代码。
- **统一元素接口**：`newElement()` 注册的元素自带 `SetValue/GetValue/SetVisible/SetDisabled/OnChanged/Emit/Destroy/UpdateTheme`，
  加新控件时承袭这套接口，配置系统 / 主题系统 / 重置系统自动兼容。
- **配置键**：默认 `"标签页/分组/控件名"` 防重名；`ConfigKey` 可覆盖；值必须是可 JSON 序列化类型。
- **兼容性**：只用原生 API + `task.*`；`writefile`/`readfile`/`isfile` 检测后才使用（Studio 自动降级内存配置）；
  `_G` 仅作防重复注入桥接（纯 Lua）。未使用执行器私有 API。

## 依赖

无。仅需 Roblox 原生 API 与 Luau 运行环境。

## 参考

- [GhostDuckyy/UI-Libraries](https://github.com/GhostDuckyy/UI-Libraries)（收录 60+ 个 UI 库，功能对比参考池）
- [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib)（本项目主要参考对象）
- 本库为学习/自用项目，请勿直接打包售卖他人代码。
