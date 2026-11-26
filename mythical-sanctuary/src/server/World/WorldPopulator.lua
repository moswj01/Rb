--[[
	WorldPopulator — วาง Landmark / อาคาร / พืชพรรณ / จุดเก็บสมุนไพร / จุดโต้ตอบ
	การกระจายพืชพรรณ = Jittered-grid blue noise + แผนที่ความหนาแน่น (กลุ่มป่า/ลานโล่ง)
	+ กฎห้ามวาง (ทางเดิน, แม่น้ำ, ความชัน, รอบ Landmark) → ป่าดูเป็นธรรมชาติแต่มีจังหวะ
	ทุกอย่าง deterministic (seed คงที่) — เปิดเกมกี่ครั้งก็ได้ป่าแบบเดิม
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldLayout = require(Shared.WorldLayout)
local AssetLibrary = require(Shared.AssetLibrary)
local AssetRegistry = require(Shared.AssetRegistry)
local Items = require(Shared.Items)
local TerrainBuilder = require(script.Parent.TerrainBuilder)

local WorldPopulator = {}

WorldPopulator.Interactables = {} -- [id] = { Kind, Position, Model, ... }
WorldPopulator.Discoverables = {} -- [id] = { Position, Radius, Name }

local root

local function groundCFrame(pos, yaw, tilt)
	local y = TerrainBuilder.HeightAt(pos.X, pos.Z)
	local cf = CFrame.new(pos.X, y + (pos.Y or 0), pos.Z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	if tilt then
		cf *= CFrame.Angles(tilt.X, 0, tilt.Y)
	end
	return cf, y
end

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or root
	return f
end

local function addPrompt(model, action, object, attributes, distance)
	local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not anchor then
		return nil
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = distance or 12
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom -- client วาดเองตาม UI theme
	for k, v in attributes do
		prompt:SetAttribute(k, v)
	end
	prompt.Parent = anchor
	return prompt
end

-- ===== Landmarks =====
local DISCOVERY_NAMES = {
	Landmark_ClockTower = "หอนาฬิกาโบราณ",
	Landmark_StoneBridge = "สะพานหินข้ามธารา",
	Landmark_ElderTree = "ต้นไม้ผู้เฒ่า",
	Landmark_TempleRuins = "ซากวิหารใต้รากไม้",
	Landmark_Waterfall = "น้ำตกเสียงกระซิบ",
}

local function placeLandmarks()
	local f = folder("Landmarks")
	local cave = TerrainBuilder.Cave()
	for index, entry in WorldLayout.Landmarks do
		local cf = groundCFrame(entry.Pos, entry.Yaw)
		if entry.Cave then
			cf = CFrame.new(entry.Pos.X, cave.FloorY, entry.Pos.Z) * CFrame.Angles(0, math.rad(entry.Yaw or 0), 0)
		end
		local model = AssetLibrary.Create(entry.Key, cf, entry.Scale)
		model.Parent = f
		local id = entry.Key .. "_" .. index
		WorldPopulator.Interactables[id] = { Kind = entry.Role, Position = cf.Position, Model = model, Zone = entry.Zone }
		if entry.Role == "Portal" then
			addPrompt(model, "เข้าสู่เขตอนุรักษ์", "ประตูเวทมนตร์", { Portal = "Enter" }, 14)
		elseif entry.Role == "Cauldron" then
			local prompt = addPrompt(model, "ปรุงยา", "หม้อยาสาธารณะ", { Station = "Cauldron" }, 10)
			if prompt then
				CollectionService:AddTag(prompt.Parent, "Cauldron")
			end
		end
		if DISCOVERY_NAMES[entry.Key] then
			WorldPopulator.Discoverables[entry.Key] = { Position = cf.Position, Radius = 60, Name = DISCOVERY_NAMES[entry.Key] }
		end
	end
	WorldPopulator.Discoverables.HiddenCave = { Position = cave.Chamber, Radius = 26, Name = "ถ้ำคริสตัลลับ" }
end

local function placeHeroTrees()
	local f = folder("HeroTrees")
	for _, entry in WorldLayout.HeroTrees do
		AssetLibrary.Create(entry.Key, (groundCFrame(entry.Pos, entry.Yaw)) * CFrame.new(0, -1, 0), entry.Scale).Parent = f
	end
end

-- ===== กฎการวางพืชพรรณ =====
local function zoneOf(x, z)
	local best, bestPriority
	for _, zone in WorldLayout.Zones do
		local d = math.sqrt((x - zone.Center.X) ^ 2 + (z - zone.Center.Z) ^ 2)
		if d <= zone.Radius and (not bestPriority or zone.Priority > bestPriority) then
			best, bestPriority = zone.Id, zone.Priority
		end
	end
	return best
end

local landmarkPoints = {}

local function nearLandmark(x, z, radius)
	for _, p in landmarkPoints do
		if (x - p.X) ^ 2 + (z - p.Z) ^ 2 < (radius + p.R) ^ 2 then
			return true
		end
	end
	return false
end

local function slopeAt(x, z)
	local h1 = TerrainBuilder.HeightAt(x + 3, z)
	local h2 = TerrainBuilder.HeightAt(x - 3, z)
	local h3 = TerrainBuilder.HeightAt(x, z + 3)
	local h4 = TerrainBuilder.HeightAt(x, z - 3)
	return (math.abs(h1 - h2) + math.abs(h3 - h4)) / 12
end

local function scatter(rule, rng, treePoints)
	local f = folder(rule.Key)
	local T = WorldLayout.Terrain
	local candidates = {}
	local cell = rule.MinSpacing
	for gx = T.Min.X + T.RimWidth * 0.5, T.Max.X - T.RimWidth * 0.5, cell do
		for gz = T.Min.Z + T.RimWidth * 0.5, T.Max.Z - T.RimWidth * 0.5, cell do
			local x = gx + rng:NextNumber(0.15, 0.85) * cell
			local z = gz + rng:NextNumber(0.15, 0.85) * cell
			if zoneOf(x, z) == rule.Zone then
				-- แผนที่ความหนาแน่น: ต้นไม้รวมกลุ่มเป็นดง เว้นลานโล่งเป็นจังหวะ
				local density = math.noise(x / 140, z / 140, 21.7) + 0.35
				local keep = rule.NearTrees and 1 or density
				if keep > rng:NextNumber(-0.25, 0.6) then
					table.insert(candidates, Vector3.new(x, 0, z))
				end
			end
		end
	end
	-- สุ่มลำดับแล้วกรองตามกฎ จนครบจำนวน
	for i = #candidates, 2, -1 do
		local j = rng:NextInteger(1, i)
		candidates[i], candidates[j] = candidates[j], candidates[i]
	end
	local placed = 0
	local points = {}
	for _, p in candidates do
		if placed >= rule.Count then
			break
		end
		local x, z = p.X, p.Z
		local pathEdge = TerrainBuilder.Path(x, z)
		local riverD = TerrainBuilder.River(x, z)
		local ok = pathEdge > (rule.KeepOffPaths or 0)
			and riverD > WorldLayout.River.Width / 2 + (rule.KeepOffRiver or 0)
			and not nearLandmark(x, z, rule.KeepOffLandmarks or 10)
		if ok and rule.MaxSlope then
			ok = slopeAt(x, z) < rule.MaxSlope
		end
		if ok and rule.NearTrees then
			ok = false
			for _, t in treePoints do
				local d2 = (x - t.X) ^ 2 + (z - t.Z) ^ 2
				if d2 < 196 and d2 > 25 then
					ok = true
					break
				end
			end
		end
		if ok then
			local variant = rule.Variants[rng:NextInteger(1, #rule.Variants)]
			local scale = rng:NextNumber(rule.ScaleRange[1], rule.ScaleRange[2])
			-- ต้นไม้ไกลทางเดินโตกว่า (ใกล้ทาง = เล็ก ไม่บังมุมกล้อง)
			if rule.Key == "Tree_Forest" then
				scale *= math.clamp(0.85 + pathEdge / 160, 0.85, 1.25)
			end
			local tilt = Vector2.new(rng:NextNumber(-0.05, 0.05), rng:NextNumber(-0.05, 0.05))
			local cf = groundCFrame(p, rng:NextNumber(0, 360), tilt) * CFrame.new(0, -0.6 * scale, 0)
			local model = AssetLibrary.Create(variant, cf, scale)
			model.Parent = f
			table.insert(points, Vector3.new(x, 0, z))
			placed += 1
			if placed % 80 == 0 then
				task.wait()
			end
		end
	end
	return points
end

-- ===== จุดเก็บสมุนไพร =====
local function placeForage()
	local f = folder("Forage")
	for index, node in WorldLayout.ForageNodes do
		local cf = groundCFrame(Vector3.new(node.Pos.X, 0, node.Pos.Z), index * 47)
		if node.Cave then
			cf = CFrame.new(node.Pos.X, TerrainBuilder.Cave().FloorY, node.Pos.Z) -- จุดในถ้ำ: วางบนพื้นห้องโถง
		end
		local model = AssetLibrary.Create("Forage_" .. node.Item, cf)
		model.Name = "Forage_" .. index
		model.Parent = f
		local id = "forage_" .. index
		CollectionService:AddTag(model, "ForageNode")
		model:SetAttribute("NodeId", id)
		model:SetAttribute("Item", node.Item)
		addPrompt(model, "เก็บ", Items.ById[node.Item].ThaiName, { Forage = id }, 9)
		WorldPopulator.Interactables[id] = { Kind = "Forage", Item = node.Item, Position = cf.Position, Model = model }
	end
end

function WorldPopulator.Build()
	root = workspace:FindFirstChild("World") or Instance.new("Folder")
	root.Name = "World"
	root.Parent = workspace
	root:ClearAllChildren() -- Props สร้างใหม่ทุกครั้ง (Terrain เท่านั้นที่ Bake ได้)
	local rng = Random.new(4207)
	for _, entry in WorldLayout.Landmarks do
		local def = AssetRegistry.Get(entry.Key)
		table.insert(landmarkPoints, { X = entry.Pos.X, Z = entry.Pos.Z, R = def and math.max(def.Size.X, def.Size.Z) * 0.6 or 8 })
	end
	for _, tree in WorldLayout.HeroTrees do
		table.insert(landmarkPoints, { X = tree.Pos.X, Z = tree.Pos.Z, R = 18 })
	end
	placeLandmarks()
	placeHeroTrees()
	local treePoints = {}
	for _, rule in WorldLayout.Scatter do
		local points = scatter(rule, rng, treePoints)
		if rule.Key == "Tree_Forest" then
			treePoints = points
		end
	end
	placeForage()
	root:SetAttribute("Populated", true)
end

function WorldPopulator.GroundAt(x, z)
	return TerrainBuilder.HeightAt(x, z)
end

return WorldPopulator
