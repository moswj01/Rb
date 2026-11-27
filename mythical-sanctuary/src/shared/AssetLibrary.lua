--[[
	AssetLibrary — สร้างโมเดลจาก Key
	ลำดับการค้นหา:
	  1) ReplicatedStorage/Assets/<Key>   ← โมเดลจริงจาก 3D Artist (MeshPart + SurfaceAppearance)
	  2) Greybox Blockout                ← ทรงหยาบสีดินเหนียว ติดแท็ก "Placeholder"

	Greybox ใช้สำหรับทดสอบ scale/gameplay/composition เท่านั้น
	ตรวจว่ายังเหลือ Placeholder กี่ชิ้น: AssetLibrary.Report() (พิมพ์รายการ Key ที่ยังขาด)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local AssetRegistry = require(script.Parent.AssetRegistry)

local AssetLibrary = {}

local CLAY = Color3.fromRGB(196, 184, 168)
local CLAY_DARK = Color3.fromRGB(150, 140, 128)
local CLAY_GREEN = Color3.fromRGB(150, 170, 140)
local missing = {}

local function assetsFolder()
	return ReplicatedStorage:FindFirstChild("Assets")
end

local function part(props, parent, meshType)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Color = CLAY
	for k, v in props do
		p[k] = v
	end
	if meshType then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = meshType
		mesh.Parent = p
	end
	p.Parent = parent
	return p
end

local UP = CFrame.Angles(0, 0, math.rad(90))

-- ===== Greybox builders (ขนาดอิง Size ใน AssetRegistry, ฐานอยู่ที่ y = 0) =====
local Builders = {}

Builders.Tree = function(model, s)
	local trunkH = s.Y * 0.55
	local trunkD = math.max(1.5, s.X * 0.16)
	part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(trunkH, trunkD, trunkD), CFrame = CFrame.new(0, trunkH / 2, 0) * UP, Color = CLAY_DARK, CanCollide = true }, model)
	local canopy = math.max(s.X, s.Z)
	part({ Name = "Canopy", Size = Vector3.new(canopy, s.Y * 0.5, canopy), CFrame = CFrame.new(0, s.Y * 0.68, 0), Color = CLAY_GREEN, CanCollide = false, CastShadow = true }, model, Enum.MeshType.Sphere)
	part({ Name = "Canopy2", Size = Vector3.new(canopy * 0.7, s.Y * 0.35, canopy * 0.7), CFrame = CFrame.new(canopy * 0.18, s.Y * 0.88, -canopy * 0.1), Color = CLAY_GREEN, CanCollide = false }, model, Enum.MeshType.Sphere)
	-- รากแผ่ (บอกตำแหน่งราก สำหรับ Artist)
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2
		part({ Name = "Root", Size = Vector3.new(trunkD * 0.6, trunkD * 0.5, trunkD * 1.6), CFrame = CFrame.new(math.cos(a) * trunkD * 0.6, trunkD * 0.15, math.sin(a) * trunkD * 0.6) * CFrame.Angles(0, -a, 0), Color = CLAY_DARK, CanCollide = false }, model, Enum.MeshType.Sphere)
	end
end

Builders.Bush = function(model, s)
	part({ Name = "Body", Size = s, CFrame = CFrame.new(0, s.Y / 2, 0), Color = CLAY_GREEN, CanCollide = false, CanQuery = false, CastShadow = false }, model, Enum.MeshType.Sphere)
end

Builders.Rock = function(model, s)
	part({ Name = "Body", Size = s, CFrame = CFrame.new(0, s.Y * 0.4, 0) * CFrame.Angles(0, 0.4, 0.08), Color = CLAY_DARK, CanCollide = true }, model, Enum.MeshType.Sphere)
	part({ Name = "Body2", Size = s * Vector3.new(0.6, 0.7, 0.6), CFrame = CFrame.new(s.X * 0.3, s.Y * 0.3, s.Z * 0.15), Color = CLAY_DARK, CanCollide = false }, model, Enum.MeshType.Sphere)
end

