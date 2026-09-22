--!strict
-- ui-lib.luau | omni generic tabbed menu (UNC/sUNC, native Instances, no deps)
local Menu = {}

local safe = (cloneref or function(i: any) return i end) :: any
local gethuiFn = (gethui or function() return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end) :: any
local UIS = safe(game:GetService("UserInputService"))

local FONT, TS, ROW = Enum.Font.Code, 13, 24
local BODY, TITLEC, ROWC = Color3.fromRGB(20, 20, 20), Color3.fromRGB(35, 35, 35), Color3.fromRGB(50, 50, 50)
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

local function text(p: Instance, s: string, c: Color3): TextLabel
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.Font, t.TextSize, t.TextColor3, t.Text = FONT, TS, c, s
	t.Parent = p
	return t
end

local function page(title: string, parent: Instance): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Name = title
	s.Size = UDim2.new(1, 0, 1, 0)
	s.BackgroundTransparency = 1
	s.ScrollBarThickness = 3
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.CanvasSize = UDim2.new(0, 0, 0, 0)
	s.Visible = false
	s.Parent = parent
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 4)
	l.Parent = s
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)
	p.Parent = s
	return s
end

function Menu.Window(title: string, toggleKey: Enum.KeyCode?)
	toggleKey = toggleKey or Enum.KeyCode.RightShift
	local root = gethuiFn()
	local old = root:FindFirstChild(title) -- ponytail: reload guard, drop for multi-window
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name, gui.DisplayOrder, gui.ResetOnSpawn = title, 999, false
	gui.Parent = root

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(400, 300)
	frame.Position = UDim2.new(0.5, -200, 0.5, -150)
	frame.BackgroundColor3 = BODY
	frame.Active, frame.Draggable = true, true
	frame.Parent = gui
	local outer = Instance.new("UIStroke") -- ponytail: 2 strokes = inner+outer, merge if engine drops one
	outer.Thickness, outer.Color = 2, WHITE
	outer.Parent = frame
	local inner = Instance.new("UIStroke")
	inner.Thickness, inner.Color, inner.ApplyStrokeMode = 2, Color3.fromRGB(120, 120, 120), Enum.ApplyStrokeMode.Border
	inner.Parent = frame

	local head = Instance.new("TextLabel")
	head.Size = UDim2.new(1, 0, 0, 28)
	head.BackgroundColor3, head.Font, head.TextSize, head.TextColor3, head.Text = TITLEC, FONT, TS, WHITE, title
	head.Parent = frame

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 26)
	bar.Position = UDim2.fromOffset(0, 28)
	bar.BackgroundTransparency = 1
	bar.Parent = frame
	local bl = Instance.new("UIListLayout")
	bl.FillDirection, bl.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 4)
	bl.Parent = bar

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, 0, 1, -54)
	body.Position = UDim2.fromOffset(0, 54)
	body.BackgroundTransparency = 1
	body.Parent = frame

	UIS.InputBegan:Connect(function(i: InputObject, gpe: boolean)
		if gpe then return end
		if i.KeyCode == toggleKey then gui.Enabled = not gui.Enabled end
	end)

	local self: any = {}
	local pages: { ScrollingFrame } = {}
	local tabs: { TextButton } = {}
	function self:Tab(name: string)
		local pg = page(name, body)
		table.insert(pages, pg)
		local tb = Instance.new("TextButton")
		tb.Size = UDim2.new(0, 96, 1, 0)
		tb.BackgroundTransparency = 1
		tb.Font, tb.TextSize, tb.TextColor3, tb.Text = FONT, TS, WHITE, name
		tb.Parent = bar
		local ul = Instance.new("Frame") -- ponytail: underline mark, swap for bg-block if noisy
		ul.Size = UDim2.new(1, 0, 0, 2)
		ul.Position = UDim2.new(0, 0, 1, -2)
		ul.BackgroundColor3, ul.Visible = WHITE, #pages == 1
		ul.Parent = tb
		table.insert(tabs, tb)
		if #pages == 1 then pg.Visible = true end
		tb.MouseButton1Click:Connect(function()
			for i, p in pages do p.Visible = (p == pg); (tabs[i]:FindFirstChildOfClass("Frame") :: Frame).Visible = (p == pg) end
		end)

		local ctl: any = {}
		local function row(): TextButton
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, ROW)
			b.BackgroundColor3, b.Font, b.TextSize, b.TextColor3 = ROWC, FONT, TS, WHITE
			b.AutoButtonColor = false
			b.Parent = pg
			return b
		end
		function ctl:AddButton(t: string, cb: () -> ())
			local b = row()
			b.Text = t
			b.MouseButton1Click:Connect(function()
				b.BackgroundColor3 = WHITE -- ponytail: flash confirm, delete if distracting
				task.delay(0.08, function() b.BackgroundColor3 = ROWC end)
				pcall(cb)
			end)
			return b
		end
		function ctl:AddToggle(t: string, default: boolean, cb: (boolean) -> ())
			local on = default
			local b = row()
			local function paint()
				b.BackgroundColor3 = if on then WHITE else ROWC
				b.TextColor3 = if on then BLACK else WHITE
				b.Text = t
			end
			paint()
			b.MouseButton1Click:Connect(function() on = not on; paint(); pcall(cb, on) end)
			pcall(cb, on)
			return b
		end
		function ctl:AddSlider(t: string, min: number, max: number, default: number, cb: (number) -> ())
			local v = math.clamp(default, min, max)
			local hold = false
			local b = row()
			b.Text = ""
			local fill = Instance.new("Frame")
			fill.BackgroundColor3, fill.BorderSizePixel = WHITE, 0
			fill.Parent = b
			local lab = text(b, "", WHITE)
			lab.TextXAlignment = Enum.TextXAlignment.Left
			local function paint()
				v = math.floor((math.clamp(v, min, max)) * 10 + 0.5) / 10
				fill.Size = UDim2.new(if max == min then 0 else (v - min) / (max - min), 0, 1, 0)
				lab.Text = ` {t} [{string.format("%.1f", v)}]`
				lab.TextColor3 = if v > min then BLACK else WHITE
			end
			paint()
			b.InputBegan:Connect(function(i: InputObject)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then hold = true end
			end)
			UIS.InputEnded:Connect(function(i: InputObject)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then hold = false end
			end)
			UIS.InputChanged:Connect(function(i: InputObject)
				if not hold or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
				local r = math.clamp((i.Position.X - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1)
				v = min + (max - min) * r
				paint()
				pcall(cb, v)
			end)
			pcall(cb, v)
			return b
		end
		function ctl:AddKeybind(t: string, default: Enum.KeyCode, cb: (Enum.KeyCode) -> ())
			local key, wait = default, false
			local b = row()
			local function paint() b.Text = if wait then `{t} [...]` else `{t} [{key.Name}]` end
			paint()
			b.MouseButton1Click:Connect(function() wait = true; paint() end)
			UIS.InputBegan:Connect(function(i: InputObject, gpe: boolean)
				if gpe or not wait or i.KeyCode == Enum.KeyCode.Unknown then return end
				wait = false
				if i.KeyCode ~= Enum.KeyCode.Escape then key = i.KeyCode; pcall(cb, key) end
				paint()
			end)
			pcall(cb, key)
			return b
		end
		return ctl
	end
	function self.Destroy() gui:Destroy() end
	return self
end

getgenv().Menu = Menu -- ponytail: run ui-lib first, demo picks it up, no file IO needed

return Menu
