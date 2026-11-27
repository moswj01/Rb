--[[
	LightingProfiles — โปรไฟล์แสง/บรรยากาศเฉพาะแต่ละ Biome (กลางวัน + กลางคืน)
	Client จะ blend ระหว่าง Day/Night ตาม ClockTime และ blend ระหว่างโซนเมื่อเดินข้ามเขต
	กลางคืนออกแบบให้ "ลึกลับแต่ยังมองเห็น" (Ambient ไม่ต่ำเกินไป + แสงเรืองจากเห็ด/โคม)
]]

local C = Color3.fromRGB

local LightingProfiles = {}

local function profile(p)
	return p
end

LightingProfiles.Zones = {
	MysticVillage = {
		Day = profile({
			Ambient = C(120, 108, 96),
			OutdoorAmbient = C(150, 135, 120),
			Brightness = 2.6,
			ExposureCompensation = 0.1,
			AtmosphereDensity = 0.16,
			AtmosphereHaze = 0.8,
			AtmosphereGlare = 0.4,
			AtmosphereColor = C(255, 226, 190),
			AtmosphereDecay = C(196, 150, 110),
			Tint = C(255, 246, 232),
			Saturation = 0.12,
			Contrast = 0.08,
			BloomIntensity = 0.35,
			BloomThreshold = 1.6,
			SunRays = 0.12,
		}),
		Night = profile({
			Ambient = C(62, 66, 104),
			OutdoorAmbient = C(78, 84, 128),
			Brightness = 1.1,
			ExposureCompensation = 0.25,
			AtmosphereDensity = 0.24,
			AtmosphereHaze = 1.2,
			AtmosphereGlare = 0.1,
			AtmosphereColor = C(120, 130, 190),
			AtmosphereDecay = C(60, 64, 120),
			Tint = C(214, 222, 255),
			Saturation = 0.05,
			Contrast = 0.12,
			BloomIntensity = 0.8, -- หน้าต่างบ้านเรืองแสงสีทอง
			BloomThreshold = 1.2,
			SunRays = 0,
		}),
		Ambience = { Day = "Ambience_Village", Night = "Ambience_Night" },
		Music = { Day = "Music_Village_Day", Night = "Music_Village_Night" },
		Particles = { "Pollen" },
	},
	WhisperingForest = {
		Day = profile({
			Ambient = C(86, 104, 86),
			OutdoorAmbient = C(104, 130, 104),
			Brightness = 2.2,
			ExposureCompensation = 0,
			AtmosphereDensity = 0.24,
			AtmosphereHaze = 1.3,
			AtmosphereGlare = 0.9,
			AtmosphereColor = C(200, 232, 196),
			AtmosphereDecay = C(96, 140, 110),
			Tint = C(236, 255, 236),
			Saturation = 0.18,
			Contrast = 0.12,
			BloomIntensity = 0.45,
			BloomThreshold = 1.4,
			SunRays = 0.28, -- แสงลอดใบไม้
		}),
		Night = profile({
			Ambient = C(48, 66, 86),
			OutdoorAmbient = C(60, 84, 110),
			Brightness = 0.9,
			ExposureCompensation = 0.35,
			AtmosphereDensity = 0.32,
			AtmosphereHaze = 1.0,
			AtmosphereGlare = 0.2,
			AtmosphereColor = C(90, 140, 170),
			AtmosphereDecay = C(40, 70, 100),
			Tint = C(200, 232, 255),
			Saturation = 0.15,
			Contrast = 0.15,
			BloomIntensity = 1.0, -- เห็ดเรืองแสง หิ่งห้อย
			BloomThreshold = 1.0,
			SunRays = 0,
		}),
		Ambience = { Day = "Ambience_Forest", Night = "Ambience_Night" },
		Music = { Day = "Music_Forest_Day", Night = "Music_Forest_Night" },
		Particles = { "GroundMist", "Fireflies", "MagicMotes" },
	},
	Sanctuary = {
		Day = profile({
			Ambient = C(112, 110, 120),
			OutdoorAmbient = C(140, 136, 150),
			Brightness = 2.5,
			ExposureCompensation = 0.1,
			AtmosphereDensity = 0.18,
			AtmosphereHaze = 1.0,
			AtmosphereGlare = 0.6,
			AtmosphereColor = C(236, 220, 255),
			AtmosphereDecay = C(170, 150, 210),
			Tint = C(250, 246, 255),
			Saturation = 0.15,
			Contrast = 0.08,
			BloomIntensity = 0.4,
			BloomThreshold = 1.5,
			SunRays = 0.18,
		}),
		Night = profile({
			Ambient = C(70, 62, 110),
			OutdoorAmbient = C(86, 78, 136),
			Brightness = 1.1,
			ExposureCompensation = 0.3,
			AtmosphereDensity = 0.26,
			AtmosphereHaze = 1.3,
			AtmosphereGlare = 0.15,
			AtmosphereColor = C(140, 120, 200),
			AtmosphereDecay = C(70, 60, 130),
			Tint = C(226, 216, 255),
			Saturation = 0.1,
			Contrast = 0.12,
			BloomIntensity = 0.9,
			BloomThreshold = 1.1,
			SunRays = 0,
		}),
		Ambience = { Day = "Ambience_Forest", Night = "Ambience_Night" },
		Music = { Day = "Music_Sanctuary", Night = "Music_Sanctuary" },
		Particles = { "MagicMotes", "Fireflies" },
	},
}

-- น้ำหนักกลางคืน 0..1 จากเวลา (มีช่วงพลบค่ำ/รุ่งสางนุ่ม ๆ)
function LightingProfiles.NightWeight(clockTime)
	if clockTime >= 7 and clockTime <= 17 then
		return 0
	elseif clockTime >= 19.5 or clockTime <= 4.5 then
		return 1
	elseif clockTime > 17 then
		return (clockTime - 17) / 2.5
	end
	return 1 - (clockTime - 4.5) / 2.5
end

local function lerp(a, b, t)
	if typeof(a) == "Color3" then
		return a:Lerp(b, t)
	end
	return a + (b - a) * t
end

function LightingProfiles.Blend(a, b, t)
	local out = {}
	for key, value in a do
		out[key] = lerp(value, b[key], t)
	end
	return out
end

function LightingProfiles.Resolve(zoneId, clockTime)
	local zone = LightingProfiles.Zones[zoneId] or LightingProfiles.Zones.MysticVillage
	return LightingProfiles.Blend(zone.Day, zone.Night, LightingProfiles.NightWeight(clockTime))
end

-- พลบค่ำ: ไล่โทนอุ่นตอนเย็น
function LightingProfiles.DuskWeight(clockTime)
	if clockTime >= 16.5 and clockTime <= 19.5 then
		return 1 - math.abs(clockTime - 18) / 1.5
	elseif clockTime >= 4.5 and clockTime <= 7.5 then
		return 1 - math.abs(clockTime - 6) / 1.5
	end
	return 0
end

return LightingProfiles
