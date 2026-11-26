--[[
	SanctuaryService — เขตอนุรักษ์ส่วนตัว
	  • ผู้เล่นแต่ละคนได้เกาะ Terrain ของตัวเอง (ปั้นด้วย noise: เนินหลัง, บ่อน้ำ, ชายหาด) ไม่ใช่ลานสี่เหลี่ยมโล่ง
	  • เดินทางผ่านประตูเวทมนตร์ในหมู่บ้าน ↔ ประตูกลับบนเกาะ
	  • วางของ: Grid Snapping + หมุน 90° + ตรวจชน/ขอบเขต/บ่อน้ำ ที่เซิร์ฟเวอร์
	  • สัตว์ของผู้เล่นอาศัยอยู่ที่นี่ โดยใช้ที่อยู่ (Habitat) ที่ตรงสายพันธุ์เป็นบ้าน
	  • รังฟักไข่: วางไข่ → ฟักตามเวลา → ได้สัตว์วัยทารก
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Species = require(Shared.Species)
local Net = require(Shared.Net)
local WorldLayout = require(Shared.WorldLayout)
local AssetLibrary = require(Shared.AssetLibrary)
local Placement = require(Shared.Placement)

local DataService = require(script.Parent.Parent.Data.DataService)
local Inventory = require(script.Parent.Parent.Gameplay.Inventory)
local QuestService = require(script.Parent.Parent.Gameplay.QuestService)
local TerrainBuilder = require(script.Parent.Parent.World.TerrainBuilder)
local CreatureService = require(script.Parent.Parent.Creatures.CreatureService)
local CreatureCare = require(script.Parent.Parent.Creatures.CreatureCare)
local CreatureFactory = require(script.Parent.Parent.Creatures.CreatureFactory)

local SanctuaryService = {}

local SAN = Config.Sanctuary
local plots = {} -- [Player] = plot
local usedSlots = {}
local folder

local FIXED = Placement.Fixed
local POND = Placement.Pond

-- ===== helpers =====
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function groundY(position)
	rayParams.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(position + Vector3.new(0, 150, 0), Vector3.new(0, -300, 0), rayParams)
	return hit and hit.Position.Y or position.Y
end

local function worldCFrame(plot, localX, localZ, yawDegrees)
	local world = plot.Origin + Vector3.new(localX, 0, localZ)
	return CFrame.new(world.X, groundY(world), world.Z) * CFrame.Angles(0, math.rad(yawDegrees), 0)
end

local snap = Placement.Snap

function SanctuaryService.Validate(data, itemId, x, z, rotationSteps, ignoreObjectId)
	return Placement.Validate(data.Sanctuary, itemId, x, z, rotationSteps, ignoreObjectId)
end

-- ===== objects =====
local function spawnObject(plot, objectId, object)
	local item = Items.ById[object.Item]
	if not item then
		return
	end
	local model = AssetLibrary.Create(item.AssetKey, worldCFrame(plot, object.X, object.Z, object.Rot * 90))
	model:SetAttribute("ObjectId", objectId)
	model:SetAttribute("ItemId", object.Item)
	model:SetAttribute("OwnerId", plot.Player.UserId)
	model.Parent = plot.Folder
	if object.Item == "incubator" then
		local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = object.Egg and "ดูไข่" or "วางไข่"
		prompt.ObjectText = "รังฟักไข่"
		prompt.HoldDuration = 0.3
		prompt.RequiresLineOfSight = false
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt:SetAttribute("Incubator", objectId)
		prompt.Parent = anchor
		if object.Egg then
			local egg = CreatureFactory.Create(object.Egg, "Egg")
			egg:PivotTo(model:GetPivot() * CFrame.new(0, 3, 0))
			egg.Parent = model
			model:SetAttribute("HatchAt", object.HatchAt)
		end
	end
	plot.Models[objectId] = model
	return model
end

local function refreshObject(plot, objectId)
	if plot.Models[objectId] then
		plot.Models[objectId]:Destroy()
		plot.Models[objectId] = nil
	end
	local data = DataService.Get(plot.Player)
	local object = data and data.Sanctuary.Objects[objectId]
	if object then
		spawnObject(plot, objectId, object)
	end
end

-- ===== creatures in sanctuary =====
local function homeFor(plot, data, speciesId)
	local def = Species.ById[speciesId]
	for _, object in data.Sanctuary.Objects do
		if object.Item == def.Habitat then
			return plot.Origin + Vector3.new(object.X, 0, object.Z), 30
		end
	end
	return plot.Origin + Vector3.new(-10, 0, -40), 60
end

local function waterSpot(plot, data)
	for _, object in data.Sanctuary.Objects do
		if object.Item == "decor_pond" then
			return plot.Origin + Vector3.new(object.X, 0, object.Z)
		end
	end
	return plot.Origin + Vector3.new(POND.Center.X - POND.Radius + 4, 0, POND.Center.Y)
end

local function spawnCreature(plot, creatureId)
	local data = DataService.Get(plot.Player)
	local record = data and data.Creatures[creatureId]
	if not record or record.Stage == "Egg" then
		return
	end
	if plot.Creatures[creatureId] then
		CreatureService.Despawn(plot.Creatures[creatureId])
	end
	local home, radius = homeFor(plot, data, record.Species)
	local entity = CreatureService.Spawn({
		Species = record.Species,
		Stage = record.Stage,
		Position = home + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)),
		Home = home,
		Radius = radius,
		Owner = plot.Player,
		Personality = record.Personality,
		Name = record.Name,
		Needs = record,
		WaterSpot = waterSpot(plot, data),
		FoodSpot = plot.Origin + Vector3.new(-26, 0, -58),
		Shelter = plot.Origin + Vector3.new(-50, 0, -78),
		Parent = plot.Folder,
	})
	entity.CreatureId = creatureId
	entity.Following = record.Following == true
	entity.Model:SetAttribute("CreatureId", creatureId)
	plot.Creatures[creatureId] = entity.Id
