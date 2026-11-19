--[[
	ItemCatalog — รายการไอเท็ม/สกินทั้งหมดในเกม
	เพิ่มไอเท็มใหม่ได้โดยเพิ่มแถวในตาราง `items` ด้านล่าง

	ฟิลด์:
		Id        : string ไม่ซ้ำกัน
		Name      : ชื่อที่แสดง
		Category  : "Skin" | "Hat" | "Trail" | "Pet" | "Aura"
		Rarity    : "Common" | "Rare" | "Epic" | "Legendary" | "Mythic"
		Price     : ราคา (0 = ฟรี/ได้จากที่อื่น)
		Currency  : "Coins" (หาได้ในเกม) | "Gems" (เติมด้วย Robux หรือรางวัล)
		Icon      : อีโมจิที่แสดงในร้าน
		Colors    : สีหลักของไอเท็ม (Color3)
		Style     : รูปทรง (ใช้กับ Hat / Pet / Aura)
		Material  : วัสดุของสกิน (ชื่อ Enum.Material)
		Rainbow   : true = เปลี่ยนสีวนสายรุ้ง
		Default   : true = ทุกคนมีตั้งแต่เริ่ม
		Exclusive : "VIP" = ได้จาก Game Pass เท่านั้น
]]

local ItemCatalog = {}

ItemCatalog.Categories = {
	{ Id = "Skin", Name = "สกินตัวละคร", Icon = "🎨" },
	{ Id = "Hat", Name = "หมวก", Icon = "🎩" },
	{ Id = "Trail", Name = "หางวิ้ง", Icon = "🌈" },
	{ Id = "Pet", Name = "สัตว์เลี้ยง", Icon = "🐾" },
	{ Id = "Aura", Name = "ออร่า", Icon = "✨" },
}

ItemCatalog.Rarities = {
	Common = { Name = "ธรรมดา", Color = Color3.fromRGB(150, 165, 180), Order = 1 },
	Rare = { Name = "หายาก", Color = Color3.fromRGB(60, 150, 255), Order = 2 },
	Epic = { Name = "มหากาพย์", Color = Color3.fromRGB(165, 85, 255), Order = 3 },
	Legendary = { Name = "ตำนาน", Color = Color3.fromRGB(255, 170, 20), Order = 4 },
	Mythic = { Name = "เทพนิยาย", Color = Color3.fromRGB(255, 70, 150), Order = 5 },
}

local C = Color3.fromRGB

