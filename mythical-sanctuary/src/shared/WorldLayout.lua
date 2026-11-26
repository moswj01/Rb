--[[
	WorldLayout — แผนผังโลกที่ออกแบบด้วยมือ (Phase 1: Mystic Village + Whispering Forest)
	ทุกตำแหน่งในไฟล์นี้วางตามหลัก Composition:
	  • Leading Lines  — ถนนจากจัตุรัสหอนาฬิกาพุ่งตรงไปประตูเหนือ → ทางป่า → ต้นไม้ผู้เฒ่า
	  • Landmark       — หอนาฬิกา (หมู่บ้าน), ต้นไม้ผู้เฒ่า (ป่า), น้ำตก (สุดทางเหนือ) มองเห็นได้จากระยะไกล
	  • Foreground/Mid/Background — ต้นไม้ยักษ์ "กรอบภาพ" สองข้างทาง, ป่าทึบชั้นกลาง, หน้าผาเป็นฉากหลัง
	  • Reward Pockets — ถ้ำลับ, ซากวิหาร, ทุ่งดอกไม้ ซ่อนนอกเส้นทางหลักให้ผู้เล่นค้นพบเอง
	ระบบ: +X = ตะวันออก, -Z = เหนือ (ป่า), หน่วย studs
]]

local V = Vector3.new

local WorldLayout = {}

-- ===== ภูมิประเทศ =====
WorldLayout.Terrain = {
	Min = V(-640, -40, -1080),
	Max = V(640, 220, 360),
	VoxelSize = 4,
	BaseHeight = 20,
	RimHeight = 150, -- ขอบโลกเป็นหน้าผาสูงปิดล้อม (Natural boundary)
	RimWidth = 140,
}

-- โซน (ใช้ตรวจว่าผู้เล่นอยู่ไหน → เปลี่ยน Lighting/เสียง/เพลง)
WorldLayout.Zones = {
	{ Id = "MysticVillage", Name = "Mystic Village", ThaiName = "หมู่บ้านมิสติก", Center = V(0, 0, 10), Radius = 200, Priority = 2 },
	{ Id = "WhisperingForest", Name = "Whispering Forest", ThaiName = "ป่าเสียงกระซิบ", Center = V(0, 0, -600), Radius = 560, Priority = 1 },
}

-- ===== ที่ราบหมู่บ้าน =====
WorldLayout.Village = {
	Center = V(0, 0, 0),
	Radius = 170,
	Height = 26,
}

-- ===== แม่น้ำ: ไหลจากน้ำตกทางเหนือ → ผ่านป่า → เลียบหมู่บ้านฝั่งตะวันออก → ใต้ =====
-- Level = ระดับผิวน้ำ ณ จุดนั้น (ลดหลั่นตามทางไหล)
WorldLayout.River = {
	Width = 26,
	Points = {
		{ Pos = V(150, 0, -905), Level = 46 },
		{ Pos = V(175, 0, -760), Level = 40 },
		{ Pos = V(135, 0, -560), Level = 33 },
		{ Pos = V(165, 0, -360), Level = 27 },
		{ Pos = V(140, 0, -180), Level = 22 },
		{ Pos = V(132, 0, 0), Level = 19 },
		{ Pos = V(95, 0, 180), Level = 16 },
		{ Pos = V(40, 0, 350), Level = 14 },
	},
}

-- ===== ทางเดิน (เส้นนำสายตา) =====
WorldLayout.Paths = {
	{ Id = "MainRoad", Width = 12, Material = "Cobblestone", Points = { V(0, 0, 120), V(0, 0, 0), V(0, 0, -150) } },
	{ Id = "MarketLane", Width = 8, Material = "Cobblestone", Points = { V(-90, 0, 20), V(0, 0, 0), V(100, 0, -5) } },
	{ Id = "BridgeRoad", Width = 9, Material = "Cobblestone", Points = { V(100, 0, -5), V(160, 0, 4), V(230, 0, 10) } },
	{ Id = "ForestTrail", Width = 9, Material = "Ground", Points = { V(0, 0, -150), V(-30, 0, -300), V(-60, 0, -440), V(-90, 0, -515) } },
	{ Id = "TempleTrail", Width = 7, Material = "Ground", Points = { V(-60, 0, -440), V(60, 0, -520), V(180, 0, -620), V(230, 0, -655) } },
	{ Id = "FallsTrail", Width = 7, Material = "Ground", Points = { V(-90, 0, -600), V(-20, 0, -720), V(80, 0, -830), V(125, 0, -860) } },
	{ Id = "HiddenTrail", Width = 4, Material = "Mud", Points = { V(-30, 0, -300), V(-160, 0, -360), V(-290, 0, -420) } }, -- ทางลับไปถ้ำ (แคบ ปกคลุมด้วยเฟิร์น)
}

