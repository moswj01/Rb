--[[
	RoundService — มินิเกมสลับกัน 2 โหมด
	1) 👗 แฟชั่นโชว์ (Showdown): ประกาศธีม → แต่งตัว → เดินแบบบนรันเวย์ → ทุกคนโหวตดาว
	   คะแนน = ดาวเฉลี่ย + โบนัสใส่ของ "ตรงธีม" + โบนัสความหายาก  ⇒ อยากได้ของสวยเพื่อชนะ
	2) 🎨 พื้นสีวิบวับ (ColorFloor): ยืนบนสีที่ประกาศ ใครตกสไลม์ก็กลับเกาะ
	ไม่มีการตาย ไม่มีความรุนแรง แพ้ก็ยังได้รางวัล
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ItemCatalog = require(Shared.ItemCatalog)

local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local CosmeticService = require(script.Parent.CosmeticService)
local ProgressService = require(script.Parent.ProgressService)

local RoundService = {}

local rng = Random.new()
local map

local function broadcast(state)
	Remotes.RoundState:FireAllClients(state)
end

local function teleport(player, cframe)
	local character = player.Character
	if character then
		character:PivotTo(cframe)
	end
end

local function sendToLobby(player)
	teleport(player, map.Spawn.CFrame + Vector3.new(rng:NextNumber(-6, 6), 4, rng:NextNumber(-6, 6)))
end

local function canJoin(player)
	if not DataService.Get(player) or player:GetAttribute("SkipRounds") then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return character ~= nil and character:FindFirstChild("HumanoidRootPart") ~= nil and humanoid ~= nil and humanoid.Health > 0
end

local function getParticipants()
	local list = {}
	for _, player in Players:GetPlayers() do
		if canJoin(player) then
			table.insert(list, player)
		end
	end
	return list
end

local function reward(player, coins, xp)
	local gained = DataService.AddCoins(player, coins)
	ProgressService.AddXP(player, xp)
	DataService.Push(player)
	return gained
end

local function finishRoundFor(player)
	local data = DataService.Get(player)
	if data then
		data.Stats.Rounds += 1
		ProgressService.Tutorial(player, "Round", 1)
		ProgressService.CheckAchievements(player)
	end
end

-- =====================================================================
-- 🎨 พื้นสีวิบวับ
-- =====================================================================

local C = Color3.fromRGB
local COLORS = {
	{ Name = "แดง", Color = C(255, 80, 80) },
	{ Name = "ส้ม", Color = C(255, 160, 50) },
	{ Name = "เหลือง", Color = C(255, 230, 60) },
	{ Name = "เขียว", Color = C(90, 220, 100) },
	{ Name = "ฟ้า", Color = C(70, 170, 255) },
	{ Name = "ม่วง", Color = C(180, 100, 255) },
}

local alive = {}

local function aliveCount()
	local n = 0
	for _ in alive do
		n += 1
	end
	return n
end

local function eliminate(player)
	if not alive[player] then
		return
	end
	alive[player] = nil
	task.defer(sendToLobby, player)
	Remotes.Notify(player, "ป๋อม! ตกลงบ่อสไลม์ 😆 รอบหน้าเอาใหม่นะ", "info")
end

