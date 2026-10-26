--[[
	AdminClient  (LocalScript)
	Coloque em: StarterPlayer > StarterPlayerScripts
	Constrói toda a interface por código. O botão "Ser ADM" só aparece para admins.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("AdminRemote")
local announceEvent = ReplicatedStorage:WaitForChild("AdminAnnounce")

----------------------------------------------------------------------
-- TEMA / HELPERS
----------------------------------------------------------------------
local C = {
	bg = Color3.fromRGB(14, 17, 30),
	panel = Color3.fromRGB(22, 26, 44),
	item = Color3.fromRGB(32, 38, 62),
	accent = Color3.fromRGB(64, 140, 255),
	accent2 = Color3.fromRGB(120, 90, 255),
	green = Color3.fromRGB(60, 200, 120),
	red = Color3.fromRGB(235, 70, 90),
	orange = Color3.fromRGB(255, 170, 60),
	text = Color3.fromRGB(235, 240, 255),
	sub = Color3.fromRGB(150, 160, 190),
	white = Color3.new(1, 1, 1),
}
local FONT = Enum.Font.GothamMedium
local FONT_B = Enum.Font.GothamBold

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function round(inst, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, inst)
end

local function stroke(inst, color, thickness, transparency)
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, inst)
end

local function tween(inst, t, props)
	TweenService:Create(inst, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local orderCounter = 0
local function nextOrder()
	orderCounter += 1
	return orderCounter
end

local function hover(btn, normal, over)
	btn.MouseEnter:Connect(function()
		tween(btn, 0.12, { BackgroundColor3 = over })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.12, { BackgroundColor3 = normal })
	end)
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

----------------------------------------------------------------------
-- EFEITO DA BOLHA (roda para TODOS os jogadores, visual local e suave)
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local fx = char and char:FindFirstChild("GodFX")
		if fx then
			for _, part in ipairs(fx:GetChildren()) do
				if part:GetAttribute("Pulse") then
					part.Transparency = 0.35 + math.sin(t * 3) * 0.1
				end
				local speed = part:GetAttribute("Speed")
				if speed then
					local motor = part:FindFirstChild("FXJoint")
					if motor then
						local phase = part:GetAttribute("Phase") or 0
						local tilt = part:GetAttribute("Tilt") or 0
						motor.Transform = CFrame.Angles(0, t * speed + phase, 0) * CFrame.Angles(0, 0, tilt)
					end
				end
			end
		end
	end
end)

----------------------------------------------------------------------
-- ANÚNCIOS (todos os jogadores veem)
----------------------------------------------------------------------
do
	local announceGui = new("ScreenGui", {
		Name = "AdminAnnounceGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 300,
	}, playerGui)

	local banner = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -100),
		Size = UDim2.new(0.9, 0, 0, 68),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
	}, announceGui)
	new("UISizeConstraint", { MaxSize = Vector2.new(480, 100) }, banner)
	round(banner, 14)
	stroke(banner, C.accent, 2, 0.2)

	local title = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 18),
		Text = "📢 Anúncio",
		Font = FONT_B,
		TextSize = 13,
		TextColor3 = C.accent,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, banner)

	local body = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 28),
		Size = UDim2.new(1, -28, 0, 32),
		Text = "",
		Font = FONT_B,
		TextSize = 16,
		TextColor3 = C.text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, banner)

	local token = 0
	announceEvent.OnClientEvent:Connect(function(text, who)
		token += 1
		local mine = token
		title.Text = "📢 Anúncio de " .. tostring(who)
		body.Text = tostring(text)
		TweenService:Create(
			banner,
			TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, 0, 0, 20) }
		):Play()
		task.delay(5.5, function()
			if token == mine then
				tween(banner, 0.35, { Position = UDim2.new(0.5, 0, 0, -100) })
			end
		end)
	end)
end

----------------------------------------------------------------------
-- VERIFICA SE É ADMIN (se não for, o resto nem é criado)
----------------------------------------------------------------------
local okCall, adminResult = pcall(function()
	return remote:InvokeServer("Check")
end)
if not okCall or adminResult ~= true then
	return
