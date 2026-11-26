--[[
	Hud — HUD ขนาดเล็ก ไม่บังวิว
	  ซ้ายบน: ชื่อโซน + เวลา/อากาศ      ขวาบน: Lumen + เลเวล
	  ซ้ายล่าง: ภารกิจที่ติดตาม           ขวาล่าง: ปุ่มสมุด / ย่อตัว / จัดวาง (สำหรับมือถือด้วย)
	  ป้าย ProximityPrompt แบบ custom (วงทอง + ปุ่ม) แทนของมาตรฐาน Roblox
	  แบนเนอร์ชื่อโซนแบบ cinematic เมื่อเดินเข้าเขตใหม่ / ค้นพบสถานที่
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Quests)
local Species = require(Shared.Species)
local WorldLayout = require(Shared.WorldLayout)
local Config = require(Shared.Config)
local Net = require(Shared.Net)

local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local Hud = {}

local Colors = Theme.Colors
local player = Players.LocalPlayer
local zoneLabel, timeLabel, coinLabel, levelLabel, questTitle, questObjective, editButton, sneakButton
Hud.Sneaking = false
Hud.OnJournal = nil
Hud.OnEdit = nil

local WEATHER = { Clear = "ท้องฟ้าแจ่มใส", Mist = "หมอกลง", Drizzle = "ฝนปรอย", Rain = "ฝนตก" }

local function zoneName(id)
	if id == "Sanctuary" then
		return "เขตอนุรักษ์ของคุณ"
	end
	for _, zone in WorldLayout.Zones do
		if zone.Id == id then
			return zone.ThaiName
		end
	end
	return ""
end

local function updateQuest(profile)
	local questId = profile.Quests.Tracked
	local quest = questId and Quests.ById[questId]
	if not quest then
		questTitle.Text = "ไม่มีภารกิจที่ติดตาม"
		questObjective.Text = ""
		return
	end
	questTitle.Text = quest.Title
	local progress = profile.Quests.Active[questId] or {}
	local lines = {}
	for index, objective in quest.Objectives do
		local value = progress[tostring(index)] or 0
		if value < objective.Count then
			table.insert(lines, string.format("◇ %s  <font color='#C9A55A'>%d/%d</font>", objective.Text, value, objective.Count))
		else
			table.insert(lines, string.format("<font color='#8FBF98'>✔ %s</font>", objective.Text))
		end
	end
	questObjective.Text = table.concat(lines, "\n")
end

function Hud.SetSneaking(on)
	Hud.Sneaking = on
	Net.Event("SetSneaking"):FireServer(on)
	sneakButton.Text = on and "ย่อตัวอยู่" or "ย่อตัว (C)"
	sneakButton.BackgroundColor3 = on and Colors.Forest or Colors.MidnightSoft
end

-- ===== Custom ProximityPrompt =====
local function promptUi(prompt, inputType, gui)
	local billboard = Theme.new("BillboardGui", { Size = UDim2.fromOffset(220, 54), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true, LightInfluence = 0, Adornee = prompt.Parent, Parent = gui })
	local frame = Theme.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Colors.MidnightDeep, BackgroundTransparency = 0.12, Parent = billboard }, { Theme.corner(6), Theme.stroke(Colors.Gold, 1.2) })
	local keyText = inputType == Enum.ProximityPromptInputType.Touch and "แตะ" or (inputType == Enum.ProximityPromptInputType.Gamepad and "X" or prompt.KeyboardKeyCode.Name)
	local key = Theme.new("TextButton", { Size = UDim2.fromOffset(38, 38), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Colors.Forest, Text = keyText, Font = Theme.Fonts.BodyBold, TextSize = 16, TextColor3 = Colors.Ivory, Parent = frame }, {
		Theme.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Theme.stroke(Colors.GoldBright, 1.5),
	})
	key.Activated:Connect(function()
		prompt:InputHoldBegin()
		task.wait()
		prompt:InputHoldEnd()
	end)
	Theme.title({ Text = prompt.ActionText, Size = UDim2.new(1, -60, 0, 24), Position = UDim2.fromOffset(54, 4), TextSize = 19, Parent = frame })
	Theme.text({ Text = prompt.ObjectText, Size = UDim2.new(1, -60, 0, 18), Position = UDim2.fromOffset(54, 28), TextSize = 14, TextColor3 = Colors.IvoryDim, Parent = frame })
	return billboard
end

