-- ShopUI — หน้าต่างร้านค้า: ลดราคาวันนี้ / หมวดไอเท็ม / ของของฉัน / เติมเพชร
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

local player = Players.LocalPlayer
local Colors = UIKit.Colors

local ShopUI = {}

local TABS = {
	{ Id = "Featured", Name = "ลดราคาวันนี้", Icon = "⭐" },
}
for _, category in ItemCatalog.Categories do
	table.insert(TABS, { Id = category.Id, Name = category.Name, Icon = category.Icon })
end
table.insert(TABS, { Id = "Owned", Name = "ของของฉัน", Icon = "🎒" })
table.insert(TABS, { Id = "Gems", Name = "เติมเพชร", Icon = "💎" })

local gui, window, tabList, infoLabel, grid, confirmFrame
local tabButtons = {}
local currentTab = "Featured"
local robuxPriceCache = {}

-- ===== กล่องยืนยันการซื้อ (กันเด็กกดพลาด) =====

local confirmCallback
local function buildConfirm()
	confirmFrame = UIKit.new("Frame", {
		Name = "Confirm",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Visible = false,
		ZIndex = 50,
		Parent = gui,
	})
	local box = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(380, 210),
		BackgroundColor3 = Colors.Panel,
		ZIndex = 51,
		Parent = confirmFrame,
	}, { UIKit.corner(18), UIKit.stroke(Colors.Stroke, 3) })
	UIKit.autoScale(box, 500, 400)
	local text = UIKit.label({
		Name = "Text",
		Size = UDim2.new(1, -30, 0, 110),
		Position = UDim2.fromOffset(15, 12),
		MaxTextSize = 26,
		ZIndex = 52,
		Parent = box,
	})
	UIKit.button({
		Text = "ยกเลิก",
		Size = UDim2.new(0.5, -22, 0, 52),
		Position = UDim2.new(0, 15, 1, -66),
		BackgroundColor3 = Colors.Muted,
		TextColor3 = Colors.Text,
		ZIndex = 52,
		Parent = box,
	}, function()
		confirmFrame.Visible = false
	end)
	UIKit.button({
		Text = "ซื้อเลย! 🎉",
		Size = UDim2.new(0.5, -22, 0, 52),
		Position = UDim2.new(0.5, 7, 1, -66),
		BackgroundColor3 = Colors.Good,
		ZIndex = 52,
		Parent = box,
	}, function()
		confirmFrame.Visible = false
		if confirmCallback then
			confirmCallback()
		end
	end)
	return text
end

local confirmText
local function confirm(text, callback)
	confirmText.Text = text
	confirmCallback = callback
	confirmFrame.Visible = true
end

-- ===== การ์ดไอเท็ม =====

local function pill(parent, text, color, anchorRight)
	return UIKit.label({
		Text = text,
		Size = UDim2.fromOffset(78, 22),
		AnchorPoint = Vector2.new(anchorRight and 1 or 0, 0),
		Position = anchorRight and UDim2.new(1, -6, 0, 6) or UDim2.fromOffset(6, 6),
		BackgroundTransparency = 0,
		BackgroundColor3 = color,
		TextColor3 = Color3.new(1, 1, 1),
		MaxTextSize = 15,
		ZIndex = 3,
		Parent = parent,
	}, nil)
end

local function addCorner(instance, radius)
	UIKit.corner(radius).Parent = instance
	return instance
end

local function buyFlow(item)
	local price = ShopRotation.GetPrice(item)
	local symbol = item.Currency == "Gems" and "💎" or "🪙"
	local data = Net.Data
	if data and data[item.Currency] < price then
		Toast.Show(item.Currency == "Gems" and "เพชรไม่พอ 💎 เติมได้ที่แท็บ 'เติมเพชร'" or "เหรียญไม่พอ 🪙 ลองเก็บดาวหรือเล่นมินิเกมนะ!", "bad")
		if item.Currency == "Gems" then
			ShopUI.Open("Gems")
		end
		return
	end
	confirm(string.format("ซื้อ %s %s\nราคา %s %s ?", item.Icon, item.Name, symbol, UIKit.formatNumber(price)), function()
		local ok, message = Net.Invoke("BuyItem", item.Id)
		Toast.Show(message, ok and "good" or "bad")
	end)
end