end

----------------------------------------------------------------------
-- GUIs BASE
----------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "AdminPanelGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toastGui = new("ScreenGui", {
	Name = "AdminToasts",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 400,
}, playerGui)

local toastHolder = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 16),
	Size = UDim2.fromOffset(320, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
}, toastGui)
new("UIListLayout", {
	Padding = UDim.new(0, 6),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, toastHolder)

local function toast(text, color)
	local t = new("TextLabel", {
		Size = UDim2.fromOffset(300, 34),
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 1,
		Text = text,
		Font = FONT_B,
		TextSize = 13,
		TextColor3 = C.text,
		TextTransparency = 1,
		LayoutOrder = nextOrder(),
	}, toastHolder)
	round(t, 10)
	local st = stroke(t, color or C.accent, 1.5, 1)
	tween(t, 0.2, { BackgroundTransparency = 0.05, TextTransparency = 0 })
	tween(st, 0.2, { Transparency = 0 })
	task.delay(2.4, function()
		tween(t, 0.25, { BackgroundTransparency = 1, TextTransparency = 1 })
		tween(st, 0.25, { Transparency = 1 })
		task.delay(0.3, function()
			t:Destroy()
		end)
	end)
end

-- Envia ação ao servidor e mostra o resultado
local function act(action, ...)
	local ok, success, msg = pcall(remote.InvokeServer, remote, action, ...)
	if not ok then
		toast("Erro de comunicação com o servidor", C.red)
		return false
	end
	if msg then
		toast(msg, success and C.green or C.red)
	end
	return success == true
end

----------------------------------------------------------------------
-- FUNÇÕES LOCAIS: FLY / NOCLIP / PULO INFINITO
----------------------------------------------------------------------
local function getChar()
	local c = player.Character
	return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local upHeld, downHeld = false, false

-- botões ▲ ▼ para celular
local flyPad = new("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -120),
	Size = UDim2.fromOffset(60, 128),
	BackgroundTransparency = 1,
	Visible = false,
}, gui)

local function padButton(text, y, setter)
	local b = new("TextButton", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(60, 60),
		BackgroundColor3 = C.accent,
		BackgroundTransparency = 0.25,
		Text = text,
		Font = FONT_B,
		TextSize = 24,
		TextColor3 = C.white,
		AutoButtonColor = false,
	}, flyPad)
	round(b, 30)
	b.InputBegan:Connect(function(i)
		if isPointer(i) then
			setter(true)
		end
	end)
	b.InputEnded:Connect(function(i)
		if isPointer(i) then
			setter(false)
		end
	end)
end
padButton("▲", 0, function(v)
	upHeld = v
end)
padButton("▼", 68, function(v)
	downHeld = v
end)

local flyEnabled = false
local flySpeed = 60
local flyObjs = {}
local flyConn

local function stopFly()
	flyEnabled = false
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end
	for _, o in ipairs(flyObjs) do
		o:Destroy()
	end
	flyObjs = {}
	upHeld, downHeld = false, false
	flyPad.Visible = false
	local _, hum = getChar()
	if hum then
		hum.PlatformStand = false
	end
end

