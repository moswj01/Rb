--[[
	AssetTools — เครื่องมือใน Studio สำหรับนำโมเดลจาก Creator Store เข้าเกม (ใช้ใน Command Bar, โหมด Edit)

	ขั้นตอน:
	  1) Toolbox → ค้นหาโมเดล (ดูคำค้นจาก AssetTools.Missing()) → ลากเข้า Workspace
	  2) คลิกเลือกโมเดลนั้น แล้วพิมพ์ใน Command Bar:
	       require(game.ReplicatedStorage.Shared.AssetTools).Register("Tree_Forest_A")
	     ถ้าโมเดลหันผิดด้าน ใส่องศาหมุนเพิ่ม:  .Register("Building_House_Small_A", 180)
	  3) เครื่องมือจะ: ลบสคริปต์ทั้งหมด (กัน backdoor) · Anchor · ย่อ/ขยายให้ตรงขนาดแมพ
	     · ตั้ง Pivot ที่ฐานกึ่งกลาง · ตั้งชื่อ · ย้ายไป ReplicatedStorage/Assets
	  4) ดูว่ายังขาดอะไร:  require(game.ReplicatedStorage.Shared.AssetTools).Missing()
	  5) File → Save — กด Play จะเห็นโมเดลจริงทั่วแมพ (ตัวแปรในครอบครัวเดียวกันใช้แทนกันได้)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetRegistry = require(script.Parent.AssetRegistry)
local AssetLibrary = require(script.Parent.AssetLibrary)

local AssetTools = {}

-- คำค้นแนะนำใน Toolbox (ภาษาอังกฤษ) — เลือกจากผู้สร้าง/แพ็กเดียวกันเพื่อให้สไตล์กลมกลืน
AssetTools.Search = {
	Landmark_ClockTower = "fantasy clock tower",
	Landmark_StoneBridge = "stone arch bridge",
	Landmark_NorthGate = "medieval stone gate archway",
	Landmark_ElderTree = "giant fantasy tree",
	Landmark_TempleRuins = "overgrown temple ruins",
	Landmark_Waterfall = "waterfall",
	Building_House_Small = "stylized fantasy cottage",
	Building_House_Medium = "medieval fantasy house",
	Building_House_Large = "large medieval house / manor",
	Building_FeedShop = "fantasy shop building",
	Building_Apothecary = "potion shop / apothecary",
	Building_Library = "fantasy library building",
	Prop_MarketStall = "medieval market stall",
	Prop_Cauldron_Public = "cauldron",
	Prop_CrystalCluster = "crystal cluster",
	Prop_FloatingLantern = "lantern",
	Tree_Ancient = "big stylized tree",
	Tree_Forest = "stylized tree / low poly tree",
	Tree_Village = "small stylized tree",
	Mushroom_Glow = "glowing mushroom",
	Plant_Fern = "fern / bush",
	Rock_Moss = "mossy rock",
	Habitat_KitsuneDen = "tree stump den / burrow",
	Habitat_MoonGlade = "stone circle",
	Habitat_MoleBurrow = "dirt mound burrow",
	Prop_HatcheryNest = "nest",
	Prop_RootBench = "wooden bench",
	Prop_WildflowerPatch = "flower patch",
	Prop_RuneArch = "rune stone arch",
	Prop_SpringPond = "small pond",
}

-- ชุดขั้นต่ำที่ทำให้แมพดูสมบูรณ์ (ที่เหลือใช้ครอบครัว/นามแฝงแทนได้)
AssetTools.Essential = {
	"Tree_Forest_A",
	"Tree_Forest_B",
	"Tree_Ancient_A",
	"Plant_Fern_A",
	"Rock_Moss_A",
	"Mushroom_Glow_A",
	"Building_House_Small_A",
	"Building_House_Medium_A",
	"Building_House_Large_A",
	"Landmark_ClockTower",
	"Landmark_StoneBridge",
	"Landmark_NorthGate",
	"Prop_MarketStall_A",
	"Prop_Cauldron_Public",
}

local function assets()
	local folder = ReplicatedStorage:FindFirstChild("Assets")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Assets"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

local function searchFor(key)
	if AssetTools.Search[key] then
		return AssetTools.Search[key]
	end
	local parts = string.split(key, "_")
	for keep = #parts - 1, 1, -1 do
		local prefix = table.concat(parts, "_", 1, keep)
		if AssetTools.Search[prefix] then
			return AssetTools.Search[prefix]
		end
	end
	return "?"
end

