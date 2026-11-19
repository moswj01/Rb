--[[
	ShopService — ซื้อ/ใส่/ลองไอเท็ม, รางวัลรายวัน, แลกโค้ด, ตั้งค่ามินิเกม
	ทุกอย่างตรวจสอบที่เซิร์ฟเวอร์ (client ส่งมาแค่ "อยากได้อะไร")
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ItemCatalog = require(Shared.ItemCatalog)
local ShopRotation = require(Shared.ShopRotation)

local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local CosmeticService = require(script.Parent.CosmeticService)
local Rewards = require(script.Parent.Rewards)
local ProgressService = require(script.Parent.ProgressService)

local ShopService = {}

local lastCall = {}

local function allow(player, cooldown)
	local now = os.clock()
	if lastCall[player] and now - lastCall[player] < (cooldown or 0.25) then
		return false
	end
	lastCall[player] = now
	return true
end

local function formatDuration(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	if h > 0 then
		return string.format("%d ชม. %d นาที", h, m)
	end
	return string.format("%d นาที", math.max(1, m))
end

local function buyItem(player, itemId)
	if not allow(player) then
		return false, "ใจเย็น ๆ นะ ลองอีกครั้ง 😅"
	end
	local item = type(itemId) == "string" and ItemCatalog.ById[itemId]
	local data = DataService.Get(player)
	if not item then
		return false, "ไม่พบไอเท็มนี้"
	end
	if not data then
		return false, "กำลังโหลดข้อมูล..."
	end
	if data.Owned[itemId] then
		return false, "คุณมีไอเท็มนี้อยู่แล้ว"
	end
	if not ItemCatalog.CanBuyDirectly(item) then
		return false, "ไอเท็มนี้ซื้อตรงไม่ได้ ดูวิธีรับในรายละเอียดนะ"
	end

	local price = ShopRotation.GetPrice(item)
	if not DataService.Spend(player, item.Currency, price, item.Id) then
		if item.Currency == "Gems" then
			return false, "เพชรไม่พอ 💎"
		end
		return false, "เหรียญไม่พอ 🪙 ลองเก็บดาวหรือเล่นมินิเกมดูนะ!"
	end

	Rewards.GiveItem(player, itemId)
	data.Equipped[item.Category] = itemId
	CosmeticService.ClearTryOn(player)
	DataService.Push(player)
	CosmeticService.Apply(player)
	ProgressService.Tutorial(player, "Buy", 1)
	return true, "ได้รับ " .. item.Icon .. " " .. item.Name .. " แล้ว! 🎉"
end

local function equipItem(player, categoryId, itemId)
	if not allow(player) then
		return false, "ใจเย็น ๆ นะ 😅"
	end
	local data = DataService.Get(player)
	if not data then
		return false, "กำลังโหลดข้อมูล..."
	end
	if type(categoryId) ~= "string" or not ItemCatalog.CategoryById[categoryId] then
		return false, "หมวดหมู่ไม่ถูกต้อง"
	end
	if itemId == nil then
		data.Equipped[categoryId] = if categoryId == "Skin" then "skin_classic" else nil
	else
		local item = type(itemId) == "string" and ItemCatalog.ById[itemId]
		if not item or item.Category ~= categoryId then
			return false, "ไม่พบไอเท็มนี้"
		end
		if not data.Owned[itemId] then
			return false, "ยังไม่มีไอเท็มนี้"
		end
		data.Equipped[categoryId] = itemId
	end
	CosmeticService.ClearTryOn(player)
	DataService.Push(player)
	CosmeticService.Apply(player)
	return true
end

local function tryOn(player, itemId)
	if not allow(player, 0.5) then
		return false, "ใจเย็น ๆ นะ 😅"
	end
	local item = type(itemId) == "string" and ItemCatalog.ById[itemId]
	if not item then
		return false, "ไม่พบไอเท็มนี้"
	end
	if player:GetAttribute("OnRunway") then
		return false, "ขึ้นเวทีอยู่ ลองของไม่ได้นะ 😉"
	end
	CosmeticService.TryOn(player, itemId)
	return true, string.format("👀 ลองใส่ %s %s (%d วิ) — ชอบไหม?", item.Icon, item.Name, Config.TryOnSeconds)
end

local function claimDaily(player)
	if not allow(player) then
		return false, "ใจเย็น ๆ นะ 😅"
	end
	local data = DataService.Get(player)
	if not data then
		return false, "กำลังโหลดข้อมูล..."
	end
	local daily = data.Daily
	local now = os.time()
	local since = now - daily.Last
	if daily.Last > 0 and since < Config.DailyCooldown then
		return false, "รับได้อีกครั้งใน " .. formatDuration(Config.DailyCooldown - since)
	end
	if daily.Last == 0 or since > Config.DailyStreakReset then
		daily.Streak = 0
	end
	daily.Streak = daily.Streak % #Config.DailyRewards + 1
	daily.Last = now
	local summary = Rewards.Grant(player, Config.DailyRewards[daily.Streak], "TimedReward", "Daily_" .. daily.Streak)
	ProgressService.AddXP(player, Config.XP.Daily)
	DataService.Push(player)
	ProgressService.Tutorial(player, "Daily", 1)
	return true, string.format("🎁 วันที่ %d: ได้รับ %s (+%d XP)", daily.Streak, summary, Config.XP.Daily)
end

local function redeemCode(player, code)
	if not allow(player) then
		return false, "ใจเย็น ๆ นะ 😅"
	end
	local data = DataService.Get(player)
	if not data then
		return false, "กำลังโหลดข้อมูล..."
	end
	if type(code) ~= "string" or #code > 40 then
		return false, "โค้ดไม่ถูกต้อง"
	end
	code = string.upper((code:gsub("%s", "")))
	local reward = Config.Codes[code]
	if not reward then
		return false, "ไม่พบโค้ดนี้ ลองเช็กตัวสะกดอีกครั้งนะ"
	end
	if data.Codes[code] then
		return false, "คุณใช้โค้ดนี้ไปแล้ว"
	end
	data.Codes[code] = true
	local summary = Rewards.Grant(player, reward, "TimedReward", "Code_" .. code)
	DataService.Push(player)
	return true, "🎟️ แลกโค้ดสำเร็จ! ได้รับ " .. summary
end

local function setSkipRounds(player, skip)
	local data = DataService.Get(player)
	if not data then
		return false
	end
	data.Settings.SkipRounds = skip == true
	player:SetAttribute("SkipRounds", data.Settings.SkipRounds)
	DataService.Push(player)
	return true
end

function ShopService.Init()
	Remotes.BuyItem.OnServerInvoke = buyItem
	Remotes.EquipItem.OnServerInvoke = equipItem
	Remotes.TryOn.OnServerInvoke = tryOn
	Remotes.ClaimDaily.OnServerInvoke = claimDaily
	Remotes.RedeemCode.OnServerInvoke = redeemCode
	Remotes.SetSkipRounds.OnServerInvoke = setSkipRounds
	Players.PlayerRemoving:Connect(function(player)
		lastCall[player] = nil
	end)
end

return ShopService