local function startFly()
	stopFly()
	local _, hum, root = getChar()
	if not hum or not root then
		return false
	end
	flyEnabled = true

	local att = Instance.new("Attachment")
	att.Name = "FlyAtt"
	att.Parent = root

	local lv = Instance.new("LinearVelocity")
	lv.Name = "FlyVel"
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = Vector3.zero
	lv.Parent = root

	local ao = Instance.new("AlignOrientation")
	ao.Name = "FlyAlign"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = math.huge
	ao.Responsiveness = 25
	ao.CFrame = root.CFrame
	ao.Parent = root

	flyObjs = { att, lv, ao }
	hum.PlatformStand = true
	flyPad.Visible = UserInputService.TouchEnabled

	flyConn = RunService.Heartbeat:Connect(function()
		if not root.Parent or not hum.Parent then
			stopFly()
			return
		end

		local cam = workspace.CurrentCamera
		local look = cam.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		local md = hum.MoveDirection
		local vel = Vector3.zero

		if flat.Magnitude > 0.01 then
			flat = flat.Unit
			local right = Vector3.new(-flat.Z, 0, flat.X)
			vel += (look * md:Dot(flat) + cam.CFrame.RightVector * md:Dot(right)) * flySpeed
			ao.CFrame = CFrame.lookAt(Vector3.zero, flat)
		end

		local typing = UserInputService:GetFocusedTextBox() ~= nil
		if upHeld or (not typing and UserInputService:IsKeyDown(Enum.KeyCode.Space)) then
			vel += Vector3.yAxis * flySpeed
		end
		if
			downHeld
			or (
				not typing
				and (
					UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
					or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				)
			)
		then
			vel -= Vector3.yAxis * flySpeed
		end

		lv.VectorVelocity = vel
	end)
	return true
end

local noclipConn
local function setNoclip(on)
	if noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
	end
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			local char = player.Character
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") and p.CanCollide then
						p.CanCollide = false
					end
				end
			end
		end)
	end
	return true
end

local infJump = false
UserInputService.JumpRequest:Connect(function()
	if infJump then
		local _, hum = getChar()
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

----------------------------------------------------------------------
-- PAINEL
----------------------------------------------------------------------
local vp = workspace.CurrentCamera.ViewportSize
local W = math.min(390, vp.X - 20)
local H = math.min(520, vp.Y - 30)

local panel = new("CanvasGroup", {
	Name = "Panel",
	Size = UDim2.fromOffset(W, H),
	Position = UDim2.fromOffset(math.floor((vp.X - W) / 2), math.floor((vp.Y - H) / 2)),
	BackgroundColor3 = C.bg,
	BorderSizePixel = 0,
	GroupTransparency = 1,
	Visible = false,
}, gui)
round(panel, 14)
stroke(panel, C.accent, 1.5, 0.4)
local popScale = new("UIScale", { Scale = 0.9 }, panel)

-- Cabeçalho (arraste por aqui)
local header = new("Frame", {
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundColor3 = C.accent,
	BorderSizePixel = 0,
}, panel)
new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, header)
new("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(14, 0),
	Size = UDim2.new(1, -100, 1, 0),
	Text = "👑 Painel ADM",
	Font = FONT_B,
	TextSize = 17,
	TextColor3 = C.white,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local function headerButton(text, x)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, x, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.8,
		Text = text,
		Font = FONT_B,
		TextSize = 16,
		TextColor3 = C.white,
		AutoButtonColor = false,
	}, header)
	round(b, 8)
	b.MouseEnter:Connect(function()
		tween(b, 0.12, { BackgroundTransparency = 0.55 })
	end)
	b.MouseLeave:Connect(function()
		tween(b, 0.12, { BackgroundTransparency = 0.8 })
	end)
	return b
end
local minBtn = headerButton("—", -46)
local closeBtn = headerButton("✕", -12)

-- Arrastar
local function makeDraggable(handle, target)
	local dragging, dragStart, startPos = false, nil, nil
	handle.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local d = input.Position - dragStart
			local v = workspace.CurrentCamera.ViewportSize
			local size = target.AbsoluteSize
			local x = math.clamp(startPos.X.Offset + d.X, 0, math.max(0, v.X - size.X))
			local y = math.clamp(startPos.Y.Offset + d.Y, 0, math.max(0, v.Y - 44))
			target.Position = UDim2.fromOffset(x, y)
		end
	end)
end
makeDraggable(header, panel)

-- Corpo (esconde ao minimizar)
local body = new("Frame", {
	Position = UDim2.fromOffset(0, 44),
	Size = UDim2.new(1, 0, 1, -44),
	BackgroundTransparency = 1,
}, panel)

local tabBar = new("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = C.panel,
	BorderSizePixel = 0,
}, body)