-- ===== พื้นที่ที่ต้องปรับรูปทรงพิเศษ =====
WorldLayout.Features = {
	-- ลานโล่งต้นไม้ผู้เฒ่า: แอ่งราบมีแสงลอดลงมา
	{ Kind = "Clearing", Center = V(-90, 0, -560), Radius = 55, Height = 30 },
	-- เนินซากวิหาร
	{ Kind = "Mound", Center = V(235, 0, -660), Radius = 70, Height = 14 },
	-- เนินเขาถ้ำลับ
	{ Kind = "Hill", Center = V(-345, 0, -440), Radius = 110, Height = 55 },
	-- หน้าผาน้ำตก (ขอบเหนือยกสูง)
	{ Kind = "Cliff", Center = V(150, 0, -960), Radius = 130, Height = 70 },
	-- ทุ่งดอกไม้ริมน้ำ (Reward pocket ที่กวางจันทราชอบ)
	{ Kind = "Clearing", Center = V(95, 0, -810), Radius = 45, Height = 44 },
}

-- ถ้ำลับ: อุโมงค์ (ลำดับลูกบอลอากาศ) + ห้องโถงคริสตัล
-- ใช้เฉพาะพิกัด X/Z — ความสูงคำนวณจากผิวเนินจริงตอนสร้าง (TerrainBuilder.Cave)
WorldLayout.HiddenCave = {
	Entrance = V(-298, 0, -424),
	Tunnel = { V(-298, 0, -424), V(-318, 0, -432), V(-338, 0, -442), V(-356, 0, -452) },
	Chamber = { Center = V(-372, 0, -462), Radius = 22 },
}

-- ===== Landmark และอาคาร (AssetKey ใน AssetRegistry) =====
-- Yaw = องศาการหมุนรอบแกน Y, Scale = ขนาดสัมพัทธ์ของโมเดล
WorldLayout.Landmarks = {
	-- หมู่บ้าน
	{ Key = "Landmark_ClockTower", Pos = V(0, 0, 0), Yaw = 0, Zone = "MysticVillage", Role = "Hero" },
	{ Key = "Building_FeedShop", Pos = V(-38, 0, -34), Yaw = 35, Zone = "MysticVillage", Role = "Shop", Npc = "npc_bramble" },
	{ Key = "Building_Apothecary", Pos = V(44, 0, -30), Yaw = -40, Zone = "MysticVillage", Role = "Crafting", Npc = "npc_willow" },
	{ Key = "Building_Library", Pos = V(-78, 0, 48), Yaw = 120, Zone = "MysticVillage", Role = "Bestiary", Npc = "npc_quill" },
	{ Key = "Prop_MarketStall_A", Pos = V(-20, 0, 24), Yaw = 160, Zone = "MysticVillage" },
	{ Key = "Prop_MarketStall_B", Pos = V(22, 0, 26), Yaw = -150, Zone = "MysticVillage" },
	{ Key = "Prop_MarketStall_C", Pos = V(30, 0, -6), Yaw = -100, Zone = "MysticVillage" },
	{ Key = "Building_House_Small_A", Pos = V(-110, 0, -60), Yaw = 60, Zone = "MysticVillage" },
	{ Key = "Building_House_Medium_A", Pos = V(-120, 0, 10), Yaw = 95, Zone = "MysticVillage" },
	{ Key = "Building_House_Large_A", Pos = V(70, 0, 70), Yaw = -140, Zone = "MysticVillage" },
	{ Key = "Building_House_Small_B", Pos = V(-40, 0, 95), Yaw = 175, Zone = "MysticVillage" },
	{ Key = "Building_House_Medium_B", Pos = V(85, 0, -75), Yaw = -60, Zone = "MysticVillage" },
	{ Key = "Building_House_Small_C", Pos = V(40, 0, 110), Yaw = -170, Zone = "MysticVillage" },
	{ Key = "Building_House_Medium_C", Pos = V(-85, 0, -110), Yaw = 30, Zone = "MysticVillage" },
	{ Key = "Landmark_StoneBridge", Pos = V(132, 9, 2), Yaw = 92, Zone = "MysticVillage", Role = "Hero" },
	{ Key = "Landmark_NorthGate", Pos = V(0, 0, -150), Yaw = 0, Zone = "MysticVillage" },
	{ Key = "Landmark_SanctuaryGate", Pos = V(-30, 0, 72), Yaw = 200, Zone = "MysticVillage", Role = "Portal" },
	{ Key = "Prop_Cauldron_Public", Pos = V(52, 0, -14), Yaw = 0, Zone = "MysticVillage", Role = "Cauldron" },

	-- ป่า
	{ Key = "Landmark_ElderTree", Pos = V(-90, 0, -560), Yaw = 20, Zone = "WhisperingForest", Role = "Hero" },
	{ Key = "Landmark_TempleRuins", Pos = V(238, 0, -662), Yaw = -25, Zone = "WhisperingForest", Role = "Hero" },
	{ Key = "Landmark_Waterfall", Pos = V(150, 0, -912), Yaw = 0, Zone = "WhisperingForest", Role = "Hero" },
	{ Key = "Prop_CaveEntrance", Pos = V(-298, 0, -424), Yaw = 70, Zone = "WhisperingForest" },
	{ Key = "Prop_CrystalCluster_A", Pos = V(-380, 0, -470), Yaw = 0, Zone = "WhisperingForest", Cave = true },
	{ Key = "Prop_ShrineStone", Pos = V(95, 0, -810), Yaw = 140, Zone = "WhisperingForest" },
}

