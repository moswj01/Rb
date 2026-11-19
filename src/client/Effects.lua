-- Effects — แอนิเมชันฝั่ง client (ลื่นไหล ไม่กินแรงเซิร์ฟเวอร์)
--   Rainbow      : Part เปลี่ยนสีวนสายรุ้ง
--   RainbowTrail : หางสายรุ้งไหลได้
--   SpinWeld     : ใบพัด/ออร่าโคจร หมุน
--   FlapWeld     : ปีกกระพือ
--   ShineGradient: ฉายาระดับสูงมีแสงวิ่ง
--   Bob          : ดาวลอยขึ้นลง + หมุน
--   Blink        : ไฟรันเวย์กะพริบ
--   แท็ก [👑 VIP] ในแชท
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local Effects = {}

local bobBase = {}
local blinkParts = {}

local function trackBob(part)
	if part:IsA("BasePart") then
		bobBase[part] = part.CFrame
	end
end

local function rainbowSequence(offset)
	local keys = {}
	for i = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6 + offset) % 1, 0.75, 1)))
	end
	return ColorSequence.new(keys)
end

function Effects.Init()
	for _, part in CollectionService:GetTagged("Bob") do
		trackBob(part)
	end
	CollectionService:GetInstanceAddedSignal("Bob"):Connect(trackBob)
	CollectionService:GetInstanceRemovedSignal("Bob"):Connect(function(part)
		bobBase[part] = nil
	end)

	task.spawn(function()
		local map = workspace:WaitForChild("Map", 30)
		if map then
			for _, d in map:GetDescendants() do
				if d:IsA("BasePart") and d:GetAttribute("Blink") then
					table.insert(blinkParts, d)
				end
			end
		end
	end)

	local trailTimer = 0
	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		local hue = (t * 0.25) % 1

		for i, part in CollectionService:GetTagged("Rainbow") do
			if part:IsA("BasePart") then
				part.Color = Color3.fromHSV((hue + i * 0.07) % 1, 0.7, 1)
			end
		end

		trailTimer += dt
		if trailTimer > 0.1 then
			trailTimer = 0
			local sequence = rainbowSequence(hue)
			for _, trail in CollectionService:GetTagged("RainbowTrail") do
				trail.Color = sequence
			end
		end

		for _, weld in CollectionService:GetTagged("SpinWeld") do
			local base = weld:GetAttribute("BaseC0")
			if base then
				weld.C0 = base * CFrame.Angles(0, t * (weld:GetAttribute("Speed") or 1), 0)
			end
		end

		for _, weld in CollectionService:GetTagged("FlapWeld") do
			local base = weld:GetAttribute("BaseC0")
			if base then
				local side = weld:GetAttribute("Side") or 1
				local speed = weld:GetAttribute("Speed") or 1
				local amp = weld:GetAttribute("Amp") or 0.35
				weld.C0 = base * CFrame.Angles(0, side * math.sin(t * speed * 2) * amp, 0)
			end
		end

		for _, gradient in CollectionService:GetTagged("ShineGradient") do
			gradient.Offset = Vector2.new(math.sin(t * 1.5) * 0.4, 0)
		end

		for part, base in bobBase do
			if part.Parent then
				local offset = math.sin(t * 2 + base.Position.X) * 0.5
				part.CFrame = base * CFrame.new(0, offset, 0) * CFrame.Angles(0, t * 1.5, 0)
			else
				bobBase[part] = nil
			end
		end

		for _, part in blinkParts do
			local index = part:GetAttribute("Blink") or 0
			part.Color = Color3.fromHSV((hue * 2 + index * 0.09) % 1, 0.55, 1)
		end
	end)

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
