--[[
	CosmeticBuilders — สร้างโมเดลไอเท็มทั้งหมดจาก Part (ใช้ร่วมกันทั้ง Server และ Client)
	- Server: สร้างแล้วเชื่อม (weld) เข้ากับตัวละคร
	- Client: สร้างแบบ anchored เพื่อโชว์ 3D ในร้านค้า (ViewportFrame)

	ระบบ "Pivot": ชิ้นส่วนที่ต้องขยับ (ปีกกระพือ, ใบพัดหมุน, ออร่าโคจร) จะต่อกับ Pivot
	ที่เชื่อมด้วย Weld + แท็ก "FlapWeld"/"SpinWeld" ให้ Effects.lua ฝั่ง client ขยับให้ลื่น ๆ
]]

local CollectionService = game:GetService("CollectionService")

local ItemCatalog = require(script.Parent.ItemCatalog)

local CB = {}

local UP = CFrame.Angles(0, 0, math.rad(90)) -- Cylinder แกนตั้ง
local R = math.rad
local BLACK = Color3.fromRGB(30, 30, 40)
local WHITE = Color3.new(1, 1, 1)
local BLUSH = Color3.fromRGB(255, 150, 175)

-- ================= primitive helpers =================

local function P(props, className)
	local part = Instance.new(className or "Part")
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

local function mat(name, fallback)
	if name and Enum.Material[name] then
		return Enum.Material[name]
	end
	return fallback or Enum.Material.SmoothPlastic
end

local function ball(size, color, material)
	return P({ Shape = Enum.PartType.Ball, Size = Vector3.one * size, Color = color, Material = material or Enum.Material.SmoothPlastic })
end

local function cyl(height, diameter, color, material)
	return P({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, diameter, diameter), Color = color, Material = material or Enum.Material.SmoothPlastic })
end

local function block(size, color, material)
	return P({ Size = size, Color = color, Material = material or Enum.Material.SmoothPlastic })
end

