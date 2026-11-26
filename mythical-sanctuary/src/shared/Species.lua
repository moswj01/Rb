--[[
	Species — ข้อมูลสัตว์เวทมนตร์ทั้ง 8 สายพันธุ์ (Original Designs)
	Phase 1 เปิดใช้ 3 สายพันธุ์: Spirit Kitsune, Lunar Stag, Treasure Mole
	ฟิลด์ Asset* ชี้ไปที่ AssetRegistry (โมเดล/ริก/แอนิเมชันจริงจาก 3D Artist)
]]

local Species = {}

local C = Color3.fromRGB

Species.Personalities = {
	Playful = { Name = "ขี้เล่น", TrustMult = 1.2, FleeMult = 0.8, PlayChance = 0.35, ApproachChance = 0.25 },
	Shy = { Name = "ขี้กลัว", TrustMult = 0.75, FleeMult = 1.5, PlayChance = 0.1, ApproachChance = 0.05 },
	Curious = { Name = "อยากรู้อยากเห็น", TrustMult = 1.1, FleeMult = 0.9, PlayChance = 0.2, ApproachChance = 0.4 },
	Solitary = { Name = "รักสันโดษ", TrustMult = 0.9, FleeMult = 1.1, PlayChance = 0.05, ApproachChance = 0.1 },
}

