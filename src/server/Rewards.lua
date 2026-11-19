--[[
	Rewards — ให้รางวัล (เหรียญ/เพชร/ไอเท็ม) จุดเดียว + เอฟเฟกต์ "ได้ของใหม่" + ประกาศทั้งเซิร์ฟ
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ItemCatalog = require(Shared.ItemCatalog)

local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)

local Rewards = {}

-- ให้ไอเท็ม: คืนค่า true ถ้าเป็นของใหม่
function Rewards.GiveItem(player, itemId, options)
	local data = DataService.Get(player)
	local item = ItemCatalog.ById[itemId]
	if not data or not item or data.Owned[itemId] then
		return false
	end
	data.Owned[itemId] = true
	options = options or {}
	if not options.Silent then
		Remotes.Celebrate:FireClient(player, itemId)
	end
	if Config.AnnounceRarities[item.Rarity] and not options.NoAnnounce then
		Remotes.Announce:FireAllClients(
			string.format("🎉 %s ได้รับ %s %s ระดับ%s!", player.DisplayName, item.Icon, item.Name, ItemCatalog.Rarities[item.Rarity].Name),
			item.Rarity
		)
	end
	return true
end

-- reward = { Coins = n, Gems = n, Item = id } คืนข้อความสรุป
function Rewards.Grant(player, reward, reason, sku)
	local parts = {}
	if reward.Coins then
		DataService.AddCoins(player, reward.Coins, { NoMultiplier = true, Reason = reason or "TimedReward", Sku = sku })
		table.insert(parts, "🪙 " .. reward.Coins)
	end
	if reward.Gems then
		DataService.AddGems(player, reward.Gems, { Reason = reason or "TimedReward", Sku = sku })
		table.insert(parts, "💎 " .. reward.Gems)
	end
	if reward.Item then
		local item = ItemCatalog.ById[reward.Item]
		if item then
			Rewards.GiveItem(player, reward.Item)
			table.insert(parts, item.Icon .. " " .. item.Name)
		end
	end
	return table.concat(parts, " + ")
end

return Rewards
