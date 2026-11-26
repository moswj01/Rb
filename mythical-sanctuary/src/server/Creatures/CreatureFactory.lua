--[[
	CreatureFactory — สร้างโมเดลสัตว์ตาม (สายพันธุ์ × ช่วงวัย)
	1) ReplicatedStorage/Assets/Creature_<species>_<Stage>  ← โมเดล+Rig+Animation จริง (ตาม CRE-RIG)
	2) Greybox: ทรงหยาบตามสัดส่วนสายพันธุ์ + สีจาก Palette (ติดแท็ก Placeholder)
	ช่วงวัยในงานจริงต้องเปลี่ยนสัดส่วน (หัวโต/ขาสั้นตอนเด็ก) ไม่ใช่แค่ย่อขนาด — greybox จำลองหลักนี้ไว้ด้วย
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Species = require(Shared.Species)
local AssetRegistry = require(Shared.AssetRegistry)

local CreatureFactory = {}

-- สัดส่วนต่อสายพันธุ์ (หน่วย studs ที่ Adult) — Baby หัวใหญ่ขึ้น ตัว/ขาสั้นลง
local BODY = {
	spirit_kitsune = { Body = Vector3.new(2.2, 2, 4), Head = 1.9, Leg = 1.8, Ears = "Pointed", Tails = 3, Glow = true },
	lunar_stag = { Body = Vector3.new(2.6, 2.6, 5.4), Head = 1.8, Leg = 3.6, Ears = "Antlers", Tails = 1, Glow = true },
	treasure_mole = { Body = Vector3.new(2.8, 2.2, 3.2), Head = 1.8, Leg = 0.7, Ears = "None", Tails = 1, Glow = false },
}

local function weldTo(root, part)
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = part
	w.Parent = part
end

local function shape(model, root, name, size, offset, color, material, mesh)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = root.CFrame * offset
	if mesh ~= false then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	end
	p.Parent = model
	weldTo(root, p)
	return p
end

local function stageFactors(stage)
	if stage == "Baby" then
		return { Scale = 0.5, Head = 1.45, Leg = 0.65, Body = 0.9 }
	elseif stage == "Juvenile" then
		return { Scale = 0.75, Head = 1.15, Leg = 0.85, Body = 0.95 }
	end
	return { Scale = 1, Head = 1, Leg = 1, Body = 1 }
end

local function buildEgg(speciesDef)
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2.6, 2)
	root.Anchored = true
	root.CanCollide = false
	root.Color = speciesDef.Palette.Primary
	root.Material = Enum.Material.SmoothPlastic
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = root
	root.Parent = model
	shape(model, root, "Spots", Vector3.new(2.05, 1, 2.05), CFrame.new(0, 0.3, 0), speciesDef.Palette.Secondary, Enum.Material.Neon).Transparency = 0.5
	model.PrimaryPart = root
	return model
end

