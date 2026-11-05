-- AWM + BFG 50 + Intervention + Desert Eagle + Barrett M82 | client-sided, self-building
-- Controls: Tap/Click = fire | Right-click or SCOPE = scope | R or RELOAD = reload | SWITCH / Q = swap gun
-- In first person the gun floats in front of you.

local SHOOT_SOUND  = "rbxassetid://137912977024524" -- AWP shot (fallback)
local RELOAD_SOUND = "rbxassetid://3666864180"      -- fallback
local BOLT_SOUND   = "rbxassetid://72961504591646" -- bolt pull (used by every bolt-action sniper)
local ZOOM_SOUND   = "rbxassetid://94183265621202"
local RETICLE_IMAGE = "rbxassetid://131085775271933"
local HOLD_ANIM   = "rbxassetid://277780478"
local RELOAD_ANIM = "rbxassetid://94332664"
local AIM_ANIM    = nil -- optional: e.g. "rbxassetid://123456" for a third-person aim pose

local CFG = {
	ForceFirstPerson = true,  -- gun floats in front of you
	Flip        = true,       -- AWM model direction (flip this if it points backwards)
	Up          = 0.6,        -- third person: studs the gun sits higher than the hand
	Forward     = 0.75,       -- third person: studs the gun sits forward
	GripOffset  = CFrame.new(0, 0, 0),
	Range       = 3000,
	StartWar    = true,   -- two NPC teams spawn and fight
	NpcPerTeam  = 4,
	NpcDistance = 55,     -- studs from you to each team
	NpcHostileToPlayer = false, -- true = NPCs shoot you too
	NpcDamage   = 34,     -- damage per NPC bullet (3 hits to kill)
	Pvp         = true,   -- other players running this script can shoot each other
	PvpDamage   = { sniper = 100, pistol = 55, auto = 20 }, -- damage per hit by gun type
	PvpHitRadius = 3.5,   -- studs: how close a shot has to pass to count as a hit
	PvpAutoDelay = 0.07,  -- seconds between observed shots from automatic guns
	NpcAccuracy = 0.75,   -- chance an NPC bullet hits its target when it has line of sight
}

local GUNS = {
	{
		name = "AWM", modelId = 8187212887, bolt = true, boltTime = 0.9,
		mag = 5, delay = 1.4, reloadTime = 1.6, scopeFOV = 10,
		pitch = 1, volume = 1.2, kick = 1.5, damage = 100,
		tracerColor = Color3.fromRGB(255, 220, 120), tracerWidth = 0.08,
		autoOrient = true,
		vmOffset = Vector3.new(0.95, -0.85, -2.5), muzzleZ = 2.4,
		aimOffset = Vector3.new(0, -0.3, -2.1),
		rHand = Vector3.new(0.05, -0.55, 0.6), lHand = Vector3.new(0, -0.45, -1.1),
	},
	{
		name = "BFG 50", modelId = 1009656448, bolt = true, boltTime = 1.1,
		mag = 5, delay = 1.7, reloadTime = 1.8, scopeFOV = 8,
		pitch = 0.7, volume = 1.8, kick = 3, damage = 150,
		tracerColor = Color3.fromRGB(255, 140, 40), tracerWidth = 0.16,
		autoOrient = true,
		-- raised + moved further forward
		vmOffset = Vector3.new(1.0, -0.72, -3.15),
		muzzleZ = 3.4,
		aimOffset = Vector3.new(0, -0.22, -2.95),
		rHand = Vector3.new(0.05, -0.7, 0.8), lHand = Vector3.new(0, -0.55, -1.4),
	},
	{
		name = "Barrett M82", modelId = 112371235175181, bolt = true, boltTime = 1.0,
		mag = 10, delay = 0.85, reloadTime = 2.4, scopeFOV = 9,
		pitch = 1, volume = 1.8, kick = 3, damage = 140,
		tracerColor = Color3.fromRGB(255, 200, 90), tracerWidth = 0.14,
		autoOrient = true,
		-- flipped because the M82 model loaded backwards (set to false to undo)
		flipModel = true,
		scale = 1.4,        -- make bigger (raise or lower this)
		shootSound = "rbxassetid://9069987808",
		reloadSound = "rbxassetid://3742339344",
		vmOffset = Vector3.new(1.0, -1.05, -3.5),
		muzzleZ = 4.3,
		aimOffset = Vector3.new(0, -0.45, -3.2),
		rHand = Vector3.new(0.05, -0.6, 0.7), lHand = Vector3.new(0, -0.5, -1.3),
	},
	{
		name = "Intervention", modelId = 597863807, bolt = true, boltTime = 0.9,
		mag = 5, delay = 1.6, reloadTime = 1.7, scopeFOV = 9,
		pitch = 0.95, volume = 1.5, kick = 2.4, damage = 120,
		tracerColor = Color3.fromRGB(255, 230, 150), tracerWidth = 0.1,
		autoOrient = true,
		flipModel = true,   -- fix backwards orientation
		shootSound = "rbxassetid://88919690594892",
		boltSound = "rbxassetid://72961504591646",
		reloadSound = "rbxassetid://4797747728",
		vmOffset = Vector3.new(0.95, -0.8, -2.7),
		muzzleZ = 2.6,
		aimOffset = Vector3.new(0, -0.28, -2.3),
		rHand = Vector3.new(0.05, -0.55, 0.6), lHand = Vector3.new(0, -0.45, -1.1),
	},
	{
		name = "Desert Eagle", modelId = 12703122297,
		mag = 7, delay = 0.35, reloadTime = 1.2, scopeFOV = 55, -- mild zoom only
		pitch = 1.05, volume = 1.6, kick = 2.2, damage = 55,
		tracerColor = Color3.fromRGB(255, 210, 90), tracerWidth = 0.07,
		autoOrient = true,
		flipModel = true,   -- fix backwards orientation
		scale = 0.62,       -- make smaller
		useScopeOverlay = false, -- keep gun visible, no black scope ring
		shootSound = "rbxassetid://71313174881521",
		reloadSound = "rbxassetid://8818002548",
		-- hip position
		vmOffset = Vector3.new(0.68, -0.85, -1.55),
		muzzleZ = 0.95,
		-- ADS: gun sits right in front of face with iron sights (lowered ~3x)
		aimOffset = Vector3.new(0.0, -0.38, -0.95),
		-- two-handed pistol grip: right hand on the grip, left hand cupped under/in front of it
		rHand = Vector3.new(0.05, -0.32, 0.22),
		lHand = Vector3.new(-0.1, -0.36, 0.02),
	},
	{
		name = "P90", modelId = 12723125531,
		auto = true,          -- hold to keep firing
		mag = 50, delay = 0.067, reloadTime = 2.0, scopeFOV = 55, -- ~900 RPM
		pitch = 1, volume = 1.2, kick = 0.5, damage = 20,
		tracerColor = Color3.fromRGB(255, 220, 120), tracerWidth = 0.05,
		autoOrient = true,
		flipModel = true,  -- P90 loaded backwards
		-- scale = 1.2,       -- uncomment to resize
		useScopeOverlay = false, -- aim down the sights without the black sniper ring
		shootSound = "rbxassetid://801170812",
		reloadSound = "rbxassetid://801171060",
		vmOffset = Vector3.new(0.8, -0.75, -2.0),
		muzzleZ = 1.6,
		aimOffset = Vector3.new(0, -0.35, -1.5),
		rHand = Vector3.new(0.05, -0.45, 0.35), lHand = Vector3.new(0, -0.4, -0.6),
	},
}

-- cleanup of an older run
if _G.SteyrScoutCleanup then pcall(_G.SteyrScoutCleanup) end

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local RS           = game:GetService("RunService")
local TS           = game:GetService("TweenService")
local Debris       = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local lp   = Players.LocalPlayer
local cam  = workspace.CurrentCamera
local pgui = lp:WaitForChild("PlayerGui")

