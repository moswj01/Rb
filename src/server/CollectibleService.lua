--[[
	CollectibleService — ดาวลอยบนเกาะ เดินชนแล้วได้เหรียญ (หาเงินฟรีแบบชิล ๆ สำหรับเด็กเล็ก)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local ProgressService = require(script.Parent.ProgressService)

local CollectibleService = {}

local rng = Random.new()
local folder
local rayParams

local function randomPosition()
	for _ = 1, 10 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(12, Config.LobbyRadius)
		local origin = Vector3.new(math.cos(angle) * radius, 50, math.sin(angle) * radius)
		local result = workspace:Raycast(origin, Vector3.new(0, -100, 0), rayParams)
		local underStage = math.abs(origin.X) < 16 and origin.Z > 38 and origin.Z < 102
		if result and not underStage then
			return result.Position + Vector3.new(0, 2.5, 0)
		end
	end
	return Vector3.new(rng:NextNumber(-30, 30), 2.5, rng:NextNumber(-30, 30))
end

local spawnStar

local function onTouched(star, hit)
	if star:GetAttribute("Taken") then
		return
	end
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local data = DataService.Get(player)
	if not humanoid or humanoid.Health <= 0 or not data then
		return
	end

	star:SetAttribute("Taken", true)
	local gained = DataService.AddCoins(player, star:GetAttribute("Value") or Config.StarValue)
	local big = star:GetAttribute("Big") == true
	data.Stats.Stars += 1
	ProgressService.AddXP(player, big and Config.XP.BigStar or Config.XP.Star)
	if data.Stats.Stars % 50 == 0 then
		ProgressService.CheckAchievements(player)
	end
	DataService.Push(player)
	ProgressService.Tutorial(player, "Star", 1)
	Remotes.CoinPopup:FireClient(player, gained, star.Position, star:GetAttribute("Big") == true)
	star:Destroy()
	task.delay(Config.StarRespawnTime, spawnStar)
end

function spawnStar()
	local big = rng:NextNumber() < Config.BigStarChance
	local star = Instance.new("Part")
	star.Name = big and "BigStar" or "Star"
	star.Shape = Enum.PartType.Ball
	star.Size = Vector3.one * (big and 3.5 or 2)
	star.Anchored = true
	star.CanCollide = false
	star.CanQuery = false
	star.Material = Enum.Material.Neon
	star.Color = big and Color3.fromRGB(255, 120, 220) or Color3.fromRGB(255, 215, 50)
	star.Position = randomPosition()
	star:SetAttribute("Value", big and Config.BigStarValue or Config.StarValue)
	star:SetAttribute("Big", big)

	local light = Instance.new("PointLight")
	light.Color = star.Color
	light.Range = big and 14 or 8
	light.Parent = star

	if big then
		local sparkles = Instance.new("Sparkles")
		sparkles.Parent = star
		CollectionService:AddTag(star, "Rainbow")
	end
	CollectionService:AddTag(star, "Bob")

	star.Touched:Connect(function(hit)
		onTouched(star, hit)
	end)
	star.Parent = folder
end

function CollectibleService.Init(map)
	folder = Instance.new("Folder")
	folder.Name = "Stars"
	folder.Parent = workspace

	rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { map.Ground }

	for _ = 1, Config.StarCount do
		spawnStar()
	end
end

return CollectibleService
