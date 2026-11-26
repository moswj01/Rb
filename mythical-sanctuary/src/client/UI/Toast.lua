-- Toast — ข้อความแจ้งเตือนกลางบนจอ + แบนเนอร์ "ค้นพบ" แบบ cinematic
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local Toast = {}

local Colors = Theme.Colors
local stack, banner, bannerTitle, bannerSub
local KIND = {
	info = Colors.Gold,
	warn = Colors.Rose,
	quest = Colors.GoldBright,
	creature = Color3.fromRGB(170, 230, 190),
	level = Colors.GoldBright,
}

function Toast.Show(text, kind)
	if not stack or not text or text == "" then
		return
	end
	local item = Theme.new("Frame", { Size = UDim2.fromOffset(460, 40), BackgroundColor3 = Colors.MidnightDeep, BackgroundTransparency = 1, Parent = stack }, {
		Theme.corner(6),
		Theme.stroke(KIND[kind] or Colors.Gold, 1.2, 1),
	})
	local label = Theme.text({ Text = text, Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), TextSize = 17, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, Parent = item })
	local stroke = item:FindFirstChildOfClass("UIStroke")
	TweenService:Create(item, TweenInfo.new(0.25), { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	TweenService:Create(stroke, TweenInfo.new(0.25), { Transparency = 0 }):Play()
	task.delay(3.4, function()
		TweenService:Create(item, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		task.wait(0.55)
		item:Destroy()
	end)
end

-- "✦ ค้นพบใหม่ ✦" ตัวอักษรทองใหญ่ค่อย ๆ ปรากฏแล้วจางหาย
function Toast.Banner(title, subtitle)
	bannerTitle.Text = title
	bannerSub.Text = subtitle or ""
	banner.Visible = true
	bannerTitle.TextTransparency, bannerSub.TextTransparency = 1, 1
	TweenService:Create(bannerTitle, TweenInfo.new(1.2), { TextTransparency = 0 }):Play()
	TweenService:Create(bannerSub, TweenInfo.new(1.6), { TextTransparency = 0.1 }):Play()
	task.delay(4, function()
		TweenService:Create(bannerTitle, TweenInfo.new(1.4), { TextTransparency = 1 }):Play()
		TweenService:Create(bannerSub, TweenInfo.new(1.4), { TextTransparency = 1 }):Play()
	end)
end

function Toast.Init(gui)
	stack = Theme.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.fromOffset(460, 220), BackgroundTransparency = 1, Parent = gui }, {
		Theme.new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	})
	Theme.scale(stack, 900, 640)
	banner = Theme.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(800, 110), BackgroundTransparency = 1, Visible = false, Parent = gui })
	Theme.scale(banner, 900, 640)
	bannerTitle = Theme.title({ Size = UDim2.new(1, 0, 0, 64), TextSize = 52, TextXAlignment = Enum.TextXAlignment.Center, Parent = banner })
	Theme.new("UIStroke", { Color = Colors.MidnightDeep, Thickness = 2, Transparency = 0.3, Parent = bannerTitle })
	bannerSub = Theme.text({ Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 66), TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Colors.Ivory, Parent = banner })
end

return Toast
