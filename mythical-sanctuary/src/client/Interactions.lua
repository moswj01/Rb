-- Interactions — กระจาย ProximityPrompt ไปยังระบบที่ถูกต้อง (ประตู, หม้อยา, สมุนไพร, NPC, รังฟักไข่)
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Items)
local Net = require(Shared.Net)

local Toast = require(script.Parent.UI.Toast)
local Windows = require(script.Parent.UI.Windows)

local Interactions = {}

local function fadeForage(prompt, seconds)
	local model = prompt:FindFirstAncestorWhichIsA("Model")
	if not model then
		return
	end
	prompt.Enabled = false
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 0.75
		end
	end
	task.delay(seconds, function()
		prompt.Enabled = true
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 0
			end
		end
	end)
end

local function portalFlash()
	local gui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Overlay")
	local flash = gui and gui:FindFirstChild("Flash")
	if flash then
		flash.BackgroundTransparency = 1
		flash.Visible = true
		TweenService:Create(flash, TweenInfo.new(0.35), { BackgroundTransparency = 0 }):Play()
		task.wait(0.4)
		return function()
			TweenService:Create(flash, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
		end
	end
	return function() end
end

function Interactions.Init()
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local portal = prompt:GetAttribute("Portal")
		local forage = prompt:GetAttribute("Forage")
		local npc = prompt:GetAttribute("Npc")
		local incubator = prompt:GetAttribute("Incubator")
		if portal then
			local finish = portalFlash()
			local ok, message = Net.Invoke("TravelSanctuary", portal == "Enter")
			finish()
			if not ok and message then
				Toast.Show(message, "warn")
			end
		elseif prompt:GetAttribute("Station") == "Cauldron" then
			Windows.OpenCrafting()
		elseif forage then
			local ok, result = Net.Invoke("Forage", forage)
			if ok and type(result) == "table" then
				Toast.Show(string.format("เก็บ %s ×%d", Items.ById[result.Item].ThaiName, result.Amount), "creature")
				fadeForage(prompt, result.Respawn)
			elseif result then
				Toast.Show(result, "warn")
			end
		elseif npc then
			Windows.Talk(npc)
		elseif incubator then
			local ok, message = Net.Invoke("UseIncubator", incubator)
			if message then
				Toast.Show(message, ok and "creature" or "info")
			end
		end
	end)
end

return Interactions
