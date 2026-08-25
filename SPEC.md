# MrrorCityLib 全功能规格 · 版本状态表

> ⚠️ **已归档 (v0.6)**：本表已被 [FEATURE_SPEC.md](FEATURE_SPEC.md)（v0.8 权威版）取代，不再同步新功能。
> 保留仅供历史对比。以下状态以 v0.6 为基准。

> 版本: v0.6.0 · 状态标注: ✅ 已实现 / 🔶 部分 / ❌ 缺失
> 本表在原始规格基础上, 按 v0.6 实际实现情况修订

## 一、窗口 / 框架层

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 创建窗口（标题/副标题/尺寸/默认位置） | ✅ | P0 | `CreateWindow({Title, Subtitle, Size, Parent})` |
| 窗口拖拽 | ✅ | P0 | 标题栏拖拽 |
| 拖拽自动夹紧屏幕边界 | ✅ | P0 | |
| 记忆窗口位置（重进恢复） | ✅ | P0 | `_WindowPosition` |
| 记忆窗口尺寸（缩放后恢复） | ✅ | P0 | `_WindowSize` (v0.2) |
| 关闭按钮 = 仅隐藏（非销毁） | ✅ | P0 | 右上 X → `Library:Toggle()` |
| 全局显隐热键（默认 RightShift） | ✅ | P0 | `Config._ToggleKey` |
| 窗口缩放（右下角手柄） | ✅ | P1 | v0.2 新增, 380×300 下限 (v0.2) |
| 窗口透明度 / 背景模糊 | 🔶 | P1 | 有半透明; 无 Acrylic 模糊 |
| 多点/多窗口管理 | ❌ | P2 | 单窗口设计, 防重复注入保证只有一套 |
| 置顶状态点 / FPS 状态栏 | ❌ | P2 | |
| UI 缩放适配分辨率 | ✅ | P2 | v0.6: `Settings.MaxScreenRatio` 初始自适应 + `Window:FitToScreen()`; 整窗 DPI 缩放未做 |

## 二、标签页（Tab）系统

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 添加 Tab | ✅ | P0 | `Window:AddTab({Name})` |
| 顶部胶囊 Tab、自动宽度、可切换 | ✅ | P0 | |
| Tab 图标 | ✅ | P1 | `Icon = "⚙"` 字形前缀 或 `"rbxassetid://..."` 图片 (v0.2) |
| Tab 数量超限横向滚动 | ✅ | P1 | Tab 栏为横滑 ScrollingFrame (v0.2) |
| Tab 动态增删 / 隐藏 | ❌ | P2 | |
| Tab 徽标/状态点 | ❌ | P2 | |

## 三、布局系统

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 左/右双列 Groupbox | ✅ | P0 | |
| 内容超高自动滚动 | ✅ | P0 | 每 Tab 独立 ScrollingFrame |
| 滚动位置记忆 | ✅ | P2 | 每 Tab 独立 CanvasPosition, 切回自动保持 |
| 分组可折叠 | ✅ | P1 | v0.3 实现: `AddGroupbox({Collapsible=true})` + `group:SetCollapsed(bool)` |
| 分隔线 / 小字标签 | ✅ | P0 | |
| 段落（多行富文本） | ✅ | P1 | `AddParagraph({Title, Content})` (v0.2) |
| 搜索框（控件名过滤） | ✅ | P2 | v0.4: `CreateWindow({Searchable=true})` 顶部搜索框 + `tab:FilterControls(关键词)` |
| 运行时事件总线 | ✅ | P1 | v0.4: `Library:on/once/off/fire`, 内置 8 个库级事件 |
| 自适应列宽 / 网格布局 | ❌ | P2 | |

## 四、控件全目录

### 4.1 基础控件 — 全部 ✅ (P0)

Button · Toggle · Slider · Dropdown(单选) · Input · Keybind · ColorPicker(0 外部资源) · Label · Divider

### 4.2 扩展控件