local function itemCard(item, data, order)
	local owned = data.Owned[item.Id] == true
	local equipped = data.Equipped[item.Category] == item.Id
	local rarity = ItemCatalog.Rarities[item.Rarity]
	local featured = ShopRotation.IsFeatured(item.Id)
	local price = ShopRotation.GetPrice(item)

	local card = UIKit.new("Frame", {
		Name = item.Id,
		LayoutOrder = order,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = grid,
	}, { UIKit.corner(14), UIKit.stroke(rarity.Color, 3) })

	local preview = UIKit.new("Frame", {
		Size = UDim2.new(1, -12, 0, 104),
		Position = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = card,
	}, {
		UIKit.corner(12),
		UIKit.new("UIGradient", { Color = ItemCatalog.GetColorSequence(item), Rotation = 45 }),
	})
	UIKit.label({ Text = item.Icon, Size = UDim2.fromScale(1, 0.8), Position = UDim2.fromScale(0, 0.15), MaxTextSize = 60, Parent = preview })
	addCorner(pill(preview, rarity.Name, rarity.Color, false), 8)
	if equipped then
		addCorner(pill(preview, "✓ ใส่อยู่", Colors.Good, true), 8)
	elseif featured and not owned then
		addCorner(pill(preview, "-" .. math.floor(Config.FeaturedDiscount * 100) .. "%", Colors.Bad, true), 8)
	end

	UIKit.label({
		Text = item.Name,
		Size = UDim2.new(1, -12, 0, 26),
		Position = UDim2.fromOffset(6, 114),
		MaxTextSize = 20,
		Parent = card,
	})

	if featured and not owned then
		UIKit.label({
			Text = "ปกติ <s>" .. UIKit.formatNumber(item.Price) .. "</s>",
			RichText = true,
			Size = UDim2.new(1, -12, 0, 18),
			Position = UDim2.fromOffset(6, 140),
			TextColor3 = Colors.SubText,
			MaxTextSize = 15,
			Parent = card,
		})
	end

	local text, color, action
	if owned then
		if equipped then
			if item.Category == "Skin" then
				text, color = "ใส่อยู่ ✓", Colors.Muted
			else
				text, color = "ถอดออก", Colors.Muted
				action = function()
					Net.Invoke("EquipItem", item.Category, nil)
				end
			end
		else
			text, color = "ใส่เลย!", Colors.Good
			action = function()
				Net.Invoke("EquipItem", item.Category, item.Id)
			end
		end
	elseif item.Exclusive == "VIP" then
		text, color = "👑 VIP เท่านั้น", Colors.Coin
		action = function()
			ShopUI.Open("Gems")
		end
	else
		local symbol = item.Currency == "Gems" and "💎 " or "🪙 "
		text = symbol .. UIKit.formatNumber(price)
		color = item.Currency == "Gems" and Colors.Gem or Colors.Coin
		if data[item.Currency] < price then
			color = color:Lerp(Colors.Muted, 0.55)
		end
		action = function()
			buyFlow(item)
		end
	end

	UIKit.button({
		Text = text,
		Size = UDim2.new(1, -12, 0, 40),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 6, 1, -6),
		BackgroundColor3 = color,
		TextColor3 = (color == Colors.Muted) and Colors.Text or Color3.new(1, 1, 1),
		Parent = card,
	}, action)
end

-- ===== การ์ด Robux =====

local function fetchRobuxPrice(id, infoType, label)
	if id == 0 then
		label.Text = "ยังไม่เปิดขาย"
		return
	end
	local key = tostring(infoType) .. id
	if robuxPriceCache[key] then
		label.Text = robuxPriceCache[key]
		return
	end
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)
		end)
		if ok and info and info.PriceInRobux then
			robuxPriceCache[key] = "R$ " .. info.PriceInRobux
			if label.Parent then
				label.Text = robuxPriceCache[key]
			end
		end
	end)
end

local function robuxCard(order, icon, title, subtitle, bonus, owned, id, infoType)
	local card = UIKit.new("Frame", {
		LayoutOrder = order,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = grid,
	}, { UIKit.corner(14), UIKit.stroke(Colors.Gem, 3) })
	local preview = UIKit.new("Frame", {
		Size = UDim2.new(1, -12, 0, 90),
		Position = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Color3.fromRGB(200, 240, 255),
		Parent = card,
	}, { UIKit.corner(12) })
	UIKit.label({ Text = icon, Size = UDim2.fromScale(1, 0.85), Position = UDim2.fromScale(0, 0.1), MaxTextSize = 50, Parent = preview })
	if bonus then
		addCorner(pill(preview, bonus, Colors.Bad, true), 8)
	end
	UIKit.label({ Text = title, Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 100), MaxTextSize = 20, Parent = card })
	UIKit.label({
		Text = subtitle,
		Size = UDim2.new(1, -12, 0, 46),
		Position = UDim2.fromOffset(6, 124),
		TextColor3 = Colors.SubText,
		TextWrapped = true,
		MaxTextSize = 14,
		Parent = card,
	})

	local button = UIKit.button({
		Text = owned and "มีแล้ว ✓" or "...",
		Size = UDim2.new(1, -12, 0, 40),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 6, 1, -6),
		BackgroundColor3 = owned and Colors.Muted or Colors.Good,
		TextColor3 = owned and Colors.Text or Color3.new(1, 1, 1),
		Parent = card,
	}, function()
		if owned then
			return
		end
		if id == 0 then
			Toast.Show("ผู้สร้างเกมยังไม่ได้ตั้งค่า ID สินค้าใน Config.lua", "info")
			return
		end
		if infoType == Enum.InfoType.GamePass then
			MarketplaceService:PromptGamePassPurchase(player, id)
		else
			MarketplaceService:PromptProductPurchase(player, id)
		end
	end)
	if not owned then
		fetchRobuxPrice(id, infoType, button)
	end
