-- Toast — ข้อความแจ้งเตือนเด้งขึ้นกลางล่างจอ
local TweenService = game:GetService("TweenService")

local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)

local Toast = {}

local container

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
		Size = UDim2.fromOffset(440, 46),
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
	task.delay(3, function()
		TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.wait(0.45)
		toast:Destroy()
	end)
end

function Toast.Init()
	local gui = UIKit.screenGui("Toasts")
	gui.DisplayOrder = 20
	container = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(440, 220),
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
	Net.Get("Notify").OnClientEvent:Connect(Toast.Show)
end

return Toast
