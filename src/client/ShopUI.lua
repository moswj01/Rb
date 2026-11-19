--[[
	ShopUI v2 — ร้านค้าแบบมืออาชีพ
	┌──────────┬───────────────────────────┬──────────────┐
	│  แท็บ     │  การ์ดไอเท็ม 3D            │  รายละเอียด    │
	│          │                           │  3D หมุน + ซื้อ │
	│          │                           │  + ลองใส่ 👀    │
	└──────────┴───────────────────────────┴──────────────┘
	แท็บ: แนะนำวันนี้ / ชุดเซ็ต / 7 หมวด / ของของฉัน / ร้านเพชร (Robux)
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ItemCatalog = require(Shared.ItemCatalog)
local ShopRotation = require(Shared.ShopRotation)

local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)
local Toast = require(script.Parent.Toast)
local Preview = require(script.Parent.Preview)

local player = Players.LocalPlayer
local Colors = UIKit.Colors

local ShopUI = {}
ShopUI.OnOpenPartyPass = nil -- ตั้งค่าจาก init (กัน require วน)

local TABS = {
	{ Id = "Featured", Name = "แนะนำวันนี้", Icon = "🔥" },
	{ Id = "Sets", Name = "ชุดเซ็ต", Icon = "🎽" },
}
for _, category in ItemCatalog.Categories do
	table.insert(TABS, { Id = category.Id, Name = category.Name, Icon = category.Icon })
end
table.insert(TABS, { Id = "Owned", Name = "ของของฉัน", Icon = "🎒" })
table.insert(TABS, { Id = "Store", Name = "ร้านเพชร", Icon = "💎" })

local gui, window, coinText, gemText
local tabButtons = {}
local infoLabel, gridScroll, listScroll, detail
local confirmFrame, confirmText, confirmCallback
local currentTab = "Featured"
local selectedId = nil
local priceCache = {}

-- ===== helpers =====

local function now()
	return workspace:GetServerTimeNow()
end

local function rarityOf(item)
	return ItemCatalog.Rarities[item.Rarity]
end

local function fetchRobuxPrice(id, infoType, callback)
	if id == 0 then
		callback("ยังไม่เปิดขาย")
		return
	end
	local key = tostring(infoType) .. id
	if priceCache[key] then
		callback(priceCache[key])
		return
	end
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)
		end)
		if ok and info and info.PriceInRobux then
			priceCache[key] = "R$ " .. info.PriceInRobux
			callback(priceCache[key])
		end
	end)
end

local function promptProduct(id)
	if id == 0 then
		Toast.Show("ผู้สร้างเกมยังไม่ได้ตั้งค่า ID สินค้าใน Config.lua", "info")
		return
	end
	MarketplaceService:PromptProductPurchase(player, id)
end

local function promptPass(passName)
	local pass = Config.GamePasses[passName]
	if not pass or pass.Id == 0 then
		Toast.Show("ผู้สร้างเกมยังไม่ได้ตั้งค่า ID Game Pass ใน Config.lua", "info")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, pass.Id)
end

function ShopUI.StarterTimeLeft()
	local data = Net.Data
	if not data or data.StarterBought or data.FirstJoin == 0 then
		return 0
	end
	return math.max(0, data.FirstJoin + Config.StarterPack.DurationHours * 3600 - now())
end

local function confirm(text, callback)
	confirmText.Text = text
	confirmCallback = callback
	confirmFrame.Visible = true
end

local function titleText(item, parent, size, position, maxSize)
	local label = UIKit.label({ Text = item.Text or item.Name, Size = size, Position = position, TextColor3 = Color3.new(1, 1, 1), Outline = 2, MaxTextSize = maxSize or 26, Parent = parent })
	UIKit.gradient(ItemCatalog.GetColorSequence(item), 0).Parent = label
	return label
end

-- ===== การกระทำกับไอเท็ม =====

local function buyFlow(item)
	local price = ShopRotation.GetPrice(item)
	local data = Net.Data
	if data and data[item.Currency] < price then
		if item.Currency == "Gems" then
			Toast.Show("เพชรไม่พอ 💎 เติมได้ที่ร้านเพชร", "bad")
			ShopUI.Open("Store")
		else
			Toast.Show("เหรียญไม่พอ 🪙 เก็บดาว เล่นมินิเกม หรือรับรางวัลรายวันนะ!", "bad")
		end
		return
	end
	local symbol = item.Currency == "Gems" and "💎" or "🪙"
	confirm(string.format("ซื้อ %s %s\nราคา %s %s ?", item.Icon, item.Name, symbol, UIKit.formatNumber(price)), function()
		local ok, message = Net.Invoke("BuyItem", item.Id)
		if not ok then
			Toast.Show(message, "bad")
		end
	end)
end