function AssetTools.Register(key, extraYawDegrees, modelOverride)
	local def = AssetRegistry.Get(key)
	assert(def, "ไม่รู้จัก Key: " .. tostring(key) .. " (ดูรายชื่อใน AssetRegistry.lua)")
	local target = modelOverride or game:GetService("Selection"):Get()[1]
	assert(target, "เลือกโมเดลใน Workspace ก่อน แล้วค่อยเรียก Register")
	local model = target
	if target:IsA("BasePart") then
		model = Instance.new("Model")
		model.Parent = target.Parent
		target.Parent = model
	end
	assert(model:IsA("Model"), "ต้องเลือก Model หรือ Part")

	local ChangeHistoryService = game:GetService("ChangeHistoryService")
	ChangeHistoryService:SetWaypoint("Before AssetTools.Register")

	-- 1) ลบสคริปต์ (โมเดลฟรีบางตัวแฝง backdoor)
	local removed = 0
	for _, d in model:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
			removed += 1
		elseif d:IsA("BasePart") then
			d.Anchored = true
		elseif d:IsA("Sound") then
			d.Playing = false
		end
	end
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end

	assert(model:FindFirstChildWhichIsA("BasePart", true), "โมเดลนี้ไม่มีชิ้นส่วน 3D")
	-- 2) ขนาด: ให้ความสูงตรงสเปก แต่ฐานไม่กว้างเกิน 1.6 เท่าของที่แมพเผื่อไว้
	local _, size = model:GetBoundingBox()
	local factor = def.Size.Y / math.max(size.Y, 0.01)
	local footprint = math.max(size.X, size.Z) * factor
	local allowed = math.max(def.Size.X, def.Size.Z) * 1.6
	if footprint > allowed then
		factor *= allowed / footprint
	end
	model:ScaleTo(model:GetScale() * factor)

	-- 3) Pivot = ฐานกึ่งกลาง, หน้า = -Z (+ องศาเพิ่มถ้าโมเดลหันผิด)
	local cf, newSize = model:GetBoundingBox()
	local base = Vector3.new(cf.Position.X, cf.Position.Y - newSize.Y / 2, cf.Position.Z)
	model.WorldPivot = CFrame.new(base) * CFrame.Angles(0, math.rad(extraYawDegrees or 0), 0)

	-- 4) ย้ายเข้า Assets
	local existing = assets():FindFirstChild(key)
	if existing then
		existing:Destroy()
	end
	model.Name = key
	model:SetAttribute("Source", "CreatorStore")
	model:SetAttribute("Spec", def.Spec)
	model:PivotTo(CFrame.new())
	model.Parent = assets()
	ChangeHistoryService:SetWaypoint("AssetTools.Register " .. key)
	print(string.format("✔ ลงทะเบียน %s (ย่อ/ขยาย ×%.2f, ลบสคริปต์ %d ตัว) — อย่าลืม File › Save", key, factor, removed))
	return model
end

-- ดาวน์โหลดโมเดลจาก Creator Store ตาม ID แล้ว Register ให้อัตโนมัติ
function AssetTools.Insert(key, assetId, extraYawDegrees)
	local ok, objects = pcall(function()
		return game:GetObjects("rbxassetid://" .. tostring(assetId))
	end)
	if not ok or not objects or #objects == 0 then
		ok, objects = pcall(function()
			return { game:GetService("InsertService"):LoadAsset(assetId) }
		end)
	end
	if not ok or not objects or #objects == 0 then
		warn(string.format("✖ โหลด %s (ID %s) ไม่สำเร็จ: %s", key, tostring(assetId), tostring(objects)))
		return nil
	end
	local model
	if #objects == 1 and objects[1]:IsA("Model") then
		model = objects[1]
	else
		model = Instance.new("Model")
		for _, object in objects do
			object.Parent = model
		end
	end
	model.Parent = workspace
	local registered, result = pcall(AssetTools.Register, key, extraYawDegrees, model)
	if not registered then
		warn(string.format("✖ Register %s ไม่สำเร็จ: %s", key, tostring(result)))
		model:Destroy()
		return nil
	end
	return result
end

-- ติดตั้งชุดโมเดลที่คัดไว้ทั้งหมด (RecommendedAssets.lua) ด้วยคำสั่งเดียว
function AssetTools.InstallRecommended()
	local list = require(script.Parent.RecommendedAssets)
	local done = 0
	for index, entry in list do
		print(string.format("[%d/%d] กำลังติดตั้ง %s — \"%s\" โดย %s", index, #list, entry.Key, entry.Name, entry.Creator))
		if AssetTools.Insert(entry.Key, entry.Id, entry.Yaw) then
			done += 1
		end
		task.wait()
	end
	print(string.format("✔ ติดตั้งสำเร็จ %d / %d ชิ้น — กด File › Save แล้ว Play", done, #list))
	print("ถ้าบ้านหันหลังให้ถนน: เลือกบ้านใน ReplicatedStorage/Assets ไม่ได้ ให้ Insert ใหม่พร้อมองศา เช่น")
	print('  require(game.ReplicatedStorage.Shared.AssetTools).Insert("Building_House_Small_A", 2210545308, 180)')
	return done
end

-- รายการที่ยังไม่มีโมเดลจริง (และไม่มีตัวแทนจากครอบครัว/นามแฝง)
function AssetTools.Missing()
	local folder = assets()
	local covered, missing = {}, {}
	for key in AssetRegistry.Environment do
		local model = AssetLibrary.Create(key, CFrame.new())
		if model:GetAttribute("Placeholder") then
			table.insert(missing, key)
		else
			table.insert(covered, key)
		end
		model:Destroy()
	end
	table.sort(missing)
	print(string.format("[AssetTools] มีโมเดลแล้ว %d / %d ชนิด (รวมที่ใช้ตัวแทน)", #covered, #covered + #missing))
	print("— ชุดขั้นต่ำที่แนะนำ (ใส่ครบ แมพจะดูสมบูรณ์):")
	for _, key in AssetTools.Essential do
		print(string.format("   %s %-26s ค้นหา: \"%s\"", folder:FindFirstChild(key) and "✔" or "◇", key, searchFor(key)))
	end
	print("— ยังเป็น Greybox:")
	for _, key in missing do
		print(string.format("   ◇ %-26s ค้นหา: \"%s\"", key, searchFor(key)))
	end
	return missing
end

return AssetTools