local function ell(size, color, material)
	local part = block(size, color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

local function light(part, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range or 6
	l.Brightness = brightness or 1
	l.Parent = part
	return l
end

local function noRainbow(part)
	part:SetAttribute("NoRainbow", true)
	return part
end

-- ================= build context =================

local function newBuild(item, base)
	local model = Instance.new("Model")
	model.Name = item.Id
	return { Model = model, Base = base, Parts = {}, Pivots = {}, Item = item }
end

local function add(b, part, offset, pivotRec)
	if pivotRec then
		offset = pivotRec.Offset * offset
	end
	part.CFrame = b.Base * offset
	part.Parent = b.Model
	if b.Item.Rainbow and not part:GetAttribute("NoRainbow") and part.Transparency < 1 then
		CollectionService:AddTag(part, "Rainbow")
	end
	table.insert(b.Parts, { Part = part, Pivot = pivotRec and pivotRec.Part })
	return part
end

local function pivot(b, offset, kind, options)
	options = options or {}
	local part = P({ Name = "Pivot", Size = Vector3.one * 0.2, Transparency = 1 })
	part.CFrame = b.Base * offset
	part.Parent = b.Model
	local rec = {
		Part = part,
		Offset = offset,
		Kind = kind,
		Side = options.Side or 1,
		Speed = options.Speed or 1,
		Amp = options.Amp or 0.35,
	}
	table.insert(b.Pivots, rec)
	return rec
end

-- ประกายตามความหายาก (Legendary / Mythic เปล่งประกาย)
local function rarityFx(item, part)
	if item.Rarity ~= "Legendary" and item.Rarity ~= "Mythic" then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = item.Rainbow and ItemCatalog.GetColorSequence(item) or ColorSequence.new(ItemCatalog.Rarities[item.Rarity].Color, WHITE)
	emitter.Rate = item.Rarity == "Mythic" and 6 or 3
	emitter.Lifetime = NumberRange.new(0.8, 1.3)
	emitter.Speed = NumberRange.new(0.4, 1)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	emitter.Parent = part
	if item.Rarity == "Mythic" then
		light(part, ItemCatalog.Rarities.Mythic.Color, 7, 0.8)
	end
end

-- ================= HATS (Base = ยอดหัว, -Z = ด้านหน้า) =================

local Hats = {}

Hats.PartyCone = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	for i = 0, 4 do
		add(b, cyl(0.4, 1.6 - i * 0.3, i % 2 == 0 and c1 or c2), CFrame.new(0, 0.2 + i * 0.38, 0) * UP)
	end
	local pom = add(b, ball(0.55, c2, Enum.Material.Neon), CFrame.new(0, 2.15, 0))
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		add(b, ball(0.18, Color3.fromHSV(i / 6, 0.6, 1)), CFrame.new(math.cos(a) * 0.62, 0.35, math.sin(a) * 0.62))
	end
	return pom
end

Hats.CatEars = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	local last
	for _, s in { -1, 1 } do
		local rot = CFrame.Angles(0, 0, R(45 + s * 8))
		add(b, block(Vector3.new(0.62, 0.62, 0.2), c1), CFrame.new(s * 0.42, 0.08, 0) * rot)
		last = add(b, block(Vector3.new(0.38, 0.38, 0.05), c2), CFrame.new(s * 0.42, 0.08, -0.11) * rot)
	end
	return last
end

Hats.Propeller = function(b, c)
	local c1, c2, c3 = c[1], c[2] or c[1], c[3] or c[1]
	for i = 0, 3 do
		add(b, ell(Vector3.new(1.42, 0.55, 0.7), i % 2 == 0 and c1 or c2), CFrame.new(0, 0.12, 0) * CFrame.Angles(0, R(i * 45), 0))
	end
	add(b, cyl(0.5, 0.14, c3), CFrame.new(0, 0.55, 0) * UP)
	local spin = pivot(b, CFrame.new(0, 0.82, 0), "Spin", { Speed = 14 })
	add(b, block(Vector3.new(2.6, 0.08, 0.34), c3), CFrame.new(), spin)
	add(b, ball(0.25, c1), CFrame.new(0, 0.08, 0), spin)
	return add(b, ell(Vector3.new(0.3, 0.12, 0.3), c2), CFrame.new(0, 0.95, 0))
end

Hats.Bow = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	for _, s in { -1, 1 } do
		local cf = CFrame.new(s * 0.55, 0.35, 0.05) * CFrame.Angles(0, 0, R(s * -18))
		add(b, ell(Vector3.new(1.05, 0.78, 0.38), c1), cf)
		add(b, ell(Vector3.new(0.6, 0.42, 0.1), c2), cf * CFrame.new(s * 0.08, 0, -0.17))
		add(b, block(Vector3.new(0.22, 0.6, 0.06), c1), CFrame.new(s * 0.22, -0.02, 0.32) * CFrame.Angles(0, 0, R(s * 20)))
	end
	return add(b, ball(0.45, c1), CFrame.new(0, 0.33, 0.02))
end

Hats.Tiara = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	for i = -5, 5 do
		local a = i * 0.26
		local h = 0.05 + (5 - math.abs(i)) * 0.06
		local pearl = add(b, ball(i % 2 == 0 and 0.24 or 0.18, i % 2 == 0 and c2 or c1), CFrame.new(math.sin(a) * 0.64, h, -math.cos(a) * 0.64))
		pearl.Reflectance = 0.25
	end
	add(b, ell(Vector3.new(0.6, 0.62, 0.14), c1, Enum.Material.Glass), CFrame.new(0, 0.55, -0.62))
	for i = -2, 2 do
		add(b, block(Vector3.new(0.07, 0.5, 0.05), c2), CFrame.new(i * 0.1, 0.55, -0.7) * CFrame.Angles(0, 0, R(i * 18)))
	end
	local gem = add(b, ball(0.26, c2, Enum.Material.Neon), CFrame.new(0, 0.95, -0.62))
	light(gem, c1, 5)
	return gem
end

Hats.Helmet = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	local dome = add(b, ball(2.05, c2, Enum.Material.Glass), CFrame.new(0, -0.62, 0))
	dome.Transparency = 0.65
	add(b, cyl(0.36, 1.95, c1), CFrame.new(0, -1.5, 0) * UP)
	add(b, cyl(0.1, 2.0, c2, Enum.Material.Neon), CFrame.new(0, -1.33, 0) * UP)
	add(b, cyl(0.7, 0.08, c1), CFrame.new(0.55, 0.45, 0.1) * CFrame.Angles(0, 0, R(-20)) * UP)
	local tip = add(b, ball(0.22, Color3.fromRGB(255, 70, 70), Enum.Material.Neon), CFrame.new(0.68, 0.8, 0.1))
	light(tip, Color3.fromRGB(255, 70, 70), 5)
	local shine = add(b, ell(Vector3.new(0.35, 0.18, 0.05), WHITE, Enum.Material.Neon), CFrame.new(-0.45, -0.1, -0.98) * CFrame.Angles(0, R(-25), R(30)))
	shine.Transparency = 0.4
	return tip
end

Hats.WitchHat = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	add(b, cyl(0.12, 2.5, c1), CFrame.new(0, 0.06, 0) * UP)
	for i = 0, 5 do
		local d = 1.25 - i * 0.19
		add(b, cyl(0.34, d, c1), CFrame.new(0, 0.25 + i * 0.3, i * i * 0.012) * CFrame.Angles(R(-i * 3), 0, 0) * UP)
	end
	add(b, cyl(0.24, 1.28, c2), CFrame.new(0, 0.28, 0) * UP)
	add(b, block(Vector3.new(0.3, 0.26, 0.06), Color3.fromRGB(255, 215, 60), Enum.Material.Metal), CFrame.new(0, 0.28, -0.64))
	local star = add(b, ball(0.32, c2, Enum.Material.Neon), CFrame.new(0, 2.05, 0.5))
	light(star, c2, 6)
	return star
end

Hats.FlowerCrown = function(b, c)
	local c1, c2, c3 = c[1], c[2] or c[1], c[3] or Color3.fromRGB(120, 210, 120)
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2
		local flowerCf = CFrame.new(math.cos(a) * 0.66, 0.08, math.sin(a) * 0.66) * CFrame.Angles(0, -a - math.pi / 2, 0)
		local petal = (i % 3 == 0) and WHITE or c1
		for k = 0, 4 do
			local pa = k / 5 * math.pi * 2
			add(b, ball(0.2, petal), flowerCf * CFrame.new(math.cos(pa) * 0.13, math.sin(pa) * 0.13, 0.02))
		end
		add(b, ball(0.16, c2), flowerCf * CFrame.new(0, 0, -0.04))
		add(b, ell(Vector3.new(0.3, 0.1, 0.16), c3), CFrame.new(math.cos(a + 0.35) * 0.66, 0.0, math.sin(a + 0.35) * 0.66) * CFrame.Angles(0, -a, 0))
	end
	local center = add(b, ball(0.3, c2, Enum.Material.Neon), CFrame.new(0, 0.3, -0.66))
	light(center, c1, 5)
	return center
end

Hats.Headphones = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	for i = 0, 8 do
		local a = -math.pi / 2 + i / 8 * math.pi
		add(b, block(Vector3.new(0.22, 0.32, 0.32), c1), CFrame.new(math.sin(a) * 0.8, -0.6 + math.cos(a) * 0.8, 0) * CFrame.Angles(0, 0, -a))
	end
	local last
	for _, s in { -1, 1 } do
		add(b, cyl(0.32, 0.8, c1), CFrame.new(s * 0.74, -0.6, 0))
		last = add(b, cyl(0.06, 0.84, c2, Enum.Material.Neon), CFrame.new(s * 0.92, -0.6, 0))
		add(b, ball(0.18, c2, Enum.Material.Neon), CFrame.new(s * 0.95, -0.6, 0))
	end
	add(b, cyl(0.7, 0.08, c1), CFrame.new(-0.72, -0.9, -0.38) * CFrame.Angles(0, R(70), 0))
	add(b, ball(0.16, c2, Enum.Material.Neon), CFrame.new(-0.6, -0.95, -0.7))
	light(last, c2, 6)
	return last
end

Hats.Crown = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	add(b, ball(1.25, c2), CFrame.new(0, 0.15, 0))
	add(b, cyl(0.48, 1.55, c1, Enum.Material.Metal), CFrame.new(0, 0.24, 0) * UP)
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		add(b, ball(0.12, WHITE), CFrame.new(math.cos(a) * 0.78, 0.02, math.sin(a) * 0.78)).Reflectance = 0.3
	end
	local top
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		local tall = i % 2 == 0
		local h = tall and 0.65 or 0.42
		local x, z = math.cos(a) * 0.66, math.sin(a) * 0.66
		add(b, block(Vector3.new(0.26, h, 0.26), c1, Enum.Material.Metal), CFrame.new(x, 0.45 + h / 2, z) * CFrame.Angles(0, -a, R(0)))
		top = add(b, ball(tall and 0.3 or 0.22, tall and c2 or WHITE, Enum.Material.Neon), CFrame.new(x, 0.5 + h, z))
	end
	add(b, ell(Vector3.new(0.4, 0.5, 0.15), Color3.fromRGB(255, 40, 80), Enum.Material.Neon), CFrame.new(0, 0.26, -0.78))
	local cross = add(b, block(Vector3.new(0.12, 0.4, 0.12), c1, Enum.Material.Metal), CFrame.new(0, 1.25, 0))
	add(b, block(Vector3.new(0.3, 0.1, 0.12), c1, Enum.Material.Metal), CFrame.new(0, 1.3, 0))
	light(cross, c1, 7)
	return top
end

Hats.Halo = function(b, c)
	local c1 = c[1]
	local spin = pivot(b, CFrame.new(0, 1.0, 0) * CFrame.Angles(R(8), 0, 0), "Spin", { Speed = 1.2 })
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		add(b, ball(0.26, c1, Enum.Material.Neon), CFrame.new(math.cos(a) * 0.78, 0, math.sin(a) * 0.78), spin)
	end
	local core = add(b, ball(0.1, c1, Enum.Material.Neon), CFrame.new(0, 1.0, 0))
	core.Transparency = 1
	light(core, c1, 8, 2)
	return core
end

-- ================= WINGS (Base = กลางหลัง, +Z = ด้านหลัง) =================

local Wings = {}

local function wingMaterial(item, fallback)
	return mat(item.Material, fallback)
end

Wings.Butterfly = function(b, c, item)
	local c1, c2 = c[1], c[2] or c[1]
	local out
	for _, s in { -1, 1 } do
		local pv = pivot(b, CFrame.new(s * 0.2, 0, 0.1), "Flap", { Side = s, Speed = 3, Amp = 0.45 })
		local upper = CFrame.new(s * 1.0, 0.6, 0.2) * CFrame.Angles(0, 0, R(s * 22))
		local lower = CFrame.new(s * 0.8, -0.55, 0.2) * CFrame.Angles(0, 0, R(s * -28))
		add(b, ell(Vector3.new(1.9, 1.6, 0.08), c1, wingMaterial(item)), upper, pv)
		add(b, ell(Vector3.new(1.1, 0.9, 0.04), c2), upper * CFrame.new(s * 0.1, 0, 0.05), pv)
		add(b, ell(Vector3.new(1.35, 1.2, 0.08), c1, wingMaterial(item)), lower, pv)
		add(b, ell(Vector3.new(0.75, 0.65, 0.04), c2), lower * CFrame.new(s * 0.05, 0, 0.05), pv)
		for k = 1, 3 do
			add(b, ball(0.16, WHITE, Enum.Material.Neon), upper * CFrame.new(s * (0.3 + k * 0.18), 0.35 - k * 0.15, 0.06), pv)
		end
		out = pv.Part
	end
	return out
end

Wings.Fin = function(b, c, item)
	local c1, c2 = c[1], c[2] or c[1]
	local out
	for _, s in { -1, 1 } do
		local pv = pivot(b, CFrame.new(s * 0.2, 0.1, 0.1), "Flap", { Side = s, Speed = 1.5, Amp = 0.3 })
		for k, ang in { 40, 12, -18 } do
			local cf = CFrame.Angles(0, 0, R(s * ang)) * CFrame.new(s * (0.9 - k * 0.05), 0, 0.2)
			local fin = add(b, ell(Vector3.new(1.9 - k * 0.2, 0.55, 0.06), c1, Enum.Material.Glass), cf, pv)
			fin.Transparency = 0.25
			add(b, block(Vector3.new(1.5 - k * 0.2, 0.06, 0.07), c2, Enum.Material.Neon), cf, pv)
		end
		out = pv.Part
	end
	local _ = item
	return out
end

Wings.Jetpack = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	add(b, block(Vector3.new(1.3, 1.5, 0.3), c1, Enum.Material.Metal), CFrame.new(0, 0, 0.15))
	local nozzle
	for _, s in { -1, 1 } do
		add(b, cyl(1.5, 0.62, c1, Enum.Material.Metal), CFrame.new(s * 0.38, 0, 0.5) * UP)
		add(b, ball(0.62, c2), CFrame.new(s * 0.38, 0.75, 0.5))
		add(b, cyl(0.12, 0.66, c2), CFrame.new(s * 0.38, 0.2, 0.5) * UP)
		nozzle = add(b, cyl(0.35, 0.42, BLACK, Enum.Material.Metal), CFrame.new(s * 0.38, -0.9, 0.5) * UP)
		local flame = Instance.new("ParticleEmitter")
		flame.EmissionDirection = Enum.NormalId.Left -- แกน X ของ cylinder ชี้ลง (หลังหมุน UP)
		flame.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 70, 30))
		flame.LightEmission = 1
		flame.Rate = 40
		flame.Speed = NumberRange.new(5, 8)
		flame.Lifetime = NumberRange.new(0.15, 0.3)
		flame.SpreadAngle = Vector2.new(8, 8)
		flame.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) })
		flame.Parent = nozzle
		light(nozzle, Color3.fromRGB(255, 140, 50), 6)
		add(b, P({ Size = Vector3.new(0.08, 0.5, 0.45), Color = c2 }, "WedgePart"), CFrame.new(s * 0.72, -0.55, 0.5))
	end
	return nozzle
