# MrrorCityLib 全功能规格（面向所有 Roblox 脚本的通用 UI 库）

> 版本基准: **v0.8.0** · 状态标注: ✅ 已实现（以源码为唯一事实）/ 🔶 部分 / ❌ 缺失
> 目标定位: 任何 Roblox 游戏 + 任意执行器环境都能挂载的通用 UI 库。不绑定任何具体游戏/脚本。
> 优先级: P0 = 基础必备（没有就不是库） P1 = 进阶（主流库标配） P2 = 扩展（加分项）
> 本表为权威状态: 旧的逐章状态表与「缺口清单」如有冲突，以本表为准（冲突即旧表未同步，一律视为旧表错误）。

---

## 一、窗口 / 框架层

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 创建窗口（标题/副标题/尺寸/默认位置） | ✅ | P0 | `CreateWindow({Title, Subtitle, Size, Parent})` |
| 窗口拖拽 | ✅ | P0 | 标题栏拖拽 |
| 拖拽自动夹紧屏幕边界 | ✅ | P0 | 防止拖出屏幕外 |
| 记忆窗口位置/尺寸/透明度（重进恢复） | ✅ | P0 | `_WindowPosition/_WindowSize/_WindowTransparency` 存配置 |
| 关闭按钮 = 仅隐藏（非销毁） | ✅ | P0 | 右上 X → `Library:Toggle()` |
| 全局显隐热键（默认 RightShift） | ✅ | P0 | `Config._ToggleKey`；`Window:SetToggleKey/GetToggleKey` |
| 窗口缩放（右下角手柄拖拽改尺寸） | ✅ | P1 | resizeHandle + `SetSize` + `FitToScreen`；锁定态禁用 |
| 多点/多窗口管理（同时开多个 window） | ✅ | P1 | `CreateWindow({ChildKey})` 子窗口 + `Library._Windows` 集合（Lite10） |
| 窗口置顶标识 / 标题栏状态点 | ✅ | P1 | `Window:SetStatusDot(color, tooltip)`（Lite10） |
| UI 缩放适配不同分辨率 | ✅ | P1 | `Settings.MaxScreenRatio` + `FitToScreen(ratio)`；窗口初始尺寸夹紧视口 |
| FPS 计数 / 状态栏显示 | ✅ | P1 | `CreateWindow({StatusBar, StatusText, ShowFPS})` + `SetStatus`（Lite10） |
| 窗口透明度 / 背景模糊 | 🔶 | P2 | 有透明度 `SetTransparency`；无 Acrylic 多层模糊（纯 Roblox 实现成本高收益低） |

## 二、标签页（Tab）系统

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 添加 Tab（`AddTab`） | ✅ | P0 | `Window:AddTab({Name, Icon})` |
| 顶部胶囊 Tab、自动宽度、可切换 | ✅ | P0 | |
| Tab 图标（字形前缀 / rbxassetid 图片） | ✅ | P1 | `Icon="⚙"` 或 `Icon="rbxassetid://..."` |
| Tab 数量超限滚动 | ✅ | P1 | tabBar ScrollingFrame 横向滚动 |
| Tab 徽标（未读/数量） | ✅ | P2 | `tab:SetBadge(text)`（Lite10） |
| Tab 动态增删 / 隐藏 | ❌ | P2 | 未实现 |

## 三、布局系统

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 左/右双列 Groupbox | ✅ | P0 | `AddLeftGroupbox/AddRightGroupbox/AddGroupbox({Side})` |
| 内容超高自动滚动 | ✅ | P0 | 双列各自 ScrollingFrame + 滚动位置独立记忆 |
| 分组可折叠（箭头收起） | ✅ | P1 | `AddGroupbox({Collapsible, DefaultCollapsed})` + `SetCollapsed/IsCollapsed` |
| 分隔线 / 小字标签 / 段落 | ✅ | P0 | `AddDivider / AddLabel / AddParagraph({Title, Content})` |
| 搜索框（控件名过滤） | ✅ | P1 | `CreateWindow({Searchable})` + `Tab:FilterControls(keyword)` |
| 自适应列宽 / 网格布局 | ❌ | P2 | 未实现（无动态网格；Table 控件本身支持列宽） |
| 滚动位置记忆 | ✅ | P2 | Tab 切换回来保持（每 Tab 独立 ScrollingFrame） |

## 四、控件全目录

### 4.1 基础控件（全部 ✅）
Button / Toggle / Slider / Dropdown（单选）/ Input / Keybind / ColorPicker / Label / Divider

