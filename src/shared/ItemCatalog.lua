--[[
	ItemCatalog v2 — ไอเท็มทั้งหมด จัดเป็น "เซ็ตธีม" (ใส่ครบเซ็ต = ได้คะแนนธีมในแฟชั่นโชว์)

	ฟิลด์หลัก:
		Id, Name, Description, Category, Rarity, Price, Currency("Coins"|"Gems"), Icon, Colors
		Set        : Id ของเซ็ต (ดู ItemCatalog.Sets)
		Style      : รูปทรง (หมวก/ปีก/สัตว์เลี้ยง/ออร่า/หาง)
		Exclusive  : "VIP" | "PartyPass" | "Starter" | "Achievement" (ซื้อตรงไม่ได้)
		Requirement: { Stat = "Wins", Value = 10 } สำหรับ Achievement
		Rainbow    : true = เปลี่ยนสีวนสายรุ้ง
		Text       : ข้อความของฉายา (Title)
]]

local ItemCatalog = {}

ItemCatalog.Categories = {
	{ Id = "Skin", Name = "สกิน", Icon = "🎨" },
	{ Id = "Hat", Name = "หมวก", Icon = "🎩" },
	{ Id = "Wings", Name = "ปีก", Icon = "🪽" },
	{ Id = "Pet", Name = "สัตว์เลี้ยง", Icon = "🐾" },
	{ Id = "Trail", Name = "หางวิ้ง", Icon = "☄️" },
	{ Id = "Aura", Name = "ออร่า", Icon = "✨" },
	{ Id = "Title", Name = "ฉายา", Icon = "🏷️" },
}

ItemCatalog.Rarities = {
	Common = { Name = "ธรรมดา", Color = Color3.fromRGB(150, 165, 180), Order = 1 },
	Rare = { Name = "หายาก", Color = Color3.fromRGB(60, 150, 255), Order = 2 },
	Epic = { Name = "มหากาพย์", Color = Color3.fromRGB(165, 85, 255), Order = 3 },
	Legendary = { Name = "ตำนาน", Color = Color3.fromRGB(255, 170, 20), Order = 4 },
	Mythic = { Name = "เทพนิยาย", Color = Color3.fromRGB(255, 70, 150), Order = 5 },
}

local C = Color3.fromRGB

ItemCatalog.Sets = {
	{ Id = "Candy", Name = "แคนดี้ป๊อป", Icon = "🍭", Colors = { C(255, 140, 200), C(140, 235, 220) } },
	{ Id = "Ocean", Name = "โอเชียนดรีม", Icon = "🌊", Colors = { C(50, 160, 255), C(140, 240, 255) } },
	{ Id = "Space", Name = "นักบินอวกาศ", Icon = "🚀", Colors = { C(40, 50, 120), C(120, 200, 255) } },
	{ Id = "Spooky", Name = "ผีน้อยน่ารัก", Icon = "🎃", Colors = { C(120, 60, 200), C(255, 150, 40) } },
	{ Id = "Fairy", Name = "สวนนางฟ้า", Icon = "🧚", Colors = { C(255, 170, 220), C(160, 255, 190) } },
	{ Id = "Cyber", Name = "นีออนไซเบอร์", Icon = "🤖", Colors = { C(20, 20, 40), C(0, 255, 230) } },
	{ Id = "Royal", Name = "ราชวงศ์ทองคำ", Icon = "👑", Colors = { C(255, 200, 50), C(200, 30, 90) } },
	{ Id = "Rainbow", Name = "ความฝันสายรุ้ง", Icon = "🌈", Colors = { C(255, 90, 90), C(90, 160, 255) } },
}