local conns, extras = {}, {}
local running = true
local function connect(sig, fn)
	local c = sig:Connect(fn)
	table.insert(conns, c)
	return c
end

local function getHum()
	local c = lp.Character
	return c and c:FindFirstChildOfClass("Humanoid"), c
end

----------------------------------------------------------------
-- BUILD GUNS
----------------------------------------------------------------
local function loadModelParts(id)
	local ok, objs = pcall(function()
		return game:GetObjects("rbxassetid://" .. id)
	end)
	if not ok or not objs or not objs[1] then
		warn("[Gun] Could not load model " .. tostring(id))
		return nil
	end
	local src = objs[1]
	local all = src:GetDescendants()
	table.insert(all, src)
	local parts = {}
	for _, d in ipairs(all) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	if #parts == 0 then return nil end
	local main, best = parts[1], 0
	for _, p in ipairs(parts) do
		local v = p.Size.X * p.Size.Y * p.Size.Z
		if v > best then best, main = v, p end
	end
	return parts, main, src
end

local function buildBFGParts()
	local parts = {}
	local dark  = Color3.fromRGB(35, 35, 40)
	local olive = Color3.fromRGB(70, 80, 60)
	local function add(name, size, offset, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(offset)
		p.Color = color
		p.Material = Enum.Material.Metal
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		table.insert(parts, p)
		return p
	end
	-- barrel points down -Z
	local main = add("Receiver", Vector3.new(0.4, 0.6, 1.8), Vector3.new(0, 0, 0), olive)
	add("Barrel",   Vector3.new(0.22, 0.22, 2.0), Vector3.new(0, 0.1, -1.9), dark)
	add("Brake",    Vector3.new(0.42, 0.42, 0.5), Vector3.new(0, 0.1, -3.15), dark)
	add("Stock",    Vector3.new(0.35, 0.7, 1.2),  Vector3.new(0, -0.05, 1.5), olive)
	add("Pad",      Vector3.new(0.4, 0.8, 0.2),   Vector3.new(0, -0.05, 2.2), dark)
	add("Scope",    Vector3.new(0.3, 0.3, 1.3),   Vector3.new(0, 0.55, -0.1), dark)
	add("ScopeMt1", Vector3.new(0.12, 0.25, 0.12), Vector3.new(0, 0.38, -0.5), dark)
	add("ScopeMt2", Vector3.new(0.12, 0.25, 0.12), Vector3.new(0, 0.38, 0.3), dark)
	add("Mag",      Vector3.new(0.35, 0.7, 0.5),  Vector3.new(0, -0.6, 0), dark)
	add("Grip",     Vector3.new(0.3, 0.6, 0.3),   Vector3.new(0, -0.55, 0.8), dark)
	add("Bipod1",   Vector3.new(0.08, 0.8, 0.08), Vector3.new(0.35, -0.5, -2.0), dark)
	add("Bipod2",   Vector3.new(0.08, 0.8, 0.08), Vector3.new(-0.35, -0.5, -2.0), dark)
	return parts, main
end

local function finalize(g, parts, main, src)
	for _, p in ipairs(parts) do
		if p ~= main and p.Name == "Handle" then p.Name = "GunPart" end
	end
	main.Name = "Handle"

	-- scale model if requested (keeps relative positions)
	if g.scale and g.scale ~= 1 then
		local s = g.scale
		local origin = main.CFrame
		for _, p in ipairs(parts) do
			p.Size = p.Size * s
			local offset = origin:ToObjectSpace(p.CFrame)
			p.CFrame = origin * CFrame.new(offset.Position * s) * (offset - offset.Position)
		end
	end

	local tool = Instance.new("Tool")
	tool.Name = g.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = g.name

	for _, p in ipairs(parts) do
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		if p ~= main then
			local w = Instance.new("Weld")
			w.Part0 = main
			w.Part1 = p
			w.C0 = main.CFrame:ToObjectSpace(p.CFrame)
			w.Parent = p
		end
	end

	-- relative offsets for the floating viewmodel (before parenting)
	local rel = {}
	for _, p in ipairs(parts) do
		rel[p] = main.CFrame:ToObjectSpace(p.CFrame)
	end

	for _, p in ipairs(parts) do p.Parent = tool end
	if src then src:Destroy() end

	-- grip orientation
	local grip = CFrame.new()
	if g.autoOrient then
		local s = main.Size
		if s.X >= s.Y and s.X >= s.Z then
			grip = CFrame.Angles(0, math.rad(CFG.Flip and -90 or 90), 0)
		elseif s.Y > s.Z then
			grip = CFrame.Angles(math.rad(CFG.Flip and 90 or -90), 0, 0)
		elseif CFG.Flip then
			grip = CFrame.Angles(0, math.rad(180), 0)
		end
	end
	-- extra 180° flip for models that load backwards
	if g.flipModel then
		grip = grip * CFrame.Angles(0, math.rad(180), 0)
	end
	tool.Grip = grip * CFrame.new(0, -CFG.Up, CFG.Forward) * CFG.GripOffset

	local gr = tool.Grip
	local rot = CFrame.fromMatrix(Vector3.zero, gr.XVector, gr.YVector, gr.ZVector)

	g.tool = tool
	g.handle = main
	g.parts = parts
	g.rotInv = rot:Inverse()
	g.ammo = g.mag

	-- floating viewmodel (clones, positioned every frame)
	local vm = Instance.new("Model")
	vm.Name = g.name .. "_VM"
	g.vmRel = {}
	for _, p in ipairs(parts) do
		local c = p:Clone()
		for _, ch in ipairs(c:GetChildren()) do
			if ch:IsA("JointInstance") or ch:IsA("WeldConstraint") then ch:Destroy() end
		end
		c.Anchored = true
		c.CanCollide = false
		c.CanQuery = false
		c.CanTouch = false
		c.Parent = vm
		g.vmRel[c] = rel[p]
		if p == main then g.vmHandle = c end
	end
	-- blocky hands + forearms (positioned every frame)
	local function hp(name, size)
		local h = Instance.new("Part")
		h.Name = name
		h.Size = size
		h.Anchored = true
		h.CanCollide = false
		h.CanQuery = false
		h.CanTouch = false
		h.Material = Enum.Material.SmoothPlastic
		h.Color = Color3.fromRGB(234, 184, 146)
		h.TopSurface = Enum.SurfaceType.Smooth
		h.BottomSurface = Enum.SurfaceType.Smooth
		h.Parent = vm
		return h
	end
	g.hands = {
		rHand = hp("RHand", Vector3.new(0.42, 0.42, 0.5)),
		rArm  = hp("RArm",  Vector3.new(0.38, 0.38, 1)),
		lHand = hp("LHand", Vector3.new(0.42, 0.42, 0.5)),
		lArm  = hp("LArm",  Vector3.new(0.38, 0.38, 1)),
	}
	g.vm = vm
	table.insert(extras, vm)
end

for _, g in ipairs(GUNS) do
	local parts, main, src
	if g.modelId then
		parts, main, src = loadModelParts(g.modelId)
	else
		parts, main = buildBFGParts()
	end
	if parts then
		finalize(g, parts, main, src)
	else
		warn("[Gun] Failed to build " .. g.name)
	end
end

-- drop guns that failed to build
for i = #GUNS, 1, -1 do
	if not GUNS[i].tool then table.remove(GUNS, i) end
end
if #GUNS == 0 then return end

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local cur = nil
local scoped, reloading = false, false
local reloadId = 0
local lastShot = 0
local baseFOV = 70
local holdTrack, reloadTrack, aimTrack
local reloadAlpha, kick, aimAlpha = 0, 0, 0
local signalShot -- set in the PvP section
local fovTween

local function isFirstPerson()
	local _, char = getHum()
	local head = char and char:FindFirstChild("Head")
	return head ~= nil and (cam.CFrame.Position - head.Position).Magnitude < 1.6
end

local function playSound(id, vol, pitch)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol or 1
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 10)
end

