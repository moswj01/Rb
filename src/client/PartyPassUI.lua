-- PartyPassUI — หน้าจอ Season Pass 30 ขั้น (แถวบน = ฟรี, แถวล่าง = พรีเมียม)
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ItemCatalog = require(Shared.ItemCatalog)
local PartyPass = require(Shared.PartyPass)

local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)
local Toast = require(script.Parent.Toast)
local Preview = require(script.Parent.Preview)

local player = Players.LocalPlayer
local Colors = UIKit.Colors

local PartyPassUI = {}

local window, tierLabel, xpFill, xpText, seasonTimer, track, buyButton
local lastSignature = ""

local function rewardVisual(cell, reward)
	if reward.Item then
		local item = ItemCatalog.ById[reward.Item]
		if item.Category == "Title" then
			local label = UIKit.label({ Text = item.Text, Size = UDim2.new(1, -6, 0, 40), Position = UDim2.fromOffset(3, 22), TextColor3 = Color3.new(1, 1, 1), Outline = 1.5, MaxTextSize = 14, Parent = cell })
			UIKit.gradient(ItemCatalog.GetColorSequence(item), 0).Parent = label
		else
			Preview.Create(item, cell, UDim2.new(1, -6, 0, 70), UDim2.fromOffset(3, 4))
		end
		UIKit.label({ Text = item.Name, Size = UDim2.new(1, -6, 0, 16), Position = UDim2.fromOffset(3, 74), MaxTextSize = 13, Parent = cell })
		return
	end
	local lines = {}
	if reward.Gems then
		table.insert(lines, "💎 " .. reward.Gems)
	end
	if reward.Coins then
		table.insert(lines, "🪙 " .. UIKit.formatNumber(reward.Coins))
	end
	UIKit.label({ Text = reward.Gems and "💎" or "🪙", Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 12), MaxTextSize = 34, Parent = cell })
	UIKit.label({ Text = table.concat(lines, "\n"), Size = UDim2.new(1, -6, 0, 30), Position = UDim2.fromOffset(3, 56), MaxTextSize = 15, Parent = cell })
end

local function rewardCell(parent, tier, trackName, reward, data, currentTier)
	local hasPremium = player:GetAttribute("PartyPass") == true
	local claimed = data.Pass[trackName][PartyPass.Key(tier)] == true
	local reached = currentTier >= tier
	local locked = trackName == "Premium" and not hasPremium
	local claimable = reached and not claimed and not locked
	local isItem = reward.Item ~= nil

	local stroke = claimable and Colors.Good or (isItem and Colors.Gold or Colors.Muted)
	local cell = UIKit.new("Frame", {
		Size = UDim2.fromOffset(96, 120),
		Position = UDim2.fromOffset(0, trackName == "Free" and 26 or 152),
		BackgroundColor3 = trackName == "Premium" and Color3.fromRGB(255, 240, 200) or Color3.new(1, 1, 1),
		Parent = parent,
	}, { UIKit.corner(12), UIKit.stroke(stroke, claimable and 4 or 2) })
	rewardVisual(cell, reward)

	local statusText, statusColor
	if claimed then
		statusText, statusColor = "✓ รับแล้ว", Colors.Muted
	elseif claimable then
		statusText, statusColor = "รับ!", Colors.Good
	elseif locked then
		statusText, statusColor = "🔒", Colors.Stroke
	else
		statusText, statusColor = "ขั้น " .. tier, Colors.Muted
	end
	local status = UIKit.button({
		Text = statusText,
		Size = UDim2.new(1, -10, 0, 24),
		Position = UDim2.new(0, 5, 1, -28),
		BackgroundColor3 = statusColor,
		TextColor3 = statusColor == Colors.Muted and Colors.Text or Color3.new(1, 1, 1),
		MaxTextSize = 15,
		Parent = cell,
	}, function()
		if claimable then
			local ok, message = Net.Invoke("ClaimPassTier", tier, trackName)
			Toast.Show(message, ok and "good" or "bad")
		elseif locked then
			PartyPassUI.PromptPremium()
		end
	end)
	if claimable then
		UIKit.pulse(status)
	end
	if claimed then
		cell.BackgroundTransparency = 0.4
	end
end

function PartyPassUI.PromptPremium()
	local id = Config.GamePasses.PartyPass.Id
	if id == 0 then
		Toast.Show("ผู้สร้างเกมยังไม่ได้ตั้งค่า ID Party Pass ใน Config.lua", "info")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, id)
end

