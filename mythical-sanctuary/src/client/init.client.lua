-- Mythical Sanctuary — Client bootstrap
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local State = require(script.State)
local Theme = require(script.UI.Theme)
local Toast = require(script.UI.Toast)
local Hud = require(script.UI.Hud)
local Journal = require(script.UI.Journal)
local Windows = require(script.UI.Windows)
local CreaturePanel = require(script.UI.CreaturePanel)
local SanctuaryEditor = require(script.UI.SanctuaryEditor)
local MainMenu = require(script.UI.MainMenu)
local Interactions = require(script.Interactions)
local Atmosphere = require(script.World.Atmosphere)
local Audio = require(script.World.Audio)

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

State.Init()
Atmosphere.Init()
Audio.Init()

local hudGui = Theme.screenGui("HUD", 1)
local windowGui = Theme.screenGui("Windows", 5)
local overlay = Theme.screenGui("Overlay", 20)
Theme.new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Colors.Ivory, BackgroundTransparency = 1, Visible = false, Parent = overlay })

Toast.Init(overlay)
Hud.Init(hudGui)
CreaturePanel.Init(hudGui)
Windows.Init(windowGui)
Journal.Init(windowGui)
SanctuaryEditor.Init(hudGui)
Interactions.Init()

Hud.OnJournal = Journal.Toggle
Hud.OnEdit = SanctuaryEditor.Toggle
Windows.OpenJournal = Journal.Open
Journal.OnSettings = function(settings)
	Audio.SetVolumes(settings.Music, settings.Sfx)
	Atmosphere.SetQuality(settings.Graphics)
end

hudGui.Enabled = false
MainMenu.Show(overlay, function()
	hudGui.Enabled = true
	task.delay(1.5, function()
		Toast.Banner("หมู่บ้านมิสติก", "ผู้เฒ่ามาริเบลรอคุณอยู่ที่หอนาฬิกา")
	end)
end)

local _ = Players
