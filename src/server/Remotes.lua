-- สร้าง RemoteEvent / RemoteFunction ทั้งหมดไว้ใน ReplicatedStorage.Remotes
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENTS = { "DataChanged", "Notify", "RoundState", "CoinPopup" }
local FUNCTIONS = { "GetData", "BuyItem", "EquipItem", "ClaimDaily", "RedeemCode", "SetSkipRounds" }

local folder = Instance.new("Folder")
folder.Name = "Remotes"

local Remotes = {}

for _, name in EVENTS do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	Remotes[name] = remote
end

for _, name in FUNCTIONS do
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = folder
	Remotes[name] = remote
end

folder.Parent = ReplicatedStorage

-- ส่งข้อความแจ้งเตือนแบบ toast ให้ผู้เล่น  kind = "good" | "bad" | "info"
Remotes.NotifyEvent = folder.Notify
function Remotes.Notify(player, text, kind)
	Remotes.NotifyEvent:FireClient(player, text, kind or "info")
end
function Remotes.NotifyAll(text, kind)
	Remotes.NotifyEvent:FireAllClients(text, kind or "info")
end

return Remotes
