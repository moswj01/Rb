-- Celebration — ฉากเปิดตัวไอเท็มใหม่ (แสงหมุน + คอนเฟตตี + 3D หมุน) สร้างความรู้สึก "คุ้มที่ซื้อ"
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemCatalog = require(Shared.ItemCatalog)

local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)
local Preview = require(script.Parent.Preview)

local Celebration = {}

local gui, overlay, rays, card, previewHolder, nameLabel, rarityLabel, setLabel, equipButton
local queue = {}
local showing = false
local currentItem
local sound

local function confetti(color)
	for _ = 1, 45 do
		local piece = UIKit.new("Frame", {
			Size = UDim2.fromOffset(math.random(8, 14), math.random(12, 20)),
			Position = UDim2.new(math.random(), 0, -0.05, 0),
			Rotation = math.random(0, 360),
			BackgroundColor3 = math.random() < 0.4 and color or Color3.fromHSV(math.random(), 0.6, 1),
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = overlay,
		})
		local duration = math.random(18, 32) / 10
		TweenService:Create(piece, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(piece.Position.X.Scale + (math.random() - 0.5) * 0.3, 0, 1.1, 0),
			Rotation = piece.Rotation + math.random(-540, 540),
		}):Play()
		task.delay(duration, function()
			piece:Destroy()
		end)
	end
end

local function showNext()
	if showing or #queue == 0 then
		return
	end
	local item = ItemCatalog.ById[table.remove(queue, 1)]
	if not item then
		return showNext()
	end
	showing = true
	currentItem = item
	local rarity = ItemCatalog.Rarities[item.Rarity]

	UIKit.clear(previewHolder)
	if item.Category == "Title" then
		local label = UIKit.label({ Text = item.Text, Size = UDim2.fromScale(1, 0.4), Position = UDim2.fromScale(0, 0.3), TextColor3 = Color3.new(1, 1, 1), Outline = 3, MaxTextSize = 44, Parent = previewHolder })
		UIKit.gradient(ItemCatalog.GetColorSequence(item), 0).Parent = label
	else
		Preview.Create(item, previewHolder, nil, nil, { Spin = true, Speed = 1.2 })
	end
	nameLabel.Text = item.Icon .. " " .. item.Name
	nameLabel.TextColor3 = rarity.Color
	rarityLabel.Text = "★ " .. rarity.Name .. " ★"
	rarityLabel.BackgroundColor3 = rarity.Color
	local set = item.Set and ItemCatalog.SetById[item.Set]
	setLabel.Text = set and ("เซ็ต " .. set.Icon .. " " .. set.Name) or (item.Description or "")
	for _, ray in rays:GetChildren() do
		if ray:IsA("Frame") then
			ray.BackgroundColor3 = rarity.Color
		end
	end
	local data = Net.Data
	equipButton.Visible = not (data and data.Equipped[item.Category] == item.Id)

	gui.Enabled = true
	overlay.BackgroundTransparency = 1
	TweenService:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 0.35 }):Play()
	local scale = card:FindFirstChildOfClass("UIScale")
	scale.Scale = 0.2
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	confetti(rarity.Color)
	sound.PlaybackSpeed = 1
	sound:Play()
	task.delay(0.15, function()
		sound.PlaybackSpeed = 1.25
		sound:Play()
	end)
	task.delay(0.3, function()
		sound.PlaybackSpeed = 1.5
		sound:Play()
	end)
end

local function close()
	gui.Enabled = false
	showing = false
	currentItem = nil
	task.delay(0.2, showNext)
end

function Celebration.Show(itemId)
	table.insert(queue, itemId)
	showNext()
end

function Celebration.Init()
	gui = UIKit.screenGui("Celebration", 40)
	gui.Enabled = false
	gui.IgnoreGuiInset = true
	sound = UIKit.new("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Parent = gui })

	overlay = UIKit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 10, 40), BackgroundTransparency = 0.35, Parent = gui })

	rays = UIKit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Parent = overlay })
	for i = 1, 12 do
		UIKit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(46, 900),
			Rotation = i * 15,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			Parent = rays,
		}, {
			UIKit.new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Rotation = 90,
			}),
		})
	end
	RunService.RenderStepped:Connect(function(dt)
		if gui.Enabled then
			rays.Rotation = (rays.Rotation + dt * 20) % 360
		end
	end)

	card = UIKit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(420, 470), BackgroundTransparency = 1, ZIndex = 2, Parent = overlay })
	UIKit.new("UIScale", { Parent = card })
	local holder = UIKit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = card })
	UIKit.autoScale(holder, 520, 600)

	UIKit.label({ Text = "✨ ได้ไอเท็มใหม่! ✨", Size = UDim2.new(1, 0, 0, 50), TextColor3 = UIKit.Colors.Gold, Outline = 3, MaxTextSize = 42, Parent = holder })
	previewHolder = UIKit.new("Frame", { Size = UDim2.new(1, 0, 0, 260), Position = UDim2.fromOffset(0, 50), BackgroundTransparency = 1, Parent = holder })
	rarityLabel = UIKit.label({ Size = UDim2.fromOffset(170, 30), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 312), BackgroundTransparency = 0, TextColor3 = Color3.new(1, 1, 1), MaxTextSize = 20, Parent = holder })
	UIKit.corner(15).Parent = rarityLabel
	nameLabel = UIKit.label({ Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 346), Outline = 3, MaxTextSize = 38, Parent = holder })
	setLabel = UIKit.label({ Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 388), TextColor3 = Color3.new(1, 1, 1), MaxTextSize = 20, Parent = holder })

	equipButton = UIKit.button({ Text = "ใส่เลย! 😍", Size = UDim2.fromOffset(190, 52), Position = UDim2.new(0.5, -195, 0, 418), BackgroundColor3 = UIKit.Colors.Good, MaxTextSize = 26, Parent = holder }, function()
		if currentItem then
			Net.Invoke("EquipItem", currentItem.Category, currentItem.Id)
		end
		close()
	end)
	UIKit.button({ Text = "เยี่ยม! 👍", Size = UDim2.fromOffset(190, 52), Position = UDim2.new(0.5, 5, 0, 418), BackgroundColor3 = UIKit.Colors.Info, MaxTextSize = 26, Parent = holder }, close)

	Net.Get("Celebrate").OnClientEvent:Connect(Celebration.Show)
	Net.Changed:Connect(function(data)
		if currentItem then
			equipButton.Visible = data.Equipped[currentItem.Category] ~= currentItem.Id
		end
	end)
end

return Celebration