end

Wings.Bat = function(b, c, item)
	local c1, c2 = c[1], c[2] or c[1]
	local out
	for _, s in { -1, 1 } do
		local pv = pivot(b, CFrame.new(s * 0.2, 0.2, 0.1), "Flap", { Side = s, Speed = 4, Amp = 0.5 })
		add(b, block(Vector3.new(2.0, 0.14, 0.14), BLACK), CFrame.Angles(0, 0, R(s * 25)) * CFrame.new(s * 1.0, 0, 0.18), pv)
		for j = 1, 3 do
			add(b, ell(Vector3.new(0.85, 1.25 - j * 0.15, 0.05), c1, wingMaterial(item)), CFrame.new(s * (0.2 + j * 0.5), 0.05 + j * 0.15 - 0.45, 0.2), pv)
		end
		add(b, ball(0.16, c2, Enum.Material.Neon), CFrame.Angles(0, 0, R(s * 25)) * CFrame.new(s * 2.0, 0, 0.18), pv)
		out = pv.Part
	end
	return out
end

Wings.Fairy = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	local out
	for _, s in { -1, 1 } do
		local pv = pivot(b, CFrame.new(s * 0.2, 0.1, 0.1), "Flap", { Side = s, Speed = 5, Amp = 0.4 })
		local up = CFrame.new(s * 1.0, 0.8, 0.2) * CFrame.Angles(0, 0, R(s * 38))
		local low = CFrame.new(s * 0.75, -0.45, 0.2) * CFrame.Angles(0, 0, R(s * -32))
		local w1 = add(b, ell(Vector3.new(2.3, 0.8, 0.05), c1, Enum.Material.Neon), up, pv)
		w1.Transparency = 0.45
		local w2 = add(b, ell(Vector3.new(1.5, 0.55, 0.05), c2, Enum.Material.Neon), low, pv)
		w2.Transparency = 0.45
		add(b, block(Vector3.new(2.0, 0.04, 0.06), WHITE, Enum.Material.Neon), up, pv)
		add(b, block(Vector3.new(1.3, 0.04, 0.06), WHITE, Enum.Material.Neon), low, pv)
		out = w1
	end
	return out
