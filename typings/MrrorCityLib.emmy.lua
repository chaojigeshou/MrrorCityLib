---@meta
---===========================================================================
--- MrrorCityLib v0.8.0 · EmmyLua 类型注解
--- 在 VSCode + EmmyLua 插件下使用: 把本项目根目录加入 workspace,
--- 编辑器会自动识别本文件并为 loadstring 返回的 Library 提供补全与检查。
---
--- 由于 Roblox 脚本库是 loadstring 动态分发, 类型提示通过:
---   1. 在本文件声明全部公开 API (---@class Library / Window / Tab / Groupbox)
---   2. 在 Example.lua 顶部加:
---      ---@type Library
---      local Library = loadstring(...)()
---===========================================================================

---@class Library
local Library = {}

---@class ThemeTable
---@field Name string
---@field Window Color3
---@field WindowTransparency number
---@field Border Color3
---@field BorderTransparency number
---@field Corner number
---@field ElementCorner number
---@field TitleText Color3
---@field SubtitleText Color3
---@field Divider Color3
---@field DividerTransparency number
---@field TabSelected Color3
---@field TabSelectedText Color3
---@field TabUnselected Color3
---@field TabUnselectedTransparency number
---@field TabUnselectedText Color3
---@field Group Color3
---@field GroupTransparency number
---@field GroupHeader Color3
---@field Control Color3
---@field ControlTransparency number
---@field ControlHover Color3
---@field ControlHoverTransparency number
---@field ControlActive Color3
---@field ControlActiveTransparency number
---@field Label Color3
---@field LabelSub Color3
---@field Accent Color3
---@field AccentDark Color3
---@field OnAccent Color3
---@field Danger Color3
---@field Success Color3
---@field Warning Color3
---@field Disabled Color3
---@field DisabledTransparency number
---@field Notify Color3
---@field NotifyTransparency number
---@field NotifyText Color3
---@field Dropdown Color3
---@field DropdownTransparency number

---@alias NotifyType "success"|"error"|"warning"|"info"
---@alias ToastType "auto"|"failed"|"warning"|"success"

---@alias Element
---| table -- 具体见控件段落 (SetValue/GetValue/SetVisible/SetDisabled/OnChanged/Destroy)

---@class WindowOptions
---@field Title? string
---@field Subtitle? string
---@field Size? UDim2
---@field Parent? Instance
---@field Searchable? boolean  -- v0.4 顶部全控件搜索框
---@field StatusBar? boolean   -- Lite10 底部状态栏 (默认 true)
---@field StatusText? string   -- Lite10 初始状态栏文本 (默认 "就绪")
---@field ShowFPS? boolean     -- Lite10 状态栏显示帧率
---@field ChildKey? string     -- Lite10 子窗口: 同名自动清理, 只挂子窗口 (不占主 _WindowRef)
---@field Name? string         -- Lite10 自定义 ScreenGui 名 (默认 MrrorCityLib_<ChildKey>)

---@class TabOptions
---@field Name? string
---@field Icon? string -- "⚙" 字形 或 "rbxassetid://..." 图片

---@class GroupboxOptions
---@field Name string
---@field Side? 1|2 -- 1=左列 2=右列
---@field Collapsible? boolean
---@field DefaultCollapsed? boolean

---@class NotifyOptions
---@field Title? string
---@field Content string
---@field Duration? number
---@field Type? NotifyType
---@field OnClick? fun() -- v0.6 点击回调

---@class ToastOptions
---@field Content? string
---@field Subtitle? string
---@field Type? ToastType -- Lite10 上色
---@field Duration? number
---@field OnClick? fun()   -- 点击关闭回调

---@class PluginOptions
---@field Name string
---@field Version? string
---@field OnInstall? fun(window:Window)
---@field OnUninstall? fun()

---@class ConfigMigration
---@field From string
---@field To string
---@field Run fun(cfg:table):table?

---@class ElementOptions
---@field Name string
---@field ConfigKey? string
---@field Callback? fun(...)
---@field Tooltip? string|{Title:string,Content:string}

---@class ToggleOptions : ElementOptions
---@field Default? boolean

---@class SliderOptions : ElementOptions
---@field Min? number
---@field Max? number
---@field Default? number
---@field Suffix? string
---@field Decimals? number

---@class DropdownOptions : ElementOptions
---@field Options? string[]
---@field Groups? {Title:string, Options:string[]}[]
---@field Multi? boolean
---@field Default? string|string[]

