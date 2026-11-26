--[[
	AssetRegistry — รายการ Asset ทั้งหมดที่เกมต้องการ (ตรงกับ docs/ASSET_SPEC.md)

	วิธีที่ 3D Artist ส่งงานเข้าเกม (ไม่ต้องแก้โค้ด):
	  1) สร้างโมเดลใน Blender ตาม ASSET_SPEC → Export .fbx
	  2) Roblox Studio → 3D Importer → ตั้งชื่อ Model ให้ตรงกับ Key ในไฟล์นี้
	  3) วางไว้ใน ReplicatedStorage/Assets/<Key>   (Pivot = จุดกึ่งกลางฐาน, หน้า = -Z)
	  เกมจะใช้โมเดลจริงแทน Greybox ให้อัตโนมัติ

	ถ้ายังไม่มีโมเดล → เกมจะวาง "Greybox Blockout" (ทรงหยาบสีดินเหนียว + แท็ก Placeholder)
	ตามมาตรฐานสตูดิโอ เพื่อให้ทดสอบ gameplay / scale / composition ได้ก่อน
	Greybox ไม่ใช่งานศิลป์สมบูรณ์ และห้ามส่งมอบเป็นงานจบ (ดู docs/LIMITATIONS.md)

	Size = ขนาดเป้าหมายโดยประมาณ (studs) ใช้ทั้งสร้าง Greybox และตรวจ scale ของโมเดลจริง
	Shape = รูปทรง Greybox: Tower | Building | Tree | Bush | Rock | Mushroom | Bridge | Arch | Stall | Crystal | Waterfall | Prop | Habitat
]]

local V = Vector3.new

local AssetRegistry = {}