end

Wings.Mech = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	add(b, block(Vector3.new(0.9, 1.0, 0.3), c1, Enum.Material.Metal), CFrame.new(0, 0, 0.15))
	local core = add(b, ball(0.4, c2, Enum.Material.Neon), CFrame.new(0, 0, 0.33))
	light(core, c2, 8)
	for _, s in { -1, 1 } do
		local pv = pivot(b, CFrame.new(s * 0.35, 0.1, 0.25), "Flap", { Side = s, Speed = 1, Amp = 0.15 })
		for k, ang in { 42, 14, -14 } do
			local cf = CFrame.Angles(0, 0, R(s * ang)) * CFrame.new(s * (1.1 - k * 0.1), 0, 0.1)
			add(b, block(Vector3.new(2.0 - k * 0.2, 0.2, 0.12), c1, Enum.Material.Metal), cf, pv)
			add(b, block(Vector3.new(1.9 - k * 0.2, 0.07, 0.14), c2, Enum.Material.Neon), cf * CFrame.new(0, -0.13, 0), pv)
		end
	end
	return core
end

Wings.Angel = function(b, c, item)
	local c1, c2 = c[1], c[2] or c[1]
	local m = wingMaterial(item)
	local out
	for _, s in { -1, 1 } do
		local pv = pivot(b, CFrame.new(s * 0.2, 0.1, 0.1), "Flap", { Side = s, Speed = 1.6, Amp = 0.3 })
		local root = CFrame.new(s * 0.3, 0.35, 0.25)
		for k = 1, 7 do
			local length = 1.1 + k * 0.17
			local ang = R(62 - k * 15)
			local cf = root * CFrame.Angles(0, 0, s * ang) * CFrame.new(s * length / 2, 0, 0)
			local feather = add(b, ell(Vector3.new(length, 0.42, 0.1), c1, m), cf, pv)
			add(b, ell(Vector3.new(length * 0.55, 0.46, 0.1), c2, m), root * CFrame.Angles(0, 0, s * ang) * CFrame.new(s * length * 0.3, 0, 0.06), pv)
			if k == 4 then
				out = feather
				if item.Fire then
					local fire = Instance.new("Fire")
					fire.Color = c1
					fire.SecondaryColor = c2
					fire.Size = 3
					fire.Heat = 2
					fire.Parent = feather
				end
			end
		end
	end
	return out
end

-- ================= PETS (Base = ตำแหน่งสัตว์, -Z = ด้านหน้า) =================

local Pets = {}

local function face(b, front, y, eyeSize, spacing)
	y = y or 0.15
	eyeSize = eyeSize or 0.3
	spacing = spacing or 0.3
	for _, s in { -1, 1 } do
		add(b, noRainbow(ball(eyeSize, BLACK)), CFrame.new(s * spacing, y, -front))
		add(b, noRainbow(ball(eyeSize * 0.33, WHITE, Enum.Material.Neon)), CFrame.new(s * spacing + 0.06, y + 0.07, -front - eyeSize * 0.4))
		add(b, noRainbow(ball(0.22, BLUSH)), CFrame.new(s * (spacing + 0.22), y - 0.27, -front + 0.08))
	end
	add(b, noRainbow(ell(Vector3.new(0.22, 0.1, 0.08), BLACK)), CFrame.new(0, y - 0.25, -front - 0.04))
end

Pets.Ball = function(b, c, item)
	local body = add(b, ball(1.6, c[1], mat(item.Material)), CFrame.new())
	if c[2] then
		add(b, cyl(0.3, 1.64, c[2]), CFrame.new(0, -0.15, 0) * CFrame.Angles(0, R(90), 0))
	end
	face(b, 0.72)
	if item.Beak then
		add(b, noRainbow(ell(Vector3.new(0.35, 0.22, 0.35), Color3.fromRGB(255, 150, 40))), CFrame.new(0, -0.05, -0.8))
		add(b, ell(Vector3.new(0.12, 0.45, 0.3), c[1]), CFrame.new(0, 0.9, 0) * CFrame.Angles(R(-20), 0, 0))
		for _, s in { -1, 1 } do
			add(b, ell(Vector3.new(0.18, 0.6, 0.45), c[1]), CFrame.new(s * 0.8, -0.05, 0.1) * CFrame.Angles(0, 0, R(s * 25)))
		end
	end
	return body
end

