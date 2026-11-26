--[[
	QuestService — ภารกิจเนื้อเรื่อง + การค้นพบ (Bestiary / Landmark)
	ระบบอื่นเรียก QuestService.Progress(player, Type, Target, amount) เมื่อเกิดเหตุการณ์
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Quests)
local Species = require(Shared.Species)
local Net = require(Shared.Net)
local DataService = require(script.Parent.Parent.Data.DataService)
local Inventory = require(script.Parent.Inventory)

local QuestService = {}

local function objectiveMatches(objective, kind, target)
	return objective.Type == kind and (objective.Target == "any" or objective.Target == target)
end

local function completeQuest(player, data, questId)
	local quest = Quests.ById[questId]
	data.Quests.Active[questId] = nil
	data.Quests.Done[questId] = os.time()
	Inventory.Grant(player, quest.Rewards)
	Inventory.Notify(player, "📜 ภารกิจสำเร็จ: " .. quest.Title, "quest")
	if quest.Next and not data.Quests.Done[quest.Next] then
		data.Quests.Active[quest.Next] = {}
		data.Quests.Tracked = quest.Next
		Inventory.Notify(player, "ภารกิจใหม่: " .. Quests.ById[quest.Next].Title, "quest")
	elseif data.Quests.Tracked == questId then
		data.Quests.Tracked = next(data.Quests.Active)
	end
end

function QuestService.Progress(player, kind, target, amount)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local changed = false
	-- คัดลอกรายการก่อน เพราะการจบภารกิจจะเพิ่ม/ลบ key ใน Active ระหว่างวนลูป
	local activeIds = {}
	for questId in data.Quests.Active do
		table.insert(activeIds, questId)
	end
	for _, questId in activeIds do
		local quest = Quests.ById[questId]
		local progress = data.Quests.Active[questId]
		if quest and progress then
			for index, objective in quest.Objectives do
				local key = tostring(index)
				local current = progress[key] or 0
				if current < objective.Count and objectiveMatches(objective, kind, target) then
					progress[key] = math.min(objective.Count, current + (amount or 1))
					changed = true
				end
			end
			local done = true
			for index, objective in quest.Objectives do
				if (progress[tostring(index)] or 0) < objective.Count then
					done = false
				end
			end
			if done then
				completeQuest(player, data, questId)
			end
		end
	end
	if changed then
		DataService.Push(player)
	end
end

-- ===== การค้นพบสัตว์ (Bestiary) =====
function QuestService.Discover(player, speciesId)
	local data = DataService.Get(player)
	if not data or not Species.ById[speciesId] then
		return
	end
	local entry = data.Bestiary[speciesId]
	if not entry then
		data.Bestiary[speciesId] = { Seen = 1, FirstSeen = os.time(), Bonded = false }
		Net.Event("Discovery"):FireClient(player, "Species", speciesId)
		Inventory.AddXP(player, 25)
		QuestService.Progress(player, "Discover", speciesId, 1)
		DataService.Push(player)
	else
		entry.Seen += 1
	end
end

function QuestService.DiscoverLandmark(player, landmarkId, name)
	local data = DataService.Get(player)
	if not data or data.Landmarks[landmarkId] then
		return
	end
	data.Landmarks[landmarkId] = os.time()
	Net.Event("Discovery"):FireClient(player, "Landmark", landmarkId, name)
	Inventory.AddXP(player, 30)
	QuestService.Progress(player, "Landmark", landmarkId, 1)
	DataService.Push(player)
end

function QuestService.Init(discoverables, npcLookup)
	Net.Handle("TrackQuest", function(player, questId)
		local data = DataService.Get(player)
		if data and type(questId) == "string" and data.Quests.Active[questId] then
			data.Quests.Tracked = questId
			DataService.Push(player)
			return true
		end
		return false
	end)

	Net.Handle("TalkToNpc", function(player, npcId)
		if type(npcId) ~= "string" then
			return false
		end
		local npc = npcLookup(npcId)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not npc or not root or (root.Position - npc.Position).Magnitude > 16 then
			return false, "เดินเข้าไปใกล้อีกนิด"
		end
		QuestService.Progress(player, "Talk", npcId, 1)
		return true, npc.Role
	end, 0.5)

	-- ตรวจการค้นพบสถานที่ทุก 1 วินาที
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local data = DataService.Get(player)
				if root and data then
					for id, d in discoverables do
						if not data.Landmarks[id] and (root.Position - d.Position).Magnitude < d.Radius then
							QuestService.DiscoverLandmark(player, id, d.Name)
						end
					end
				end
			end
		end
	end)
end

return QuestService
