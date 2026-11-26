--[[
	CreatureCare — ความไว้วางใจ (Taming แบบอ่อนโยน), การช่วยเหลือ, การดูแล, การเติบโต

	สัตว์ป่า:   Offer (ให้อาหาร/ยา) · Calm (ปลอบ) · Heal (รักษาบาดแผล) · Bond (ผูกพันเมื่อไว้ใจ 100)
	สัตว์ของเรา: Feed · Pet · Play · Follow · Rename · Tonic
	ไม่มีการจับด้วยกำลัง — ทุกอย่างผ่าน "ความไว้วางใจ" ที่ขึ้นกับบุคลิก อาหารที่ชอบ และท่าทีของผู้เล่น
]]

local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Species = require(Shared.Species)
local Items = require(Shared.Items)
local Net = require(Shared.Net)
local WorldLayout = require(Shared.WorldLayout)

local DataService = require(script.Parent.Parent.Data.DataService)
local Inventory = require(script.Parent.Parent.Gameplay.Inventory)
local QuestService = require(script.Parent.Parent.Gameplay.QuestService)
local CreatureService = require(script.Parent.CreatureService)

local CreatureCare = {}

CreatureCare.OnCreatureAdded = nil -- function(player, creatureId) (SanctuaryService ผูก)
CreatureCare.OnCreatureChanged = nil -- function(player, creatureId) (เช่น โตขึ้น → เปลี่ยนโมเดล)

local TRUST = Config.Trust
local CARE = Config.Care
local cooldowns = {}
local rescueEntities = {} -- [Player] = entityId

local function feedback(player, entity, mood, trust, text)
	Net.Event("CreatureFeedback"):FireClient(player, entity.Id, mood, trust, text)
end

local function within(player, entity, distance)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and entity.Root and (root.Position - entity.Root.Position).Magnitude <= distance
end

local function onCooldown(player, entity, seconds)
	local key = player.UserId .. entity.Id
	local now = os.clock()
	if cooldowns[key] and now - cooldowns[key] < seconds then
		return true
	end
	cooldowns[key] = now
	return false
end

local function addTrust(player, entity, amount)
	local personality = Species.Personalities[entity.Personality]
	if amount > 0 then
		amount *= personality.TrustMult
		if player:GetAttribute("Sneaking") then
			amount += 2
		end
	end
	local value = math.clamp((entity.Trust[player.UserId] or 0) + amount, 0, TRUST.Max)
	entity.Trust[player.UserId] = value
	return value
end

local function clampNeeds(record)
	record.Hunger = math.clamp(record.Hunger, 0, 100)
	record.Energy = math.clamp(record.Energy, 0, 100)
	record.Joy = math.clamp(record.Joy, 0, 100)
end

-- ===== การเติบโต =====
local function checkGrowth(player, creatureId, record)
	local growth = Config.Growth
	local nextStage
	if record.Stage == "Baby" and record.CareXP >= growth.CareXPToJuvenile and record.Joy >= growth.MinJoyToGrow then
		nextStage = "Juvenile"
	elseif record.Stage == "Juvenile" and record.CareXP >= growth.CareXPToAdult and record.Joy >= growth.MinJoyToGrow then
		nextStage = "Adult"
	end
	if nextStage then
		record.Stage = nextStage
		Inventory.Notify(player, string.format("✦ %s เติบโตเป็นวัย%s แล้ว!", record.Name, nextStage == "Adult" and "ผู้ใหญ่" or "รุ่น"), "creature")
		Inventory.AddXP(player, 80)
		if CreatureCare.OnCreatureChanged then
			CreatureCare.OnCreatureChanged(player, creatureId)
		end
	end
end

local function addCareXP(player, creatureId, record, amount)
	record.CareXP += amount
	checkGrowth(player, creatureId, record)
end

-- ===== เพิ่มสัตว์เข้าความดูแลของผู้เล่น =====
function CreatureCare.AddCreature(player, speciesId, options)
	local data = DataService.Get(player)
	local def = Species.ById[speciesId]
	if not data or not def then
		return nil
	end
	local count = 0
	for _ in data.Creatures do
		count += 1
	end
	if count >= Config.Sanctuary.MaxCreatures then
		Inventory.Notify(player, "เขตอนุรักษ์เต็มแล้ว (ขยายพื้นที่ได้ในอนาคต)", "warn")
		return nil
	end
	local id = DataService.NewId(player, "c")
	data.Creatures[id] = {
		Species = speciesId,
		Name = options.Name or def.ThaiName,
		Stage = options.Stage or "Baby",
		Personality = options.Personality or def.Personalities[1],
		Hunger = 70,
		Energy = 80,
		Joy = 70,
		CareXP = 0,
		Born = os.time(),
		Origin = options.Origin or "Tamed",
		Following = false,
	}
	local entry = data.Bestiary[speciesId] or { Seen = 1, FirstSeen = os.time() }
	entry.Bonded = true
	data.Bestiary[speciesId] = entry
	if CreatureCare.OnCreatureAdded then
		CreatureCare.OnCreatureAdded(player, id)
	end
	return id
