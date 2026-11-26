--[[
	Audio — เพลง/เสียงบรรยากาศตามโซน + ช่วงเวลา (crossfade), เสียงน้ำ 3D, ฝีเท้าตามพื้นผิว
	SoundId มาจาก AssetRegistry.Sounds (0 = ยังไม่มีไฟล์เสียง → เงียบ ไม่ error)
	ต้องเป็นเสียง/ดนตรีที่สร้างใหม่หรือมีสิทธิ์ใช้งานถูกต้องเท่านั้น
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AssetRegistry = require(Shared.AssetRegistry)
local LightingProfiles = require(Shared.LightingProfiles)
local WorldLayout = require(Shared.WorldLayout)

local State = require(script.Parent.Parent.State)

local Audio = {}

local player = Players.LocalPlayer
local musicGroup, sfxGroup, ambienceGroup
local playing = { Music = nil, Ambience = nil }

local FOOTSTEP = {
	[Enum.Material.Grass] = "Sfx_Footstep_Grass",
	[Enum.Material.LeafyGrass] = "Sfx_Footstep_Grass",
	[Enum.Material.Ground] = "Sfx_Footstep_Mud",
	[Enum.Material.Mud] = "Sfx_Footstep_Mud",
	[Enum.Material.Sand] = "Sfx_Footstep_Mud",
	[Enum.Material.Cobblestone] = "Sfx_Footstep_Stone",
	[Enum.Material.Rock] = "Sfx_Footstep_Stone",
	[Enum.Material.Slate] = "Sfx_Footstep_Stone",
	[Enum.Material.WoodPlanks] = "Sfx_Footstep_Wood",
	[Enum.Material.Wood] = "Sfx_Footstep_Wood",
}

local function soundId(key)
	local id = AssetRegistry.Sounds[key]
	if not id or id == 0 then
		return nil
	end
	return "rbxassetid://" .. tostring(id)
end

local function makeSound(key, group, looped, parent)
	local id = soundId(key)
	if not id then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = id
	sound.Looped = looped
	sound.Volume = 0
	sound.SoundGroup = group
	sound.Parent = parent or SoundService
	return sound
end

local function crossfade(slot, key, group, volume)
	local current = playing[slot]
	if current and current.Name == key then
		return
	end
	if current then
		local old = current
		TweenService:Create(old, TweenInfo.new(3), { Volume = 0 }):Play()
		task.delay(3.2, function()
			old:Destroy()
		end)
	end
	local sound = key and makeSound(key, group, true)
	playing[slot] = sound
	if sound then
		sound:Play()
		TweenService:Create(sound, TweenInfo.new(4), { Volume = volume }):Play()
	end
end

local function refresh()
	local zone = LightingProfiles.Zones[State.Zone]
	if not zone then
		return
	end
	local night = LightingProfiles.NightWeight(Lighting.ClockTime) > 0.5
	crossfade("Music", night and zone.Music.Night or zone.Music.Day, musicGroup, 0.5)
	local ambience = night and zone.Ambience.Night or zone.Ambience.Day
	if State.World.Weather == "Rain" then
		ambience = "Ambience_Rain"
	end
	crossfade("Ambience", ambience, ambienceGroup, 0.6)
end

local function placeWaterEmitters()
	-- เสียงลำธาร 3D ตามแนวแม่น้ำ + น้ำตก (ได้ยินเมื่อเข้าใกล้)
	local holder = Instance.new("Folder")
	holder.Name = "AudioEmitters"
	holder.Parent = workspace
	local function emitterAt(position, key, distance)
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Transparency = 1
		part.Size = Vector3.one
		part.Position = position
		part.Parent = holder
		local sound = makeSound(key, ambienceGroup, true, part)
		if sound then
			sound.RollOffMode = Enum.RollOffMode.InverseTapered
			sound.RollOffMaxDistance = distance
			sound.RollOffMinDistance = 12
			sound.Volume = 0.7
			sound:Play()
		end
	end
	for _, point in WorldLayout.River.Points do
		emitterAt(point.Pos + Vector3.new(0, point.Level, 0), "Ambience_River", 90)
	end
	for _, landmark in WorldLayout.Landmarks do
		if landmark.Key == "Landmark_Waterfall" then
			emitterAt(landmark.Pos + Vector3.new(0, 60, 0), "Ambience_Waterfall", 220)
		end
	end
end

function Audio.SetVolumes(music, sfx)
	musicGroup.Volume = music
	ambienceGroup.Volume = math.max(0.2, music)
	sfxGroup.Volume = sfx
end

function Audio.Play(key, parent)
	local sound = makeSound(key, sfxGroup, false, parent)
	if sound then
		sound.Volume = 0.8
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end
end

function Audio.Init()
	musicGroup = Instance.new("SoundGroup", SoundService)
	musicGroup.Name = "Music"
	ambienceGroup = Instance.new("SoundGroup", SoundService)
	ambienceGroup.Name = "Ambience"
	sfxGroup = Instance.new("SoundGroup", SoundService)
	sfxGroup.Name = "Sfx"

	placeWaterEmitters()
	State.ZoneChanged:Connect(refresh)
	State.WorldChanged:Connect(refresh)
	State.Changed:Connect(function(profile)
		Audio.SetVolumes(profile.Settings.Music, profile.Settings.Sfx)
	end)
	task.spawn(function()
		while true do
			refresh()
			task.wait(10)
		end
	end)

	-- ฝีเท้าตามพื้นผิว
	local stepTimer = 0
	RunService.Heartbeat:Connect(function(dt)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then
			return
		end
		local speed = (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
		if speed < 2 or humanoid.FloorMaterial == Enum.Material.Air then
			stepTimer = 0
			return
		end
		stepTimer += dt
		local interval = math.clamp(5 / speed, 0.25, 0.6)
		if stepTimer >= interval then
			stepTimer = 0
			local key = FOOTSTEP[humanoid.FloorMaterial]
			if key then
				Audio.Play(key, root)
			end
		end
	end)
end

return Audio