local function itemStatus(item, data)
	local owned = data.Owned[item.Id] == true
	local equipped = data.Equipped[item.Category] == item.Id
	return owned, equipped
end

-- ===== การ์ดไอเท็ม =====

local function itemCard(item, order, parent)
	local data = Net.Data
	local owned, equipped = itemStatus(item, data)
	local rarity = rarityOf(item)
	local selected = item.Id == selectedId

	local card = UIKit.new("Frame", {
		Name = item.Id,
		LayoutOrder = order,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = parent,
	}, {
		UIKit.corner(14),
		UIKit.stroke(selected and Colors.Gold or rarity.Color, selected and 4 or 2.5),
		UIKit.gradient(ColorSequence.new(rarity.Color:Lerp(Color3.new(1, 1, 1), 0.72), Color3.new(1, 1, 1)), 90),
	})
	if item.Category == "Title" then
		titleText(item, card, UDim2.new(1, -10, 0, 60), UDim2.fromOffset(5, 40), 22)
	else
		Preview.Create(item, card, UDim2.new(1, -6, 0, 118), UDim2.fromOffset(3, 4))
	end
	UIKit.chip(card, rarity.Name, rarity.Color, UDim2.fromOffset(5, 5), nil, UDim2.fromOffset(64, 18))
	if equipped then
		UIKit.chip(card, "✓ ใส่อยู่", Colors.Good, UDim2.new(1, -5, 0, 5), Vector2.new(1, 0), UDim2.fromOffset(62, 18))
	elseif owned then
		UIKit.chip(card, "มีแล้ว", Colors.Info, UDim2.new(1, -5, 0, 5), Vector2.new(1, 0), UDim2.fromOffset(52, 18))
	elseif ShopRotation.IsFeatured(item.Id) then
		UIKit.chip(card, "-" .. math.floor(Config.FeaturedDiscount * 100) .. "%", Colors.Bad, UDim2.new(1, -5, 0, 5), Vector2.new(1, 0), UDim2.fromOffset(46, 18))
	elseif item.Exclusive then
		UIKit.chip(card, "🔒", Colors.Stroke, UDim2.new(1, -5, 0, 5), Vector2.new(1, 0), UDim2.fromOffset(26, 18))
	end

	UIKit.label({ Text = item.Name, Size = UDim2.new(1, -8, 0, 22), Position = UDim2.fromOffset(4, 122), MaxTextSize = 17, Parent = card })
	local priceText
	if owned then
		priceText = equipped and "กำลังใส่" or "กดเพื่อใส่"
	elseif item.Exclusive == "VIP" then
		priceText = "👑 VIP"
	elseif item.Exclusive == "PartyPass" then
		priceText = "🎫 Party Pass"
	elseif item.Exclusive == "Starter" then
		priceText = "🚀 Starter Pack"
	elseif item.Exclusive == "Achievement" then
		priceText = "🏅 ความสำเร็จ"
	else
		priceText = (item.Currency == "Gems" and "💎 " or "🪙 ") .. UIKit.formatNumber(ShopRotation.GetPrice(item))
	end
	local priceLabel = UIKit.label({
		Text = priceText,
		Size = UDim2.new(1, -10, 0, 26),
		Position = UDim2.fromOffset(5, 146),
		BackgroundTransparency = 0,
		BackgroundColor3 = owned and Colors.Muted or (item.Currency == "Gems" and Colors.Gem or Colors.Coin),
		TextColor3 = owned and Colors.Text or Color3.new(1, 1, 1),
		MaxTextSize = 17,
		Parent = card,
	})
	UIKit.corner(8).Parent = priceLabel

	local hit = UIKit.new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 6, Parent = card })
	hit.Activated:Connect(function()
		UIKit.click(1.9)
		if selectedId == item.Id and owned and not equipped then
			Net.Invoke("EquipItem", item.Category, item.Id)
		end
		selectedId = item.Id
		ShopUI.Render()
	end)
	return card
end

-- ===== แผงรายละเอียด =====

