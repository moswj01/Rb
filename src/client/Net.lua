-- Net — ตัวช่วยคุยกับเซิร์ฟเวอร์ + เก็บข้อมูลผู้เล่นล่าสุด
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Net = {}
Net.Data = nil

local changed = Instance.new("BindableEvent")
Net.Changed = changed.Event

function Net.Get(name)
	return Remotes:WaitForChild(name)
end

-- เรียก RemoteFunction แบบปลอดภัย คืนค่า (ok, message)
function Net.Invoke(name, ...)
	local remote = Net.Get(name)
	local args = table.pack(...)
	local ok, a, b = pcall(function()
		return remote:InvokeServer(table.unpack(args, 1, args.n))
	end)
	if not ok then
		return false, "เชื่อมต่อไม่ได้ ลองใหม่อีกครั้งนะ"
	end
	return a, b
end

local function setData(data)
	Net.Data = data
	changed:Fire(data)
end

function Net.Init()
	Net.Get("DataChanged").OnClientEvent:Connect(setData)
	task.spawn(function()
		while not Net.Data do
			local ok, data = pcall(function()
				return Net.Get("GetData"):InvokeServer()
			end)
			if ok and data and not Net.Data then
				setData(data)
			end
			if not Net.Data then
				task.wait(1)
			end
		end
	end)
end

return Net