local pagesHolder = new("Frame", {
	Position = UDim2.fromOffset(0, 40),
	Size = UDim2.new(1, 0, 1, -40),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, body)

local pages, tabButtons = {}, {}
local indicator = new("Frame", {
	Position = UDim2.new(0, 6, 1, -3),
	Size = UDim2.new(1 / 3, -12, 0, 3),
	BackgroundColor3 = C.accent,
	BorderSizePixel = 0,
}, tabBar)
round(indicator, 2)

local function selectTab(i)
	for idx, pg in ipairs(pages) do
		pg.Visible = (idx == i)
		tabButtons[idx].TextColor3 = (idx == i) and C.text or C.sub
	end
	tween(indicator, 0.2, { Position = UDim2.new((i - 1) / 3, 6, 1, -3) })
	local pg = pages[i]
	pg.Position = UDim2.fromOffset(0, 12)
	tween(pg, 0.2, { Position = UDim2.fromOffset(0, 0) })
end

local function newPage(tabName)
	local idx = #pages + 1
	local btn = new("TextButton", {
		Position = UDim2.new((idx - 1) / 3, 0, 0, 0),
		Size = UDim2.new(1 / 3, 0, 1, -3),
		BackgroundTransparency = 1,
		Text = tabName,
		Font = FONT_B,
		TextSize = 14,
		TextColor3 = C.sub,
	}, tabBar)
	btn.Activated:Connect(function()
		selectTab(idx)
	end)
	table.insert(tabButtons, btn)

	local sf = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Visible = false,
	}, pagesHolder)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 12),
	}, sf)
	table.insert(pages, sf)
	return sf
end

----------------------------------------------------------------------
-- COMPONENTES
----------------------------------------------------------------------
local function sectionLabel(parent, text)
	return new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = string.upper(text),
		Font = FONT_B,
		TextSize = 11,
		TextColor3 = C.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = nextOrder(),
	}, parent)
end

local function rowFrame(parent, title, desc, rightReserve)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = C.item,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
	}, parent)
	round(row, 10)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 7),
		Size = UDim2.new(1, -rightReserve, 0, 18),
		Text = title,
		Font = FONT_B,
		TextSize = 14,
		TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 27),
		Size = UDim2.new(1, -rightReserve, 0, 16),
		Text = desc,
		Font = FONT,
		TextSize = 11,
		TextColor3 = C.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	return row
end

local function toggleRow(parent, title, desc, onChange)
	local row = rowFrame(parent, title, desc, 84)
	local sw = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(46, 24),
		BackgroundColor3 = C.bg,
		Text = "",
		AutoButtonColor = false,
	}, row)
	round(sw, 12)
	local knob = new("Frame", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = C.sub,
		BorderSizePixel = 0,
	}, sw)
	round(knob, 9)

	local on = false
	local function render()
		tween(knob, 0.15, {
			Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
			BackgroundColor3 = on and C.white or C.sub,
		})
		tween(sw, 0.15, { BackgroundColor3 = on and C.accent or C.bg })
	end

	sw.Activated:Connect(function()
		local want = not on
		if onChange(want) ~= false then
			on = want
			render()
		end
	end)

	return {
		Set = function(v)
			on = v
			render()
		end,
	}
end

local function stepperRow(parent, title, desc, min, max, step, initial, onChange)
	local row = rowFrame(parent, title, desc, 134)
	local value = initial

	local function mk(text, x)
		local b = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, x, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = C.accent,
			Text = text,
			Font = FONT_B,
			TextSize = 18,
			TextColor3 = C.white,
			AutoButtonColor = false,
		}, row)
		round(b, 8)
		hover(b, C.accent, C.accent2)
		return b
	end

	local plus = mk("+", -12)
	local valLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -46, 0.5, 0),
		Size = UDim2.fromOffset(44, 30),
		BackgroundTransparency = 1,
		Text = tostring(initial),
		Font = FONT_B,
		TextSize = 15,
		TextColor3 = C.text,
	}, row)
	local minus = mk("−", -94)

	local function change(delta)
		local v = math.clamp(value + delta, min, max)
		if v == value then
			return
		end
		if onChange(v) ~= false then
			value = v
			valLabel.Text = tostring(v)
		end
	end
	plus.Activated:Connect(function()
		change(step)
	end)
	minus.Activated:Connect(function()
		change(-step)
	end)

	return {
		Set = function(v)
			value = v
			valLabel.Text = tostring(v)
		end,
	}
