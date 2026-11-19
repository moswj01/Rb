-- Panels — หน้าต่างรางวัลรายวัน และแลกโค้ด
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ShopRotation = require(Shared.ShopRotation)

local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)
local Toast = require(script.Parent.Toast)

local Colors = UIKit.Colors

local Panels = {}

local dailyWindow, dayCards, dailyStatus, claimButton
local codeWindow

local function rewardText(reward)
	local parts = {}
	if reward.Coins then
		table.insert(parts, "🪙 " .. reward.Coins)
	end
	if reward.Gems then
		table.insert(parts, "💎 " .. reward.Gems)
	end
	return table.concat(parts, "\n")
end

local function dailyState()
	local data = Net.Data
	if not data then
		return false, 1, 0
	end
	local daily = data.Daily
	local now = workspace:GetServerTimeNow()
	local since = now - daily.Last
	local canClaim = daily.Last == 0 or since >= Config.DailyCooldown
	local expired = daily.Last == 0 or since > Config.DailyStreakReset
	local nextDay = expired and 1 or (daily.Streak % #Config.DailyRewards + 1)
	return canClaim, nextDay, math.max(0, Config.DailyCooldown - since)
end

function Panels.CanClaimDaily()
	local canClaim = dailyState()
	return canClaim
end

local function renderDaily()
	if not dailyWindow.Visible then
		return
	end
	local canClaim, nextDay, wait = dailyState()
	for day, card in dayCards do
		local isNext = day == nextDay
		local done = day < nextDay
		card.BackgroundColor3 = isNext and Colors.Coin or (done and Colors.Good or Color3.new(1, 1, 1))
		card.Check.Visible = done
	end
	if canClaim then
		dailyStatus.Text = "🎉 พร้อมรับรางวัลวันที่ " .. nextDay .. " แล้ว!"
		claimButton.Text = "รับรางวัล! 🎁"
		claimButton.BackgroundColor3 = Colors.Good
	else
		dailyStatus.Text = "กลับมาใหม่ในอีก " .. ShopRotation.FormatTime(wait) .. " ⏰"
		claimButton.Text = "รับแล้ววันนี้ ✓"
		claimButton.BackgroundColor3 = Colors.Muted
	end
end

local function buildDaily(gui)
	local content
	dailyWindow, content = UIKit.window(gui, "🎁 ของขวัญรายวัน", UDim2.fromOffset(640, 340))
	UIKit.label({
		Text = "เข้าเกมทุกวันติดต่อกัน รางวัลยิ่งใหญ่ขึ้น! (หายเกิน 2 วัน เริ่มนับใหม่)",
		Size = UDim2.new(1, 0, 0, 26),
		TextColor3 = Colors.SubText,
		MaxTextSize = 18,
		Parent = content,
	})
	local row = UIKit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 120),
		Position = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 1,
		Parent = content,
	}, {
		UIKit.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	dayCards = {}
	for day, reward in Config.DailyRewards do
		local card = UIKit.new("Frame", {
			LayoutOrder = day,
			Size = UDim2.fromOffset(78, 116),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = row,
		}, { UIKit.corner(12), UIKit.stroke(Colors.Stroke, 2) })
		UIKit.label({ Text = "วันที่ " .. day, Size = UDim2.new(1, -6, 0, 24), Position = UDim2.fromOffset(3, 4), MaxTextSize = 16, Parent = card })
		UIKit.label({ Text = day == #Config.DailyRewards and "🎉" or "🎁", Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 28), MaxTextSize = 30, Parent = card })
		UIKit.label({ Text = rewardText(reward), Size = UDim2.new(1, -6, 0, 44), Position = UDim2.fromOffset(3, 66), MaxTextSize = 16, Parent = card })
		UIKit.label({ Name = "Check", Text = "✅", Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -24, 0, -6), Visible = false, MaxTextSize = 24, Parent = card })
		dayCards[day] = card
	end
	dailyStatus = UIKit.label({
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 162),
		MaxTextSize = 22,
		Parent = content,
	})
	claimButton = UIKit.button({
		Size = UDim2.fromOffset(240, 52),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 200),
		Parent = content,
	}, function()
		local ok, message = Net.Invoke("ClaimDaily")
		Toast.Show(message, ok and "good" or "bad")
	end)

	Net.Changed:Connect(renderDaily)
	task.spawn(function()
		while true do
			task.wait(1)
			renderDaily()
		end
	end)
end

local function buildCodes(gui)
	local content
	codeWindow, content = UIKit.window(gui, "🎟️ แลกโค้ด", UDim2.fromOffset(440, 250))
	UIKit.label({
		Text = "ติดตามโค้ดใหม่ได้จากกลุ่มของเกม 💌",
		Size = UDim2.new(1, 0, 0, 26),
		TextColor3 = Colors.SubText,
		MaxTextSize = 18,
		Parent = content,
	})
	local box = UIKit.new("TextBox", {
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.fromOffset(0, 36),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Font = UIKit.Font,
		PlaceholderText = "พิมพ์โค้ดตรงนี้...",
		Text = "",
		TextSize = 24,
		TextColor3 = Colors.Text,
		ClearTextOnFocus = false,
		Parent = content,
	}, { UIKit.corner(12), UIKit.stroke(Colors.Stroke, 2) })
	UIKit.button({
		Text = "แลกเลย! ✨",
		Size = UDim2.fromOffset(200, 50),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 104),
		BackgroundColor3 = Colors.Good,
		Parent = content,
	}, function()
		local ok, message = Net.Invoke("RedeemCode", box.Text)
		Toast.Show(message, ok and "good" or "bad")
		if ok then
			box.Text = ""
		end
	end)
end

function Panels.OpenDaily()
	UIKit.open(dailyWindow)
	renderDaily()
end

function Panels.OpenCodes()
	UIKit.toggle(codeWindow)
end

function Panels.Init()
	local gui = UIKit.screenGui("Panels")
	gui.DisplayOrder = 10
	buildDaily(gui)
	buildCodes(gui)
end

return Panels
