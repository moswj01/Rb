--[[
	Theme — ภาษาภาพของ UI แบบ Premium Fantasy
	สี: Midnight Blue · Antique Gold · Forest Green · Ivory
	กรอบทองสองชั้น + เครื่องประดับมุมแบบพอดี (ไม่รก) + การเคลื่อนไหวนุ่มนวล
	ไอคอน: ใช้ AssetRegistry.Icons ถ้ามี (ภาพวาดเฉพาะเกม) ถ้ายังไม่มี แสดงอักษรย่อในวงทอง
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetRegistry = require(ReplicatedStorage:WaitForChild("Shared").AssetRegistry)

local Theme = {}

local C = Color3.fromRGB
Theme.Colors = {
	Midnight = C(20, 27, 51),
	MidnightDeep = C(12, 16, 32),
	MidnightSoft = C(34, 44, 78),
	Gold = C(201, 165, 90),
	GoldBright = C(236, 206, 140),
	GoldDim = C(130, 104, 58),
	Forest = C(47, 93, 70),
	ForestBright = C(84, 150, 112),
	Ivory = C(244, 235, 217),
	IvoryDim = C(196, 186, 166),
	Rose = C(196, 96, 104),
	Sky = C(120, 170, 220),
}

Theme.Fonts = {
	Title = Enum.Font.Garamond,
	Body = Enum.Font.SourceSans,
	BodyBold = Enum.Font.SourceSansSemibold,
}

local Colors = Theme.Colors

function Theme.new(className, props, children)
	local instance = Instance.new(className)
	local parent
	for k, v in props or {} do
		if k == "Parent" then
			parent = v
		else
			instance[k] = v
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

local new = Theme.new

function Theme.corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

function Theme.stroke(color, thickness, transparency)
	return new("UIStroke", { Color = color or Colors.Gold, Thickness = thickness or 1.5, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

function Theme.padding(t, r, b, l)
	return new("UIPadding", { PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r or t), PaddingBottom = UDim.new(0, b or t), PaddingLeft = UDim.new(0, l or r or t) })
end

function Theme.text(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Body,
		TextColor3 = Colors.Ivory,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = "",
		RichText = true,
	}
	for k, v in props do
		defaults[k] = v
	end
	return new("TextLabel", defaults)
end

function Theme.title(props)
	props.Font = props.Font or Theme.Fonts.Title
	props.TextColor3 = props.TextColor3 or Colors.GoldBright
	props.TextSize = props.TextSize or 26
	return Theme.text(props)
end

-- เครื่องประดับมุม (เพชรทองเล็ก ๆ) — ลวดลายเวทมนตร์แบบพอดี
local function ornaments(frame)
	for _, anchor in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		new("Frame", {
			Name = "Ornament",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(anchor.X, anchor.Y),
			Size = UDim2.fromOffset(10, 10),
			Rotation = 45,
			BackgroundColor3 = Colors.Gold,
			BorderSizePixel = 0,
			ZIndex = (frame.ZIndex or 1) + 2,
			Parent = frame,
		}, { Theme.stroke(Colors.MidnightDeep, 1.5) })
	end
end

-- แผงหลัก: พื้น Midnight ไล่เฉด + กรอบทองสองชั้น
function Theme.panel(props)
	local frame = new("Frame", {
		BackgroundColor3 = Colors.Midnight,
		BackgroundTransparency = props.Transparency or 0.06,
		BorderSizePixel = 0,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Visible = props.Visible ~= false,
		Name = props.Name or "Panel",
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	}, {
		Theme.corner(props.Radius or 8),
		Theme.stroke(Colors.Gold, 1.5),
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Colors.MidnightSoft, Colors.MidnightDeep) }),
	})
	-- เส้นทองชั้นใน
	new("Frame", {
		Name = "InnerFrame",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(5, 5),
		Size = UDim2.new(1, -10, 1, -10),
		ZIndex = frame.ZIndex,
		Parent = frame,
	}, { Theme.corner(math.max(2, (props.Radius or 8) - 4)), Theme.stroke(Colors.GoldDim, 1, 0.35) })
	if props.Ornaments ~= false then
		ornaments(frame)
	end
	return frame