end

local function buttonRow(parent, text, color, onClick, height)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, height or 38),
		BackgroundColor3 = color,
		Text = text,
		Font = FONT_B,
		TextSize = 14,
		TextColor3 = C.white,
		AutoButtonColor = false,
		LayoutOrder = nextOrder(),
	}, parent)
	round(b, 10)
	hover(b, color, color:Lerp(C.white, 0.15))
	b.Activated:Connect(onClick)
	return b
end

----------------------------------------------------------------------
-- ABA 1: PRINCIPAL
----------------------------------------------------------------------
local pageMain = newPage("Principal")

local _, hum0 = getChar()
if not hum0 then
	player.CharacterAdded:Wait()
	_, hum0 = getChar()
end
local defaultWalk = hum0 and hum0.WalkSpeed or 16
local defaultJump = hum0 and hum0.JumpPower or 50

sectionLabel(pageMain, "Movimento")

local flyToggle = toggleRow(pageMain, "✈️ Fly", "Voe pelo mapa (Espaço sobe, Ctrl/Shift desce)", function(on)
	if on then
		return startFly()
	end
	stopFly()
	return true
end)

stepperRow(pageMain, "💨 Velocidade do Fly", "Quão rápido você voa", 10, 200, 10, flySpeed, function(v)
	flySpeed = v
	return true
end)

local speedStepper = stepperRow(pageMain, "🏃 Velocidade", "Velocidade de andar", 8, 120, 8, math.floor(defaultWalk), function(v)
	return act("Speed", v)
end)

local jumpStepper = stepperRow(pageMain, "🦘 Pulo", "Força do pulo", 25, 200, 25, math.floor(defaultJump), function(v)
	return act("Jump", v)
end)

toggleRow(pageMain, "👻 Noclip", "Atravesse paredes", function(on)
	return setNoclip(on)
end)

toggleRow(pageMain, "⬆️ Pulo infinito", "Pule no ar quantas vezes quiser", function(on)
	infJump = on
	return true
end)

sectionLabel(pageMain, "Proteção")

toggleRow(pageMain, "🛡️ Modo God", "Bolha azul que impede de te pegarem", function(on)
	return act("God", on)
end)

buttonRow(pageMain, "↺ Resetar velocidade e pulo", C.orange, function()
	local a = act("Speed", math.floor(defaultWalk))
	local b = act("Jump", math.floor(defaultJump))
	if a then
		speedStepper.Set(math.floor(defaultWalk))
	end
	if b then
		jumpStepper.Set(math.floor(defaultJump))
	end
end)

----------------------------------------------------------------------
-- ABA 2: JOGADORES
----------------------------------------------------------------------
local pagePlayers = newPage("Jogadores")

local selectedUserId, selectedName = nil, nil

local search = new("TextBox", {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = C.item,
	PlaceholderText = "🔍 Buscar jogador...",
	PlaceholderColor3 = C.sub,
	Text = "",
	ClearTextOnFocus = false,
	Font = FONT,
	TextSize = 13,
	TextColor3 = C.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = nextOrder(),
}, pagePlayers)
round(search, 10)
new("UIPadding", { PaddingLeft = UDim.new(0, 12) }, search)

local list = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 170),
	BackgroundColor3 = C.item,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = C.accent,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	LayoutOrder = nextOrder(),
}, pagePlayers)
round(list, 10)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name }, list)
new("UIPadding", {
	PaddingTop = UDim.new(0, 6),
	PaddingBottom = UDim.new(0, 6),
	PaddingLeft = UDim.new(0, 6),
	PaddingRight = UDim.new(0, 6),
}, list)

