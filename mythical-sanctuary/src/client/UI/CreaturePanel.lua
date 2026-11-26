--[[
	CreaturePanel — แผงโต้ตอบกับสัตว์ที่อยู่ใกล้ที่สุด (≤ 14 studs)
	สัตว์ป่า:   [ให้ของ] [ปลอบ] [ผูกพัน]   + แถบความไว้วางใจ
	สัตว์ของเรา: [ให้อาหาร] [ลูบหัว] [เล่น] [ตามมา]  + แถบ หิว/พลังงาน/ความสุข
	ป้ายอารมณ์ลอยเหนือหัวสัตว์เมื่อมีปฏิกิริยา (รัก, ตกใจ, สงบ, ผูกพัน)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Species = require(Shared.Species)
local Items = require(Shared.Items)
local Net = require(Shared.Net)
local Config = require(Shared.Config)

local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local CreaturePanel = {}

local Colors = Theme.Colors
local player = Players.LocalPlayer
local panel, nameLabel, subLabel, trustBar, trustFill, needsFrame, actionsRow, picker, pickerList
local needFills = {}
local target -- model ที่โฟกัสอยู่
local trustCache = {} -- [entityId] = trust

local MOODS = {
	Love = { Glyph = "♥", Color = Color3.fromRGB(255, 140, 170) },
	Happy = { Glyph = "✦", Color = Colors.GoldBright },
	Grateful = { Glyph = "✿", Color = Color3.fromRGB(200, 255, 210) },
	Calm = { Glyph = "~", Color = Colors.Sky },
	Playful = { Glyph = "♪", Color = Colors.GoldBright },
	Neutral = { Glyph = "…", Color = Colors.IvoryDim },
	Disgust = { Glyph = "×", Color = Colors.Rose },
	Scared = { Glyph = "!", Color = Colors.Rose },
	Bonded = { Glyph = "❖", Color = Colors.GoldBright },
}

local function bubble(model, mood)
	local def = MOODS[mood] or MOODS.Neutral
	local head = model:FindFirstChild("Head", true) or model.PrimaryPart
	if not head then
		return
	end
	local gui = Theme.new("BillboardGui", { Size = UDim2.fromOffset(46, 46), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true, LightInfluence = 0, Adornee = head, Parent = player.PlayerGui })
	local circle = Theme.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Colors.MidnightDeep, BackgroundTransparency = 0.15, Parent = gui }, {
		Theme.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Theme.stroke(def.Color, 2),
	})
	Theme.title({ Text = def.Glyph, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = def.Color, TextSize = 28, Parent = circle })
	TweenService:Create(gui, TweenInfo.new(1.8, Enum.EasingStyle.Quad), { StudsOffset = Vector3.new(0, 5, 0) }):Play()
	task.delay(1.2, function()
		TweenService:Create(circle, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	end)
	task.delay(1.9, function()
		gui:Destroy()
	end)
end

local function ownedRecord(model)
	local creatureId = model:GetAttribute("CreatureId")
	return creatureId and State.Profile and State.Profile.Creatures[creatureId]
end

local function isMine(model)
	return model:GetAttribute("OwnerId") == player.UserId
end

local function invoke(action, arg)
	if not target then
		return
	end
	local ok, message = Net.Invoke("CreatureAction", target:GetAttribute("EntityId"), action, arg)
	if message and type(message) == "string" then
		Toast.Show(message, ok and "info" or "warn")
	end
end

local function openPicker(action, filter)
	Theme.clear(pickerList)
	local any = false
	for _, item in Items.List do
		local count = State.Count(item.Id)
		if count > 0 and filter(item) then
			any = true
			Theme.button({ Text = string.format("%s  ×%d", item.ThaiName, count), Size = UDim2.new(1, -8, 0, 34), Style = "Secondary", TextSize = 16, Parent = pickerList }, function()
				picker.Visible = false
				invoke(action, item.Id)
			end)
		end
	end
	if not any then
		Theme.text({ Text = "ไม่มีของที่ใช้ได้ — ซื้อได้ที่ร้านของแบรมเบิล หรือเก็บในป่า", Size = UDim2.new(1, -8, 0, 44), TextSize = 15, TextColor3 = Colors.IvoryDim, Parent = pickerList })
	end
	Theme.show(picker, true)
end

local function rebuildActions(model)
	Theme.clear(actionsRow)
	picker.Visible = false
	local mine = isMine(model)
	local actions
	if mine then
		actions = {
			{ "ให้อาหาร", function()
				openPicker("Feed", function(item)
					return item.Category == "Food" or item.Id == "growth_tonic"
				end)
			end },
			{ "ลูบหัว", function()
				invoke("Pet")
			end },
			{ "เล่นด้วย", function()
				invoke("Play")
			end },
			{ "ตามมา/อยู่บ้าน", function()
				invoke("Follow")
			end },
		}
	else
		actions = {
			{ "ยื่นของให้", function()
				openPicker("Offer", function(item)
					return item.Category == "Food" or item.Id == "healing_salve" or item.Id == "calming_draught"
				end)
			end },
			{ "ปลอบโยน", function()
				invoke("Calm")
			end },
			{ "ผูกพัน", function()
				invoke("Bond")
			end },
		}
	end
	for i, action in actions do
		Theme.button({ Text = string.format("%d · %s", i, action[1]), Size = UDim2.fromOffset(132, 36), TextSize = 16, LayoutOrder = i, Style = i == 1 and "Primary" or "Secondary", Parent = actionsRow }, action[2])
	end
	CreaturePanel.Actions = actions
end

local function refresh()
	if not target then
		return
	end
	local speciesId = target:GetAttribute("Species")
	local def = Species.ById[speciesId]
	local known = State.Profile and State.Profile.Bestiary[speciesId]
	local mine = isMine(target)
	local personality = Species.Personalities[target:GetAttribute("Personality") or ""]
	nameLabel.Text = target:GetAttribute("DisplayName") or (def and def.ThaiName) or "?"
	local stageNames = { Baby = "วัยทารก", Juvenile = "วัยรุ่น", Adult = "วัยผู้ใหญ่", Egg = "ไข่" }
	local parts = { (known or mine) and def and def.Name or "สายพันธุ์ที่ยังไม่รู้จัก", stageNames[target:GetAttribute("Stage")] or "" }
	if personality and (known or mine) then
		table.insert(parts, "นิสัย" .. personality.Name)
	end
	if target:GetAttribute("Injured") then
		table.insert(parts, "<font color='#E07A80'>บาดเจ็บ</font>")
	end
	subLabel.Text = table.concat(parts, " · ")

	needsFrame.Visible = mine
	trustBar.Visible = not mine
	if mine then
		local record = ownedRecord(target)
		if record then
			Theme.setBar(needFills.Hunger, record.Hunger / 100)
			Theme.setBar(needFills.Energy, record.Energy / 100)
			Theme.setBar(needFills.Joy, record.Joy / 100)
		end
	else
		Theme.setBar(trustFill, (trustCache[target:GetAttribute("EntityId")] or 0) / Config.Trust.Max)
	end
end

local function nearestCreature()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local best, bestD = nil, 14
	for _, model in CollectionService:GetTagged("Creature") do
		local primary = model.PrimaryPart
		if primary and model:GetAttribute("EntityId") and model:GetAttribute("Stage") ~= "Egg" then
			local d = (primary.Position - root.Position).Magnitude
			if d < bestD then
				best, bestD = model, d
			end
		end
	end
	return best
end

function CreaturePanel.Init(gui)
	panel = Theme.panel({ Name = "CreaturePanel", Size = UDim2.fromOffset(600, 150), Position = UDim2.new(0.5, 0, 1, -24), AnchorPoint = Vector2.new(0.5, 1), Visible = false, Parent = gui })
	Theme.scale(panel, 900, 640)
	nameLabel = Theme.title({ Size = UDim2.new(1, -32, 0, 30), Position = UDim2.fromOffset(18, 12), TextSize = 26, Parent = panel })
	subLabel = Theme.text({ Size = UDim2.new(1, -32, 0, 20), Position = UDim2.fromOffset(18, 42), TextSize = 16, TextColor3 = Colors.IvoryDim, Parent = panel })

	trustBar, trustFill = Theme.bar(panel, Colors.GoldBright, UDim2.fromOffset(18, 70), UDim2.new(1, -150, 0, 10))
	Theme.text({ Text = "ความไว้วางใจ", Size = UDim2.fromOffset(110, 16), Position = UDim2.new(1, -124, 0, 66), TextSize = 14, TextColor3 = Colors.Gold, Parent = panel })

	needsFrame = Theme.new("Frame", { Size = UDim2.new(1, -36, 0, 18), Position = UDim2.fromOffset(18, 66), BackgroundTransparency = 1, Visible = false, Parent = panel }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14) }),
	})
	for i, need in { { "Hunger", "อิ่ม", Color3.fromRGB(220, 160, 90) }, { "Energy", "พลัง", Colors.Sky }, { "Joy", "สุข", Color3.fromRGB(230, 130, 170) } } do
		local holder = Theme.new("Frame", { LayoutOrder = i, Size = UDim2.fromOffset(176, 18), BackgroundTransparency = 1, Parent = needsFrame })
		Theme.text({ Text = need[2], Size = UDim2.fromOffset(34, 18), TextSize = 14, TextColor3 = Colors.Gold, Parent = holder })
		local _, fill = Theme.bar(holder, need[3], UDim2.fromOffset(36, 5), UDim2.new(1, -36, 0, 8))
		needFills[need[1]] = fill
	end

	actionsRow = Theme.new("Frame", { Size = UDim2.new(1, -36, 0, 40), Position = UDim2.fromOffset(18, 96), BackgroundTransparency = 1, Parent = panel }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	picker = Theme.panel({ Name = "Picker", Size = UDim2.fromOffset(260, 220), Position = UDim2.new(0, 0, 0, -12), AnchorPoint = Vector2.new(0, 1), Visible = false, Parent = panel })
	pickerList = Theme.new("ScrollingFrame", { Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = picker }, {
		Theme.new("UIListLayout", { Padding = UDim.new(0, 4) }),
	})

	Net.Event("CreatureFeedback").OnClientEvent:Connect(function(entityId, mood, trust, text)
		trustCache[entityId] = trust
		for _, model in CollectionService:GetTagged("Creature") do
			if model:GetAttribute("EntityId") == entityId then
				bubble(model, mood)
			end
		end
		if text then
			Toast.Show(text, mood == "Bonded" and "creature" or "info")
		end
		refresh()
	end)
	State.Changed:Connect(refresh)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not panel.Visible or not CreaturePanel.Actions then
			return
		end
		local index = ({ [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4 })[input.KeyCode]
		local action = index and CreaturePanel.Actions[index]
		if action then
			action[2]()
		end
	end)

	local timer = 0
	RunService.Heartbeat:Connect(function(dt)
		timer += dt
		if timer < 0.2 then
			return
		end
		timer = 0
		local nearest = nearestCreature()
		if nearest ~= target then
			target = nearest
			if target then
				rebuildActions(target)
				refresh()
				Theme.show(panel, true)
			else
				panel.Visible = false
			end
		end
	end)
end

return CreaturePanel