Builders.Mushroom = function(model, s, def)
	part({ Name = "Stem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(s.Y * 0.6, s.X * 0.25, s.X * 0.25), CFrame = CFrame.new(0, s.Y * 0.3, 0) * UP, Color = CLAY, CanCollide = false, CanQuery = false }, model)
	local cap = part({ Name = "Cap", Size = Vector3.new(s.X, s.Y * 0.45, s.Z), CFrame = CFrame.new(0, s.Y * 0.65, 0), Color = def.Glow or CLAY, Material = def.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false }, model, Enum.MeshType.Sphere)
	cap.Transparency = def.Glow and 0.25 or 0
end

Builders.Building = function(model, s)
	local wallH = s.Y * 0.55
	part({ Name = "Walls", Size = Vector3.new(s.X, wallH, s.Z), CFrame = CFrame.new(0, wallH / 2, 0), Color = CLAY, CanCollide = true }, model)
	part({ Name = "Roof", Size = Vector3.new(s.X * 1.15, s.Y * 0.5, s.Z * 1.15), CFrame = CFrame.new(0, wallH + s.Y * 0.18, 0), Color = CLAY_DARK, CanCollide = true }, model, Enum.MeshType.Sphere)
	part({ Name = "Door", Size = Vector3.new(4, 7, 0.4), CFrame = CFrame.new(0, 3.5, -s.Z / 2 - 0.1), Color = CLAY_DARK, CanCollide = false }, model)
end

Builders.Tower = function(model, s)
	part({ Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(s.Y * 0.8, s.X, s.Z), CFrame = CFrame.new(0, s.Y * 0.4, 0) * UP, Color = CLAY, CanCollide = true }, model)
	part({ Name = "Clock", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, s.X * 0.6, s.X * 0.6), CFrame = CFrame.new(0, s.Y * 0.68, -s.Z / 2) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(230, 220, 190), CanCollide = false }, model)
	part({ Name = "Spire", Size = Vector3.new(s.X * 1.1, s.Y * 0.3, s.Z * 1.1), CFrame = CFrame.new(0, s.Y * 0.88, 0), Color = CLAY_DARK, CanCollide = true }, model, Enum.MeshType.Sphere)
end

Builders.Bridge = function(model, s)
	for i = 0, 6 do
		local t = i / 6
		local y = math.sin(t * math.pi) * s.Y * 0.4
		part({ Name = "Deck", Size = Vector3.new(s.X / 6.5, 1.6, s.Z), CFrame = CFrame.new((t - 0.5) * s.X, y + 2, 0) * CFrame.Angles(0, 0, math.cos(t * math.pi) * -0.35), Color = CLAY, CanCollide = true }, model)
	end
end

Builders.Arch = function(model, s, def)
	for _, side in { -1, 1 } do
		part({ Name = "Pillar", Size = Vector3.new(s.X * 0.16, s.Y * 0.85, s.Z), CFrame = CFrame.new(side * s.X * 0.42, s.Y * 0.42, 0), Color = CLAY, CanCollide = true }, model)
	end
	part({ Name = "Lintel", Size = Vector3.new(s.X, s.Y * 0.22, s.Z * 1.1), CFrame = CFrame.new(0, s.Y * 0.88, 0), Color = CLAY_DARK, CanCollide = true }, model, Enum.MeshType.Sphere)
	if def.Glow then
		local surface = part({ Name = "PortalSurface", Size = Vector3.new(s.X * 0.66, s.Y * 0.72, 0.4), CFrame = CFrame.new(0, s.Y * 0.4, 0), Color = def.Glow, Material = Enum.Material.Neon, Transparency = 0.55, CanCollide = false }, model)
		surface:SetAttribute("Portal", true)
	end
end

Builders.Ruins = function(model, s)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local h = s.Y * (0.4 + (i % 3) * 0.25)
		part({ Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 4, 4), CFrame = CFrame.new(math.cos(a) * s.X * 0.4, h / 2, math.sin(a) * s.Z * 0.4) * UP, Color = CLAY, CanCollide = true }, model)
	end
	part({ Name = "Altar", Size = Vector3.new(10, 4, 6), CFrame = CFrame.new(0, 2, 0), Color = CLAY_DARK, CanCollide = true }, model)
end