local function renderDetail()
	local d = detail
	local item = selectedId and ItemCatalog.ById[selectedId]
	local data = Net.Data
	local rebuildPreview = d.PreviewItemId ~= selectedId
	if rebuildPreview then
		UIKit.clear(d.PreviewHolder)
		d.PreviewItemId = selectedId
	end
	if not item or not data then
		d.Name.Text = "เลือกไอเท็มเพื่อดูรายละเอียด"
		d.Rarity.Visible = false
		d.Set.Text = ""
		d.Desc.Text = ""
		d.Price.Text = ""
		d.Primary.Visible = false
		d.Try.Visible = false
		return
	end
	local rarity = rarityOf(item)
	local owned, equipped = itemStatus(item, data)

	if rebuildPreview then
		if item.Category == "Title" then
			titleText(item, d.PreviewHolder, UDim2.new(1, 0, 0, 60), UDim2.fromOffset(0, 80), 32)
		else
			Preview.Create(item, d.PreviewHolder, nil, nil, { Spin = true })
		end
	end
	d.Name.Text = item.Icon .. " " .. item.Name
	d.Rarity.Visible = true
	d.Rarity.Text = rarity.Name
	d.Rarity.BackgroundColor3 = rarity.Color
	local set = item.Set and ItemCatalog.SetById[item.Set]
	d.Set.Text = set and ("เซ็ต " .. set.Icon .. " " .. set.Name) or ItemCatalog.CategoryById[item.Category].Name
	d.Desc.Text = item.Description or ""

	local price = ShopRotation.GetPrice(item)
	local primaryText, primaryColor, primaryAction = nil, Colors.Good, nil
	d.Price.Text = ""
	if owned then
		if equipped then
			if item.Category == "Skin" then
				primaryText, primaryColor = "ใส่อยู่ ✓", Colors.Muted
			else
				primaryText, primaryColor = "ถอดออก", Colors.Muted
				primaryAction = function()
					Net.Invoke("EquipItem", item.Category, nil)
				end
			end
		else
			primaryText = "ใส่เลย! ✨"
			primaryAction = function()
				Net.Invoke("EquipItem", item.Category, item.Id)
			end
		end
		d.Price.Text = "✅ คุณเป็นเจ้าของแล้ว"
	elseif item.Exclusive == "VIP" then
		primaryText, primaryColor = "👑 ปลดล็อก VIP", Colors.Gold
		primaryAction = function()
			promptPass("VIP")
		end
		d.Price.Text = "ได้ฟรีเมื่อมี VIP"
	elseif item.Exclusive == "PartyPass" then
		primaryText, primaryColor = "🎫 ดู Party Pass", Colors.HeaderDark
		primaryAction = function()
			if ShopUI.OnOpenPartyPass then
				ShopUI.OnOpenPartyPass()
			end
		end
		d.Price.Text = "รางวัลพิเศษใน Party Pass"
	elseif item.Exclusive == "Starter" then
		primaryText, primaryColor = "🚀 ดู Starter Pack", Colors.Robux
		primaryAction = function()
			ShopUI.Open("Store")
		end
		d.Price.Text = "มีเฉพาะใน Starter Pack"
	elseif item.Exclusive == "Achievement" then
		local req = item.Requirement
		primaryText, primaryColor = "🔒 ปลดล็อกด้วยความสำเร็จ", Colors.Muted
		if req then
			d.Price.Text = string.format("%s %s / %s", req.Text, UIKit.formatNumber(data.Stats[req.Stat] or 0), UIKit.formatNumber(req.Value))
		else
			d.Price.Text = item.Description or ""
		end
	else
		local symbol = item.Currency == "Gems" and "💎" or "🪙"
		local affordable = data[item.Currency] >= price
		primaryText = string.format("ซื้อ %s %s", symbol, UIKit.formatNumber(price))
		primaryColor = item.Currency == "Gems" and Colors.Gem or Colors.Coin
		if not affordable then
			primaryColor = primaryColor:Lerp(Colors.Muted, 0.5)
		end
		primaryAction = function()
			buyFlow(item)
		end
		if ShopRotation.IsFeatured(item.Id) then
			d.Price.Text = string.format("🔥 ลด %d%% วันนี้! ปกติ <s>%s</s>", math.floor(Config.FeaturedDiscount * 100), UIKit.formatNumber(item.Price))
		elseif not affordable then
			d.Price.Text = string.format("ขาดอีก %s %s", symbol, UIKit.formatNumber(price - data[item.Currency]))
		end
	end

	d.Primary.Visible = true
	d.Primary.Text = primaryText
	d.Primary.BackgroundColor3 = primaryColor
	d.Primary.TextColor3 = primaryColor == Colors.Muted and Colors.Text or Color3.new(1, 1, 1)
	d.PrimaryAction = primaryAction
	d.Try.Visible = not owned
end

