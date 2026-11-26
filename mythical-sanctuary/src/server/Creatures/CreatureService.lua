--[[
	CreatureService — ตัวตนของสัตว์ + AI (State Machine)

	States: Idle → Wander → Forage → Drink → Sleep → Play → Flee → Approach → Follow → Shelter → React
	  • บุคลิก (Playful/Shy/Curious/Solitary) ปรับระยะหนี, โอกาสเข้าหา, โอกาสเล่น
	  • ช่วงเวลา: สัตว์กลางคืนหลับตอนกลางวัน, ตุ่นหลับตอนกลางคืน
	  • สภาพอากาศ: ฝนตก → หาที่หลบใต้ต้นไม้
	  • ผู้เล่นวิ่งเข้าใกล้ = ตกใจหนี, ย่อตัวเดินช้า ๆ = ยอมให้เข้าใกล้
	  • ความไว้วางใจสูง → เดินเข้าหาผู้เล่นเอง

	Performance: AI LOD ตามระยะผู้เล่นใกล้สุด
	  ≤ NearDistance  : คิดทุก 0.25 วิ
	  ≤ FarDistance   : คิดทุก 2 วิ
	  > FarDistance   : หลับลึก (หยุดประมวลผล, หยุดเคลื่อนที่)
	  ระยะไกล (> PathfindingMinDistance) ใช้ PathfindingService, ใกล้ใช้ MoveTo ตรง ๆ
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Species = require(Shared.Species)
local Net = require(Shared.Net)
local CreatureFactory = require(script.Parent.CreatureFactory)

local CreatureService = {}

CreatureService.Entities = {} -- [entityId] = entity
CreatureService.Environment = nil -- EnvironmentService (inject)
CreatureService.OnDiscover = nil -- function(player, speciesId)

local AI = Config.AI
local rng = Random.new()
local folder
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

-- ===== utilities =====

local function groundAt(pos)
	rayParams.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(pos + Vector3.new(0, 120, 0), Vector3.new(0, -260, 0), rayParams)
	if hit and hit.Material ~= Enum.Material.Water then
		return hit.Position
	end
	return nil
end

local function randomPointNear(center, radius)
	for _ = 1, 8 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * radius
		local p = groundAt(center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
		if p then
			return p
		end
	end
	return nil
end

local function isActiveTime(def)
	local env = CreatureService.Environment
	if not env or def.ActiveTime == "Any" then
		return true
	end
	local period = env.Period()
	if def.ActiveTime == "Night" then
		return period == "Night" or period == "Dusk"
	elseif def.ActiveTime == "Dusk" then
		return period ~= "Day" or rng:NextNumber() < 0.35
	end
	return period == "Day" or period == "Dawn"
end

local function playerSpeed(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return 0
	end
	local v = root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude
end

-- ===== animation =====
local function playAnimation(entity, name)
	if entity.AnimName == name then
		return
	end
	entity.AnimName = name
	entity.Model:SetAttribute("Anim", name) -- client ใช้ทำ procedural motion สำหรับ greybox / emote bubble
	local animator = entity.Humanoid and entity.Humanoid:FindFirstChildOfClass("Animator")
	local anims = entity.Model:FindFirstChild("Animations")
	if not animator or not anims then
		return
	end
	if entity.Track then
		entity.Track:Stop(0.25)
	end
	local anim = anims:FindFirstChild(name) or anims:FindFirstChild("Idle")
	if anim then
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok then
			entity.Track = track
			track:Play(0.25)
		end
	end
end

-- ===== movement =====
local function stopMoving(entity)
	entity.PathToken = nil
	if entity.Humanoid and entity.Root.Parent then
		entity.Humanoid:MoveTo(entity.Root.Position)
	end
end

local function moveTo(entity, target, run)
	local humanoid = entity.Humanoid
	if not humanoid then
		return
	end
	local def = entity.Def
	local stageMult = entity.Stage == "Baby" and 0.6 or (entity.Stage == "Juvenile" and 0.85 or 1)
	humanoid.WalkSpeed = (run and def.Speed.Run or def.Speed.Walk) * stageMult
	entity.MoveTarget = target
	local distance = (target - entity.Root.Position).Magnitude
	if distance < AI.PathfindingMinDistance then
		entity.PathToken = nil
		humanoid:MoveTo(target)
		return
	end
	local token = {}
	entity.PathToken = token
	task.spawn(function()
		local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 4, AgentCanJump = true, WaypointSpacing = 10 })
		local ok = pcall(function()
			path:ComputeAsync(entity.Root.Position, target)
		end)
		if entity.PathToken ~= token then
			return
		end
		if not ok or path.Status ~= Enum.PathStatus.Success then
			humanoid:MoveTo(target)
			return
		end
		for _, waypoint in path:GetWaypoints() do
			if entity.PathToken ~= token or not entity.Root.Parent then
				return
			end
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end
			humanoid:MoveTo(waypoint.Position)
			local reached = humanoid.MoveToFinished:Wait()
			if not reached then
				humanoid:MoveTo(target)
				return
			end
		end
	end)
end

local function setState(entity, state, duration)
	entity.State = state
	entity.StateUntil = os.clock() + (duration or 5)
	entity.Model:SetAttribute("State", state)
end

-- ===== decision making =====
local function nearestPlayer(entity)
	local best, bestDistance = nil, math.huge
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local d = (root.Position - entity.Root.Position).Magnitude
			if d < bestDistance then
				best, bestDistance = player, d
			end
		end
	end
	return best, bestDistance
end

function CreatureService.TrustOf(entity, player)
	if entity.Owner then
		return entity.Owner == player and 100 or 50
	end
	return entity.Trust[player.UserId] or 0
end

local function chooseIdleBehaviour(entity)
	local personality = Species.Personalities[entity.Personality]
	local roll = rng:NextNumber()
	local env = CreatureService.Environment
	local needs = entity.Needs

	if env and (env.Weather == "Rain") and entity.Shelter then
		setState(entity, "Shelter", 20)
		moveTo(entity, entity.Shelter, true)
		return
	end
	if needs and needs.Energy < 25 then
		setState(entity, "Sleep", 40)
		stopMoving(entity)
		return
	end
	if needs and needs.Hunger < 35 and entity.FoodSpot then
		setState(entity, "Forage", 12)
		moveTo(entity, entity.FoodSpot)
		return
	end
	if entity.WaterSpot and roll < 0.12 then
		setState(entity, "Drink", 10)
		moveTo(entity, entity.WaterSpot)
		return
	end
	-- เล่นกับสัตว์ตัวอื่นที่อยู่ใกล้
	if roll < personality.PlayChance then
		for _, other in CreatureService.Entities do
			if other ~= entity and other.Root.Parent and (other.Root.Position - entity.Root.Position).Magnitude < 30 and other.State ~= "Sleep" then
				setState(entity, "Play", 6)
				entity.PlayWith = other
				moveTo(entity, other.Root.Position, true)
				return
			end
		end
	end
	if roll < 0.55 then
		local target = randomPointNear(entity.Home, entity.Radius)
		if target then
			setState(entity, "Wander", 10)
			moveTo(entity, target)
			return
		end
	end
	if roll < 0.75 then
		setState(entity, "Forage", rng:NextNumber(4, 7)) -- ดมพื้น / ขุด / เล็มหญ้า
		stopMoving(entity)
		return
	end
	setState(entity, "Idle", rng:NextNumber(3, 7))
	stopMoving(entity)
end

local function think(entity)
	local now = os.clock()
	local def = entity.Def
	local personality = Species.Personalities[entity.Personality]
	local player, distance = nearestPlayer(entity)

	-- ช่วงเวลาไม่ใช่เวลาออกหากิน → นอน
	if entity.Wild and not isActiveTime(def) and entity.State ~= "Flee" then
		if entity.State ~= "Sleep" then
			setState(entity, "Sleep", 30)
			stopMoving(entity)
		end
		playAnimation(entity, "Sleep")
		return
	end

	-- ตอบสนองต่อผู้เล่น
	if player and distance < 60 then
		local trust = CreatureService.TrustOf(entity, player)
		local calm = entity.CalmUntil and entity.CalmUntil > now
		local fleeRadius = def.FleeDistance * personality.FleeMult * (entity.Injured and 0.4 or 1)
		local startled = playerSpeed(player) > Config.NormalWalkSpeed + 1 or not player:GetAttribute("Sneaking")
		if entity.Wild and not calm and trust < 60 and distance < fleeRadius and startled and not entity.Injured then
			local root = player.Character.HumanoidRootPart
			local away = (entity.Root.Position - root.Position) * Vector3.new(1, 0, 1)
			away = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
			local target = groundAt(entity.Root.Position + away * 40)
			if target then
				if entity.State ~= "Flee" then
					Net.Event("CreatureFeedback"):FireClient(player, entity.Id, "Scared", trust)
				end
				setState(entity, "Flee", 4)
				moveTo(entity, target, true)
				playAnimation(entity, "Run")
				return
			end
		end
		-- ไว้ใจมากพอ หรือขี้สงสัย → เดินเข้าหา
		local approachChance = personality.ApproachChance + trust / 140
		if entity.Wild and trust >= 40 and distance > 7 and distance < 35 and entity.State ~= "Approach" and rng:NextNumber() < approachChance * 0.25 then
			setState(entity, "Approach", 5)
			moveTo(entity, player.Character.HumanoidRootPart.Position)
		end
		if CreatureService.OnDiscover and distance < 45 and entity.Wild then
			CreatureService.OnDiscover(player, entity.Species)
		end
	end

	-- ติดตามเจ้าของ
	if entity.Following and entity.Owner then
		local root = entity.Owner.Character and entity.Owner.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local d = (root.Position - entity.Root.Position).Magnitude
			if d > 9 then
				setState(entity, "Follow", 1)
				moveTo(entity, root.Position - root.CFrame.LookVector * 5, d > 25)
			else
				setState(entity, "Idle", 1)
			end
		end
	end

	if now >= entity.StateUntil and not entity.Injured then
		chooseIdleBehaviour(entity)
	end

	-- animation ตาม state + ความเร็วจริง
	local speed = entity.Root.AssemblyLinearVelocity.Magnitude
	local anim = "Idle"
	if entity.State == "Sleep" then
		anim = "Sleep"
	elseif entity.State == "Play" and speed < 2 then
		anim = "Play"
	elseif entity.State == "Forage" and speed < 2 then
		anim = "Eat"
	elseif entity.State == "Drink" and speed < 2 then
		anim = "Drink"
	elseif speed > 14 then
		anim = "Run"
	elseif speed > 1 then
		anim = "Walk"
	end
	if entity.Injured then
		anim = "Sleep" -- นอนขดตัวรอความช่วยเหลือ
	end
	if entity.ReactUntil and entity.ReactUntil > now then
		anim = entity.ReactAnim
	end
	playAnimation(entity, anim)
end

-- ===== spawn / despawn =====

function CreatureService.Spawn(options)
	local def = Species.ById[options.Species]
	assert(def, "unknown species " .. tostring(options.Species))
	local stage = options.Stage or "Adult"
	local model = CreatureFactory.Create(def.Id, stage)
	local id = options.Id or HttpService:GenerateGUID(false)
	local position = groundAt(options.Position) or options.Position
	model:PivotTo(CFrame.new(position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	model:SetAttribute("EntityId", id)
	model:SetAttribute("Wild", options.Owner == nil)
	model:SetAttribute("Personality", options.Personality)
	model:SetAttribute("DisplayName", options.Name or def.ThaiName)
	model:SetAttribute("Injured", options.Injured == true)
	if options.Owner then
		model:SetAttribute("OwnerId", options.Owner.UserId)
	end
	model.Parent = options.Parent or folder

	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	local entity = {
		Id = id,
		Species = def.Id,
		Def = def,
		Stage = stage,
		Personality = options.Personality or def.Personalities[rng:NextInteger(1, #def.Personalities)],
		Model = model,
		Root = root,
		Humanoid = model:FindFirstChildOfClass("Humanoid"),
		Home = options.Home or position,
		Radius = options.Radius or def.WanderRadius,
		Wild = options.Owner == nil,
		Owner = options.Owner,
		Trust = {},
		Injured = options.Injured == true,
		Needs = options.Needs, -- ตารางเดียวกับใน DataService (สัตว์ที่มีเจ้าของ)
		FoodSpot = options.FoodSpot,
		WaterSpot = options.WaterSpot,
		Shelter = options.Shelter,
		QuestFor = options.QuestFor,
		SpawnArea = options.SpawnArea,
		State = "Idle",
		StateUntil = 0,
		NextThink = 0,
	}
	model:SetAttribute("Personality", entity.Personality)
	if stage == "Egg" then
		root.Anchored = true
		entity.Humanoid = nil
	else
		pcall(function()
			root:SetNetworkOwner(nil) -- AI ฝั่งเซิร์ฟเวอร์
		end)
	end
	if entity.Injured then
		setState(entity, "Idle", 9999)
		model:SetAttribute("State", "Injured")
	end
	CreatureService.Entities[id] = entity
	return entity
end

function CreatureService.Despawn(id)
	local entity = CreatureService.Entities[id]
	if entity then
		entity.PathToken = nil
		entity.Model:Destroy()
		CreatureService.Entities[id] = nil
	end
end

function CreatureService.React(entity, animName, seconds)
	entity.ReactAnim = animName
	entity.ReactUntil = os.clock() + (seconds or 2)
	playAnimation(entity, animName)
end

function CreatureService.Find(id)
	return CreatureService.Entities[id]
end

-- ===== wild population =====
local function spawnWild(area)
	local def = Species.ById[area.Species]
	if not def or def.Phase > 1 then
		return
	end
	local position = randomPointNear(area.Center, area.Radius)
	if not position then
		return
	end
	CreatureService.Spawn({
		Species = area.Species,
		Stage = rng:NextNumber() < 0.25 and "Juvenile" or "Adult",
		Position = position,
		Home = area.Center,
		Radius = area.Radius,
		SpawnArea = area,
		WaterSpot = area.WaterSpot,
		Shelter = area.Shelter,
	})
end

function CreatureService.InitWild(spawnAreas, extras)
	for _, area in spawnAreas do
		area.WaterSpot = extras.WaterNear and extras.WaterNear(area.Center) or nil
		area.Shelter = area.Center + Vector3.new(8, 0, 8)
	end
	task.spawn(function()
		while true do
			for _, area in spawnAreas do
				local count = 0
				for _, entity in CreatureService.Entities do
					if entity.SpawnArea == area then
						count += 1
					end
				end
				if count < AI.MaxWildPerSpawnArea then
					spawnWild(area)
				end
			end
			task.wait(AI.RespawnSeconds / AI.MaxWildPerSpawnArea)
		end
	end)
end

function CreatureService.Init()
	folder = Instance.new("Folder")
	folder.Name = "Creatures"
	folder.Parent = workspace

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for id, entity in CreatureService.Entities do
			if not entity.Root or not entity.Root.Parent then
				CreatureService.Entities[id] = nil
			elseif now >= entity.NextThink and entity.Humanoid then
				local _, distance = nearestPlayer(entity)
				if distance > AI.FarDistance then
					if entity.State ~= "Dormant" then
						setState(entity, "Dormant", 0)
						stopMoving(entity)
					end
					entity.NextThink = now + 3
				else
					entity.NextThink = now + (distance <= AI.NearDistance and AI.NearTick or AI.FarTick)
					local ok, err = pcall(think, entity)
					if not ok then
						warn("[CreatureAI]", entity.Species, err)
						entity.NextThink = now + 5
					end
				end
			end
		end
	end)
end

return CreatureService