Pets.Bear = function(b, c)
	local body = add(b, ball(1.5, c[1], Enum.Material.Glass), CFrame.new())
	body.Transparency = 0.15
	for _, s in { -1, 1 } do
		local ear = add(b, ball(0.5, c[1], Enum.Material.Glass), CFrame.new(s * 0.52, 0.6, 0.05))
		ear.Transparency = 0.15
		local foot = add(b, ball(0.45, c[1], Enum.Material.Glass), CFrame.new(s * 0.4, -0.7, -0.2))
		foot.Transparency = 0.15
	end
	add(b, ell(Vector3.new(0.6, 0.42, 0.3), c[1]:Lerp(WHITE, 0.4)), CFrame.new(0, -0.12, -0.66))
	add(b, noRainbow(ball(0.16, BLACK)), CFrame.new(0, -0.02, -0.8))
	face(b, 0.62, 0.22, 0.24, 0.28)
	return body
end

Pets.Cube = function(b, c, item)
	local body = add(b, block(Vector3.one * 1.5, c[1], mat(item.Material)), CFrame.new())
	add(b, block(Vector3.new(1.52, 0.18, 1.52), c[2] or c[1]:Lerp(WHITE, 0.3)), CFrame.new(0, 0.55, 0))
	face(b, 0.72)
	return body
end

Pets.Fish = function(b, c)
	local c1, c2 = c[1], c[2] or WHITE
	local body = add(b, ell(Vector3.new(1.0, 1.25, 1.8), c1), CFrame.new())
	add(b, ell(Vector3.new(1.02, 1.2, 0.25), c2), CFrame.new(0, 0, -0.3))
	add(b, ell(Vector3.new(1.02, 1.0, 0.25), c2), CFrame.new(0, 0, 0.4))
	for _, s in { -1, 1 } do
		add(b, ell(Vector3.new(0.12, 0.75, 0.6), c1), CFrame.new(0, s * 0.3, 1.05) * CFrame.Angles(R(s * 35), 0, 0))
		add(b, noRainbow(ball(0.3, BLACK)), CFrame.new(s * 0.42, 0.2, -0.55))
		add(b, noRainbow(ball(0.1, WHITE, Enum.Material.Neon)), CFrame.new(s * 0.52, 0.27, -0.6))
		add(b, ell(Vector3.new(0.08, 0.35, 0.4), c2), CFrame.new(s * 0.52, -0.25, -0.1) * CFrame.Angles(0, R(s * 30), 0))
	end
	add(b, ell(Vector3.new(0.1, 0.45, 0.7), c1), CFrame.new(0, 0.7, 0.1))
	return body
end

Pets.Ufo = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	local body = add(b, cyl(0.4, 2.3, c1, Enum.Material.Metal), UP)
	local dome = add(b, ball(1.15, c2, Enum.Material.Glass), CFrame.new(0, 0.3, 0))
	dome.Transparency = 0.35
	add(b, noRainbow(ball(0.7, Color3.fromRGB(120, 230, 120))), CFrame.new(0, 0.25, 0))
	for _, s in { -1, 1 } do
		add(b, noRainbow(ball(0.2, BLACK)), CFrame.new(s * 0.14, 0.35, -0.3))
	end
	local spin = pivot(b, CFrame.new(0, -0.05, 0), "Spin", { Speed = 3 })
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		add(b, noRainbow(ball(0.22, Color3.fromHSV(i / 8, 0.6, 1), Enum.Material.Neon)), CFrame.new(math.cos(a) * 1.08, 0, math.sin(a) * 1.08), spin)
	end
	local beam = add(b, cyl(0.6, 0.9, c2, Enum.Material.Neon), CFrame.new(0, -0.5, 0) * UP)
	beam.Transparency = 0.6
	return body
end

Pets.Pumpkin = function(b, c)
	local c1, c2 = c[1], c[2] or Color3.fromRGB(60, 140, 50)
	local body = add(b, ell(Vector3.new(1.75, 1.3, 1.75), c1), CFrame.new())
	for i = 0, 3 do
		add(b, ell(Vector3.new(1.85, 1.25, 0.9), c1:Lerp(BLACK, 0.12)), CFrame.Angles(0, R(i * 45), 0))
	end
	add(b, cyl(0.4, 0.22, c2), CFrame.new(0, 0.8, 0) * UP)
	add(b, ell(Vector3.new(0.5, 0.08, 0.3), c2), CFrame.new(0.25, 0.75, 0) * CFrame.Angles(0, 0, R(-20)))
	local glow = Color3.fromRGB(255, 230, 80)
	for _, s in { -1, 1 } do
		add(b, noRainbow(block(Vector3.new(0.3, 0.3, 0.1), glow, Enum.Material.Neon)), CFrame.new(s * 0.35, 0.15, -0.92) * CFrame.Angles(0, 0, R(45)))
	end
	add(b, noRainbow(ell(Vector3.new(0.7, 0.2, 0.1), glow, Enum.Material.Neon)), CFrame.new(0, -0.25, -0.92))
	light(body, Color3.fromRGB(255, 160, 50), 7, 1.2)
	return body
end

Pets.Bunny = function(b, c)
	local c1, c2 = c[1], c[2] or BLUSH
	local body = add(b, ball(1.45, c1), CFrame.new())
	for _, s in { -1, 1 } do
		local cf = CFrame.new(s * 0.3, 1.05, 0.05) * CFrame.Angles(0, 0, R(s * -10))
		add(b, ell(Vector3.new(0.38, 1.3, 0.24), c1), cf)
		add(b, ell(Vector3.new(0.2, 0.95, 0.06), c2), cf * CFrame.new(0, 0, -0.12))
		add(b, ball(0.42, c1), CFrame.new(s * 0.38, -0.65, -0.25))
	end
	add(b, ball(0.45, WHITE), CFrame.new(0, -0.3, 0.72))
	face(b, 0.66, 0.1, 0.27, 0.28)
	return body
end

Pets.Robot = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	local body = add(b, block(Vector3.new(1.45, 1.15, 1.15), c1, Enum.Material.Metal), CFrame.new())
	add(b, block(Vector3.new(1.1, 0.75, 0.05), BLACK), CFrame.new(0, 0.02, -0.58))
	for _, s in { -1, 1 } do
		add(b, block(Vector3.new(0.24, 0.24, 0.05), c2, Enum.Material.Neon), CFrame.new(s * 0.26, 0.08, -0.61))
		add(b, cyl(0.15, 0.45, c1, Enum.Material.Metal), CFrame.new(s * 0.78, 0, 0))
		add(b, cyl(0.06, 0.3, c2, Enum.Material.Neon), CFrame.new(s * 0.87, 0, 0))
	end
	add(b, block(Vector3.new(0.4, 0.06, 0.05), c2, Enum.Material.Neon), CFrame.new(0, -0.18, -0.61))
	add(b, cyl(0.45, 0.08, c1), CFrame.new(0, 0.8, 0) * UP)
	local tip = add(b, ball(0.25, c2, Enum.Material.Neon), CFrame.new(0, 1.05, 0))
	light(tip, c2, 6)
	local jet = add(b, cyl(0.3, 0.5, c2, Enum.Material.Neon), CFrame.new(0, -0.72, 0) * UP)
	jet.Transparency = 0.3
	return body