---@class InputOptions : ElementOptions
---@field PlaceholderText? string
---@field Default? string
---@field ClearTextOnFocus? boolean
---@field Multiline? boolean -- v0.5
---@field Height? number      -- v0.5 多行高度
---@field Password? boolean   -- v0.5
---@field PasswordChar? string

---@class KeybindOptions : ElementOptions
---@field Default? Enum.KeyCode

---@class ColorPickerOptions : ElementOptions
---@field Default? Color3
---@field Transparency? boolean -- v0.5
---@field DefaultTransparency? number
---@field Presets? Color3[]

---@class RangeSliderOptions : ElementOptions
---@field Min? number
---@field Max? number
---@field DefaultLow? number
---@field DefaultHigh? number
---@field Suffix? string

---@class StepperOptions : ElementOptions
---@field Min? number
---@field Max? number
---@field Default? number
---@field Step? number
---@field Suffix? string

---@class ProgressOptions : ElementOptions
---@field Value? number
---@field Suffix? string

---@class CheckboxGroupOptions : ElementOptions
---@field Options? string[]
---@field Default? string[]

---@class RadioGroupOptions : ElementOptions
---@field Options? string[]
---@field Default? string

---@class TableOptions
---@field Name? string
---@field Columns? string[]
---@field ColumnWidths? number[]
---@field Rows? table[]
---@field Height? number
---@field Callback? fun(row:table)
---@field Tooltip? string

---@class ParagraphOptions
---@field Title? string
---@field Content string

---@class EntryFunc : fun(opts:ElementOptions):Element

---@class Groupbox
---@field Name string
---@field Object Frame
---@field Content Frame
---@field AddButton fun(self:Groupbox, opts:ElementOptions):Element
---@field AddToggle fun(self:Groupbox, opts:ToggleOptions):Element
---@field AddSlider fun(self:Groupbox, opts:SliderOptions):Element
---@field AddDropdown fun(self:Groupbox, opts:DropdownOptions):Element
---@field AddInput fun(self:Groupbox, opts:InputOptions):Element
---@field AddKeybind fun(self:Groupbox, opts:KeybindOptions):Element
---@field AddColorPicker fun(self:Groupbox, opts:ColorPickerOptions):Element
---@field AddRangeSlider fun(self:Groupbox, opts:RangeSliderOptions):Element
---@field AddStepper fun(self:Groupbox, opts:StepperOptions):Element
---@field AddProgressBar fun(self:Groupbox, opts:ProgressOptions):Element
---@field AddCheckboxGroup fun(self:Groupbox, opts:CheckboxGroupOptions):Element
---@field AddRadioGroup fun(self:Groupbox, opts:RadioGroupOptions):Element
---@field AddTable fun(self:Groupbox, opts:TableOptions):Element
---@field AddLabel fun(self:Groupbox, opts:ElementOptions):Element
---@field AddParagraph fun(self:Groupbox, opts:ParagraphOptions):Element
---@field AddDivider fun(self:Groupbox):Element
---@field AddCustom fun(self:Groupbox, name:string, opts:ElementOptions):Element
---@field SetCollapsed fun(self:Groupbox, collapsed:boolean)
---@field IsCollapsed fun(self:Groupbox):boolean

---@class Tab
---@field Name string
---@field Object ScrollingFrame
---@field Button TextButton
---@field AddGroupbox fun(self:Tab, opts:GroupboxOptions):Groupbox
---@field AddLeftGroupbox fun(self:Tab, name:string):Groupbox
---@field AddRightGroupbox fun(self:Tab, name:string):Groupbox
---@field FilterControls fun(self:Tab, keyword:string)
---@field SetBadge fun(self:Tab, text?:string) -- Lite10 徽标; nil/"" 隐藏

---@class Window
---@field Object Frame
---@field Gui ScreenGui
---@field Tabs Tab[]
---@field AddTab fun(self:Window, opts:TabOptions):Tab
---@field SetTitle fun(self:Window, text:string)
---@field SetSubtitle fun(self:Window, text:string)
---@field SetSize fun(self:Window, w:number, h:number)
---@field FitToScreen fun(self:Window, ratio?:number)
---@field SetVisible fun(self:Window, visible:boolean)
---@field Toggle fun(self:Window)
---@field Destroy fun(self:Window)
---@field SetStatus fun(self:Window, text:string) -- Lite10 底部状态栏
---@field SetStatusDot fun(self:Window, color?:Color3, tooltipText?:string) -- Lite10 标题栏状态点
---@field SetToggleKey fun(self:Window, key:Enum.KeyCode|string) -- Lite7
---@field GetToggleKey fun(self:Window):Enum.KeyCode
---@field ResetWindowState fun(self:Window) -- Lite7 恢复默认尺寸/位置/透明度
---@field SetTransparency fun(self:Window, trans:number)