end

local function respawnAllCreatures(plot)
	local data = DataService.Get(plot.Player)
	for creatureId in data.Creatures do
		spawnCreature(plot, creatureId)
	end
end

-- ===== plot lifecycle =====
local function createPlot(player, data)
	local slot = 1
	while usedSlots[slot] do
		slot += 1
	end
	usedSlots[slot] = player
	local origin = SAN.PlotOrigin + Vector3.new((slot - 1) * SAN.PlotSpacing, 0, 0)
	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Sanctuary_" .. player.UserId
	plotFolder.Parent = folder
	local plot = { Player = player, Slot = slot, Origin = origin, Folder = plotFolder, Models = {}, Creatures = {} }
	plots[player] = plot

	TerrainBuilder.BuildIsland(origin)
	for _, fixed in FIXED do
		local model = AssetLibrary.Create(fixed.Key, worldCFrame(plot, fixed.Pos.X, fixed.Pos.Z, fixed.Yaw))
		model.Parent = plotFolder
		local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		if anchor and (fixed.Portal or fixed.Cauldron) then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = fixed.Portal and "กลับหมู่บ้าน" or "ปรุงยา"
			prompt.ObjectText = fixed.Portal and "ประตูเวทมนตร์" or "หม้อยาของคุณ"
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Style = Enum.ProximityPromptStyle.Custom
			if fixed.Portal then
				prompt:SetAttribute("Portal", "Exit")
			else
				prompt:SetAttribute("Station", "Cauldron")
				CollectionService:AddTag(anchor, "Cauldron")
			end
			prompt.Parent = anchor
		end
	end
	for objectId, object in data.Sanctuary.Objects do
		spawnObject(plot, objectId, object)
	end
	respawnAllCreatures(plot)
	player:SetAttribute("SanctuaryOrigin", origin)
	return plot
end

