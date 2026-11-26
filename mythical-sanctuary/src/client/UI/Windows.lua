--[[
	Windows — หน้าต่างตามบริบท: บทสนทนา NPC, ร้านค้า, หม้อยา
	(สมุดบันทึกหลักอยู่ใน Journal.lua)
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Items)
local Quests = require(Shared.Quests)
local WorldLayout = require(Shared.WorldLayout)
local Net = require(Shared.Net)

local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local Windows = {}

local Colors = Theme.Colors
local gui
local dialog, dialogName, dialogText, dialogButtons
local shop, shopList, shopTab
local craft, craftList, brewBar, brewFill
local openWindow

local NPC_LINES = {
	npc_elder = "ป่าเสียงกระซิบไม่เคยเงียบจริง ๆ หรอก… มันแค่รอให้ใครสักคนตั้งใจฟัง",
	npc_bramble = "อาหารสด ๆ จากสวนหลังร้าน! สัตว์แต่ละตัวมีของโปรดต่างกันนะ ลองสังเกตดู",
	npc_willow = "สมุนไพรที่ดีต้องเก็บด้วยความเคารพ หม้อยาอยู่หน้าร้าน ใช้ได้ตามสบาย",
	npc_quill = "ทุกสัตว์ที่เธอพบ จะถูกบันทึกลงสมุดภาพสัตว์ของเธอเอง เปิดดูได้ทุกเมื่อ (กด J)",
	npc_pip = "เมื่อคืนฉันเห็นแสงสีเงินวิ่งผ่านน้ำตก! ต้องเป็นกวางจันทราแน่ ๆ",
	npc_rowan = "ระวังทางลับฝั่งตะวันตกนะ เฟิร์นขึ้นรกจนแทบมองไม่เห็นทาง… ได้ยินว่ามีถ้ำอยู่",
}

local function npcDef(id)
	for _, npc in WorldLayout.Npcs do
		if npc.Id == id then
			return npc
		end
	end
	return nil
end

local function closeAll()
	for _, w in { dialog, shop, craft } do
		w.Visible = false
	end
	openWindow = nil
end

local function open(window)
	closeAll()
	openWindow = window
	Theme.show(window, true)
end

local function windowFrame(name, size)
	local frame = Theme.panel({ Name = name, Size = size, Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Parent = gui })
	Theme.scale(frame, size.X.Offset + 120, size.Y.Offset + 160)
	Theme.button({ Text = "✕", Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -44, 0, 10), Style = "Secondary", TextSize = 18, ZIndex = 4, Parent = frame }, closeAll)
	return frame
end

-- ===== บทสนทนา =====
function Windows.Talk(npcId)
	local def = npcDef(npcId)
	if not def then
		return
	end
	local ok, role = Net.Invoke("TalkToNpc", npcId)
	if not ok then
		if role then
			Toast.Show(role, "warn")
		end
		return
	end
	dialogName.Text = def.ThaiName .. "  <font color='#C4BAA6' size='16'>" .. def.Name .. "</font>"
	local line = NPC_LINES[npcId] or "สวัสดี ผู้พิทักษ์"
	-- ถ้า NPC นี้เป็นผู้ให้ภารกิจที่กำลังทำ ให้เล่าเรื่องของภารกิจนั้น
	local profile = State.Profile
	if profile then
		for questId in profile.Quests.Active do
			local quest = Quests.ById[questId]
			if quest and quest.Giver == npcId then
				line = quest.Story
			end
		end
	end
	dialogText.Text = ""
	Theme.clear(dialogButtons)
	if role == "Shop" then
		Theme.button({ Text = "ดูสินค้า", Size = UDim2.fromOffset(150, 38), Parent = dialogButtons }, function()
			Windows.OpenShop()
		end)
	elseif role == "Bestiary" then
		Theme.button({ Text = "เปิดสมุดภาพสัตว์", Size = UDim2.fromOffset(170, 38), Parent = dialogButtons }, function()
			closeAll()
			if Windows.OpenJournal then
				Windows.OpenJournal("Bestiary")
			end
		end)
	end
	Theme.button({ Text = "ลาก่อน", Size = UDim2.fromOffset(120, 38), Style = "Secondary", Parent = dialogButtons }, closeAll)
	open(dialog)
	-- พิมพ์ทีละตัวอักษร
	task.spawn(function()
		local chars = utf8.len(line) or #line
		for i = 1, chars do
			if openWindow ~= dialog then
				break
			end
			local cut = utf8.offset(line, i + 1)
			dialogText.Text = cut and string.sub(line, 1, cut - 1) or line
			task.wait(0.018)
		end
		dialogText.Text = line
	end)