end

Pets.Dragon = function(b, c, item)
	local c1, c2 = c[1], c[2] or c[1]
	local m = mat(item.Material)
	local body = add(b, ball(1.5, c1, m), CFrame.new())
	add(b, ell(Vector3.new(0.85, 0.6, 0.75), c1, m), CFrame.new(0, -0.12, -0.72))
	add(b, ell(Vector3.new(1.0, 1.0, 0.4), c1:Lerp(WHITE, 0.45)), CFrame.new(0, -0.3, -0.5))
	for _, s in { -1, 1 } do
		add(b, noRainbow(ball(0.1, BLACK)), CFrame.new(s * 0.15, -0.05, -1.08))
		add(b, cyl(0.6, 0.14, c2), CFrame.new(s * 0.3, 0.8, 0.15) * CFrame.Angles(R(-30), 0, R(s * -15)) * UP)
		local pv = pivot(b, CFrame.new(s * 0.55, 0.3, 0.3), "Flap", { Side = s, Speed = 3, Amp = 0.5 })
		add(b, ell(Vector3.new(1.3, 0.8, 0.06), c2), CFrame.new(s * 0.6, 0.25, 0) * CFrame.Angles(0, 0, R(s * 25)), pv)
	end
	for i = 1, 3 do
		add(b, P({ Size = Vector3.new(0.1, 0.3, 0.3), Color = c2 }, "WedgePart"), CFrame.new(0, 0.78 - i * 0.12, 0.05 + i * 0.25))
	end
	add(b, ell(Vector3.new(0.4, 0.4, 1.1), c1, m), CFrame.new(0, -0.4, 0.95) * CFrame.Angles(R(25), 0, 0))
	face(b, 0.66, 0.25, 0.28, 0.32)
	return body
end

Pets.Unicorn = function(b, c)
	local c1, c2 = c[1], c[2] or c[1]
	local body = add(b, ball(1.5, c1), CFrame.new())
	for i = 0, 3 do
		local horn = add(b, cyl(0.28, 0.32 - i * 0.07, Color3.fromHSV(i / 4, 0.5, 1), Enum.Material.Neon), CFrame.new(0, 0.82 + i * 0.22, -0.32 - i * 0.06) * CFrame.Angles(R(-15), 0, 0) * UP)
		CollectionService:AddTag(horn, "Rainbow")
	end
	for i = 1, 5 do
		add(b, noRainbow(ball(0.4, Color3.fromHSV(i / 6, 0.45, 1))), CFrame.new(0, 0.7 - i * 0.08, -0.1 + i * 0.22))
	end
	for _, s in { -1, 1 } do
		add(b, ell(Vector3.new(0.22, 0.45, 0.15), c1), CFrame.new(s * 0.42, 0.7, 0.05) * CFrame.Angles(0, 0, R(s * -20)))
	end
	for i = 1, 3 do
		add(b, noRainbow(ball(0.35, Color3.fromHSV(i / 4, 0.5, 1))), CFrame.new(0, -0.1 - i * 0.12, 0.7 + i * 0.12))
	end
	add(b, ball(0.42, c2), CFrame.new(0, -0.15, -0.7))
	face(b, 0.62, 0.25, 0.3, 0.3)
	return body
end

-- ================= AURA แบบโคจร (Base = กลางตัว) =================

local function orbitPiece(shape, color, rainbow)
	if shape == "Cube" then
		local p = block(Vector3.one * 0.45, color, Enum.Material.Neon)
		return p, CFrame.Angles(R(45), R(45), 0)
	elseif shape == "Gem" then
		local p = block(Vector3.new(0.4, 0.4, 0.4), color, Enum.Material.Neon)
		return p, CFrame.Angles(R(45), 0, R(45))
	elseif shape == "Wisp" then
		local p = ball(0.45, color, Enum.Material.Neon)
		p.Transparency = 0.25
		return p, CFrame.new()
	elseif shape == "Planet" then
		return ball(0.7, color), CFrame.new()
	end
	local p = ball(0.38, color, Enum.Material.Neon)
	if rainbow then
		p.Transparency = 0
	end
	return p, CFrame.new()
end

