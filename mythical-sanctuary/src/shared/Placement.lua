--[[
	Placement — กฎการวางของในเขตอนุรักษ์ (ใช้ร่วมกัน: client แสดงผีสีเขียว/แดง, server ตรวจจริง)
	พิกัดทั้งหมดเป็น local (เทียบกับจุดกึ่งกลางเกาะ)
]]

local Config = require(script.Parent.Config)
local Items = require(script.Parent.Items)

local Placement = {}

-- องค์ประกอบคงที่ของเกาะ — จัดวางแบบ foreground (ประตู) / midground (ลานกลาง) / background (บ้าน + เนินหลัง)
Placement.Fixed = {
	{ Key = "Sanctuary_Cottage", Pos = Vector3.new(-50, 0, -95), Yaw = 20, Footprint = Vector2.new(30, 26) },
	{ Key = "Sanctuary_ReturnGate", Pos = Vector3.new(0, 0, 120), Yaw = 180, Footprint = Vector2.new(20, 8), Portal = true },
	{ Key = "Sanctuary_Cauldron", Pos = Vector3.new(-22, 0, -66), Yaw = 0, Footprint = Vector2.new(8, 8), Cauldron = true },
}
Placement.Pond = { Center = Vector2.new(55, 30), Radius = 30 }
Placement.Arrival = Vector3.new(0, 0, 98)

function Placement.Snap(value)
	local g = Config.Sanctuary.GridSize
	return math.floor(value / g + 0.5) * g
end

function Placement.Rect(x, z, footprint, rotationSteps)
	local w, d = footprint.X, footprint.Y
	if rotationSteps % 2 == 1 then
		w, d = d, w
	end
	return { MinX = x - w / 2, MaxX = x + w / 2, MinZ = z - d / 2, MaxZ = z + d / 2 }
end

local function overlaps(a, b)
	return a.MinX < b.MaxX and a.MaxX > b.MinX and a.MinZ < b.MaxZ and a.MaxZ > b.MinZ
end

function Placement.Radius(sanctuaryData)
	return Config.Sanctuary.BuildRadius + (sanctuaryData.Expansion or 0) * 25
end

-- objects = data.Sanctuary.Objects  คืนค่า ok, reason
function Placement.Validate(sanctuaryData, itemId, x, z, rotationSteps, ignoreObjectId)
	local item = Items.ById[itemId]
	if not item or not item.Placeable then
		return false, "วางของชิ้นนี้ไม่ได้"
	end
	local radius = Placement.Radius(sanctuaryData)
	local rect = Placement.Rect(x, z, item.Footprint, rotationSteps)
	for _, corner in { { rect.MinX, rect.MinZ }, { rect.MaxX, rect.MinZ }, { rect.MinX, rect.MaxZ }, { rect.MaxX, rect.MaxZ } } do
		if corner[1] ^ 2 + corner[2] ^ 2 > radius ^ 2 then
			return false, "อยู่นอกพื้นที่เขตอนุรักษ์"
		end
	end
	local pond = Placement.Pond
	local pondD = math.sqrt((x - pond.Center.X) ^ 2 + (z - pond.Center.Y) ^ 2)
	if pondD < pond.Radius + math.max(item.Footprint.X, item.Footprint.Y) * 0.4 and itemId ~= "decor_lantern" then
		return false, "วางในบ่อน้ำไม่ได้"
	end
	local arrival = Placement.Arrival
	if math.abs(x - arrival.X) < 8 and math.abs(z - arrival.Z) < 14 then
		return false, "เว้นทางเดินหน้าประตูไว้"
	end
	for _, fixed in Placement.Fixed do
		if overlaps(rect, Placement.Rect(fixed.Pos.X, fixed.Pos.Z, fixed.Footprint, 0)) then
			return false, "ชนกับสิ่งปลูกสร้าง"
		end
	end
	for objectId, object in sanctuaryData.Objects do
		if objectId ~= ignoreObjectId then
			local other = Items.ById[object.Item]
			if other and overlaps(rect, Placement.Rect(object.X, object.Z, other.Footprint, object.Rot)) then
				return false, "ชนกับ " .. other.ThaiName
			end
		end
	end
	return true
end

return Placement
