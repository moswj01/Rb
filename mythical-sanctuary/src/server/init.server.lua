--[[
	Mythical Sanctuary — Server bootstrap
	ลำดับ: Net → Environment → Terrain → Props → NPC → Data → Creatures → Sanctuary → Gameplay
	ผู้เล่นจะเกิดหลังโลกพร้อมแล้วเท่านั้น (กันตกโลกตอนเซิร์ฟเพิ่งเปิด)
]]

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Config = require(Shared.Config)
local WorldLayout = require(Shared.WorldLayout)

local World = script.World
local EnvironmentService = require(World.EnvironmentService)
local TerrainBuilder = require(World.TerrainBuilder)
local WorldPopulator = require(World.WorldPopulator)
local NpcService = require(World.NpcService)
local DataService = require(script.Data.DataService)
local Inventory = require(script.Gameplay.Inventory)
local QuestService = require(script.Gameplay.QuestService)
local EconomyService = require(script.Gameplay.EconomyService)
local CreatureService = require(script.Creatures.CreatureService)
local CreatureCare = require(script.Creatures.CreatureCare)
local SanctuaryService = require(script.Sanctuary.SanctuaryService)

Players.CharacterAutoLoads = false
StarterPlayer.CharacterWalkSpeed = Config.NormalWalkSpeed
Net.Event("Notify") -- สร้างโฟลเดอร์ Remote ทันที

local started = os.clock()
EnvironmentService.Init()
if TerrainBuilder.BuildWorld(false) then
	print(string.format("[Boot] ปั้นภูมิประเทศเสร็จใน %.1f วินาที", os.clock() - started))
end
WorldPopulator.Build()
NpcService.Init()

-- จุดเกิด
local spawnPos = WorldLayout.PlayerSpawn
local spawn = Instance.new("SpawnLocation")
spawn.Name = "VillageSpawn"
spawn.Anchored = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(spawnPos.X, TerrainBuilder.HeightAt(spawnPos.X, spawnPos.Z) + 1, spawnPos.Z)
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = workspace

-- ระบบเกม
DataService.Init()
CreatureService.Environment = EnvironmentService
CreatureService.OnDiscover = QuestService.Discover
CreatureService.Init()
CreatureService.InitWild(WorldLayout.SpawnAreas, {
	WaterNear = function(center)
		local best, bestD
		for _, point in WorldLayout.River.Points do
			local d = (point.Pos - center).Magnitude
			if d < 200 and (not bestD or d < bestD) then
				best, bestD = point.Pos, d
			end
		end
		return best and (best + Vector3.new(WorldLayout.River.Width * 0.6, 0, 0)) or nil
	end,
})
CreatureCare.Init()
SanctuaryService.Init()
QuestService.Init(WorldPopulator.Discoverables, NpcService.Lookup)
EconomyService.Init(WorldPopulator, NpcService.Lookup, EnvironmentService)

-- เกิดตัวละครหลังข้อมูลโหลดเสร็จ + เกิดใหม่เมื่อหมดแรง (ไม่มีการตายในเกม แต่กันตกน้ำ/ตกหน้าผา)
DataService.OnLoaded(function(player)
	player:LoadCharacter()
end)
local function hookRespawn(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			task.wait(3)
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end)
end
Players.PlayerAdded:Connect(hookRespawn)
for _, player in Players:GetPlayers() do
	hookRespawn(player)
end

local _ = Inventory
print(string.format("✦ Mythical Sanctuary %s พร้อมแล้ว (%.1f วินาที)", Config.Version, os.clock() - started))
