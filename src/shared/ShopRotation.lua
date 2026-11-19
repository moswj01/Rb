--[[
	ShopRotation — "ของแนะนำวันนี้" ลดราคา เปลี่ยนทุกวันตอน 07:00 น. เวลาไทย (00:00 UTC)
	ใช้ร่วมกันทั้ง Server และ Client จึงได้ผลลัพธ์ตรงกันเสมอ (สุ่มด้วย seed จากเลขวัน)
	หมายเหตุ: ของทุกชิ้นซื้อได้ตลอด — Rotation แค่ "ลดราคา" ไม่ได้ล็อกของ (ไม่กดดันเด็กด้วย FOMO)
]]

local Config = require(script.Parent.Config)
local ItemCatalog = require(script.Parent.ItemCatalog)

local ShopRotation = {}

local DAY = 86400
local cache = { Day = -1, Ids = {}, Set = {} }

local function now()
	-- workspace:GetServerTimeNow() ตรงกันทั้ง client/server
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return ok and t or os.time()
end

function ShopRotation.GetDayNumber(t)
	return math.floor((t or now()) / DAY)
end

function ShopRotation.SecondsUntilReset()
	local t = now()
	return math.max(0, math.ceil((ShopRotation.GetDayNumber(t) + 1) * DAY - t))
end

function ShopRotation.GetFeatured(day)
	day = day or ShopRotation.GetDayNumber()
	if cache.Day == day then
		return cache.Ids, cache.Set
	end

	local pool = {}
	for _, item in ItemCatalog.List do
		if item.Price > 0 and not item.Exclusive then
			table.insert(pool, item.Id)
		end
	end
	table.sort(pool)

	local rng = Random.new(day * 7919 + 13)
	local ids, set = {}, {}
	for _ = 1, math.min(Config.FeaturedCount, #pool) do
		local index = rng:NextInteger(1, #pool)
		local id = table.remove(pool, index)
		table.insert(ids, id)
		set[id] = true
	end

	cache = { Day = day, Ids = ids, Set = set }
	return ids, set
end

function ShopRotation.IsFeatured(itemId)
	local _, set = ShopRotation.GetFeatured()
	return set[itemId] == true
end

function ShopRotation.GetPrice(item)
	if ShopRotation.IsFeatured(item.Id) then
		return math.max(1, math.floor(item.Price * (1 - Config.FeaturedDiscount)))
	end
	return item.Price
end

function ShopRotation.FormatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

return ShopRotation