end

-- ===== actions: สัตว์ป่า =====
local function offer(player, entity, itemId)
	local item = Items.ById[itemId]
	if not item or Inventory.Count(player, itemId) < 1 then
		return false, "ไม่มีของชิ้นนี้"
	end
	local def = entity.Def
	if itemId == "healing_salve" then
		if not entity.Injured then
			return false, "ตัวนี้ไม่ได้บาดเจ็บ"
		end
		Inventory.Remove(player, itemId, 1)
		entity.Injured = false
		entity.Model:SetAttribute("Injured", false)
		entity.StateUntil = 0
		local trust = addTrust(player, entity, TRUST.HealInjured)
		local data = DataService.Get(player)
		data.Stats.Rescued += 1
		QuestService.Progress(player, "Rescue", entity.Species, 1)
		CreatureService.React(entity, "Happy", 3)
		feedback(player, entity, "Grateful", trust, "บาดแผลหายแล้ว… มันมองคุณด้วยแววตาขอบคุณ")
		return true
	elseif itemId == "calming_draught" then
		Inventory.Remove(player, itemId, 1)
		entity.CalmUntil = os.clock() + 90
		local trust = addTrust(player, entity, 10)
		feedback(player, entity, "Calm", trust, "กลิ่นยาหอม ๆ ทำให้มันผ่อนคลาย")
		return true
	elseif item.Category ~= "Food" then
		return false, "สัตว์ไม่สนใจของชิ้นนี้"
	end
	Inventory.Remove(player, itemId, 1)
	local amount, mood, text
	if itemId == def.Favorite then
		amount, mood, text = TRUST.OfferFavoriteFood, "Love", "ของโปรดเลย! หางกระดิกไม่หยุด"
	elseif table.find(def.Likes, itemId) then
		amount, mood, text = TRUST.OfferFood, "Happy", "มันกินอย่างเอร็ดอร่อย"
	elseif table.find(def.Dislikes, itemId) then
		amount, mood, text = TRUST.OfferDislikedFood, "Disgust", "มันส่ายหน้า… ดูเหมือนจะไม่ชอบ"
	else
		amount, mood, text = TRUST.OfferFood * 0.5, "Neutral", "มันดมแล้วกินนิดหน่อย"
	end
	local trust = addTrust(player, entity, amount)
	CreatureService.React(entity, amount > 0 and "Eat" or "Scared", 2.5)
	feedback(player, entity, mood, trust, text)
	return true
end

local function calm(player, entity)
	local root = player.Character.HumanoidRootPart
	local v = root.AssemblyLinearVelocity
	local running = Vector3.new(v.X, 0, v.Z).Magnitude > Config.NormalWalkSpeed + 1
	local amount = running and TRUST.CalmWhileRunning or (player:GetAttribute("Sneaking") and TRUST.CalmWhileSneaking or TRUST.CalmWhileSneaking * 0.5)
	local trust = addTrust(player, entity, amount)
	if running then
		CreatureService.React(entity, "Scared", 2)
		feedback(player, entity, "Scared", trust, "คุณเคลื่อนไหวเร็วเกินไป มันตกใจ!")
	else
		CreatureService.React(entity, "Happy", 1.5)
		feedback(player, entity, "Calm", trust, "คุณพูดด้วยน้ำเสียงอ่อนโยน มันเงี่ยหูฟัง")
	end
	return true
end

local function bond(player, entity)
	local trust = CreatureService.TrustOf(entity, player)
	if trust < TRUST.BondThreshold then
		return false, string.format("ยังไม่ไว้ใจพอ (%d/%d)", trust, TRUST.BondThreshold)
	end
	local id = CreatureCare.AddCreature(player, entity.Species, {
		Stage = entity.Stage == "Adult" and "Adult" or (entity.Stage == "Juvenile" and "Juvenile" or "Baby"),
		Personality = entity.Personality,
		Origin = entity.QuestFor and "Rescued" or "Tamed",
	})
	if not id then
		return false, "ไม่สามารถรับดูแลเพิ่มได้"
	end
	local data = DataService.Get(player)
	data.Stats.Bonded += 1
	QuestService.Progress(player, "Bond", entity.Species, 1)
	Inventory.AddXP(player, 100)
	feedback(player, entity, "Bonded", 100, entity.Def.ThaiName .. " ตัดสินใจไปอยู่กับคุณ! มันจะรอที่เขตอนุรักษ์")
	if rescueEntities[player] == entity.Id then
		rescueEntities[player] = nil
	end
	task.delay(2, function()
		CreatureService.Despawn(entity.Id)
	end)
	DataService.Push(player)
	return true