local items = {
	-- ================= พื้นฐาน =================
	{ Id = "skin_classic", Name = "ตัวเดิมของฉัน", Description = "อวตารของคุณเอง ไม่เปลี่ยนแปลง", Category = "Skin", Rarity = "Common", Price = 0, Currency = "Coins", Icon = "🙂", Default = true, Colors = { C(255, 214, 170) } },
	{ Id = "skin_strawberry", Name = "สตรอว์เบอร์รี่", Description = "หวานอมเปรี้ยว สดชื่นทั้งวัน", Category = "Skin", Rarity = "Common", Price = 200, Currency = "Coins", Icon = "🍓", Colors = { C(255, 95, 125), C(255, 190, 205), C(110, 200, 90) } },
	{ Id = "skin_mint", Name = "มินต์ช็อกชิป", Description = "เย็นซ่าแบบไอศกรีม", Category = "Skin", Rarity = "Common", Price = 250, Currency = "Coins", Icon = "🍦", Colors = { C(150, 235, 200), C(110, 75, 55) } },
	{ Id = "hat_party", Name = "หมวกปาร์ตี้", Description = "พร้อมปาร์ตี้ทุกเมื่อ!", Category = "Hat", Rarity = "Common", Price = 80, Currency = "Coins", Icon = "🥳", Style = "PartyCone", Colors = { C(255, 100, 180), C(255, 230, 80) } },
	{ Id = "hat_cat", Name = "หูแมวเหมียว", Description = "เมี๊ยว~ น่ารักเกินต้าน", Category = "Hat", Rarity = "Common", Price = 150, Currency = "Coins", Icon = "🐱", Style = "CatEars", Colors = { C(255, 165, 110), C(255, 200, 220) } },
	{ Id = "hat_propeller", Name = "หมวกใบพัด", Description = "ใบพัดหมุนติ้ว ๆ ตลอดเวลา", Category = "Hat", Rarity = "Rare", Price = 600, Currency = "Coins", Icon = "🚁", Style = "Propeller", Colors = { C(255, 60, 60), C(60, 140, 255), C(255, 220, 40) } },
	{ Id = "wings_paper", Name = "ปีกกระดาษ", Description = "ปีกคู่แรกของนักบินตัวน้อย", Category = "Wings", Rarity = "Common", Price = 400, Currency = "Coins", Icon = "📄", Style = "Butterfly", Colors = { C(250, 250, 255), C(200, 210, 230) } },
	{ Id = "pet_slime", Name = "สไลม์ดุ๊กดิ๊ก", Description = "เพื่อนซี้ตัวกลม ตามติดทุกที่", Category = "Pet", Rarity = "Common", Price = 250, Currency = "Coins", Icon = "🟢", Style = "Ball", Colors = { C(120, 230, 120) } },
	{ Id = "trail_basic", Name = "สายลมเย็น", Description = "หางลมพลิ้วไหวเบา ๆ", Category = "Trail", Rarity = "Common", Price = 100, Currency = "Coins", Icon = "💨", Colors = { C(255, 255, 255), C(170, 220, 255) } },
	{ Id = "aura_sparkle", Name = "ประกายดาว", Description = "ระยิบระยับรอบตัว", Category = "Aura", Rarity = "Common", Price = 200, Currency = "Coins", Icon = "⭐", Style = "Particles", Preset = "Rise", Colors = { C(255, 255, 180) } },

	-- ================= 🍭 แคนดี้ป๊อป =================
	{ Id = "skin_candy", Set = "Candy", Name = "ลูกอมหลากสี", Description = "หวานหลายรส ในตัวเดียว", Category = "Skin", Rarity = "Common", Price = 300, Currency = "Coins", Icon = "🍬", Colors = { C(255, 150, 210), C(140, 235, 220), C(255, 235, 130) } },
	{ Id = "hat_bow", Set = "Candy", Name = "โบว์ยักษ์", Description = "โบว์โตสุดคิ้วท์", Category = "Hat", Rarity = "Common", Price = 250, Currency = "Coins", Icon = "🎀", Style = "Bow", Colors = { C(255, 110, 180), C(255, 230, 240) } },
	{ Id = "wings_candy", Set = "Candy", Name = "ปีกผีเสื้อลูกกวาด", Description = "ปีกพาสเทลกระพือได้จริง", Category = "Wings", Rarity = "Rare", Price = 900, Currency = "Coins", Icon = "🦋", Style = "Butterfly", Colors = { C(255, 150, 210), C(140, 235, 220) } },
	{ Id = "trail_candy", Set = "Candy", Name = "สายไหม", Description = "ทิ้งความหวานไว้ทุกทาง", Category = "Trail", Rarity = "Common", Price = 300, Currency = "Coins", Icon = "🍭", Colors = { C(255, 130, 200), C(130, 220, 255) } },
	{ Id = "pet_gummy", Set = "Candy", Name = "หมีกัมมี่", Description = "หมีเยลลี่ใส ๆ เด้งดึ๋ง", Category = "Pet", Rarity = "Rare", Price = 800, Currency = "Coins", Icon = "🐻", Style = "Bear", Colors = { C(255, 80, 110) } },
	{ Id = "aura_sprinkle", Set = "Candy", Name = "เม็ดสีโปรยปราย", Description = "ปาร์ตี้สีรุ้งตลอดเวลา", Category = "Aura", Rarity = "Rare", Price = 600, Currency = "Coins", Icon = "🎊", Style = "Particles", Preset = "Burst", Colors = { C(255, 120, 200), C(120, 220, 255), C(255, 235, 100) } },

	-- ================= 🌊 โอเชียนดรีม =================
	{ Id = "skin_ocean", Set = "Ocean", Name = "คลื่นทะเลใส", Description = "สีฟ้าครามสดใส", Category = "Skin", Rarity = "Rare", Price = 700, Currency = "Coins", Icon = "🌊", Colors = { C(50, 160, 255), C(130, 225, 255), C(30, 100, 200) } },
	{ Id = "hat_tiara_sea", Set = "Ocean", Name = "มงกุฎเปลือกหอย", Description = "ประดับไข่มุกจากใต้ทะเล", Category = "Hat", Rarity = "Rare", Price = 800, Currency = "Coins", Icon = "🐚", Style = "Tiara", Colors = { C(140, 240, 255), C(255, 250, 240) } },
	{ Id = "wings_fin", Set = "Ocean", Name = "ครีบนางเงือก", Description = "ครีบใสเรืองแสงแบบโลมา", Category = "Wings", Rarity = "Rare", Price = 1200, Currency = "Coins", Icon = "🐬", Style = "Fin", Colors = { C(80, 200, 255), C(180, 250, 255) } },
	{ Id = "trail_bubble", Set = "Ocean", Name = "ฟองสบู่", Description = "ฟองลอยฟุ้งตามหลัง", Category = "Trail", Rarity = "Rare", Price = 600, Currency = "Coins", Icon = "🫧", Style = "Sparkle", Colors = { C(180, 235, 255), C(255, 255, 255) } },
	{ Id = "pet_fish", Set = "Ocean", Name = "ปลาน้อยนีโม่จัง", Description = "ว่ายในอากาศได้ด้วย!", Category = "Pet", Rarity = "Rare", Price = 1000, Currency = "Coins", Icon = "🐠", Style = "Fish", Colors = { C(255, 140, 40), C(255, 255, 255) } },
	{ Id = "aura_bubbles", Set = "Ocean", Name = "ฟองน้ำลอยขึ้น", Description = "เหมือนอยู่ใต้ทะเล", Category = "Aura", Rarity = "Rare", Price = 800, Currency = "Coins", Icon = "💧", Style = "Particles", Preset = "Rise", Colors = { C(150, 220, 255), C(220, 250, 255) } },

	-- ================= 🚀 นักบินอวกาศ =================
	{ Id = "skin_astro", Set = "Space", Name = "ชุดนักบินอวกาศ", Description = "พร้อมออกสำรวจจักรวาล", Category = "Skin", Rarity = "Epic", Price = 2000, Currency = "Coins", Icon = "🧑‍🚀", Colors = { C(240, 240, 250), C(60, 90, 200), C(200, 205, 215) }, Material = "SmoothPlastic", Reflectance = 0.1 },
	{ Id = "hat_helmet", Set = "Space", Name = "หมวกอวกาศ", Description = "โดมกระจกใส มีไฟสัญญาณ", Category = "Hat", Rarity = "Epic", Price = 1800, Currency = "Coins", Icon = "🪐", Style = "Helmet", Colors = { C(240, 240, 250), C(120, 200, 255) } },
	{ Id = "wings_jetpack", Set = "Space", Name = "เจ็ตแพ็กไอพ่น", Description = "ไอพ่นพ่นไฟของจริง!", Category = "Wings", Rarity = "Epic", Price = 2800, Currency = "Coins", Icon = "🚀", Style = "Jetpack", Colors = { C(220, 225, 235), C(255, 80, 60) } },
	{ Id = "trail_comet", Set = "Space", Name = "หางดาวหาง", Description = "พุ่งแรงเหมือนดาวตก", Category = "Trail", Rarity = "Epic", Price = 2000, Currency = "Coins", Icon = "🌠", Style = "Sparkle", Colors = { C(120, 60, 255), C(20, 200, 255), C(255, 255, 255) } },
	{ Id = "pet_ufo", Set = "Space", Name = "จานบินจิ๋ว", Description = "มนุษย์ต่างดาวขี้เล่นขับมาเอง", Category = "Pet", Rarity = "Epic", Price = 2500, Currency = "Coins", Icon = "🛸", Style = "Ufo", Colors = { C(170, 180, 200), C(120, 255, 200) } },
	{ Id = "aura_planets", Set = "Space", Name = "ระบบสุริยะส่วนตัว", Description = "ดาวเคราะห์โคจรรอบตัวคุณ", Category = "Aura", Rarity = "Epic", Price = 3000, Currency = "Coins", Icon = "🌍", Style = "Orbit", Shape = "Planet", Colors = { C(255, 170, 60), C(90, 180, 255), C(200, 120, 255) } },

	-- ================= 🎃 ผีน้อยน่ารัก =================
	{ Id = "skin_ghostly", Set = "Spooky", Name = "ผีน้อยโปร่งแสง", Description = "ตัวใส ๆ ขี้อายนิดหน่อย", Category = "Skin", Rarity = "Epic", Price = 2000, Currency = "Coins", Icon = "👻", Colors = { C(235, 240, 255), C(200, 190, 255) }, Transparency = 0.3, Glow = true },
	{ Id = "hat_witch", Set = "Spooky", Name = "หมวกแม่มดน้อย", Description = "มีดาวเวทมนตร์ห้อยปลาย", Category = "Hat", Rarity = "Epic", Price = 1800, Currency = "Coins", Icon = "🧙", Style = "WitchHat", Colors = { C(90, 40, 150), C(255, 150, 40) } },
	{ Id = "wings_bat", Set = "Spooky", Name = "ปีกค้างคาว", Description = "กระพือแบบค้างคาวน้อย", Category = "Wings", Rarity = "Epic", Price = 2600, Currency = "Coins", Icon = "🦇", Style = "Bat", Colors = { C(60, 30, 90), C(170, 90, 255) } },
	{ Id = "trail_spooky", Set = "Spooky", Name = "ควันวิญญาณ", Description = "ม่วงอมเขียวน่าขนลุก(นิดนึง)", Category = "Trail", Rarity = "Epic", Price = 1800, Currency = "Coins", Icon = "🕸️", Style = "Wide", Colors = { C(150, 60, 255), C(80, 255, 140) } },
	{ Id = "pet_pumpkin", Set = "Spooky", Name = "ฟักทองยิ้มแฉ่ง", Description = "จุดไฟในหัวได้ด้วย", Category = "Pet", Rarity = "Epic", Price = 2400, Currency = "Coins", Icon = "🎃", Style = "Pumpkin", Colors = { C(255, 140, 30), C(60, 140, 50) } },
	{ Id = "aura_spirit", Set = "Spooky", Name = "ไฟวิญญาณ", Description = "ดวงไฟลอยวนรอบตัว", Category = "Aura", Rarity = "Epic", Price = 2800, Currency = "Coins", Icon = "🕯️", Style = "Orbit", Shape = "Wisp", Colors = { C(170, 255, 200), C(180, 120, 255) } },

	-- ================= 🧚 สวนนางฟ้า =================
	{ Id = "skin_fairy", Set = "Fairy", Name = "นางฟ้าดอกไม้", Description = "ผิวเรืองแสงอ่อน ๆ เหมือนแสงจันทร์", Category = "Skin", Rarity = "Legendary", Price = 80, Currency = "Gems", Icon = "🧚", Colors = { C(255, 210, 235), C(180, 255, 210), C(255, 240, 180) }, Glow = true },
	{ Id = "hat_flowercrown", Set = "Fairy", Name = "มงกุฎดอกไม้", Description = "ดอกไม้บานรอบศีรษะ", Category = "Hat", Rarity = "Legendary", Price = 70, Currency = "Gems", Icon = "🌸", Style = "FlowerCrown", Colors = { C(255, 150, 210), C(255, 240, 120), C(120, 210, 120) } },
	{ Id = "wings_fairy", Set = "Fairy", Name = "ปีกนางฟ้า", Description = "ปีกใสเรืองแสง 4 แฉก", Category = "Wings", Rarity = "Legendary", Price = 120, Currency = "Gems", Icon = "🧚‍♀️", Style = "Fairy", Colors = { C(255, 190, 240), C(170, 255, 230) } },
	{ Id = "trail_petal", Set = "Fairy", Name = "กลีบดอกไม้", Description = "ทิ้งกลีบซากุระตามทาง", Category = "Trail", Rarity = "Legendary", Price = 70, Currency = "Gems", Icon = "🌷", Style = "Sparkle", Colors = { C(255, 170, 220), C(180, 255, 200) } },
	{ Id = "pet_bunny", Set = "Fairy", Name = "กระต่ายวิเศษ", Description = "กระต่ายขาวหูยาวสุดนุ่ม", Category = "Pet", Rarity = "Legendary", Price = 110, Currency = "Gems", Icon = "🐰", Style = "Bunny", Colors = { C(255, 255, 255), C(255, 180, 210) } },
	{ Id = "aura_fairydust", Set = "Fairy", Name = "ผงวิเศษ", Description = "ฝุ่นนางฟ้าสีทองชมพู", Category = "Aura", Rarity = "Legendary", Price = 90, Currency = "Gems", Icon = "✨", Style = "Particles", Preset = "Rise", Colors = { C(255, 220, 120), C(255, 150, 220) } },

	-- ================= 🤖 นีออนไซเบอร์ =================
	{ Id = "skin_cyber", Set = "Cyber", Name = "ไซบอร์กนีออน", Description = "ตัวดำ แขนขาเรืองแสงนีออน", Category = "Skin", Rarity = "Legendary", Price = 90, Currency = "Gems", Icon = "🦾", Colors = { C(25, 25, 40), C(0, 255, 230), C(255, 40, 200) }, LimbMaterial = "Neon" },
	{ Id = "hat_headphones", Set = "Cyber", Name = "หูฟังเกมเมอร์", Description = "ไฟ RGB กะพริบเท่ ๆ", Category = "Hat", Rarity = "Legendary", Price = 70, Currency = "Gems", Icon = "🎧", Style = "Headphones", Colors = { C(30, 30, 45), C(0, 255, 230) } },
	{ Id = "wings_mech", Set = "Cyber", Name = "ปีกจักรกล", Description = "ใบมีดเลเซอร์ 6 แฉก", Category = "Wings", Rarity = "Legendary", Price = 130, Currency = "Gems", Icon = "⚙️", Style = "Mech", Colors = { C(40, 40, 55), C(0, 255, 230) } },
	{ Id = "trail_neon", Set = "Cyber", Name = "เลเซอร์คู่", Description = "เส้นแสงนีออนกว้างสะใจ", Category = "Trail", Rarity = "Legendary", Price = 80, Currency = "Gems", Icon = "⚡", Style = "Wide", Colors = { C(0, 255, 230), C(255, 40, 200) } },
	{ Id = "pet_robot", Set = "Cyber", Name = "บอทจิ๋ว B-0", Description = "หุ่นยนต์ตาจอ LED", Category = "Pet", Rarity = "Legendary", Price = 120, Currency = "Gems", Icon = "🤖", Style = "Robot", Colors = { C(200, 205, 220), C(0, 255, 230) } },
	{ Id = "aura_cubes", Set = "Cyber", Name = "ข้อมูลดิจิทัล", Description = "คิวบ์นีออนลอยวนรอบตัว", Category = "Aura", Rarity = "Legendary", Price = 100, Currency = "Gems", Icon = "🧊", Style = "Orbit", Shape = "Cube", Colors = { C(0, 255, 230), C(255, 40, 200) } },

	-- ================= 👑 ราชวงศ์ทองคำ =================
	{ Id = "skin_royal", Set = "Royal", Name = "เชื้อพระวงศ์", Description = "ทองคำแท้ประกายวิบวับ", Category = "Skin", Rarity = "Mythic", Price = 200, Currency = "Gems", Icon = "🏆", Colors = { C(255, 205, 60), C(255, 250, 235), C(200, 30, 90) }, Material = "Metal", Reflectance = 0.2 },
	{ Id = "hat_crown", Set = "Royal", Name = "มงกุฎเพชร", Description = "มงกุฎทองฝังอัญมณี", Category = "Hat", Rarity = "Mythic", Price = 160, Currency = "Gems", Icon = "👑", Style = "Crown", Colors = { C(255, 200, 40), C(230, 40, 130) } },
	{ Id = "wings_angel_gold", Set = "Royal", Name = "ปีกเทวดาทองคำ", Description = "ขนนกทองคำ 14 เส้น", Category = "Wings", Rarity = "Mythic", Price = 250, Currency = "Gems", Icon = "🪽", Style = "Angel", Colors = { C(255, 210, 70), C(255, 245, 200) }, Material = "Metal" },
	{ Id = "trail_gold", Set = "Royal", Name = "ประกายทองคำ", Description = "ทิ้งเกล็ดทองตามรอยเท้า", Category = "Trail", Rarity = "Mythic", Price = 150, Currency = "Gems", Icon = "💫", Style = "Sparkle", Colors = { C(255, 245, 160), C(255, 180, 0) } },
	{ Id = "pet_dragon", Set = "Royal", Name = "มังกรน้อยทองคำ", Description = "มังกรประจำราชวงศ์ กระพือปีกได้", Category = "Pet", Rarity = "Mythic", Price = 250, Currency = "Gems", Icon = "🐉", Style = "Dragon", Colors = { C(255, 200, 50), C(200, 30, 90) }, Material = "Metal" },
	{ Id = "aura_royal", Set = "Royal", Name = "อัญมณีราชินี", Description = "เพชรลอยวนพร้อมแสงทอง", Category = "Aura", Rarity = "Mythic", Price = 220, Currency = "Gems", Icon = "💠", Style = "Orbit", Shape = "Gem", Colors = { C(255, 210, 60), C(255, 90, 170) } },

	-- ================= 🌈 ความฝันสายรุ้ง (Party Pass) =================
	{ Id = "skin_rainbow", Set = "Rainbow", Exclusive = "PartyPass", Name = "สายรุ้งวิบวับ", Description = "เปลี่ยนสีวนตลอดเวลา", Category = "Skin", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "🌈", Rainbow = true, Glow = true, Colors = { C(255, 80, 80), C(80, 200, 255), C(255, 230, 60) } },
	{ Id = "hat_rainbow_halo", Set = "Rainbow", Exclusive = "PartyPass", Name = "วงแหวนสายรุ้ง", Description = "รัศมีเทพสีรุ้ง", Category = "Hat", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "😇", Style = "Halo", Rainbow = true, Colors = { C(255, 120, 200) } },
	{ Id = "wings_rainbow", Set = "Rainbow", Exclusive = "PartyPass", Name = "ปีกสายรุ้ง", Description = "ปีกเทวดาเปลี่ยนสีได้", Category = "Wings", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "🕊️", Style = "Angel", Rainbow = true, Colors = { C(255, 120, 200), C(120, 200, 255) }, Material = "Neon" },
	{ Id = "trail_rainbow", Set = "Rainbow", Exclusive = "PartyPass", Name = "สายรุ้งพาดฟ้า", Description = "หางสายรุ้งเต็มสเปกตรัม", Category = "Trail", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "🌈", Style = "Wide", Rainbow = true, Colors = { C(255, 80, 80), C(80, 255, 120), C(80, 140, 255) } },
	{ Id = "pet_unicorn", Set = "Rainbow", Exclusive = "PartyPass", Name = "ยูนิคอร์นจิ๋ว", Description = "เขาสายรุ้งเรืองแสง", Category = "Pet", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "🦄", Style = "Unicorn", Colors = { C(255, 255, 255), C(255, 150, 220) } },
	{ Id = "aura_rainbow", Set = "Rainbow", Exclusive = "PartyPass", Name = "ดาวรุ้งโคจร", Description = "ดาวหลากสีวนรอบตัว", Category = "Aura", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "🌟", Style = "Orbit", Shape = "Ball", Rainbow = true, Colors = { C(255, 120, 200), C(120, 200, 255) } },

	-- ================= 👑 VIP =================
	{ Id = "skin_vip", Exclusive = "VIP", Name = "ราชาปาร์ตี้", Description = "สกินพิเศษสำหรับ VIP", Category = "Skin", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "🤴", Colors = { C(255, 210, 40), C(190, 20, 90), C(255, 245, 200) }, Material = "Metal", Reflectance = 0.15 },
	{ Id = "wings_vip", Exclusive = "VIP", Name = "ปีกฟีนิกซ์", Description = "ปีกนกไฟสำหรับ VIP", Category = "Wings", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "🔥", Style = "Angel", Fire = true, Colors = { C(255, 120, 30), C(255, 230, 80) }, Material = "Neon" },
	{ Id = "aura_vip", Exclusive = "VIP", Name = "ประกาย VIP", Description = "แสงทองแห่ง VIP", Category = "Aura", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "💫", Style = "Sparkles", Colors = { C(255, 215, 0) } },

	-- ================= 🚀 Starter Pack =================
	{ Id = "pet_chick", Exclusive = "Starter", Name = "ลูกเจี๊ยบเริ่มต้น", Description = "จาก Starter Pack เท่านั้น", Category = "Pet", Rarity = "Epic", Price = 0, Currency = "Gems", Icon = "🐥", Style = "Ball", Beak = true, Colors = { C(255, 225, 70) } },
	{ Id = "trail_starter", Exclusive = "Starter", Name = "แสงแรกของวัน", Description = "จาก Starter Pack เท่านั้น", Category = "Trail", Rarity = "Epic", Price = 0, Currency = "Gems", Icon = "🌅", Style = "Sparkle", Colors = { C(255, 200, 80), C(255, 120, 160) } },

	-- ================= 🏷️ ฉายา =================
	{ Id = "title_cute", Name = "น่ารักที่สุด", Text = "✨ น่ารักที่สุด ✨", Description = "ฉายาลอยเหนือหัว", Category = "Title", Rarity = "Common", Price = 500, Currency = "Coins", Icon = "✨", Colors = { C(255, 170, 220), C(255, 255, 255) } },
	{ Id = "title_cool", Name = "สายชิล", Text = "😎 สายชิล", Description = "ฉายาลอยเหนือหัว", Category = "Title", Rarity = "Rare", Price = 1500, Currency = "Coins", Icon = "😎", Colors = { C(90, 200, 255), C(160, 255, 220) } },
	{ Id = "title_star", Name = "ซุปตาร์", Text = "⭐ ซุปตาร์ ⭐", Description = "ฉายาลอยเหนือหัว", Category = "Title", Rarity = "Epic", Price = 4000, Currency = "Coins", Icon = "⭐", Colors = { C(255, 220, 80), C(255, 120, 200) } },
	{ Id = "title_legend", Name = "ตำนานแฟชั่น", Text = "🔥 ตำนานแฟชั่น 🔥", Description = "ฉายาลอยเหนือหัว", Category = "Title", Rarity = "Legendary", Price = 120, Currency = "Gems", Icon = "🔥", Colors = { C(255, 200, 40), C(255, 80, 40) } },
	{ Id = "title_rich", Name = "เศรษฐีปาร์ตี้", Text = "💎 เศรษฐีปาร์ตี้ 💎", Description = "ฉายาเปลี่ยนสีสายรุ้ง", Category = "Title", Rarity = "Mythic", Price = 300, Currency = "Gems", Icon = "💎", Rainbow = true, Colors = { C(255, 120, 200), C(120, 200, 255) } },
	{ Id = "title_newbie", Exclusive = "Achievement", Name = "มือใหม่ไฟแรง", Text = "🌱 มือใหม่ไฟแรง", Description = "ทำภารกิจมือใหม่ครบ", Category = "Title", Rarity = "Common", Price = 0, Currency = "Coins", Icon = "🌱", Colors = { C(140, 230, 120), C(220, 255, 180) } },
	{ Id = "title_champion", Exclusive = "Achievement", Requirement = { Stat = "Wins", Value = 10, Text = "ชนะพื้นสี" }, Name = "แชมป์พื้นสี", Text = "🏆 แชมป์พื้นสี", Description = "ชนะมินิเกมพื้นสี 10 ครั้ง", Category = "Title", Rarity = "Epic", Price = 0, Currency = "Coins", Icon = "🏆", Colors = { C(255, 210, 60), C(255, 140, 40) } },
	{ Id = "title_runway", Exclusive = "Achievement", Requirement = { Stat = "ShowdownWins", Value = 3, Text = "ชนะแฟชั่นโชว์" }, Name = "ดาวรันเวย์", Text = "💃 ดาวรันเวย์", Description = "ได้ที่ 1 แฟชั่นโชว์ 3 ครั้ง", Category = "Title", Rarity = "Legendary", Price = 0, Currency = "Coins", Icon = "💃", Colors = { C(255, 100, 180), C(200, 120, 255) } },
	{ Id = "title_collector", Exclusive = "Achievement", Requirement = { Stat = "Stars", Value = 1000, Text = "เก็บดาว" }, Name = "นักล่าดาว", Text = "🌟 นักล่าดาว", Description = "เก็บดาว 1,000 ดวง", Category = "Title", Rarity = "Epic", Price = 0, Currency = "Coins", Icon = "🌟", Colors = { C(255, 235, 100), C(255, 180, 60) } },
	{ Id = "title_pass", Exclusive = "PartyPass", Name = "ปาร์ตี้สตาร์", Text = "🎫 ปาร์ตี้สตาร์ S1", Description = "รางวัล Party Pass ขั้น 30", Category = "Title", Rarity = "Legendary", Price = 0, Currency = "Coins", Icon = "🎫", Colors = { C(255, 120, 200), C(255, 220, 90) } },
	{ Id = "title_vip", Exclusive = "VIP", Name = "VIP", Text = "👑 VIP", Description = "ฉายาสำหรับ VIP", Category = "Title", Rarity = "Mythic", Price = 0, Currency = "Coins", Icon = "👑", Colors = { C(255, 215, 40), C(255, 160, 20) } },
	{ Id = "title_starter", Exclusive = "Starter", Name = "ผู้บุกเบิก", Text = "🚀 ผู้บุกเบิก", Description = "จาก Starter Pack เท่านั้น", Category = "Title", Rarity = "Epic", Price = 0, Currency = "Coins", Icon = "🚀", Colors = { C(120, 200, 255), C(255, 200, 80) } },
}