local selLabel = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	Text = "Selecionado: nenhum",
	Font = FONT_B,
	TextSize = 13,
	TextColor3 = C.accent,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = nextOrder(),
}, pagePlayers)

local countLabel -- definido na aba Servidor

local function refreshPlayers()
	for _, ch in ipairs(list:GetChildren()) do
		if ch:IsA("TextButton") then
			ch:Destroy()
		end
	end

	local q = string.lower(search.Text)
	local total = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		total += 1
		local dn, un = plr.DisplayName, plr.Name
		if q == "" or string.find(string.lower(dn), q, 1, true) or string.find(string.lower(un), q, 1, true) then
			local selected = (plr.UserId == selectedUserId)
			local row = new("TextButton", {
				Name = string.lower(dn),
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = selected and C.accent or C.panel,
				AutoButtonColor = false,
				Text = "",
			}, list)
			round(row, 8)
			local av = new("ImageLabel", {
				BackgroundColor3 = C.bg,
				Position = UDim2.fromOffset(5, 5),
				Size = UDim2.fromOffset(30, 30),
				Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60"):format(plr.UserId),
			}, row)
			round(av, 15)
			new("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(43, 3),
				Size = UDim2.new(1, -50, 0, 18),
				Text = dn .. (plr == player and "  (você)" or ""),
				Font = FONT_B,
				TextSize = 13,
				TextColor3 = C.text,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, row)
			new("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(43, 20),
				Size = UDim2.new(1, -50, 0, 16),
				Text = "@" .. un,
				Font = FONT,
				TextSize = 11,
				TextColor3 = selected and C.white or C.sub,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, row)
			row.Activated:Connect(function()
				selectedUserId = plr.UserId
				selectedName = dn
				selLabel.Text = "Selecionado: " .. dn
				refreshPlayers()
			end)
		end
	end

	if not selectedUserId then
		selLabel.Text = "Selecionado: nenhum"
	end
	if countLabel then
		countLabel.Text = ("Jogadores no servidor: %d"):format(total)
	end
end

search:GetPropertyChangedSignal("Text"):Connect(refreshPlayers)
Players.PlayerAdded:Connect(function()
	task.delay(0.2, refreshPlayers)
end)
Players.PlayerRemoving:Connect(function(p)
	if p.UserId == selectedUserId then
		selectedUserId, selectedName = nil, nil
	end
	task.delay(0.2, refreshPlayers)
end)

local function needSelection()
	if not selectedUserId then
		toast("Selecione um jogador primeiro", C.orange)
		return false
	end
	return true
end

