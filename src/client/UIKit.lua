-- UIKit — ชุดเครื่องมือสร้าง UI โทนพาสเทล ใช้ได้ทั้ง PC / มือถือ / แท็บเล็ต
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local UIKit = {}

UIKit.Font = Enum.Font.FredokaOne
UIKit.Colors = {
	Panel = Color3.fromRGB(255, 250, 245),
	PanelDark = Color3.fromRGB(245, 235, 250),
	Header = Color3.fromRGB(255, 110, 180),
	HeaderDark = Color3.fromRGB(190, 70, 200),
	Text = Color3.fromRGB(70, 45, 90),
	SubText = Color3.fromRGB(140, 120, 160),
	Coin = Color3.fromRGB(255, 190, 30),
	Gem = Color3.fromRGB(70, 195, 255),
	Robux = Color3.fromRGB(40, 200, 110),
	Good = Color3.fromRGB(70, 205, 115),
	Bad = Color3.fromRGB(255, 90, 105),
	Info = Color3.fromRGB(120, 130, 255),
	Button = Color3.fromRGB(255, 140, 200),
	Muted = Color3.fromRGB(215, 205, 225),
	Stroke = Color3.fromRGB(90, 50, 110),
	Gold = Color3.fromRGB(255, 205, 60),
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

function UIKit.gradient(sequence, rotation)
	return UIKit.new("UIGradient", { Color = sequence, Rotation = rotation or 90 })
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
	local textStroke = defaults.Outline
	defaults.Outline = nil
	local label = UIKit.new("TextLabel", defaults)
	if defaults.TextScaled then
		UIKit.new("UITextSizeConstraint", { MaxTextSize = maxText, Parent = label })
	end
	if textStroke then
		UIKit.new("UIStroke", { Color = UIKit.Colors.Stroke, Thickness = textStroke, Parent = label })
	end
	return label
end

-- ชิปเล็ก ๆ เช่น "ตำนาน", "-30%"
function UIKit.chip(parent, text, color, position, anchor, size)
	return UIKit.label({
		Text = text,
		Size = size or UDim2.fromOffset(74, 20),
		Position = position or UDim2.fromOffset(6, 6),
		AnchorPoint = anchor or Vector2.zero,
		BackgroundTransparency = 0,
		BackgroundColor3 = color,
		TextColor3 = Color3.new(1, 1, 1),
		MaxTextSize = 14,
		ZIndex = 5,
		Parent = parent,
	}, nil)
end

local clickSound = UIKit.new("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.25 })
function UIKit.click(pitch)
	if not clickSound.Parent then
		clickSound.Parent = workspace.CurrentCamera
	end
	clickSound.PlaybackSpeed = pitch or 1.6
	clickSound:Play()
end

-- ปุ่มเด้ง ๆ น่ากด
function UIKit.button(props, onClick)
	local maxText = props.MaxTextSize or 24
	props.MaxTextSize = nil
	local defaults = {
		BackgroundColor3 = UIKit.Colors.Button,
		Font = UIKit.Font,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		AutoButtonColor = true,
		Text = "",
	}
	for key, value in props do
		defaults[key] = value
	end
	local button = UIKit.new("TextButton", defaults, {
		UIKit.corner(12),
		UIKit.stroke(UIKit.Colors.Stroke, 2),
		UIKit.new("UITextSizeConstraint", { MaxTextSize = maxText }),
		UIKit.new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }),
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
			scale.Scale = 0.9
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			UIKit.click()
			onClick()
		end)
	end
	return button
end

-- ทำให้ปุ่ม "เต้น" เรียกร้องความสนใจ (ใช้กับปุ่มซื้อ/ข้อเสนอ)
function UIKit.pulse(guiObject)
	local scale = guiObject:FindFirstChildOfClass("UIScale") or UIKit.new("UIScale", { Parent = guiObject })
	task.spawn(function()
		while guiObject.Parent do
			TweenService:Create(scale, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { Scale = 1.07 }):Play()
			task.wait(0.6)
			TweenService:Create(scale, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { Scale = 1 }):Play()
			task.wait(0.6)
		end
	end)
end

-- ย่อ/ขยาย UI ตามขนาดจอ
function UIKit.autoScale(guiObject, baseWidth, baseHeight)
	local scale = UIKit.new("UIScale", { Parent = guiObject })
	local function update()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local view = camera.ViewportSize
		scale.Scale = math.clamp(math.min(view.X / baseWidth, view.Y / baseHeight), 0.42, 1.2)
	end
	update()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	return scale
end

function UIKit.screenGui(name, order)
	return UIKit.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 0,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
end

-- หน้าต่างมาตรฐาน: หัวข้อไล่สี + ปุ่มปิด  คืนค่า (window, content, header)
function UIKit.window(gui, title, size)
	local window = UIKit.new("Frame", {
		Name = title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundColor3 = UIKit.Colors.Panel,
		Visible = false,
		Parent = gui,
	}, { UIKit.corner(22), UIKit.stroke(UIKit.Colors.Stroke, 3) })
	UIKit.autoScale(window, size.X.Offset + 40, size.Y.Offset + 90)

	local header = UIKit.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = window,
	}, {
		UIKit.corner(22),
		UIKit.gradient(ColorSequence.new(UIKit.Colors.Header, UIKit.Colors.HeaderDark), 0),
	})
	UIKit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -22),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = header,
	}, { UIKit.gradient(ColorSequence.new(UIKit.Colors.Header, UIKit.Colors.HeaderDark), 0) })
	UIKit.label({
		Text = title,
		Size = UDim2.new(0.6, 0, 1, -12),
		Position = UDim2.fromOffset(20, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
		Outline = 2,
		MaxTextSize = 32,
		ZIndex = 2,
		Parent = header,
	})
	UIKit.button({
		Text = "✖",
		Size = UDim2.fromOffset(44, 44),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = UIKit.Colors.Bad,
		ZIndex = 3,
		Parent = header,
	}, function()
		UIKit.close(window)
	end)

	local content = UIKit.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -24, 1, -72),
		Position = UDim2.fromOffset(12, 64),
		BackgroundTransparency = 1,
		Parent = window,
	})
	return window, content, header
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
	TweenService:Create(window, TweenInfo.new(0.28, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
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

function UIKit.formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local d = seconds // 86400
	local h = (seconds % 86400) // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	if d > 0 then
		return string.format("%dว %02d:%02d:%02d", d, h, m, s)
	end
	return string.format("%02d:%02d:%02d", h, m, s)
end

function UIKit.clear(container)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

return UIKit
