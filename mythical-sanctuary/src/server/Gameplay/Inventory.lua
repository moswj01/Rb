-- Inventory — ของ / เงิน (Lumen) / XP / เลเวล (ฝั่งเซิร์ฟเวอร์เท่านั้น)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Net = require(Shared.Net)
local DataService = require(script.Parent.Parent.Data.DataService)

local Inventory = {}

function Inventory.Notify(player, text, kind)
	Net.Event("Notify"):FireClient(player, text, kind or "info")
end

function Inventory.Count(player, itemId)
	local data = DataService.Get(player)
	return data and (data.Inventory[itemId] or 0) or 0
end

function Inventory.Add(player, itemId, amount)
	local data = DataService.Get(player)
	if not data or not Items.ById[itemId] or amount <= 0 then
		return false
	end
	data.Inventory[itemId] = (data.Inventory[itemId] or 0) + amount
	return true
end

function Inventory.Remove(player, itemId, amount)
	local data = DataService.Get(player)
	if not data or (data.Inventory[itemId] or 0) < amount then
		return false
	end
	data.Inventory[itemId] -= amount
	if data.Inventory[itemId] <= 0 then
		data.Inventory[itemId] = nil
	end
	return true
end

function Inventory.HasAll(player, inputs)
	for itemId, amount in inputs do
		if Inventory.Count(player, itemId) < amount then
			return false
		end
	end
	return true
end

function Inventory.AddCoins(player, amount)
	local data = DataService.Get(player)
	if data then
		data.Coins = math.max(0, data.Coins + amount)
	end
end

function Inventory.SpendCoins(player, amount)
	local data = DataService.Get(player)
	if not data or amount < 0 or data.Coins < amount then
		return false
	end
	data.Coins -= amount
	return true
end

function Inventory.AddXP(player, amount)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.XP += amount
	while data.XP >= Config.LevelXP(data.Level) do
		data.XP -= Config.LevelXP(data.Level)
		data.Level += 1
		Inventory.Notify(player, "✦ เลเวลอัป! ตอนนี้คุณเป็นผู้พิทักษ์ระดับ " .. data.Level, "level")
	end
end

-- reward = { Coins, XP, Items = {id = n} }
function Inventory.Grant(player, reward)
	if reward.Coins then
		Inventory.AddCoins(player, reward.Coins)
	end
	if reward.XP then
		Inventory.AddXP(player, reward.XP)
	end
	for itemId, amount in reward.Items or {} do
		Inventory.Add(player, itemId, amount)
	end
end

return Inventory