local function buildOrbit(b, c, item)
	local shape = item.Shape or "Ball"
	local count = shape == "Planet" and 3 or 6
	local radius = shape == "Planet" and 3 or 2.6
	local spin = pivot(b, CFrame.new(0, 0.2, 0), "Spin", { Speed = shape == "Planet" and 0.8 or 1.4 })
	local last
	for i = 1, count do
		local a = i / count * math.pi * 2
		local color = c[(i - 1) % #c + 1]
		local piece, rot = orbitPiece(shape, color, item.Rainbow)
		local pos = CFrame.new(math.cos(a) * radius, math.sin(a * 2) * 0.6, math.sin(a) * radius)
		last = add(b, piece, pos * rot, spin)
		if shape == "Planet" then
			add(b, cyl(0.05, 1.25, color:Lerp(WHITE, 0.5)), pos * CFrame.Angles(R(20), 0, 0), spin)
		elseif shape == "Wisp" then
			light(piece, color, 5)
		end
	end
	if shape == "Gem" or shape == "Wisp" then
		local spin2 = pivot(b, CFrame.new(0, 1.2, 0), "Spin", { Speed = -2 })
		for i = 1, 4 do
			local a = i / 4 * math.pi * 2
			add(b, ball(0.18, c[1], Enum.Material.Neon), CFrame.new(math.cos(a) * 1.6, 0, math.sin(a) * 1.6), spin2)
		end
	end
	return last
end

-- ================= PUBLIC API =================

-- สร้างโมเดล (ยังไม่เชื่อมกับอะไร) คืนค่า build table
function CB.Build(item, base)
	local b = newBuild(item, base or CFrame.new())
	local colors = item.Colors or { WHITE }
	local showcase
	if item.Category == "Hat" and Hats[item.Style] then
		showcase = Hats[item.Style](b, colors, item)
	elseif item.Category == "Wings" and Wings[item.Style] then
		showcase = Wings[item.Style](b, colors, item)
	elseif item.Category == "Pet" and Pets[item.Style] then
		showcase = Pets[item.Style](b, colors, item)
		b.Body = showcase
	elseif item.Category == "Aura" and item.Style == "Orbit" then
		showcase = buildOrbit(b, colors, item)
	else
		return nil
	end
	if showcase then
		rarityFx(item, showcase)
	end
	return b
end

-- เชื่อม build เข้ากับชิ้นส่วนตัวละคร (server)
function CB.Attach(b, anchor)
	local anchorOffset = anchor.CFrame:ToObjectSpace(b.Base)
	for _, rec in b.Pivots do
		local weld = Instance.new("Weld")
		weld.Part0 = anchor
		weld.Part1 = rec.Part
		weld.C0 = anchorOffset * rec.Offset
		weld:SetAttribute("BaseC0", weld.C0)
		weld:SetAttribute("Side", rec.Side)
		weld:SetAttribute("Speed", rec.Speed)
		weld:SetAttribute("Amp", rec.Amp)
		weld.Parent = rec.Part
		CollectionService:AddTag(weld, rec.Kind == "Flap" and "FlapWeld" or "SpinWeld")
	end
	for _, rec in b.Parts do
		if rec.Part ~= anchor then
			local constraint = Instance.new("WeldConstraint")
			constraint.Part0 = rec.Pivot or anchor
			constraint.Part1 = rec.Part
			constraint.Parent = rec.Part
		end
	end
end

-- ทำให้ทุกชิ้นอยู่กับที่ (preview ในร้าน)
function CB.Anchor(b)
	for _, d in b.Model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
end

-- ===== สกิน =====

function CB.SkinColor(item, partName)
	local colors = item.Colors
	if partName:find("Arm") or partName:find("Hand") then
		return colors[2] or colors[1], true
	elseif partName:find("Leg") or partName:find("Foot") then
		return colors[3] or colors[2] or colors[1], true
	end
	return colors[1], false
end

function CB.ApplySkinToPart(item, part)
	local color, isLimb = CB.SkinColor(item, part.Name)
	part.Color = color
	part.Material = (isLimb and item.LimbMaterial) and mat(item.LimbMaterial) or mat(item.Material)
	part.Reflectance = item.Reflectance or 0
	if item.Transparency and part.Name ~= "HumanoidRootPart" then
		part.Transparency = item.Transparency
	end
	if item.Rainbow then
		CollectionService:AddTag(part, "Rainbow")
	end
end

-- ===== หาง (Trail) =====

function CB.CreateTrail(item, root)
	local created = {}
	local half = item.Style == "Wide" and 1.4 or 0.9
	local top = Instance.new("Attachment")
	top.Name = "TrailTop"
	top.Position = Vector3.new(0, half, 0.3)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "TrailBottom"
	bottom.Position = Vector3.new(0, -half, 0.3)
	bottom.Parent = root
	local trail = Instance.new("Trail")
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Color = ItemCatalog.GetColorSequence(item)
	trail.Lifetime = item.Style == "Wide" and 0.9 or 0.7
	trail.MinLength = 0.05
	trail.LightEmission = 0.7
	trail.FaceCamera = true
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.1) })
	trail.Parent = root
	table.insert(created, top)
	table.insert(created, bottom)
	table.insert(created, trail)
	if item.Rainbow then
		CollectionService:AddTag(trail, "RainbowTrail")
	end
	if item.Style == "Sparkle" then
		local feet = Instance.new("Attachment")
		feet.Position = Vector3.new(0, -2.4, 0.5)
		feet.Parent = root
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ItemCatalog.GetColorSequence(item)
		emitter.Rate = 14
		emitter.Lifetime = NumberRange.new(0.8, 1.4)
		emitter.Speed = NumberRange.new(0.3, 1)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Acceleration = Vector3.new(0, 1.5, 0)
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
		emitter.Parent = feet
		table.insert(created, feet)
	end
	return created
end

-- ===== ออร่าแบบอนุภาค =====

function CB.CreateAuraEffects(item, root)
	local created = {}
	if item.Style == "Fire" then
		local fire = Instance.new("Fire")
		fire.Color = item.Colors[1]
		fire.SecondaryColor = item.Colors[2] or item.Colors[1]
		fire.Size = 3
		fire.Heat = 4
		fire.Parent = root
		table.insert(created, fire)
	elseif item.Style == "Sparkles" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = item.Colors[1]
		sparkles.Parent = root
		table.insert(created, sparkles)
	elseif item.Style == "Particles" then
		local burst = item.Preset == "Burst"
		for _, color in item.Colors do
			local emitter = Instance.new("ParticleEmitter")
			emitter.Color = ColorSequence.new(color)
			emitter.Rate = math.floor(16 / #item.Colors + 2)
			emitter.Lifetime = burst and NumberRange.new(0.6, 1) or NumberRange.new(1.4, 2.2)
			emitter.Speed = burst and NumberRange.new(3, 5) or NumberRange.new(0.5, 1.5)
			emitter.Drag = burst and 3 or 0
			emitter.Acceleration = burst and Vector3.new(0, -3, 0) or Vector3.new(0, 2, 0)
			emitter.SpreadAngle = Vector2.new(180, 180)
			emitter.Rotation = NumberRange.new(0, 360)
			emitter.RotSpeed = NumberRange.new(-120, 120)
			emitter.LightEmission = 1
			emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, burst and 0.3 or 0.45), NumberSequenceKeypoint.new(1, 0) })
			emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
			emitter.Parent = root
			table.insert(created, emitter)
		end
	end
	return created
end

-- ===== ฉายาเหนือหัว =====