### 4.2 扩展控件（全部 ✅）
Dropdown Multi 多选（搜索 + 全选/清空）、OptGroup 分组下拉（`Groups` + `AddGroup`）、
RangeSlider 双值、Input 多行/密码（`Multiline/Password`）、ColorPicker Alpha（`Transparency`）+ 预设色板（`Presets`）、
ProgressBar、Stepper、CheckboxGroup、RadioGroup、Table 列表（Columns/Rows/AddRow/SetSelected）、
Paragraph、Accordion（以「可折叠分组 Collapsible」近似实现）、Tooltip（`AddTooltip` + `Tooltip` 选项）、
`RegisterCustomControl` 自定义控件注册 + `group:AddCustom`

### 4.3 控件通用接口

| 能力 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| `SetValue(v, silent?)` / `GetValue()` | ✅ | P0 | silent=不触发回调不自动保存 |
| `SetVisible(bool)` / `Destroy()` / `UpdateTheme()` | ✅ | P0 | |
| `OnChanged(cb)`（运行时动态注册回调） | ✅ | P1 | `el:OnChanged(cb)` / `el:Emit(v)` |
| `SetDisabled(bool)`（置灰+输入拦截） | ✅ | P1 | |
| `SetLabel(text)` / `SetSuffix(s)` | ✅ | P2 | 动态改名/动态后缀（Input 有 `SetText` 别名） |

## 五、主题 / 样式系统

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 主题表（深色/浅色内置） | ✅ | P0 | `Library.Themes.Dark/Light` |
| `SetTheme(name/table)` 实时刷新所有控件 | ✅ | P0 | 遍历 Registry |
| 颜色零硬编码（全走 Theme） | ✅ | P0 | |
| 自定义主题（用户 COPY 表改色）+ 字段缺失回退 | ✅ | P0 | |
| 主题持久化（存配置 + 自动应用） | ✅ | P1 | `Config._Theme` + `SetTheme` 自动写入 |
| 动态主题（跟随时间/节日） | ✅ | P2 | `SetDynamicTheme(fn)` 每分钟刷新（Lite10） |
| 字体/字号系统（全局可调） | ✅ | P1 | `SetStyle({Font, TextSize, ...})` 即时刷新 |
| 动画曲线开关 / 动画时长全局设置 | ✅ | P2 | `SetAnimation(bool)` + `SetStyle({ANIM})` |
| 用户自定义主题编辑器（内置调色器） | ❌ | P2 | 未实现（P2 加分项，非公共库必备） |

## 六、配置持久化

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 控件值自动入 `Library.Config` | ✅ | P0 | |
| 配置键默认 `Tab/Group/Name` 防重名 | ✅ | P0 | 可用 `ConfigKey` 覆盖 |
| `SaveConfig` / `LoadConfig` | ✅ | P0 | writefile（执行器）/ HTTP（Studio）双路径 |
| JSON 序列化限定（Keybind 存 Name、Color 存 hex） | ✅ | P0 | |
| `OnConfigLoaded` 回调 | ✅ | P0 | |
| 自动保存（控件变更防抖写盘） | ✅ | P0 | `_AutoSave` |
| 配置读取时「值变化才回调」 | ✅ | P0 | |
| 多个配置档案（档 1/档 2/档 3） | ✅ | P1 | `SaveConfig(name)/LoadConfig(name)` |
| 配置导入/导出（明文 JSON 分享） | ✅ | P1 | `ExportConfig()/ImportConfig(jsonText)`（Lite10，含 UI 输入框） |
| 重置为默认（清除配置） | ✅ | P1 | `Library:ResetConfig()` + UI 按钮 |
| 配置读取错误容错（坏 JSON 自动跳过） | ✅ | P0 | pcall |
| 配置保存位置可配置 | 🔶 | P2 | 固定 `MrrorCityLib/config_<档案>.json`；无改路径开关 |
| **配置版本迁移（新增字段兼容旧档）** | ✅ | P1 | **v0.8**: `_ConfigVersion` + `RegisterConfigMigration(from,to,fn)` 迁移链，LoadConfig/ImportConfig 自动按序执行；失败保留旧档不半迁移 |

## 七、通知 / 反馈系统

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 右上堆叠通知 | ✅ | P0 | `Notify(text, seconds)` |
| 通知带标题/内容/时长 | ✅ | P0 | `Notify({Title, Content, Duration})` |
| 点击关闭 | ✅ | P0 | |
| 淡入淡出动画 | ✅ | P0 | |
| 通知类型（成功/错误/警告/信息，颜色区分） | ✅ | P1 | `Notify({Type="error"...})` |
| 通知队列（多通知不重叠，超上限回收最旧） | ✅ | P1 | `Settings.MaxNotifications=5` |
| 通知点击回调（跳转/执行） | ✅ | P2 | `Notify({OnClick=...})` |
| Toast / 居中大字提示 | ✅ | P1 | `Toast(text)` / `Toast({Content, Subtitle, Type, OnClick})`（Lite10） |
| 水印 + 显隐/内容自适应 | ✅ | P0 | `SetWatermark/SetWatermarkVisibility` |

