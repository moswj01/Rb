--[[
	Net — ประกาศ Remote ทั้งหมดในที่เดียว (Server สร้าง, Client รอ)
	หลัก Server-authoritative: Client ส่งแค่ "เจตนา" เซิร์ฟเวอร์ตรวจและตัดสินทุกอย่าง
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.Events = {
	"ProfileChanged", -- server → client: snapshot ข้อมูลผู้เล่น
	"Notify", -- server → client: ข้อความ toast
	"WorldState", -- server → client: เวลา/อากาศ
	"CreatureFeedback", -- server → client: อารมณ์/ความไว้วางใจของสัตว์ (เพื่อแสดงเอฟเฟกต์)
	"Discovery", -- server → client: ค้นพบสัตว์/สถานที่ใหม่
	"SetSneaking", -- client → server: ย่อตัว (ใช้คำนวณความไว้วางใจ)
}

Net.Functions = {
	"GetProfile",
	"CreatureAction", -- (creatureId, action, itemId?)  action: Offer | Calm | Heal | Feed | Pet | Play | Rename | Follow
	"Forage", -- (nodeId)
	"Craft", -- (recipeId)
	"Buy", -- (itemId, amount)
	"Sell", -- (itemId, amount)
	"TalkToNpc", -- (npcId)
	"TravelSanctuary", -- (enter: bool)
	"PlaceObject", -- (itemId, x, z, rotationSteps)
	"MoveObject", -- (objectId, x, z, rotationSteps)
	"RemoveObject", -- (objectId)
	"UseIncubator", -- (objectId, eggItemId)
	"TrackQuest", -- (questId)
	"SaveSettings", -- (settings)
}

local folder

local function getFolder()
	if folder then
		return folder
	end
	if RunService:IsServer() then
		folder = ReplicatedStorage:FindFirstChild("Net") or Instance.new("Folder")
		folder.Name = "Net"
		for _, name in Net.Events do
			if not folder:FindFirstChild(name) then
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = folder
			end
		end
		for _, name in Net.Functions do
			if not folder:FindFirstChild(name) then
				local remote = Instance.new("RemoteFunction")
				remote.Name = name
				remote.Parent = folder
			end
		end
		folder.Parent = ReplicatedStorage
	else
		folder = ReplicatedStorage:WaitForChild("Net")
	end
	return folder
end

function Net.Event(name)
	return getFolder():WaitForChild(name)
end

function Net.Function(name)
	return getFolder():WaitForChild(name)
end

-- Server helper: ผูก handler + rate limit + pcall กัน error หลุดไป client
local lastCall = {}
function Net.Handle(name, handler, cooldown)
	cooldown = cooldown or 0.15
	Net.Function(name).OnServerInvoke = function(player, ...)
		local key = player.UserId .. name
		local now = os.clock()
		if lastCall[key] and now - lastCall[key] < cooldown then
			return false, "ช้าลงหน่อยนะ"
		end
		lastCall[key] = now
		local ok, a, b = pcall(handler, player, ...)
		if not ok then
			warn("[Net]", name, a)
			return false, "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง"
		end
		return a, b
	end
end

-- Client helper
function Net.Invoke(name, ...)
	local args = table.pack(...)
	local ok, a, b = pcall(function()
		return Net.Function(name):InvokeServer(table.unpack(args, 1, args.n))
	end)
	if not ok then
		return false, "การเชื่อมต่อขัดข้อง"
	end
	return a, b
end

return Net
