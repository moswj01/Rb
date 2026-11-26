--[[
	Journal — สมุดบันทึกผู้พิทักษ์ (หน้าจอหลักแบบหนังสือเวท)
	แท็บ: สัตว์ของฉัน · สมุดภาพสัตว์ · กระเป๋า · ภารกิจ · แผนที่ · ตั้งค่า
	เปิด/ปิด: J (PC) หรือปุ่มสมุดบนจอ (มือถือ)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Species = require(Shared.Species)
local Items = require(Shared.Items)
local Quests = require(Shared.Quests)
local WorldLayout = require(Shared.WorldLayout)
local Config = require(Shared.Config)
local Net = require(Shared.Net)

local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local Journal = {}

local Colors = Theme.Colors
local player = Players.LocalPlayer
local book, pageLeft, pageRight, tabButtons = nil, nil, nil, {}
local currentTab = "Creatures"
local selected = {}

local TABS = {
	{ Id = "Creatures", Name = "สัตว์ของฉัน" },
	{ Id = "Bestiary", Name = "สมุดภาพสัตว์" },
	{ Id = "Inventory", Name = "กระเป๋า" },
	{ Id = "Quests", Name = "ภารกิจ" },
	{ Id = "Map", Name = "แผนที่" },
	{ Id = "Settings", Name = "ตั้งค่า" },
}

local STAGE = { Egg = "ไข่", Baby = "วัยทารก", Juvenile = "วัยรุ่น", Adult = "วัยผู้ใหญ่" }

local function list(parent)
	return Theme.new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Colors.Gold, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = parent }, {
		Theme.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
end

local function entryButton(parent, order, title, subtitle, iconKey, isSelected, onClick)
	local button = Theme.new("TextButton", { LayoutOrder = order, Size = UDim2.new(1, -8, 0, 58), BackgroundColor3 = isSelected and Colors.Forest or Colors.MidnightDeep, BackgroundTransparency = isSelected and 0.1 or 0.35, Text = "", AutoButtonColor = true, Parent = parent }, {
		Theme.corner(6),
		Theme.stroke(isSelected and Colors.Gold or Colors.GoldDim, 1, isSelected and 0 or 0.5),
	})
	local icon = Theme.icon(iconKey, title, UDim2.fromOffset(42, 42), button)
	icon.Position = UDim2.fromOffset(8, 8)
	Theme.title({ Text = title, Size = UDim2.new(1, -64, 0, 24), Position = UDim2.fromOffset(58, 6), TextSize = 19, Parent = button })
	Theme.text({ Text = subtitle, Size = UDim2.new(1, -64, 0, 20), Position = UDim2.fromOffset(58, 30), TextSize = 14, TextColor3 = Colors.IvoryDim, Parent = button })
	button.Activated:Connect(onClick)
	return button
end

local function heading(parent, text, y)
	return Theme.title({ Text = text, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, y or 0), TextSize = 30, Parent = parent })
end

local function paragraph(parent, text, y, height, size)
	return Theme.text({ Text = text, Size = UDim2.new(1, 0, 0, height or 60), Position = UDim2.fromOffset(0, y), TextSize = size or 17, TextYAlignment = Enum.TextYAlignment.Top, Parent = parent })
end

-- ===== แท็บ: สัตว์ของฉัน =====
local function renderCreatures(profile)
	local scroll = list(pageLeft)
	local ids = {}
	for id in profile.Creatures do
		table.insert(ids, id)
	end
	table.sort(ids)
	if #ids == 0 then
		paragraph(scroll, "ยังไม่มีสัตว์ในความดูแล\nทำภารกิจ <font color='#ECCE8C'>เสียงร้องใต้ต้นไม้ผู้เฒ่า</font> เพื่อพบเพื่อนคนแรก", 0, 80)
	end
	selected.Creature = selected.Creature or ids[1]
	for i, id in ids do
		local c = profile.Creatures[id]
		local def = Species.ById[c.Species]
		entryButton(scroll, i, c.Name, string.format("%s · %s", def.ThaiName, STAGE[c.Stage] or c.Stage), "creature_" .. c.Species, id == selected.Creature, function()
			selected.Creature = id
			Journal.Render()
		end)
	end
	local c = selected.Creature and profile.Creatures[selected.Creature]
	if not c then
		return
	end
	local def = Species.ById[c.Species]
	heading(pageRight, c.Name)
	paragraph(pageRight, string.format("<font color='#C9A55A'>%s</font> · %s · นิสัย%s", def.Name, STAGE[c.Stage], Species.Personalities[c.Personality].Name), 38, 24, 16)
	local y = 70
	for _, need in { { "Hunger", "ความอิ่ม", Color3.fromRGB(220, 160, 90) }, { "Energy", "พลังงาน", Colors.Sky }, { "Joy", "ความสุข", Color3.fromRGB(230, 130, 170) } } do
		Theme.text({ Text = need[2], Size = UDim2.fromOffset(90, 20), Position = UDim2.fromOffset(0, y), TextSize = 16, TextColor3 = Colors.Gold, Parent = pageRight })
		local _, fill = Theme.bar(pageRight, need[3], UDim2.fromOffset(96, y + 6), UDim2.new(1, -100, 0, 10))
		Theme.setBar(fill, c[need[1]] / 100)
		y += 28
	end
	local nextXP = c.Stage == "Baby" and Config.Growth.CareXPToJuvenile or (c.Stage == "Juvenile" and Config.Growth.CareXPToAdult or nil)
	Theme.text({ Text = nextXP and string.format("การเติบโต: %d / %d Care XP (ความสุขต้อง ≥ %d)", c.CareXP, nextXP, Config.Growth.MinJoyToGrow) or "โตเต็มวัยแล้ว", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, y), TextSize = 15, TextColor3 = Colors.IvoryDim, Parent = pageRight })
	if nextXP then
		local _, fill = Theme.bar(pageRight, Colors.GoldBright, UDim2.fromOffset(0, y + 24), UDim2.new(1, 0, 0, 8))
		Theme.setBar(fill, c.CareXP / nextXP)
	end
	y += 46
	paragraph(pageRight, string.format("<font color='#C9A55A'>ความสามารถพิเศษ:</font> %s — %s", def.Ability.Name, def.Ability.Description), y, 44, 15)
	y += 50
	paragraph(pageRight, string.format("<font color='#C9A55A'>ของโปรด:</font> %s", Items.ById[def.Favorite] and Items.ById[def.Favorite].ThaiName or "?"), y, 22, 15)
	y += 30
	local box = Theme.new("TextBox", { Size = UDim2.new(1, -130, 0, 34), Position = UDim2.fromOffset(0, y), BackgroundColor3 = Colors.MidnightDeep, Font = Theme.Fonts.Body, TextSize = 16, TextColor3 = Colors.Ivory, PlaceholderText = "ตั้งชื่อใหม่…", PlaceholderColor3 = Colors.IvoryDim, Text = "", ClearTextOnFocus = false, Parent = pageRight }, { Theme.corner(6), Theme.stroke(Colors.GoldDim, 1) })
	Theme.button({ Text = "ตั้งชื่อ", Size = UDim2.fromOffset(118, 34), Position = UDim2.new(1, -118, 0, y), Parent = pageRight }, function()
		local model
		for _, m in game:GetService("CollectionService"):GetTagged("Creature") do
			if m:GetAttribute("CreatureId") == selected.Creature and m:GetAttribute("OwnerId") == player.UserId then
				model = m
			end
		end
		if not model then
			Toast.Show("ไปหา " .. c.Name .. " ที่เขตอนุรักษ์ก่อนนะ แล้วตั้งชื่อตอนอยู่ใกล้ ๆ", "warn")
			return
		end
		local ok, message = Net.Invoke("CreatureAction", model:GetAttribute("EntityId"), "Rename", box.Text)
		Toast.Show(message or (ok and "ตั้งชื่อแล้ว" or "ตั้งชื่อไม่สำเร็จ"), ok and "info" or "warn")
	end)