---@class Library
---@field Version string
---@field Theme ThemeTable
---@field Themes {Dark:ThemeTable, Light:ThemeTable}
---@field Fonts {Text:Enum.Font, Bold:Enum.Font}
---@field Settings {TextSize:number, SubSize:number, SmallSize:number, TitleSize:number, HeaderSize:number, Animate:boolean, ANIM:number, MaxScreenRatio:number, MaxNotifications:number}
---@field Config table
---@field ConfigVersion string -- 当前配置格式版本
---@field CreateWindow fun(self:Library, opts:WindowOptions):Window
---@field SetTheme fun(self:Library, theme:string|ThemeTable)
---@field SetDynamicTheme fun(self:Library, fn?:fun():string|ThemeTable) -- Lite10; nil 关闭
---@field SetStyle fun(self:Library, style:table)
---@field SetAnimation fun(self:Library, enabled:boolean)
---@field GetTheme fun(self:Library):ThemeTable
---@field Toggle fun(self:Library)
---@field Notify fun(self:Library, text:string, seconds?:number)|fun(self:Library, opts:NotifyOptions)
---@field Toast fun(self:Library, text:string, seconds?:number)|fun(self:Library, opts:ToastOptions) -- Lite10
---@field DebugLog fun(self:Library, msg:string, level?:"info"|"warn"|"error") -- Lite10
---@field ShowDebugLog fun(self:Library) -- Lite10
---@field CloseDebugLog fun(self:Library) -- Lite10
---@field LogError fun(self:Library, err:any, step?:string) -- Lite10
---@field pcallSafe fun(self:Library, fn:fun(), step?:string):boolean,... -- Lite10
---@field RegisterPlugin fun(self:Library, plugin:PluginOptions) -- Lite10
---@field InstallPlugins fun(self:Library, win?:Window) -- Lite10
---@field UninstallPlugins fun(self:Library) -- Lite10
---@field AddSmoothScroll fun(self:Library, scrollingFrame:ScrollingFrame, speed?:number) -- Lite10
---@field DisableSmoothScrolls fun(self:Library) -- Lite10
---@field SetWatermark fun(self:Library, text:string)
---@field SetWatermarkVisibility fun(self:Library, visible:boolean)
---@field SaveConfig fun(self:Library, name?:string):boolean
---@field LoadConfig fun(self:Library, name?:string):boolean
---@field ResetConfig fun(self:Library, name?:string):number
---@field ExportConfig fun(self:Library, name?:string):string? -- Lite10 JSON 文本
---@field ImportConfig fun(self:Library, jsonText:string):boolean -- Lite10
---@field RegisterConfigMigration fun(self:Library, fromVersion:string, toVersion:string, run:fun(cfg:table):table?):boolean -- v0.8
---@field OnConfigLoaded fun(self:Library, cb:fun())
---@field OnUnload fun(self:Library, cb:fun())
---@field Unload fun(self:Library)
---@field RegisterCustomControl fun(self:Library, name:string, build:fun(content:Frame, opts:ElementOptions, keyPrefix:string):Element):string
---@field RegisterConfigKey fun(self:Library, key:string)
---@field AddTooltip fun(self:Library, obj:Instance, text:string|{Title:string,Content:string})
---@field AddHoverFx fun(self:Library, frame:Frame, hoverColor?:Color3, hoverTransparency?:number, duration?:number) -- Lite10
---@field Tween fun(self:Library, object:Instance, goal:table, time?:number, style?:Enum.EasingStyle, direction?:Enum.EasingDirection)
---@field on fun(self:Library, event:string, cb:fun(...)):fun(...)
---@field once fun(self:Library, event:string, cb:fun(...)):fun(...)
---@field off fun(self:Library, event:string, cb:fun(...))
---@field fire fun(self:Library, event:string, ...)
---@field ConvertColor fun(self:Library, v:Color3|number|string):Color3
---@field IsMouseOver fun(self:Library, obj:GuiObject):boolean

return Library
