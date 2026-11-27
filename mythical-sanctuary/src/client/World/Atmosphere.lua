--[[
	Atmosphere — แสง/บรรยากาศฝั่ง client
	  • ตรวจโซนที่ผู้เล่นอยู่ → blend Lighting profile ของโซน (นุ่ม ๆ ไม่กระชาก)
	  • กลางวัน ↔ กลางคืน ↔ พลบค่ำ (โทนอุ่น) ตาม ClockTime
	  • อากาศ: Mist (หมอกหนา), Drizzle/Rain (ฝนรอบกล้อง + ท้องฟ้าหม่น)
	  • อนุภาคสิ่งแวดล้อมรอบกล้อง: หมอกพื้นดิน, หิ่งห้อย (กลางคืน), ละอองเวท, เกสร
	  • ไฟกลางคืน: เปิดเฉพาะดวงที่อยู่ใกล้ (จำกัดจำนวนตามระดับกราฟิก)
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldLayout = require(Shared.WorldLayout)
local LightingProfiles = require(Shared.LightingProfiles)

local State = require(script.Parent.Parent.State)

local Atmosphere = {}

local player = Players.LocalPlayer
local current -- profile ที่แสดงอยู่ (ค่อย ๆ ไล่เข้าหา target)
local effects = {}
local particleRig
local emitters = {}
Atmosphere.Quality = "High" -- Low | Medium | High

local QUALITY = {
	Low = { Lights = 6, ParticleScale = 0.3, Rain = 60 },
	Medium = { Lights = 14, ParticleScale = 0.65, Rain = 160 },
	High = { Lights = 28, ParticleScale = 1, Rain = 320 },
}

local function zoneAt(position)
	local origin = player:GetAttribute("SanctuaryOrigin")
	if origin and (position - origin).Magnitude < 300 then
		return "Sanctuary"
	end
	local best, bestPriority = "WhisperingForest", -1
	for _, zone in WorldLayout.Zones do
		local d = ((position - zone.Center) * Vector3.new(1, 0, 1)).Magnitude
		if d <= zone.Radius and zone.Priority > bestPriority then
			best, bestPriority = zone.Id, zone.Priority
		end
	end
	return best
end

local function emitter(name, props)
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	for k, v in props do
		e[k] = v
	end
	e.Parent = particleRig
	emitters[name] = { Emitter = e, BaseRate = props.Rate }
	return e
end

local function buildParticles()
	particleRig = Instance.new("Part")
	particleRig.Name = "AtmosphereRig"
	particleRig.Anchored = true
	particleRig.CanCollide = false
	particleRig.CanQuery = false
	particleRig.CanTouch = false
	particleRig.Transparency = 1
	particleRig.Size = Vector3.new(90, 1, 90)
	particleRig.Parent = workspace.CurrentCamera

	emitter("GroundMist", {
		Rate = 6,
		Lifetime = NumberRange.new(8, 12),
		Speed = NumberRange.new(0.4, 1.2),
		SpreadAngle = Vector2.new(180, 10),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 22) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.86), NumberSequenceKeypoint.new(1, 1) }),
		Color = ColorSequence.new(Color3.fromRGB(220, 232, 230)),
		LightInfluence = 1,
		Orientation = Enum.ParticleOrientation.FacingCamera,
	})
	emitter("Fireflies", {
		Rate = 10,
		Lifetime = NumberRange.new(4, 7),
		Speed = NumberRange.new(0.3, 1),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 0.3, 0),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(0.8, 0.2), NumberSequenceKeypoint.new(1, 0) }),
		Color = ColorSequence.new(Color3.fromRGB(230, 255, 150)),
		LightEmission = 1,
		LightInfluence = 0,
	})
	emitter("MagicMotes", {
		Rate = 5,
		Lifetime = NumberRange.new(5, 8),
		Speed = NumberRange.new(0.2, 0.6),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 0.6, 0),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 0) }),
		Color = ColorSequence.new(Color3.fromRGB(170, 210, 255), Color3.fromRGB(220, 180, 255)),
		LightEmission = 1,
		LightInfluence = 0,
	})
	emitter("Pollen", {
		Rate = 4,
		Lifetime = NumberRange.new(6, 9),
		Speed = NumberRange.new(0.3, 0.8),
		SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new(0.12),
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 200)),
		LightEmission = 0.5,
		LightInfluence = 1,
	})
	emitter("Rain", {
		Rate = 0,
		Lifetime = NumberRange.new(0.8, 1),
		Speed = NumberRange.new(70, 80),
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(4, 4),
		Size = NumberSequence.new(0.1),
		Squash = NumberSequence.new(-3),
		Color = ColorSequence.new(Color3.fromRGB(200, 215, 230)),
		Transparency = NumberSequence.new(0.5),
		LightInfluence = 1,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
	})
end

local function ensureEffects()
	effects.Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
	effects.Color = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
	effects.Bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	effects.SunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
end