## 八、事件 / 生命周期

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| `OnUnload` 钩子 / `Unload()` 全断开+销毁 | ✅ | P0 | |
| `Register/Unregister` 元素注册表 | ✅ | P0 | |
| `AddGateListener`（全局输入拦截） | ✅ | P0 | |
| 防重复注入（已有实例则回收旧 UI） | ✅ | P1 | `_G.__MrrorCityLib` 桥接，重载完整回收 |
| 运行时事件总线 | ✅ | P1 | `on/once/off/fire`（Lite10 已并入） |
| 控件 → 库事件（调起断开重连） | ❌ | P2 | 未实现（P2 加分项） |
| 错误捕获全局（pcall 包裹控件回调 + 日志） | ✅ | P1 | `LogError(err, step)` / `pcallSafe(fn, step)`（Lite10） |
| 调试日志面板（开发者开关） | ✅ | P2 | `DebugLog/ShowDebugLog/CloseDebugLog`（Lite10） |
| 插件系统（tab/控件可挂外部插件） | ✅ | P2 | `RegisterPlugin/InstallPlugins/UninstallPlugins`（Lite10） |

## 九、兼容性 / 执行器适配

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 只用 Roblox 原生 API + `task.*` | ✅ | P0 | 无 getgenv/getfenv/setfenv/newproxy/unpack（Luau 安全） |
| Studio 可预览（内存配置降级） | ✅ | P0 | 无 writefile 自动降级，不报错 |
| 执行器双环境（writefile 检测后有/无） | ✅ | P0 | `hasWriteFile()` |
| HTTP 加载（`game:HttpGet` raw 分发） | ✅ | P0 | README 说明 |
| 免依赖（零 external assets） | ✅ | P0 | 取色器 UIGradient |
| 加载失败友好提示（loadstring 失败） | ✅ | P1 | 库内 pcall + 提示 |
| 多游戏兼容（zindex 不冲突，避让游戏 UI） | ✅ | P2 | ZIndexBehavior Sibling + 自定义 ScreenGui 名（`CreateWindow({Name})`） |
| 执行器差异处理（readfile 相对/绝对路径） | 🔶 | P2 | 未特判；档位路径相对固定 |

## 十、性能 / 渲染质量

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 无每帧轮询（事件驱动 + 需要才更新） | ✅ | P0 | |
| Tween 封装（统一动画 API） | ✅ | P0 | `Library:Tween` |
| 动画可关（低端设备） | ✅ | P1 | `SetAnimation(false)` |
| 平滑滚动（鼠标滚轮补间） | ✅ | P1 | `AddSmoothScroll(frame, speed)`（Lite10）+ `DisableSmoothScrolls()` |
| 阴影 / 玻璃卡片 / 渐变描边 | 🔶 | P2 | 圆角+描边+UIGradient 玻璃渐变；无多层阴影 |
| 大量控件懒加载（滚到才创建） | ❌ | P2 | 未实现（见 Out of Scope：分页懒加载） |
| UI 内存监控（Unload 后断言零泄漏） | ❌ | P2 | 未实现（见 Out of Scope） |

## 十一、扩展性 / 开发体验

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 自定义控件注册（`RegisterCustomControl`） | ✅ | P1 | 第三方开发者加控件 |
| 元素接口统一（SetValue/GetValue/...） | ✅ | P0 | |
| 文档（Docs.md/README/Example.lua/SPEC.md） | ✅ | P0 | |
| **类型提示 / EmmyLua 注解** | ✅ | P2 | `typings/MrrorCityLib.emmy.lua`（v0.8 全量：Lite10 + 配置迁移均已收录） |
| 单元测试 / CI | ✅ | P2 | `tests/`（stub + exercise + build.js）+ `tools/check.ps1` + `.github/workflows/ci.yml` |
| API 版本管理（`Library.Version`） | ✅ | P0 | |
| 变更日志 | ❌ | P2 | 未实现（单文件库，README 特性表兼作变更记录） |

## 十二、安全 / 反作弊敏感性（对 executor 用户）

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 低指纹（不读反作弊敏感 API） | ✅ | P0 | 无异常调用 |
| 可整体卸载/清痕（Unload 彻底） | ✅ | P0 | |
| 无明文敏感信息写配置 | ✅ | P0 | 配置只有 UI 值 |
| 可自定义窗口名（多实例/低暴露） | ✅ | P2 | `CreateWindow({Name="..."})`（Lite10） |
| UI 隐藏快捷（防止被看到） | ✅ | P0 | 全局热键 |

