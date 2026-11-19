--[[
	Config — ค่าตั้งค่าหลักของเกม "Skin Party Island"
	แก้ตัวเลขตรงนี้เพื่อปรับสมดุลเกมได้ทันที ไม่ต้องไปแก้โค้ดส่วนอื่น
]]

local Config = {}

Config.GameName = "Skin Party Island"
Config.DataStoreName = "SkinPartyIsland_Data_v1"
Config.AutoSaveInterval = 120 -- วินาที

-- ===== เงินเริ่มต้น =====
Config.StartingCoins = 150
Config.StartingGems = 0

-- ===== ดาวบนเกาะ (เก็บเหรียญฟรี) =====
Config.StarCount = 35
Config.StarValue = 5
Config.BigStarValue = 25
Config.BigStarChance = 0.07 -- โอกาสที่ดาวจะเป็น "ดาวยักษ์สายรุ้ง"
Config.StarRespawnTime = 4
Config.LobbyRadius = 100

-- ===== มินิเกม "พื้นสีวิบวับ" =====
Config.IntermissionTime = 25
Config.MinPlayersForRound = 1
Config.RoundWaves = 10
Config.WaveStartTime = 5 -- เวลาหาสีในเวฟแรก
Config.WaveMinTime = 1.6 -- เวลาน้อยสุดในเวฟท้าย ๆ
Config.WaveTimeStep = 0.4 -- ลดลงเวฟละกี่วินาที
Config.RoundRewardPerWave = 8
Config.RoundRewardWin = 120

-- ===== รางวัลรายวัน (ต่อเนื่อง 7 วัน แล้ววนใหม่) =====
Config.DailyRewards = {
	{ Coins = 50 },
	{ Coins = 80 },
	{ Coins = 120 },
	{ Gems = 5 },
	{ Coins = 200 },
	{ Coins = 300 },
	{ Gems = 20, Coins = 300 },
}
Config.DailyCooldown = 20 * 60 * 60 -- รับได้ทุก 20 ชม.
Config.DailyStreakReset = 48 * 60 * 60 -- ถ้าหายไปเกิน 48 ชม. สตรีครีเซ็ต

-- ===== ร้านค้า: ของแนะนำประจำวัน =====
Config.FeaturedCount = 4
Config.FeaturedDiscount = 0.25 -- ลด 25%

-- ===== โค้ดแจกของ (ตัวพิมพ์ใหญ่เท่านั้น) =====
Config.Codes = {
	WELCOME = { Coins = 200 },
	PARTYTIME = { Gems = 5 },
	SKINPARTY2026 = { Coins = 500 },
}

-- ===== Robux: Game Pass =====
-- ใส่ ID จริงจากหน้า Creator Dashboard (0 = ยังไม่ได้ตั้งค่า)
Config.GamePasses = {
	VIP = {
		Id = 0,
		Name = "VIP ปาร์ตี้",
		Icon = "👑",
		Description = "ได้สกิน VIP + ออร่า VIP + ป้ายชื่อทอง + แท็กแชท",
	},
	DoubleCoins = {
		Id = 0,
		Name = "เหรียญ x2",
		Icon = "🪙",
		Description = "ได้เหรียญจากดาวและมินิเกมเป็น 2 เท่าตลอดไป",
	},
}

-- ===== Robux: Developer Products (เติมเพชร) =====
Config.GemPacks = {
	{ ProductId = 0, Gems = 40, Name = "ถุงเพชรจิ๋ว", Icon = "💎" },
	{ ProductId = 0, Gems = 110, Name = "กล่องเพชร", Icon = "💎💎", Bonus = "+10%" },
	{ ProductId = 0, Gems = 250, Name = "หีบเพชร", Icon = "🧰", Bonus = "+25%" },
	{ ProductId = 0, Gems = 600, Name = "ภูเขาเพชร", Icon = "🏔️", Bonus = "+50%" },
}

-- ทดสอบใน Studio: true = ให้ทุก Game Pass อัตโนมัติ (ไม่มีผลในเซิร์ฟเวอร์จริง)
Config.StudioGrantAllPasses = false

return Config