end

-- ===== ร้านค้า =====
local function renderShop()
	Theme.clear(shopList)
	local buying = shopTab == "Buy"
	for _, item in Items.List do
		local price = buying and item.Price or item.SellPrice
		local count = State.Count(item.Id)
		if price and (buying or count > 0) and item.Category ~= "Egg" then
			local row = Theme.new("Frame", { Size = UDim2.new(1, -10, 0, 64), BackgroundColor3 = Colors.MidnightDeep, BackgroundTransparency = 0.3, Parent = shopList }, { Theme.corner(6), Theme.stroke(Colors.GoldDim, 1, 0.5) })
			local icon = Theme.icon(item.Icon, item.Name, UDim2.fromOffset(48, 48), row)
			icon.Position = UDim2.fromOffset(8, 8)
			Theme.title({ Text = item.ThaiName, Size = UDim2.new(1, -280, 0, 24), Position = UDim2.fromOffset(66, 6), TextSize = 20, Parent = row })
			Theme.text({ Text = item.Description .. string.format("  <font color='#C9A55A'>(มี %d)</font>", count), Size = UDim2.new(1, -280, 0, 30), Position = UDim2.fromOffset(66, 30), TextSize = 14, TextColor3 = Colors.IvoryDim, Parent = row })
			Theme.text({ Text = string.format("✧ %d", price), Size = UDim2.fromOffset(70, 64), Position = UDim2.new(1, -196, 0, 0), TextSize = 20, TextColor3 = Colors.GoldBright, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
			Theme.button({ Text = buying and "ซื้อ" or "ขาย", Size = UDim2.fromOffset(100, 36), Position = UDim2.new(1, -112, 0.5, -18), Parent = row }, function()
				local ok, message = Net.Invoke(buying and "Buy" or "Sell", item.Id, 1)
				if not ok and message then
					Toast.Show(message, "warn")
				end
			end)
		end
	end
end

function Windows.OpenShop()
	shopTab = shopTab or "Buy"
	renderShop()
	open(shop)
end

-- ===== หม้อยา =====
local function renderCraft()
	Theme.clear(craftList)
	for _, recipe in Items.Recipes do
		local output = Items.ById[recipe.Output]
		local row = Theme.new("Frame", { Size = UDim2.new(1, -10, 0, 78), BackgroundColor3 = Colors.MidnightDeep, BackgroundTransparency = 0.3, Parent = craftList }, { Theme.corner(6), Theme.stroke(Colors.GoldDim, 1, 0.5) })
		local icon = Theme.icon(output.Icon, output.Name, UDim2.fromOffset(54, 54), row)
		icon.Position = UDim2.fromOffset(10, 12)
		Theme.title({ Text = output.ThaiName, Size = UDim2.new(1, -220, 0, 24), Position = UDim2.fromOffset(76, 8), TextSize = 20, Parent = row })
		local parts, ready = {}, true
		for itemId, amount in recipe.Inputs do
			local have = State.Count(itemId)
			local color = have >= amount and "#9FD8A8" or "#E07A80"
			if have < amount then
				ready = false
			end
			table.insert(parts, string.format("<font color='%s'>%s %d/%d</font>", color, Items.ById[itemId].ThaiName, have, amount))
		end
		Theme.text({ Text = table.concat(parts, "   "), Size = UDim2.new(1, -220, 0, 36), Position = UDim2.fromOffset(76, 34), TextSize = 15, Parent = row })
		local button = Theme.button({ Text = "ปรุง", Size = UDim2.fromOffset(110, 38), Position = UDim2.new(1, -122, 0.5, -19), Style = ready and "Primary" or "Secondary", Parent = row })
		button.Activated:Connect(function()
			if not ready then
				Toast.Show("วัตถุดิบไม่พอ ลองเก็บในป่าเสียงกระซิบ", "warn")
				return
			end
			brewBar.Visible = true
			brewFill.Size = UDim2.fromScale(0, 1)
			TweenService:Create(brewFill, TweenInfo.new(recipe.Seconds, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) }):Play()
			local ok, result = Net.Invoke("Craft", recipe.Id)
			brewBar.Visible = false
			Toast.Show(ok and ("✦ ปรุงสำเร็จ: " .. tostring(result)) or tostring(result), ok and "quest" or "warn")
		end)
	end
end

function Windows.OpenCrafting()
	renderCraft()
	open(craft)
end

function Windows.IsOpen()
	return openWindow ~= nil
end

function Windows.Init(screenGui)
	gui = screenGui

	dialog = Theme.panel({ Name = "Dialog", Size = UDim2.fromOffset(720, 190), Position = UDim2.new(0.5, 0, 1, -30), AnchorPoint = Vector2.new(0.5, 1), Visible = false, Parent = gui })
	Theme.scale(dialog, 900, 640)
	dialogName = Theme.title({ Size = UDim2.new(1, -40, 0, 30), Position = UDim2.fromOffset(22, 14), TextSize = 26, Parent = dialog })
	dialogText = Theme.text({ Size = UDim2.new(1, -44, 0, 80), Position = UDim2.fromOffset(22, 50), TextSize = 19, TextYAlignment = Enum.TextYAlignment.Top, Parent = dialog })
	dialogButtons = Theme.new("Frame", { Size = UDim2.new(1, -44, 0, 40), Position = UDim2.new(0, 22, 1, -54), BackgroundTransparency = 1, Parent = dialog }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 10) }),
	})

	shop = windowFrame("Shop", UDim2.fromOffset(640, 480))
	Theme.title({ Text = "ร้านอาหารสัตว์ของแบรมเบิล", Size = UDim2.new(1, -80, 0, 34), Position = UDim2.fromOffset(22, 14), TextSize = 28, Parent = shop })
	local tabs = Theme.new("Frame", { Size = UDim2.new(1, -44, 0, 36), Position = UDim2.fromOffset(22, 54), BackgroundTransparency = 1, Parent = shop }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
	})
	for _, tab in { { "Buy", "ซื้อ" }, { "Sell", "ขาย" } } do
		Theme.button({ Text = tab[2], Size = UDim2.fromOffset(110, 32), Style = "Secondary", Parent = tabs }, function()
			shopTab = tab[1]
			renderShop()
		end)
	end
	shopList = Theme.new("ScrollingFrame", { Size = UDim2.new(1, -44, 1, -112), Position = UDim2.fromOffset(22, 98), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Colors.Gold, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = shop }, {
		Theme.new("UIListLayout", { Padding = UDim.new(0, 6) }),
	})

	craft = windowFrame("Crafting", UDim2.fromOffset(620, 420))
	Theme.title({ Text = "หม้อยาเวทมนตร์", Size = UDim2.new(1, -80, 0, 34), Position = UDim2.fromOffset(22, 14), TextSize = 28, Parent = craft })
	Theme.text({ Text = "ใส่วัตถุดิบตามสูตร แล้วรอให้น้ำยาเดือดเปลี่ยนสี", Size = UDim2.new(1, -80, 0, 20), Position = UDim2.fromOffset(22, 48), TextSize = 15, TextColor3 = Colors.IvoryDim, Parent = craft })
	craftList = Theme.new("ScrollingFrame", { Size = UDim2.new(1, -44, 1, -130), Position = UDim2.fromOffset(22, 78), BackgroundTransparency = 1, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = craft }, {
		Theme.new("UIListLayout", { Padding = UDim.new(0, 6) }),
	})
	brewBar, brewFill = Theme.bar(craft, Colors.ForestBright, UDim2.new(0, 22, 1, -36), UDim2.new(1, -44, 0, 12))
	brewBar.Visible = false

	State.Changed:Connect(function()
		if shop.Visible then
			renderShop()
		end
		if craft.Visible then
			renderCraft()
		end
	end)
end

Windows.CloseAll = closeAll

return Windows