Species.List = {
	{
		Id = "spirit_kitsune",
		Name = "Spirit Kitsune",
		ThaiName = "จิ้งจอกวิญญาณ",
		Phase = 1,
		Element = "Spirit",
		Rarity = "Uncommon",
		Zone = "WhisperingForest",
		ActiveTime = "Dusk", -- Day | Night | Dusk | Any
		Personalities = { "Playful", "Curious", "Shy" },
		Favorite = "spirit_plum",
		Likes = { "glowberry", "spirit_plum" },
		Dislikes = { "crystal_grub" },
		Speed = { Walk = 10, Run = 26 },
		FleeDistance = 22,
		WanderRadius = 60,
		Habitat = "habitat_kitsune_den",
		Ability = { Id = "WispLight", Name = "แสงวิญญาณนำทาง", Description = "ปล่อยดวงไฟวิญญาณส่องทางในที่มืด" },
		Palette = { Primary = C(242, 236, 228), Secondary = C(140, 196, 255), Accent = C(255, 196, 120) },
		Size = { Baby = 0.45, Juvenile = 0.7, Adult = 1.0 },
		Lore = "จิ้งจอกที่เกิดจากแสงหิ่งห้อยนับพันดวงรวมตัวกันในคืนฤดูร้อน หางทั้งสามของมันเรืองแสงตามอารมณ์ — สีฟ้าเมื่อสงบ สีทองเมื่อดีใจ",
		Clues = { "รอยเท้าเรืองแสงจาง ๆ", "เสียงกระดิ่งลมทั้งที่ไม่มีลม", "กลีบดอกไม้ลอยวนเป็นวง" },
	},
	{
		Id = "lunar_stag",
		Name = "Lunar Stag",
		ThaiName = "กวางจันทรา",
		Phase = 1,
		Element = "Moon",
		Rarity = "Rare",
		Zone = "WhisperingForest",
		ActiveTime = "Night",
		Personalities = { "Shy", "Solitary", "Curious" },
		Favorite = "moonleaf",
		Likes = { "moonleaf", "glowberry" },
		Dislikes = { "honeyroot" },
		Speed = { Walk = 8, Run = 30 },
		FleeDistance = 34,
		WanderRadius = 80,
		Habitat = "habitat_moon_glade",
		Ability = { Id = "MoonStep", Name = "ก้าวแสงจันทร์", Description = "กระโดดข้ามระยะไกลทิ้งรอยแสงจันทร์บนพื้น" },
		Palette = { Primary = C(78, 92, 140), Secondary = C(210, 226, 255), Accent = C(255, 246, 210) },
		Size = { Baby = 0.5, Juvenile = 0.75, Adult = 1.0 },
		Lore = "เขาของกวางจันทราเปลี่ยนรูปตามข้างขึ้นข้างแรม ในคืนเดือนมืดมันจะซ่อนตัวที่ริมน้ำตก และจะยอมให้เห็นเฉพาะผู้ที่เดินอย่างแผ่วเบาเท่านั้น",
		Clues = { "ใบไม้เป็นประกายเงินตามทางเดิน", "รอยกีบรูปพระจันทร์เสี้ยว", "เสียงกระซิบใกล้แหล่งน้ำ" },
	},
	{
		Id = "treasure_mole",
		Name = "Treasure Mole",
		ThaiName = "ตุ่นนักขุดสมบัติ",
		Phase = 1,
		Element = "Earth",
		Rarity = "Common",
		Zone = "WhisperingForest",
		ActiveTime = "Day",
		Personalities = { "Curious", "Playful", "Solitary" },
		Favorite = "crystal_grub",
		Likes = { "crystal_grub", "honeyroot" },
		Dislikes = { "moonleaf" },
		Speed = { Walk = 7, Run = 14 },
		FleeDistance = 14,
		WanderRadius = 45,
		Habitat = "habitat_mole_burrow",
		Ability = { Id = "Dig", Name = "ขุดหาสมบัติ", Description = "ขุดดินหาสมุนไพรและของมีค่าให้เจ้าของวันละครั้ง" },
		Palette = { Primary = C(120, 92, 74), Secondary = C(232, 196, 160), Accent = C(120, 220, 210) },
		Size = { Baby = 0.5, Juvenile = 0.75, Adult = 1.0 },
		Lore = "ตุ่นตัวกลมที่จมูกไวต่อแร่คริสตัล มันชอบสะสมของแวววาวไว้ในโพรง และมักโผล่ขึ้นมาทักทายนักเดินทางที่ใจดีกับมันด้วยเสียงจิ๊บ ๆ",
		Clues = { "กองดินเล็ก ๆ เป็นแนวยาว", "เศษคริสตัลเล็ก ๆ ตกอยู่", "เสียงขุดดินใต้เท้า" },
	},

	-- ===== Phase 2–3 (ข้อมูลพร้อม รอ Asset + Zone) =====
	{ Id = "ember_dragon", Name = "Ember Dragon", ThaiName = "มังกรถ่านเพลิง", Phase = 3, Element = "Fire", Rarity = "Legendary", Zone = "EmberValley", ActiveTime = "Any", Personalities = { "Playful", "Solitary" }, Favorite = "ember_pepper", Likes = { "ember_pepper" }, Dislikes = { "moonleaf" }, Speed = { Walk = 10, Run = 28 }, FleeDistance = 30, WanderRadius = 120, Habitat = "habitat_dragon_cave", Ability = { Id = "EmberBreath", Name = "ลมหายใจถ่านเพลิง", Description = "พ่นถ่านอุ่น ๆ จุดไฟเตาและทำลายน้ำแข็ง" }, Palette = { Primary = C(160, 52, 36), Secondary = C(255, 150, 60), Accent = C(255, 230, 140) }, Size = { Baby = 0.4, Juvenile = 0.7, Adult = 1.0 }, Lore = "เกล็ดของมันเก็บความร้อนจากภูเขาไฟได้นานนับร้อยปี", Clues = { "หินที่ยังอุ่นอยู่", "ร่องรอยไหม้รูปกรงเล็บ" } },
	{ Id = "storm_griffin", Name = "Storm Griffin", ThaiName = "กริฟฟินวายุ", Phase = 3, Element = "Wind", Rarity = "Epic", Zone = "FrostMountains", ActiveTime = "Day", Personalities = { "Curious", "Solitary" }, Favorite = "sky_seed", Likes = { "sky_seed" }, Dislikes = { "crystal_grub" }, Speed = { Walk = 9, Run = 30 }, FleeDistance = 36, WanderRadius = 140, Habitat = "habitat_cliff_nest", Ability = { Id = "Gust", Name = "พายุหมุน", Description = "สร้างลมยกตัวผู้ขี่ขึ้นสู่ที่สูง" }, Palette = { Primary = C(200, 190, 170), Secondary = C(110, 140, 190), Accent = C(240, 240, 255) }, Size = { Baby = 0.45, Juvenile = 0.7, Adult = 1.0 }, Lore = "ทำรังบนยอดเขาที่ฟ้าผ่าบ่อยที่สุด", Clues = { "ขนนกมีประจุไฟฟ้า" } },
	{ Id = "solar_phoenix", Name = "Solar Phoenix", ThaiName = "วิหคสุริยัน", Phase = 3, Element = "Light", Rarity = "Legendary", Zone = "CelestialIslands", ActiveTime = "Day", Personalities = { "Curious", "Playful" }, Favorite = "sun_nectar", Likes = { "sun_nectar" }, Dislikes = {}, Speed = { Walk = 8, Run = 34 }, FleeDistance = 40, WanderRadius = 160, Habitat = "habitat_sun_perch", Ability = { Id = "Rebirth", Name = "คืนชีพแห่งแสง", Description = "ฟื้นพลังให้สัตว์ทุกตัวรอบตัว" }, Palette = { Primary = C(255, 170, 60), Secondary = C(255, 90, 60), Accent = C(255, 240, 180) }, Size = { Baby = 0.4, Juvenile = 0.7, Adult = 1.0 }, Lore = "บินตามดวงอาทิตย์ไม่เคยหยุดพัก", Clues = { "ขนไฟที่ไม่ไหม้มือ" } },
	{ Id = "aqua_serpent", Name = "Aqua Serpent", ThaiName = "นาคาวารี", Phase = 3, Element = "Water", Rarity = "Epic", Zone = "CrystalCavern", ActiveTime = "Any", Personalities = { "Shy", "Solitary" }, Favorite = "pearl_kelp", Likes = { "pearl_kelp" }, Dislikes = { "ember_pepper" }, Speed = { Walk = 9, Run = 26 }, FleeDistance = 30, WanderRadius = 90, Habitat = "habitat_deep_pool", Ability = { Id = "TideCall", Name = "เรียกกระแสน้ำ", Description = "ยกระดับน้ำเปิดทางลับใต้ถ้ำ" }, Palette = { Primary = C(40, 120, 160), Secondary = C(120, 230, 220), Accent = C(230, 255, 250) }, Size = { Baby = 0.4, Juvenile = 0.7, Adult = 1.0 }, Lore = "อาศัยในทะเลสาบใต้ดินที่แสงคริสตัลส่องถึง", Clues = { "เกล็ดใสลอยบนผิวน้ำ" } },
	{ Id = "shadow_wolf", Name = "Shadow Wolf", ThaiName = "หมาป่าเงาราตรี", Phase = 3, Element = "Shadow", Rarity = "Epic", Zone = "FrostMountains", ActiveTime = "Night", Personalities = { "Solitary", "Shy" }, Favorite = "dusk_meat", Likes = { "dusk_meat" }, Dislikes = { "sun_nectar" }, Speed = { Walk = 11, Run = 32 }, FleeDistance = 38, WanderRadius = 150, Habitat = "habitat_shadow_den", Ability = { Id = "ShadowVeil", Name = "ม่านเงา", Description = "ซ่อนผู้ขี่จากสัตว์ขี้ตกใจชั่วครู่" }, Palette = { Primary = C(40, 40, 60), Secondary = C(110, 90, 180), Accent = C(190, 170, 255) }, Size = { Baby = 0.45, Juvenile = 0.72, Adult = 1.0 }, Lore = "เงาของมันเดินแยกจากตัวได้ในคืนพระจันทร์เต็มดวง", Clues = { "รอยเท้าที่ไม่มีเงา" } },
}

Species.ById = {}
for _, s in Species.List do
	Species.ById[s.Id] = s
end

function Species.IsEnabled(id, currentPhase)
	local s = Species.ById[id]
	return s ~= nil and s.Phase <= (currentPhase or 1)
end

return Species