local function buildDetail(parent)
	local panel = UIKit.new("Frame", {
		Name = "Detail",
		Size = UDim2.new(0, 250, 1, 0),
		Position = UDim2.new(1, -250, 0, 0),
		BackgroundColor3 = Colors.PanelDark,
		Parent = parent,
	}, { UIKit.corner(16), UIKit.stroke(Colors.Muted, 2) })
	local d = { Frame = panel }
	d.PreviewHolder = UIKit.new("Frame", { Size = UDim2.new(1, -16, 0, 200), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.new(1, 1, 1), Parent = panel }, {
		UIKit.corner(14),
		UIKit.gradient(ColorSequence.new(Color3.fromRGB(255, 240, 250), Color3.fromRGB(230, 220, 255)), 90),
	})
	d.Rarity = UIKit.label({ Size = UDim2.fromOffset(90, 22), Position = UDim2.fromOffset(14, 14), BackgroundTransparency = 0, TextColor3 = Color3.new(1, 1, 1), MaxTextSize = 15, ZIndex = 3, Parent = panel })
	UIKit.corner(11).Parent = d.Rarity
	d.Name = UIKit.label({ Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 212), MaxTextSize = 24, Parent = panel })
	d.Set = UIKit.label({ Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 242), TextColor3 = Colors.HeaderDark, MaxTextSize = 16, Parent = panel })
	d.Desc = UIKit.label({ Size = UDim2.new(1, -16, 0, 38), Position = UDim2.fromOffset(8, 263), TextColor3 = Colors.SubText, TextWrapped = true, MaxTextSize = 15, Parent = panel })
	d.Price = UIKit.label({ Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 302), RichText = true, TextColor3 = Colors.Bad, MaxTextSize = 16, Parent = panel })
	d.Primary = UIKit.button({ Size = UDim2.new(1, -16, 0, 50), Position = UDim2.new(0, 8, 1, -112), MaxTextSize = 24, Parent = panel }, function()
		if d.PrimaryAction then
			d.PrimaryAction()
		end
	end)
	UIKit.pulse(d.Primary)
	d.Try = UIKit.button({ Text = "👀 ลองใส่ฟรี " .. Config.TryOnSeconds .. " วิ", Size = UDim2.new(1, -16, 0, 44), Position = UDim2.new(0, 8, 1, -54), BackgroundColor3 = Colors.Info, MaxTextSize = 20, Parent = panel }, function()
		if selectedId then
			local ok, message = Net.Invoke("TryOn", selectedId)
			Toast.Show(message, ok and "info" or "bad")
		end
	end)
	return d
end

-- ===== แท็บชุดเซ็ต =====

local function bundleFor(setId)
	for _, bundle in Config.Bundles do
		if bundle.Set == setId then
			return bundle
		end
	end
	return nil
end

