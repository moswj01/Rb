--[[
	EnvironmentService — วงจรกลางวัน/กลางคืน + สภาพอากาศแบบ dynamic (ฝั่งเซิร์ฟเวอร์เป็นผู้กำหนด)
	Client ใช้ WorldState เพื่อ blend Lighting profile, ฝน, หมอก, เสียง
	สภาพอากาศมีผลต่อสัตว์: ฝนตก → สัตว์หาที่หลบ / กวางจันทราออกมามากขึ้นตอนหมอกลง
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)

local EnvironmentService = {}

local WEATHER = {
	{ Id = "Clear", Weight = 5, Minutes = { 6, 12 } },
	{ Id = "Mist", Weight = 2, Minutes = { 3, 6 } },
	{ Id = "Drizzle", Weight = 2, Minutes = { 3, 5 } },
	{ Id = "Rain", Weight = 1, Minutes = { 2, 4 } },
}

EnvironmentService.Weather = "Clear"
local rng = Random.new()

local function pickWeather()
	local total = 0
	for _, w in WEATHER do
		total += w.Weight
	end
	local roll = rng:NextNumber(0, total)
	for _, w in WEATHER do
		roll -= w.Weight
		if roll <= 0 then
			return w
		end
	end
	return WEATHER[1]
end

function EnvironmentService.ClockTime()
	return Lighting.ClockTime
end

function EnvironmentService.IsNight()
	local t = Lighting.ClockTime
	return t >= 19 or t < 5.5
end

function EnvironmentService.Period()
	local t = Lighting.ClockTime
	if t >= 17 and t < 19.5 then
		return "Dusk"
	elseif t >= 19.5 or t < 5 then
		return "Night"
	elseif t >= 5 and t < 7 then
		return "Dawn"
	end
	return "Day"
end

local function broadcast()
	Net.Event("WorldState"):FireAllClients({ Weather = EnvironmentService.Weather, Period = EnvironmentService.Period() })
end

function EnvironmentService.Init()
	Lighting.ClockTime = Config.StartClockTime
	Lighting.GeographicLatitude = 23
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.5
	pcall(function()
		Lighting.ShadowSoftness = 0.35
	end)
	for _, className in { "Atmosphere", "ColorCorrectionEffect", "BloomEffect", "SunRaysEffect", "DepthOfFieldEffect", "Sky" } do
		if not Lighting:FindFirstChildOfClass(className) then
			local effect = Instance.new(className)
			if className == "DepthOfFieldEffect" then
				effect.FarIntensity = 0.04
				effect.FocusDistance = 200
				effect.InFocusRadius = 200
				effect.NearIntensity = 0
			end
			effect.Parent = Lighting
		end
	end

	local hoursPerSecond = 24 / (Config.DayLengthMinutes * 60)
	task.spawn(function()
		local lastPeriod = EnvironmentService.Period()
		while true do
			local dt = task.wait(0.5)
			Lighting.ClockTime = (Lighting.ClockTime + dt * hoursPerSecond) % 24
			local period = EnvironmentService.Period()
			if period ~= lastPeriod then
				lastPeriod = period
				broadcast()
			end
		end
	end)

	task.spawn(function()
		while true do
			local w = pickWeather()
			EnvironmentService.Weather = w.Id
			broadcast()
			task.wait(rng:NextNumber(w.Minutes[1], w.Minutes[2]) * 60)
		end
	end)

	game:GetService("Players").PlayerAdded:Connect(function(player)
		task.delay(3, function()
			if player.Parent then
				Net.Event("WorldState"):FireClient(player, { Weather = EnvironmentService.Weather, Period = EnvironmentService.Period() })
			end
		end)
	end)
end

return EnvironmentService