ItemCatalog.List = items
ItemCatalog.ById = {}
ItemCatalog.CategoryById = {}
ItemCatalog.SetById = {}

for _, category in ItemCatalog.Categories do
	ItemCatalog.CategoryById[category.Id] = category
end
for _, set in ItemCatalog.Sets do
	ItemCatalog.SetById[set.Id] = set
end

for _, item in items do
	assert(ItemCatalog.ById[item.Id] == nil, "Duplicate item id: " .. item.Id)
	assert(ItemCatalog.CategoryById[item.Category], "Unknown category for " .. item.Id)
	assert(ItemCatalog.Rarities[item.Rarity], "Unknown rarity for " .. item.Id)
	assert(item.Set == nil or ItemCatalog.SetById[item.Set], "Unknown set for " .. item.Id)
	ItemCatalog.ById[item.Id] = item
end

local function sortItems(a, b)
	local ra, rb = ItemCatalog.Rarities[a.Rarity].Order, ItemCatalog.Rarities[b.Rarity].Order
	if ra ~= rb then
		return ra < rb
	end
	if a.Currency ~= b.Currency then
		return a.Currency == "Coins"
	end
	if a.Price ~= b.Price then
		return a.Price < b.Price
	end
	return a.Id < b.Id
end

function ItemCatalog.Sort(list)
	table.sort(list, sortItems)
	return list