Builders.Crystal = function(model, s, def)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		local h = s.Y * (0.5 + (i % 2) * 0.4)
		part({ Name = "Crystal", Size = Vector3.new(2.4, h, 2.4), CFrame = CFrame.new(math.cos(a) * 3, h / 2, math.sin(a) * 3) * CFrame.Angles(math.cos(a) * 0.3, 0, math.sin(a) * 0.3), Color = def.Glow or CLAY, Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false }, model)
	end
end

Builders.Waterfall = function(model, s)
	local sheet = part({ Name = "WaterSheet", Size = Vector3.new(s.X, s.Y, 1), CFrame = CFrame.new(0, s.Y / 2, 0), Color = Color3.fromRGB(170, 220, 235), Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false }, model)
	local mist = Instance.new("ParticleEmitter")
	mist.Rate = 18
	mist.Lifetime = NumberRange.new(2, 3)
	mist.Speed = NumberRange.new(2, 5)
	mist.SpreadAngle = Vector2.new(60, 20)
	mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 10) })
	mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	mist.EmissionDirection = Enum.NormalId.Front
	mist.Parent = sheet
end

Builders.Stall = function(model, s)
	part({ Name = "Counter", Size = Vector3.new(s.X, s.Y * 0.35, s.Z * 0.5), CFrame = CFrame.new(0, s.Y * 0.18, 0), Color = CLAY, CanCollide = true }, model)
	part({ Name = "Canopy", Size = Vector3.new(s.X * 1.1, s.Y * 0.2, s.Z), CFrame = CFrame.new(0, s.Y * 0.85, 0), Color = CLAY_DARK, CanCollide = false }, model, Enum.MeshType.Sphere)
end

Builders.Habitat = function(model, s, def)
	part({ Name = "Mound", Size = s, CFrame = CFrame.new(0, s.Y * 0.35, 0), Color = CLAY_GREEN, CanCollide = true }, model, Enum.MeshType.Sphere)
	part({ Name = "Entrance", Size = Vector3.new(s.X * 0.35, s.Y * 0.5, 1), CFrame = CFrame.new(0, s.Y * 0.25, -s.Z * 0.45), Color = Color3.fromRGB(60, 50, 44), CanCollide = false }, model, Enum.MeshType.Sphere)
	if def.Glow then
		part({ Name = "Glow", Size = Vector3.one * 1.2, CFrame = CFrame.new(0, s.Y * 0.8, 0), Color = def.Glow, Material = Enum.Material.Neon, CanCollide = false }, model, Enum.MeshType.Sphere)
	end
end

Builders.Pond = function(model, s)
	part({ Name = "Water", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, s.X, s.Z), CFrame = CFrame.new(0, 0.3, 0) * UP, Color = Color3.fromRGB(90, 170, 190), Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false }, model)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		part({ Name = "Stone", Size = Vector3.new(2.2, 1.2, 1.6), CFrame = CFrame.new(math.cos(a) * s.X * 0.5, 0.5, math.sin(a) * s.Z * 0.5) * CFrame.Angles(0, -a, 0), Color = CLAY_DARK, CanCollide = false }, model, Enum.MeshType.Sphere)
	end
end

Builders.Lantern = function(model, s, def)
	part({ Name = "Lantern", Size = s, CFrame = CFrame.new(0, 6, 0), Color = def.Glow or CLAY, Material = Enum.Material.Neon, Transparency = 0.2, CanCollide = false }, model, Enum.MeshType.Sphere)
end

Builders.Prop = function(model, s, def)
	part({ Name = "Body", Size = s, CFrame = CFrame.new(0, s.Y / 2, 0), Color = CLAY, CanCollide = true }, model, Enum.MeshType.Sphere)
	if def.Glow then
		part({ Name = "Glow", Size = Vector3.new(s.X * 0.7, 0.4, s.Z * 0.7), CFrame = CFrame.new(0, s.Y * 0.92, 0), Color = def.Glow, Material = Enum.Material.Neon, CanCollide = false }, model, Enum.MeshType.Sphere)
	end
end