end

-- ===== actions: สัตว์ของเรา =====
local function ownedRecord(player, entity)
	local data = DataService.Get(player)
	return data and entity.CreatureId and data.Creatures[entity.CreatureId]
end

local function feed(player, entity, record, itemId)
	local item = Items.ById[itemId]
	if itemId == "growth_tonic" then
		if not Inventory.Remove(player, itemId, 1) then
			return false, "ไม่มียาบำรุง"
		end
		addCareXP(player, entity.CreatureId, record, 40)
		CreatureService.React(entity, "Happy", 2)
		return true, "ยาบำรุงทำให้ " .. record.Name .. " แข็งแรงขึ้น"
	end
	if not item or item.Category ~= "Food" or not Inventory.Remove(player, itemId, 1) then
		return false, "ไม่มีอาหารชิ้นนี้"
	end
	local def = entity.Def
	record.Hunger += CARE.FeedHunger
	local favorite = itemId == def.Favorite
	if favorite then
		record.Joy += CARE.FeedFavoriteJoy
	elseif table.find(def.Dislikes, itemId) then
		record.Joy -= 6
	end
	clampNeeds(record)
	addCareXP(player, entity.CreatureId, record, favorite and CARE.CareXP.FeedFavorite or CARE.CareXP.Feed)
	CreatureService.React(entity, "Eat", 2.5)
	QuestService.Progress(player, "Feed", entity.Species, 1)
	feedback(player, entity, favorite and "Love" or "Happy", 100)
	return true
end

local function pet(player, entity, record)
	if onCooldown(player, entity, CARE.PetCooldown) then
		return false, "ให้มันพักสักครู่"
	end
	record.Joy += CARE.PetJoy
	clampNeeds(record)
	addCareXP(player, entity.CreatureId, record, CARE.CareXP.Pet)
	CreatureService.React(entity, "Happy", 2)
	feedback(player, entity, "Happy", 100)
	return true
end

local function play(player, entity, record)
	if record.Energy < CARE.PlayEnergyCost + 5 then
		return false, record.Name .. " เหนื่อยแล้ว ให้มันนอนพักก่อน"
	end
	record.Energy -= CARE.PlayEnergyCost
	record.Joy += CARE.PlayJoy
	clampNeeds(record)
	addCareXP(player, entity.CreatureId, record, CARE.CareXP.Play)
	CreatureService.React(entity, "Play", 4)
	feedback(player, entity, "Playful", 100)
	return true
end