function Hud.Init(gui)
	-- ซ้ายบน
	local topLeft = Theme.new("Frame", { Position = UDim2.fromOffset(24, 64), Size = UDim2.fromOffset(340, 64), BackgroundTransparency = 1, Parent = gui })
	Theme.scale(topLeft, 1100, 700)
	zoneLabel = Theme.title({ Size = UDim2.new(1, 0, 0, 30), TextSize = 26, Parent = topLeft })
	Theme.new("UIStroke", { Color = Colors.MidnightDeep, Thickness = 1.5, Transparency = 0.4, Parent = zoneLabel })
	timeLabel = Theme.text({ Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 32), TextSize = 15, TextColor3 = Colors.Ivory, Parent = topLeft })
	Theme.new("UIStroke", { Color = Colors.MidnightDeep, Thickness = 1, Transparency = 0.5, Parent = timeLabel })

	-- ขวาบน
	local topRight = Theme.panel({ Size = UDim2.fromOffset(200, 56), Position = UDim2.new(1, -24, 0, 20), AnchorPoint = Vector2.new(1, 0), Transparency = 0.25, Ornaments = false, Parent = gui })
	Theme.scale(topRight, 1100, 700)
	coinLabel = Theme.title({ Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(14, 6), TextSize = 21, Parent = topRight })
	levelLabel = Theme.text({ Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(14, 30), TextSize = 14, TextColor3 = Colors.IvoryDim, Parent = topRight })

	-- ซ้ายล่าง: ภารกิจ
	local quest = Theme.new("Frame", { Position = UDim2.new(0, 24, 1, -24), AnchorPoint = Vector2.new(0, 1), Size = UDim2.fromOffset(380, 110), BackgroundTransparency = 1, Parent = gui })
	Theme.scale(quest, 1100, 700)
	questTitle = Theme.title({ Size = UDim2.new(1, 0, 0, 24), TextSize = 20, Parent = quest })
	Theme.new("UIStroke", { Color = Colors.MidnightDeep, Thickness = 1.5, Transparency = 0.4, Parent = questTitle })
	questObjective = Theme.text({ Size = UDim2.new(1, 0, 0, 80), Position = UDim2.fromOffset(0, 26), TextSize = 15, TextYAlignment = Enum.TextYAlignment.Top, Parent = quest })
	Theme.new("UIStroke", { Color = Colors.MidnightDeep, Thickness = 1, Transparency = 0.45, Parent = questObjective })

	-- ขวาล่าง: ปุ่ม
	local buttons = Theme.new("Frame", { Position = UDim2.new(1, -24, 1, -24), AnchorPoint = Vector2.new(1, 1), Size = UDim2.fromOffset(160, 140), BackgroundTransparency = 1, Parent = gui }, {
		Theme.new("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Theme.scale(buttons, 1100, 700)
	editButton = Theme.button({ Text = "จัดวาง (B)", Size = UDim2.fromOffset(150, 38), LayoutOrder = 1, Style = "Secondary", Visible = false, Parent = buttons }, function()
		if Hud.OnEdit then
			Hud.OnEdit()
		end
	end)
	sneakButton = Theme.button({ Text = "ย่อตัว (C)", Size = UDim2.fromOffset(150, 38), LayoutOrder = 2, Style = "Secondary", Parent = buttons }, function()
		Hud.SetSneaking(not Hud.Sneaking)
	end)
	Theme.button({ Text = "สมุดบันทึก (J)", Size = UDim2.fromOffset(150, 40), LayoutOrder = 3, Parent = buttons }, function()
		if Hud.OnJournal then
			Hud.OnJournal()
		end
	end)

	-- state
	State.Changed:Connect(function(profile)
		coinLabel.Text = string.format("✧ %s Lumen", tostring(profile.Coins))
		levelLabel.Text = string.format("ผู้พิทักษ์ระดับ %d · %d/%d XP", profile.Level, profile.XP, Config.LevelXP(profile.Level))
		updateQuest(profile)
	end)
	State.ZoneChanged:Connect(function(zone)
		zoneLabel.Text = zoneName(zone)
		editButton.Visible = zone == "Sanctuary"
		Toast.Banner(zoneName(zone), zone == "Sanctuary" and "บ้านของสัตว์ที่ไว้ใจคุณ" or nil)
	end)
	zoneLabel.Text = zoneName(State.Zone)

	task.spawn(function()
		while true do
			local t = Lighting.ClockTime
			local h = math.floor(t)
			local m = math.floor((t - h) * 60)
			timeLabel.Text = string.format("%02d:%02d · %s", h, m, WEATHER[State.World.Weather] or "")
			task.wait(1)
		end
	end)

	Net.Event("Notify").OnClientEvent:Connect(Toast.Show)
	Net.Event("Discovery").OnClientEvent:Connect(function(kind, id, name)
		if kind == "Species" then
			local def = Species.ById[id]
			Toast.Banner("✦ พบสัตว์ใหม่ ✦", def.ThaiName .. " — บันทึกลงสมุดภาพสัตว์แล้ว")
		else
			Toast.Banner("✦ " .. tostring(name) .. " ✦", "ค้นพบสถานที่ใหม่")
		end
	end)

	-- prompts
	local shown = {}
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			shown[prompt] = promptUi(prompt, inputType, gui)
		end
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		if shown[prompt] then
			shown[prompt]:Destroy()
			shown[prompt] = nil
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.C then
			Hud.SetSneaking(not Hud.Sneaking)
		elseif input.KeyCode == Enum.KeyCode.J and Hud.OnJournal then
			Hud.OnJournal()
		elseif input.KeyCode == Enum.KeyCode.B and State.Zone == "Sanctuary" and Hud.OnEdit then
			Hud.OnEdit()
		elseif input.KeyCode == Enum.KeyCode.LeftShift and not Hud.Sneaking then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.RunSpeed
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift and not Hud.Sneaking then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.NormalWalkSpeed
			end
		end
	end)
	player.CharacterAdded:Connect(function()
		Hud.Sneaking = false
		Hud.SetSneaking(false)
	end)
end

return Hud