end

-- ===== แท็บ: สมุดภาพสัตว์ =====
local function renderBestiary(profile)
	local scroll = list(pageLeft)
	selected.Species = selected.Species or Species.List[1].Id
	for i, def in Species.List do
		local entry = profile.Bestiary[def.Id]
		local title = entry and def.ThaiName or "???"
		local subtitle = entry and (entry.Bonded and "ผูกพันแล้ว ✦" or ("พบแล้ว " .. entry.Seen .. " ครั้ง")) or (def.Phase > 1 and "ดินแดนที่ยังไม่เปิด" or "ยังไม่พบ")
		entryButton(scroll, i, title, subtitle, entry and ("creature_" .. def.Id) or "unknown", def.Id == selected.Species, function()
			selected.Species = def.Id
			Journal.Render()
		end)
	end
	local def = Species.ById[selected.Species]
	local entry = profile.Bestiary[def.Id]
	if not entry then
		heading(pageRight, "สัตว์ปริศนา")
		paragraph(pageRight, "ร่องรอยที่ชาวบ้านเคยพบ:", 44, 24)
		local y = 72
		for _, clue in def.Clues do
			paragraph(pageRight, "✧ " .. clue, y, 24, 16)
			y += 26
		end
		return
	end
	heading(pageRight, def.ThaiName)
	paragraph(pageRight, string.format("<i>%s</i> · ธาตุ%s · %s", def.Name, def.Element, def.Rarity), 38, 22, 15)
	paragraph(pageRight, def.Lore, 66, 96, 17)
	local likes = {}
	for _, id in def.Likes do
		table.insert(likes, Items.ById[id] and Items.ById[id].ThaiName or id)
	end
	local active = { Day = "กลางวัน", Night = "กลางคืน", Dusk = "พลบค่ำถึงกลางคืน", Any = "ทุกเวลา" }
	local info = {
		"<font color='#C9A55A'>ช่วงเวลาที่พบ:</font> " .. active[def.ActiveTime],
		"<font color='#C9A55A'>ของโปรด:</font> " .. (Items.ById[def.Favorite] and Items.ById[def.Favorite].ThaiName or "ยังไม่ทราบ"),
		"<font color='#C9A55A'>ชอบ:</font> " .. table.concat(likes, ", "),
		"<font color='#C9A55A'>ความสามารถ:</font> " .. def.Ability.Name,
		"<font color='#C9A55A'>นิสัยที่พบได้:</font> " .. (function()
			local names = {}
			for _, p in def.Personalities do
				table.insert(names, Species.Personalities[p].Name)
			end
			return table.concat(names, ", ")
		end)(),
	}
	paragraph(pageRight, table.concat(info, "\n"), 168, 140, 16)