local function decorate(model, def)
	-- แสงไฟหน้าต่าง/โคม (ใช้กับโมเดลจริงด้วย ถ้า Artist ไม่ได้ใส่ไฟเอง)
	if (def.Light or def.Glow) and not model:FindFirstChildWhichIsA("Light", true) then
		local anchor = Instance.new("Part")
		anchor.Name = "LightAnchor"
		anchor.Size = Vector3.one * 0.2
		anchor.Transparency = 1
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.CFrame = model:GetPivot() * CFrame.new(0, def.Size.Y * 0.35, 0)
		anchor.Parent = model
		local light = Instance.new("PointLight")
		light.Color = def.Glow or Color3.fromRGB(255, 196, 120)
		light.Range = math.clamp(def.Size.Magnitude * 0.6, 8, 28)
		light.Brightness = def.Glow and 1.2 or 0.9
		light.Shadows = false
		light.Parent = anchor
		CollectionService:AddTag(light, "NightLight") -- client เปิด/ปิดตามเวลา + ระดับกราฟิก
	end
end

local function buildGreybox(key, def)
	local model = Instance.new("Model")
	model.Name = key
	local builder = Builders[def.Shape] or Builders.Prop
	builder(model, def.Size, def)
	model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	model:SetAttribute("Placeholder", true)
	model:SetAttribute("Spec", def.Spec)
	CollectionService:AddTag(model, "Placeholder")
	missing[key] = (missing[key] or 0) + 1
	return model
end

-- คืนค่า Model ที่ตั้ง pivot (ฐานกึ่งกลาง) ไว้ที่ cframe แล้ว
AssetLibrary.Aliases = {
	Building_FeedShop = "Building_House_Medium_",
	Building_Apothecary = "Building_House_Medium_",
	Building_Library = "Building_House_Large_",
	Sanctuary_Cottage = "Building_House_",
	Landmark_ElderTree = "Tree_Ancient_",
	Tree_Ancient_A = "Tree_Forest_",
	Tree_Ancient_B = "Tree_Forest_",
	Tree_Ancient_C = "Tree_Forest_",
	Tree_Village_A = "Tree_Forest_",
	Tree_Village_B = "Tree_Forest_",
	Forage_silverfern = "Plant_Fern_",
	Forage_honeyroot = "Plant_Fern_",
	Forage_dewcap = "Mushroom_Glow_",
	Forage_wisp_lily = "Mushroom_Glow_",
	Prop_GlowcapCluster = "Mushroom_Glow_",
	Prop_ShrineStone = "Rock_Moss_",
	Landmark_SanctuaryGate = "Landmark_NorthGate",
	Sanctuary_ReturnGate = "Landmark_NorthGate",
	Prop_CaveEntrance = "Rock_Moss_",
	Sanctuary_Cauldron = "Prop_Cauldron_Public",
}