-- ต้นไม้ "กรอบภาพ" (Hero trees) วางด้วยมือสองข้างทางเพื่อนำสายตา
WorldLayout.HeroTrees = {
	{ Key = "Tree_Ancient_A", Pos = V(-24, 0, -190), Yaw = 10, Scale = 1.2 },
	{ Key = "Tree_Ancient_B", Pos = V(26, 0, -205), Yaw = 200, Scale = 1.1 },
	{ Key = "Tree_Ancient_C", Pos = V(-70, 0, -470), Yaw = 80, Scale = 1.3 },
	{ Key = "Tree_Ancient_A", Pos = V(-30, 0, -505), Yaw = 300, Scale = 1.15 },
	{ Key = "Tree_Ancient_B", Pos = V(200, 0, -610), Yaw = 140, Scale = 1.25 },
	{ Key = "Tree_Ancient_C", Pos = V(100, 0, -870), Yaw = 45, Scale = 1.2 },
}

-- กฎการกระจายพืชพรรณ (Poisson-disk + แผนที่ความหนาแน่น + เขตห้ามวาง) — ไม่ใช่สุ่มมั่ว
WorldLayout.Scatter = {
	{ Key = "Tree_Forest", Variants = { "Tree_Forest_A", "Tree_Forest_B", "Tree_Forest_C", "Tree_Forest_D" }, Zone = "WhisperingForest", MinSpacing = 26, ScaleRange = { 0.85, 1.35 }, KeepOffPaths = 14, KeepOffRiver = 20, MaxSlope = 0.55, Count = 420 },
	{ Key = "Mushroom_Glow", Variants = { "Mushroom_Glow_A", "Mushroom_Glow_B", "Mushroom_Glow_C" }, Zone = "WhisperingForest", MinSpacing = 14, ScaleRange = { 0.7, 1.4 }, KeepOffPaths = 4, KeepOffRiver = 6, NearTrees = true, Count = 260 },
	{ Key = "Plant_Fern", Variants = { "Plant_Fern_A", "Plant_Fern_B" }, Zone = "WhisperingForest", MinSpacing = 8, ScaleRange = { 0.8, 1.5 }, KeepOffPaths = 3, KeepOffRiver = 4, Count = 700 },
	{ Key = "Rock_Moss", Variants = { "Rock_Moss_A", "Rock_Moss_B", "Rock_Moss_C" }, Zone = "WhisperingForest", MinSpacing = 30, ScaleRange = { 0.6, 1.8 }, KeepOffPaths = 6, KeepOffRiver = 0, Count = 140 },
	{ Key = "Tree_Village", Variants = { "Tree_Village_A", "Tree_Village_B" }, Zone = "MysticVillage", MinSpacing = 34, ScaleRange = { 0.9, 1.2 }, KeepOffPaths = 12, KeepOffRiver = 14, KeepOffLandmarks = 26, Count = 40 },
}

