--[[
	CosmeticService — สวมใส่สกิน/หมวก/หาง/สัตว์เลี้ยง/ออร่า ให้ตัวละคร
	ทุกชิ้นสร้างจาก Part ล้วน ๆ (ไม่ต้องอัปโหลด Mesh) จึงใช้ได้ทันที
	ฝั่ง client (Effects.lua) จะทำแอนิเมชันสายรุ้ง/ใบพัดหมุนให้ผ่าน CollectionService tag
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemCatalog = require(Shared.ItemCatalog)
local DataService = require(script.Parent.DataService)

local CosmeticService = {}

local states = {} -- [Player] = state
local petsFolder
local stashRoot

local UP = CFrame.Angles(0, 0, math.rad(90)) -- หมุน Cylinder ให้ตั้งขึ้น
local CLOTHING = { Shirt = true, Pants = true, ShirtGraphic = true, BodyColors = true }

-- ===== helpers =====

local function newPart(props)
	local part = Instance.new("Part")
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		part[key] = value
	end
	return part
end

local function ball(size, color, material)
	return newPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * size,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

local function cylinder(height, diameter, color, material)
	return newPart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

local function block(size, color, material)
	return newPart({ Size = size, Color = color, Material = material or Enum.Material.SmoothPlastic })
end

local function ellipsoid(size, color)
	local part = block(size, color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

local function weld(a, b)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = a
	constraint.Part1 = b
	constraint.Parent = b
end

local function track(state, instance)
	table.insert(state.Created, instance)
	return instance
end

local function materialOf(item)
	if item.Material and Enum.Material[item.Material] then
		return Enum.Material[item.Material]
	end
	return Enum.Material.SmoothPlastic
end

-- ===== หมวก: แต่ละสไตล์สร้างจาก Part หลายชิ้น วางเทียบกับ "ยอดหัว" =====

local HatBuilders = {}

HatBuilders.PartyCone = function(c, add)
	local c1, c2 = c[1], c[2] or c[1]
	for i = 0, 4 do
		local d = 1.6 - i * 0.3
		add(cylinder(0.4, d, i % 2 == 0 and c1 or c2), CFrame.new(0, 0.2 + i * 0.38, 0) * UP)
	end
	add(ball(0.5, c2, Enum.Material.Neon), CFrame.new(0, 2.15, 0))
end

HatBuilders.CatEars = function(c, add)
	local c1, c2 = c[1], c[2] or c[1]
	for _, side in { -1, 1 } do
		local rot = CFrame.Angles(0, 0, math.rad(45))
		add(block(Vector3.new(0.6, 0.6, 0.18), c1), CFrame.new(side * 0.42, 0.05, 0) * rot)
		add(block(Vector3.new(0.38, 0.38, 0.05), c2), CFrame.new(side * 0.42, 0.05, -0.1) * rot)
	end
end

HatBuilders.BunnyEars = function(c, add)
	local c1, c2 = c[1], c[2] or c[1]
	for _, side in { -1, 1 } do
		local cf = CFrame.new(side * 0.32, 0.75, 0) * CFrame.Angles(0, 0, math.rad(-side * 10))
		add(ellipsoid(Vector3.new(0.4, 1.7, 0.3), c1), cf)
		add(ellipsoid(Vector3.new(0.22, 1.2, 0.1), c2), cf * CFrame.new(0, 0, -0.12))
	end
end

HatBuilders.Flower = function(c, add)
	local c1, c2 = c[1], c[2] or c[1]
	add(ball(0.5, c2), CFrame.new(0, 0.25, 0))
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		add(ball(0.42, c1), CFrame.new(math.cos(a) * 0.42, 0.2, math.sin(a) * 0.42))
	end
end

HatBuilders.Antenna = function(c, add)
	local c1, c2 = c[1], c[2] or c[1]
	for _, side in { -1, 1 } do
		local tilt = CFrame.Angles(0, 0, math.rad(-side * 15))
		add(cylinder(1.0, 0.12, c1), CFrame.new(side * 0.3, 0.45, 0) * tilt * UP)
		local tip = ball(0.42, c2, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = c2
		light.Range = 6
		light.Parent = tip
		add(tip, CFrame.new(side * 0.43, 0.98, 0))
	end
end

HatBuilders.TopHat = function(c, add)
	local c1, c2 = c[1], c[2] or c[1]
	add(cylinder(0.15, 2.0, c1), CFrame.new(0, 0.08, 0) * UP)
	add(cylinder(1.3, 1.3, c1), CFrame.new(0, 0.8, 0) * UP)
	add(cylinder(0.25, 1.36, c2), CFrame.new(0, 0.3, 0) * UP)
end

HatBuilders.Propeller = function(c, add)
	local c1, c2, c3 = c[1], c[2] or c[1], c[3] or c[1]
	add(cylinder(0.3, 1.35, c1), CFrame.new(0, 0.15, 0) * UP)
	add(cylinder(0.25, 1.36, c2), CFrame.new(0, 0.12, 0) * UP)
	add(cylinder(0.5, 0.14, c3), CFrame.new(0, 0.55, 0) * UP)
	add(block(Vector3.new(2.4, 0.08, 0.32), c3), CFrame.new(0, 0.82, 0), true) -- ใบพัด (หมุนฝั่ง client)
end

HatBuilders.Crown = function(c, add)
	local c1, c2 = c[1], c[2] or c[1]
	add(cylinder(0.5, 1.5, c1, Enum.Material.Metal), CFrame.new(0, 0.25, 0) * UP)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local x, z = math.cos(a) * 0.62, math.sin(a) * 0.62
		add(block(Vector3.new(0.28, 0.5, 0.28), c1, Enum.Material.Metal), CFrame.new(x, 0.7, z) * CFrame.Angles(0, -a, 0))
		add(ball(0.26, c2, Enum.Material.Neon), CFrame.new(x, 1.02, z))
	end
end

HatBuilders.Halo = function(c, add)
	local c1 = c[1]
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		add(ball(0.28, c1, Enum.Material.Neon), CFrame.new(math.cos(a) * 0.75, 1.0, math.sin(a) * 0.75))
	end
	local core = ball(0.1, c1, Enum.Material.Neon)
	core.Transparency = 1
	local light = Instance.new("PointLight")
	light.Color = c1
	light.Range = 8
	light.Brightness = 2
	light.Parent = core
	add(core, CFrame.new(0, 1.0, 0))
end

-- ===== สัตว์เลี้ยง =====

local PetBuilders = {}

local function addFace(body, front, add)
	for _, side in { -1, 1 } do
		add(ball(0.3, Color3.fromRGB(30, 30, 40)), CFrame.new(side * 0.3, 0.15, -front))
		add(ball(0.1, Color3.new(1, 1, 1), Enum.Material.Neon), CFrame.new(side * 0.3 + 0.06, 0.22, -front - 0.12))
		add(ball(0.22, Color3.fromRGB(255, 150, 170)), CFrame.new(side * 0.52, -0.12, -front + 0.08))
	end
	return body
end

PetBuilders.Ball = function(item, c, add)
	local body = ball(1.6, c[1], materialOf(item))
	add(body, CFrame.new())
	if c[2] then
		add(cylinder(0.3, 1.64, c[2]), CFrame.new(0, -0.15, 0) * CFrame.Angles(0, math.rad(90), 0))
	end
	return addFace(body, 0.72, add)
end

PetBuilders.Cube = function(item, c, add)
	local body = block(Vector3.one * 1.5, c[1], materialOf(item))
	add(body, CFrame.new())
	return addFace(body, 0.72, add)
end

PetBuilders.Ghost = function(item, c, add)
	local body = ball(1.6, c[1], materialOf(item))
	body.Transparency = 0.2
	add(body, CFrame.new())
	for i = -1, 1 do
		local tail = ball(0.55, c[1])
		tail.Transparency = 0.2
		add(tail, CFrame.new(i * 0.45, -0.75, 0))
	end
	return addFace(body, 0.72, add)
end

PetBuilders.Cloud = function(item, c, add)
	local body = ball(1.4, c[1], materialOf(item))
	add(body, CFrame.new())
	add(ball(1.0, c[2] or c[1]), CFrame.new(-0.8, -0.15, 0))
	add(ball(1.0, c[2] or c[1]), CFrame.new(0.8, -0.15, 0))
	add(ball(0.9, c[1]), CFrame.new(0.35, 0.5, 0.2))
	return addFace(body, 0.62, add)
end

PetBuilders.Ufo = function(item, c, add)
	local body = cylinder(0.4, 2.3, c[1], Enum.Material.Metal)
	add(body, UP)
	local dome = ball(1.1, c[2] or c[1], Enum.Material.Glass)
	dome.Transparency = 0.35
	add(dome, CFrame.new(0, 0.3, 0))
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		add(ball(0.2, Color3.fromHSV(i / 6, 0.6, 1), Enum.Material.Neon), CFrame.new(math.cos(a) * 1.05, -0.05, math.sin(a) * 1.05))
	end
	for _, side in { -1, 1 } do
		add(ball(0.18, Color3.fromRGB(30, 30, 40)), CFrame.new(side * 0.18, 0.4, -0.45))
	end
	return body
end

-- ===== appliers ต่อหมวดหมู่ =====

local Appliers = {}

local function bodyColorFor(partName, colors)
	if partName:find("Arm") or partName:find("Hand") then
		return colors[2] or colors[1]
	elseif partName:find("Leg") or partName:find("Foot") then
		return colors[3] or colors[2] or colors[1]
	end
	return colors[1]
end

Appliers.Skin = function(_player, character, state, item)
	if item.Id == "skin_classic" then
		return -- ใช้รูปลักษณ์อวตารเดิมของผู้เล่น
	end
	for _, child in character:GetChildren() do
		if CLOTHING[child.ClassName] then
			child.Parent = state.Stash
		end
	end
	local material = materialOf(item)
	for part in state.Original do
		if part.Parent == character then
			part.Color = bodyColorFor(part.Name, item.Colors)
			part.Material = material
			part.Reflectance = item.Reflectance or 0
			if item.Rainbow then
				CollectionService:AddTag(part, "Rainbow")
			end
		end
	end
end

Appliers.Hat = function(_player, character, state, item)
	local head = character:FindFirstChild("Head")
	local builder = HatBuilders[item.Style]
	if not head or not builder then
		return
	end

	-- ซ่อนหมวกเดิมของอวตารชั่วคราว ไม่ให้ซ้อนกัน
	for _, accessory in character:GetChildren() do
		if accessory:IsA("Accessory") and accessory.AccessoryType == Enum.AccessoryType.Hat then
			local handle = accessory:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") and state.Hidden[handle] == nil then
				state.Hidden[handle] = handle.Transparency
				handle.Transparency = 1
			end
		end
	end

	local model = track(state, Instance.new("Model"))
	model.Name = "CosmeticHat"
	local topOffset = CFrame.new(0, head.Size.Y / 2, 0)
	local base = head.CFrame * topOffset

	builder(item.Colors, function(part, offset, spin)
		part.CFrame = base * offset
		part.Parent = model
		if item.Rainbow then
			CollectionService:AddTag(part, "Rainbow")
		end
		if spin then
			local w = Instance.new("Weld")
			w.Part0 = head
			w.Part1 = part
			w.C0 = topOffset * offset
			w:SetAttribute("BaseC0", w.C0)
			w.Parent = part
			CollectionService:AddTag(w, "SpinWeld")
		else
			weld(head, part)
		end
	end)
	model.Parent = character
end

Appliers.Trail = function(_player, character, state, item)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local top = track(state, Instance.new("Attachment"))
	top.Name = "TrailTop"
	top.Position = Vector3.new(0, 0.9, 0.3)
	top.Parent = root
	local bottom = track(state, Instance.new("Attachment"))
	bottom.Name = "TrailBottom"
	bottom.Position = Vector3.new(0, -0.9, 0.3)
	bottom.Parent = root

	local trail = track(state, Instance.new("Trail"))
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Color = ItemCatalog.GetColorSequence(item)
	trail.Lifetime = 0.7
	trail.MinLength = 0.05
	trail.LightEmission = 0.6
	trail.FaceCamera = true
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	trail.Parent = root
end

Appliers.Aura = function(_player, character, state, item)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local colors = item.Colors
	if item.Style == "Fire" then
		local fire = track(state, Instance.new("Fire"))
		fire.Color = colors[1]
		fire.SecondaryColor = colors[2] or colors[1]
		fire.Size = 3
		fire.Heat = 4
		fire.Parent = root
	elseif item.Style == "Sparkles" then
		local sparkles = track(state, Instance.new("Sparkles"))
		sparkles.SparkleColor = colors[1]
		sparkles.Parent = root
	else
		local emitter = track(state, Instance.new("ParticleEmitter"))
		emitter.Color = ItemCatalog.GetColorSequence(item)
		emitter.Rate = 14
		emitter.Lifetime = NumberRange.new(1, 1.8)
		emitter.Speed = NumberRange.new(1, 2.5)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-90, 90)
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Parent = root
	end
end

Appliers.Pet = function(player, character, state, item)
	local root = character:FindFirstChild("HumanoidRootPart")
	local builder = PetBuilders[item.Style]
	if not root or not builder then
		return
	end

	local model = Instance.new("Model")
	model.Name = player.Name .. "_Pet"
	local start = root.CFrame * CFrame.new(2.5, 1.5, 2.5)
	local parts = {}
	local body = builder(item, item.Colors, function(part, offset)
		part.CFrame = start * offset
		part.Parent = model
		table.insert(parts, part)
		if item.Rainbow then
			CollectionService:AddTag(part, "Rainbow")
		end
	end)
	for _, part in parts do
		if part ~= body then
			weld(body, part)
		end
	end
	body.Massless = false
	model.PrimaryPart = body

	local petAttachment = Instance.new("Attachment")
	petAttachment.CFrame = body.CFrame:ToObjectSpace(start) -- ให้แกนของ pet ตรงกับผู้เล่นเสมอ (เช่น UFO ที่ body หมุนอยู่)
	petAttachment.Parent = body
	local target = track(state, Instance.new("Attachment"))
	target.Name = "PetTarget"
	target.Position = Vector3.new(2.5, 1.5, 2.5)
	target.Parent = root

	local align = Instance.new("AlignPosition")
	align.Attachment0 = petAttachment
	align.Attachment1 = target
	align.MaxForce = 1e6
	align.Responsiveness = 18
	align.Parent = body

	local orient = Instance.new("AlignOrientation")
	orient.Attachment0 = petAttachment
	orient.Attachment1 = target
	orient.MaxTorque = 1e6
	orient.Responsiveness = 18
	orient.Parent = body

	model.Parent = petsFolder
	pcall(function()
		body:SetNetworkOwner(player)
	end)
	state.Pet = model
end

-- ===== ป้าย VIP บนหัว =====

local function addVipTag(character, state)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local gui = track(state, Instance.new("BillboardGui"))
	gui.Name = "VipTag"
	gui.Size = UDim2.fromOffset(120, 32)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 80
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = "👑 VIP"
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 215, 40)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = head
end

-- ===== state management =====

local function restore(state)
	for _, instance in state.Created do
		instance:Destroy()
	end
	table.clear(state.Created)

	if state.Pet then
		state.Pet:Destroy()
		state.Pet = nil
	end

	for _, child in state.Stash:GetChildren() do
		child.Parent = state.Character
	end

	for part, original in state.Original do
		if part.Parent then
			part.Color = original.Color
			part.Material = original.Material
			part.Reflectance = original.Reflectance
			CollectionService:RemoveTag(part, "Rainbow")
		end
	end

	for handle, transparency in state.Hidden do
		if handle.Parent then
			handle.Transparency = transparency
		end
	end
	table.clear(state.Hidden)
end

local function destroyState(player)
	local state = states[player]
	if not state then
		return
	end
	for _, instance in state.Created do
		instance:Destroy()
	end
	if state.Pet then
		state.Pet:Destroy()
	end
	state.Stash:Destroy()
	states[player] = nil
end

function CosmeticService.Apply(player)
	local state = states[player]
	local character = player.Character
	if not state or not character or state.Character ~= character then
		return
	end
	restore(state)

	local data = DataService.Get(player)
	if not data then
		return
	end

	for _, category in ItemCatalog.Categories do
		local itemId = data.Equipped[category.Id]
		local item = itemId and ItemCatalog.ById[itemId]
		if item and data.Owned[itemId] and item.Category == category.Id then
			local ok, err = pcall(Appliers[category.Id], player, character, state, item)
			if not ok then
				warn("[CosmeticService] ใส่", itemId, "ไม่สำเร็จ:", err)
			end
		end
	end

	if player:GetAttribute("VIP") then
		addVipTag(character, state)
	end
end

local function onCharacter(player, character)
	destroyState(player)

	-- รอให้อวตารโหลดครบก่อน (สีผิว/เสื้อผ้า) เพื่อจำค่าเดิมไว้คืนได้
	local waited = 0
	while not player:HasAppearanceLoaded() and waited < 6 do
		waited += task.wait(0.1)
	end
	if player.Character ~= character or not character.Parent then
		return
	end

	local stash = Instance.new("Folder")
	stash.Name = tostring(player.UserId)
	stash.Parent = stashRoot

	local original = {}
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			original[part] = { Color = part.Color, Material = part.Material, Reflectance = part.Reflectance }
		end
	end

	states[player] = {
		Character = character,
		Original = original,
		Stash = stash,
		Hidden = {},
		Created = {},
		Pet = nil,
	}

	-- รอข้อมูลโหลดเสร็จ แล้วสวมใส่
	while not DataService.Get(player) and player.Parent do
		task.wait(0.2)
	end
	CosmeticService.Apply(player)
end

function CosmeticService.Init()
	petsFolder = Instance.new("Folder")
	petsFolder.Name = "Pets"
	petsFolder.Parent = workspace

	stashRoot = Instance.new("Folder")
	stashRoot.Name = "CosmeticStash"
	stashRoot.Parent = ServerStorage

	local function onPlayer(player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(destroyState)
end

return CosmeticService
