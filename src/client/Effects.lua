-- Effects — แอนิเมชันฝั่ง client (ลื่นไหล ไม่กินแรงเซิร์ฟเวอร์)
--   Rainbow  : เปลี่ยนสีวนสายรุ้ง
--   SpinWeld : ใบพัดหมวกหมุน
--   Bob      : ดาวลอยขึ้นลง + หมุน
--   แท็ก [👑 VIP] ในแชท
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local Effects = {}

local bobBase = {} -- [Part] = CFrame เริ่มต้น

local function trackBob(part)
	bobBase[part] = part.CFrame
end

function Effects.Init()
	for _, part in CollectionService:GetTagged("Bob") do
		trackBob(part)
	end
	CollectionService:GetInstanceAddedSignal("Bob"):Connect(trackBob)
	CollectionService:GetInstanceRemovedSignal("Bob"):Connect(function(part)
		bobBase[part] = nil
	end)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()

		local hue = (t * 0.25) % 1
		for i, part in CollectionService:GetTagged("Rainbow") do
			if part:IsA("BasePart") then
				part.Color = Color3.fromHSV((hue + i * 0.07) % 1, 0.7, 1)
			end
		end

		for _, w in CollectionService:GetTagged("SpinWeld") do
			local base = w:GetAttribute("BaseC0")
			if base then
				w.C0 = base * CFrame.Angles(0, t * 14, 0)
			end
		end

		for part, base in bobBase do
			if part.Parent then
				local offset = math.sin(t * 2 + base.Position.X) * 0.5
				part.CFrame = base * CFrame.new(0, offset, 0) * CFrame.Angles(0, t * 1.5, 0)
			else
				bobBase[part] = nil
			end
		end
	end)

	-- แท็ก VIP ในแชท (TextChatService)
	TextChatService.OnIncomingMessage = function(message)
		local properties = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		if source then
			local speaker = Players:GetPlayerByUserId(source.UserId)
			if speaker and speaker:GetAttribute("VIP") then
				properties.PrefixText = "<font color='#FFD028'>[👑 VIP]</font> " .. message.PrefixText
			end
		end
		return properties
	end
end

return Effects