AssetRegistry.Environment = {
	-- ===== Landmarks =====
	Landmark_ClockTower = { Size = V(22, 78, 22), Shape = "Tower", Spec = "ENV-L01", Light = true },
	Landmark_StoneBridge = { Size = V(52, 14, 16), Shape = "Bridge", Spec = "ENV-L02" },
	Landmark_NorthGate = { Size = V(30, 26, 8), Shape = "Arch", Spec = "ENV-L03" },
	Landmark_SanctuaryGate = { Size = V(18, 22, 6), Shape = "Arch", Spec = "ENV-L04", Glow = Color3.fromRGB(140, 210, 255) },
	Landmark_ElderTree = { Size = V(70, 120, 70), Shape = "Tree", Spec = "ENV-L05", Glow = Color3.fromRGB(170, 255, 200) },
	Landmark_TempleRuins = { Size = V(60, 34, 50), Shape = "Ruins", Spec = "ENV-L06" },
	Landmark_Waterfall = { Size = V(34, 70, 10), Shape = "Waterfall", Spec = "ENV-L07" },

	-- ===== อาคารหมู่บ้าน =====
	Building_FeedShop = { Size = V(26, 24, 20), Shape = "Building", Spec = "ENV-B01", Light = true },
	Building_Apothecary = { Size = V(24, 28, 22), Shape = "Building", Spec = "ENV-B02", Light = true },
	Building_Library = { Size = V(40, 38, 30), Shape = "Building", Spec = "ENV-B03", Light = true },
	Building_House_Small_A = { Size = V(18, 18, 16), Shape = "Building", Spec = "ENV-B10", Light = true },
	Building_House_Small_B = { Size = V(16, 20, 16), Shape = "Building", Spec = "ENV-B11", Light = true },
	Building_House_Small_C = { Size = V(18, 17, 18), Shape = "Building", Spec = "ENV-B12", Light = true },
	Building_House_Medium_A = { Size = V(24, 24, 20), Shape = "Building", Spec = "ENV-B13", Light = true },
	Building_House_Medium_B = { Size = V(22, 26, 22), Shape = "Building", Spec = "ENV-B14", Light = true },
	Building_House_Medium_C = { Size = V(26, 22, 20), Shape = "Building", Spec = "ENV-B15", Light = true },
	Building_House_Large_A = { Size = V(32, 30, 26), Shape = "Building", Spec = "ENV-B16", Light = true },

	-- ===== Props =====
	Prop_MarketStall_A = { Size = V(12, 12, 8), Shape = "Stall", Spec = "ENV-P01" },
	Prop_MarketStall_B = { Size = V(12, 12, 8), Shape = "Stall", Spec = "ENV-P02" },
	Prop_MarketStall_C = { Size = V(10, 11, 8), Shape = "Stall", Spec = "ENV-P03" },
	Prop_Cauldron_Public = { Size = V(6, 5, 6), Shape = "Prop", Spec = "ENV-P04", Glow = Color3.fromRGB(150, 255, 170) },
	Prop_CaveEntrance = { Size = V(20, 16, 10), Shape = "Arch", Spec = "ENV-P05" },
	Prop_CrystalCluster_A = { Size = V(14, 18, 14), Shape = "Crystal", Spec = "ENV-C01", Glow = Color3.fromRGB(160, 130, 255) },
	Prop_ShrineStone = { Size = V(6, 10, 6), Shape = "Rock", Spec = "ENV-P06", Glow = Color3.fromRGB(210, 230, 255) },
	Prop_FloatingLantern = { Size = V(2, 3, 2), Shape = "Lantern", Spec = "ENV-P07", Glow = Color3.fromRGB(255, 200, 120) },

	-- ===== พืชพรรณ / หิน (หลาย Variation) =====
	Tree_Ancient_A = { Size = V(34, 70, 34), Shape = "Tree", Spec = "ENV-T01" },
	Tree_Ancient_B = { Size = V(30, 64, 30), Shape = "Tree", Spec = "ENV-T02" },
	Tree_Ancient_C = { Size = V(38, 76, 38), Shape = "Tree", Spec = "ENV-T03" },
	Tree_Forest_A = { Size = V(18, 44, 18), Shape = "Tree", Spec = "ENV-T10" },
	Tree_Forest_B = { Size = V(16, 40, 16), Shape = "Tree", Spec = "ENV-T11" },
	Tree_Forest_C = { Size = V(20, 48, 20), Shape = "Tree", Spec = "ENV-T12" },
	Tree_Forest_D = { Size = V(14, 36, 14), Shape = "Tree", Spec = "ENV-T13" },
	Tree_Village_A = { Size = V(16, 26, 16), Shape = "Tree", Spec = "ENV-T20" },
	Tree_Village_B = { Size = V(14, 22, 14), Shape = "Tree", Spec = "ENV-T21" },
	Mushroom_Glow_A = { Size = V(3, 3, 3), Shape = "Mushroom", Spec = "ENV-M01", Glow = Color3.fromRGB(120, 230, 255) },
	Mushroom_Glow_B = { Size = V(4, 5, 4), Shape = "Mushroom", Spec = "ENV-M02", Glow = Color3.fromRGB(200, 140, 255) },
	Mushroom_Glow_C = { Size = V(2, 2, 2), Shape = "Mushroom", Spec = "ENV-M03", Glow = Color3.fromRGB(140, 255, 170) },
	Plant_Fern_A = { Size = V(4, 3, 4), Shape = "Bush", Spec = "ENV-G01" },
	Plant_Fern_B = { Size = V(5, 4, 5), Shape = "Bush", Spec = "ENV-G02" },
	Rock_Moss_A = { Size = V(8, 5, 7), Shape = "Rock", Spec = "ENV-R01" },
	Rock_Moss_B = { Size = V(12, 7, 10), Shape = "Rock", Spec = "ENV-R02" },
	Rock_Moss_C = { Size = V(5, 4, 5), Shape = "Rock", Spec = "ENV-R03" },

	-- ===== Forage nodes =====
	Forage_silverfern = { Size = V(3, 2, 3), Shape = "Bush", Spec = "ENV-F01" },
	Forage_dewcap = { Size = V(2, 2, 2), Shape = "Mushroom", Spec = "ENV-F02", Glow = Color3.fromRGB(120, 230, 255) },
	Forage_wisp_lily = { Size = V(2, 3, 2), Shape = "Mushroom", Spec = "ENV-F03", Glow = Color3.fromRGB(255, 240, 180) },
	Forage_honeyroot = { Size = V(3, 1, 3), Shape = "Bush", Spec = "ENV-F04" },

	-- ===== เขตอนุรักษ์ (ของที่วางได้) =====
	Habitat_KitsuneDen = { Size = V(10, 7, 10), Shape = "Habitat", Spec = "SAN-H01" },
	Habitat_MoonGlade = { Size = V(14, 6, 14), Shape = "Habitat", Spec = "SAN-H02", Glow = Color3.fromRGB(210, 225, 255) },
	Habitat_MoleBurrow = { Size = V(8, 4, 8), Shape = "Habitat", Spec = "SAN-H03" },
	Prop_HatcheryNest = { Size = V(6, 4, 6), Shape = "Habitat", Spec = "SAN-H04", Glow = Color3.fromRGB(255, 190, 120) },
	Prop_GlowcapCluster = { Size = V(4, 4, 4), Shape = "Mushroom", Spec = "SAN-D01", Glow = Color3.fromRGB(120, 230, 255) },
	Prop_RootBench = { Size = V(6, 3, 2), Shape = "Prop", Spec = "SAN-D02" },
	Prop_WildflowerPatch = { Size = V(6, 1, 6), Shape = "Bush", Spec = "SAN-D03" },
	Prop_RuneArch = { Size = V(8, 10, 4), Shape = "Arch", Spec = "SAN-D04", Glow = Color3.fromRGB(150, 200, 255) },
	Prop_SpringPond = { Size = V(12, 1, 12), Shape = "Pond", Spec = "SAN-D05" },
	Sanctuary_Cottage = { Size = V(26, 24, 22), Shape = "Building", Spec = "SAN-B01", Light = true },
	Sanctuary_ReturnGate = { Size = V(18, 22, 6), Shape = "Arch", Spec = "SAN-B02", Glow = Color3.fromRGB(140, 210, 255) },
	Sanctuary_Cauldron = { Size = V(6, 5, 6), Shape = "Prop", Spec = "SAN-B03", Glow = Color3.fromRGB(150, 255, 170) },
}