| 控件 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| **Dropdown 多选（Multi）** | ✅ | P1 高 | v0.2 实现, 值 = 字符串表, `GetSelected()` 取副本 |
| Multi「全选/清空」按钮 | ✅ | P1 | v0.2 实现 |
| Dropdown 搜索（自动过滤） | ✅ | P1 | 单选/多选共用, >6 项时出现搜索框, 不区分大小写 |
| Slider 双值范围（RangeSlider） | ✅ | P2 | v0.2 实现, 值 = `{Low, High}`, 点轨道就近吸附 |
| Stepper（步进器 +/−） | ✅ | P2 | v0.2 实现 |
| ProgressBar（进度条） | ✅ | P2 | v0.2 实现, `:SetValue(0~1)` |
| Dropdown 分组（OptGroup） | ✅ | P2 | v0.5: `AddDropdown({Groups={...}})` + `AddGroup(title, opts)`; 组头随搜索显隐 |
| Input 多行 / 密码输入 | ✅ | P2 | v0.5: `Multiline=true` / `Password=true`(● 遮罩, 值仍真实存储) |
| ColorPicker 透明度 / 预设色板 | ✅ | P2 | v0.5: `Transparency=true`(回调双参) / `Presets={Color3...}` 点击取色 |
| Checkbox 组 / Radio 组 | ✅ | P2 | v0.3 实现: `AddCheckboxGroup` / `AddRadioGroup` (支持动态 AddOption) |
| Accordion 内容折叠 | ❌ | P2 | |
| List / 表格（玩家列表、物品列表） | ✅ | P2 | v0.4 实现: `AddTable({Columns, Rows, Height})` + SetRows/AddRow/SetSelected |
| Tooltip（Hover 提示） | ✅ | P2 | v0.4: `AddXxx({Tooltip=})` 或 `Library:AddTooltip(obj, {Title,Content})`, 跟随鼠标 |
| **RegisterCustomControl 自定义控件** | ✅ | P1 | v0.2 实现, `group:AddCustom("X", opts)` |

### 4.3 控件通用接口 — 全部 ✅

`:SetValue(v, silent?)` · `:GetValue()` · `:SetVisible()` · `:Destroy()` · `:UpdateTheme()`（全部 P0）
`:OnChanged(cb)` ✅ P1 (v0.2) · `:SetDisabled(bool)` ✅ P1 (v0.2, 置灰+拦截输入)
`:SetLabel` ❌ P2 · `:SetSuffix` ❌ P2

## 五、主题 / 样式系统

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 主题表（深色/浅色内置） | ✅ | P0 | |
| SetTheme 实时刷新 | ✅ | P0 | 遍历 Registry |
| 颜色零硬编码 | ✅ | P0 | |
| 自定义主题（COPY 表改色） | ✅ | P0 | |
| 字段缺失回退 | ✅ | P0 | v0.2 实现: 缺字段自动用深色主题补全 |
| 主题持久化 | ✅ | P1 | v0.2: SetTheme 自动写入 `Config._Theme` |
| 主题编辑器 / 动态主题 | ❌ | P2 | |
| 字体/字号全局可调 | ✅ | P1 | v0.3: `Library:SetStyle({Font, FontBold, TextSize, SubSize, ...})` 即时刷新全部控件 |
| 动画时长/曲线全局设置 | ✅ | P2 | v0.3: `SetStyle({ANIM})` 全局时长; `Library:SetAnimation(bool)` 一键开关 |
| 黑暗模式适配 | 🔶 | P2 | |

## 六、配置持久化 — 全部 ✅ (P0) + 🔶/✅ (P1)

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 值自动入 Config / 键前缀防重名 / Save/Load / JSON 限定 / OnConfigLoaded / 自动保存 / 坏 JSON 容错 | ✅ | P0 | 原有实现 |
| 多配置档案 `SaveConfig("档1")` / `LoadConfig("档1")` | ✅ | P1 | v0.2, 文件 `config_<档案>.json` |
| 重置为默认 `Library:ResetConfig()` | ✅ | P1 | v0.2, 恢复 DefaultValue + 写盘 + 通知 |
| 配置导入/导出 UI | 🔶 | P1 | 有文件, 无 UI 按钮 |
| 保存位置可配置 | 🔶 | P2 | 文件名带档案名 |
| 配置版本迁移 | ❌ | P2 | |