local function render(force)
	local data = Net.Data
	if not data or not window.Visible then
		return
	end
	local progress, currentTier = PartyPass.ProgressInTier(data.Pass.XP)
	tierLabel.Text = "ขั้น " .. currentTier .. " / " .. Config.PartyPass.Tiers
	xpFill.Size = UDim2.fromScale(progress, 1)
	xpText.Text = currentTier >= Config.PartyPass.Tiers and "สูงสุดแล้ว! 🎉" or string.format("%d / %d XP", data.Pass.XP % Config.PartyPass.XPPerTier, Config.PartyPass.XPPerTier)
	local hasPremium = player:GetAttribute("PartyPass") == true
	buyButton.Visible = not hasPremium

	local parts = { currentTier, tostring(hasPremium) }
	for key in data.Pass.Free do
		table.insert(parts, "f" .. key)
	end
	for key in data.Pass.Premium do
		table.insert(parts, "p" .. key)
	end
	table.sort(parts, function(a, b)
		return tostring(a) < tostring(b)
	end)
	local signature = table.concat(parts, ",")
	if signature == lastSignature and not force then
		return
	end
	lastSignature = signature

	local scroll = track.CanvasPosition
	UIKit.clear(track)
	for tier = 1, Config.PartyPass.Tiers do
		local column = UIKit.new("Frame", { LayoutOrder = tier, Size = UDim2.fromOffset(96, 276), BackgroundTransparency = 1, Parent = track })
		UIKit.label({
			Text = tostring(tier),
			Size = UDim2.fromOffset(40, 22),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			BackgroundTransparency = 0,
			BackgroundColor3 = currentTier >= tier and Colors.Header or Colors.Muted,
			TextColor3 = Color3.new(1, 1, 1),
			MaxTextSize = 16,
			Parent = column,
		})
		rewardCell(column, tier, "Free", PartyPass.Free[tier], data, currentTier)
		rewardCell(column, tier, "Premium", PartyPass.Premium[tier], data, currentTier)
	end
	task.defer(function()
		if force then
			track.CanvasPosition = Vector2.new(math.max(0, (currentTier - 2) * 104), 0)
		else
			track.CanvasPosition = scroll
		end
	end)
end

function PartyPassUI.Open()
	UIKit.open(window)
	render(true)
end

function PartyPassUI.Init()
	local gui = UIKit.screenGui("PartyPass", 10)
	local content
	window, content = UIKit.window(gui, "🎫 Party Pass — " .. Config.PartyPass.Name, UDim2.fromOffset(900, 470))

	local top = UIKit.new("Frame", { Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1, Parent = content })
	tierLabel = UIKit.label({ Size = UDim2.fromOffset(160, 34), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 28, Parent = top })
	local bar = UIKit.new("Frame", { Size = UDim2.fromOffset(360, 24), Position = UDim2.fromOffset(0, 40), BackgroundColor3 = Colors.Muted, Parent = top }, { UIKit.corner(12) })
	xpFill = UIKit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = bar }, {
		UIKit.corner(12),
		UIKit.gradient(ColorSequence.new(Colors.Header, Colors.Gold), 0),
	})
	xpText = UIKit.label({ Size = UDim2.fromScale(1, 1), TextColor3 = Color3.new(1, 1, 1), Outline = 1.5, MaxTextSize = 16, ZIndex = 3, Parent = bar })
	seasonTimer = UIKit.label({ Size = UDim2.fromOffset(240, 26), Position = UDim2.fromOffset(176, 6), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Colors.SubText, MaxTextSize = 17, Parent = top })
	UIKit.label({ Text = "รับ XP จาก: เก็บดาว • มินิเกม • โหวต • รางวัลรายวัน", Size = UDim2.fromOffset(380, 22), Position = UDim2.fromOffset(372, 42), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Colors.SubText, MaxTextSize = 15, Parent = top })

	buyButton = UIKit.button({ Text = "⭐ ปลดล็อกพรีเมียม", Size = UDim2.fromOffset(210, 46), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -150, 0, 0), BackgroundColor3 = Colors.Gold, MaxTextSize = 20, Parent = top }, PartyPassUI.PromptPremium)
	UIKit.pulse(buyButton)
	UIKit.button({ Text = "⏩ ข้าม " .. Config.TierSkip.Tiers .. " ขั้น", Size = UDim2.fromOffset(140, 46), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Colors.Robux, MaxTextSize = 18, Parent = top }, function()
		if Config.TierSkip.ProductId == 0 then
			Toast.Show("ผู้สร้างเกมยังไม่ได้ตั้งค่า ID สินค้าใน Config.lua", "info")
			return
		end
		MarketplaceService:PromptProductPurchase(player, Config.TierSkip.ProductId)
	end)

	UIKit.label({ Text = "ฟรี", Size = UDim2.fromOffset(60, 22), Position = UDim2.fromOffset(0, 112), TextColor3 = Colors.Info, MaxTextSize = 18, Parent = content })
	UIKit.label({ Text = "⭐ พรีเมียม", Size = UDim2.fromOffset(60, 40), Position = UDim2.fromOffset(0, 230), TextColor3 = Colors.Gold, TextWrapped = true, MaxTextSize = 16, Parent = content })

	track = UIKit.new("ScrollingFrame", {
		Size = UDim2.new(1, -66, 0, 300),
		Position = UDim2.fromOffset(66, 76),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		Parent = content,
	}, {
		UIKit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	Net.Changed:Connect(function()
		render(false)
	end)
	player.AttributeChanged:Connect(function(name)
		if name == "PartyPass" then
			render(true)
		end
	end)
	task.spawn(function()
		while true do
			seasonTimer.Text = "⏰ ซีซั่นจบใน " .. UIKit.formatTime(Config.PartyPass.EndsAt - workspace:GetServerTimeNow())
			task.wait(1)
		end
	end)
end

return PartyPassUI