local function skinColor()
	local _, char = getHum()
	if char then
		for _, n in ipairs({ "Right Arm", "RightHand", "RightLowerArm" }) do
			local p = char:FindFirstChild(n)
			if p and p:IsA("BasePart") then return p.Color end
		end
	end
	return Color3.fromRGB(234, 184, 146)
end

local function updateCam()
	local want = cur and (CFG.ForceFirstPerson or scoped)
	lp.CameraMode = want and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic
end

----------------------------------------------------------------
-- GUI
----------------------------------------------------------------
local scopeGui = Instance.new("ScreenGui")
scopeGui.Name = "SteyrScope"
scopeGui.IgnoreGuiInset = true
scopeGui.ResetOnSpawn = false
scopeGui.DisplayOrder = 5
scopeGui.Enabled = false
scopeGui.Parent = pgui
table.insert(extras, scopeGui)

do
	local vp = cam.ViewportSize
	local D = math.floor(math.min(vp.X, vp.Y) * 0.92)

	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromOffset(D, D)
	ring.BackgroundTransparency = 1
	ring.Parent = scopeGui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 3000
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = ring

	local ret = Instance.new("ImageLabel")
	ret.AnchorPoint = Vector2.new(0.5, 0.5)
	ret.Position = UDim2.fromScale(0.5, 0.5)
	ret.Size = UDim2.fromOffset(D, D)
	ret.BackgroundTransparency = 1
	ret.Image = RETICLE_IMAGE
	ret.ScaleType = Enum.ScaleType.Fit
	ret.ZIndex = 2
	ret.Parent = scopeGui

	-- solid black bars around the scope square so the world never shows beside it
	local function bar(anchor, pos, size)
		local f = Instance.new("Frame")
		f.AnchorPoint = anchor
		f.Position = pos
		f.Size = size
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		f.ZIndex = 1
		f.Parent = scopeGui
	end
	bar(Vector2.new(0, 0.5),   UDim2.fromScale(0, 0.5),   UDim2.new(0.5, -D / 2, 1, 0))  -- left
	bar(Vector2.new(1, 0.5),   UDim2.fromScale(1, 0.5),   UDim2.new(0.5, -D / 2, 1, 0))  -- right
	bar(Vector2.new(0.5, 0),   UDim2.fromScale(0.5, 0),   UDim2.new(1, 0, 0.5, -D / 2))  -- top
	bar(Vector2.new(0.5, 1),   UDim2.fromScale(0.5, 1),   UDim2.new(1, 0, 0.5, -D / 2))  -- bottom
end

local hud = Instance.new("ScreenGui")
hud.Name = "SteyrHUD"
hud.ResetOnSpawn = false
hud.DisplayOrder = 10
hud.Enabled = false
hud.Parent = pgui
table.insert(extras, hud)

local ammoLabel = Instance.new("TextLabel")
ammoLabel.AnchorPoint = Vector2.new(0.5, 1)
ammoLabel.Position = UDim2.new(0.5, 0, 1, -20)
ammoLabel.Size = UDim2.fromOffset(220, 36)
ammoLabel.BackgroundColor3 = Color3.new(0, 0, 0)
ammoLabel.BackgroundTransparency = 0.4
ammoLabel.TextColor3 = Color3.new(1, 1, 1)
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextSize = 18
ammoLabel.Text = ""
ammoLabel.Parent = hud
Instance.new("UICorner", ammoLabel)

local function makeButton(text, y)
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -16, 0.5, y)
	b.Size = UDim2.fromOffset(86, 50)
	b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	b.BackgroundTransparency = 0.25
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 15
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = hud
	Instance.new("UICorner", b)
	return b
end
local fireBtn   = makeButton("FIRE", -90)
local scopeBtn  = makeButton("SCOPE", -30)
local reloadBtn = makeButton("RELOAD", 30)
local switchBtn = makeButton("SWITCH", 90)
local warBtn    = makeButton("WAR: ON", 150)

local function updateAmmo()
	if not cur then return end
	if reloading then
		ammoLabel.Text = cur.name .. "  RELOADING..."
	else
		ammoLabel.Text = cur.name .. "  " .. cur.ammo .. " / " .. cur.mag
	end
end

----------------------------------------------------------------
-- SCOPE
----------------------------------------------------------------
local function setScope(on)
	if on and (not cur or reloading) then return end
	if scoped == on then return end
	scoped = on
	playSound(ZOOM_SOUND, 1, on and 1 or 0.9)
	if aimTrack then
		if on then aimTrack:Play() else aimTrack:Stop() end
	end
	local fov = on and cur.scopeFOV or baseFOV
	if fovTween then fovTween:Cancel() end
	TS:Create(cam, TweenInfo.new(0.2), { FieldOfView = fov }):Play()
	UIS.MouseDeltaSensitivity = on and 0.25 or 1
	updateCam()
end

----------------------------------------------------------------
-- EFFECTS
----------------------------------------------------------------
local function playShot(g)
	local id = g.shootSound or SHOOT_SOUND
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = g.volume
	s.PlaybackSpeed = g.pitch
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 8)
end

local function tracer(g, a, b)
	local dist = (b - a).Magnitude
	if dist < 0.1 then return end
	local t = Instance.new("Part")
	t.Anchored = true
	t.CanCollide = false
	t.CanQuery = false
	t.Material = Enum.Material.Neon
	t.Color = g.tracerColor
	t.Size = Vector3.new(g.tracerWidth, g.tracerWidth, dist)
	t.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -dist / 2)
	t.Parent = workspace
	TS:Create(t, TweenInfo.new(0.25), { Transparency = 1 }):Play()
	Debris:AddItem(t, 0.3)
end

local function hitFx(g, pos, inst)
	local sz = g.kick > 2 and 1 or 0.6
	local s = Instance.new("Part")
	s.Anchored = true
	s.CanCollide = false
	s.CanQuery = false
	s.Shape = Enum.PartType.Ball
	s.Material = Enum.Material.Neon
	s.Color = g.tracerColor
	s.Size = Vector3.new(sz, sz, sz)
	s.Position = pos
	s.Parent = workspace
	TS:Create(s, TweenInfo.new(0.3), { Size = Vector3.new(sz * 2.6, sz * 2.6, sz * 2.6), Transparency = 1 }):Play()
	Debris:AddItem(s, 0.35)

	local model = inst and inst:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		local h = Instance.new("Highlight")
		h.FillColor = Color3.fromRGB(255, 0, 0)
		h.FillTransparency = 0.4
		h.OutlineTransparency = 1
		h.Parent = model
		Debris:AddItem(h, 0.2)
	end
end

local function damageAt(inst, dmg, dir, srcTeam, allowSelf)
	if not inst then return end
	local model = inst:FindFirstAncestorOfClass("Model")
	while model and not model:FindFirstChildOfClass("Humanoid") do
		model = model:FindFirstAncestorOfClass("Model")
	end
	if not model then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	if model == lp.Character then
		if not allowSelf then return end
	elseif Players:GetPlayerFromCharacter(model) then
		return -- other real players can't be hurt from the client
	end
	if srcTeam and model:GetAttribute("Team") == srcTeam then return end
	if inst.Name == "Head" then dmg = dmg * 2 end

	hum.Health = math.max(0, hum.Health - dmg)
	if hum.Health <= 0 then
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
		pcall(function() model:BreakJoints() end)
		task.defer(function()
			pcall(function()
				inst:ApplyImpulse(dir * math.min(inst.AssemblyMass, 100) * 60)
			end)
		end)
	else
		local h = Instance.new("Highlight")
		h.FillColor = Color3.fromRGB(255, 0, 0)
		h.FillTransparency = 0.5
		h.OutlineTransparency = 1
		h.Parent = model
		Debris:AddItem(h, 0.15)
	end