local function targetProfile()
	local profile = LightingProfiles.Resolve(State.Zone, Lighting.ClockTime)
	-- พลบค่ำ: อุ่นขึ้น
	local dusk = LightingProfiles.DuskWeight(Lighting.ClockTime)
	if dusk > 0 then
		profile.Tint = profile.Tint:Lerp(Color3.fromRGB(255, 214, 180), dusk * 0.6)
		profile.AtmosphereColor = profile.AtmosphereColor:Lerp(Color3.fromRGB(255, 170, 130), dusk * 0.5)
	end
	-- สภาพอากาศ
	local weather = State.World.Weather
	if weather == "Mist" then
		profile.AtmosphereDensity += 0.12
		profile.AtmosphereHaze += 1
	elseif weather == "Drizzle" or weather == "Rain" then
		local w = weather == "Rain" and 1 or 0.5
		profile.AtmosphereDensity += 0.12 * w
		profile.Saturation -= 0.12 * w
		profile.Brightness *= 1 - 0.3 * w
		profile.SunRays *= 1 - w
	end
	return profile
end

local function apply(p)
	Lighting.Ambient = p.Ambient
	Lighting.OutdoorAmbient = p.OutdoorAmbient
	Lighting.Brightness = p.Brightness
	Lighting.ExposureCompensation = p.ExposureCompensation
	effects.Atmosphere.Density = p.AtmosphereDensity
	effects.Atmosphere.Haze = p.AtmosphereHaze
	effects.Atmosphere.Glare = p.AtmosphereGlare
	effects.Atmosphere.Color = p.AtmosphereColor
	effects.Atmosphere.Decay = p.AtmosphereDecay
	effects.Color.TintColor = p.Tint
	effects.Color.Saturation = p.Saturation
	effects.Color.Contrast = p.Contrast
	effects.Bloom.Intensity = p.BloomIntensity
	effects.Bloom.Threshold = p.BloomThreshold
	effects.Bloom.Size = 28
	effects.SunRays.Intensity = p.SunRays
	effects.SunRays.Spread = 0.6
end

local function updateParticles()
	local zone = LightingProfiles.Zones[State.Zone]
	local wanted = {}
	for _, name in zone and zone.Particles or {} do
		wanted[name] = true
	end
	local night = LightingProfiles.NightWeight(Lighting.ClockTime) > 0.5
	local q = QUALITY[Atmosphere.Quality]
	for name, rec in emitters do
		local rate = 0
		if name == "Rain" then
			local weather = State.World.Weather
			rate = (weather == "Rain" and q.Rain) or (weather == "Drizzle" and q.Rain * 0.35) or 0
		elseif wanted[name] then
			rate = rec.BaseRate * q.ParticleScale
			if name == "Fireflies" and not night then
				rate = 0
			elseif name == "Pollen" and night then
				rate = 0
			elseif name == "GroundMist" and State.World.Weather == "Mist" then
				rate *= 2.5
			end
		end
		rec.Emitter.Rate = rate
	end
end

-- ไฟกลางคืน: เปิดเฉพาะ N ดวงที่ใกล้ที่สุด
local function updateLights()
	local camera = workspace.CurrentCamera
	local night = LightingProfiles.NightWeight(Lighting.ClockTime)
	local lights = CollectionService:GetTagged("NightLight")
	local origin = camera.CFrame.Position
	table.sort(lights, function(a, b)
		local pa, pb = a.Parent, b.Parent
		local da = pa and pa:IsA("BasePart") and (pa.Position - origin).Magnitude or math.huge
		local db = pb and pb:IsA("BasePart") and (pb.Position - origin).Magnitude or math.huge
		return da < db
	end)
	local limit = QUALITY[Atmosphere.Quality].Lights
	for i, light in lights do
		light.Enabled = night > 0.25 and i <= limit
	end
end

function Atmosphere.SetQuality(quality)
	if quality == "Auto" then
		local level = UserSettings().GameSettings.SavedQualityLevel.Value
		quality = level >= 8 and "High" or (level >= 4 and "Medium" or "Low")
		if level == 0 then
			quality = "Medium"
		end
	end
	Atmosphere.Quality = QUALITY[quality] and quality or "Medium"
	updateParticles()
end

function Atmosphere.Init()
	ensureEffects()
	buildParticles()
	local p = targetProfile()
	current = p
	apply(p)

	State.WorldChanged:Connect(updateParticles)
	State.ZoneChanged:Connect(updateParticles)
	State.Changed:Connect(function(profile)
		if profile.Settings and profile.Settings.Graphics then
			local before = Atmosphere.Quality
			Atmosphere.SetQuality(profile.Settings.Graphics)
			if before ~= Atmosphere.Quality then
				updateLights()
			end
		end
	end)

	local accumulator, lightTimer = 0, 0
	RunService.RenderStepped:Connect(function(dt)
		local camera = workspace.CurrentCamera
		particleRig.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, -4, 0))
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			State.SetZone(zoneAt(root.Position))
		end
		accumulator += dt
		if accumulator > 0.1 then
			local target = targetProfile()
			current = LightingProfiles.Blend(current, target, math.clamp(accumulator * 1.2, 0, 1))
			apply(current)
			accumulator = 0
		end
		lightTimer += dt
		if lightTimer > 1.5 then
			lightTimer = 0
			updateLights()
			updateParticles()
		end
	end)
end

return Atmosphere
