--!strict
-- ui-lib.luau | omni generic tabbed menu, nebula-style sidebar (UNC/sUNC, native only)
local Menu = {}

local safe = (cloneref or function(i: any) return i end) :: any
local gethuiFn = (gethui or function() return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end) :: any
local UIS = safe(game:GetService("UserInputService"))

local FONT, TS, ROW = Enum.Font.Code, 13, 24
local ACC = Color3.fromRGB(178, 156, 255) -- ponytail: Akiri purple accent
local OUTLINE = Color3.new(0, 0, 0)
local BLACK = Color3.new(0, 0, 0)
local BODY = Color3.fromRGB(25, 20, 45)
local SIDEBG = Color3.fromRGB(20, 16, 36)
local SECT = Color3.fromRGB(40, 34, 64)
local ROWC = Color3.fromRGB(46, 42, 76)
local TEXTPC = Color3.fromRGB(200, 190, 255)
local TEXTDIM = Color3.fromRGB(140, 135, 180)

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

local function controls(host: Instance, ctx: any): any
	local ctl: any = {}
	local function closePop()
		if ctx.pop then
			ctx.pop:Destroy()
			ctx.pop = nil
		end
		if ctx.veil then
			ctx.veil:Destroy()
			ctx.veil = nil
		end
	end
	ctx.close = closePop
	local function popFrame(w: number, h: number, rowBtn: TextButton): Frame
		closePop()
		local veil = Instance.new("TextButton")
		veil.Size = UDim2.new(1, 0, 1, 0)
		veil.BackgroundTransparency = 1
		veil.Text = ""
		veil.AutoButtonColor = false
		veil.Parent = ctx.frame
		veil.MouseButton1Click:Connect(closePop)
		veil.MouseButton2Click:Connect(closePop)
		ctx.veil = veil
		local pop = Instance.new("Frame")
		pop.Size = UDim2.fromOffset(w, h)
		local fp, rp = ctx.frame.AbsolutePosition, rowBtn.AbsolutePosition
		local s = ctx.zoom.Scale
		local y = (rp.Y - fp.Y) / s + ROW
		if y + h > ctx.frame.AbsoluteSize.Y / s then
			y = (rp.Y - fp.Y) / s - h
		end
		pop.Position = UDim2.fromOffset((rp.X - fp.X) / s, y)
		pop.BackgroundColor3, pop.BorderSizePixel = SECT, 0
		pop.Parent = ctx.frame
		local st = Instance.new("UIStroke")
		st.Thickness, st.Color = 1, Color3.fromRGB(120, 120, 120)
		st.Parent = pop
		ctx.pop = pop
		return pop
	end
		local function row(): TextButton
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, ROW)
			b.BackgroundColor3, b.Font, b.TextSize = ROWC, FONT, TS
		b.TextColor3, b.TextXAlignment, b.AutoButtonColor = TEXTPC, Enum.TextXAlignment.Left, false
		b.Text = ""
		b.Parent = host
		pad(b, 6)
		b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(56, 52, 88) end)
		b.MouseLeave:Connect(function() b.BackgroundColor3 = ROWC end)
			return b
		end
	local function label(b: TextButton, t: string)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -28, 1, 0)
		l.BackgroundTransparency = 1
		l.Font, l.TextSize, l.TextColor3 = FONT, TS, TEXTPC
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
		local bound: Enum.KeyCode? = nil
		local mode, wait = "toggle", false
		local b = row()
		local tl = label(b, t)
		tl.Size = UDim2.new(1, -84, 1, 0)
		local bl = Instance.new("TextLabel")
		bl.Size = UDim2.new(0, 52, 1, 0)
		bl.AnchorPoint = Vector2.new(1, 0)
		bl.Position = UDim2.new(1, -26, 0, 0)
		bl.BackgroundTransparency = 1
		bl.Font, bl.TextSize = FONT, TS
		bl.TextColor3, bl.TextXAlignment = TEXTDIM, Enum.TextXAlignment.Right
		bl.Text = ""
		bl.Parent = b
		local entry = {name = t, key = "", mode = "toggle"}
		table.insert(binds, entry)
		local _, paint = box(b)
		local function show()
			paint(on)
			if wait then
				bl.Text = "[...]"
			elseif bound then
				bl.Text = if mode == "hold" then "[" .. bound.Name .. "+]" else "[" .. bound.Name .. "]"
			else
				bl.Text = ""
			end
		end
		show()
		b.MouseButton1Click:Connect(function()
			if wait then return end
			on = not on
			entry.key = bound and bound.Name or ""
			entry.mode = mode
			if ctx.refresh then ctx.refresh() end
			pcall(cb, on)
		end)
		b.MouseButton2Click:Connect(function()
			if wait then
				wait = false
				bound = nil
				mode = "toggle"
			elseif not bound then
				wait = true
			elseif mode == "toggle" then
				mode = "hold"
			else
				bound = nil
				mode = "toggle"
			end
			entry.key = bound and bound.Name or ""
			entry.mode = mode
			if ctx.refresh then ctx.refresh() end
			show()
		end)
		UIS.InputBegan:Connect(function(i: InputObject, gpe: boolean)
			if gpe or i.KeyCode == Enum.KeyCode.Unknown then return end
			if wait then
				if i.KeyCode == Enum.KeyCode.Escape then
					bound = nil
				else
					bound = i.KeyCode
				end
				mode = "toggle"
				wait = false
				entry.key = bound and bound.Name or ""
				entry.mode = mode
				if ctx.refresh then ctx.refresh() end
				show()
				return
			end
			if bound and i.KeyCode == bound then
				if mode == "hold" then
					on = true
				else
					on = not on
				end
				entry.key = bound and bound.Name or ""
				entry.mode = mode
				if ctx.refresh then ctx.refresh() end
				show()
				pcall(cb, on)
			end
		end)
		UIS.InputEnded:Connect(function(i: InputObject)
			if bound and mode == "hold" and i.KeyCode == bound and on then
				on = false
				entry.key = bound and bound.Name or ""
				entry.mode = mode
				if ctx.refresh then ctx.refresh() end
				show()
				pcall(cb, on)
			end
		end)
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
			lab.Font, lab.TextSize, lab.TextColor3 = FONT, TS, TEXTPC
		lab.TextXAlignment = Enum.TextXAlignment.Left
			lab.TextTruncate = Enum.TextTruncate.AtEnd
			lab.Parent = b
			local stroke = Instance.new("UIStroke") -- ponytail: keeps white text readable over fill
			stroke.Thickness, stroke.Color, stroke.Transparency = 1, BLACK, 0.4
			stroke.Parent = lab
		local function paint()
			v = math.floor(math.clamp(v, min, max) * 10 + 0.5) / 10
			fill.Size = UDim2.new(if max == min then 0 else (v - min) / (max - min), 0, 1, 0)
			lab.Text = `{t} [{string.format("%.1f", v)}]`
		end
		paint()
			local function setAt(px: number)
				v = min + (max - min) * math.clamp((px - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1)
				paint()
				pcall(cb, v)
			end
			b.InputBegan:Connect(function(i: InputObject)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then
					hold = true
					setAt(i.Position.X)
				end
			end)
		UIS.InputEnded:Connect(function(i: InputObject)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then hold = false end
		end)
			UIS.InputChanged:Connect(function(i: InputObject)
				if not hold or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
				setAt(i.Position.X)
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
		right.TextColor3, right.TextXAlignment = TEXTDIM, Enum.TextXAlignment.Right
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
	function ctl:AddDropdown(t: string, options: { string }, defaults: { boolean }?, cb: ({ boolean }) -> ())
		local sel: { boolean } = {}
		for i in options do sel[i] = if defaults then defaults[i] == true else false end
		local b = row()
		local lab = label(b, t)
		local function preview()
			local names: { string } = {}
			for i, on in sel do
				if on then table.insert(names, options[i]) end
			end
			local s = table.concat(names, ", ")
			if s == "" then s = "none" end
			lab.Text = t .. " [" .. s .. "]"
		end
		preview()
		b.MouseButton1Click:Connect(function()
			if #options == 0 then return end
			if ctx.pop and ctx.pop:GetAttribute("owner") == b then
				closePop()
				return
			end
			local pop = popFrame(200, math.min(#options, 6) * ROW + 8, b)
			pop:SetAttribute("owner", b)
			local inner = Instance.new("ScrollingFrame")
			inner.Size = UDim2.new(1, -8, 1, -8)
			inner.Position = UDim2.fromOffset(4, 4)
			inner.BackgroundTransparency = 1
			inner.ScrollBarThickness = 2
			inner.AutomaticCanvasSize = Enum.AutomaticSize.Y
			inner.CanvasSize = UDim2.new(0, 0, 0, 0)
			inner.ScrollingDirection = Enum.ScrollingDirection.Y
			inner.Parent = pop
			list(inner, false)
			for i, name in options do
				local ob = Instance.new("TextButton")
				ob.Size = UDim2.new(1, 0, 0, ROW)
				ob.BackgroundColor3, ob.Font, ob.TextSize = ROWC, FONT, TS
				ob.TextColor3, ob.TextXAlignment, ob.AutoButtonColor = TEXTPC, Enum.TextXAlignment.Left, false
				ob.Text = "  " .. name
				ob.Parent = inner
				local _, paint = box(ob)
				paint(sel[i])
				ob.MouseButton1Click:Connect(function()
					sel[i] = not sel[i]
					paint(sel[i])
					preview()
					pcall(cb, sel)
				end)
			end
		end)
		pcall(cb, sel)
		return b
	end
	function ctl:AddColor(t: string, default: Color3, cb: (Color3) -> ())
		local h, s, v = default:ToHSV()
		local b = row()
		label(b, t)
		local sw = Instance.new("Frame")
		sw.Size = UDim2.fromOffset(14, 14)
		sw.AnchorPoint = Vector2.new(1, 0.5)
		sw.Position = UDim2.new(1, -6, 0.5, 0)
		sw.BackgroundColor3, sw.BorderSizePixel = default, 0
		sw.Parent = b
		local function cur(): Color3 return Color3.fromHSV(h, s, v) end
		b.MouseButton1Click:Connect(function()
			if ctx.pop and ctx.pop:GetAttribute("owner") == b then
				closePop()
				return
			end
			local pop = popFrame(176, 200, b)
			pop:SetAttribute("owner", b)
			local sv = Instance.new("TextButton")
			sv.Size = UDim2.new(1, -16, 0, 160)
			sv.Position = UDim2.fromOffset(8, 8)
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			sv.AutoButtonColor, sv.Text = false, ""
			sv.Parent = pop
			local satL = Instance.new("Frame")
			satL.Size = UDim2.new(1, 0, 1, 0)
			satL.BackgroundColor3, satL.BorderSizePixel = TEXTPC, 0
			satL.Parent = sv
			local satG = Instance.new("UIGradient")
			satG.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
			satG.Parent = satL
			local valL = Instance.new("Frame")
			valL.Size = UDim2.new(1, 0, 1, 0)
			valL.BackgroundColor3, valL.BorderSizePixel = BLACK, 0
			valL.Parent = sv
			local valG = Instance.new("UIGradient")
			valG.Rotation = 90
			valG.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
			valG.Parent = valL
			local cur2 = Instance.new("Frame")
			cur2.Size = UDim2.fromOffset(6, 6)
			cur2.AnchorPoint = Vector2.new(0.5, 0.5)
			cur2.BackgroundTransparency = 1
			cur2.Parent = sv
			local cs = Instance.new("UIStroke")
			cs.Thickness, cs.Color = 1, TEXTPC
			cs.Parent = cur2
			local hue = Instance.new("TextButton")
			hue.Size = UDim2.new(1, -16, 0, 16)
			hue.Position = UDim2.fromOffset(8, 176)
			hue.AutoButtonColor, hue.Text = false, ""
			hue.Parent = pop
			local hueG = Instance.new("UIGradient")
			hueG.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			})
			hueG.Parent = hue
			local hueC = Instance.new("Frame")
			hueC.Size = UDim2.new(0, 4, 1, 0)
			hueC.BackgroundColor3, hueC.BorderSizePixel = TEXTPC, 0
			hueC.Parent = hue
			local function paint()
				sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				cur2.Position = UDim2.new(s, 0, 1 - v, 0)
				hueC.Position = UDim2.new(h, 0, 0, 0)
				sw.BackgroundColor3 = cur()
			end
			paint()
			local drag: TextButton? = nil
			local function setFrom(i: InputObject)
				if drag == sv then
					s = math.clamp((i.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
					v = 1 - math.clamp((i.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
				elseif drag == hue then
					h = math.clamp((i.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 0.999)
				else
					return
				end
				paint()
				pcall(cb, cur())
			end
			sv.InputBegan:Connect(function(i: InputObject)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then
					drag = sv
					setFrom(i)
				end
			end)
			hue.InputBegan:Connect(function(i: InputObject)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then
					drag = hue
					setFrom(i)
				end
			end)
			UIS.InputEnded:Connect(function(i: InputObject)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = nil end
			end)
			UIS.InputChanged:Connect(function(i: InputObject)
				if drag and i.UserInputType == Enum.UserInputType.MouseMovement then setFrom(i) end
			end)
		end)
		pcall(cb, cur())
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
	frame.Size = UDim2.fromOffset(620, 360)
	frame.Position = UDim2.new(0.5, -310, 0.5, -180)
	frame.BackgroundColor3 = BODY
	frame.Active, frame.Draggable = true, true
	frame.Parent = gui
	local zoom = Instance.new("UIScale") -- ponytail: uniform scale, layout-proof
	zoom.Parent = frame
	local function fit()
		local h = 900
		local cam = workspace.CurrentCamera
		if cam then h = cam.ViewportSize.Y end
		zoom.Scale = math.clamp(h / 900, 0.8, 1.2)
	end
	fit()
	local function track(cam: Camera?)
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	end
	track(workspace.CurrentCamera)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		track(workspace.CurrentCamera)
		fit()
	end)
	local ctx: any = { frame = frame, zoom = zoom, binds = binds, refresh = nil }
	local kb: any = nil
	ctx.refresh = function()
		if not kb or not kb.Parent then return end
		for c in kb:GetChildren() do if c:IsA("TextLabel") then c:Destroy() end end
		local y = 0
		for _, e in binds do
			if e.key ~= "" then
				local l = Instance.new("TextLabel")
				l.Size = UDim2.new(1, 0, 0, ROW)
				l.BackgroundTransparency = 1
				l.Font, l.TextSize, l.TextColor3 = FONT, TS, TEXTPC
				l.TextXAlignment = Enum.TextXAlignment.Left
				l.Text = `{e.name}: [{e.key}] {e.mode}`
				l.Position = UDim2.new(0, 0, 0, y)
				l.Parent = kb
				y += ROW
			end
		end
	end
	local outer = Instance.new("UIStroke") -- ponytail: black outline outer, purple accent inner
	outer.Thickness, outer.Color = 2, OUTLINE
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
	logo.Font, logo.TextSize, logo.TextColor3, logo.Text = FONT, 15, TEXTPC, title
	logo.Parent = side
	local sheen = Instance.new("UIGradient") -- ponytail: slow sweep, delete grad + thread if distracting
		sheen.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, TEXTPC),
			ColorSequenceKeypoint.new(0.35, TEXTPC),
			ColorSequenceKeypoint.new(0.5, ACC),
			ColorSequenceKeypoint.new(0.65, TEXTPC),
			ColorSequenceKeypoint.new(1, TEXTPC),
		})
	sheen.Parent = logo
	task.spawn(function()
		local o, d = -1, 0.05
		while gui.Parent do
			sheen.Offset = Vector2.new(o, 0)
			o = o + d
			if o > 1 or o < -1 then d = -d end
			task.wait(0.05)
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
	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, 0, 1, 0)
	body.BackgroundTransparency = 1
	body.Parent = content

	UIS.InputBegan:Connect(function(i: InputObject, gpe: boolean)
		if gpe then return end
		if i.KeyCode == toggleKey then gui.Enabled = not gui.Enabled end
	end)
	UIS.InputBegan:Connect(function(i: InputObject, gpe: boolean)
		if gpe then return end
		if i.KeyCode == Enum.KeyCode.P then -- ponytail: kill switch; loops exit via gui.Parent, conns go dead
			gui:Destroy()
			getgenv().Menu = nil
		end
	end)

	-- keybind list panel (floating, draggable)
	local kbGui = Instance.new("ScreenGui")
	kbGui.Name = title .. "_kb"
	kbGui.ResetOnSpawn = false
	kbGui.DisplayOrder = 1000
	kbGui.Parent = root
	kb = Instance.new("TextButton")
	kb.Size = UDim2.fromOffset(200, 24)
	kb.Position = UDim2.new(1, -210, 1, -30)
	kb.BackgroundColor3, kb.BorderSizePixel = SIDEBG, 0
	kb.Font, kb.TextSize, kb.Text, kb.AutoButtonColor = FONT, TS, "Binds", false
	kb.TextColor3 = TEXTPC
	kb.Parent = kbGui
	local kbStroke = Instance.new("UIStroke")
	kbStroke.Thickness, kbStroke.Color = 1, OUTLINE
	kbStroke.Parent = kb
	local kbInner = Instance.new("Frame")
	kbInner.Size = UDim2.new(1, 0, 0, 0)
	kbInner.AutomaticSize = Enum.AutomaticSize.Y
	kbInner.BackgroundTransparency = 1
	kbInner.Parent = kb
	UIS.InputBegan:Connect(function(i: InputObject)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then kbDrag(i) end
	end)
	local kbDragging = false
	local kbStart = Vector2.new()
	local kbPos = Vector2.new()
	function kbDrag(i: InputObject)
		kbDragging = true
		kbStart = i.Position
		kbPos = kb.Position
	end
	UIS.InputEnded:Connect(function(i: InputObject)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then kbDragging = false end
	end)
	UIS.InputChanged:Connect(function(i: InputObject)
		if kbDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			kb.Position = Vector2.new(kbPos.X + (i.Position.X - kbStart.X), kbPos.Y + (i.Position.Y - kbStart.Y))
		end
	end)

	local self: any = {}
	local pages: { ScrollingFrame } = {}
	local navs: { TextButton } = {}
	local binds: { {name: string, key: string?, mode: string} } = {}
	local function select(idx: number)
		if ctx.close then ctx.close() end
		for i, p in pages do
			local on = i == idx
			p.Visible = on
			local nf: any = navs[i]:FindFirstChildOfClass("Frame")
			if nf then nf.Visible = on end
			navs[i].TextColor3 = if on then TEXTPC else TEXTDIM
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
		pg.ScrollingDirection = Enum.ScrollingDirection.Y -- ponytail: kills horizontal bar from col math
		pg.Visible = #pages == 0
		pg.Parent = body
		local qp = Instance.new("UIPadding")
		qp.PaddingLeft, qp.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)
		qp.Parent = pg
		table.insert(pages, pg)

		-- ponytail: conjoined scroll, canvas follows tallest column; split scroll if columns desync
		local cols = Instance.new("Frame")
		cols.Size = UDim2.new(1, 0, 0, 0)
		cols.AutomaticSize = Enum.AutomaticSize.Y
		cols.BackgroundTransparency = 1
		cols.Parent = pg
		list(cols, true)
		local function column(scale: number): Frame
			local c = Instance.new("Frame")
			c.Size = UDim2.new(scale, -4, 0, 0) -- ponytail: -4 slack so rounding never clips right col
			c.AutomaticSize = Enum.AutomaticSize.Y
			c.BackgroundTransparency = 1
			c.Parent = cols
			list(c, false)
			return c
		end
		local left, right = column(0.6), column(0.4)

		local nb = Instance.new("TextButton")
		nb.Size = UDim2.new(1, 0, 0, ROW)
		nb.BackgroundTransparency = 1
		nb.Font, nb.TextSize, nb.Text = FONT, TS, name
		nb.TextColor3, nb.TextXAlignment, nb.AutoButtonColor = TEXTDIM, Enum.TextXAlignment.Left, false
		nb.Parent = nav
		local edge = Instance.new("Frame") -- ponytail: left-edge mark, swap for bg block if noisy
		edge.Size = UDim2.new(0, 2, 1, 0)
		edge.BackgroundColor3, edge.BorderSizePixel, edge.Visible = ACC, 0, #pages == 1
		edge.Parent = nb
		table.insert(navs, nb)
		if #pages == 1 then navs[1].TextColor3 = TEXTPC end
		local idx = #pages
		nb.MouseButton1Click:Connect(function() select(idx) end)

		local ctl: any = controls(left, ctx)
		function ctl:Section(t: string, default: boolean, cb: (boolean) -> (), col: string?)
			local host = if col == "right" then right else left
			local on = default
			local wrap = Instance.new("Frame")
			wrap.Size = UDim2.new(1, 0, 0, 0)
			wrap.AutomaticSize = Enum.AutomaticSize.Y
			wrap.BackgroundColor3, wrap.BorderSizePixel = SECT, 0
			wrap.Parent = host
			list(wrap, false)
			local qp2 = Instance.new("UIPadding")
			qp2.PaddingTop, qp2.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
			qp2.Parent = wrap
			local head = Instance.new("TextButton")
			head.Size = UDim2.new(1, 0, 0, ROW)
			head.BackgroundTransparency = 1
			head.Font, head.TextSize, head.TextColor3 = FONT, TS, TEXTPC
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
			return controls(innerHost, ctx)
		end
		return ctl
	end
	function self.Destroy() gui:Destroy() end
	return self
end

getgenv().Menu = Menu -- ponytail: run ui-lib first, demo picks it up, no file IO needed

return Menu
