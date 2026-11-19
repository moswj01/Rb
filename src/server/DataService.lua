--[[
	DataService — โหลด/บันทึกข้อมูลผู้เล่นด้วย DataStore
	- retry อัตโนมัติ, autosave, บันทึกตอนออกเกมและตอนปิดเซิร์ฟเวอร์
	- ใน Studio ถ้ายังไม่เปิด "Enable Studio Access to API Services" จะใช้ข้อมูลชั่วคราว (ไม่บันทึก)
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ItemCatalog = require(Shared.ItemCatalog)
local Remotes = require(script.Parent.Remotes)

local DataService = {}

local profiles = {} -- [Player] = data
local noSave = {} -- [Player] = true (ข้อมูลชั่วคราวใน Studio)
local loadedSignal = Instance.new("BindableEvent")

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore ใช้งานไม่ได้:", result)
	end
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function reconcile(data, template)
	for key, value in template do
		if data[key] == nil then
			data[key] = deepCopy(value)
		elseif type(value) == "table" and type(data[key]) == "table" then
			reconcile(data[key], value)
		end
	end
	return data
end

local function makeTemplate()
	local owned = {}
	for _, item in ItemCatalog.List do
		if item.Default then
			owned[item.Id] = true
		end
	end
	return {
		Coins = Config.StartingCoins,
		Gems = Config.StartingGems,
		Owned = owned,
		Equipped = { Skin = "skin_classic" },
		Daily = { Last = 0, Streak = 0 },
		Codes = {},
		Stats = { Wins = 0, Stars = 0, Rounds = 0, Spent = 0 },
		Settings = { SkipRounds = false },
		Purchases = {}, -- PurchaseId ของ Robux ที่ให้ของไปแล้ว (กันให้ซ้ำ)
	}
end

local TEMPLATE = makeTemplate()

local function keyFor(player)
	return "u_" .. player.UserId
end

local function setupLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "เหรียญ"
	coins.Value = data.Coins
	coins.Parent = leaderstats

	local wins = Instance.new("IntValue")
	wins.Name = "ชนะ"
	wins.Value = data.Stats.Wins
	wins.Parent = leaderstats

	leaderstats.Parent = player
end

local function snapshot(data)
	local copy = table.clone(data)
	copy.Purchases = nil
	return copy
end

local function loadPlayer(player)
	local data, ok, err
	if store then
		for attempt = 1, 3 do
			ok, err = pcall(function()
				data = store:GetAsync(keyFor(player))
			end)
			if ok then
				break
			end
			warn(string.format("[DataService] โหลดข้อมูล %s ไม่สำเร็จ (ครั้งที่ %d): %s", player.Name, attempt, tostring(err)))
			task.wait(attempt * 2)
		end
	end

	if not player.Parent then
		return
	end

	if not ok then
		if RunService:IsStudio() then
			warn("[DataService] Studio: ใช้ข้อมูลชั่วคราว (เปิด Game Settings > Security > Enable Studio Access to API Services เพื่อบันทึกจริง)")
			noSave[player] = true
			data = nil
		else
			player:Kick("โหลดข้อมูลไม่สำเร็จ 🙏 กรุณาเข้าเกมใหม่อีกครั้งนะ")
			return
		end
	end

	if type(data) ~= "table" then
		data = deepCopy(TEMPLATE)
	end
	reconcile(data, TEMPLATE)

	profiles[player] = data
	setupLeaderstats(player, data)
	player:SetAttribute("SkipRounds", data.Settings.SkipRounds == true)
	player:SetAttribute("DataLoaded", true)

	DataService.Push(player)
	loadedSignal:Fire(player)
end

-- ===== API =====

function DataService.Get(player)
	return profiles[player]
end

function DataService.OnLoaded(callback)
	for player in profiles do
		task.spawn(callback, player)
	end
	return loadedSignal.Event:Connect(callback)
end

-- ส่งข้อมูลล่าสุดให้ client + อัปเดต leaderstats
function DataService.Push(player)
	local data = profiles[player]
	if not data then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats["เหรียญ"].Value = data.Coins
		leaderstats["ชนะ"].Value = data.Stats.Wins
	end
	Remotes.DataChanged:FireClient(player, snapshot(data))
end

-- ให้เหรียญ (คูณ 2 อัตโนมัติถ้ามี Game Pass DoubleCoins) คืนค่าจำนวนที่ได้จริง
function DataService.AddCoins(player, amount, options)
	local data = profiles[player]
	if not data or amount == 0 then
		return 0
	end
	if amount > 0 and player:GetAttribute("DoubleCoins") and not (options and options.NoMultiplier) then
		amount *= 2
	end
	data.Coins = math.max(0, data.Coins + amount)
	return amount
end

function DataService.AddGems(player, amount)
	local data = profiles[player]
	if not data then
		return 0
	end
	data.Gems = math.max(0, data.Gems + amount)
	return amount
end

-- หักเงิน คืนค่า true ถ้าสำเร็จ
function DataService.Spend(player, currency, amount)
	local data = profiles[player]
	if not data or (currency ~= "Coins" and currency ~= "Gems") then
		return false
	end
	if amount < 0 or data[currency] < amount then
		return false
	end
	data[currency] -= amount
	if currency == "Coins" then
		data.Stats.Spent += amount
	end
	return true
end

function DataService.Save(player)
	local data = profiles[player]
	if not data then
		return false
	end
	if noSave[player] or not store then
		return true
	end
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			store:UpdateAsync(keyFor(player), function()
				return data
			end)
		end)
		if ok then
			return true
		end
		warn(string.format("[DataService] บันทึก %s ไม่สำเร็จ (ครั้งที่ %d): %s", player.Name, attempt, tostring(err)))
		task.wait(attempt)
	end
	return false
end

function DataService.Init()
	Players.PlayerAdded:Connect(loadPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if profiles[player] then
			DataService.Save(player)
		end
		profiles[player] = nil
		noSave[player] = nil
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.Save(player)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveInterval)
			for player in profiles do
				task.spawn(DataService.Save, player)
			end
		end
	end)

	Remotes.GetData.OnServerInvoke = function(player)
		local data = profiles[player]
		return data and snapshot(data) or nil
	end
end

return DataService
