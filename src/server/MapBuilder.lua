--[[
	MapBuilder — สร้างแผนที่ทั้งหมดด้วยโค้ด (เปิดเกมใน Studio แล้วเล่นได้เลย ไม่ต้องสร้างฉากเอง)
	- เกาะกลม + ทะเล + ต้นไม้ลูกกวาด
	- ร้านสกิน (ProximityPrompt เปิดร้าน) และกล่องของขวัญรายวัน
	- อารีน่าลอยฟ้า "พื้นสีวิบวับ" + บ่อสไลม์ด้านล่าง
]]

local Lighting = game:GetService("Lighting")

local MapBuilder = {}

local UP = CFrame.Angles(0, 0, math.rad(90))
local rng = Random.new(2026)

MapBuilder.ArenaCenter = Vector3.new(0, 80, 175)
MapBuilder.TileSize = 9
MapBuilder.GridSize = 8

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		p[key] = value
	end
	p.Parent = parent
	return p
end

local function billboard(adornee, text, color, offsetY, size)
	local gui = Instance.new("BillboardGui")
	gui.Size = size or UDim2.fromOffset(260, 70)
	gui.StudsOffset = Vector3.new(0, offsetY or 6, 0)
	gui.MaxDistance = 200
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(60, 30, 80)
	label.Parent = gui
	gui.Parent = adornee
	return gui
end

local function prompt(parent, actionText, objectText, attribute)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = actionText
	p.ObjectText = objectText
	p.HoldDuration = 0
	p.MaxActivationDistance = 14
	p.RequiresLineOfSight = false
	p:SetAttribute(attribute, true)
	p.Parent = parent
	return p
end