local function setRow(set, order)
	local data = Net.Data
	local items = ItemCatalog.GetBySet(set.Id)
	local ownedCount = 0
	for _, item in items do
		if data.Owned[item.Id] then
			ownedCount += 1
		end
	end
	local row = UIKit.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, -10, 0, 186),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = listScroll,
	}, {
		UIKit.corner(16),
		UIKit.stroke(set.Colors[1], 3),
		UIKit.gradient(ColorSequence.new(set.Colors[1]:Lerp(Color3.new(1, 1, 1), 0.65), set.Colors[2]:Lerp(Color3.new(1, 1, 1), 0.65)), 0),
	})
	UIKit.label({ Text = set.Icon .. " " .. set.Name, Size = UDim2.new(0.6, 0, 0, 30), Position = UDim2.fromOffset(12, 6), TextXAlignment = Enum.TextXAlignment.Left, Outline = 1.5, TextColor3 = Color3.new(1, 1, 1), MaxTextSize = 24, Parent = row })
	UIKit.label({ Text = string.format("สะสมแล้ว %d/%d", ownedCount, #items), Size = UDim2.new(0.38, 0, 0, 24), Position = UDim2.new(0.6, 0, 0, 8), TextXAlignment = Enum.TextXAlignment.Right, MaxTextSize = 17, Parent = row })

	local strip = UIKit.new("Frame", { Size = UDim2.new(1, -16, 0, 84), Position = UDim2.fromOffset(8, 40), BackgroundTransparency = 1, Parent = row }, {
		UIKit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, item in items do
		local cell = UIKit.new("Frame", { LayoutOrder = i, Size = UDim2.fromOffset(72, 84), BackgroundColor3 = Color3.new(1, 1, 1), Parent = strip }, {
			UIKit.corner(10),
			UIKit.stroke(item.Id == selectedId and Colors.Gold or rarityOf(item).Color, item.Id == selectedId and 3 or 2),
		})
		Preview.Create(item, cell)
		if data.Owned[item.Id] then
			UIKit.chip(cell, "✓", Colors.Good, UDim2.new(1, -3, 0, 3), Vector2.new(1, 0), UDim2.fromOffset(18, 18))
		end
		local hit = UIKit.new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 6, Parent = cell })
		hit.Activated:Connect(function()
			UIKit.click(1.9)
			selectedId = item.Id
			renderDetail()
		end)
	end

	local coins, gems = ItemCatalog.GetSetValue(set.Id)
	local valueParts = {}
	if coins > 0 then
		table.insert(valueParts, "🪙 " .. UIKit.formatNumber(coins))
	end
	if gems > 0 then
		table.insert(valueParts, "💎 " .. UIKit.formatNumber(gems))
	end
	UIKit.label({ Text = "มูลค่าทั้งเซ็ต " .. table.concat(valueParts, " + "), Size = UDim2.new(0.5, 0, 0, 22), Position = UDim2.fromOffset(12, 134), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Colors.Text, MaxTextSize = 15, Parent = row })

	local bundle = bundleFor(set.Id)
	local buttonProps = { Size = UDim2.fromOffset(200, 42), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 132), MaxTextSize = 18, Parent = row }
	if ownedCount == #items then
		buttonProps.Text = "ครบเซ็ตแล้ว ✓"
		buttonProps.BackgroundColor3 = Colors.Muted
		buttonProps.TextColor3 = Colors.Text
		UIKit.button(buttonProps)
	elseif set.Id == "Rainbow" then
		buttonProps.Text = "🎫 รับใน Party Pass"
		buttonProps.BackgroundColor3 = Colors.HeaderDark
		UIKit.button(buttonProps, function()
			if ShopUI.OnOpenPartyPass then
				ShopUI.OnOpenPartyPass()
			end
		end)
	elseif bundle then
		buttonProps.Text = "ซื้อทั้งเซ็ต..."
		buttonProps.BackgroundColor3 = Colors.Robux
		local button = UIKit.button(buttonProps, function()
			promptProduct(bundle.ProductId)
		end)
		UIKit.chip(row, bundle.Tag .. " +💎" .. bundle.BonusGems, Colors.Bad, UDim2.new(1, -14, 0, 112), Vector2.new(1, 0), UDim2.fromOffset(110, 20))
		fetchRobuxPrice(bundle.ProductId, Enum.InfoType.Product, function(price)
			if button.Parent then
				button.Text = "ซื้อทั้งเซ็ต " .. price
			end
		end)
	else
		buttonProps.Text = "ดูไอเท็มในเซ็ต"
		buttonProps.BackgroundColor3 = Colors.Info
		UIKit.button(buttonProps, function()
			selectedId = items[1] and items[1].Id
			renderDetail()
		end)
	end
end

-- ===== ร้านเพชร (Robux) =====

local function sectionTitle(text, order)
	UIKit.label({ LayoutOrder = order, Text = text, Size = UDim2.new(1, -10, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 24, Parent = listScroll })
end

local function robuxCard(parent, order, icon, title, subtitle, tag, highlight, owned, onBuy, priceSetter)
	local card = UIKit.new("Frame", { LayoutOrder = order, Size = UDim2.fromOffset(170, 220), BackgroundColor3 = Color3.new(1, 1, 1), Parent = parent }, {
		UIKit.corner(16),
		UIKit.stroke(highlight and Colors.Gold or Colors.Gem, highlight and 4 or 2.5),
		UIKit.gradient(ColorSequence.new(highlight and Color3.fromRGB(255, 245, 200) or Color3.fromRGB(220, 245, 255), Color3.new(1, 1, 1)), 90),
	})
	UIKit.label({ Text = icon, Size = UDim2.new(1, 0, 0, 70), Position = UDim2.fromOffset(0, 12), MaxTextSize = 56, Parent = card })
	if tag then
		UIKit.chip(card, tag, highlight and Colors.Bad or Colors.HeaderDark, UDim2.new(0.5, 0, 0, -10), Vector2.new(0.5, 0), UDim2.fromOffset(110, 22))
	end
	UIKit.label({ Text = title, Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 84), MaxTextSize = 20, Parent = card })
	UIKit.label({ Text = subtitle, Size = UDim2.new(1, -12, 0, 54), Position = UDim2.fromOffset(6, 110), TextColor3 = Colors.SubText, TextWrapped = true, MaxTextSize = 14, Parent = card })
	local button = UIKit.button({
		Text = owned and "มีแล้ว ✓" or "...",
		Size = UDim2.new(1, -16, 0, 42),
		Position = UDim2.new(0, 8, 1, -50),
		BackgroundColor3 = owned and Colors.Muted or Colors.Robux,
		TextColor3 = owned and Colors.Text or Color3.new(1, 1, 1),
		MaxTextSize = 22,
		Parent = card,
	}, function()
		if not owned then
			onBuy()
		end
	end)
	if not owned and priceSetter then
		priceSetter(function(price)
			if button.Parent then
				button.Text = price
			end
		end)
	end
	if highlight and not owned then
		UIKit.pulse(button)
	end
	return card
end

local function cardRow(order, height)
	return UIKit.new("ScrollingFrame", {
		LayoutOrder = order,
		Size = UDim2.new(1, -10, 0, height or 236),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		Parent = listScroll,
	}, {
		UIKit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		UIKit.new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 4) }),
	})
end

