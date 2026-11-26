--[[
	Items — อาหาร สมุนไพร ยา และของตกแต่งเขตอนุรักษ์
	Category: Food | Herb | Potion | Decor | Habitat | Egg
	Placeable = วางในเขตอนุรักษ์ได้ (Footprint = ขนาดบนกริด, AssetKey = โมเดลใน AssetRegistry)
]]

local Items = {}

Items.List = {
	-- อาหาร
	{ Id = "glowberry", Name = "Glowberry", ThaiName = "เบอร์รี่เรืองแสง", Category = "Food", Price = 6, Icon = "icon_glowberry", Description = "ผลไม้ป่าที่สัตว์ส่วนใหญ่ชอบ" },
	{ Id = "spirit_plum", Name = "Spirit Plum", ThaiName = "พลัมวิญญาณ", Category = "Food", Price = 18, Icon = "icon_spirit_plum", Description = "ลูกพลัมสีฟ้าใส ของโปรดจิ้งจอกวิญญาณ" },
	{ Id = "moonleaf", Name = "Moonleaf", ThaiName = "ใบจันทรา", Category = "Food", Price = 16, Icon = "icon_moonleaf", Description = "ใบไม้ที่เก็บแสงจันทร์ไว้ ของโปรดกวางจันทรา" },
	{ Id = "honeyroot", Name = "Honeyroot", ThaiName = "รากน้ำผึ้ง", Category = "Food", Price = 8, Icon = "icon_honeyroot", Description = "รากไม้รสหวาน กินแล้วอิ่มนาน" },
	{ Id = "crystal_grub", Name = "Crystal Grub", ThaiName = "หนอนคริสตัล", Category = "Food", Price = 14, Icon = "icon_crystal_grub", Description = "ของโปรดตุ่นนักขุดสมบัติ" },

	-- สมุนไพร (เก็บได้ในป่า)
	{ Id = "silverfern", Name = "Silverfern", ThaiName = "เฟิร์นเงิน", Category = "Herb", SellPrice = 3, Icon = "icon_silverfern", Description = "เฟิร์นใบเงิน ใช้ทำยาสมานแผล" },
	{ Id = "dewcap", Name = "Dewcap", ThaiName = "เห็ดหยาดน้ำค้าง", Category = "Herb", SellPrice = 4, Icon = "icon_dewcap", Description = "เห็ดเรืองแสงที่มีน้ำค้างเย็นอยู่ในหมวก" },
	{ Id = "wisp_lily", Name = "Wisp Lily", ThaiName = "ลิลลี่ดวงไฟ", Category = "Herb", SellPrice = 8, Icon = "icon_wisp_lily", Description = "ดอกไม้ที่บานเฉพาะยามค่ำ มีพลังสงบจิตใจ" },

	-- ยา (ปรุงที่หม้อยา)
	{ Id = "healing_salve", Name = "Healing Salve", ThaiName = "ยาสมานแผล", Category = "Potion", SellPrice = 20, Icon = "icon_healing_salve", Description = "รักษาสัตว์ที่บาดเจ็บ (ใช้ช่วยเหลือสัตว์ป่า)" },
	{ Id = "calming_draught", Name = "Calming Draught", ThaiName = "ยาสงบใจ", Category = "Potion", SellPrice = 24, Icon = "icon_calming_draught", Description = "ทำให้สัตว์ขี้กลัวไม่หนีชั่วครู่ และไว้ใจเร็วขึ้น" },
	{ Id = "growth_tonic", Name = "Growth Tonic", ThaiName = "ยาบำรุงการเติบโต", Category = "Potion", SellPrice = 40, Icon = "icon_growth_tonic", Description = "เพิ่ม Care XP ให้สัตว์ในเขตอนุรักษ์" },

	-- ไข่
	{ Id = "egg_spirit_kitsune", Name = "Kitsune Egg", ThaiName = "ไข่จิ้งจอกวิญญาณ", Category = "Egg", Species = "spirit_kitsune", Icon = "icon_egg_kitsune", Description = "วางในโรงเพาะฟักเพื่อฟักไข่" },

	-- ที่อยู่สัตว์ (วางในเขตอนุรักษ์)
	{ Id = "habitat_kitsune_den", Name = "Kitsune Den", ThaiName = "โพรงจิ้งจอก", Category = "Habitat", Price = 150, Placeable = true, Footprint = Vector2.new(10, 10), AssetKey = "Habitat_KitsuneDen", Icon = "icon_kitsune_den", Description = "โพรงรากไม้อบอุ่นสำหรับจิ้งจอกวิญญาณ" },
	{ Id = "habitat_moon_glade", Name = "Moon Glade", ThaiName = "ลานจันทรา", Category = "Habitat", Price = 220, Placeable = true, Footprint = Vector2.new(14, 14), AssetKey = "Habitat_MoonGlade", Icon = "icon_moon_glade", Description = "ลานหญ้าเงินกับหินจันทร์สำหรับกวางจันทรา" },
	{ Id = "habitat_mole_burrow", Name = "Mole Burrow", ThaiName = "โพรงตุ่น", Category = "Habitat", Price = 120, Placeable = true, Footprint = Vector2.new(8, 8), AssetKey = "Habitat_MoleBurrow", Icon = "icon_mole_burrow", Description = "เนินดินกับอุโมงค์คดเคี้ยว" },
	{ Id = "incubator", Name = "Hatchery Nest", ThaiName = "รังฟักไข่", Category = "Habitat", Price = 80, Placeable = true, Footprint = Vector2.new(6, 6), AssetKey = "Prop_HatcheryNest", Icon = "icon_incubator", Description = "รังอุ่นด้วยหินเวทสำหรับฟักไข่" },

	-- ของตกแต่ง
	{ Id = "decor_lantern", Name = "Floating Lantern", ThaiName = "โคมลอยเวทมนตร์", Category = "Decor", Price = 25, Placeable = true, Footprint = Vector2.new(2, 2), AssetKey = "Prop_FloatingLantern", Icon = "icon_lantern", Description = "โคมไฟลอยได้ ส่องแสงอุ่นยามค่ำ" },
	{ Id = "decor_mushroom_lamp", Name = "Glowcap Cluster", ThaiName = "กอเห็ดเรืองแสง", Category = "Decor", Price = 30, Placeable = true, Footprint = Vector2.new(4, 4), AssetKey = "Prop_GlowcapCluster", Icon = "icon_glowcap", Description = "กอเห็ดเรืองแสงหลายขนาด" },
	{ Id = "decor_bench", Name = "Root Bench", ThaiName = "ม้านั่งรากไม้", Category = "Decor", Price = 40, Placeable = true, Footprint = Vector2.new(6, 2), AssetKey = "Prop_RootBench", Icon = "icon_bench", Description = "ม้านั่งที่รากไม้บิดเป็นรูปทรงเอง" },
	{ Id = "decor_flowerbed", Name = "Wildflower Patch", ThaiName = "แปลงดอกไม้ป่า", Category = "Decor", Price = 20, Placeable = true, Footprint = Vector2.new(6, 6), AssetKey = "Prop_WildflowerPatch", Icon = "icon_flowerbed", Description = "ดอกไม้ป่าหลากสี สัตว์ชอบนอนเล่น" },
	{ Id = "decor_stone_arch", Name = "Rune Arch", ThaiName = "ซุ้มหินอักขระ", Category = "Decor", Price = 90, Placeable = true, Footprint = Vector2.new(8, 4), AssetKey = "Prop_RuneArch", Icon = "icon_rune_arch", Description = "ซุ้มหินโบราณสลักอักขระเรืองแสง" },
	{ Id = "decor_pond", Name = "Spring Pond", ThaiName = "บ่อน้ำพุเวท", Category = "Decor", Price = 110, Placeable = true, Footprint = Vector2.new(12, 12), AssetKey = "Prop_SpringPond", Icon = "icon_pond", Description = "บ่อน้ำใส สัตว์ใช้ดื่มน้ำ (เพิ่มความสุข)" },
}

Items.ById = {}
for _, item in Items.List do
	Items.ById[item.Id] = item
end

-- สูตรปรุงยา / งานคราฟต์
Items.Recipes = {
	{ Id = "healing_salve", Output = "healing_salve", Amount = 1, Inputs = { silverfern = 2, dewcap = 1 }, Station = "Cauldron", Seconds = 3 },
	{ Id = "calming_draught", Output = "calming_draught", Amount = 1, Inputs = { wisp_lily = 1, silverfern = 1 }, Station = "Cauldron", Seconds = 3 },
	{ Id = "growth_tonic", Output = "growth_tonic", Amount = 1, Inputs = { dewcap = 2, wisp_lily = 1, honeyroot = 1 }, Station = "Cauldron", Seconds = 4 },
}

Items.RecipeById = {}
for _, recipe in Items.Recipes do
	Items.RecipeById[recipe.Id] = recipe
end

return Items
