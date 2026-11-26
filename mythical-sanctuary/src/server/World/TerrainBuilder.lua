--[[
	TerrainBuilder — ปั้นภูมิประเทศด้วย Roblox Terrain (voxel) จาก WorldLayout
	ผลลัพธ์เป็นผิวโค้งต่อเนื่องแบบ organic ไม่ใช่ Part สี่เหลี่ยม:
	  • เนินเขาหลายระดับความถี่ (noise 3 ชั้น) + หน้าผาขอบโลกปิดล้อม
	  • ที่ราบหมู่บ้าน, ลานโล่งต้นไม้ผู้เฒ่า, เนินวิหาร, เนินถ้ำ, หน้าผาน้ำตก
	  • แม่น้ำไหลลดหลั่น มีตลิ่ง, ทางเดินกลืนกับพื้น, วัสดุเปลี่ยนตามความชัน/ความสูง/ความชื้น
	  • ถ้ำลับเจาะด้วยลูกบอลอากาศ

	Bake ใน Studio (แนะนำ เพื่อให้ Environment Artist ปั้นต่อด้วยมือ):
	  Command Bar: require(game.ServerScriptService.Server.World.TerrainBuilder).BuildWorld(true)
	  แล้ว Save — เมื่อ workspace มี Attribute "WorldBaked" เกมจะไม่สร้างทับอีก
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldLayout = require(Shared.WorldLayout)

local TerrainBuilder = {}

local T = WorldLayout.Terrain
local M = Enum.Material
local VOXEL = T.VoxelSize

local function smoothstep(e0, e1, x)
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

-- ระยะจากจุดถึงเส้นโพลีไลน์ (XZ) + พารามิเตอร์ตามความยาว
local function polylineDistance(points, x, z, getPos)
	local best, bestT, bestIndex = math.huge, 0, 1
	for i = 1, #points - 1 do
		local a, b = getPos(points[i]), getPos(points[i + 1])
		local abx, abz = b.X - a.X, b.Z - a.Z
		local len2 = abx * abx + abz * abz
		local t = len2 > 0 and math.clamp(((x - a.X) * abx + (z - a.Z) * abz) / len2, 0, 1) or 0
		local px, pz = a.X + abx * t, a.Z + abz * t
		local d = math.sqrt((x - px) ^ 2 + (z - pz) ^ 2)
		if d < best then
			best, bestT, bestIndex = d, t, i
		end
	end
	return best, bestIndex, bestT
end

local function riverPos(p)
	return p.Pos
end
local function identity(p)
	return p
end

function TerrainBuilder.River(x, z)
	local points = WorldLayout.River.Points
	-- คดเคี้ยวเล็กน้อยด้วย noise ไม่ให้แม่น้ำเป็นเส้นตรง
	local wobble = math.noise(x / 60, z / 60, 7.3) * 9
	local d, index, t = polylineDistance(points, x + wobble, z, riverPos)
	local level = lerp(points[index].Level, points[index + 1].Level, t)
	return d, level
end

function TerrainBuilder.Path(x, z)
	local best, material, width = math.huge, nil, 0
	for _, path in WorldLayout.Paths do
		local d = polylineDistance(path.Points, x, z, identity)
		local edge = d - path.Width / 2
		if edge < best then
			best, material, width = edge, path.Material, path.Width
		end
	end
	return best, material, width
end

local function inVillage(x, z)
	local c = WorldLayout.Village.Center
	return math.sqrt((x - c.X) ^ 2 + (z - c.Z) ^ 2)
end

-- ===== ฟังก์ชันความสูงหลัก =====
function TerrainBuilder.HeightAt(x, z)
	local h = T.BaseHeight
		+ math.noise(x / 260, z / 260, 0.3) * 18
		+ math.noise(x / 95, z / 95, 1.7) * 7
		+ math.noise(x / 28, z / 28, 3.1) * 1.6

	-- หน้าผาขอบโลก (ปิดล้อมอย่างเป็นธรรมชาติ ไม่ใช่กำแพง)
	local edge = math.min(x - T.Min.X, T.Max.X - x, z - T.Min.Z, T.Max.Z - z)
	if edge < T.RimWidth then
		local t = 1 - edge / T.RimWidth
		h += (t ^ 2.2) * T.RimHeight * (0.75 + 0.35 * math.noise(x / 80, z / 80, 9.1))
	end

	-- สันเขาในป่า (ridged noise): ป่ามีเนินและหุบเขา ทางเดิน/แม่น้ำจะอยู่ในหุบ (ทางธรรมชาติ)
	local villageD = inVillage(x, z)
	local forestness = smoothstep(WorldLayout.Village.Radius * 1.1, WorldLayout.Village.Radius * 2.2, villageD)
	if forestness > 0 then
		local ridge = 1 - math.abs(math.noise(x / 170, z / 170, 12.5))
		local valley = smoothstep(6, 34, TerrainBuilder.Path(x, z)) * smoothstep(WorldLayout.River.Width, WorldLayout.River.Width * 3.5, (TerrainBuilder.River(x, z)))
		h += (ridge ^ 2.2) * 34 * forestness * valley
		h += math.noise(x / 55, z / 55, 14.2) * 5 * forestness
	end

	for _, f in WorldLayout.Features do
		local d = math.sqrt((x - f.Center.X) ^ 2 + (z - f.Center.Z) ^ 2)
		if d < f.Radius * 1.4 then
			local w = 1 - smoothstep(f.Radius * 0.55, f.Radius * 1.4, d)
			if f.Kind == "Clearing" then
				h = lerp(h, f.Height + math.noise(x / 18, z / 18) * 0.8, w)
			elseif f.Kind == "Mound" then
				h += f.Height * w
			elseif f.Kind == "Hill" then
				local cone = smoothstep(0, 1, 1 - d / (f.Radius * 1.4))
				h += f.Height * (cone ^ 1.3) * (0.85 + 0.25 * math.noise(x / 40, z / 40, 4.4))
			elseif f.Kind == "Cliff" then
				h += f.Height * smoothstep(0, 1, w * 1.6)
			end
		end
	end

	-- ที่ราบหมู่บ้าน: ราบแต่ไม่เรียบเป๊ะ
	local dv = inVillage(x, z)
	local village = WorldLayout.Village
	if dv < village.Radius * 1.5 then
		local w = 1 - smoothstep(village.Radius * 0.75, village.Radius * 1.5, dv)
		h = lerp(h, village.Height + math.noise(x / 40, z / 40, 5.5) * 1.4, w)
	end

	-- ทางเดิน: ลดความขรุขระ
	local pathEdge = TerrainBuilder.Path(x, z)
	if pathEdge < 6 then
		local w = 1 - smoothstep(-2, 6, pathEdge)
		h = lerp(h, T.BaseHeight + (h - T.BaseHeight) * 0.92, w)
	end

	-- แม่น้ำ: ร่องน้ำ + ตลิ่ง
	local rd, level = TerrainBuilder.River(x, z)
	local half = WorldLayout.River.Width / 2
	if rd < half * 2.6 then
		local bank = level + 1.5
		if rd < half then
			local bed = level - 3 - (1 - rd / half) * 5
			h = math.min(h, bed)
		else
			local w = 1 - smoothstep(half, half * 2.6, rd)
			h = lerp(h, math.max(bank, math.min(h, bank + (rd - half) * 0.45)), w)
		end
	end
	return h
end

local function surfaceMaterial(x, z, h, slope, zoneHint)
	local pathEdge, pathMaterial = TerrainBuilder.Path(x, z)
	local rd, level = TerrainBuilder.River(x, z)
	local half = WorldLayout.River.Width / 2
	if h < level + 0.5 and rd < half * 1.3 then
		return (math.noise(x / 12, z / 12) > 0) and M.Sand or M.Ground
	end
	if pathEdge < 0 then
		return M[pathMaterial] or M.Ground
	end
	if slope > 1.1 or h > 95 then
		return (math.noise(x / 30, z / 30, 2) > 0.2) and M.Slate or M.Rock
	end
	if slope > 0.7 then
		return M.Rock
	end
	if rd < half * 2.2 then
		return (math.noise(x / 9, z / 9, 6) > 0.1) and M.Mud or M.Grass
	end
	if pathEdge < 2.5 then
		return M.Ground -- ขอบทางเดินฝุ่นดิน (soft edge)
	end
	if zoneHint == "Village" then
		return (math.noise(x / 22, z / 22, 8) > 0.45) and M.LeafyGrass or M.Grass
	end
	local n = math.noise(x / 26, z / 26, 11)
	if n > 0.35 then
		return M.Ground
	elseif n < -0.3 then
		return M.Grass
	end
	return M.LeafyGrass
end

-- เขียน voxel ทีละ chunk (มี yield เพื่อไม่ให้เซิร์ฟค้าง)
local function writeRegion(minX, maxX, minZ, maxZ, heightFn, materialFn, waterFn)
	local terrain = workspace.Terrain
	local chunk = 64
	for cx = minX, maxX - 1, chunk do
		for cz = minZ, maxZ - 1, chunk do
			local nx, nz = chunk / VOXEL, chunk / VOXEL
			-- ความสูงพร้อมขอบ 1 ช่องสำหรับคำนวณความชัน
			local heights = {}
			local lowest, highest = math.huge, -math.huge
			for i = 0, nx + 1 do
				heights[i] = {}
				for k = 0, nz + 1 do
					local x = cx + (i - 0.5) * VOXEL
					local z = cz + (k - 0.5) * VOXEL
					local h = heightFn(x, z)
					heights[i][k] = h
					lowest = math.min(lowest, h)
					highest = math.max(highest, h)
				end
			end
			local waterTop = -math.huge
			local waters = {}
			for i = 1, nx do
				waters[i] = {}
				for k = 1, nz do
					local w = waterFn(cx + (i - 0.5) * VOXEL, cz + (k - 0.5) * VOXEL, heights[i][k])
					waters[i][k] = w
					if w then
						waterTop = math.max(waterTop, w)
					end
				end
			end
			local y0 = math.floor((lowest - 12) / VOXEL) * VOXEL
			local y1 = math.ceil((math.max(highest, waterTop) + VOXEL) / VOXEL) * VOXEL
			local ny = (y1 - y0) / VOXEL

			local materials, occupancy = {}, {}
			for i = 1, nx do
				materials[i], occupancy[i] = {}, {}
				local x = cx + (i - 0.5) * VOXEL
				for j = 1, ny do
					materials[i][j], occupancy[i][j] = {}, {}
				end
				for k = 1, nz do
					local z = cz + (k - 0.5) * VOXEL
					local h = heights[i][k]
					local slope = (math.abs(heights[i + 1][k] - heights[i - 1][k]) + math.abs(heights[i][k + 1] - heights[i][k - 1])) / (2 * VOXEL)
					local surface = materialFn(x, z, h, slope)
					local water = waters[i][k]
					for j = 1, ny do
						local yb = y0 + (j - 1) * VOXEL
						local occ = math.clamp((h - yb) / VOXEL, 0, 1)
						local mat = M.Air
						if occ > 0 then
							local depth = h - yb
							if depth > 14 then
								mat = M.Rock
							elseif depth > 6 and surface ~= M.Rock and surface ~= M.Slate then
								mat = M.Ground
							else
								mat = surface
							end
						end
						if water and occ < 1 and yb < water then
							local wocc = math.clamp((water - yb) / VOXEL, 0, 1)
							if occ < 0.5 then
								mat = M.Water
								occ = math.max(occ, wocc)
							end
						end
						materials[i][j][k] = mat
						occupancy[i][j][k] = occ
					end
				end
			end
			local region = Region3.new(Vector3.new(cx, y0, cz), Vector3.new(cx + chunk, y1, cz + chunk))
			terrain:WriteVoxels(region, VOXEL, materials, occupancy)
			task.wait()
		end
	end
end

local function worldMaterial(x, z, h, slope)
	local hint = inVillage(x, z) < WorldLayout.Village.Radius and "Village" or "Forest"
	return surfaceMaterial(x, z, h, slope, hint)
end

local function worldWater(x, z, h)
	local rd, level = TerrainBuilder.River(x, z)
	if rd < WorldLayout.River.Width * 1.4 and h < level then
		return level
	end
	return nil
end

-- ตำแหน่งถ้ำคำนวณจากผิวเนินจริง: ปากถ้ำเปิดที่ผิวดิน แล้วอุโมงค์ลาดลงไปใต้เนิน
function TerrainBuilder.Cave()
	local cave = WorldLayout.HiddenCave
	local e = cave.Entrance
	local entranceY = TerrainBuilder.HeightAt(e.X, e.Z) + 1
	local tunnel = {}
	for i, p in cave.Tunnel do
		tunnel[i] = Vector3.new(p.X, entranceY - (i - 1) * 1.5, p.Z)
	end
	local c = cave.Chamber.Center
	local chamber = Vector3.new(c.X, entranceY - 6, c.Z)
	return { Entrance = Vector3.new(e.X, entranceY, e.Z), Tunnel = tunnel, Chamber = chamber, Radius = cave.Chamber.Radius, FloorY = chamber.Y - 1 }
end

local function carveCave()
	local terrain = workspace.Terrain
	local cave = TerrainBuilder.Cave()
	for i = 1, #cave.Tunnel - 1 do
		local a, b = cave.Tunnel[i], cave.Tunnel[i + 1]
		for s = 0, 1, 0.2 do
			local p = a:Lerp(b, s)
			terrain:FillBall(p + Vector3.new(0, 4, 0), 7 + math.noise(p.X / 10, p.Z / 10) * 1.5, M.Air)
		end
	end
	local last = cave.Tunnel[#cave.Tunnel]
	for s = 0, 1, 0.25 do
		local p = last:Lerp(cave.Chamber, s)
		terrain:FillBall(p + Vector3.new(0, 4, 0), 7, M.Air)
	end
	terrain:FillBall(cave.Chamber + Vector3.new(0, 8, 0), cave.Radius, M.Air)
	terrain:FillBall(cave.Chamber + Vector3.new(6, 4, -4), cave.Radius * 0.7, M.Air)
	-- พื้นห้องโถง + แอ่งน้ำใต้ดินเล็ก ๆ
	terrain:FillCylinder(CFrame.new(cave.Chamber - Vector3.new(0, 4, 0)), 6, cave.Radius * 1.6, M.Basalt)
	terrain:FillCylinder(CFrame.new(cave.Chamber + Vector3.new(-6, -0.5, 6)), 2, 12, M.Water)
end

function TerrainBuilder.BuildWorld(markBaked)
	if workspace:GetAttribute("WorldBaked") and not markBaked then
		return false
	end
	local terrain = workspace.Terrain
	terrain:Clear()
	terrain.Decoration = true
	terrain.WaterColor = Color3.fromRGB(46, 120, 128)
	terrain.WaterTransparency = 0.55
	terrain.WaterReflectance = 0.6
	terrain.WaterWaveSize = 0.08
	terrain.WaterWaveSpeed = 6
	pcall(function()
		terrain:SetMaterialColor(M.Grass, Color3.fromRGB(108, 150, 72))
		terrain:SetMaterialColor(M.LeafyGrass, Color3.fromRGB(78, 120, 64))
		terrain:SetMaterialColor(M.Ground, Color3.fromRGB(116, 92, 68))
		terrain:SetMaterialColor(M.Mud, Color3.fromRGB(86, 70, 56))
		terrain:SetMaterialColor(M.Rock, Color3.fromRGB(120, 116, 108))
		terrain:SetMaterialColor(M.Slate, Color3.fromRGB(96, 98, 104))
		terrain:SetMaterialColor(M.Cobblestone, Color3.fromRGB(150, 140, 124))
		terrain:SetMaterialColor(M.Sand, Color3.fromRGB(196, 178, 140))
	end)
	writeRegion(T.Min.X, T.Max.X, T.Min.Z, T.Max.Z, TerrainBuilder.HeightAt, worldMaterial, worldWater)
	carveCave()
	if markBaked then
		workspace:SetAttribute("WorldBaked", true)
	end
	return true
end

-- ===== เกาะเขตอนุรักษ์ส่วนตัว =====
function TerrainBuilder.IslandHeightAt(origin, x, z)
	local lx, lz = x - origin.X, z - origin.Z
	local d = math.sqrt(lx * lx + lz * lz)
	local radius = 175 + math.noise(lx / 70, lz / 70, 2.2) * 22
	local h = 24 + math.noise(lx / 90, lz / 90, 1.1) * 7 + math.noise(lx / 25, lz / 25, 4.4) * 1.2
	-- เนินด้านหลังเป็นฉากหลัง (background) ให้เกาะมีมิติ
	local hill = math.sqrt((lx + 30) ^ 2 + (lz + 120) ^ 2)
	h += 26 * (1 - smoothstep(20, 90, hill))
	-- บ่อน้ำกลางเกาะ
	local pond = math.sqrt((lx - 55) ^ 2 + (lz - 30) ^ 2)
	if pond < 26 then
		h = math.min(h, 17 + pond * 0.25)
	end
	-- ชายฝั่ง
	h = lerp(h, 4, smoothstep(radius - 30, radius + 10, d))
	return h
end

function TerrainBuilder.BuildIsland(origin)
	local size = 220
	local function heightFn(x, z)
		return TerrainBuilder.IslandHeightAt(origin, x, z)
	end
	local function materialFn(x, z, h, slope)
		local lx, lz = x - origin.X, z - origin.Z
		if h < 13 then
			return M.Sand
		end
		if slope > 0.8 then
			return M.Rock
		end
		if math.sqrt((lx - 55) ^ 2 + (lz - 30) ^ 2) < 30 then
			return M.Mud
		end
		return (math.noise(lx / 20, lz / 20, 3) > 0.3) and M.LeafyGrass or M.Grass
	end
	local function waterFn(x, z, h)
		local lx, lz = x - origin.X, z - origin.Z
		if math.sqrt((lx - 55) ^ 2 + (lz - 30) ^ 2) < 26 and h < 21 then
			return 21
		end
		if h < 10 then
			return 10
		end
		return nil
	end
	-- ผิวทะเลรอบเกาะ (ฉากหลัง) แล้วค่อยเขียนตัวเกาะทับ
	workspace.Terrain:FillBlock(CFrame.new(origin + Vector3.new(0, 6, 0)), Vector3.new(1100, 8, 1100), M.Water)
	writeRegion(origin.X - size, origin.X + size, origin.Z - size, origin.Z + size, heightFn, materialFn, waterFn)
end

function TerrainBuilder.ClearIsland(origin)
	local size = 224
	local region = Region3.new(origin - Vector3.new(size, 60, size), origin + Vector3.new(size, 140, size)):ExpandToGrid(VOXEL)
	workspace.Terrain:FillRegion(region, VOXEL, M.Air)
end

return TerrainBuilder