local function isOut(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return true
	end
	return root.Position.Y < map.ArenaCenter.Y - 6
end

local function randomizeTiles()
	for _, tile in map.Tiles do
		local index = rng:NextInteger(1, #COLORS)
		tile.Color = COLORS[index].Color
		tile:SetAttribute("ColorIndex", index)
		tile.Transparency = 0
		tile.CanCollide = true
	end
end

local function resetTiles()
	for _, tile in map.Tiles do
		tile.Color = Color3.new(1, 1, 1)
		tile.Transparency = 0
		tile.CanCollide = true
	end
end

local function runColorFloor()
	local cfg = Config.ColorFloor
	local participants = getParticipants()
	if #participants < Config.MinPlayersForRound then
		return false
	end
	randomizeTiles()
	for _, player in participants do
		alive[player] = true
		local tile = map.Tiles[rng:NextInteger(1, #map.Tiles)]
		teleport(player, tile.CFrame + Vector3.new(0, 4, 0))
	end
	broadcast({ Phase = "Starting", Mode = "ColorFloor", Time = 3 })
	task.wait(3)

	for wave = 1, cfg.Waves do
		if aliveCount() == 0 then
			break
		end
		local time = math.max(cfg.MinTime, cfg.StartTime - (wave - 1) * cfg.TimeStep)
		local target = map.Tiles[rng:NextInteger(1, #map.Tiles)]:GetAttribute("ColorIndex")
		local color = COLORS[target]
		broadcast({ Phase = "Wave", Wave = wave, MaxWave = cfg.Waves, ColorName = color.Name, Color = color.Color, Time = time, Alive = aliveCount() })
		task.wait(time)
		for _, tile in map.Tiles do
			if tile:GetAttribute("ColorIndex") ~= target then
				tile.Transparency = 1
				tile.CanCollide = false
			end
		end
		task.wait(2.5)
		for player in alive do
			if isOut(player) then
				eliminate(player)
			end
		end
		for player in alive do
			local gained = reward(player, cfg.RewardPerWave, Config.XP.WaveSurvived)
			Remotes.CoinPopup:FireClient(player, gained, nil, false)
		end
		randomizeTiles()
		task.wait(1)
	end

	local winners = {}
	for player in alive do
		local data = DataService.Get(player)
		if data then
			data.Stats.Wins += 1
			reward(player, cfg.RewardWin, Config.XP.ColorFloorWin)
			Remotes.Notify(player, "🏆 ชนะแล้ว! เก่งมาก ได้รับโบนัส 🪙 " .. cfg.RewardWin, "good")
			table.insert(winners, player.DisplayName)
		end
	end
	broadcast({ Phase = "Results", Winners = winners, Time = 5 })
	task.wait(4)
	for player in alive do
		sendToLobby(player)
	end
	table.clear(alive)
	resetTiles()
	for _, player in participants do
		if player.Parent then
			finishRoundFor(player)
		end
	end
	return true
end

-- =====================================================================
-- 👗 แฟชั่นโชว์
-- =====================================================================

local show = nil -- { Theme, CurrentModel, Votes = {[modelUserId] = {[voterUserId] = stars}} }

local function outfitScore(player, theme)
	local outfit = CosmeticService.GetVisibleOutfit(player)
	local themeItems, rarityBonus = 0, 0
	for _, itemId in outfit do
		local item = ItemCatalog.ById[itemId]
		if item and item.Id ~= "skin_classic" then
			if item.Set == theme.Set then
				themeItems += 1
			end
			rarityBonus += Config.Showdown.RarityBonus[item.Rarity] or 0
		end
	end
	return themeItems * Config.Showdown.ThemeBonusPerItem + rarityBonus, themeItems
end

local function vote(player, targetUserId, stars)
	if not show or not show.CurrentModel then
		return false, "ตอนนี้ยังโหวตไม่ได้"
	end
	if type(targetUserId) ~= "number" or type(stars) ~= "number" then
		return false, "ไม่ถูกต้อง"
	end
	stars = math.clamp(math.floor(stars), 1, 5)
	if targetUserId ~= show.CurrentModel.UserId then
		return false, "หมดเวลาโหวตคนนี้แล้ว"
	end
	if player.UserId == targetUserId then
		return false, "โหวตตัวเองไม่ได้นะ 😆"
	end
	local votes = show.Votes[targetUserId]
	local first = votes[player.UserId] == nil
	votes[player.UserId] = stars
	if first then
		ProgressService.AddXP(player, Config.XP.Vote)
	end
	return true, "โหวต " .. string.rep("⭐", stars) .. " แล้ว!"
end

local function runShowdown()
	local cfg = Config.Showdown
	local participants = getParticipants()
	if #participants < Config.MinPlayersForRound then
		return false
	end
	local theme = Config.ShowdownThemes[rng:NextInteger(1, #Config.ShowdownThemes)]
	show = { Theme = theme, CurrentModel = nil, Votes = {} }

	-- 1) แต่งตัวหลังเวที
	for i, player in participants do
		teleport(player, map.Runway.Backstage * CFrame.new((i % 5 - 2) * 3, 4, math.floor(i / 5) * 3))
	end
	broadcast({ Phase = "Dress", Mode = "Showdown", ThemeName = theme.Name, ThemeIcon = theme.Icon, ThemeSet = theme.Set, Time = cfg.DressTime })
	task.wait(cfg.DressTime)

	-- 2) เดินแบบทีละคน
	local models = {}
	for _, player in participants do
		if player.Parent and player.Character then
			table.insert(models, player)
		end
	end
	for i = #models, 2, -1 do
		local j = rng:NextInteger(1, i)
		models[i], models[j] = models[j], models[i]
	end
	while #models > cfg.MaxModels do
		table.remove(models)
	end

	for index, model in models do
		if model.Parent and model.Character then
			CosmeticService.ClearTryOn(model)
			model:SetAttribute("OnRunway", true)
			show.Votes[model.UserId] = {}
			show.CurrentModel = model
			teleport(model, map.Runway.Start)
			local humanoid = model.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:MoveTo(map.Runway.End.Position)
			end
			local bonus, themeItems = outfitScore(model, theme)
			broadcast({
				Phase = "Runway",
				ModelUserId = model.UserId,
				ModelName = model.DisplayName,
				Index = index,
				Total = #models,
				ThemeItems = themeItems,
				Bonus = bonus,
				ThemeName = theme.Name,
				ThemeIcon = theme.Icon,
				Time = cfg.WalkTime,
			})
			task.wait(cfg.WalkTime)
			show.CurrentModel = nil
			model:SetAttribute("OnRunway", nil)
			teleport(model, map.Runway.Audience * CFrame.new(rng:NextNumber(-8, 8), 4, rng:NextNumber(-3, 3)))
		end
	end

	-- 3) สรุปคะแนน
	local results = {}
	for _, model in models do
		if model.Parent then
			local votes = show.Votes[model.UserId] or {}
			local total, count = 0, 0
			for _, stars in votes do
				total += stars
				count += 1
			end
			local average = count > 0 and total / count or 3
			local bonus = outfitScore(model, theme)
			table.insert(results, { Player = model, Score = average + bonus, Votes = count })
		end
	end
	table.sort(results, function(a, b)
		return a.Score > b.Score
	end)

	local top = {}
	for rank, result in results do
		local player = result.Player
		local coins = cfg.Rewards[rank] or cfg.Participation
		local xp = rank <= 3 and Config.XP.ShowdownTop3 or Config.XP.ShowdownJoin
		reward(player, coins, xp)
		if rank == 1 then
			local data = DataService.Get(player)
			if data then
				data.Stats.ShowdownWins += 1
			end
		end
		if rank <= 3 then
			table.insert(top, { Name = player.DisplayName, UserId = player.UserId, Score = math.floor(result.Score * 10 + 0.5) / 10 })
			teleport(player, map.Runway.Podium[rank] + Vector3.new(0, 4, 0))
			Remotes.Notify(player, string.format("🏅 อันดับ %d แฟชั่นโชว์! ได้รับ 🪙 %d", rank, coins), "good")
		else
			Remotes.Notify(player, "👏 เดินแบบสวยมาก! ได้รับ 🪙 " .. coins, "info")
		end
	end
	broadcast({ Phase = "ShowdownResults", Top = top, ThemeName = theme.Name, ThemeIcon = theme.Icon, Time = 8 })
	if top[1] then
		Remotes.Announce:FireAllClients(string.format("👑 %s ชนะแฟชั่นโชว์ธีม %s %s!", top[1].Name, theme.Icon, theme.Name), "Legendary")
	end
	task.wait(8)

	for _, player in participants do
		if player.Parent then
			sendToLobby(player)
			finishRoundFor(player)
		end
	end
	show = nil
	return true
end

-- =====================================================================

function RoundService.Init(builtMap)
	map = builtMap
	Remotes.Vote.OnServerInvoke = vote

	map.Slime.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			if alive[player] then
				eliminate(player)
			else
				sendToLobby(player)
			end
		end
	end)

	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 0.25 then
			return
		end
		accumulator = 0
		for player in alive do
			if not player.Parent or isOut(player) then
				eliminate(player)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		alive[player] = nil
	end)

	task.spawn(function()
		local modeIndex = 0
		while true do
			modeIndex = modeIndex % #Config.RoundModes + 1
			local mode = Config.RoundModes[modeIndex]
			for t = Config.IntermissionTime, 1, -1 do
				broadcast({ Phase = "Intermission", Mode = mode, Time = t })
				task.wait(1)
			end
			local ok, result = pcall(mode == "Showdown" and runShowdown or runColorFloor)
			if not ok then
				warn("[RoundService] error:", result)
				table.clear(alive)
				resetTiles()
				show = nil
			elseif not result then
				broadcast({ Phase = "Waiting" })
				task.wait(3)
			end
		end
	end)
end

return RoundService
