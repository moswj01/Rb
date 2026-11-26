--[[
	Quests — เนื้อเรื่องบทนำ "เสียงเรียกจากป่า" (Phase 1)
	Objective.Type: Talk | Forage | Craft | Discover | Trust | Bond | Visit | Place | Feed | Hatch
]]

local Quests = {}

Quests.List = {
	{
		Id = "q01_arrival",
		Title = "ผู้มาใหม่แห่งมิสติก",
		Giver = "npc_elder",
		Story = "ผู้เฒ่ามาริเบลรอคุณอยู่ที่หอนาฬิกา เธอว่ามีบางอย่างในป่าเรียกหาคุณ",
		Objectives = { { Type = "Talk", Target = "npc_elder", Count = 1, Text = "คุยกับผู้เฒ่ามาริเบลที่หอนาฬิกา" } },
		Rewards = { Coins = 30, XP = 40 },
		Next = "q02_herbs",
	},
	{
		Id = "q02_herbs",
		Title = "สมุนไพรแห่งการเยียวยา",
		Giver = "npc_willow",
		Story = "สัตว์ในป่าบาดเจ็บจากพายุเมื่อคืน วิลโลว์ต้องการเฟิร์นเงินและเห็ดหยาดน้ำค้างเพื่อปรุงยา",
		Objectives = {
			{ Type = "Forage", Target = "silverfern", Count = 4, Text = "เก็บเฟิร์นเงินในป่า" },
			{ Type = "Forage", Target = "dewcap", Count = 2, Text = "เก็บเห็ดหยาดน้ำค้างใกล้ต้นไม้ผู้เฒ่า" },
		},
		Rewards = { Coins = 40, XP = 60 },
		Next = "q03_brew",
	},
	{
		Id = "q03_brew",
		Title = "หม้อยาแรก",
		Giver = "npc_willow",
		Story = "ใช้หม้อยาหน้าร้านปรุงยาเพื่อปรุงยาสมานแผล",
		Objectives = { { Type = "Craft", Target = "healing_salve", Count = 1, Text = "ปรุงยาสมานแผล 1 ขวด" } },
		Rewards = { Coins = 30, XP = 60, Items = { glowberry = 4 } },
		Next = "q04_rescue",
	},
	{
		Id = "q04_rescue",
		Title = "เสียงร้องใต้ต้นไม้ผู้เฒ่า",
		Giver = "npc_elder",
		Story = "มีจิ้งจอกวิญญาณบาดเจ็บอยู่ใกล้ต้นไม้ผู้เฒ่า เดินเข้าไปอย่างแผ่วเบา (กด Ctrl/ปุ่มย่อตัว) แล้วใช้ยาสมานแผล",
		Objectives = {
			{ Type = "Discover", Target = "spirit_kitsune", Count = 1, Text = "ตามหาจิ้งจอกวิญญาณ" },
			{ Type = "Rescue", Target = "spirit_kitsune", Count = 1, Text = "รักษาจิ้งจอกที่บาดเจ็บ" },
		},
		Rewards = { Coins = 60, XP = 120 },
		Next = "q05_bond",
	},
	{
		Id = "q05_bond",
		Title = "สายใยแห่งความไว้วางใจ",
		Giver = "npc_elder",
		Story = "จิ้งจอกยังลังเล ให้อาหารที่มันชอบและอยู่ใกล้ ๆ อย่างอ่อนโยนจนมันยอมไว้ใจ",
		Objectives = { { Type = "Bond", Target = "spirit_kitsune", Count = 1, Text = "สร้างความผูกพันกับจิ้งจอกวิญญาณ" } },
		Rewards = { Coins = 80, XP = 150, Items = { habitat_kitsune_den = 1 } },
		Next = "q06_sanctuary",
	},
	{
		Id = "q06_sanctuary",
		Title = "บ้านหลังใหม่",
		Giver = "npc_elder",
		Story = "เดินผ่านประตูเขตอนุรักษ์ในหมู่บ้าน แล้ววางโพรงจิ้งจอกให้เพื่อนใหม่",
		Objectives = {
			{ Type = "Visit", Target = "Sanctuary", Count = 1, Text = "เข้าสู่เขตอนุรักษ์ส่วนตัว" },
			{ Type = "Place", Target = "habitat_kitsune_den", Count = 1, Text = "วางโพรงจิ้งจอก" },
			{ Type = "Feed", Target = "any", Count = 1, Text = "ให้อาหารสัตว์ในเขตอนุรักษ์" },
		},
		Rewards = { Coins = 120, XP = 200, Items = { egg_spirit_kitsune = 1, incubator = 1 } },
		Next = "q07_egg",
	},
	{
		Id = "q07_egg",
		Title = "ไข่ปริศนา",
		Giver = "npc_quill",
		Story = "ควิลล์พบไข่ที่ถูกทิ้งไว้ในห้องสมุด วางมันในรังฟักไข่ แล้วรอดูชีวิตใหม่",
		Objectives = {
			{ Type = "Place", Target = "incubator", Count = 1, Text = "วางรังฟักไข่ในเขตอนุรักษ์" },
			{ Type = "Hatch", Target = "any", Count = 1, Text = "ฟักไข่ให้สำเร็จ" },
		},
		Rewards = { Coins = 150, XP = 250 },
		Next = "q08_explore",
	},
	{
		Id = "q08_explore",
		Title = "นักสำรวจแห่งป่าเสียงกระซิบ",
		Giver = "npc_quill",
		Story = "บันทึกสัตว์ทุกชนิดในป่าลงสมุดภาพสัตว์ และตามหาสถานที่ลับที่ซ่อนอยู่",
		Objectives = {
			{ Type = "Discover", Target = "lunar_stag", Count = 1, Text = "พบกวางจันทรา (ออกตอนกลางคืน ใกล้น้ำตก)" },
			{ Type = "Discover", Target = "treasure_mole", Count = 1, Text = "พบตุ่นนักขุดสมบัติ" },
			{ Type = "Landmark", Target = "HiddenCave", Count = 1, Text = "ค้นพบถ้ำลับ" },
		},
		Rewards = { Coins = 200, XP = 300 },
	},
}

Quests.ById = {}
for _, quest in Quests.List do
	Quests.ById[quest.Id] = quest
end

Quests.First = "q01_arrival"

return Quests