local items = {
	-- ================= สกินตัวละคร =================
	{ Id = "skin_classic", Name = "ตัวเดิมของฉัน", Category = "Skin", Rarity = "Common", Price = 0, Currency = "Coins", Icon = "🙂", Default = true, Colors = { C(255, 214, 170) } },
	{ Id = "skin_strawberry", Name = "สตรอว์เบอร์รี่", Category = "Skin", Rarity = "Common", Price = 150, Currency = "Coins", Icon = "🍓", Colors = { C(255, 110, 140), C(255, 190, 205), C(120, 200, 90) } },
	{ Id = "skin_banana", Name = "กล้วยหอม", Category = "Skin", Rarity = "Common", Price = 200, Currency = "Coins", Icon = "🍌", Colors = { C(255, 228, 90), C(255, 240, 160) } },
	{ Id = "skin_mint", Name = "มินต์ช็อกชิป", Category = "Skin", Rarity = "Common", Price = 250, Currency = "Coins", Icon = "🍦", Colors = { C(150, 235, 200), C(110, 75, 55) } },
	{ Id = "skin_ocean", Name = "ทะเลใส", Category = "Skin", Rarity = "Rare", Price = 400, Currency = "Coins", Icon = "🌊", Colors = { C(60, 165, 255), C(130, 220, 255), C(30, 110, 200) } },
	{ Id = "skin_grape", Name = "องุ่นเปรี้ยว", Category = "Skin", Rarity = "Rare", Price = 450, Currency = "Coins", Icon = "🍇", Colors = { C(150, 90, 220), C(195, 145, 255) } },
	{ Id = "skin_robot", Name = "หุ่นยนต์จิ๋ว", Category = "Skin", Rarity = "Epic", Price = 1200, Currency = "Coins", Icon = "🤖", Colors = { C(175, 185, 195), C(95, 105, 120), C(60, 200, 255) }, Material = "DiamondPlate" },
	{ Id = "skin_ice", Name = "เจ้าหญิงน้ำแข็ง", Category = "Skin", Rarity = "Epic", Price = 1300, Currency = "Coins", Icon = "❄️", Colors = { C(205, 240, 255), C(160, 215, 255) }, Material = "Ice" },
	{ Id = "skin_lava", Name = "ลาวาเดือด", Category = "Skin", Rarity = "Epic", Price = 1500, Currency = "Coins", Icon = "🌋", Colors = { C(255, 95, 25), C(255, 175, 40), C(80, 30, 20) }, Material = "Neon" },
	{ Id = "skin_gold", Name = "ทองคำแท้", Category = "Skin", Rarity = "Legendary", Price = 60, Currency = "Gems", Icon = "🏆", Colors = { C(255, 200, 50) }, Material = "Metal", Reflectance = 0.25 },
	{ Id = "skin_galaxy", Name = "กาแล็กซี่", Category = "Skin", Rarity = "Legendary", Price = 80, Currency = "Gems", Icon = "🌌", Colors = { C(55, 25, 120), C(120, 60, 220), C(25, 140, 220) }, Material = "Neon" },
	{ Id = "skin_rainbow", Name = "สายรุ้งวิบวับ", Category = "Skin", Rarity = "Mythic", Price = 150, Currency = "Gems", Icon = "🌈", Rainbow = true, Colors = { C(255, 80, 80), C(80, 200, 255), C(255, 230, 60) } },
	{ Id = "skin_vip", Name = "ราชาปาร์ตี้", Category = "Skin", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "👑", Exclusive = "VIP", Colors = { C(255, 210, 40), C(190, 20, 90), C(255, 245, 200) }, Material = "Metal", Reflectance = 0.15 },

	-- ================= หมวก =================
	{ Id = "hat_party", Name = "หมวกปาร์ตี้", Category = "Hat", Rarity = "Common", Price = 100, Currency = "Coins", Icon = "🥳", Style = "PartyCone", Colors = { C(255, 100, 180), C(255, 230, 80) } },
	{ Id = "hat_cat", Name = "หูแมวเหมียว", Category = "Hat", Rarity = "Common", Price = 180, Currency = "Coins", Icon = "🐱", Style = "CatEars", Colors = { C(255, 165, 110), C(255, 200, 220) } },
	{ Id = "hat_flower", Name = "มงกุฎดอกไม้", Category = "Hat", Rarity = "Rare", Price = 300, Currency = "Coins", Icon = "🌸", Style = "Flower", Colors = { C(255, 140, 200), C(255, 230, 80) } },
	{ Id = "hat_bunny", Name = "หูกระต่ายน้อย", Category = "Hat", Rarity = "Rare", Price = 350, Currency = "Coins", Icon = "🐰", Style = "BunnyEars", Colors = { C(255, 255, 255), C(255, 175, 200) } },
	{ Id = "hat_antenna", Name = "เสาอากาศเอเลี่ยน", Category = "Hat", Rarity = "Rare", Price = 400, Currency = "Coins", Icon = "👽", Style = "Antenna", Colors = { C(90, 90, 100), C(80, 255, 120) } },
	{ Id = "hat_tophat", Name = "หมวกนักมายากล", Category = "Hat", Rarity = "Epic", Price = 900, Currency = "Coins", Icon = "🎩", Style = "TopHat", Colors = { C(40, 40, 50), C(220, 40, 60) } },
	{ Id = "hat_propeller", Name = "หมวกใบพัด", Category = "Hat", Rarity = "Epic", Price = 1100, Currency = "Coins", Icon = "🚁", Style = "Propeller", Colors = { C(255, 60, 60), C(60, 140, 255), C(255, 220, 40) } },
	{ Id = "hat_crown", Name = "มงกุฎเพชร", Category = "Hat", Rarity = "Legendary", Price = 50, Currency = "Gems", Icon = "👑", Style = "Crown", Colors = { C(255, 200, 40), C(230, 40, 130) } },
	{ Id = "hat_halo", Name = "วงแหวนนางฟ้า", Category = "Hat", Rarity = "Legendary", Price = 70, Currency = "Gems", Icon = "😇", Style = "Halo", Colors = { C(255, 250, 180) } },

	-- ================= หางวิ้ง (Trail) =================
	{ Id = "trail_bubble", Name = "ฟองสบู่", Category = "Trail", Rarity = "Common", Price = 120, Currency = "Coins", Icon = "🫧", Colors = { C(180, 230, 255), C(255, 255, 255) } },
	{ Id = "trail_candy", Name = "สายไหม", Category = "Trail", Rarity = "Common", Price = 160, Currency = "Coins", Icon = "🍬", Colors = { C(255, 120, 200), C(130, 220, 255) } },
	{ Id = "trail_fire", Name = "เปลวไฟ", Category = "Trail", Rarity = "Rare", Price = 450, Currency = "Coins", Icon = "🔥", Colors = { C(255, 235, 60), C(255, 80, 20) } },
	{ Id = "trail_toxic", Name = "น้ำยาเรืองแสง", Category = "Trail", Rarity = "Rare", Price = 500, Currency = "Coins", Icon = "🧪", Colors = { C(170, 255, 60), C(30, 180, 80) } },
	{ Id = "trail_galaxy", Name = "ดาวตก", Category = "Trail", Rarity = "Epic", Price = 1400, Currency = "Coins", Icon = "🌠", Colors = { C(120, 60, 255), C(20, 200, 255), C(255, 80, 200) } },
	{ Id = "trail_gold", Name = "ประกายทอง", Category = "Trail", Rarity = "Legendary", Price = 45, Currency = "Gems", Icon = "✨", Colors = { C(255, 245, 160), C(255, 180, 0) } },
	{ Id = "trail_rainbow", Name = "สายรุ้งพาดฟ้า", Category = "Trail", Rarity = "Mythic", Price = 100, Currency = "Gems", Icon = "🌈", Rainbow = true, Colors = { C(255, 80, 80), C(80, 255, 120), C(80, 140, 255) } },

	-- ================= สัตว์เลี้ยง =================
	{ Id = "pet_slime", Name = "สไลม์ดุ๊กดิ๊ก", Category = "Pet", Rarity = "Common", Price = 250, Currency = "Coins", Icon = "🟢", Style = "Ball", Colors = { C(120, 230, 120) } },
	{ Id = "pet_cubie", Name = "คิวบี้", Category = "Pet", Rarity = "Common", Price = 300, Currency = "Coins", Icon = "🧊", Style = "Cube", Colors = { C(130, 200, 255) } },
	{ Id = "pet_bee", Name = "ผึ้งน้อยบัซ", Category = "Pet", Rarity = "Rare", Price = 600, Currency = "Coins", Icon = "🐝", Style = "Ball", Colors = { C(255, 210, 40), C(40, 40, 40) } },
	{ Id = "pet_ghost", Name = "ผีน้อยขี้อาย", Category = "Pet", Rarity = "Rare", Price = 650, Currency = "Coins", Icon = "👻", Style = "Ghost", Colors = { C(245, 245, 255) } },
	{ Id = "pet_cloud", Name = "ก้อนเมฆนุ่มนิ่ม", Category = "Pet", Rarity = "Epic", Price = 1300, Currency = "Coins", Icon = "☁️", Style = "Cloud", Colors = { C(255, 255, 255), C(200, 230, 255) } },
	{ Id = "pet_ufo", Name = "จานบินจิ๋ว", Category = "Pet", Rarity = "Epic", Price = 1600, Currency = "Coins", Icon = "🛸", Style = "Ufo", Colors = { C(170, 180, 200), C(120, 255, 200) } },
	{ Id = "pet_goldblob", Name = "บล็อบทองคำ", Category = "Pet", Rarity = "Legendary", Price = 75, Currency = "Gems", Icon = "💛", Style = "Ball", Colors = { C(255, 200, 40) }, Material = "Metal" },
	{ Id = "pet_rainbowcube", Name = "คิวบี้สายรุ้ง", Category = "Pet", Rarity = "Mythic", Price = 120, Currency = "Gems", Icon = "🌈", Style = "Cube", Rainbow = true, Colors = { C(255, 80, 80), C(80, 200, 255) } },

	-- ================= ออร่า =================
	{ Id = "aura_sparkle", Name = "ประกายดาว", Category = "Aura", Rarity = "Common", Price = 200, Currency = "Coins", Icon = "⭐", Style = "Particles", Colors = { C(255, 255, 180) } },
	{ Id = "aura_love", Name = "ออร่าชมพูหวาน", Category = "Aura", Rarity = "Rare", Price = 500, Currency = "Coins", Icon = "💗", Style = "Particles", Colors = { C(255, 120, 180), C(255, 200, 230) } },
	{ Id = "aura_snow", Name = "หิมะโปรยปราย", Category = "Aura", Rarity = "Rare", Price = 550, Currency = "Coins", Icon = "🌨️", Style = "Particles", Colors = { C(220, 240, 255), C(255, 255, 255) } },
	{ Id = "aura_fire", Name = "ไฟลุกโชน", Category = "Aura", Rarity = "Epic", Price = 1200, Currency = "Coins", Icon = "🔥", Style = "Fire", Colors = { C(255, 120, 30), C(255, 220, 60) } },
	{ Id = "aura_magic", Name = "เวทมนตร์ม่วง", Category = "Aura", Rarity = "Legendary", Price = 65, Currency = "Gems", Icon = "🔮", Style = "Particles", Colors = { C(170, 80, 255), C(80, 200, 255) } },
	{ Id = "aura_vip", Name = "ประกาย VIP", Category = "Aura", Rarity = "Mythic", Price = 0, Currency = "Gems", Icon = "💫", Style = "Sparkles", Exclusive = "VIP", Colors = { C(255, 215, 0) } },
}

ItemCatalog.List = items
ItemCatalog.ById = {}
ItemCatalog.CategoryById = {}

for _, category in ItemCatalog.Categories do
	ItemCatalog.CategoryById[category.Id] = category
end

for _, item in items do
	assert(ItemCatalog.ById[item.Id] == nil, "Duplicate item id: " .. item.Id)
	assert(ItemCatalog.CategoryById[item.Category], "Unknown category for " .. item.Id)
	assert(ItemCatalog.Rarities[item.Rarity], "Unknown rarity for " .. item.Id)
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