end

-- ===== แท็บ: กระเป๋า =====
local CATEGORY = { Food = "อาหาร", Herb = "สมุนไพร", Potion = "ยา", Egg = "ไข่", Habitat = "ที่อยู่สัตว์", Decor = "ของตกแต่ง" }

local function renderInventory(profile)
	local scroll = list(pageLeft)
	local order = 0
	for _, item in Items.List do
		local count = profile.Inventory[item.Id]
		if count and count > 0 then
			order += 1
			selected.Item = selected.Item or item.Id
			entryButton(scroll, order, string.format("%s  ×%d", item.ThaiName, count), CATEGORY[item.Category] or item.Category, item.Icon, item.Id == selected.Item, function()
				selected.Item = item.Id
				Journal.Render()
			end)
		end
	end
	Theme.title({ Text = string.format("✧ %d Lumen", profile.Coins), Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 1, -28), TextSize = 22, Parent = pageRight })
	local item = selected.Item and Items.ById[selected.Item]
	if not item then
		paragraph(pageRight, "กระเป๋าว่างเปล่า", 0)
		return
	end
	heading(pageRight, item.ThaiName)
	paragraph(pageRight, string.format("<i>%s</i> · %s", item.Name, CATEGORY[item.Category]), 38, 22, 15)
	paragraph(pageRight, item.Description, 66, 60)
	if item.Placeable then
		paragraph(pageRight, "<font color='#C9A55A'>วางได้ในเขตอนุรักษ์</font> — เข้าเขตอนุรักษ์แล้วกด B เพื่อจัดวาง", 126, 44, 15)
	end
end

