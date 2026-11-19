--[[
	MonetizationService — ระบบ Robux
	Developer Products: เพชร, ชุดเซ็ต (Bundle), Starter Pack, ข้ามขั้น Party Pass
	Game Passes: VIP, เหรียญ x2, Party Pass พรีเมียม

	ความปลอดภัย: เก็บ PurchaseId กันให้ของซ้ำ + บันทึก DataStore สำเร็จก่อนยืนยันกับ Roblox
	ถ้าบันทึกไม่ได้จะ "ย้อนข้อมูลกลับ" แล้วให้ Roblox ส่ง receipt มาใหม่ภายหลัง
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ItemCatalog = require(Shared.ItemCatalog)

local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local CosmeticService = require(script.Parent.CosmeticService)
local Rewards = require(script.Parent.Rewards)
local ProgressService = require(script.Parent.ProgressService)
local Analytics = require(script.Parent.Analytics)

local MonetizationService = {}

local MAX_RECEIPT_HISTORY = 100
local handlers = {} -- [ProductId] = function(player, data) -> message

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

local function register(productId, handler)
	if productId and productId ~= 0 then
		assert(handlers[productId] == nil, "ProductId ซ้ำใน Config: " .. productId)
		handlers[productId] = handler
	end
end

-- ===== Developer Products =====

for _, pack in Config.GemPacks do
	register(pack.ProductId, function(player)
		DataService.AddGems(player, pack.Gems, { Reason = "IAP", Sku = pack.Key })
		return string.format("💎 +%d เพชร", pack.Gems)
	end)
end

for _, bundle in Config.Bundles do
	register(bundle.ProductId, function(player)
		local set = ItemCatalog.SetById[bundle.Set]
		for _, item in ItemCatalog.GetBySet(bundle.Set) do
			Rewards.GiveItem(player, item.Id, { NoAnnounce = true, Silent = true })
		end
		DataService.AddGems(player, bundle.BonusGems, { Reason = "IAP", Sku = bundle.Key })
		Remotes.Announce:FireAllClients(string.format("🎉 %s ได้ชุด %s %s ครบเซ็ต!", player.DisplayName, set.Icon, set.Name), "Mythic")
		return string.format("ชุด %s %s ครบเซ็ต + 💎 %d", set.Icon, set.Name, bundle.BonusGems)
	end)
end

register(Config.StarterPack.ProductId, function(player, data)
	data.StarterBought = true
	DataService.AddGems(player, Config.StarterPack.Gems, { Reason = "IAP", Sku = "starter_pack" })
	DataService.AddCoins(player, Config.StarterPack.Coins, { NoMultiplier = true, Reason = "IAP", Sku = "starter_pack" })
	for _, itemId in Config.StarterPack.Items do
		Rewards.GiveItem(player, itemId, { NoAnnounce = true })
	end
	return "🚀 Starter Pack: ของพิเศษ 3 ชิ้น + 💎 " .. Config.StarterPack.Gems .. " + 🪙 " .. Config.StarterPack.Coins
end)

register(Config.TierSkip.ProductId, function(player)
	ProgressService.AddTiers(player, Config.TierSkip.Tiers)
	return "🎫 ข้าม " .. Config.TierSkip.Tiers .. " ขั้น Party Pass!"
end)

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and DataService.Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(data.Purchases, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local handler = handlers[receipt.ProductId]
	if not handler then
		warn("[Monetization] ไม่รู้จัก ProductId:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local backup = deepCopy(data)
	local ok, message = pcall(handler, player, data)
	if not ok then
		warn("[Monetization] handler error:", message)
		DataService.Restore(player, backup)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	table.insert(data.Purchases, receipt.PurchaseId)
	while #data.Purchases > MAX_RECEIPT_HISTORY do
		table.remove(data.Purchases, 1)
	end
	data.Stats.RobuxPurchases += 1

	if not DataService.Save(player) then
		DataService.Restore(player, backup)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	DataService.Push(player)
	CosmeticService.Apply(player)
	Analytics.Custom(player, "RobuxPurchase", receipt.CurrencySpent)
	Remotes.Notify(player, "ขอบคุณที่สนับสนุนนะ! 💖 " .. tostring(message), "good")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ===== Game Passes =====

local function grantPass(player, passName)
	if player:GetAttribute(passName) then
		return
	end
	player:SetAttribute(passName, true)
	local data = DataService.Get(player)
	if passName == "VIP" and data then
		for _, item in ItemCatalog.List do
			if item.Exclusive == "VIP" then
				data.Owned[item.Id] = true
			end
		end
		if not data.Equipped.Title then
			data.Equipped.Title = "title_vip"
		end
		DataService.Push(player)
	end
	CosmeticService.Apply(player)
end

local function checkPasses(player)
	for passName, pass in Config.GamePasses do
		if Config.StudioGrantAllPasses and RunService:IsStudio() then
			grantPass(player, passName)
		elseif pass.Id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
			end)
			if ok and owns then
				grantPass(player, passName)
			end
		end
	end
end

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for passName, pass in Config.GamePasses do
			if pass.Id == passId then
				grantPass(player, passName)
				Remotes.Notify(player, "ปลดล็อก " .. pass.Icon .. " " .. pass.Name .. " แล้ว! ขอบคุณมาก 💖", "good")
				Remotes.Announce:FireAllClients(string.format("💖 %s ปลดล็อก %s %s!", player.DisplayName, pass.Icon, pass.Name), "Legendary")
			end
		end
	end)

	DataService.OnLoaded(checkPasses)
end

return MonetizationService