local function destroyPlot(player)
	local plot = plots[player]
	if not plot then
		return
	end
	for _, entityId in plot.Creatures do
		CreatureService.Despawn(entityId)
	end
	plot.Folder:Destroy()
	TerrainBuilder.ClearIsland(plot.Origin)
	usedSlots[plot.Slot] = nil
	plots[player] = nil
end

function SanctuaryService.GetPlot(player)
	return plots[player]
end

function SanctuaryService.IsInSanctuary(player)
	local plot = plots[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return plot ~= nil and root ~= nil and (root.Position - plot.Origin).Magnitude < 260
end

-- ===== remotes =====
local function localCoords(player, x, z)
	if type(x) ~= "number" or type(z) ~= "number" or x ~= x or z ~= z then
		return nil
	end
	return snap(x), snap(z)
end

local function travel(player, enter)
	local character = player.Character
	local plot = plots[player]
	if not character or not plot then
		return false, "เขตอนุรักษ์กำลังเตรียมพร้อม..."
	end
	if enter then
		local cf = worldCFrame(plot, Placement.Arrival.X, Placement.Arrival.Z, 180)
		character:PivotTo(cf + Vector3.new(0, 4, 0))
		player:SetAttribute("Zone", "Sanctuary")
		QuestService.Progress(player, "Visit", "Sanctuary", 1)
	else
		local gate
		for _, entry in WorldLayout.Landmarks do
			if entry.Role == "Portal" then
				gate = entry.Pos
			end
		end
		local target = (gate or WorldLayout.PlayerSpawn) + Vector3.new(0, 0, -12)
		character:PivotTo(CFrame.new(target.X, TerrainBuilder.HeightAt(target.X, target.Z) + 5, target.Z))
		player:SetAttribute("Zone", nil)
	end
	return true
end

local function place(player, itemId, x, z, rotationSteps)
	local data = DataService.Get(player)
	local plot = plots[player]
	if not data or not plot or type(itemId) ~= "string" then
		return false
	end
	if not SanctuaryService.IsInSanctuary(player) then
		return false, "ต้องอยู่ในเขตอนุรักษ์"
	end
	x, z = localCoords(player, x, z)
	rotationSteps = (type(rotationSteps) == "number" and math.floor(rotationSteps) or 0) % 4
	if not x then
		return false
	end
	if Inventory.Count(player, itemId) < 1 then
		return false, "ไม่มีของชิ้นนี้ในกระเป๋า"
	end
	local count = 0
	for _ in data.Sanctuary.Objects do
		count += 1
	end
	if count >= SAN.MaxPlacedObjects then
		return false, "วางของได้สูงสุด " .. SAN.MaxPlacedObjects .. " ชิ้น"
	end
	local ok, reason = SanctuaryService.Validate(data, itemId, x, z, rotationSteps)
	if not ok then
		return false, reason
	end
	Inventory.Remove(player, itemId, 1)
	local objectId = "o" .. data.Sanctuary.NextId
	data.Sanctuary.NextId += 1
	data.Sanctuary.Objects[objectId] = { Item = itemId, X = x, Z = z, Rot = rotationSteps }
	spawnObject(plot, objectId, data.Sanctuary.Objects[objectId])
	QuestService.Progress(player, "Place", itemId, 1)
	-- ที่อยู่ใหม่ → ย้ายสัตว์สายพันธุ์นั้นไปอยู่
	if Items.ById[itemId].Category == "Habitat" then
		respawnAllCreatures(plot)
	end
	DataService.Push(player)
	return true, objectId
end

local function move(player, objectId, x, z, rotationSteps)
	local data = DataService.Get(player)
	local plot = plots[player]
	if not data or not plot or type(objectId) ~= "string" or not data.Sanctuary.Objects[objectId] then
		return false
	end
	x, z = localCoords(player, x, z)
	rotationSteps = (type(rotationSteps) == "number" and math.floor(rotationSteps) or 0) % 4
	if not x then
		return false
	end
	local object = data.Sanctuary.Objects[objectId]
	local ok, reason = SanctuaryService.Validate(data, object.Item, x, z, rotationSteps, objectId)
	if not ok then
		return false, reason
	end
	object.X, object.Z, object.Rot = x, z, rotationSteps
	refreshObject(plot, objectId)
	DataService.Push(player)
	return true
end

local function remove(player, objectId)
	local data = DataService.Get(player)
	local plot = plots[player]
	local object = data and type(objectId) == "string" and data.Sanctuary.Objects[objectId]
	if not object or not plot then
		return false
	end
	if object.Egg then
		Inventory.Add(player, "egg_" .. object.Egg, 1)
	end
	Inventory.Add(player, object.Item, 1)
	data.Sanctuary.Objects[objectId] = nil
	refreshObject(plot, objectId)
	DataService.Push(player)
	return true
end

local function useIncubator(player, objectId, eggItemId)
	local data = DataService.Get(player)
	local plot = plots[player]
	local object = data and type(objectId) == "string" and data.Sanctuary.Objects[objectId]
	if not object or object.Item ~= "incubator" or not plot then
		return false
	end
	if object.Egg then
		local left = math.max(0, object.HatchAt - os.time())
		return false, string.format("ไข่กำลังอุ่นอยู่… อีก %d:%02d นาทีจะฟัก", left // 60, left % 60)
	end
	if type(eggItemId) ~= "string" then
		for itemId, count in data.Inventory do
			if count > 0 and Items.ById[itemId] and Items.ById[itemId].Category == "Egg" then
				eggItemId = itemId
				break
			end
		end
	end
	local egg = eggItemId and Items.ById[eggItemId]
	if not egg or egg.Category ~= "Egg" or not Inventory.Remove(player, eggItemId, 1) then
		return false, "ยังไม่มีไข่ในกระเป๋า"
	end
	object.Egg = egg.Species
	object.HatchAt = os.time() + Config.Growth.EggHatchSeconds
	refreshObject(plot, objectId)
	DataService.Push(player)
	return true, "วางไข่แล้ว ✦ มันจะฟักในอีก " .. math.floor(Config.Growth.EggHatchSeconds / 60) .. " นาที"
end

local function tickHatching()
	for player, plot in plots do
		local data = DataService.Get(player)
		if data then
			for objectId, object in data.Sanctuary.Objects do
				if object.Egg and object.HatchAt and os.time() >= object.HatchAt then
					local speciesId = object.Egg
					object.Egg, object.HatchAt = nil, nil
					local creatureId = CreatureCare.AddCreature(player, speciesId, { Stage = "Baby", Origin = "Hatched" })
					if creatureId then
						data.Stats.Hatched += 1
						Inventory.Notify(player, "🥚 ไข่ฟักแล้ว! " .. Species.ById[speciesId].ThaiName .. " ตัวน้อยลืมตาดูโลก", "creature")
						QuestService.Progress(player, "Hatch", speciesId, 1)
					end
					refreshObject(plot, objectId)
					DataService.Push(player)
				end
			end
		end
	end
end

function SanctuaryService.Init()
	folder = Instance.new("Folder")
	folder.Name = "Sanctuaries"
	folder.Parent = workspace

	CreatureCare.OnCreatureAdded = function(player, creatureId)
		local plot = plots[player]
		if plot then
			spawnCreature(plot, creatureId)
		end
	end
	CreatureCare.OnCreatureChanged = CreatureCare.OnCreatureAdded

	DataService.OnLoaded(function(player, data)
		if not plots[player] then
			createPlot(player, data)
		end
	end)
	Players.PlayerRemoving:Connect(destroyPlot)

	Net.Handle("TravelSanctuary", travel, 1)
	Net.Handle("PlaceObject", place, 0.2)
	Net.Handle("MoveObject", move, 0.2)
	Net.Handle("RemoveObject", remove, 0.2)
	Net.Handle("UseIncubator", useIncubator, 0.5)

	task.spawn(function()
		while true do
			task.wait(5)
			tickHatching()
		end
	end)
end

return SanctuaryService
