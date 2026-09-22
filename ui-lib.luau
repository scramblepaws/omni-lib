--!strict
-- ui-lib.luau | omni generic tabbed menu, nebula-style sidebar (UNC/sUNC, native only)
local Menu = {}

local safe = (cloneref or function(i: any) return i end) :: any
local gethuiFn = (gethui or function() return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end) :: any
local UIS = safe(game:GetService("UserInputService"))

local FONT, TS, ROW = Enum.Font.Code, 13, 24
local ACC = Color3.fromRGB(150, 135, 255) -- ponytail: single accent, swap one line to retheme
local BODY, SIDEBG, SECT, ROWC = Color3.fromRGB(20, 20, 20), Color3.fromRGB(14, 14, 14), Color3.fromRGB(26, 26, 26), Color3.fromRGB(38, 38, 38)
local WHITE, GREY = Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)

local function pad(p: Instance, x: number)
	local u = Instance.new("UIPadding")
	u.PaddingLeft = UDim.new(0, x)
	u.Parent = p
end

local function list(p: Instance, horizontal: boolean?): UIListLayout
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 4)
	if horizontal then l.FillDirection = Enum.FillDirection.Horizontal end
	l.Parent = p
	return l
end

-- ponytail: 14px square box, purple fill when on; pill switch if boxy ever drops
local function box(p: Instance): (Frame, (boolean) -> ())
	local b = Instance.new("Frame")
	b.Size = UDim2.fromOffset(14, 14)
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -6, 0.5, 0)
	b.BackgroundColor3, b.BorderSizePixel = ROWC, 0
	b.Parent = p
	local s = Instance.new("UIStroke")
	s.Thickness, s.Color = 1, Color3.fromRGB(120, 120, 120)
	s.Parent = b
	return b, function(on: boolean) b.BackgroundColor3 = if on then ACC else ROWC end
end

local function controls(host: Instance): any
	local ctl: any = {}
	local function row(): TextButton
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, ROW)
		b.BackgroundColor3, b.Font, b.TextSize = ROWC, FONT, TS
		b.TextColor3, b.TextXAlignment, b.AutoButtonColor = WHITE, Enum.TextXAlignment.Left, false
		b.Text = ""
		b.Parent = host
		pad(b, 6)
		return b
	end
	local function label(b: TextButton, t: string)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -28, 1, 0)
		l.BackgroundTransparency = 1
		l.Font, l.TextSize, l.TextColor3 = FONT, TS, WHITE
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Text = t
		l.Parent = b
		return l
	end
	function ctl:AddButton(t: string, cb: () -> ())
		local b = row()
		label(b, t)
		b.MouseButton1Click:Connect(function()
			b.BackgroundColor3 = ACC -- ponytail: flash confirm, delete if distracting
			task.delay(0.08, function() b.BackgroundColor3 = ROWC end)
			pcall(cb)
		end)
		return b
	end
	function ctl:AddToggle(t: string, default: boolean, cb: (boolean) -> ())
		local on = default
		local b = row()
		label(b, t)
		local _, paint = box(b)
		paint(on)
		b.MouseButton1Click:Connect(function() on = not on; paint(on); pcall(cb, on) end)
		pcall(cb, on)
		return b
	end
	function ctl:AddSlider(t: string, min: number, max: number, default: number, cb: (number) -> ())
		local v, hold = math.clamp(default, min, max), false
		local b = row()
		local fill = Instance.new("Frame")
		fill.BackgroundColor3, fill.BorderSizePixel = ACC, 0
		fill.Parent = b
		local lab = Instance.new("TextLabel")
		lab.Size = UDim2.new(1, -6, 1, 0)
		lab.BackgroundTransparency = 1
		lab.Font, lab.TextSize, lab.TextColor3 = FONT, TS, WHITE
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.TextTruncate = Enum.TextTruncate.AtEnd
		lab.Parent = b
		local function paint()
			v = math.floor(math.clamp(v, min, max) * 10 + 0.5) / 10
			fill.Size = UDim2.new(if max == min then 0 else (v - min) / (max - min), 0, 1, 0)
			lab.Text = `{t} [{string.format("%.1f", v)}]`
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
			v = min + (max - min) * math.clamp((i.Position.X - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1)
			paint()
			pcall(cb, v)
		end)
		pcall(cb, v)
		return b
	end
	function ctl:AddKeybind(t: string, default: Enum.KeyCode, cb: (Enum.KeyCode) -> ())
		local key, wait = default, false
		local b = row()
		local left = label(b, t)
		local right = Instance.new("TextLabel")
		right.Size = UDim2.new(0, 80, 1, 0)
		right.AnchorPoint = Vector2.new(1, 0)
		right.Position = UDim2.new(1, -6, 0, 0)
		right.BackgroundTransparency = 1
		right.Font, right.TextSize = FONT, TS
		right.TextColor3, right.TextXAlignment = GREY, Enum.TextXAlignment.Right
		right.Parent = b
		local function paint()
			left.Text, right.Text = t, if wait then "[...]" else `[{key.Name}]`
		end
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

