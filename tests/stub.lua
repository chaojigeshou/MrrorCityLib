-- MrrorCityLib 冒烟测试: Roblox 全局 stub + Instance 模拟器
-- 与 source.lua 拼接后由 luau.exe 执行, 验证完整 API 创建流程

local function signal()
	return {
		Connect = function(self, cb)
			return { Disconnect = function(self) end }
		end,
		Wait = function(self)
			return nil
		end,
	}
end

local function mockInstance(className)
	local self = { ClassName = className, Children = {} }
	self.Destroy = function(self)
		local p = rawget(self, "_parent")
		if type(p) == "table" and p.Children then
			for i = #p.Children, 1, -1 do
				if p.Children[i] == self then
					table.remove(p.Children, i)
				end
			end
		end
		rawset(self, "_destroyed", true)
	end
	self.FindFirstChild = function(self, name)
		for _, child in ipairs(self.Children) do
			if child.Name == name then
				return child
			end
		end
		return nil
	end
	self.FindFirstChildOfClass = function(self, className)
		for _, child in ipairs(self.Children) do
			if child.ClassName == className then
				return child
			end
		end
		return nil
	end
	self.GetPropertyChangedSignal = function(self, prop)
		return signal()
	end
	self.GetAttribute = function(self, name)
		return rawget(self, "_attr_" .. tostring(name))
	end
	self.SetAttribute = function(self, name, value)
		rawset(self, "_attr_" .. tostring(name), value)
	end
	self.WaitForChild = function(self, name)
		return self:FindFirstChild(name)
	end
	self.GetChildren = function(self)
		return self.Children
	end
	self.GetDescendants = function(self)
		local out = {}
		for _, child in ipairs(self.Children) do
			table.insert(out, child)
			for _, sub in ipairs(child:GetDescendants()) do
				table.insert(out, sub)
			end
		end
		return out
	end
	self.IsDescendantOf = function(self, ancestor)
		local cur = rawget(self, "_parent")
		while type(cur) == "table" do
			if cur == ancestor then
				return true
			end
			cur = rawget(cur, "_parent")
		end
		return false
	end
	self.IsA = function(self, className)
		return self.ClassName == className
	end
	local mt = {
		__index = function(t, key)
			local v = rawget(t, key)
			if v ~= nil then
				return v
			end
			local ev = signal()
			rawset(t, key, ev)
			return ev
		end,
		__newindex = function(t, key, value)
			if key == "Parent" then
				rawset(t, "_parent", value)
				if type(value) == "table" and value.Children then
					table.insert(value.Children, self)
				end
			else
				rawset(t, key, value)
			end
		end,
	}
	return setmetatable(self, mt)
end

Instance = { new = function(className)
	return mockInstance(className)
end }

game = {
	GetService = function(self, name)
		if name == "UserInputService" then
			return {
				InputBegan = signal(),
				InputChanged = signal(),
				InputEnded = signal(),
				GetMouseLocation = function(self)
					return { X = 640, Y = 360 }
				end,
				GetFocusedTextBox = function(self)
					return nil
				end,
			}
		elseif name == "TweenService" then
			return {
				Create = function(self, object, info, goal)
					return { Play = function(self) end, Cancel = function(self) end }
				end,
			}
		elseif name == "TextService" then
			return {
				GetTextSize = function(self, text, size, font)
					return { X = 80, Y = 16 }
				end,
			}
		elseif name == "HttpService" then
			return {
				JSONEncode = function(self, data)
					return "{}"
				end,
				JSONDecode = function(self, json)
					return {}
				end,
				RequestAsync = function(self, req)
					return { Success = false }
				end,
			}
		elseif name == "Players" then
			return { LocalPlayer = nil }
		elseif name == "CoreGui" then
			return mockInstance("CoreGui")
		end
		return {}
	end,
}

Enum = {
	Font = { Gotham = "Gotham", GothamBold = "GothamBold", LuaGothic = "LuaGothic", LuaGothicBold = "LuaGothicBold" },
	UserInputType = { MouseButton1 = 1, MouseMovement = 2, Keyboard = 3, MouseWheel = 4 },
	TextXAlignment = { Left = 0, Right = 1, Center = 2 },
	TextYAlignment = { Center = 0, Top = 1 },
	TextTruncate = { AtEnd = 0 },
	FillDirection = { Horizontal = 0, Vertical = 1 },
	HorizontalAlignment = { Left = 0, Center = 1, Right = 2 },
	SortOrder = { LayoutOrder = 0 },
	ZIndexBehavior = { Sibling = 0 },
	ScrollingDirection = { Y = 0, X = 1 },
	AutomaticSize = { None = 0, X = 1, Y = 2, Union = 3 },
	ScaleType = { Fit = 0 },
	EasingStyle = { Quart = 0, Quad = 1, Back = 2 },
	EasingDirection = { Out = 0, In = 1 },
	KeyCode = {
		None = { Name = "None" },
		Escape = { Name = "Escape" },
		RightShift = { Name = "RightShift" },
		V = { Name = "V" },
	},
}
Color3 = {
	new = function(r, g, b)
		return { R = r, G = g, B = b }
	end,
	fromRGB = function(r, g, b)
		return { R = r / 255, G = g / 255, B = b / 255 }
	end,
}
ColorSequence = { new = function(keypoints)
	return { Keypoints = keypoints }
end }
ColorSequenceKeypoint = { new = function(pos, color, transparency)
	return { Position = pos, Color = color, Transparency = transparency }
end }
Vector2 = {
	new = function(x, y)
		return { X = x, Y = y }
	end,
	zero = { X = 0, Y = 0 },
}
UDim = { new = function(a, b)
	return { A = a, B = b }
end }
UDim2 = {
	fromOffset = function(x, y)
		return { X = { Offset = x, Scale = 0 }, Y = { Offset = y, Scale = 0 } }
	end,
	fromScale = function(sx, sy)
		return { X = { Offset = 0, Scale = sx }, Y = { Offset = 0, Scale = sy } }
	end,
	new = function(sx, x, sy, y)
		return { X = { Offset = x, Scale = sx }, Y = { Offset = y, Scale = sy } }
	end,
}
TweenInfo = { new = function(...)
	return {}
end }
task = {
	delay = function(t, cb)
		return
	end,
	defer = function(cb)
		cb()
		return
	end,
	wait = function()
		return
	end,
}
writefile = nil
readfile = nil
isfile = nil
warn = function(...) end
_G = {} -- luau CLI 的 _G 只读, 换成可写表 (真实 Roblox 中 _G 可写)
workspace = { CurrentCamera = { ViewportSize = { X = 1920, Y = 1080 } } }

--========== 以下为 MrrorCityLib source.lua ==========