local function rename(player, record, name)
	if type(name) ~= "string" or #name < 1 or #name > 40 then
		return false, "ชื่อยาว 1–20 ตัวอักษร"
	end
	local ok, filtered = pcall(function()
		return TextService:FilterStringAsync(name, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if not ok then
		return false, "ตั้งชื่อไม่สำเร็จ ลองใหม่อีกครั้ง"
	end
	record.Name = filtered
	return true, "ตั้งชื่อใหม่เป็น " .. filtered
end

local function handleAction(player, entityId, action, arg)
	if type(entityId) ~= "string" or type(action) ~= "string" then
		return false
	end
	local entity = CreatureService.Find(entityId)
	if not entity or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return false, "ไม่พบสัตว์ตัวนี้"
	end
	if not within(player, entity, 14) then
		return false, "เข้าไปใกล้อีกนิด"
	end
	local result, message
	if entity.Wild then
		if entity.QuestFor and entity.QuestFor ~= player then
			return false, "ผู้พิทักษ์คนอื่นกำลังดูแลตัวนี้อยู่"
		end
		if onCooldown(player, entity, TRUST.InteractCooldown) and action ~= "Bond" then
			return false, "ค่อย ๆ นะ ให้เวลามันสักครู่"
		end
		if action == "Offer" then
			result, message = offer(player, entity, arg)
		elseif action == "Calm" then
			result, message = calm(player, entity)
		elseif action == "Bond" then
			result, message = bond(player, entity)
		end
	else
		if entity.Owner ~= player then
			return false, "นี่คือสัตว์ของผู้พิทักษ์คนอื่น"
		end
		local record = ownedRecord(player, entity)
		if not record then
			return false
		end
		if action == "Feed" then
			result, message = feed(player, entity, record, arg)
		elseif action == "Pet" then
			result, message = pet(player, entity, record)
		elseif action == "Play" then
			result, message = play(player, entity, record)
		elseif action == "Follow" then
			entity.Following = not entity.Following
			record.Following = entity.Following
			result, message = true, entity.Following and (record.Name .. " จะเดินตามคุณ") or (record.Name .. " กลับไปเล่นที่บ้าน")
		elseif action == "Rename" then
			result, message = rename(player, record, arg)
			entity.Model:SetAttribute("DisplayName", record.Name)
		end
	end
	if result then
		DataService.Push(player)
	end
	return result, message
end

-- ===== needs tick =====
local function tickNeeds()
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			for creatureId, record in data.Creatures do
				if record.Stage ~= "Egg" then
					local sleeping = false
					for _, entity in CreatureService.Entities do
						if entity.Owner == player and entity.CreatureId == creatureId then
							sleeping = entity.State == "Sleep"
							entity.Needs = record
						end
					end
					record.Hunger -= CARE.HungerPerTick
					record.Joy -= CARE.JoyPerTick * (record.Hunger < 30 and 2 or 1)
					record.Energy += sleeping and CARE.SleepEnergyPerTick or -CARE.EnergyPerTick
					-- Cozy: สัตว์ไม่มีวันป่วยหนักหรือตาย ค่าต่ำสุด 10
					record.Hunger = math.max(10, record.Hunger)
					record.Joy = math.max(10, record.Joy)
					record.Energy = math.max(10, record.Energy)
					clampNeeds(record)
				end
			end
		end
	end
end

local function applyOfflineDecay(_player, data)
	local hours = math.min((os.time() - (data.LastOnline or os.time())) / 3600, CARE.OfflineDecayCapHours)
	if hours <= 0 then
		return
	end
	local ticks = hours * 3600 / CARE.TickSeconds
	for _, record in data.Creatures do
		if record.Stage ~= "Egg" then
			record.Hunger = math.max(20, record.Hunger - CARE.HungerPerTick * ticks * 0.5)
			record.Joy = math.max(20, record.Joy - CARE.JoyPerTick * ticks * 0.5)
			record.Energy = math.min(100, record.Energy + 20) -- ได้นอนพักระหว่างที่คุณไม่อยู่
		end
	end
end

-- ===== สัตว์บาดเจ็บสำหรับภารกิจช่วยเหลือ (ต่อผู้เล่น) =====
local function ensureRescueCreature(player, data)
	local active = data.Quests.Active.q04_rescue or data.Quests.Active.q05_bond
	if not active then
		return
	end
	local existing = rescueEntities[player] and CreatureService.Find(rescueEntities[player])
	if existing then
		return
	end
	local elder = WorldLayout.Features[1].Center
	local entity = CreatureService.Spawn({
		Species = "spirit_kitsune",
		Stage = "Baby",
		Position = elder + Vector3.new(14 + player.UserId % 7, 0, 10),
		Home = elder,
		Radius = 18,
		Personality = "Shy",
		Injured = data.Quests.Active.q04_rescue ~= nil,
		QuestFor = player,
	})
	entity.Model:SetAttribute("QuestFor", player.UserId)
	rescueEntities[player] = entity.Id
end

function CreatureCare.Init()
	Net.Handle("CreatureAction", handleAction, 0.3)

	Net.Event("SetSneaking").OnServerEvent:Connect(function(player, sneaking)
		player:SetAttribute("Sneaking", sneaking == true)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = sneaking and Config.SneakWalkSpeed or Config.NormalWalkSpeed
		end
	end)

	DataService.OnLoaded(applyOfflineDecay)

	Players.PlayerRemoving:Connect(function(player)
		if rescueEntities[player] then
			CreatureService.Despawn(rescueEntities[player])
			rescueEntities[player] = nil
		end
	end)

	task.spawn(function()
		while true do
			task.wait(CARE.TickSeconds)
			tickNeeds()
			for _, player in Players:GetPlayers() do
				DataService.Push(player)
			end
		end
	end)

	-- ความไว้วางใจของสัตว์ป่าค่อย ๆ ลดลงเมื่อผู้เล่นจากไป + ดูแลสัตว์ภารกิจ
	task.spawn(function()
		while true do
			task.wait(5)
			for _, entity in CreatureService.Entities do
				if entity.Wild then
					for userId, trust in entity.Trust do
						local player = Players:GetPlayerByUserId(userId)
						local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if not root or (root.Position - entity.Root.Position).Magnitude > 80 then
							entity.Trust[userId] = math.max(0, trust - TRUST.DecayPerMinute / 12)
						end
					end
				end
			end
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data then
					ensureRescueCreature(player, data)
				end
			end
		end
	end)
end

return CreatureCare
