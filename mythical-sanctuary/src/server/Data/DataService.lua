--[[
	DataService — บันทึก/โหลดข้อมูลผู้เล่น
	✔ Session Locking  : กันข้อมูลซ้อนเมื่อผู้เล่นย้ายเซิร์ฟเร็ว ๆ (ล็อกด้วย JobId + เวลา)
	✔ Retry/Backoff    : ทุกการเรียก DataStore
	✔ Data Migration   : อัปเกรดข้อมูลเวอร์ชันเก่าอัตโนมัติ (Config.DataVersion)
	✔ Autosave + BindToClose
	✔ Studio fallback  : ถ้าไม่ได้เปิด API Services จะใช้ข้อมูลชั่วคราว
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Quests = require(Shared.Quests)
local Net = require(Shared.Net)

local DataService = {}

local profiles = {} -- [Player] = data
local temporary = {} -- [Player] = true
local loadedEvent = Instance.new("BindableEvent")
local releasing = {}

local store
pcall(function()
	store = DataStoreService:GetDataStore(Config.DataStoreName)
end)

local function deepCopy(v)
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in v do
		out[k] = deepCopy(x)
	end
	return out
end

local function template()
	local inventory = {}
	for id, n in Config.StartingItems do
		inventory[id] = n
	end
	return {
		Version = Config.DataVersion,
		Coins = Config.StartingCoins,
		Level = 1,
		XP = 0,
		Inventory = inventory,
		Creatures = {}, -- [creatureId] = { Species, Name, Stage, Personality, Hunger, Energy, Joy, CareXP, Born, ... }
		Bestiary = {}, -- [speciesId] = { Seen = n, FirstSeen = t, Bonded = bool }
		Landmarks = {}, -- [landmarkId] = true
		Quests = { Active = { [Quests.First] = {} }, Done = {}, Tracked = Quests.First },
		Sanctuary = { Objects = {}, NextId = 1, Expansion = 0 },
		Settings = { Music = 0.6, Sfx = 0.8, Graphics = "Auto", ShowHints = true },
		Stats = { Rescued = 0, Bonded = 0, Hatched = 0, Foraged = 0, Brewed = 0 },
		LastOnline = os.time(),
		NextCreatureId = 1,
	}
end

-- ===== Migrations: version N → N+1 =====
local migrations = {
	[1] = function(data)
		-- v1 ยังไม่มีระบบ Settings/Stats แยก
		data.Settings = data.Settings or {}
		data.Stats = data.Stats or {}
	end,
}

local function reconcile(data, base)
	for k, v in base do
		if data[k] == nil then
			data[k] = deepCopy(v)
		elseif type(v) == "table" and type(data[k]) == "table" and next(v) ~= nil then
			-- เติมเฉพาะตารางที่มีโครงสร้าง (ไม่เติม dictionary แบบไดนามิก เช่น Inventory)
			if k == "Settings" or k == "Stats" or k == "Sanctuary" or k == "Quests" then
				reconcile(data[k], v)
			end
		end
	end
end

local function migrate(data)
	local version = data.Version or 1
	while version < Config.DataVersion do
		local step = migrations[version]
		if step then
			step(data)
		end
		version += 1
	end
	data.Version = Config.DataVersion
	reconcile(data, template())
	return data
end

local function withRetry(fn, label)
	local delay = 1
	-- Studio ที่ยังไม่เปิด API Services จะ error ทุกครั้ง → ลองครั้งเดียวแล้วใช้ข้อมูลชั่วคราวทันที
	local attempts = RunService:IsStudio() and 1 or 5
	for attempt = 1, attempts do
		local ok, a, b = pcall(fn)
		if ok then
			return true, a, b
		end
		warn(string.format("[DataService] %s ล้มเหลว (%d/%d): %s", label, attempt, attempts, tostring(a)))
		if attempt < attempts then
			task.wait(delay)
		end
		delay *= 2
	end
	return false
end

local function key(player)
	return "player_" .. player.UserId
end

-- ===== โหลด + ล็อก session =====
local function acquire(player)
	local data, lockedElsewhere = nil, false
	local ok = withRetry(function()
		store:UpdateAsync(key(player), function(old)
			old = old or { Data = nil, Lock = nil }
			local lock = old.Lock
			if lock and lock.JobId ~= game.JobId and os.time() - lock.Time < Config.SessionLockTimeout then
				lockedElsewhere = true
				return nil -- ไม่แก้อะไร
			end
			lockedElsewhere = false
			old.Lock = { JobId = game.JobId, Time = os.time() }
			data = old.Data
			return old
		end)
	end, "acquire " .. player.Name)
	return ok, data, lockedElsewhere
end

local function loadPlayer(player)
	local data
	if store then
		local ok, loaded, locked
		for attempt = 1, 6 do
			ok, loaded, locked = acquire(player)
			if not ok or not locked then
				break
			end
			-- เซิร์ฟเก่ายังปล่อยล็อกไม่เสร็จ: รอแล้วลองใหม่
			task.wait(attempt * 2)
		end
		if not player.Parent then
			return
		end
		if ok and not locked then
			data = loaded and migrate(loaded) or template()
		elseif ok and locked then
			player:Kick("ข้อมูลของคุณยังถูกใช้งานในเซิร์ฟเวอร์อื่น กรุณาเข้าใหม่อีกครั้งในอีกสักครู่")
			return
		end
	end
	if not data then
		if RunService:IsStudio() then
			warn("[DataService] ใช้ข้อมูลชั่วคราว (เปิด Game Settings › Security › Studio Access to API Services เพื่อบันทึกจริง)")
			temporary[player] = true
			data = template()
		else
			player:Kick("โหลดข้อมูลไม่สำเร็จ กรุณาลองใหม่")
			return
		end
	end
	data.SessionStart = os.time()
	profiles[player] = data
	DataService.Push(player)
	loadedEvent:Fire(player, data)
end

-- ===== บันทึก =====
local function save(player, release)
	local data = profiles[player]
	if not data or temporary[player] or not store then
		return true
	end
	data.LastOnline = os.time()
	local payload = HttpService:JSONDecode(HttpService:JSONEncode(data)) -- ตรวจว่า serialize ได้ + ตัด reference
	payload.SessionStart = nil
	return withRetry(function()
		store:UpdateAsync(key(player), function(old)
			old = old or {}
			if old.Lock and old.Lock.JobId ~= game.JobId then
				warn("[DataService] ล็อกถูกเซิร์ฟอื่นยึด ไม่บันทึกทับ:", player.Name)
				return nil
			end
			old.Data = payload
			old.Lock = (not release) and { JobId = game.JobId, Time = os.time() } or nil
			return old
		end)
	end, "save " .. player.Name)
end

-- ===== API =====
function DataService.Get(player)
	return profiles[player]
end

function DataService.OnLoaded(callback)
	for player, data in profiles do
		task.spawn(callback, player, data)
	end
	return loadedEvent.Event:Connect(callback)
end

function DataService.Push(player)
	local data = profiles[player]
	if data then
		Net.Event("ProfileChanged"):FireClient(player, data)
	end
end

function DataService.Save(player)
	return save(player, false)
end

function DataService.NewId(player, prefix)
	local data = profiles[player]
	local id = prefix .. data.NextCreatureId
	data.NextCreatureId += 1
	return id
end

function DataService.Init()
	Net.Handle("GetProfile", function(player)
		return profiles[player]
	end, 0.5)

	Players.PlayerAdded:Connect(loadPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if releasing[player] then
			return
		end
		releasing[player] = true
		save(player, true)
		profiles[player] = nil
		temporary[player] = nil
		releasing[player] = nil
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local start = os.clock()
		while pending > 0 and os.clock() - start < 25 do
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveInterval)
			for player in profiles do
				task.spawn(save, player, false)
			end
		end
	end)
end

return DataService
