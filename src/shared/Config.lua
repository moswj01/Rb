--[[
	Config — ค่าตั้งค่าหลักของเกม "Skin Party Island" v2
	ปรับสมดุลเกม / ราคา / Robux ได้จากไฟล์นี้ไฟล์เดียว
]]

local Config = {}

Config.Version = "2.0"
Config.GameName = "Skin Party Island"
Config.DataStoreName = "SkinPartyIsland_Data_v1"
Config.AutoSaveInterval = 120

-- ===== เงินเริ่มต้น =====
Config.StartingCoins = 250
Config.StartingGems = 10

-- ===== ดาวบนเกาะ =====
Config.StarCount = 40
Config.StarValue = 5
Config.BigStarValue = 30
Config.BigStarChance = 0.07
Config.StarRespawnTime = 4
Config.LobbyRadius = 100

-- ===== XP (ใช้เลื่อนขั้น Party Pass) =====
Config.XP = {
	Star = 2,
	BigStar = 12,
	WaveSurvived = 8,
	ColorFloorWin = 60,
	ShowdownJoin = 30,
	ShowdownTop3 = 70,
	Vote = 2,
	Daily = 120,
}

-- ===== โหมดมินิเกม (สลับกันไปเรื่อย ๆ) =====
Config.IntermissionTime = 25
Config.MinPlayersForRound = 1
Config.RoundModes = { "Showdown", "ColorFloor" }

-- พื้นสีวิบวับ
Config.ColorFloor = {
	Waves = 10,
	StartTime = 5,
	MinTime = 1.6,
	TimeStep = 0.4,
	RewardPerWave = 10,
	RewardWin = 150,
}

-- เวทีแฟชั่นโชว์ (หัวใจของเกม: ยิ่งมีของสวย ยิ่งได้คะแนน)
Config.Showdown = {
	DressTime = 40, -- เวลาแต่งตัว
	WalkTime = 7, -- เวลาเดินแบบต่อคน
	MaxModels = 10,
	ThemeBonusPerItem = 0.4, -- ใส่ของตรงธีมได้คะแนนเพิ่มชิ้นละ
	RarityBonus = { Common = 0, Rare = 0.05, Epic = 0.1, Legendary = 0.2, Mythic = 0.3 },
	Rewards = { 200, 120, 80 }, -- อันดับ 1-3
	Participation = 40,
}

Config.ShowdownThemes = {
	{ Name = "หวานแหววแคนดี้", Icon = "🍭", Set = "Candy" },
	{ Name = "เจ้าหญิงใต้ทะเล", Icon = "🌊", Set = "Ocean" },
	{ Name = "นักบินอวกาศ", Icon = "🚀", Set = "Space" },
	{ Name = "ผีน้อยน่ารัก", Icon = "🎃", Set = "Spooky" },
	{ Name = "นางฟ้าในสวน", Icon = "🧚", Set = "Fairy" },
	{ Name = "นีออนแห่งอนาคต", Icon = "🤖", Set = "Cyber" },
	{ Name = "ราชวงศ์สุดหรู", Icon = "👑", Set = "Royal" },
	{ Name = "ความฝันสายรุ้ง", Icon = "🌈", Set = "Rainbow" },
}

-- ===== รางวัลรายวัน =====
Config.DailyRewards = {
	{ Coins = 100 },
	{ Coins = 150 },
	{ Gems = 5 },
	{ Coins = 300 },
	{ Gems = 10 },
	{ Coins = 500 },
	{ Gems = 30, Coins = 500 },
}
Config.DailyCooldown = 20 * 60 * 60
Config.DailyStreakReset = 48 * 60 * 60

-- ===== ภารกิจมือใหม่ (Onboarding) =====
Config.Tutorial = {
	{ Id = "Star", Text = "เก็บดาว ⭐ 5 ดวง", Goal = 5, Reward = { Coins = 100 } },
	{ Id = "Buy", Text = "ซื้อไอเท็มชิ้นแรกที่ร้าน 🛍️", Goal = 1, Reward = { Coins = 150 } },
	{ Id = "Round", Text = "เล่นมินิเกม 1 รอบ 🎮", Goal = 1, Reward = { Gems = 10 } },
	{ Id = "Daily", Text = "รับของขวัญรายวัน 🎁", Goal = 1, Reward = { Item = "title_newbie", Coins = 200 } },
}

-- ===== ร้านค้า =====
Config.FeaturedCount = 6
Config.FeaturedDiscount = 0.3
Config.AnnounceRarities = { Legendary = true, Mythic = true } -- ประกาศทั้งเซิร์ฟเมื่อมีคนได้ของระดับนี้
Config.TryOnSeconds = 20