end

-- ===== วาดหน้า =====

local function clearGrid()
	for _, child in grid:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function updateInfo()
	if currentTab == "Featured" then
		infoLabel.Text = string.format(
			"⭐ ลด %d%% เฉพาะวันนี้! ของใหม่มาใน %s",
			math.floor(Config.FeaturedDiscount * 100),
			ShopRotation.FormatTime(ShopRotation.SecondsUntilReset())
		)
	elseif currentTab == "Gems" then
		infoLabel.Text = "💎 สนับสนุนผู้สร้างเกม ✨ ของทุกชิ้นเป็นความสวยงาม ไม่มีผลต่อการแข่ง"
	elseif currentTab == "Owned" then
		local count = 0
		for _ in (Net.Data and Net.Data.Owned or {}) do
			count += 1
		end
		infoLabel.Text = string.format("🎒 คุณสะสมแล้ว %d / %d ชิ้น", count, #ItemCatalog.List)
	else
		local category = ItemCatalog.CategoryById[currentTab]
		local list = ItemCatalog.GetByCategory(currentTab)
		local owned = 0
		for _, item in list do
			if Net.Data and Net.Data.Owned[item.Id] then
				owned += 1
			end
		end
		infoLabel.Text = string.format("%s %s — มีแล้ว %d / %d", category.Icon, category.Name, owned, #list)
	end
end

local function render()
	if not window or not window.Visible then
		return
	end
	local data = Net.Data
	if not data then
		return
	end
	local scrollPosition = grid.CanvasPosition
	clearGrid()

	for id, button in tabButtons do
		button.BackgroundColor3 = id == currentTab and Colors.Header or Color3.new(1, 1, 1)
		button.TextColor3 = id == currentTab and Color3.new(1, 1, 1) or Colors.Text
	end

	if currentTab == "Gems" then
		local order = 0
		for passName, pass in Config.GamePasses do
			order += 1
			robuxCard(order, pass.Icon, pass.Name, pass.Description, "Game Pass", player:GetAttribute(passName) == true, pass.Id, Enum.InfoType.GamePass)
		end
		for _, pack in Config.GemPacks do
			order += 1
			robuxCard(order + 10, pack.Icon, pack.Name, "💎 " .. pack.Gems .. " เพชร", pack.Bonus, false, pack.ProductId, Enum.InfoType.Product)
		end
	else
		local list
		if currentTab == "Featured" then
			list = {}
			for _, id in (ShopRotation.GetFeatured()) do
				table.insert(list, ItemCatalog.ById[id])
			end
		elseif currentTab == "Owned" then
			list = {}
			for _, item in ItemCatalog.List do
				if data.Owned[item.Id] then
					table.insert(list, item)
				end
			end
			ItemCatalog.Sort(list)
		else
			list = ItemCatalog.GetByCategory(currentTab)
		end
		for i, item in list do
			itemCard(item, data, i)
		end
	end

	updateInfo()
	task.defer(function()
		grid.CanvasPosition = scrollPosition
	end)
end

function ShopUI.Open(tabId)
	if tabId then
		if tabId ~= currentTab then
			grid.CanvasPosition = Vector2.zero
		end
		currentTab = tabId
	end
	UIKit.open(window)
	render()
end

function ShopUI.Toggle()
	if window.Visible then
		UIKit.close(window)
	else
		ShopUI.Open()
	end
end

function ShopUI.Init()
	gui = UIKit.screenGui("Shop")
	gui.DisplayOrder = 10

	local content
	window, content = UIKit.window(gui, "🛍️ ร้านสกินปาร์ตี้", UDim2.fromOffset(820, 520))

	tabList = UIKit.new("ScrollingFrame", {
		Size = UDim2.new(0, 170, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = content,
	}, {
		UIKit.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		UIKit.new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8) }),
	})
	for i, tab in TABS do
		tabButtons[tab.Id] = UIKit.button({
			Text = tab.Icon .. " " .. tab.Name,
			Size = UDim2.new(1, 0, 0, 44),
			LayoutOrder = i,
			BackgroundColor3 = Color3.new(1, 1, 1),
			TextColor3 = Colors.Text,
			MaxTextSize = 20,
			Parent = tabList,
		}, function()
			ShopUI.Open(tab.Id)
		end)
	end

	infoLabel = UIKit.label({
		Size = UDim2.new(1, -184, 0, 30),
		Position = UDim2.fromOffset(180, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 20,
		Parent = content,
	})

	grid = UIKit.new("ScrollingFrame", {
		Size = UDim2.new(1, -180, 1, -38),
		Position = UDim2.fromOffset(180, 36),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = content,
	}, {
		UIKit.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(146, 214),
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		UIKit.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4) }),
	})

	confirmText = buildConfirm()

	Net.Changed:Connect(render)
	player.AttributeChanged:Connect(function(name)
		if name == "VIP" or name == "DoubleCoins" then
			render()
		end
	end)

	-- นับถอยหลังของลดราคา
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