end

function ItemCatalog.GetByCategory(categoryId)
	local result = {}
	for _, item in items do
		if item.Category == categoryId then
			table.insert(result, item)
		end
	end
	return ItemCatalog.Sort(result)
end

local CATEGORY_ORDER = {}
for i, category in ItemCatalog.Categories do
	CATEGORY_ORDER[category.Id] = i
end

function ItemCatalog.GetBySet(setId)
	local result = {}
	for _, item in items do
		if item.Set == setId then
			table.insert(result, item)
		end
	end
	table.sort(result, function(a, b)
		return CATEGORY_ORDER[a.Category] < CATEGORY_ORDER[b.Category]
	end)
	return result
end

-- มูลค่าเต็มของเซ็ต (ใช้แสดง "ประหยัด X%" ของ Bundle)
function ItemCatalog.GetSetValue(setId)
	local coins, gems = 0, 0
	for _, item in ItemCatalog.GetBySet(setId) do
		if item.Currency == "Gems" then
			gems += item.Price
		else
			coins += item.Price
		end
	end
	return coins, gems
end

function ItemCatalog.CanBuyDirectly(item)
	return item.Exclusive == nil and item.Price > 0
end

-- ColorSequence สำหรับ UI gradient / Trail
function ItemCatalog.GetColorSequence(item)
	if item.Rainbow then
		local keys = {}
		for i = 0, 6 do
			table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.75, 1)))
		end
		return ColorSequence.new(keys)
	end
	local colors = item.Colors or { Color3.new(1, 1, 1) }
	if #colors == 1 then
		return ColorSequence.new(colors[1])
	end
	local keys = {}
	for i, color in colors do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color))
	end
	return ColorSequence.new(keys)
end

return ItemCatalog