-- ===== สัตว์: 1 โมเดลต่อ (สายพันธุ์ × ช่วงวัย) + ชุดแอนิเมชัน =====
-- โมเดลต้องมี: HumanoidRootPart, Humanoid (หรือ AnimationController) + Animator, Rig ตาม CRE-RIG
-- แอนิเมชันใส่เป็น Animation object ในโฟลเดอร์ "Animations" ของโมเดล หรือกรอก AnimationId ด้านล่าง
AssetRegistry.CreatureAnimations = { "Idle", "Walk", "Run", "Sleep", "Eat", "Drink", "Play", "Happy", "Scared", "Ability" }

AssetRegistry.Creatures = {
	spirit_kitsune = { Spec = "CRE-01", Animations = {} },
	lunar_stag = { Spec = "CRE-02", Animations = {} },
	treasure_mole = { Spec = "CRE-03", Animations = {} },
}

-- ===== NPC (ตัวละครออกแบบเฉพาะ: ReplicatedStorage/Assets/NPC_<id>, R15 rig มาตรฐาน) =====
AssetRegistry.Npcs = {
	npc_elder = { Spec = "NPC-01" },
	npc_bramble = { Spec = "NPC-02" },
	npc_willow = { Spec = "NPC-03" },
	npc_quill = { Spec = "NPC-04" },
	npc_pip = { Spec = "NPC-05" },
	npc_rowan = { Spec = "NPC-06" },
}

-- ===== เสียง (ใส่ SoundId หลังอัปโหลดเสียงที่มีสิทธิ์ใช้งาน) =====
AssetRegistry.Sounds = {
	Music_Village_Day = 0,
	Music_Village_Night = 0,
	Music_Forest_Day = 0,
	Music_Forest_Night = 0,
	Music_Sanctuary = 0,
	Ambience_Village = 0, -- เสียงผู้คน ไก่ ระฆังลม
	Ambience_Forest = 0, -- ใบไม้ นก แมลง
	Ambience_Night = 0, -- จิ้งหรีด ลม
	Ambience_River = 0, -- ลำธาร (3D, วางตามแม่น้ำ)
	Ambience_Waterfall = 0, -- น้ำตก (3D)
	Ambience_Rain = 0,
	Sfx_Footstep_Grass = 0,
	Sfx_Footstep_Stone = 0,
	Sfx_Footstep_Wood = 0,
	Sfx_Footstep_Mud = 0,
	Sfx_Forage = 0,
	Sfx_Potion_Brew = 0,
	Sfx_Trust_Up = 0,
	Sfx_Bond = 0,
	Sfx_UI_Open = 0,
	Sfx_UI_Click = 0,
	Creature_spirit_kitsune_Call = 0,
	Creature_lunar_stag_Call = 0,
	Creature_treasure_mole_Call = 0,
}

-- ===== ไอคอน UI (วาดเฉพาะเกม, PNG 256×256 โปร่งใส) =====
AssetRegistry.Icons = {} -- [IconKey] = "rbxassetid://..." ; ว่าง = แสดงตัวอักษรย่อบนกรอบทอง

function AssetRegistry.Get(key)
	return AssetRegistry.Environment[key]
end

function AssetRegistry.CreatureModelKey(speciesId, stage)
	return "Creature_" .. speciesId .. "_" .. stage
end

return AssetRegistry
