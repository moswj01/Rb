-- State — สำเนาข้อมูลผู้เล่นฝั่ง client (อ่านอย่างเดียว เซิร์ฟเวอร์เป็นผู้ตัดสิน)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared").Net)

local State = {}
State.Profile = nil
State.World = { Weather = "Clear", Period = "Day" }
State.Zone = "MysticVillage"

local changed = Instance.new("BindableEvent")
State.Changed = changed.Event
local worldChanged = Instance.new("BindableEvent")
State.WorldChanged = worldChanged.Event
local zoneChanged = Instance.new("BindableEvent")
State.ZoneChanged = zoneChanged.Event

function State.SetZone(zone)
	if zone ~= State.Zone then
		State.Zone = zone
		zoneChanged:Fire(zone)
	end
end

function State.Init()
	Net.Event("ProfileChanged").OnClientEvent:Connect(function(profile)
		State.Profile = profile
		changed:Fire(profile)
	end)
	Net.Event("WorldState").OnClientEvent:Connect(function(world)
		State.World = world
		worldChanged:Fire(world)
	end)
	task.spawn(function()
		while not State.Profile do
			local ok, profile = Net.Invoke("GetProfile")
			if ok and type(ok) == "table" then
				profile = ok
			end
			if type(profile) == "table" and not State.Profile then
				State.Profile = profile
				changed:Fire(profile)
			end
			task.wait(1)
		end
	end)
end

function State.Count(itemId)
	return State.Profile and State.Profile.Inventory[itemId] or 0
end

return State