local function starterBanner(order)
	local banner = UIKit.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, -10, 0, 170), BackgroundColor3 = Color3.new(1, 1, 1), Parent = listScroll }, {
		UIKit.corner(18),
		UIKit.stroke(Colors.Gold, 4),
		UIKit.gradient(ColorSequence.new(Color3.fromRGB(255, 130, 90), Color3.fromRGB(255, 90, 180)), 0),
	})
	UIKit.label({ Text = "🚀 STARTER PACK — ครั้งเดียวเท่านั้น!", Size = UDim2.new(0.62, 0, 0, 34), Position = UDim2.fromOffset(14, 8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Outline = 2, MaxTextSize = 26, Parent = banner })
	local timer = UIKit.label({ Size = UDim2.new(0.36, 0, 0, 26), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 12), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.new(1, 1, 1), Outline = 1.5, MaxTextSize = 20, Parent = banner })
	task.spawn(function()
		while timer.Parent do
			timer.Text = "⏰ เหลือ " .. UIKit.formatTime(ShopUI.StarterTimeLeft())
			task.wait(1)
		end
	end)
	local strip = UIKit.new("Frame", { Size = UDim2.new(0, 260, 0, 100), Position = UDim2.fromOffset(14, 50), BackgroundTransparency = 1, Parent = banner }, {
		UIKit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
	})
	for _, itemId in Config.StarterPack.Items do
		local item = ItemCatalog.ById[itemId]
		local cell = UIKit.new("Frame", { Size = UDim2.fromOffset(80, 100), BackgroundColor3 = Color3.new(1, 1, 1), Parent = strip }, { UIKit.corner(12) })
		if item.Category == "Title" then
			titleText(item, cell, UDim2.new(1, -6, 0, 40), UDim2.fromOffset(3, 30), 16)
		else
			Preview.Create(item, cell)
		end
	end
	UIKit.label({
		Text = string.format("ของพิเศษ 3 ชิ้น\n+ 💎 %d เพชร\n+ 🪙 %s เหรียญ", Config.StarterPack.Gems, UIKit.formatNumber(Config.StarterPack.Coins)),
		Size = UDim2.new(0, 200, 0, 100),
		Position = UDim2.fromOffset(290, 50),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
		Outline = 1.5,
		MaxTextSize = 20,
		Parent = banner,
	})
	local button = UIKit.button({ Text = "...", Size = UDim2.fromOffset(170, 56), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), BackgroundColor3 = Colors.Robux, MaxTextSize = 26, Parent = banner }, function()
		promptProduct(Config.StarterPack.ProductId)
	end)
	UIKit.pulse(button)
	fetchRobuxPrice(Config.StarterPack.ProductId, Enum.InfoType.Product, function(price)
		if button.Parent then
			button.Text = price
		end
	end)
end