-- ===== จุดเกิดสัตว์ป่า =====
WorldLayout.SpawnAreas = {
	{ Species = "spirit_kitsune", Center = V(-90, 0, -560), Radius = 60 },
	{ Species = "spirit_kitsune", Center = V(-210, 0, -310), Radius = 45 },
	{ Species = "lunar_stag", Center = V(95, 0, -810), Radius = 55 },
	{ Species = "lunar_stag", Center = V(-120, 0, -760), Radius = 60 },
	{ Species = "treasure_mole", Center = V(235, 0, -660), Radius = 45 },
	{ Species = "treasure_mole", Center = V(-110, 0, -210), Radius = 40 },
}

-- ===== จุดเก็บสมุนไพร =====
WorldLayout.ForageNodes = {
	{ Item = "silverfern", Pos = V(-40, 0, -260) }, { Item = "silverfern", Pos = V(-75, 0, -330) },
	{ Item = "silverfern", Pos = V(20, 0, -360) }, { Item = "silverfern", Pos = V(-130, 0, -520) },
	{ Item = "silverfern", Pos = V(160, 0, -600) }, { Item = "silverfern", Pos = V(-200, 0, -650) },
	{ Item = "dewcap", Pos = V(-110, 0, -585) }, { Item = "dewcap", Pos = V(-62, 0, -598) },
	{ Item = "dewcap", Pos = V(115, 0, -480) }, { Item = "dewcap", Pos = V(-250, 0, -400) },
	{ Item = "dewcap", Pos = V(210, 0, -700) }, { Item = "dewcap", Pos = V(-362, 0, -470), Cave = true },
	{ Item = "wisp_lily", Pos = V(85, 0, -820) }, { Item = "wisp_lily", Pos = V(110, 0, -796) },
	{ Item = "wisp_lily", Pos = V(-100, 0, -540) }, { Item = "wisp_lily", Pos = V(-370, 0, -452), Cave = true },
	{ Item = "honeyroot", Pos = V(-160, 0, -360) }, { Item = "honeyroot", Pos = V(60, 0, -520) },
}

-- ===== NPC + ตารางเวลา (ชั่วโมงในเกม → จุดหมาย) =====
WorldLayout.Npcs = {
	{ Id = "npc_elder", Name = "Elder Maribel", ThaiName = "ผู้เฒ่ามาริเบล", Role = "QuestGiver", Home = V(8, 0, 14), Schedule = { { Hour = 6, Pos = V(8, 0, 14) }, { Hour = 20, Pos = V(-120, 0, 10) } } },
	{ Id = "npc_bramble", Name = "Bramble", ThaiName = "แบรมเบิล", Role = "Shop", Home = V(-34, 0, -26), Schedule = { { Hour = 7, Pos = V(-34, 0, -26) }, { Hour = 19, Pos = V(-110, 0, -60) } } },
	{ Id = "npc_willow", Name = "Willow", ThaiName = "วิลโลว์", Role = "Crafting", Home = V(48, 0, -22), Schedule = { { Hour = 8, Pos = V(48, 0, -22) }, { Hour = 21, Pos = V(85, 0, -75) } } },
	{ Id = "npc_quill", Name = "Quill", ThaiName = "ควิลล์", Role = "Bestiary", Home = V(-72, 0, 40), Schedule = { { Hour = 9, Pos = V(-72, 0, 40) }, { Hour = 22, Pos = V(-72, 0, 40) } } },
	{ Id = "npc_pip", Name = "Pip", ThaiName = "พิป", Role = "Villager", Home = V(-40, 0, 95), Schedule = { { Hour = 7, Pos = V(-18, 0, 20) }, { Hour = 12, Pos = V(110, 0, 0) }, { Hour = 17, Pos = V(5, 0, -6) }, { Hour = 20, Pos = V(-40, 0, 95) } } },
	{ Id = "npc_rowan", Name = "Rowan", ThaiName = "โรแวน", Role = "Villager", Home = V(70, 0, 70), Schedule = { { Hour = 6, Pos = V(0, 0, -140) }, { Hour = 11, Pos = V(24, 0, 22) }, { Hour = 18, Pos = V(70, 0, 70) } } },
}

WorldLayout.PlayerSpawn = V(0, 0, 60)

return WorldLayout
