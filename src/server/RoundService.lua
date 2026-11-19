--[[
	RoundService — มินิเกม "พื้นสีวิบวับ"
	เกมจะบอกสี → รีบไปยืนบนพื้นสีนั้น → พื้นสีอื่นหายไป → ใครตกลงบ่อสไลม์ก็กลับเกาะ (ไม่มีการตาย ไม่มีความรุนแรง)
	รอดทุกเวฟ = ชนะ! ได้เหรียญทุกเวฟที่รอด จึงสนุกแม้ไม่ชนะ
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)

local RoundService = {}

local C = Color3.fromRGB
local COLORS = {
	{ Name = "แดง", Color = C(255, 80, 80) },
	{ Name = "ส้ม", Color = C(255, 160, 50) },
	{ Name = "เหลือง", Color = C(255, 230, 60) },
	{ Name = "เขียว", Color = C(90, 220, 100) },
	{ Name = "ฟ้า", Color = C(70, 170, 255) },
	{ Name = "ม่วง", Color = C(180, 100, 255) },
}

local rng = Random.new()
local map
local alive = {} -- [Player] = true

local function broadcast(state)
	Remotes.RoundState:FireAllClients(state)
end

local function aliveCount()
	local n = 0
	for _ in alive do
		n += 1
	end
	return n
end

local function sendToLobby(player)
	local character = player.Character
	if character then
		local offset = Vector3.new(rng:NextNumber(-6, 6), 4, rng:NextNumber(-6, 6))
		character:PivotTo(map.Spawn.CFrame + offset)
	end
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

local function canJoin(player)
	if not DataService.Get(player) or player:GetAttribute("SkipRounds") then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return character ~= nil and character:FindFirstChild("HumanoidRootPart") ~= nil and humanoid ~= nil and humanoid.Health > 0
end

local function runRound()
	local participants = {}
	for _, player in Players:GetPlayers() do
		if canJoin(player) then
			table.insert(participants, player)
		end
	end
	if #participants < Config.MinPlayersForRound then
		return false
	end

	randomizeTiles()
	for _, player in participants do
		alive[player] = true
		local tile = map.Tiles[rng:NextInteger(1, #map.Tiles)]
		player.Character:PivotTo(tile.CFrame + Vector3.new(0, 4, 0))
		local data = DataService.Get(player)
		data.Stats.Rounds += 1
	end

	broadcast({ Phase = "Starting", Time = 3 })
	task.wait(3)

	for wave = 1, Config.RoundWaves do
		if aliveCount() == 0 then
			break
		end
		local time = math.max(Config.WaveMinTime, Config.WaveStartTime - (wave - 1) * Config.WaveTimeStep)
		local pick = map.Tiles[rng:NextInteger(1, #map.Tiles)]
		local target = pick:GetAttribute("ColorIndex")
		local color = COLORS[target]

		broadcast({
			Phase = "Wave",
			Wave = wave,
			MaxWave = Config.RoundWaves,
			ColorName = color.Name,
			Color = color.Color,
			Time = time,
			Alive = aliveCount(),
		})
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
			local gained = DataService.AddCoins(player, Config.RoundRewardPerWave)
			DataService.Push(player)
			Remotes.CoinPopup:FireClient(player, gained, nil, false)
		end

		randomizeTiles()
		task.wait(1)
	end

	local winners = {}
	for player in alive do
		local data = DataService.Get(player)
		if data then
			DataService.AddCoins(player, Config.RoundRewardWin)
			data.Stats.Wins += 1
			DataService.Push(player)
			Remotes.Notify(player, "🏆 ชนะแล้ว! เก่งมาก ได้รับโบนัส 🪙 " .. Config.RoundRewardWin, "good")
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
	return true
end

function RoundService.Init(builtMap)
	map = builtMap

	-- ตกบ่อสไลม์ = ออกจากรอบทันที
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

	-- ตรวจสำรองเผื่อ Touched พลาด
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
		while true do
			for t = Config.IntermissionTime, 1, -1 do
				broadcast({ Phase = "Intermission", Time = t })
				task.wait(1)
			end
			local ok, result = pcall(runRound)
			if not ok then
				warn("[RoundService] error:", result)
				table.clear(alive)
				resetTiles()
			elseif not result then
				broadcast({ Phase = "Waiting" })
				task.wait(3)
			end
		end
	end)
end

return RoundService