function Menu.Window(title: string, toggleKey: Enum.KeyCode?)
	toggleKey = toggleKey or Enum.KeyCode.RightShift
	local root = gethuiFn()
	local old = root:FindFirstChild(title) -- ponytail: reload guard, drop for multi-window
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name, gui.DisplayOrder, gui.ResetOnSpawn = title, 999, false
	gui.Parent = root

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(560, 360)
	frame.Position = UDim2.new(0.5, -280, 0.5, -180)
	frame.BackgroundColor3 = BODY
	frame.Active, frame.Draggable = true, true
	frame.Parent = gui
	local outer = Instance.new("UIStroke") -- ponytail: 2 strokes = inner+outer, merge if engine drops one
	outer.Thickness, outer.Color = 2, WHITE
	outer.Parent = frame
	local inner = Instance.new("UIStroke")
	inner.Thickness, inner.Color, inner.ApplyStrokeMode = 2, Color3.fromRGB(120, 120, 120), Enum.ApplyStrokeMode.Border
	inner.Parent = frame

	-- sidebar
	local side = Instance.new("Frame")
	side.Size = UDim2.new(0, 140, 1, 0)
	side.BackgroundColor3, side.BorderSizePixel = SIDEBG, 0
	side.Parent = frame
	local logo = Instance.new("TextLabel")
	logo.Size = UDim2.new(1, 0, 0, 30)
	logo.BackgroundTransparency = 1
	logo.Font, logo.TextSize, logo.TextColor3, logo.Text = FONT, 15, WHITE, title
	logo.Parent = side
	local sheen = Instance.new("UIGradient") -- ponytail: slow sweep, delete grad + thread if distracting
	sheen.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, WHITE),
		ColorSequenceKeypoint.new(0.35, WHITE),
		ColorSequenceKeypoint.new(0.5, ACC),
		ColorSequenceKeypoint.new(0.65, WHITE),
		ColorSequenceKeypoint.new(1, WHITE),
	})
	sheen.Parent = logo
	task.spawn(function()
		while gui.Parent do
			for o = -1, 1, 0.05 do
				if not gui.Parent then break end
				sheen.Offset = Vector2.new(o, 0)
				task.wait(0.05)
			end
		end
	end)
	local rule = Instance.new("Frame")
	rule.Size = UDim2.new(1, -16, 0, 2)
	rule.Position = UDim2.new(0, 8, 0, 30)
	rule.BackgroundColor3, rule.BorderSizePixel = ACC, 0
	rule.Parent = side
	local nav = Instance.new("Frame")
	nav.Size = UDim2.new(1, 0, 1, -36)
	nav.Position = UDim2.fromOffset(0, 36)
	nav.BackgroundTransparency = 1
	nav.Parent = side
	list(nav, false)
	pad(nav, 8)

	-- content
	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -140, 1, 0)
	content.Position = UDim2.fromOffset(140, 0)
	content.BackgroundTransparency = 1
	content.Parent = frame
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 26)
	bar.BackgroundTransparency = 1
	bar.Parent = content
	list(bar, true)
	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, 0, 1, -26)
	body.Position = UDim2.fromOffset(0, 26)
	body.BackgroundTransparency = 1
	body.Parent = content

	UIS.InputBegan:Connect(function(i: InputObject, gpe: boolean)
		if gpe then return end
		if i.KeyCode == toggleKey then gui.Enabled = not gui.Enabled end
	end)

	local self: any = {}
	local pages: { ScrollingFrame } = {}
	local tabs: { TextButton } = {}
	local navs: { TextButton } = {}
	local function select(idx: number)
		for i, p in pages do
			local on = i == idx
			p.Visible = on
			local tf: any = tabs[i]:FindFirstChildOfClass("Frame")
			if tf then tf.Visible = on end
			local nf: any = navs[i]:FindFirstChildOfClass("Frame")
			if nf then nf.Visible = on end
			local nl: any = navs[i]:FindFirstChildOfClass("TextLabel")
			if nl then nl.TextColor3 = if on then WHITE else GREY end
		end
	end
	function self:Tab(name: string)
		local pg = Instance.new("ScrollingFrame")
		pg.Name = name
		pg.Size = UDim2.new(1, 0, 1, 0)
		pg.BackgroundTransparency = 1
		pg.ScrollBarThickness = 3
		pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
		pg.CanvasSize = UDim2.new(0, 0, 0, 0)
		pg.Visible = #pages == 0
		pg.Parent = body
		list(pg, false)
		local qp = Instance.new("UIPadding")
		qp.PaddingLeft, qp.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)
		qp.Parent = pg
		table.insert(pages, pg)

		local tb = Instance.new("TextButton")
		tb.Size = UDim2.new(0, 96, 1, 0)
		tb.BackgroundTransparency = 1
		tb.Font, tb.TextSize, tb.TextColor3, tb.Text = FONT, TS, WHITE, name
		tb.Parent = bar
		local ul = Instance.new("Frame")
		ul.Size = UDim2.new(1, 0, 0, 2)
		ul.Position = UDim2.new(0, 0, 1, -2)
		ul.BackgroundColor3, ul.BorderSizePixel, ul.Visible = ACC, 0, #pages == 1
		ul.Parent = tb
		table.insert(tabs, tb)

		local nb = Instance.new("TextButton")
		nb.Size = UDim2.new(1, 0, 0, ROW)
		nb.BackgroundTransparency = 1
		nb.Font, nb.TextSize, nb.Text = FONT, TS, name
		nb.TextColor3, nb.TextXAlignment, nb.AutoButtonColor = GREY, Enum.TextXAlignment.Left, false
		nb.Parent = nav
		local edge = Instance.new("Frame") -- ponytail: left-edge mark, swap for bg block if noisy
		edge.Size = UDim2.new(0, 2, 1, 0)
		edge.BackgroundColor3, edge.BorderSizePixel, edge.Visible = ACC, 0, #pages == 1
		edge.Parent = nb
		table.insert(navs, nb)
		if #pages == 1 then
			local first: any = navs[1]:FindFirstChildOfClass("TextLabel")
			if first then first.TextColor3 = WHITE end
		end
		local idx = #pages
		tb.MouseButton1Click:Connect(function() select(idx) end)
		nb.MouseButton1Click:Connect(function() select(idx) end)

		local ctl: any = controls(pg)
		function ctl:Section(t: string, default: boolean, cb: (boolean) -> ())
			local on = default
			local wrap = Instance.new("Frame")
			wrap.Size = UDim2.new(1, 0, 0, 0)
			wrap.AutomaticSize = Enum.AutomaticSize.Y
			wrap.BackgroundColor3, wrap.BorderSizePixel = SECT, 0
			wrap.Parent = pg
			list(wrap, false)
			local qp2 = Instance.new("UIPadding")
			qp2.PaddingTop, qp2.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
			qp2.Parent = wrap
			local head = Instance.new("TextButton")
			head.Size = UDim2.new(1, 0, 0, ROW)
			head.BackgroundTransparency = 1
			head.Font, head.TextSize, head.TextColor3 = FONT, TS, WHITE
			head.TextXAlignment, head.AutoButtonColor = Enum.TextXAlignment.Left, false
			head.Text = "  " .. t
			head.Parent = wrap
			local _, paint = box(head)
			paint(on)
			head.MouseButton1Click:Connect(function() on = not on; paint(on); pcall(cb, on) end)
			pcall(cb, on)
			local innerHost = Instance.new("Frame")
			innerHost.Size = UDim2.new(1, 0, 0, 0)
			innerHost.AutomaticSize = Enum.AutomaticSize.Y
			innerHost.BackgroundTransparency = 1
			innerHost.Parent = wrap
			list(innerHost, false)
			local qp3 = Instance.new("UIPadding")
			qp3.PaddingLeft, qp3.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)
			qp3.Parent = innerHost
			return controls(innerHost)
		end
		return ctl
	end
	function self.Destroy() gui:Destroy() end
	return self
end

getgenv().Menu = Menu -- ponytail: run ui-lib first, demo picks it up, no file IO needed

return Menu