local function buildTree(position, parent)
	local leafColors = {
		Color3.fromRGB(255, 160, 200),
		Color3.fromRGB(150, 235, 190),
		Color3.fromRGB(255, 235, 130),
		Color3.fromRGB(190, 160, 255),
	}
	local height = rng:NextNumber(7, 11)
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.6, 1.6),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * UP,
		Color = Color3.fromRGB(150, 100, 70),
		Material = Enum.Material.Wood,
	}, parent)
	local leaves = rng:NextNumber(6, 9)
	part({
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * leaves,
		Position = position + Vector3.new(0, height + leaves * 0.3, 0),
		Color = leafColors[rng:NextInteger(1, #leafColors)],
		CanCollide = false,
	}, parent)
end

local function buildShop(parent)
	local model = Instance.new("Model")
	model.Name = "SkinShop"
	local origin = CFrame.new(32, 0, -22) * CFrame.Angles(0, math.rad(-30), 0)

	part({ Name = "Floor", Size = Vector3.new(18, 1, 12), CFrame = origin * CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(255, 240, 220) }, model)
	for _, x in { -8, 8 } do
		for _, z in { -5, 5 } do
			part({
				Name = "Pillar",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(9, 1, 1),
				CFrame = origin * CFrame.new(x, 5, z) * UP,
				Color = Color3.fromRGB(255, 255, 255),
			}, model)
		end
	end
	-- หลังคาลายทาง
	for i = 0, 8 do
		part({
			Name = "Roof",
			Size = Vector3.new(2.2, 1, 14),
			CFrame = origin * CFrame.new(-8.8 + i * 2.2, 9.5, 0),
			Color = i % 2 == 0 and Color3.fromRGB(255, 110, 170) or Color3.fromRGB(255, 255, 255),
		}, model)
	end
	local counter = part({
		Name = "Counter",
		Size = Vector3.new(14, 3.5, 2.5),
		CFrame = origin * CFrame.new(0, 2.75, -3),
		Color = Color3.fromRGB(120, 200, 255),
	}, model)
	-- โชว์ของบนเคาน์เตอร์
	for i = -2, 2 do
		part({
			Name = "Display",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.4,
			CFrame = origin * CFrame.new(i * 2.6, 5.2, -3),
			Color = Color3.fromHSV((i + 2) / 5, 0.6, 1),
			Material = Enum.Material.Neon,
		}, model)
	end
	billboard(counter, "🛍️ ร้านสกินปาร์ตี้", Color3.fromRGB(255, 120, 190), 9)
	prompt(counter, "เปิดร้าน", "ร้านสกิน", "OpenShop")
	model.Parent = parent
end

local function buildGiftBox(parent)
	local model = Instance.new("Model")
	model.Name = "DailyGift"
	local pos = Vector3.new(-32, 0, -22)
	local box = part({ Name = "Box", Size = Vector3.new(7, 6, 7), Position = pos + Vector3.new(0, 3, 0), Color = Color3.fromRGB(120, 210, 255) }, model)
	part({ Name = "Lid", Size = Vector3.new(7.6, 1.4, 7.6), Position = pos + Vector3.new(0, 6.7, 0), Color = Color3.fromRGB(100, 190, 240) }, model)
	part({ Name = "RibbonA", Size = Vector3.new(1.2, 7.5, 7.8), Position = pos + Vector3.new(0, 3.75, 0), Color = Color3.fromRGB(255, 90, 140) }, model)
	part({ Name = "RibbonB", Size = Vector3.new(7.8, 7.5, 1.2), Position = pos + Vector3.new(0, 3.75, 0), Color = Color3.fromRGB(255, 90, 140) }, model)
	for _, side in { -1, 1 } do
		part({
			Name = "Bow",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 2.4,
			Position = pos + Vector3.new(side * 1.2, 8.2, 0),
			Color = Color3.fromRGB(255, 90, 140),
		}, model)
	end
	billboard(box, "🎁 ของขวัญรายวัน", Color3.fromRGB(120, 210, 255), 7)
	prompt(box, "เปิดของขวัญ", "รางวัลรายวัน", "OpenDaily")
	model.Parent = parent
end

local function buildArena(parent)
	local arena = Instance.new("Model")
	arena.Name = "ColorArena"
	local center = MapBuilder.ArenaCenter
	local tileSize = MapBuilder.TileSize
	local n = MapBuilder.GridSize
	local half = tileSize * n / 2

	local tiles = {}
	for x = 1, n do
		for z = 1, n do
			local tile = part({
				Name = "Tile",
				Size = Vector3.new(tileSize - 0.2, 1, tileSize - 0.2),
				Position = center + Vector3.new((x - 0.5) * tileSize - half, 0, (z - 0.5) * tileSize - half),
				Color = Color3.new(1, 1, 1),
			}, arena)
			table.insert(tiles, tile)
		end
	end

	-- กำแพงใสกันตกขอบ (ตกได้แค่ทางรูที่พื้นหายไป)
	local wallColor = Color3.fromRGB(180, 230, 255)
	for _, info in {
		{ Vector3.new(0, 4, half + 0.5), Vector3.new(half * 2 + 2, 8, 1) },
		{ Vector3.new(0, 4, -half - 0.5), Vector3.new(half * 2 + 2, 8, 1) },
		{ Vector3.new(half + 0.5, 4, 0), Vector3.new(1, 8, half * 2) },
		{ Vector3.new(-half - 0.5, 4, 0), Vector3.new(1, 8, half * 2) },
	} do
		part({
			Name = "Wall",
			Position = center + info[1],
			Size = info[2],
			Color = wallColor,
			Material = Enum.Material.Glass,
			Transparency = 0.7,
		}, arena)
	end

	local slime = part({
		Name = "Slime",
		Size = Vector3.new(half * 2 + 30, 2, half * 2 + 30),
		Position = center - Vector3.new(0, 14, 0),
		Color = Color3.fromRGB(150, 255, 90),
		Material = Enum.Material.Neon,
		Transparency = 0.15,
	}, arena)

	local signAnchor = part({
		Name = "Sign",
		Size = Vector3.one,
		Position = center + Vector3.new(0, 14, half),
		Transparency = 1,
		CanCollide = false,
	}, arena)
	billboard(signAnchor, "🎨 พื้นสีวิบวับ", Color3.fromRGB(255, 230, 80), 0, UDim2.fromOffset(420, 100))

	arena.Parent = parent
	return tiles, slime
end

function MapBuilder.Build()
	local old = workspace:FindFirstChild("Baseplate")
	if old then
		old:Destroy()
	end

	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 160, 190)
	Lighting.GlobalShadows = true

	local map = Instance.new("Folder")
	map.Name = "Map"

	local ground = Instance.new("Folder")
	ground.Name = "Ground"
	ground.Parent = map

	part({
		Name = "Water",
		Size = Vector3.new(1400, 2, 1400),
		Position = Vector3.new(0, -4, 0),
		Color = Color3.fromRGB(90, 185, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.15,
	}, map)
	part({
		Name = "Sand",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 250, 250),
		CFrame = CFrame.new(0, -3.5, 0) * UP,
		Color = Color3.fromRGB(255, 225, 160),
		Material = Enum.Material.Sand,
	}, ground)
	part({
		Name = "Grass",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 228, 228),
		CFrame = CFrame.new(0, -3, 0) * UP,
		Color = Color3.fromRGB(125, 215, 110),
		Material = Enum.Material.Grass,
	}, ground)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Color = Color3.fromRGB(255, 150, 210)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = map
	local placed = 0
	local attempts = 0
	while placed < 18 and attempts < 200 do
		attempts += 1
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(50, 105)
		local pos = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		-- เว้นที่ร้านค้า / กล่องของขวัญ
		if (pos - Vector3.new(32, 0, -22)).Magnitude > 20 and (pos - Vector3.new(-32, 0, -22)).Magnitude > 16 then
			buildTree(pos, decor)
			placed += 1
		end
	end

	buildShop(map)
	buildGiftBox(map)
	local tiles, slime = buildArena(map)

	map.Parent = workspace

	return {
		Map = map,
		Ground = ground,
		Spawn = spawn,
		Tiles = tiles,
		Slime = slime,
		ArenaCenter = MapBuilder.ArenaCenter,
	}
end

return MapBuilder