function CB.CreateTitle(item, head)
	local gui = Instance.new("BillboardGui")
	gui.Name = "TitleTag"
	gui.Size = UDim2.fromOffset(220, 34)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = item.Text or item.Name
	label.TextScaled = true
	label.TextColor3 = WHITE
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(50, 25, 70)
	stroke.Parent = label
	local gradient = Instance.new("UIGradient")
	gradient.Color = ItemCatalog.GetColorSequence(item)
	gradient.Parent = label
	if item.Rainbow or item.Rarity == "Mythic" or item.Rarity == "Legendary" then
		CollectionService:AddTag(gradient, "ShineGradient")
	end
	gui.Parent = head
	return gui
end

-- ===== ตุ๊กตาโชว์สกินในร้าน (preview) =====

function CB.BuildMannequin(skinItem, base)
	base = base or CFrame.new()
	local model = Instance.new("Model")
	model.Name = "Mannequin"
	local defs = {
		{ "Head", Vector3.new(1.25, 1.25, 1.25), CFrame.new(0, 2.25, 0) },
		{ "UpperTorso", Vector3.new(2, 1.6, 1), CFrame.new(0, 0.8, 0) },
		{ "LowerTorso", Vector3.new(2, 0.4, 1), CFrame.new(0, -0.2, 0) },
		{ "LeftArm", Vector3.new(0.95, 2, 0.95), CFrame.new(-1.5, 0.6, 0) },
		{ "RightArm", Vector3.new(0.95, 2, 0.95), CFrame.new(1.5, 0.6, 0) },
		{ "LeftLeg", Vector3.new(0.95, 2, 0.95), CFrame.new(-0.5, -1.4, 0) },
		{ "RightLeg", Vector3.new(0.95, 2, 0.95), CFrame.new(0.5, -1.4, 0) },
	}
	local parts = {}
	for _, def in defs do
		local part = P({ Name = def[1], Size = def[2], Anchored = true, Color = Color3.fromRGB(255, 214, 170) })
		local cf = def[3]
		if def[1] == "Head" then
			part.Shape = Enum.PartType.Cylinder
			part.Size = Vector3.new(1.2, 1.35, 1.35)
			cf = cf * UP
		end
		part.CFrame = base * cf
		if skinItem and skinItem.Id ~= "skin_classic" then
			CB.ApplySkinToPart(skinItem, part)
		end
		part.Parent = model
		parts[def[1]] = part
	end
	for _, s in { -1, 1 } do
		local eye = ball(0.22, BLACK)
		eye.Anchored = true
		eye.CFrame = base * CFrame.new(s * 0.25, 2.35, -0.66)
		eye.Parent = model
	end
	local smile = ell(Vector3.new(0.4, 0.1, 0.08), BLACK)
	smile.Anchored = true
	smile.CFrame = base * CFrame.new(0, 2.05, -0.68)
	smile.Parent = model
	model.PrimaryPart = parts.UpperTorso
	return model, parts
end

-- โมเดลโชว์ในร้าน คืนค่า (model, viewHint)  viewHint = "Front" | "Back"
function CB.BuildPreview(item)
	local category = item.Category
	if category == "Skin" then
		local model = CB.BuildMannequin(item)
		return model, "Front"
	elseif category == "Hat" then
		local model = Instance.new("Model")
		local head = P({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 1.35, 1.35), Anchored = true, Color = Color3.fromRGB(255, 214, 170), CFrame = UP })
		head.Parent = model
		for _, s in { -1, 1 } do
			local eye = ball(0.2, BLACK)
			eye.Anchored = true
			eye.CFrame = CFrame.new(s * 0.24, 0.1, -0.64)
			eye.Parent = model
		end
		local b = CB.Build(item, CFrame.new(0, 0.6, 0))
		if b then
			CB.Anchor(b)
			b.Model.Parent = model
		end
		return model, "Front"
	elseif category == "Wings" then
		local model, parts = CB.BuildMannequin(nil)
		local torso = parts.UpperTorso
		local b = CB.Build(item, torso.CFrame * CFrame.new(0, 0.2, 0.5))
		if b then
			CB.Anchor(b)
			b.Model.Parent = model
		end
		return model, "Back"
	elseif category == "Pet" then
		local b = CB.Build(item, CFrame.new())
		if b then
			CB.Anchor(b)
			return b.Model, "Front"
		end
	elseif category == "Aura" then
		local model = CB.BuildMannequin(nil)
		if item.Style == "Orbit" then
			local b = CB.Build(item, CFrame.new(0, 0.6, 0))
			if b then
				CB.Anchor(b)
				b.Model.Parent = model
			end
		else
			for i = 1, 10 do
				local a = i / 10 * math.pi * 2
				local color = item.Colors[(i - 1) % #item.Colors + 1]
				local glow = ball(0.3 + (i % 3) * 0.12, color, Enum.Material.Neon)
				glow.Anchored = true
				glow.Transparency = 0.15
				glow.CFrame = CFrame.new(math.cos(a) * 2.2, -1 + (i % 5) * 0.9, math.sin(a) * 1.4)
				glow.Parent = model
			end
		end
		return model, "Front"
	elseif category == "Trail" then
		local model = Instance.new("Model")
		local sequence = ItemCatalog.GetColorSequence(item)
		local keys = sequence.Keypoints
		local width = item.Style == "Wide" and 2.6 or 1.8
		for i = 0, 13 do
			local t = i / 13
			local color = keys[1].Value
			for k = 1, #keys - 1 do
				if t >= keys[k].Time and t <= keys[k + 1].Time then
					local span = keys[k + 1].Time - keys[k].Time
					color = keys[k].Value:Lerp(keys[k + 1].Value, span > 0 and (t - keys[k].Time) / span or 0)
				end
			end
			local seg = block(Vector3.new(0.55, width * (1 - t * 0.7), 0.15), color, Enum.Material.Neon)
			seg.Anchored = true
			seg.Transparency = t * 0.6
			seg.CFrame = CFrame.new(-3.5 + i * 0.55, math.sin(t * math.pi * 1.5) * 1.2, 0) * CFrame.Angles(0, 0, math.cos(t * math.pi * 1.5) * 0.6)
			seg.Parent = model
			if item.Style == "Sparkle" and i % 3 == 0 then
				local spark = ball(0.25, WHITE, Enum.Material.Neon)
				spark.Anchored = true
				spark.CFrame = seg.CFrame * CFrame.new(0.2, width * 0.6, -0.2)
				spark.Parent = model
			end
		end
		return model, "Front"
	end
	return nil
end

return CB