---

## 已实现全量清单（v0.8.0 汇总）

### 旧 SPEC 清单项 → 现状（均已 ✅）
1. Dropdown Multi ✅ `MultiSelect` + 全选/清空 + 搜索 + 分组(OptGroup)
2. OnChanged ✅ `el:OnChanged(cb)` / `el:Emit`
3. 防重复注入 ✅ `_G.__MrrorCityLib` 桥接 + 同名 ScreenGui 清理
4. SetDisabled ✅ 置灰遮罩 + 输入拦截
5. Dropdown 搜索 ✅ 选项>6 自动出搜索框
6. AddParagraph ✅
7. Tab 图标/滚动 ✅ Icon（rbxassetid/字形前缀）+ tabBar ScrollingFrame
8. 窗口缩放 ✅ resizeHandle + FitToScreen + SetSize
9. 通知类型/点击回调 ✅ Type 上色 + OnClick；Toast ✅
10. 多配置档案+重置+导入导出 ✅ SaveConfig(name)/LoadConfig(name)/ResetConfig/ExportConfig/ImportConfig
11. 自定义控件注册 ✅ `RegisterCustomControl` / `group:AddCustom`
12. 主题持久化/字体字号/动画开关 ✅ SetTheme 自动写 `_Theme` + SetStyle/SetAnimation · `SetDynamicTheme` ✅
13. 加载失败友好提示 ✅ 库内 pcall + Notify
14. ProgressBar/Stepper/Table/RangeSlider/Tooltip ✅ 全部；Accordion 以「可折叠分组」近似实现
15. 搜索框过滤/UI 缩放适配 ✅ Searchable + MaxScreenRatio + FitToScreen
16. 多窗口 ✅ `CreateWindow({ChildKey})` 子窗口 + `Library._Windows` 集合
17. 事件总线 ✅ on/once/off/fire
18. 插件系统 ✅ RegisterPlugin/InstallPlugins/UninstallPlugins
19. 状态栏/FPS/状态点/徽标 ✅ SetStatus/ShowFPS/SetStatusDot/SetBadge
20. DebugLog/LogError/pcallSafe ✅
21. 玻璃渐变 ✅ 窗口斜向 UIGradient
22. 平滑滚动 ✅ AddSmoothScroll + 内容区自动接入
23. 自定义 ScreenGui 名 ✅ `CreateWindow({Name})`
24. 设置 Tab 充实 ✅ 复制/导入配置JSON/调试日志开关/测试状态点/测试徽标

### v0.8.0 新增（本次）
- ✅ **配置版本迁移** — `Library.ConfigVersion` + `RegisterConfigMigration(from, to, fn)`；
  `LoadConfig`/`ImportConfig` 自动按序执行迁移链；旧档无 `_ConfigVersion` 视为 `"1"`；迁移抛错 → 放弃该档（保留旧文件，不半迁移）；
  `SaveConfig`/`ExportConfig` 携带 `_ConfigVersion`；事件 `config:migrated` / `config:migrationRegistered` / `config:migrationGap`。
- ✅ **类型提示更新到 v0.8** — `typings/MrrorCityLib.emmy.lua` 全量（Lite10 方法/选项/迁移 API 均已声明）。
- ✅ **测试修复/增强** — stub 补齐缺失枚举与 Instance 方法；exercise 新增 6 条迁移断言（版本守卫/按序执行/旧档缺省/幂等/失败保护）。

---

## Out of Scope（明确不做，非公共库职责）

| 项 | 理由 |
|---|---|
| 国际化 / 本地化 | 中文社区 + executor 场景，全文本抽取收益趋近于零，属教科书式过度设计 |
| UI 内存监控断言 | 开发/QA 内部工具（Unload 后遍历 Registry 断言零泄漏），使用者无感知；库已提供 `Unload()` 全清理 + `DebugLog`，泄漏可自查 |
| 分页懒加载（滚到才创建） | 通用脚本 UI 通常几十~几百控件，千级条目是孤立场景；Roblox 单 ScreenGui 本身有容量上限，收益低 |
| 用户自定义主题编辑器（内置调色器） | P2 加分项；`SetTheme` + `SetStyle` 已覆盖 99% 需求，编辑器属于「便利性开发工具」而非库职责 |
| 多语言文档 | README/Docs/SPEC 中文已完整；英文版属仓库运营项，非库功能 |

> 若未来确有必要，前 3 项可以独立 addon（插件形式，`RegisterPlugin`）交付，不进库核心。