end

local function muzzleFlash(g)
	for _, part in ipairs({ g.handle, g.vmHandle }) do
		if part then
			local l = Instance.new("PointLight")
			l.Brightness = 6
			l.Range = 14
			l.Color = Color3.fromRGB(255, 200, 120)
			l.Parent = part
			Debris:AddItem(l, 0.06)
		end
	end
end

----------------------------------------------------------------
-- FIRE / RELOAD
----------------------------------------------------------------
local function reload()
	local g = cur
	if not g or reloading or g.ammo >= g.mag then return end
	reloading = true
	reloadId += 1
	local id = reloadId
	setScope(false)
	updateAmmo()
	local soundId = g.reloadSound or RELOAD_SOUND
	playSound(soundId, 1.2, 1)
	if reloadTrack then reloadTrack:Play() end
	task.wait(g.reloadTime)
	if id == reloadId then
		if cur == g then g.ammo = g.mag end
		reloading = false
		updateAmmo()
	end
end

local bolting, boltT0, boltDur = false, 0, 1
local function boltCycle(g)
	local id = reloadId
	task.wait(0.35)
	if cur ~= g or reloading or id ~= reloadId then return end
	local wasScoped = scoped
	if wasScoped then setScope(false) end
	bolting = true
	boltT0 = os.clock()
	boltDur = g.boltTime or 0.9
	playSound(g.boltSound or BOLT_SOUND, 1.1, 1)
	task.wait(boltDur)
	bolting = false
	if wasScoped and cur == g and not reloading then setScope(true) end
end

local function fire()
	local g = cur
	if not g or reloading or bolting then return end
	if g.ammo <= 0 then
		task.spawn(reload)
		return
	end
	if os.clock() - lastShot < g.delay then return end
	lastShot = os.clock()
	g.ammo -= 1
	updateAmmo()

	local _, char = getHum()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, g.tool, g.vm }

	local origin = cam.CFrame.Position
	local dir = cam.CFrame.LookVector
	local res = workspace:Raycast(origin, dir * CFG.Range, params)
	local hitPos = res and res.Position or (origin + dir * CFG.Range)

	local startPos
	if scoped then
		startPos = origin + dir * 2
	elseif isFirstPerson() then
		startPos = (cam.CFrame * CFrame.new(g.vmOffset.X, g.vmOffset.Y + 0.05, g.vmOffset.Z - g.muzzleZ)).Position
	else
		startPos = g.handle.Position
	end

	playShot(g)
	if signalShot then signalShot(g) end
	-- bolt-action cock after the shot
	if g.bolt then task.spawn(boltCycle, g) end
	tracer(g, startPos, hitPos)
	if res then hitFx(g, hitPos, res.Instance) end
	if res then damageAt(res.Instance, g.damage, dir, nil, false) end
	muzzleFlash(g)

	-- recoil (FOV punch + camera kick up)
	kick = g.kick
	-- FOV punch always returns to the proper FOV (not whatever it is mid-punch), so fast guns can't creep the zoom in
	local fov = scoped and cur.scopeFOV or baseFOV
	if fovTween then fovTween:Cancel() end
	cam.FieldOfView = fov - g.kick * 1.2
	fovTween = TS:Create(cam, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = fov })
	fovTween:Play()

	local recoilAmt = math.rad(g.kick * 1.8) -- stronger vertical kick
	local side = math.rad((math.random() - 0.5) * g.kick * 0.6) -- slight random horizontal
	local startCF = cam.CFrame
	local targetCF = startCF * CFrame.Angles(recoilAmt, side, 0)
	if not g.auto then cam.CFrame = targetCF end
	-- recover over time
	task.spawn(function()
		if g.auto then return end
		local t0 = os.clock()
		local dur = 0.22
		while os.clock() - t0 < dur do
			local a = (os.clock() - t0) / dur
			a = a * a -- ease out
			cam.CFrame = startCF:Lerp(targetCF, 1 - a)
			task.wait()
		end
		cam.CFrame = startCF
	end)

	if g.ammo <= 0 then
		task.delay(0.6, function()
			if cur == g and g.ammo <= 0 then reload() end
		end)
	end
end

----------------------------------------------------------------
-- EQUIP / ANIMS
----------------------------------------------------------------
local holding, autoId = false, 0
local function startAuto(g)
	holding = true
	autoId += 1
	local id = autoId
	task.spawn(function()
		while holding and running and cur == g and id == autoId do
			fire()
			task.wait(g.delay)
		end
	end)
end

local function loadAnims()
	if holdTrack then pcall(function() holdTrack:Stop() end) end
	if reloadTrack then pcall(function() reloadTrack:Stop() end) end
	if aimTrack then pcall(function() aimTrack:Stop() end) end
	aimTrack = nil
	local hum = getHum()
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	local a1 = Instance.new("Animation")
	a1.AnimationId = HOLD_ANIM
	holdTrack = animator:LoadAnimation(a1)
	holdTrack.Looped = true
	holdTrack.Priority = Enum.AnimationPriority.Action

	local a2 = Instance.new("Animation")
	a2.AnimationId = RELOAD_ANIM
	reloadTrack = animator:LoadAnimation(a2)
	reloadTrack.Looped = false
	reloadTrack.Priority = Enum.AnimationPriority.Action2

	if AIM_ANIM then
		local a3 = Instance.new("Animation")
		a3.AnimationId = AIM_ANIM
		aimTrack = animator:LoadAnimation(a3)
		aimTrack.Looped = true
		aimTrack.Priority = Enum.AnimationPriority.Action3
	end
end

for _, g in ipairs(GUNS) do
	connect(g.tool.Equipped, function()
		cur = g
		bolting = false
		reloading = false
		reloadId += 1
		scoped = false
		scopeGui.Enabled = false
		aimAlpha = 0
		baseFOV = cam.FieldOfView > 20 and cam.FieldOfView or 70
		loadAnims()
		if holdTrack then holdTrack:Play() end
		local sc = skinColor()
		for _, h in pairs(g.hands) do h.Color = sc end
		hud.Enabled = true
		updateCam()
		updateAmmo()
	end)

	connect(g.tool.Unequipped, function()
		if cur ~= g then return end
		setScope(false)
		cur = nil
		bolting = false
		reloading = false
		reloadId += 1
		if holdTrack then holdTrack:Stop() end
		if reloadTrack then reloadTrack:Stop() end
		g.vm.Parent = nil
		scopeGui.Enabled = false
		aimAlpha = 0
		hud.Enabled = false
		updateCam()
	end)

	connect(g.tool.Activated, function()
		if g.auto then startAuto(g) else fire() end
	end)
	connect(g.tool.Deactivated, function() holding = false end)
end

----------------------------------------------------------------
-- FLOATING VIEWMODEL + FIRST PERSON
----------------------------------------------------------------
local function segment(p, a, b)
	local len = (b - a).Magnitude
	if len < 0.05 then return end
	p.Size = Vector3.new(p.Size.X, p.Size.Y, len)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
end

