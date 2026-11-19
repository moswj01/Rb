-- Hud — แถบเงิน, ปุ่มเมนู, ป้ายมินิเกม, เหรียญเด้ง
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)
local Toast = require(script.Parent.Toast)
local ShopUI = require(script.Parent.ShopUI)
local Panels = require(script.Parent.Panels)

local player = Players.LocalPlayer
local Colors = UIKit.Colors

local Hud = {}

local coinLabel, gemLabel, coinPill, joinButton, dailyDot
local banner, bannerText, bannerSub, bannerBar
local roundState = { Phase = "Waiting" }

local coinSound = UIKit.new("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.4 })

local function currencyPill(parent, order, icon, color, onPlus)
	local frame = UIKit.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(190, 46),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = parent,
	}, { UIKit.corner(23), UIKit.stroke(color, 3) })
	UIKit.label({ Text = icon, Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(4, 3), MaxTextSize = 30, Parent = frame })
	local label = UIKit.label({
		Text = "0",
		Size = UDim2.new(1, onPlus and -96 or -54, 1, -10),
		Position = UDim2.fromOffset(46, 5),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 26,
		Parent = frame,
	})
	if onPlus then
		UIKit.button({
			Text = "+",
			Size = UDim2.fromOffset(38, 38),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			BackgroundColor3 = Colors.Good,
			MaxTextSize = 28,
			Parent = frame,
		}, onPlus)
	end
	return label, frame
end

local function animateNumber(label, target)
	local current = tonumber((label.Text:gsub(",", ""))) or 0
	if current == target then
		return
	end
	local value = Instance.new("NumberValue")
	value.Value = current
	value.Changed:Connect(function(v)
		label.Text = UIKit.formatNumber(v)
	end)
	local tween = TweenService:Create(value, TweenInfo.new(0.4), { Value = target })
	tween.Completed:Connect(function()
		label.Text = UIKit.formatNumber(target)
		value:Destroy()
	end)
	tween:Play()
end

local function updateCurrency(data)
	animateNumber(coinLabel, data.Coins)
	animateNumber(gemLabel, data.Gems)
	local skip = data.Settings and data.Settings.SkipRounds
	joinButton.Text = skip and "🎮 มินิเกม: พัก" or "🎮 มินิเกม: เล่น"
	joinButton.BackgroundColor3 = skip and Colors.Muted or Colors.Info
	joinButton.TextColor3 = skip and Colors.Text or Color3.new(1, 1, 1)
	dailyDot.Visible = Panels.CanClaimDaily()
end

local function coinPopup(amount, _position, big)
	coinSound.PlaybackSpeed = big and 1.2 or 1.5
	coinSound:Play()
	local popup = UIKit.label({
		Text = "+" .. amount .. " 🪙",
		Size = UDim2.fromOffset(120, 34),
		Position = UDim2.new(0, 120, 1, 4),
		TextColor3 = big and Color3.fromRGB(255, 110, 210) or Colors.Coin,
		TextStrokeTransparency = 0.2,
		TextStrokeColor3 = Colors.Stroke,
		MaxTextSize = big and 34 or 26,
		Parent = coinPill,
	})
	TweenService:Create(popup, TweenInfo.new(0.9), { Position = UDim2.new(0, 120, 1, 40), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1, function()
		popup:Destroy()
	end)
	local scale = coinPill:FindFirstChildOfClass("UIScale") or UIKit.new("UIScale", { Parent = coinPill })
	scale.Scale = 1.12
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- ===== ป้ายมินิเกมด้านบน =====

local function showBanner(text, sub, color)
	banner.Visible = true
	bannerText.Text = text
	bannerSub.Text = sub or ""
	banner.BackgroundColor3 = color or Colors.Header
end

local waveToken = 0
local function onRoundState(state)
	roundState = state
	local skip = player:GetAttribute("SkipRounds")
	bannerBar.Visible = false

	if state.Phase == "Intermission" then
		showBanner(
			"🎨 พื้นสีวิบวับ เริ่มใน " .. state.Time .. " วิ",
			skip and "คุณกำลังพักอยู่ (กดปุ่ม 🎮 เพื่อเข้าร่วม)" or "ยืนบนสีที่เกมบอก แล้วอย่าตกสไลม์นะ!",
			Colors.Header
		)
	elseif state.Phase == "Waiting" then
		showBanner("⏳ รอผู้เล่นเข้าร่วม...", "เปิดโหมด 🎮 เล่น เพื่อเข้าร่วมมินิเกม", Colors.Info)
	elseif state.Phase == "Starting" then
		showBanner("เตรียมตัว! 🏁", "เกมกำลังจะเริ่ม", Colors.Info)
	elseif state.Phase == "Wave" then
		local textColor = state.Color
		showBanner(
			"ไปยืนบนสี " .. state.ColorName .. "!",
			string.format("เวฟ %d/%d • เหลือ %d คน", state.Wave, state.MaxWave, state.Alive),
			textColor
		)
		bannerBar.Visible = true
		bannerBar.Size = UDim2.new(1, -20, 0, 8)
		TweenService:Create(bannerBar, TweenInfo.new(state.Time, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 8) }):Play()
		waveToken += 1
		local token = waveToken
		task.delay(state.Time, function()
			if token == waveToken and roundState.Phase == "Wave" then
				bannerText.Text = "หมดเวลา! ⏰"
			end
		end)
	elseif state.Phase == "Results" then
		local winners = state.Winners or {}
		if #winners == 0 then
			showBanner("ไม่มีใครรอดเลย 😆", "รอบหน้าลองใหม่นะ!", Colors.Info)
		else
			showBanner("🏆 ผู้ชนะ!", table.concat(winners, ", "), Colors.Good)
		end
	end
