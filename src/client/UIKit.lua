-- UIKit — ชุดเครื่องมือสร้าง UI โทนสีพาสเทลน่ารัก ใช้ได้ทั้ง PC / มือถือ / แท็บเล็ต
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local UIKit = {}

UIKit.Font = Enum.Font.FredokaOne
UIKit.Colors = {
	Panel = Color3.fromRGB(255, 250, 245),
	Header = Color3.fromRGB(255, 120, 185),
	Text = Color3.fromRGB(70, 45, 90),
	SubText = Color3.fromRGB(140, 120, 160),
	Coin = Color3.fromRGB(255, 195, 40),
	Gem = Color3.fromRGB(80, 200, 255),
	Good = Color3.fromRGB(80, 210, 120),
	Bad = Color3.fromRGB(255, 95, 110),
	Info = Color3.fromRGB(120, 140, 255),
	Button = Color3.fromRGB(255, 140, 200),
	Muted = Color3.fromRGB(215, 205, 225),
	Stroke = Color3.fromRGB(90, 50, 110),
}

function UIKit.new(className, props, children)
	local instance = Instance.new(className)
	local parent
	for key, value in props or {} do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function UIKit.corner(radius)
	return UIKit.new("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function UIKit.stroke(color, thickness)
	return UIKit.new("UIStroke", {
		Color = color or UIKit.Colors.Stroke,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UIKit.padding(px)
	local u = UDim.new(0, px)
	return UIKit.new("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u })
end

function UIKit.label(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = UIKit.Font,
		TextColor3 = UIKit.Colors.Text,
		TextScaled = true,
		Text = "",
	}
	for key, value in props do
		defaults[key] = value
	end
	local maxText = defaults.MaxTextSize or 28
	defaults.MaxTextSize = nil
	local label = UIKit.new("TextLabel", defaults)
	if defaults.TextScaled then
		UIKit.new("UITextSizeConstraint", { MaxTextSize = maxText, Parent = label })
	end
	return label
end

-- ปุ่มเด้ง ๆ น่ากด
function UIKit.button(props, onClick)
	local defaults = {
		BackgroundColor3 = UIKit.Colors.Button,
		Font = UIKit.Font,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		AutoButtonColor = true,
		Text = "",
	}
	local maxText = props.MaxTextSize or 24
	props.MaxTextSize = nil
	for key, value in props do
		defaults[key] = value
	end
	local button = UIKit.new("TextButton", defaults, {
		UIKit.corner(12),
		UIKit.stroke(UIKit.Colors.Stroke, 2),
		UIKit.new("UITextSizeConstraint", { MaxTextSize = maxText }),
		UIKit.new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
	})
	local scale = UIKit.new("UIScale", { Parent = button })
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.05 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)
	if onClick then
		button.Activated:Connect(function()
			scale.Scale = 0.92
			TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			UIKit.click()
			onClick()
		end)
	end
	return button
end

local clickSound = UIKit.new("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.25 })
function UIKit.click()
	if not clickSound.Parent then
		clickSound.Parent = workspace.CurrentCamera
	end
	clickSound.PlaybackSpeed = 1.6
	clickSound:Play()
end

-- ย่อ/ขยาย UI ตามขนาดจอ (มือถือจอเล็กก็ใช้ได้)
function UIKit.autoScale(guiObject, baseWidth, baseHeight)
	local scale = UIKit.new("UIScale", { Parent = guiObject })
	local function update()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local view = camera.ViewportSize
		scale.Scale = math.clamp(math.min(view.X / baseWidth, view.Y / baseHeight), 0.45, 1.25)
	end
	update()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	return scale
end

function UIKit.screenGui(name)
	return UIKit.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
end

-- หน้าต่างมาตรฐาน: หัวข้อ + ปุ่มปิด  คืนค่า (window, content)
function UIKit.window(gui, title, size)
	local window = UIKit.new("Frame", {
		Name = title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundColor3 = UIKit.Colors.Panel,
		Visible = false,
		Parent = gui,
	}, { UIKit.corner(20), UIKit.stroke(UIKit.Colors.Stroke, 3) })
	UIKit.autoScale(window, size.X.Offset + 40, size.Y.Offset + 80)

	local header = UIKit.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = UIKit.Colors.Header,
		Parent = window,
	}, { UIKit.corner(20) })
	-- ปิดมุมล่างของหัวให้เหลี่ยม
	UIKit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, -20),
		BackgroundColor3 = UIKit.Colors.Header,
		BorderSizePixel = 0,
		Parent = header,
	})
	UIKit.label({
		Text = title,
		Size = UDim2.new(1, -120, 1, -10),
		Position = UDim2.fromOffset(18, 5),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
		MaxTextSize = 30,
		ZIndex = 2,
		Parent = header,
	})
	UIKit.button({
		Text = "✖",
		Size = UDim2.fromOffset(42, 42),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = UIKit.Colors.Bad,
		ZIndex = 2,
		Parent = header,
	}, function()
		UIKit.close(window)
	end)

	local content = UIKit.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -24, 1, -70),
		Position = UDim2.fromOffset(12, 62),
		BackgroundTransparency = 1,
		Parent = window,
	})
	return window, content
end

local openWindows = {}

function UIKit.open(window)
	for other in openWindows do
		if other ~= window then
			UIKit.close(other)
		end
	end
	openWindows[window] = true
	window.Visible = true
	window.Position = UDim2.fromScale(0.5, 0.56)
	TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
end

function UIKit.close(window)
	openWindows[window] = nil
	window.Visible = false
end

function UIKit.toggle(window)
	if window.Visible then
		UIKit.close(window)
	else
		UIKit.open(window)
	end
end

function UIKit.formatNumber(n)
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

return UIKit