local function buildGreybox(speciesId, stage)
	local def = Species.ById[speciesId]
	local body = BODY[speciesId] or BODY.treasure_mole
	if stage == "Egg" then
		return buildEgg(def)
	end
	local f = stageFactors(stage)
	local s = f.Scale
	local pal = def.Palette

	local model = Instance.new("Model")
	local legH = body.Leg * f.Leg * s
	local bodySize = body.Body * f.Body * s
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(bodySize.X, bodySize.Y, bodySize.Z)
	root.Transparency = 1
	root.CanCollide = true
	root.CanQuery = true
	root.CFrame = CFrame.new(0, legH + bodySize.Y / 2, 0)
	root.Parent = model
	model.PrimaryPart = root

	local primary, secondary, accent = pal.Primary, pal.Secondary, pal.Accent
	shape(model, root, "Body", bodySize, CFrame.new(), primary)
	shape(model, root, "Belly", bodySize * Vector3.new(0.8, 0.6, 0.85), CFrame.new(0, -bodySize.Y * 0.15, 0), secondary)
	local headSize = body.Head * f.Head * s
	local headOffset = CFrame.new(0, bodySize.Y * 0.45, -bodySize.Z * 0.5)
	local head = shape(model, root, "Head", Vector3.one * headSize, headOffset, primary)
	head.Name = "Head"
	shape(model, root, "Snout", Vector3.new(headSize * 0.5, headSize * 0.4, headSize * 0.6), headOffset * CFrame.new(0, -headSize * 0.12, -headSize * 0.45), secondary)
	for _, side in { -1, 1 } do
		local eye = shape(model, root, "Eye", Vector3.one * headSize * 0.2, headOffset * CFrame.new(side * headSize * 0.25, headSize * 0.1, -headSize * 0.42), Color3.fromRGB(30, 30, 40))
		eye:SetAttribute("Eye", true)
		if body.Ears == "Pointed" then
			shape(model, root, "Ear", Vector3.new(headSize * 0.28, headSize * 0.6, headSize * 0.14), headOffset * CFrame.new(side * headSize * 0.3, headSize * 0.55, 0) * CFrame.Angles(0, 0, math.rad(-side * 15)), primary)
		elseif body.Ears == "Antlers" and stage ~= "Baby" then
			local antler = shape(model, root, "Antler", Vector3.new(headSize * 0.14, headSize * (stage == "Adult" and 1.4 or 0.7), headSize * 0.14), headOffset * CFrame.new(side * headSize * 0.25, headSize * 0.9, 0.1) * CFrame.Angles(0, 0, math.rad(-side * 25)), accent, Enum.Material.Neon)
			antler.Transparency = 0.15
		end
	end
	-- ขา 4 ข้าง (ตำแหน่งบอก Artist ว่าข้อต่ออยู่ไหน)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			shape(model, root, "Leg", Vector3.new(bodySize.X * 0.22, legH + bodySize.Y * 0.3, bodySize.X * 0.22), CFrame.new(x * bodySize.X * 0.32, -(bodySize.Y / 2 + legH / 2) + bodySize.Y * 0.15, z * bodySize.Z * 0.3), primary, nil, false)
		end
	end
	-- หาง
	for i = 1, body.Tails do
		local spread = (i - (body.Tails + 1) / 2) * 0.45
		local tail = shape(model, root, "Tail", Vector3.new(bodySize.X * 0.3, bodySize.X * 0.3, bodySize.Z * 0.6), CFrame.new(spread * bodySize.X * 0.5, bodySize.Y * 0.25, bodySize.Z * 0.6) * CFrame.Angles(math.rad(35), spread, 0), body.Glow and secondary or primary, body.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic)
		if body.Glow then
			tail.Transparency = 0.2
		end
	end
	if body.Glow then
		local light = Instance.new("PointLight")
		light.Color = secondary
		light.Range = 10 * s
		light.Brightness = 0.8
		light.Parent = root
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = legH
	humanoid.Parent = model
	return model
end

function CreatureFactory.Create(speciesId, stage)
	local key = AssetRegistry.CreatureModelKey(speciesId, stage)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local source = assets and assets:FindFirstChild(key)
	local model
	if source then
		model = source:Clone()
	else
		model = buildGreybox(speciesId, stage)
		model:SetAttribute("Placeholder", true)
		CollectionService:AddTag(model, "Placeholder")
	end
	model.Name = key
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	model:SetAttribute("Species", speciesId)
	model:SetAttribute("Stage", stage)
	CollectionService:AddTag(model, "Creature")

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.BreakJointsOnDeath = false
		humanoid.RequiresNeck = false
		for _, state in { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Dead, Enum.HumanoidStateType.Seated } do
			humanoid:SetStateEnabled(state, false)
		end
		if not humanoid:FindFirstChildOfClass("Animator") then
			Instance.new("Animator").Parent = humanoid
		end
	end
	return model
end

return CreatureFactory