## 七、通知 / 反馈系统 — 全部 ✅ (P0) + ✅ (P1)

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 右上堆叠 / 标题内容时长 / 点击关闭 / 淡入淡出 | ✅ | P0 | |
| 通知类型（success/error/warning/info 配色） | ✅ | P1 | v0.2 |
| 队列（堆叠 + 上限自动回收最旧） | ✅ | P1 | v0.6: `Settings.MaxNotifications=5` |
| 通知点击回调 | ✅ | P2 | v0.6: `Notify({OnClick=fn})`; Toast 居中大字 ❌ 未做 |
| 水印 / 显隐 | ✅ | P0 | |

## 八、事件 / 生命周期

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| OnUnload / Unload 全断开销毁 / Registry / GateListener | ✅ | P0 | |
| **防重复注入** | ✅ | P1 高 | v0.2: `_G.__MrrorCityLib` 桥接, 重载即回收旧实例(含全局监听) |
| 运行时事件总线 | ✅ | P1 | v0.4: `Library:on/once/off/fire` + 内置事件 |
| 控件→库事件 | ❌ | P2 | |
| 错误捕获（内核 pcall） | 🔶 | P1 | 回调全 pcall, 无全局日志 |
| 调试日志面板 | ❌ | P2 | |

## 九、兼容性 / 执行器适配

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 只用原生 API + task.*（无 getgenv 等） | ✅ | P0 | `_G` 仅作防重复注入桥接(纯 Lua) |
| Studio 可预览 | 🔶 | P1 | 配置降级内存; 无 .rbxm/rojo |
| writefile 检测 / HTTP 加载 / 零资产依赖 | ✅ | P0 | |
| 网络失败降级（加载失败友好提示） | ✅ | P1 | Example 内置 pcall + SetCore 提示范例 |
| 执行器差异（路径/环境） | ❌ | P2 | |
| 多游戏 zindex 兼容 | 🔶 | P2 | |

## 十、性能 / 渲染质量

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 无每帧轮询 / 统一 Tween | ✅ | P0 | |
| 动画可关（低端设备） | ✅ | P2 | v0.3: `Library:SetAnimation(false)` 所有 Tween 立即落位 |
| 千级条目懒加载 | ❌ | P2 | 下拉搜索缓解 |
| 阴影/玻璃多层 | 🔶 | P2 | 圆角+描边 |
| 平滑滚动 / UI 内存监控 | ❌ / 🔶 | P2 / P1 | |

## 十一、扩展性 / 开发体验

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| RegisterCustomControl | ✅ | P1 | v0.2 |
| 插件系统 | ❌ | P2 | |
| 元素接口统一 | ✅ | P0 | |
| 文档（README/Docs/Example） | ✅ | P0 | |
| Luau 类型注解 / CI 测试 | ✅ | P2 | v0.6: EmmyLua 注解文件 `typings/` + `tests/` 冒烟 + `tools/check.ps1` + GitHub Actions CI |
| `Library.Version` / 变更日志 | ✅ / ❌ | P0 / P2 | |

## 十二、安全 / 反作弊敏感性

| 功能 | 状态 | 优先级 | 说明 |
|---|---|---|---|
| 低指纹 / 可整体卸载 | ✅ | P0 | |
| 无明文敏感信息写配置 | ✅ | P0 | |
| UI 隐藏热键 | ✅ | P0 | |
| 自定义窗口名规避检测 | ❌ | P2 | |

---

## 本轮（v0.2）已解决清单

1. ✅ **Dropdown Multi 多选**（含全选/清空/搜索）— 品质/物品多选场景
2. ✅ **`:OnChanged` 运行时回调** — 动态刷新控件链
3. ✅ **防重复注入** — `_G` 桥接+同名回收, 重载只保留一套 UI 和一套监听
4. ✅ **`:SetDisabled`** — 置灰遮罩 + 全部输入路径拦截
5. ✅ Dropdown 搜索 · 6. ✅ AddParagraph · 7. ✅ Tab 图标 + 横滑
8. ✅ 窗口缩放 + 尺寸记忆 · 9. ✅ 通知类型 · 10. ✅ 多配置档案 + ResetConfig
11. ✅ RegisterCustomControl · 12. ✅ 主题持久化 · 13. ✅ 加载失败友好提示(范例)

## 下一批（P1 剩余 / P2 高价值）

- **P1**: 字体/字号系统、事件总线、分组可折叠、通知队列上限、评分: 主题编辑器
- **P2 优先**: Tooltip、List/Table、Checkbox 组/Radio 组、动画开关、多窗口、搜索过滤全面板、调试日志、类型注解
