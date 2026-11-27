--[[
	Mythical Sanctuary — Server bootstrap
	ลำดับ: Net → Environment → Terrain (หมู่บ้านก่อน) → Props → NPC → Data → Creatures → Sanctuary → Gameplay
	  • ทุกขั้นตอนห่อ pcall: ขั้นไหนพังจะพิมพ์ ❌ ใน Output แต่ผู้เล่นยังเกิดได้ (ไม่ค้างหน้าโหลด)
	  • ผู้เล่นเกิดทันทีที่หมู่บ้านพร้อม ป่าที่เหลือสร้างต่อเบื้องหลัง
	  • ความคืบหน้าส่งไปหน้าโหลดผ่าน workspace Attribute "BootProgress" / "BootStage"
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
local QuestService = require(script.Gameplay.QuestService)
local EconomyService = require(script.Gameplay.EconomyService)
local CreatureService = require(script.Creatures.CreatureService)
local CreatureCare = require(script.Creatures.CreatureCare)
local SanctuaryService = require(script.Sanctuary.SanctuaryService)

Players.CharacterAutoLoads = false
StarterPlayer.CharacterWalkSpeed = Config.NormalWalkSpeed
Net.Event("Notify") -- สร้างโฟลเดอร์ Remote ทันที

local started = os.clock()
local failures = 0

local function step(name, fn)
	workspace:SetAttribute("BootStage", name)
	local t = os.clock()
	local ok, err = pcall(fn)
	if ok then
		print(string.format("[Boot] ✔ %s (%.1f วิ)", name, os.clock() - t))
	else
		failures += 1
		warn(string.format("[Boot] ❌ %s ล้มเหลว: %s", name, tostring(err)))
	end
end

-- ===== การเกิดตัวละคร (ไม่ขึ้นกับว่าระบบอื่นจะสำเร็จหรือไม่) =====
local worldReady = false
local function spawnPlayer(player)
	if worldReady and player.Parent and not player.Character then
		player:LoadCharacter()
	end
end
local function hookPlayer(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			task.wait(3)
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end)
	spawnPlayer(player)
end
Players.PlayerAdded:Connect(hookPlayer)
for _, player in Players:GetPlayers() do
	hookPlayer(player)
end

local function setWorldReady()
	if worldReady then
		return
	end
	worldReady = true
	workspace:SetAttribute("WorldReady", true)
	print(string.format("[Boot] หมู่บ้านพร้อม — ผู้เล่นเกิดได้แล้ว (%.1f วิ)", os.clock() - started))
	for _, player in Players:GetPlayers() do
		spawnPlayer(player)
	end
end

-- จุดเกิด (คำนวณจากฟังก์ชันความสูง ไม่ต้องรอ Terrain)
local spawnPos = WorldLayout.PlayerSpawn
local spawn = Instance.new("SpawnLocation")
spawn.Name = "VillageSpawn"
spawn.Anchored = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(spawnPos.X, TerrainBuilder.HeightAt(spawnPos.X, spawnPos.Z) + 2, spawnPos.Z)
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = workspace

TerrainBuilder.SetRegistry(require(Shared.AssetRegistry)) -- ฐานรากใต้อาคาร (ต้องก่อนคำนวณความสูงใด ๆ)
spawn.Position = Vector3.new(spawnPos.X, TerrainBuilder.HeightAt(spawnPos.X, spawnPos.Z) + 2, spawnPos.Z)
step("Environment", EnvironmentService.Init)

-- Terrain สร้างในเธรดแยก: หมู่บ้านเสร็จก่อน → ระบบอื่นเริ่มต่อได้ทันที
local nearReady = false
task.spawn(function()
	local ok, err = pcall(function()
		if TerrainBuilder.BuildWorld(false, function()
			nearReady = true
		end) then
			print(string.format("[Boot] ✔ Terrain ทั้งโลกเสร็จ (%.1f วิ)", os.clock() - started))
		end
	end)
	if not ok then
		warn("[Boot] ❌ Terrain ล้มเหลว: " .. tostring(err))
		-- พื้นฉุกเฉิน: กันผู้เล่นตกโลกถ้าสร้าง Terrain ไม่ได้ (เช่นไฟล์ไม่มี Workspace.Terrain)
		local ground = Instance.new("Part")
		ground.Name = "EmergencyGround"
		ground.Anchored = true
		ground.Size = Vector3.new(2048, 4, 2048)
		ground.Position = Vector3.new(0, WorldLayout.Village.Height - 2, -350)
		ground.Material = Enum.Material.Grass
		ground.Color = Color3.fromRGB(108, 150, 72)
		ground:SetAttribute("Placeholder", true)
		ground.Parent = workspace
		workspace:SetAttribute("BootStage", "TerrainError")
		nearReady = true
	end
end)
local waitStart = os.clock()
while not nearReady and os.clock() - waitStart < 90 do
	task.wait(0.2)
end

step("Assets", function()
	local n = require(Shared.AssetLibrary).NormalizeAll()
	if n > 0 then
		print("[Boot] ปรับขนาด/Pivot โมเดลที่ลากใส่ Assets เอง " .. n .. " ชิ้น")
	end
end)
step("World props", WorldPopulator.Build)
step("NPC", NpcService.Init)
step("Data", DataService.Init)
step("Creatures", function()
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
end)
step("Creature care", CreatureCare.Init)
step("Sanctuary", SanctuaryService.Init)
step("Quests", function()
	QuestService.Init(WorldPopulator.Discoverables, NpcService.Lookup)
end)
step("Economy", function()
	EconomyService.Init(WorldPopulator, NpcService.Lookup, EnvironmentService)
end)

setWorldReady()
workspace:SetAttribute("BootStage", failures > 0 and "Error" or "Ready")
print(string.format("✦ Mythical Sanctuary %s พร้อมแล้ว (%.1f วินาที, ผิดพลาด %d ขั้น)", Config.Version, os.clock() - started, failures))
