--[[
	Config — ค่าปรับสมดุลเกม Mythical Sanctuary (Phase 1: Vertical Slice)
	แยกตัวเลขทั้งหมดออกจากโค้ด เพื่อให้ Game Designer ปรับได้โดยไม่แตะระบบ
]]

local Config = {}

Config.Version = "0.1.0-vertical-slice"
Config.DataStoreName = "MythicalSanctuary_Player"
Config.DataVersion = 2 -- เพิ่มเลขนี้ทุกครั้งที่เปลี่ยนโครงสร้างข้อมูล + เพิ่ม migration ใน DataService
Config.AutoSaveInterval = 90
Config.SessionLockTimeout = 30 * 60 -- ล็อกค้างนานกว่านี้ถือว่าเซิร์ฟเก่าล่มไปแล้ว

-- ===== เวลาในเกม =====
Config.DayLengthMinutes = 24 -- 1 วันในเกม = 24 นาทีจริง
Config.StartClockTime = 9

-- ===== เศรษฐกิจ =====
Config.StartingCoins = 120 -- "Lumen" เหรียญแสงเวทมนตร์
Config.StartingItems = { glowberry = 6, silverfern = 2 }

-- ===== ผู้เล่น =====
Config.LevelXP = function(level)
	return 100 + (level - 1) * 60
end
Config.SneakWalkSpeed = 8 -- ย่อตัวเข้าหาสัตว์อย่างนุ่มนวล
Config.NormalWalkSpeed = 16
Config.RunSpeed = 24

-- ===== ความไว้วางใจ (Taming แบบไม่ใช้กำลัง) =====
Config.Trust = {
	Max = 100,
	OfferFavoriteFood = 22,
	OfferFood = 9,
	OfferDislikedFood = -6,
	CalmWhileSneaking = 6,
	CalmWhileRunning = -10, -- วิ่งเข้าใส่ทำให้ตกใจ
	HealInjured = 45,
	DecayPerMinute = 2, -- ถ้าผู้เล่นเดินจากไป ความไว้วางใจลดลงช้า ๆ
	BondThreshold = 100, -- ครบ = สัตว์ยอมติดตามไปเขตอนุรักษ์
	InteractCooldown = 2.5,
}

-- ===== การดูแลสัตว์ =====
Config.Care = {
	TickSeconds = 30,
	HungerPerTick = 2.5, -- ลดลงต่อ tick (0-100)
	EnergyPerTick = 1.5,
	JoyPerTick = 1.2,
	OfflineDecayCapHours = 6, -- ออฟไลน์นาน ค่าก็ไม่ลดเกินนี้ (Cozy: สัตว์ไม่มีวันตาย)
	FeedHunger = 30,
	FeedFavoriteJoy = 12,
	PetJoy = 8,
	PlayJoy = 18,
	PlayEnergyCost = 10,
	SleepEnergyPerTick = 8,
	CareXP = { Feed = 6, FeedFavorite = 10, Pet = 3, Play = 8 },
	PetCooldown = 4,
}

-- ช่วงวัย: ต้องได้ CareXP ถึงเกณฑ์ + ความสุขเฉลี่ยดี
Config.Growth = {
	Stages = { "Egg", "Baby", "Juvenile", "Adult" },
	EggHatchSeconds = 8 * 60,
	CareXPToJuvenile = 120,
	CareXPToAdult = 400,
	MinJoyToGrow = 50,
}

-- ===== AI สัตว์ =====
Config.AI = {
	NearDistance = 160, -- ใกล้ผู้เล่น: คิดทุก 0.25 วิ
	FarDistance = 420, -- ไกล: คิดทุก 2 วิ, ไกลกว่านี้: หลับ (ไม่ประมวลผล)
	NearTick = 0.25,
	FarTick = 2,
	PathfindingMinDistance = 40, -- ระยะเกินนี้ใช้ PathfindingService
	MaxWildPerSpawnArea = 3,
	RespawnSeconds = 120,
}

-- ===== เขตอนุรักษ์ส่วนตัว =====
Config.Sanctuary = {
	PlotSpacing = 1400,
	PlotOrigin = Vector3.new(6000, 0, 0),
	BuildRadius = 150, -- รัศมีที่วางของได้ (ขยายได้ในอนาคต)
	GridSize = 2,
	MaxPlacedObjects = 150,
	MaxCreatures = 12,
}

-- ===== เก็บสมุนไพร =====
Config.Forage = {
	RespawnSeconds = 90,
	InteractDistance = 10,
}

return Config