-- ===== แท็บ: ภารกิจ =====
local function renderQuests(profile)
	local scroll = list(pageLeft)
	local order = 0
	for questId in profile.Quests.Active do
		local quest = Quests.ById[questId]
		if quest then
			order += 1
			selected.Quest = selected.Quest or questId
			entryButton(scroll, order, quest.Title, profile.Quests.Tracked == questId and "กำลังติดตาม ✦" or "กำลังทำ", "quest", questId == selected.Quest, function()
				selected.Quest = questId
				Net.Invoke("TrackQuest", questId)
				Journal.Render()
			end)
		end
	end
	for _, quest in Quests.List do
		if profile.Quests.Done[quest.Id] then
			order += 1
			entryButton(scroll, order, quest.Title, "สำเร็จแล้ว", "quest_done", quest.Id == selected.Quest, function()
				selected.Quest = quest.Id
				Journal.Render()
			end)
		end
	end
	local quest = selected.Quest and Quests.ById[selected.Quest]
	if not quest then
		return
	end
	heading(pageRight, quest.Title)
	paragraph(pageRight, quest.Story, 40, 80)
	local progress = profile.Quests.Active[quest.Id] or {}
	local done = profile.Quests.Done[quest.Id] ~= nil
	local y = 126
	for index, objective in quest.Objectives do
		local value = done and objective.Count or (progress[tostring(index)] or 0)
		local mark = value >= objective.Count and "<font color='#9FD8A8'>✔</font>" or "<font color='#C9A55A'>◇</font>"
		paragraph(pageRight, string.format("%s %s  (%d/%d)", mark, objective.Text, value, objective.Count), y, 24, 16)
		y += 28
	end
	local rewards = { string.format("✧ %d Lumen", quest.Rewards.Coins or 0), string.format("%d XP", quest.Rewards.XP or 0) }
	for itemId, amount in quest.Rewards.Items or {} do
		table.insert(rewards, string.format("%s ×%d", Items.ById[itemId].ThaiName, amount))
	end
	paragraph(pageRight, "<font color='#C9A55A'>รางวัล:</font> " .. table.concat(rewards, " · "), y + 8, 44, 15)
end

-- ===== แท็บ: แผนที่ =====
local mapDot
local function renderMap(profile)
	local T = WorldLayout.Terrain
	local holder = Theme.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(46, 58, 44), Parent = pageLeft.Parent }, { Theme.corner(6), Theme.stroke(Colors.Gold, 1.5) })
	holder.Position = pageLeft.Position
	holder.Size = UDim2.new(pageRight.Position.X.Scale + pageRight.Size.X.Scale, pageRight.Position.X.Offset + pageRight.Size.X.Offset - pageLeft.Position.X.Offset, pageLeft.Size.Y.Scale, pageLeft.Size.Y.Offset)
	holder.Name = "MapCanvas"
	local width = T.Max.X - T.Min.X
	local depth = T.Max.Z - T.Min.Z
	local function toUI(pos)
		return UDim2.fromScale((pos.X - T.Min.X) / width, (pos.Z - T.Min.Z) / depth)
	end
	local function line(a, b, thickness, color, transparency)
		local pa, pb = toUI(a), toUI(b)
		local size = holder.AbsoluteSize
		local ax, ay = pa.X.Scale * size.X, pa.Y.Scale * size.Y
		local bx, by = pb.X.Scale * size.X, pb.Y.Scale * size.Y
		local length = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
		Theme.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((ax + bx) / 2, (ay + by) / 2), Size = UDim2.fromOffset(length, thickness), Rotation = math.deg(math.atan2(by - ay, bx - ax)), BackgroundColor3 = color, BackgroundTransparency = transparency or 0, BorderSizePixel = 0, Parent = holder })
	end
	task.defer(function()
		if not holder.Parent then
			return
		end
		for _, zone in WorldLayout.Zones do
			local size = holder.AbsoluteSize
			local r = zone.Radius / width * size.X
			local p = toUI(zone.Center)
			Theme.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = p, Size = UDim2.fromOffset(r * 2, r * 2 * width / depth * size.Y / size.X), BackgroundColor3 = zone.Id == "MysticVillage" and Color3.fromRGB(150, 140, 100) or Color3.fromRGB(40, 80, 54), BackgroundTransparency = 0.55, Parent = holder }, {
				Theme.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			})
			Theme.title({ Text = zone.ThaiName, Position = p + UDim2.fromOffset(-80, -12), Size = UDim2.fromOffset(160, 24), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 0.25, Parent = holder })
		end
		local river = WorldLayout.River.Points
		for i = 1, #river - 1 do
			line(river[i].Pos, river[i + 1].Pos, 5, Color3.fromRGB(110, 170, 200))
		end
		for _, path in WorldLayout.Paths do
			for i = 1, #path.Points - 1 do
				line(path.Points[i], path.Points[i + 1], path.Id == "HiddenTrail" and 1 or 2, Colors.IvoryDim, path.Id == "HiddenTrail" and 0.6 or 0.2)
			end
		end
		for _, landmark in WorldLayout.Landmarks do
			if landmark.Role == "Hero" then
				local known = profile.Landmarks[landmark.Key] ~= nil
				Theme.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = toUI(landmark.Pos), Size = UDim2.fromOffset(12, 12), Rotation = 45, BackgroundColor3 = known and Colors.GoldBright or Colors.MidnightSoft, Parent = holder }, { Theme.stroke(Colors.Gold, 1) })
			end
		end
		mapDot = Theme.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Colors.Rose, Parent = holder }, {
			Theme.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Theme.stroke(Colors.Ivory, 2),
		})
		Theme.text({ Text = "◆ ทอง = สถานที่ที่ค้นพบแล้ว   ● ชมพู = ตำแหน่งของคุณ", Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 8, 1, -26), TextSize = 14, Parent = holder })
	end)
	return toUI