-- ===== โค้ด =====
Config.Codes = {
	WELCOME = { Coins = 300 },
	PARTYTIME = { Gems = 10 },
	SKINPARTY2026 = { Coins = 500, Gems = 5 },
}

--[[ =====================================================================
	ROBUX — ใส่ ID จริงจาก Creator Dashboard (0 = ยังไม่ตั้งค่า)
	ราคาที่แนะนำอยู่ในคอมเมนต์ (อ้างอิงเกมแนวแต่งตัวยอดนิยม)
===================================================================== ]]

-- Game Passes
Config.GamePasses = {
	VIP = { -- แนะนำ 249 R$
		Id = 0,
		Name = "VIP ปาร์ตี้",
		Icon = "👑",
		Description = "สกิน+ปีก+ออร่า+ฉายา VIP, ป้ายทอง, แท็กแชท, เหรียญ +20%",
	},
	DoubleCoins = { -- แนะนำ 149 R$
		Id = 0,
		Name = "เหรียญ x2",
		Icon = "🪙",
		Description = "ได้เหรียญจากทุกกิจกรรม 2 เท่า ตลอดไป",
	},
	PartyPass = { -- แนะนำ 399 R$ (สร้างใหม่ทุกซีซั่น)
		Id = 0,
		Name = "Party Pass พรีเมียม",
		Icon = "🎫",
		Description = "ปลดล็อกรางวัลพรีเมียม 30 ขั้น: ชุดสายรุ้งเทพนิยายครบเซ็ต + เพชร 300",
	},
}

-- Developer Products: เติมเพชร
Config.GemPacks = {
	{ Key = "gems_s", ProductId = 0, Gems = 50, Name = "ถุงเพชร", Icon = "💎" }, -- 49 R$
	{ Key = "gems_m", ProductId = 0, Gems = 130, Name = "กล่องเพชร", Icon = "💎💎", Tag = "+10%" }, -- 119 R$
	{ Key = "gems_l", ProductId = 0, Gems = 300, Name = "หีบเพชร", Icon = "🧰", Tag = "ยอดนิยม", Highlight = true }, -- 249 R$
	{ Key = "gems_xl", ProductId = 0, Gems = 700, Name = "ภูเขาเพชร", Icon = "🏔️", Tag = "+40%" }, -- 499 R$
	{ Key = "gems_xxl", ProductId = 0, Gems = 1600, Name = "ปราสาทเพชร", Icon = "🏰", Tag = "คุ้มสุด!", Highlight = true }, -- 999 R$
}

-- Developer Products: ชุดเซ็ตครบ (ได้ทุกชิ้นในเซ็ตทันที + เพชรโบนัส)
Config.Bundles = {
	{ Key = "bundle_space", Set = "Space", ProductId = 0, BonusGems = 30, Tag = "-35%" }, -- 199 R$
	{ Key = "bundle_spooky", Set = "Spooky", ProductId = 0, BonusGems = 30, Tag = "-35%" }, -- 199 R$
	{ Key = "bundle_fairy", Set = "Fairy", ProductId = 0, BonusGems = 60, Tag = "-40%" }, -- 349 R$
	{ Key = "bundle_cyber", Set = "Cyber", ProductId = 0, BonusGems = 60, Tag = "-40%" }, -- 349 R$
	{ Key = "bundle_royal", Set = "Royal", ProductId = 0, BonusGems = 120, Tag = "-45%" }, -- 599 R$
}

-- Starter Pack: ข้อเสนอครั้งเดียว สำหรับผู้เล่นใหม่ 72 ชม. (ตัวทำเงินอันดับ 1 ของเกมแนวนี้)
Config.StarterPack = { -- แนะนำ 99 R$
	ProductId = 0,
	DurationHours = 72,
	Gems = 150,
	Coins = 3000,
	Items = { "pet_chick", "trail_starter", "title_starter" },
}

-- ข้ามขั้น Party Pass
Config.TierSkip = { ProductId = 0, Tiers = 5 } -- 99 R$

-- ===== Party Pass (Season Pass) =====
Config.PartyPass = {
	Season = 1,
	Name = "ซีซั่น 1: ปาร์ตี้สายรุ้ง",
	Tiers = 30,
	XPPerTier = 250,
	EndsAt = 1801440000, -- 1 ก.พ. 2027 00:00 UTC
}

-- ทดสอบใน Studio: true = ให้ทุก Game Pass อัตโนมัติ
Config.StudioGrantAllPasses = false

return Config
