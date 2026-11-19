-- Toast — ข้อความแจ้งเตือน (ล่างจอ) + แบนเนอร์ประกาศทั้งเซิร์ฟ (บนจอ)
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemCatalog = require(Shared.ItemCatalog)

local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)

local Toast = {}

local container, announceHolder
local announceQueue = {}
local announcing = false

local KIND_COLORS = {
	good = UIKit.Colors.Good,
	bad = UIKit.Colors.Bad,
	info = UIKit.Colors.Info,
}

function Toast.Show(text, kind)
	if not container or not text or text == "" then
		return
	end
	local toast = UIKit.new("Frame", {
		Size = UDim2.fromOffset(460, 48),
		BackgroundColor3 = KIND_COLORS[kind] or UIKit.Colors.Info,
		BackgroundTransparency = 1,
		Parent = container,
	}, { UIKit.corner(14), UIKit.stroke(UIKit.Colors.Stroke, 2) })
	local label = UIKit.label({
		Text = text,
		Size = UDim2.new(1, -20, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 1,
		MaxTextSize = 22,
		Parent = toast,
	})
	TweenService:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
	task.delay(3.2, function()
		TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.wait(0.45)
		toast:Destroy()
	end)
end

local function playAnnounce()
	if announcing or #announceQueue == 0 then
		return
	end
	announcing = true
	local entry = table.remove(announceQueue, 1)
	local rarity = ItemCatalog.Rarities[entry.Rarity] or ItemCatalog.Rarities.Legendary
	local banner = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -70),
		Size = UDim2.fromOffset(560, 52),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = announceHolder,
	}, {
		UIKit.corner(26),
		UIKit.stroke(Color3.new(1, 1, 1), 3),
		UIKit.gradient(ColorSequence.new(rarity.Color, rarity.Color:Lerp(Color3.new(0, 0, 0), 0.25)), 0),
	})
	UIKit.label({ Text = entry.Text, Size = UDim2.new(1, -24, 1, -10), Position = UDim2.fromOffset(12, 5), TextColor3 = Color3.new(1, 1, 1), Outline = 2, MaxTextSize = 24, Parent = banner })
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 0) }):Play()
	task.delay(4, function()
		TweenService:Create(banner, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0, -70) }):Play()
		task.wait(0.35)
		banner:Destroy()
		announcing = false
		playAnnounce()
	end)
end

function Toast.Announce(text, rarity)
	table.insert(announceQueue, { Text = text, Rarity = rarity })
	if #announceQueue > 5 then
		table.remove(announceQueue, 1)
	end
	playAnnounce()
end

function Toast.Init()
	local gui = UIKit.screenGui("Toasts", 25)
	container = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(460, 230),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UIKit.new("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
	})
	UIKit.autoScale(container, 700, 600)

	announceHolder = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 110),
		Size = UDim2.fromOffset(560, 60),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Parent = gui,
	})
	UIKit.autoScale(announceHolder, 900, 650)

	Net.Get("Notify").OnClientEvent:Connect(Toast.Show)
	Net.Get("Announce").OnClientEvent:Connect(Toast.Announce)
end

return Toast