end

-- ===== แท็บ: ตั้งค่า =====
local function slider(parent, y, label, value, onChange)
	Theme.text({ Text = label, Size = UDim2.fromOffset(160, 24), Position = UDim2.fromOffset(0, y), TextSize = 17, Parent = parent })
	local track = Theme.new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.new(1, -180, 0, 10), Position = UDim2.fromOffset(170, y + 8), BackgroundColor3 = Colors.MidnightDeep, Parent = parent }, { Theme.corner(5), Theme.stroke(Colors.GoldDim, 1) })
	local fill = Theme.new("Frame", { Size = UDim2.fromScale(value, 1), BackgroundColor3 = Colors.Gold, Parent = track }, { Theme.corner(5) })
	local dragging = false
	local function set(x)
		local v = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.fromScale(v, 1)
		onChange(v)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			set(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			set(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local function renderSettings(profile)
	local settings = table.clone(profile.Settings)
	heading(pageLeft, "ตั้งค่า")
	local function save()
		Net.Invoke("SaveSettings", settings)
		if Journal.OnSettings then
			Journal.OnSettings(settings)
		end
	end
	slider(pageLeft, 50, "ดนตรี", settings.Music, function(v)
		settings.Music = v
		if Journal.OnSettings then
			Journal.OnSettings(settings)
		end
	end)
	slider(pageLeft, 90, "เสียงเอฟเฟกต์", settings.Sfx, function(v)
		settings.Sfx = v
		if Journal.OnSettings then
			Journal.OnSettings(settings)
		end
	end)
	Theme.text({ Text = "คุณภาพกราฟิก", Size = UDim2.fromOffset(160, 24), Position = UDim2.fromOffset(0, 136), TextSize = 17, Parent = pageLeft })
	for i, quality in { "Auto", "Low", "Medium", "High" } do
		Theme.button({ Text = quality, Size = UDim2.fromOffset(76, 32), Position = UDim2.fromOffset(170 + (i - 1) * 82, 132), Style = settings.Graphics == quality and "Primary" or "Secondary", TextSize = 15, Parent = pageLeft }, function()
			settings.Graphics = quality
			save()
		end)
	end
	Theme.button({ Text = "บันทึกการตั้งค่า", Size = UDim2.fromOffset(180, 38), Position = UDim2.fromOffset(0, 190), Parent = pageLeft }, save)
	heading(pageRight, "การควบคุม")
	paragraph(pageRight, table.concat({
		"<font color='#C9A55A'>J</font>  เปิดสมุดบันทึก",
		"<font color='#C9A55A'>C</font>  ย่อตัว (เข้าหาสัตว์อย่างนุ่มนวล)",
		"<font color='#C9A55A'>Shift</font>  วิ่ง (สัตว์ขี้กลัวจะตกใจ)",
		"<font color='#C9A55A'>E</font>  โต้ตอบ  ·  <font color='#C9A55A'>1–4</font>  คำสั่งกับสัตว์",
		"<font color='#C9A55A'>B</font>  โหมดจัดวางในเขตอนุรักษ์  ·  <font color='#C9A55A'>R</font> หมุน",
		"",
		string.format("<font color='#C4BAA6'>Mythical Sanctuary %s</font>", Config.Version),
	}, "\n"), 44, 220, 16)
end

-- ===== render =====
function Journal.Render()
	if not book or not book.Visible or not State.Profile then
		return
	end
	for id, button in tabButtons do
		local active = id == currentTab
		button.BackgroundColor3 = active and Colors.Forest or Colors.MidnightSoft
		button:FindFirstChildOfClass("UIStroke").Color = active and Colors.GoldBright or Colors.GoldDim
	end
	Theme.clear(pageLeft)
	Theme.clear(pageRight)
	local canvas = book:FindFirstChild("MapCanvas", true)
	if canvas then
		canvas:Destroy()
	end
	mapDot = nil
	local renderers = { Creatures = renderCreatures, Bestiary = renderBestiary, Inventory = renderInventory, Quests = renderQuests, Map = renderMap, Settings = renderSettings }
	local result = renderers[currentTab](State.Profile)
	Journal.MapToUI = currentTab == "Map" and result or nil
end

function Journal.Open(tab)
	if tab then
		currentTab = tab
	end
	Theme.show(book, true)
	Journal.Render()
end

function Journal.Toggle()
	if book.Visible then
		book.Visible = false
	else
		Journal.Open()
	end
end

function Journal.Init(gui)
	book = Theme.panel({ Name = "Journal", Size = UDim2.fromOffset(980, 600), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Parent = gui })
	Theme.scale(book, 1080, 720)
	Theme.title({ Text = "สมุดบันทึกผู้พิทักษ์", Size = UDim2.new(1, -80, 0, 36), Position = UDim2.fromOffset(28, 16), TextSize = 32, Parent = book })
	Theme.button({ Text = "✕", Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -50, 0, 16), Style = "Secondary", Parent = book }, function()
		book.Visible = false
	end)
	local tabs = Theme.new("Frame", { Size = UDim2.new(1, -56, 0, 38), Position = UDim2.fromOffset(28, 60), BackgroundTransparency = 1, Parent = book }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, tab in TABS do
		tabButtons[tab.Id] = Theme.button({ Text = tab.Name, Size = UDim2.fromOffset(148, 34), LayoutOrder = i, Style = "Secondary", TextSize = 16, Parent = tabs }, function()
			currentTab = tab.Id
			Journal.Render()
		end)
	end
	-- หน้ากระดาษซ้าย/ขวา + เส้นสันหนังสือ
	pageLeft = Theme.new("Frame", { Name = "PageLeft", Size = UDim2.new(0.42, -36, 1, -136), Position = UDim2.fromOffset(28, 112), BackgroundTransparency = 1, Parent = book })
	Theme.new("Frame", { Size = UDim2.new(0, 1, 1, -150), Position = UDim2.new(0.42, 0, 0, 118), BackgroundColor3 = Colors.GoldDim, BorderSizePixel = 0, Parent = book })
	pageRight = Theme.new("Frame", { Name = "PageRight", Size = UDim2.new(0.58, -50, 1, -136), Position = UDim2.new(0.42, 22, 0, 112), BackgroundTransparency = 1, Parent = book })

	State.Changed:Connect(function()
		if currentTab ~= "Map" and currentTab ~= "Settings" then
			Journal.Render()
		end
	end)
	RunService.RenderStepped:Connect(function()
		if mapDot and Journal.MapToUI then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				mapDot.Position = Journal.MapToUI(root.Position)
			end
		end
	end)
end

return Journal