end

function Theme.button(props, onClick)
	local primary = props.Style ~= "Secondary"
	local button = new("TextButton", {
		Name = props.Name or "Button",
		Size = props.Size or UDim2.fromOffset(160, 40),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		BackgroundColor3 = primary and Colors.Forest or Colors.MidnightSoft,
		AutoButtonColor = false,
		Font = Theme.Fonts.BodyBold,
		Text = props.Text or "",
		TextColor3 = Colors.Ivory,
		TextSize = props.TextSize or 18,
		ZIndex = props.ZIndex or 1,
		Visible = props.Visible ~= false,
		Parent = props.Parent,
	}, {
		Theme.corner(6),
		Theme.stroke(primary and Colors.Gold or Colors.GoldDim, 1.5),
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 200)) }),
	})
	local stroke = button:FindFirstChildOfClass("UIStroke")
	local base = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = primary and Colors.ForestBright or Colors.MidnightSoft:Lerp(Colors.Gold, 0.15) }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.15), { Color = Colors.GoldBright }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), { BackgroundColor3 = base }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), { Color = primary and Colors.Gold or Colors.GoldDim }):Play()
	end)
	if onClick then
		button.Activated:Connect(onClick)
	end
	return button
end

-- ไอคอนไอเท็ม/สัตว์: ภาพวาดจริงถ้ามี ไม่งั้นวงทองพร้อมอักษรย่อ (ไม่ใช่อีโมจิ)
function Theme.icon(iconKey, label, size, parent)
	local holder = new("Frame", { Size = size or UDim2.fromOffset(56, 56), BackgroundColor3 = Colors.MidnightDeep, Parent = parent }, {
		new("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Theme.stroke(Colors.Gold, 1.5),
	})
	local image = AssetRegistry.Icons[iconKey]
	if image then
		new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Image = image, Parent = holder })
	else
		Theme.title({ Text = string.upper(string.sub(label or "?", 1, 2)), Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextScaled = true, Parent = holder }).TextTransparency = 0.1
		new("UIPadding", { PaddingTop = UDim.new(0.22, 0), PaddingBottom = UDim.new(0.22, 0), Parent = holder })
	end
	return holder
end

function Theme.bar(parent, color, position, size)
	local back = new("Frame", { Size = size or UDim2.new(1, 0, 0, 8), Position = position, BackgroundColor3 = Colors.MidnightDeep, Parent = parent }, { Theme.corner(4), Theme.stroke(Colors.GoldDim, 1, 0.4) })
	local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = back }, { Theme.corner(4) })
	return back, fill
end

function Theme.setBar(fill, value)
	TweenService:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(math.clamp(value, 0, 1), 1) }):Play()
end

function Theme.screenGui(name, order)
	return new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 0,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
end

-- ย่อขยายตามจอ (มือถือ/แท็บเล็ต/PC)
function Theme.scale(object, baseWidth, baseHeight)
	local s = new("UIScale", { Parent = object })
	local function update()
		local v = workspace.CurrentCamera.ViewportSize
		s.Scale = math.clamp(math.min(v.X / baseWidth, v.Y / baseHeight), 0.55, 1.15)
	end
	update()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	return s
end

-- เปิด/ปิดแบบเลื่อน + จาง
function Theme.show(frame, visible)
	if visible then
		frame.Visible = true
		local scale = frame:FindFirstChild("OpenScale") or new("UIScale", { Name = "OpenScale", Parent = frame })
		scale.Scale = 0.96
		TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Quint), { Scale = 1 }):Play()
		local group = frame:FindFirstChildOfClass("CanvasGroup")
		if group then
			group.GroupTransparency = 1
			TweenService:Create(group, TweenInfo.new(0.2), { GroupTransparency = 0 }):Play()
		end
	else
		frame.Visible = false
	end
end

function Theme.clear(container)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

return Theme