local grid = new("Frame", {
	Size = UDim2.new(1, 0, 0, 120),
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(),
}, pagePlayers)
new("UIGridLayout", {
	CellSize = UDim2.new(0.5, -4, 0, 36),
	CellPadding = UDim2.fromOffset(8, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, grid)

buttonRow(grid, "🧲 Trazer até mim", C.accent, function()
	if needSelection() then
		act("Bring", selectedUserId)
	end
end)
buttonRow(grid, "➡️ Ir até ele", C.accent2, function()
	if needSelection() then
		act("GoTo", selectedUserId)
	end
end)
buttonRow(grid, "❄️ Congelar", Color3.fromRGB(60, 170, 220), function()
	if needSelection() then
		act("Freeze", selectedUserId)
	end
end)
buttonRow(grid, "💚 Curar", C.green, function()
	if needSelection() then
		act("Heal", selectedUserId)
	end
end)
buttonRow(grid, "🔄 Reiniciar", C.orange, function()
	if needSelection() then
		act("Respawn", selectedUserId)
	end
end)

local kickArmed = false
local kickBtn
kickBtn = buttonRow(grid, "🚪 Expulsar", C.red, function()
	if not needSelection() then
		return
	end
	if not kickArmed then
		kickArmed = true
		kickBtn.Text = "⚠️ Confirmar?"
		task.delay(3, function()
			kickArmed = false
			kickBtn.Text = "🚪 Expulsar"
		end)
	else
		kickArmed = false
		kickBtn.Text = "🚪 Expulsar"
		act("Kick", selectedUserId)
	end
end)

----------------------------------------------------------------------
-- ABA 3: SERVIDOR
----------------------------------------------------------------------
local pageServer = newPage("Servidor")

sectionLabel(pageServer, "Anúncio para todos")

local announceBox = new("TextBox", {
	Size = UDim2.new(1, 0, 0, 56),
	BackgroundColor3 = C.item,
	PlaceholderText = "Digite a mensagem (máx. 120 caracteres)...",
	PlaceholderColor3 = C.sub,
	Text = "",
	ClearTextOnFocus = false,
	MultiLine = true,
	TextWrapped = true,
	Font = FONT,
	TextSize = 13,
	TextColor3 = C.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	LayoutOrder = nextOrder(),
}, pageServer)
round(announceBox, 10)
new("UIPadding", {
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
	PaddingTop = UDim.new(0, 8),
}, announceBox)

buttonRow(pageServer, "📢 Enviar anúncio", C.accent, function()
	if act("Announce", announceBox.Text) then
		announceBox.Text = ""
	end
end)

sectionLabel(pageServer, "Ações em massa")

buttonRow(pageServer, "🧲 Trazer todos até mim", C.accent2, function()
	act("BringAll")
end)
buttonRow(pageServer, "💚 Curar todos", C.green, function()
	act("HealAll")
end)

sectionLabel(pageServer, "Informações")
countLabel = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundTransparency = 1,
	Text = "Jogadores no servidor: 0",
	Font = FONT_B,
	TextSize = 13,
	TextColor3 = C.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = nextOrder(),
}, pageServer)

refreshPlayers()
selectTab(1)

----------------------------------------------------------------------
-- ABRIR / FECHAR / MINIMIZAR
----------------------------------------------------------------------
local panelOpen, minimized = false, false

local function openPanel()
	panelOpen = true
	panel.Visible = true
	tween(panel, 0.25, { GroupTransparency = 0 })
	TweenService:Create(popScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local function closePanel()
	panelOpen = false
	tween(panel, 0.2, { GroupTransparency = 1 })
	tween(popScale, 0.2, { Scale = 0.9 })
	task.delay(0.22, function()
		if not panelOpen then
			panel.Visible = false
		end
	end)
end

local function setMinimized(v)
	minimized = v
	if v then
		minBtn.Text = "▢"
		tween(panel, 0.2, { Size = UDim2.fromOffset(W, 44) })
		task.delay(0.2, function()
			if minimized then
				body.Visible = false
			end
		end)
	else
		minBtn.Text = "—"
		body.Visible = true
		tween(panel, 0.2, { Size = UDim2.fromOffset(W, H) })
	end
end

minBtn.Activated:Connect(function()
	setMinimized(not minimized)
end)
closeBtn.Activated:Connect(closePanel)

----------------------------------------------------------------------
-- BOTÃO "SER ADM" (abre o painel; depois vira "Painel" para reabrir)
----------------------------------------------------------------------
local launcher = new("TextButton", {
	Name = "Launcher",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.fromOffset(124, 42),
	BackgroundColor3 = C.white,
	Text = "👑 Ser ADM",
	Font = FONT_B,
	TextSize = 15,
	TextColor3 = C.white,
	AutoButtonColor = false,
}, gui)
round(launcher, 21)
new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, launcher)
local launcherStroke = stroke(launcher, C.white, 2, 0.4)
TweenService:Create(
	launcherStroke,
	TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Transparency = 0.9 }
):Play()

local activated = false
launcher.Activated:Connect(function()
	if not activated then
		if act("Check") then
			activated = true
			launcher.Text = "👑 Painel"
			toast("Modo ADM ativado!", C.green)
			openPanel()
		end
	else
		if panelOpen then
			closePanel()
		else
			openPanel()
		end
	end
end)

-- Ao renascer: o fly é desligado (os outros estados o servidor reaplica)
player.CharacterAdded:Connect(function()
	stopFly()
	flyToggle.Set(false)
end)