RS:BindToRenderStep("SteyrViewmodel", Enum.RenderPriority.Camera.Value + 1, function(dt)
	for _, g in ipairs(GUNS) do
		if g ~= cur and g.vm.Parent then g.vm.Parent = nil end
	end
	local g = cur
	if not g then return end

	local fp = isFirstPerson()
	local useOverlay = g.useScopeOverlay ~= false -- default true for snipers
	local hideHeld = (scoped and useOverlay) or fp
	for _, p in ipairs(g.parts) do
		p.LocalTransparencyModifier = hideHeld and 1 or 0
	end

	-- aim animation: gun slides to the centre, then the scope view opens (snipers only)
	aimAlpha += ((scoped and 1 or 0) - aimAlpha) * math.min(dt * 9, 1)
	local inScope = scoped and aimAlpha > 0.85 and useOverlay
	scopeGui.Enabled = inScope

	-- show viewmodel when in first person, or when aiming a pistol (no overlay)
	local showVM = fp and (not inScope or not useOverlay)
	if showVM then
		if g.vm.Parent ~= cam then g.vm.Parent = cam end
		reloadAlpha += ((reloading and 1 or 0) - reloadAlpha) * math.min(dt * 8, 1)
		kick += (0 - kick) * math.min(dt * 10, 1)
		local t = os.clock()
		local k = 1 - aimAlpha
		local bp = 0
		if bolting then
			local a = math.clamp((os.clock() - boltT0) / boltDur, 0, 1)
			bp = math.sin(a * math.pi) ^ 0.7 -- hand goes up/back, then forward again
		end
		local bob = CFrame.new(math.sin(t * 1.6) * 0.012 * k, math.sin(t * 2.2) * 0.014 * k, 0)
		local off = g.vmOffset:Lerp(g.aimOffset, aimAlpha)
		local baseF = cam.CFrame
			* CFrame.new(off)
			* bob
			* CFrame.new(0, -0.9 * reloadAlpha, 0.4 * reloadAlpha + kick * 0.05)
			* CFrame.Angles(math.rad(-30 * reloadAlpha + kick * 2), 0, math.rad(20 * reloadAlpha))
			* CFrame.Angles(0, 0, math.rad(-10 * bp))

		-- gun
		local base = baseF * g.rotInv
		for p, rel in pairs(g.vmRel) do
			p.CFrame = base * rel
		end

		-- hands (left hand drops away to the mag while reloading)
		local rPos = g.rHand + Vector3.new(0.25, 0.3, 0.6) * bp
		local lPos = g.lHand + Vector3.new(-0.25, -0.9, 0.8) * reloadAlpha
		local H = g.hands
		local rW = baseF * CFrame.new(rPos)
		local lW = baseF * CFrame.new(lPos)
		H.rHand.CFrame = rW
		H.lHand.CFrame = lW
		segment(H.rArm, rW.Position, (baseF * CFrame.new(rPos + Vector3.new(0.5, -0.9, 1.6))).Position)
		segment(H.lArm, lW.Position, (baseF * CFrame.new(lPos + Vector3.new(-0.7, -1.0, 1.5))).Position)
	else
		if g.vm.Parent then g.vm.Parent = nil end
	end
end)