local function renderStore()
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end
	if ShopUI.StarterTimeLeft() > 0 then
		starterBanner(nextOrder())
	end

	sectionTitle("⭐ Game Pass (ซื้อครั้งเดียว ใช้ได้ตลอด)", nextOrder())
	local passRow = cardRow(nextOrder())
	local passOrder = { "VIP", "PartyPass", "DoubleCoins" }
	for i, passName in passOrder do
		local pass = Config.GamePasses[passName]
		robuxCard(passRow, i, pass.Icon, pass.Name, pass.Description, i == 1 and "ยอดนิยม" or nil, i == 1, player:GetAttribute(passName) == true, function()
			promptPass(passName)
		end, function(setter)
			fetchRobuxPrice(pass.Id, Enum.InfoType.GamePass, setter)
		end)
	end

	sectionTitle("💎 เติมเพชร", nextOrder())
	local gemRow = cardRow(nextOrder())
	for i, pack in Config.GemPacks do
		robuxCard(gemRow, i, pack.Icon, pack.Name, "💎 " .. UIKit.formatNumber(pack.Gems) .. " เพชร", pack.Tag, pack.Highlight, false, function()
			promptProduct(pack.ProductId)
		end, function(setter)
			fetchRobuxPrice(pack.ProductId, Enum.InfoType.Product, setter)
		end)
	end

	sectionTitle("🎽 ชุดเซ็ตครบ (คุ้มกว่าซื้อแยก)", nextOrder())
	local bundleRow = cardRow(nextOrder())
	for i, bundle in Config.Bundles do
		local set = ItemCatalog.SetById[bundle.Set]
		local items = ItemCatalog.GetBySet(bundle.Set)
		local allOwned = true
		for _, item in items do
			if not Net.Data.Owned[item.Id] then
				allOwned = false
			end
		end
		robuxCard(bundleRow, i, set.Icon, "ชุด" .. set.Name, string.format("ครบ %d ชิ้น + 💎 %d", #items, bundle.BonusGems), bundle.Tag, bundle.Set == "Royal", allOwned, function()
			promptProduct(bundle.ProductId)
		end, function(setter)
			fetchRobuxPrice(bundle.ProductId, Enum.InfoType.Product, setter)
		end)
	end

	UIKit.label({
		LayoutOrder = nextOrder(),
		Text = "💖 ขอบคุณที่สนับสนุนผู้สร้างเกม • ทุกไอเท็มเป็นความสวยงาม ไม่มีกล่องสุ่ม ไม่มีผลต่อการแข่ง",
		Size = UDim2.new(1, -10, 0, 30),
		TextColor3 = Colors.SubText,
		MaxTextSize = 15,
		Parent = listScroll,
	})
end

-- ===== render หลัก =====

local function listForTab(tab)
	local data = Net.Data
	if tab == "Featured" then
		local list = {}
		for _, id in (ShopRotation.GetFeatured()) do
			table.insert(list, ItemCatalog.ById[id])
		end
		return list
	elseif tab == "Owned" then
		local list = {}
		for _, item in ItemCatalog.List do
			if data.Owned[item.Id] then
				table.insert(list, item)
			end
		end
		return ItemCatalog.Sort(list)
	end
	return ItemCatalog.GetByCategory(tab)
end

local function updateInfo()
	if currentTab == "Featured" then
		infoLabel.Text = string.format("🔥 ลด %d%% เฉพาะวันนี้! ของใหม่มาใน %s", math.floor(Config.FeaturedDiscount * 100), ShopRotation.FormatTime(ShopRotation.SecondsUntilReset()))
	elseif currentTab == "Sets" then
		infoLabel.Text = "🎽 ใส่ของตรงธีมแฟชั่นโชว์ = ได้คะแนนโบนัส! สะสมให้ครบเซ็ตเลย"
	elseif currentTab == "Owned" then
		local count = 0
		for _ in Net.Data.Owned do
			count += 1
		end
		infoLabel.Text = string.format("🎒 คอลเลกชันของคุณ %d / %d ชิ้น", count, #ItemCatalog.List)
	elseif currentTab == "Store" then
		infoLabel.Text = "💎 ร้านเพชร — ข้อเสนอสุดคุ้ม"
	else
		local category = ItemCatalog.CategoryById[currentTab]
		local list = ItemCatalog.GetByCategory(currentTab)
		local owned = 0
		for _, item in list do
			if Net.Data.Owned[item.Id] then
				owned += 1
			end
		end
		infoLabel.Text = string.format("%s %s — มีแล้ว %d / %d", category.Icon, category.Name, owned, #list)
	end
end

function ShopUI.Render()
	if not window or not window.Visible or not Net.Data then
		return
	end
	local data = Net.Data
	coinText.Text = "🪙 " .. UIKit.formatNumber(data.Coins)
	gemText.Text = "💎 " .. UIKit.formatNumber(data.Gems)

	for id, button in tabButtons do
		local active = id == currentTab
		button.BackgroundColor3 = active and Colors.Header or Color3.new(1, 1, 1)
		button.TextColor3 = active and Color3.new(1, 1, 1) or Colors.Text
	end

	local gridPos, listPos = gridScroll.CanvasPosition, listScroll.CanvasPosition
	UIKit.clear(gridScroll)
	UIKit.clear(listScroll)

	local fullWidth = currentTab == "Store"
	detail.Frame.Visible = not fullWidth
	local mainWidth = fullWidth and UDim2.new(1, -160, 1, -38) or UDim2.new(1, -420, 1, -38)
	gridScroll.Size = mainWidth
	listScroll.Size = mainWidth
	infoLabel.Size = UDim2.new(mainWidth.X.Scale, mainWidth.X.Offset, 0, 30)

	if currentTab == "Store" then
		gridScroll.Visible, listScroll.Visible = false, true
		renderStore()
	elseif currentTab == "Sets" then
		gridScroll.Visible, listScroll.Visible = false, true
		for i, set in ItemCatalog.Sets do
			setRow(set, i)
		end
		if not selectedId then
			selectedId = ItemCatalog.GetBySet(ItemCatalog.Sets[1].Id)[1].Id
		end
	else
		gridScroll.Visible, listScroll.Visible = true, false
		local list = listForTab(currentTab)
		local found = false
		for i, item in list do
			if item.Id == selectedId then
				found = true
			end
			itemCard(item, i, gridScroll)
		end
		if not found and list[1] then
			selectedId = list[1].Id
			local first = gridScroll:FindFirstChild(selectedId)
			if first then
				first:FindFirstChildOfClass("UIStroke").Color = Colors.Gold
			end
		end
	end
	renderDetail()
	updateInfo()
	task.defer(function()
		gridScroll.CanvasPosition = gridPos
		listScroll.CanvasPosition = listPos
	end)
end

function ShopUI.Open(tabId, itemId)
	if tabId and tabId ~= currentTab then
		currentTab = tabId
		gridScroll.CanvasPosition = Vector2.zero
		listScroll.CanvasPosition = Vector2.zero
		selectedId = nil
	end
	if itemId then
		selectedId = itemId
	end
	UIKit.open(window)
	ShopUI.Render()
end

function ShopUI.Toggle()
	if window.Visible then
		UIKit.close(window)
	else
		ShopUI.Open()
	end
end

function ShopUI.IsOpen()
	return window.Visible
end

function ShopUI.Init()
	gui = UIKit.screenGui("Shop", 10)
	local content, header
	window, content, header = UIKit.window(gui, "🛍️ ร้านสกินปาร์ตี้", UDim2.fromOffset(940, 570))

	coinText = UIKit.label({ Size = UDim2.fromOffset(130, 34), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -200, 0.5, 0), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), MaxTextSize = 20, ZIndex = 3, Parent = header })
	UIKit.corner(17).Parent = coinText
	gemText = UIKit.label({ Size = UDim2.fromOffset(120, 34), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), MaxTextSize = 20, ZIndex = 3, Parent = header })
	UIKit.corner(17).Parent = gemText

	local tabList = UIKit.new("ScrollingFrame", {
		Size = UDim2.new(0, 150, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = content,
	}, {
		UIKit.new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }),
		UIKit.new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 6) }),
	})
	for i, tab in TABS do
		local button = UIKit.button({
			Text = tab.Icon .. " " .. tab.Name,
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = i,
			BackgroundColor3 = Color3.new(1, 1, 1),
			TextColor3 = Colors.Text,
			MaxTextSize = 19,
			Parent = tabList,
		}, function()
			ShopUI.Open(tab.Id)
		end)
		tabButtons[tab.Id] = button
		if tab.Id == "Store" then
			local stroke = button:FindFirstChildOfClass("UIStroke")
			stroke.Color = Colors.Robux
			stroke.Thickness = 3
		end
	end

	infoLabel = UIKit.label({ Size = UDim2.new(1, -420, 0, 30), Position = UDim2.fromOffset(160, 0), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 19, Parent = content })

	gridScroll = UIKit.new("ScrollingFrame", {
		Size = UDim2.new(1, -420, 1, -38),
		Position = UDim2.fromOffset(160, 36),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = content,
	}, {
		UIKit.new("UIGridLayout", { CellSize = UDim2.fromOffset(150, 178), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		UIKit.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4) }),
	})
	listScroll = UIKit.new("ScrollingFrame", {
		Size = UDim2.new(1, -420, 1, -38),
		Position = UDim2.fromOffset(160, 36),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Visible = false,
		Parent = content,
	}, {
		UIKit.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		UIKit.new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 4) }),
	})

	detail = buildDetail(content)

	-- กล่องยืนยันการซื้อ
	confirmFrame = UIKit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Visible = false, ZIndex = 50, Parent = gui })
	local box = UIKit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(400, 220), BackgroundColor3 = Colors.Panel, ZIndex = 51, Parent = confirmFrame }, { UIKit.corner(20), UIKit.stroke(Colors.Stroke, 3) })
	UIKit.autoScale(box, 520, 420)
	confirmText = UIKit.label({ Size = UDim2.new(1, -30, 0, 110), Position = UDim2.fromOffset(15, 14), MaxTextSize = 26, ZIndex = 52, Parent = box })
	UIKit.button({ Text = "ยกเลิก", Size = UDim2.new(0.5, -22, 0, 54), Position = UDim2.new(0, 15, 1, -70), BackgroundColor3 = Colors.Muted, TextColor3 = Colors.Text, ZIndex = 52, Parent = box }, function()
		confirmFrame.Visible = false
	end)
	UIKit.button({ Text = "ซื้อเลย! 🎉", Size = UDim2.new(0.5, -22, 0, 54), Position = UDim2.new(0.5, 7, 1, -70), BackgroundColor3 = Colors.Good, ZIndex = 52, Parent = box }, function()
		confirmFrame.Visible = false
		if confirmCallback then
			confirmCallback()
		end
	end)

	-- render ใหม่ทั้งหน้าเฉพาะเมื่อของ/การใส่เปลี่ยน (เก็บดาวแค่อัปเดตตัวเลข)
	local lastSignature = ""
	Net.Changed:Connect(function(data)
		local parts = {}
		for id in data.Owned do
			table.insert(parts, id)
		end
		for categoryId, id in data.Equipped do
			table.insert(parts, categoryId .. "=" .. id)
		end
		table.sort(parts)
		table.insert(parts, tostring(data.StarterBought))
		local signature = table.concat(parts, ",")
		if signature ~= lastSignature then
			lastSignature = signature
			ShopUI.Render()
		elseif window.Visible then
			coinText.Text = "🪙 " .. UIKit.formatNumber(data.Coins)
			gemText.Text = "💎 " .. UIKit.formatNumber(data.Gems)
			renderDetail()
		end
	end)
	player.AttributeChanged:Connect(function(name)
		if Config.GamePasses[name] then
			ShopUI.Render()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if window.Visible and currentTab == "Featured" then
				updateInfo()
			end
		end
	end)
end

return ShopUI
