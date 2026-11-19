--[[
	MonetizationService — ระบบ Robux
	- Developer Products: เติมเพชร (ProcessReceipt แบบกันให้ของซ้ำ + บันทึกก่อนยืนยัน)
	- Game Passes: VIP, DoubleCoins
	หลักการ: ขายความสวยงาม ไม่ขายความได้เปรียบในการแข่ง (no pay-to-win) และไม่มีกล่องสุ่ม
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

local MonetizationService = {}

local MAX_RECEIPT_HISTORY = 100

local function packByProductId(productId)
	for _, pack in Config.GemPacks do
		if pack.ProductId ~= 0 and pack.ProductId == productId then
			return pack
		end
	end
	return nil
end

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

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = DataService.Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- เคยให้ของไปแล้ว → ยืนยันซ้ำได้เลย
	if table.find(data.Purchases, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local pack = packByProductId(receipt.ProductId)
	if not pack then
		warn("[Monetization] ไม่รู้จัก ProductId:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	data.Gems += pack.Gems
	table.insert(data.Purchases, receipt.PurchaseId)
	while #data.Purchases > MAX_RECEIPT_HISTORY do
		table.remove(data.Purchases, 1)
	end

	-- ต้องบันทึกให้สำเร็จก่อนบอก Roblox ว่าให้ของแล้ว
	if not DataService.Save(player) then
		data.Gems -= pack.Gems
		local index = table.find(data.Purchases, receipt.PurchaseId)
		if index then
			table.remove(data.Purchases, index)
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	DataService.Push(player)
	Remotes.Notify(player, string.format("ขอบคุณที่สนับสนุนนะ! 💖 ได้รับ 💎 %d", pack.Gems), "good")
	return Enum.ProductPurchaseDecision.PurchaseGranted
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
			end
		end
	end)

	DataService.OnLoaded(checkPasses)
end

return MonetizationService