----------------------------------------------------------------
-- INPUT
----------------------------------------------------------------
local function switchGun()
	local hum = getHum()
	if not hum then return end
	local idx = 0
	for i, g in ipairs(GUNS) do
		if g == cur then idx = i end
	end
	local nxt = GUNS[idx % #GUNS + 1]
	hum:UnequipTools()
	task.wait(0.05)
	hum:EquipTool(nxt.tool)
end

connect(UIS.InputBegan, function(input, gpe)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if cur then setScope(not scoped) end
	elseif not gpe then
		if input.KeyCode == Enum.KeyCode.R then
			task.spawn(reload)
		elseif input.KeyCode == Enum.KeyCode.Q then
			task.spawn(switchGun)
		end
	end
end)

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1
end
connect(fireBtn.InputBegan, function(i)
	if not isPress(i) or not cur then return end
	if cur.auto then startAuto(cur) else fire() end
end)
connect(fireBtn.InputEnded, function(i)
	if isPress(i) then holding = false end
end)
connect(scopeBtn.Activated, function() setScope(not scoped) end)
connect(reloadBtn.Activated, function() task.spawn(reload) end)
connect(switchBtn.Activated, function() task.spawn(switchGun) end)

----------------------------------------------------------------
-- NPC WAR: two teams with rifles shoot and KILL each other
----------------------------------------------------------------
local NPC_WALK = "rbxassetid://180426354"
local NPC_IDLE = "rbxassetid://180435571"

local TEAMS = {
	Red  = { color = Color3.fromRGB(196, 40, 28),  tracer = Color3.fromRGB(255, 90, 70) },
	Blue = { color = Color3.fromRGB(13, 105, 172), tracer = Color3.fromRGB(90, 170, 255) },
}
local npcs, bases = {}, {}
local warOn, warGen = false, 0
local spawnNpc

local warFolder = Instance.new("Folder")
warFolder.Name = "SteyrWar"
warFolder.Parent = workspace
table.insert(extras, warFolder)

local function mkPart(name, size, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function motor(name, p0, p1, c0, c1)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = c0
	m.C1 = c1
	m.Parent = p0
	return m
end

local function buildRifle(model, rArm)
	local dark = Color3.fromRGB(35, 35, 40)
	local grip = CFrame.new(0, -1, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
	local handle = mkPart("Handle", Vector3.new(0.25, 0.4, 1.4), dark, model)
	handle.CFrame = rArm.CFrame * grip
	local list = { handle }
	local extra = {
		{ "Barrel", Vector3.new(0.15, 0.15, 1.2), Vector3.new(0, 0.1, -1.25) },
		{ "Stock",  Vector3.new(0.25, 0.45, 0.8), Vector3.new(0, -0.05, 1.0) },
		{ "Mag",    Vector3.new(0.2, 0.5, 0.3),   Vector3.new(0, -0.4, -0.1) },
	}
	for _, d in ipairs(extra) do
		local p = mkPart(d[1], d[2], dark, model)
		p.CFrame = handle.CFrame * CFrame.new(d[3])
		local w = Instance.new("Weld")
		w.Part0 = handle
		w.Part1 = p
		w.C0 = CFrame.new(d[3])
		w.Parent = p
		table.insert(list, p)
	end
	for _, p in ipairs(list) do
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
	end
	local w = Instance.new("Weld")
	w.Part0 = rArm
	w.Part1 = handle
	w.C0 = grip
	w.Parent = handle
	return handle
end

local function buildNpc(teamName, pos)
	local T = TEAMS[teamName]
	local m = Instance.new("Model")
	m.Name = teamName .. "_Soldier"
	m:SetAttribute("Team", teamName)

	local skin = Color3.fromRGB(234, 184, 146)
	local legC = Color3.fromRGB(40, 40, 50)
	local hrp   = mkPart("HumanoidRootPart", Vector3.new(2, 2, 1), skin, m)
	hrp.Transparency = 1
	local torso = mkPart("Torso", Vector3.new(2, 2, 1), T.color, m)
	local head  = mkPart("Head", Vector3.new(2, 1, 1), skin, m)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head
	local rArm = mkPart("Right Arm", Vector3.new(1, 2, 1), skin, m)
	local lArm = mkPart("Left Arm",  Vector3.new(1, 2, 1), skin, m)
	local rLeg = mkPart("Right Leg", Vector3.new(1, 2, 1), legC, m)
	local lLeg = mkPart("Left Leg",  Vector3.new(1, 2, 1), legC, m)

	local base = CFrame.new(pos)
	hrp.CFrame = base
	torso.CFrame = base
	head.CFrame = base * CFrame.new(0, 1.5, 0)
	rArm.CFrame = base * CFrame.new(1.5, 0, 0)
	lArm.CFrame = base * CFrame.new(-1.5, 0, 0)
	rLeg.CFrame = base * CFrame.new(0.5, -2, 0)
	lLeg.CFrame = base * CFrame.new(-0.5, -2, 0)

	local rootC = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
	motor("RootJoint", hrp, torso, rootC, rootC)
	motor("Neck", torso, head,
		CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	motor("Right Shoulder", torso, rArm,
		CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	motor("Left Shoulder", torso, lArm,
		CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	motor("Right Hip", torso, rLeg,
		CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	motor("Left Hip", torso, lLeg,
		CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

	local handle = buildRifle(m, rArm)

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.MaxHealth = 100
	hum.Health = 100
	hum.WalkSpeed = 16
	hum.UseJumpPower = true
	hum.JumpPower = 50
	hum.AutoRotate = false
	hum.BreakJointsOnDeath = true
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = m
	local animator = Instance.new("Animator")
	animator.Parent = hum
	m.PrimaryPart = hrp
	m.Parent = warFolder

	local function track(id, looped, prio)
		local a = Instance.new("Animation")
		a.AnimationId = id
		local t = animator:LoadAnimation(a)
		t.Looped = looped
		t.Priority = prio
		return t
	end
	local n = {
		model = m, hum = hum, hrp = hrp, head = head, torso = torso, handle = handle, team = teamName,
		last = os.clock() + math.random() * 1.0, delay = 0.6, strafe = 0, strafeT = 0,
		walk = track(NPC_WALK, true, Enum.AnimationPriority.Core),
		idle = track(NPC_IDLE, true, Enum.AnimationPriority.Idle),
		hold = track(HOLD_ANIM, true, Enum.AnimationPriority.Action),
	}
	n.hold:Play()
	n.idle:Play()

	hum.Died:Connect(function()
		local i = table.find(npcs, n)
		if i then table.remove(npcs, i) end
		pcall(function() n.hold:Stop() n.walk:Stop() n.idle:Stop() end)
		Debris:AddItem(m, 6)
		local gen = warGen
		task.delay(6, function()
			if running and warOn and gen == warGen then spawnNpc(teamName) end
		end)
	end)
	return n
end

local function groundAt(pos)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local _, char = getHum()
	rp.FilterDescendantsInstances = { char, warFolder }
	local res = workspace:Raycast(pos + Vector3.new(0, 300, 0), Vector3.new(0, -600, 0), rp)
	return res and res.Position or pos
end

spawnNpc = function(team)
	local b = bases[team]
	if not b then return end
	local off = Vector3.new(math.random(-14, 14), 0, math.random(-14, 14))
	local gp = groundAt(b + off)
	local n = buildNpc(team, gp + Vector3.new(0, 3.3, 0))
	table.insert(npcs, n)
end

local function playerTarget()
	local hum, char = getHum()
	if not hum or hum.Health <= 0 then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")
	if not hrp or not head then return nil end
	return { model = char, hrp = hrp, head = head, hum = hum, team = "Player", isPlayer = true }
end

local function hasLOS(n, tgt)
	local from = n.head.Position
	local to = tgt.head.Position
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { n.model }
	local res = workspace:Raycast(from, to - from, rp)
	return res == nil or res.Instance:IsDescendantOf(tgt.model)
end

local function npcShoot(n, tgt)
	local muzzle = n.handle.CFrame:PointToWorldSpace(Vector3.new(0, 0.1, -1.9))
	-- if the rifle isn't posed yet, shoot from the chest so bullets never start in the ground
	if (muzzle - n.hrp.Position).Magnitude > 6 then
		muzzle = n.hrp.Position + Vector3.new(0, 1, 0)
	end
	local aim = tgt.head.Position
	local dist = (aim - muzzle).Magnitude
	local hitChance = math.random() < CFG.NpcAccuracy

	local hitPos, hitInst
	local dir = (aim - muzzle).Unit

	if hitChance then
		-- a clean hit on the target's torso or head
		local part = (math.random() < 0.25) and tgt.head or (tgt.torso or tgt.hrp)
		hitPos = part.Position
		hitInst = part
		dir = (hitPos - muzzle).Unit
	else
		-- a miss: spread the shot, but anything unlucky in the way still takes the hit
		local spread = math.clamp(dist / 60, 0.08, 0.35)
		dir = (dir + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * spread).Unit
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { n.model }
		local res = workspace:Raycast(muzzle, dir * 400, rp)
		hitPos = res and res.Position or (muzzle + dir * 400)
		hitInst = res and res.Instance
	end

	tracer({ tracerColor = TEAMS[n.team].tracer, tracerWidth = 0.1 }, muzzle, hitPos)

	local s = Instance.new("Sound")
	s.SoundId = SHOOT_SOUND
	s.Volume = 0.8
	s.PlaybackSpeed = 1 + math.random() * 0.25
	s.RollOffMinDistance = 20
	s.RollOffMaxDistance = 350
	s.Parent = n.handle
	s:Play()
	Debris:AddItem(s, 6)

	local l = Instance.new("PointLight")
	l.Brightness = 5
	l.Range = 10
	l.Color = Color3.fromRGB(255, 200, 120)
	l.Parent = n.handle
	Debris:AddItem(l, 0.05)

	if hitInst then
		-- NPCs can hurt enemy NPCs (and you only if NpcHostileToPlayer is on); never their own team
		damageAt(hitInst, CFG.NpcDamage, dir, n.team, CFG.NpcHostileToPlayer)
	end
end

local function setMoving(n, moving)
	if moving then
		if not n.walk.IsPlaying then
			n.walk:Play(0.1)
			n.idle:Stop(0.1)
		end
	else
		if not n.idle.IsPlaying then
			n.idle:Play(0.1)
			n.walk:Stop(0.1)
		end
	end
end

local function aiStep(n, dt)
	local hum, hrp = n.hum, n.hrp

	local tgt, bd = nil, math.huge
	for _, o in ipairs(npcs) do
		if o.team ~= n.team and o.hum.Health > 0 and o.hrp.Parent then
			local d = (o.hrp.Position - hrp.Position).Magnitude
			if d < bd then tgt, bd = o, d end
		end
	end
	if CFG.NpcHostileToPlayer then
		local pt = playerTarget()
		if pt then
			local d = (pt.hrp.Position - hrp.Position).Magnitude
			if d < bd then tgt, bd = pt, d end
		end
	end

	if not tgt then
		hum:Move(Vector3.zero, false)
		setMoving(n, false)
		return
	end

	local tp = tgt.hrp.Position
	local flat = Vector3.new(tp.X - hrp.Position.X, 0, tp.Z - hrp.Position.Z)
	local dist = flat.Magnitude
	local fwd = dist > 0.1 and flat.Unit or hrp.CFrame.LookVector
	local right = fwd:Cross(Vector3.yAxis)

	n.strafeT -= dt
	if n.strafeT <= 0 then
		n.strafe = ({ -1, 0, 1 })[math.random(1, 3)]
		n.strafeT = 1 + math.random() * 2
	end

	-- close in to a comfortable shooting range, back off if too close
	local f = 0
	if dist > 50 then f = 1 elseif dist < 20 then f = -1 end
	local move = fwd * f + right * n.strafe * 0.8
	if move.Magnitude > 1 then move = move.Unit end
	hum:Move(move, false)
	setMoving(n, move.Magnitude > 0.1)

	-- face the target
	local look = CFrame.lookAt(hrp.Position, hrp.Position + fwd)
	hrp.CFrame = hrp.CFrame:Lerp(look, math.min(dt * 10, 1))

	-- jump over obstacles / randomly like a player
	if move.Magnitude > 0.1 then
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { n.model }
		local blocked = workspace:Raycast(hrp.Position - Vector3.new(0, 1.5, 0), move.Unit * 3, rp)
		if blocked then hum.Jump = true end
	end
	if math.random() < dt * 0.15 then hum.Jump = true end

	-- shoot
	if dist < 250 and os.clock() - n.last > n.delay and hasLOS(n, tgt) then
		n.last = os.clock()
		n.delay = 0.5 + math.random() * 0.7
		npcShoot(n, tgt)
	end
end

connect(RS.Heartbeat, function(dt)
	if not warOn then return end
	for _, n in ipairs(table.clone(npcs)) do
		if n.hum.Health > 0 and n.hrp.Parent then
			if n.hrp.Position.Y < -300 then
				n.hum.Health = 0
			else
				aiStep(n, dt)
			end
		end
	end
end)

local function startWar()
	local _, char = getHum()
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local center = hrp and hrp.Position or Vector3.new(0, 10, 0)
	local ang = math.random() * math.pi * 2
	local d = Vector3.new(math.cos(ang), 0, math.sin(ang)) * CFG.NpcDistance
	bases.Red = center + d
	bases.Blue = center - d
	warOn = true
	warGen += 1
	local gen = warGen
	warBtn.Text = "WAR: ON"
	for _, team in ipairs({ "Red", "Blue" }) do
		for i = 1, CFG.NpcPerTeam do
			task.delay(i * 0.3, function()
				if running and warOn and gen == warGen then spawnNpc(team) end
			end)
		end
	end
end

local function stopWar()
	warOn = false
	warGen += 1
	for _, n in ipairs(npcs) do
		pcall(function() n.model:Destroy() end)
	end
	table.clear(npcs)
	warBtn.Text = "WAR: OFF"
end

connect(warBtn.Activated, function()
	if warOn then stopWar() else startWar() end
end)

----------------------------------------------------------------
-- PVP: other players running this same script
-- A client script can't talk to other clients directly, so each shot is announced through a
-- tiny, invisible animation on your character (animations DO replicate to everyone). Other
-- copies of this script see it, draw your tracer + sound, and the player you were facing
-- works out the hit and damages THEMSELVES. So everyone has to be running this script.
----------------------------------------------------------------
local HOLD_ID = HOLD_ANIM:match("%d+")
-- signal animations (Roblox default R6 anims nobody normally plays). Change the ids here if a type never registers.
local SIG_ANIM = {
	sniper = "rbxassetid://129967390",
	pistol = "rbxassetid://129967478",
	auto   = "rbxassetid://128777973",
}
local SIG_NUM = {}
for cls, id in pairs(SIG_ANIM) do SIG_NUM[cls] = id:match("%d+") end
local SIG_SOUND = {
	sniper = { id = SHOOT_SOUND, vol = 1.4, pitch = 1 },
	pistol = { id = "rbxassetid://71313174881521", vol = 1.4, pitch = 1.05 },
	auto   = { id = "rbxassetid://801170812", vol = 1.0, pitch = 1 },
}
local SIG_TRACER = {
	sniper = { tracerColor = Color3.fromRGB(255, 220, 120), tracerWidth = 0.1 },
	pistol = { tracerColor = Color3.fromRGB(255, 210, 90), tracerWidth = 0.07 },
	auto   = { tracerColor = Color3.fromRGB(255, 220, 120), tracerWidth = 0.05 },
}

local function classOf(g)
	if g.auto then return "auto" end
	if g.bolt then return "sniper" end
	return "pistol"
end

---------------- announcing my shots ----------------
local sigTracks, autoUntil = {}, 0

local function sigTrack(cls)
	local hum = getHum()
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then return nil end
	local cached = sigTracks[cls]
	if cached and cached.animator == animator then return cached.track end
	local a = Instance.new("Animation")
	a.AnimationId = SIG_ANIM[cls]
	local ok, t = pcall(function() return animator:LoadAnimation(a) end)
	if not ok or not t then return nil end
	t.Looped = true
	t.Priority = Enum.AnimationPriority.Idle
	sigTracks[cls] = { animator = animator, track = t }
	return t
end

signalShot = function(g)
	if not CFG.Pvp then return end
	local cls = classOf(g)
	local t = sigTrack(cls)
	if not t then return end
	if cls == "auto" then
		autoUntil = os.clock() + 0.25
		if not t.IsPlaying then t:Play(0, 0.01, 1) end
	else
		if t.IsPlaying then t:Stop(0) end
		t:Play(0, 0.01, 1)
		task.delay(0.2, function()
			pcall(function() t:Stop(0) end)
		end)
	end
end

connect(RS.Heartbeat, function()
	local c = sigTracks.auto
	if c and c.track.IsPlaying and os.clock() > autoUntil then
		pcall(function() c.track:Stop(0) end)
	end
end)

---------------- getting hurt ----------------
local pvpHP = 100
local pvpGui = Instance.new("ScreenGui")
pvpGui.Name = "SteyrPvp"
pvpGui.IgnoreGuiInset = true
pvpGui.ResetOnSpawn = false
pvpGui.DisplayOrder = 20
pvpGui.Enabled = CFG.Pvp
pvpGui.Parent = pgui
table.insert(extras, pvpGui)

local hpLabel = Instance.new("TextLabel")
hpLabel.AnchorPoint = Vector2.new(0, 0)
hpLabel.Position = UDim2.new(0, 12, 0, 60)
hpLabel.Size = UDim2.fromOffset(110, 28)
hpLabel.BackgroundColor3 = Color3.new(0, 0, 0)
hpLabel.BackgroundTransparency = 0.4
hpLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
hpLabel.Font = Enum.Font.GothamBold
hpLabel.TextSize = 16
hpLabel.Text = "PVP HP 100"
hpLabel.Parent = pvpGui
Instance.new("UICorner", hpLabel)

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.ZIndex = 0
flash.Parent = pvpGui

local function pvpDamage(amount)
	local hum = getHum()
	if not hum or hum.Health <= 0 or pvpHP <= 0 then return end
	pvpHP = math.max(0, pvpHP - amount)
	hpLabel.Text = "PVP HP " .. math.floor(pvpHP)
	hpLabel.TextColor3 = pvpHP > 50 and Color3.fromRGB(120, 255, 120)
		or pvpHP > 25 and Color3.fromRGB(255, 220, 90) or Color3.fromRGB(255, 80, 80)
	flash.BackgroundTransparency = 0.6
	TS:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	pcall(function() hum.Health = math.max(0, pvpHP) end)
	if pvpHP <= 0 then
		pcall(function() hum.Health = 0 end)
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
		pcall(function()
			local _, ch = getHum()
			if ch then ch:BreakJoints() end
		end)
	end
end

local function resetPvp()
	pvpHP = 100
	hpLabel.Text = "PVP HP 100"
	hpLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	sigTracks = {}
end
connect(lp.CharacterAdded, resetPvp)

---------------- watching other players ----------------
local function flatDir(v)
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 0.05 and f.Unit or nil
end

local function observedShot(pl, char, cls)
	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not head or not hrp then return end

	local aim = head.CFrame.LookVector
	local origin = head.Position + aim * 1.5

	-- tracer + sound for everyone watching
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char }
	local res = workspace:Raycast(origin, aim * 600, rp)
	tracer(SIG_TRACER[cls], origin, res and res.Position or (origin + aim * 600))
	local sd = SIG_SOUND[cls]
	local s = Instance.new("Sound")
	s.SoundId = sd.id
	s.Volume = sd.vol
	s.PlaybackSpeed = sd.pitch
	s.RollOffMinDistance = 30
	s.RollOffMaxDistance = 600
	s.Parent = head
	s:Play()
	Debris:AddItem(s, 6)

	-- am I the one being shot at?
	local myHum, myChar = getHum()
	if not myHum or myHum.Health <= 0 then return end
	local myHrp = myChar:FindFirstChild("HumanoidRootPart")
	local myHead = myChar:FindFirstChild("Head")
	if not myHrp or not myHead then return end

	local toMe = myHrp.Position - head.Position
	local face = flatDir(head.CFrame.LookVector) or flatDir(hrp.CFrame.LookVector)
	local flatTo = flatDir(toMe)
	if not face then return end
	if flatTo then
		local cosA = face:Dot(flatTo)
		if cosA < 0.3 then return end
		local flatDist = Vector3.new(toMe.X, 0, toMe.Z).Magnitude
		local lateral = flatDist * math.sqrt(math.max(0, 1 - cosA * cosA))
		if lateral > CFG.PvpHitRadius then return end
	end

	-- nothing solid in the way
	local rp2 = RaycastParams.new()
	rp2.FilterType = Enum.RaycastFilterType.Exclude
	rp2.FilterDescendantsInstances = { char }
	local block = workspace:Raycast(head.Position, myHead.Position - head.Position, rp2)
	if block and not block.Instance:IsDescendantOf(myChar) then return end

	pvpDamage(CFG.PvpDamage[cls] or 20)
end

local watch = {}
connect(RS.Heartbeat, function()
	if not CFG.Pvp then return end
	local now = os.clock()
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= lp then
			local char = pl.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local animator = hum and hum:FindFirstChildOfClass("Animator")
			local st = watch[pl]
			if not st then st = { auto = 0 }; watch[pl] = st end
			local ids = nil
			if animator and hum.Health > 0 then
				ids = {}
				for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
					local a = t.Animation
					local num = a and a.AnimationId:match("%d+")
					if num then ids[num] = true end
				end
			end
			if ids and ids[HOLD_ID] then -- only people actually holding one of these guns
				for cls, num in pairs(SIG_NUM) do
					local on = ids[num] == true
					if cls == "auto" then
						if on and now >= st.auto then
							st.auto = now + CFG.PvpAutoDelay
							observedShot(pl, char, cls)
						end
					else
						if on and not st[cls] and now - (st[cls .. "T"] or 0) > 0.25 then
							st[cls .. "T"] = now
							observedShot(pl, char, cls)
						end
						st[cls] = on
					end
				end
			else
				st.sniper, st.pistol = false, false
			end
		end
	end
end)
connect(Players.PlayerRemoving, function(pl) watch[pl] = nil end)

----------------------------------------------------------------
-- SERVER BROWSER: list public servers of this game and join one
----------------------------------------------------------------
local HttpService     = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)

local srvBtn = Instance.new("TextButton")
srvBtn.Position = UDim2.new(0, 12, 0, 94)
srvBtn.Size = UDim2.fromOffset(110, 30)
srvBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
srvBtn.BackgroundTransparency = 0.25
srvBtn.TextColor3 = Color3.new(1, 1, 1)
srvBtn.Font = Enum.Font.GothamBold
srvBtn.TextSize = 14
srvBtn.Text = "SERVERS"
srvBtn.Parent = pvpGui
Instance.new("UICorner", srvBtn)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(420, 300)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.ZIndex = 30
panel.Parent = pvpGui
Instance.new("UICorner", panel)

local function panelLabel(text, pos, size, align)
	local l = Instance.new("TextLabel")
	l.Position = pos
	l.Size = size
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 15
	l.Text = text
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.ZIndex = 31
	l.Parent = panel
	return l
end
panelLabel("SERVER BROWSER", UDim2.fromOffset(14, 8), UDim2.fromOffset(200, 24))
local status = panelLabel("", UDim2.fromOffset(14, 32), UDim2.new(1, -28, 0, 20))
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(190, 190, 190)

local function panelButton(text, x, w)
	local b = Instance.new("TextButton")
	b.Position = UDim2.new(1, x, 0, 8)
	b.Size = UDim2.fromOffset(w, 26)
	b.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.Text = text
	b.ZIndex = 31
	b.Parent = panel
	Instance.new("UICorner", b)
	return b
end
local closeBtn   = panelButton("X", -40, 30)
local refreshBtn = panelButton("REFRESH", -126, 80)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(10, 58)
list.Size = UDim2.new(1, -20, 1, -68)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ZIndex = 31
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function addRow(text, order, serverId)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 36)
	row.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
	row.LayoutOrder = order
	row.ZIndex = 32
	row.Parent = list
	Instance.new("UICorner", row)
	local l = Instance.new("TextLabel")
	l.Position = UDim2.fromOffset(10, 0)
	l.Size = UDim2.new(1, -90, 1, 0)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.Gotham
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.ZIndex = 33
	l.Parent = row
	if serverId then
		local j = Instance.new("TextButton")
		j.AnchorPoint = Vector2.new(1, 0.5)
		j.Position = UDim2.new(1, -6, 0.5, 0)
		j.Size = UDim2.fromOffset(66, 26)
		j.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
		j.TextColor3 = Color3.new(1, 1, 1)
		j.Font = Enum.Font.GothamBold
		j.TextSize = 13
		j.Text = "JOIN"
		j.ZIndex = 33
		j.Parent = row
		Instance.new("UICorner", j)
		j.Activated:Connect(function()
			status.Text = "Joining..."
			local ok, err = pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, lp)
			end)
			if not ok then status.Text = "Couldn't join: " .. tostring(err) end
		end)
	end
end

local refreshing = false
local function refreshServers()
	if refreshing then return end
	refreshing = true
	status.Text = "Loading servers..."
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	local servers, err = {}, nil
	local cursor = nil
	for _ = 1, 3 do -- up to 3 pages of 100
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(game.PlaceId)
		if cursor then url = url .. "&cursor=" .. cursor end
		local ok, body = pcall(function()
			if httpRequest then
				local r = httpRequest({ Url = url, Method = "GET" })
				return r and r.Body
			end
			return game:HttpGet(url)
		end)
		if not ok or not body then err = "HTTP request failed (does your executor support requests?)"; break end
		local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
		if not ok2 or type(data) ~= "table" then err = "bad response"; break end
		if data.errors then
			err = (data.errors[1] and data.errors[1].message) or "request refused"
			break
		end
		for _, sv in ipairs(data.data or {}) do table.insert(servers, sv) end
		cursor = data.nextPageCursor
		if not cursor then break end
	end

	if #servers == 0 then
		status.Text = err or "No public servers found."
	else
		status.Text = #servers .. " servers  (most players first)"
		addRow("This server  -  " .. #Players:GetPlayers() .. " players", 0, nil)
		local order = 1
		for _, sv in ipairs(servers) do
			if sv.id ~= game.JobId then
				local ping = sv.ping and (" - " .. sv.ping .. " ms") or ""
				addRow(("%d/%d players%s"):format(sv.playing or 0, sv.maxPlayers or 0, ping), order, sv.id)
				order += 1
			end
		end
	end
	refreshing = false
end

connect(srvBtn.Activated, function()
	panel.Visible = not panel.Visible
	if panel.Visible then task.spawn(refreshServers) end
end)
connect(closeBtn.Activated, function() panel.Visible = false end)
connect(refreshBtn.Activated, function() task.spawn(refreshServers) end)

----------------------------------------------------------------
-- GIVE TOOLS (and again after respawn)
----------------------------------------------------------------
local function give()
	local backpack = lp:WaitForChild("Backpack")
	for _, g in ipairs(GUNS) do
		g.tool.Parent = backpack
	end
	task.wait(0.2)
	local hum = getHum()
	if hum then hum:EquipTool(GUNS[1].tool) end
end

connect(lp.CharacterAdded, function()
	cur, scoped, reloading = nil, false, false
	reloadId += 1
	for _, g in ipairs(GUNS) do g.ammo = g.mag end
	task.wait(1)
	give()
end)

give()
if CFG.StartWar then task.spawn(startWar) end

_G.SteyrScoutCleanup = function()
	running = false
	pcall(function() RS:UnbindFromRenderStep("SteyrViewmodel") end)
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	for _, e in ipairs(extras) do pcall(function() e:Destroy() end) end
	for _, g in ipairs(GUNS) do pcall(function() g.tool:Destroy() end) end
	pcall(function()
		lp.CameraMode = Enum.CameraMode.Classic
		UIS.MouseDeltaSensitivity = 1
	end)
end