end

function Hud.Init()
	local gui = UIKit.screenGui("HUD")

	-- เงิน (มุมซ้ายบน)
	local wallet = UIKit.new("Frame", {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(200, 110),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { UIKit.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	UIKit.autoScale(wallet, 1000, 650)
	coinLabel, coinPill = currencyPill(wallet, 1, "🪙", Colors.Coin)
	gemLabel = currencyPill(wallet, 2, "💎", Colors.Gem, function()
		ShopUI.Open("Gems")
	end)

	-- ปุ่มเมนู (ซ้ายกลาง)
	local menu = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(200, 260),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { UIKit.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
	UIKit.autoScale(menu, 1000, 650)

	UIKit.button({ Text = "🛍️ ร้านค้า", Size = UDim2.fromOffset(170, 54), LayoutOrder = 1, BackgroundColor3 = Colors.Header, MaxTextSize = 26, Parent = menu }, function()
		ShopUI.Toggle()
	end)
	local dailyButton = UIKit.button({ Text = "🎁 รายวัน", Size = UDim2.fromOffset(170, 54), LayoutOrder = 2, BackgroundColor3 = Colors.Gem, MaxTextSize = 26, Parent = menu }, function()
		Panels.OpenDaily()
	end)
	dailyDot = UIKit.new("Frame", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -10, 0, -6),
		BackgroundColor3 = Colors.Bad,
		Visible = false,
		Parent = dailyButton,
	}, { UIKit.corner(9), UIKit.stroke(Color3.new(1, 1, 1), 2) })
	UIKit.button({ Text = "🎟️ โค้ด", Size = UDim2.fromOffset(170, 54), LayoutOrder = 3, BackgroundColor3 = Colors.Coin, MaxTextSize = 26, Parent = menu }, function()
		Panels.OpenCodes()
	end)
	joinButton = UIKit.button({ Text = "🎮 มินิเกม: เล่น", Size = UDim2.fromOffset(170, 54), LayoutOrder = 4, BackgroundColor3 = Colors.Info, MaxTextSize = 22, Parent = menu }, function()
		local skip = not player:GetAttribute("SkipRounds")
		Net.Invoke("SetSkipRounds", skip)
		Toast.Show(skip and "พักมินิเกมแล้ว เดินเล่นชิล ๆ ได้เลย 🌴" or "เข้าร่วมมินิเกมรอบหน้า! 🎮", "info")
	end)

	-- ป้ายมินิเกม (บนกลาง)
	banner = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(460, 84),
		BackgroundColor3 = Colors.Header,
		Visible = false,
		Parent = gui,
	}, { UIKit.corner(18), UIKit.stroke(Colors.Stroke, 3) })
	UIKit.autoScale(banner, 1000, 650)
	bannerText = UIKit.label({
		Size = UDim2.new(1, -20, 0, 44),
		Position = UDim2.fromOffset(10, 4),
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.3,
		TextStrokeColor3 = Colors.Stroke,
		MaxTextSize = 36,
		Parent = banner,
	})
	bannerSub = UIKit.label({
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.fromOffset(10, 48),
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.5,
		TextStrokeColor3 = Colors.Stroke,
		MaxTextSize = 18,
		Parent = banner,
	})
	bannerBar = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -4),
		Size = UDim2.new(1, -20, 0, 8),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Visible = false,
		Parent = banner,
	}, { UIKit.corner(4) })

	coinSound.Parent = gui

	Net.Changed:Connect(updateCurrency)
	if Net.Data then
		updateCurrency(Net.Data)
	end
	Net.Get("CoinPopup").OnClientEvent:Connect(coinPopup)
	Net.Get("RoundState").OnClientEvent:Connect(onRoundState)

	-- ป้ายในโลก (ร้านค้า / กล่องของขวัญ)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("OpenShop") then
			ShopUI.Open("Featured")
		elseif prompt:GetAttribute("OpenDaily") then
			Panels.OpenDaily()
		end
	end)

	task.spawn(function()
		while true do
			task.wait(5)
			if Net.Data then
				dailyDot.Visible = Panels.CanClaimDaily()
			end
		end
	end)
end

return Hud