-- หาโมเดลจริง: ชื่อตรง Key ก่อน ถ้าไม่มีใช้ "ครอบครัวเดียวกัน" (เช่น Tree_Forest_B → Tree_Forest_A)
-- ทำให้ใส่โมเดลแค่ไม่กี่ชิ้นก็เติมทั้งแมพได้ — คืนค่า (source, sourceKey)
local function findSource(key)
	local folder = assetsFolder()
	if not folder then
		return nil
	end
	local exact = folder:FindFirstChild(key)
	if exact then
		return exact, key
	end
	local parts = string.split(key, "_")
	for keep = #parts - 1, 2, -1 do
		local prefix = table.concat(parts, "_", 1, keep) .. "_"
		local candidates = {}
		for _, child in folder:GetChildren() do
			if child:IsA("Model") and string.sub(child.Name, 1, #prefix) == prefix then
				table.insert(candidates, child)
			end
		end
		if #candidates > 0 then
			table.sort(candidates, function(a, b)
				return a.Name < b.Name
			end)
			-- เลือกตัวแปรแบบคงที่ต่อ Key (ไม่สุ่มทุกครั้งที่เปิดเกม)
			local hash = 0
			for i = 1, #key do
				hash = (hash * 31 + string.byte(key, i)) % 1000003
			end
			local chosen = candidates[hash % #candidates + 1]
			return chosen, chosen.Name
		end
	end
	-- นามแฝง: ถ้าไม่มีโมเดลเฉพาะ ใช้หมวดที่ใกล้เคียง (เช่น ร้านค้า → บ้านขนาดกลาง)
	local alias = AssetLibrary.Aliases[key]
	if alias then
		for _, child in folder:GetChildren() do
			if child:IsA("Model") and string.sub(child.Name, 1, #alias) == alias then
				return child, child.Name
			end
		end
	end
	return nil
end

-- ป้องกันโมเดลฟรีที่แฝงสคริปต์ (backdoor) — ลบสคริปต์ทุกชนิดออกก่อนใช้
local function sanitize(model)
	for _, d in model:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
end

function AssetLibrary.Create(key, cframe, scale)
	local def = AssetRegistry.Get(key) or { Size = Vector3.new(4, 4, 4), Shape = "Prop", Spec = "UNSPECIFIED" }
	local source, sourceKey = findSource(key)
	local model
	if source then
		model = source:Clone()
		sanitize(model)
		model:SetAttribute("Placeholder", nil)
		-- ใช้โมเดลของ Key อื่นในครอบครัว → ปรับขนาดให้ตรงความสูงที่ Key นี้ต้องการ
		local sourceDef = sourceKey ~= key and AssetRegistry.Get(sourceKey)
		if sourceDef and sourceDef.Size.Y > 0 then
			scale = (scale or 1) * def.Size.Y / sourceDef.Size.Y
		end
	else
		model = buildGreybox(key, def)
	end
	model:SetAttribute("AssetKey", key)
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- สตรีมทั้งชิ้น ไม่โผล่ครึ่ง ๆ
	end)
	if not source then
		model.WorldPivot = CFrame.new() -- Greybox สร้างที่ origin (ฐาน y=0)
	end
	if scale and scale ~= 1 then
		pcall(function()
			model:ScaleTo(scale)
		end)
	end
	model:PivotTo(cframe or CFrame.new())
	decorate(model, def)
	return model
end

-- ปรับโมเดลที่ลากใส่ ReplicatedStorage/Assets เองโดยตรง (ไม่ได้ผ่าน AssetTools.Register)
-- ลบสคริปต์ · Anchor · ปรับขนาดให้ความสูงตรงสเปก · Pivot ฐานกึ่งกลาง — เรียกครั้งเดียวที่เซิร์ฟเวอร์ตอนเริ่มเกม
function AssetLibrary.NormalizeAll()
	local folder = assetsFolder()
	if not folder then
		return 0
	end
	local count = 0
	for _, child in folder:GetChildren() do
		local def = AssetRegistry.Get(child.Name)
		if child:IsA("Model") and def and not child:GetAttribute("Normalized") and child:FindFirstChildWhichIsA("BasePart", true) then
			sanitize(child)
			child.PrimaryPart = nil
			child.WorldPivot = CFrame.new(child.WorldPivot.Position)
			local _, size = child:GetBoundingBox()
			local factor = def.Size.Y / math.max(size.Y, 0.01)
			local footprint = math.max(size.X, size.Z) * factor
			local allowed = math.max(def.Size.X, def.Size.Z) * 1.6
			if footprint > allowed then
				factor *= allowed / footprint
			end
			if not child:GetAttribute("Source") then -- Register แล้วไม่ต้องย่อซ้ำ
				pcall(function()
					child:ScaleTo(child:GetScale() * factor)
				end)
			end
			local cf, newSize = child:GetBoundingBox()
			child.WorldPivot = CFrame.new(cf.Position.X, cf.Position.Y - newSize.Y / 2, cf.Position.Z)
			child:SetAttribute("Normalized", true)
			count += 1
		end
	end
	return count
end

function AssetLibrary.IsPlaceholder(model)
	return model:GetAttribute("Placeholder") == true
end

-- รายงาน Asset ที่ยังเป็น Greybox (ใช้ใน Studio Command Bar)
function AssetLibrary.Report()
	local keys = {}
	for key, count in missing do
		table.insert(keys, string.format("%-28s x%-4d %s", key, count, (AssetRegistry.Get(key) or {}).Spec or ""))
	end
	table.sort(keys)
	print(string.format("[AssetLibrary] Greybox ที่ยังรอโมเดลจริง: %d ชนิด", #keys))
	for _, line in keys do
		print("  " .. line)
	end
	return keys
end

return AssetLibrary
