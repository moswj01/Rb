-- Hud — เงิน, XP/Party Pass, เมนู, ข้อเสนอ Starter, ภารกิจมือใหม่, ป้ายมินิเกม + โหวตแฟชั่นโชว์
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local PartyPass = require(Shared.PartyPass)

local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)
local Toast = require(script.Parent.Toast)
local ShopUI = require(script.Parent.ShopUI)
local Panels = require(script.Parent.Panels)
local PartyPassUI = require(script.Parent.PartyPassUI)

local player = Players.LocalPlayer
local Colors = UIKit.Colors

local Hud = {}

local coinLabel, gemLabel, coinPill, joinButton, dailyDot, passDot
local tierText, tierFill
local offerButton, offerTimer
local tutorialCard, tutorialText, tutorialBar
local banner, bannerText, bannerSub, bannerBar, bannerAction, voteBar
local roundState = { Phase = "Waiting" }
local sound

-- ===== เงิน =====

local function currencyPill(parent, order, icon, color, onPlus)
	local frame = UIKit.new("Frame", { LayoutOrder = order, Size = UDim2.fromOffset(200, 46), BackgroundColor3 = Color3.new(1, 1, 1), Parent = parent }, {
		UIKit.corner(23),
		UIKit.stroke(color, 3),
	})
	UIKit.label({ Text = icon, Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(4, 3), MaxTextSize = 30, Parent = frame })
	local label = UIKit.label({ Text = "0", Size = UDim2.new(1, onPlus and -96 or -54, 1, -10), Position = UDim2.fromOffset(46, 5), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 26, Parent = frame })
	if onPlus then
		UIKit.button({ Text = "+", Size = UDim2.fromOffset(38, 38), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), BackgroundColor3 = Colors.Robux, MaxTextSize = 28, Parent = frame }, onPlus)
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

local function hasClaimablePass(data)
	local tier = PartyPass.TierFromXP(data.Pass.XP)
	local premium = player:GetAttribute("PartyPass") == true
	for t = 1, tier do
		local key = PartyPass.Key(t)
		if not data.Pass.Free[key] or (premium and not data.Pass.Premium[key]) then
			return true
		end
	end
	return false
end

local function updateData(data)
	animateNumber(coinLabel, data.Coins)
	animateNumber(gemLabel, data.Gems)
	local skip = data.Settings and data.Settings.SkipRounds
	joinButton.Text = skip and "🎮 มินิเกม: พัก" or "🎮 มินิเกม: เล่น"
	joinButton.BackgroundColor3 = skip and Colors.Muted or Colors.Info
	joinButton.TextColor3 = skip and Colors.Text or Color3.new(1, 1, 1)
	dailyDot.Visible = Panels.CanClaimDaily()
	passDot.Visible = hasClaimablePass(data)

	local progress, tier = PartyPass.ProgressInTier(data.Pass.XP)
	tierText.Text = "🎫 " .. tier
	TweenService:Create(tierFill, TweenInfo.new(0.3), { Size = UDim2.fromScale(progress, 1) }):Play()

	local step = Config.Tutorial[data.Tutorial.Step]
	tutorialCard.Visible = step ~= nil
	if step then
		tutorialText.Text = string.format("📋 ภารกิจ %d/%d: %s", data.Tutorial.Step, #Config.Tutorial, step.Text)
		tutorialBar.Size = UDim2.fromScale(math.clamp(data.Tutorial.Progress / step.Goal, 0, 1), 1)
	end
end

local function coinPopup(amount, _position, big)
	sound.PlaybackSpeed = big and 1.2 or 1.5
	sound:Play()
	local popup = UIKit.label({
		Text = "+" .. amount .. " 🪙",
		Size = UDim2.fromOffset(120, 34),
		Position = UDim2.new(1, 8, 0, 6),
		TextColor3 = big and Color3.fromRGB(255, 110, 210) or Colors.Coin,
		Outline = 2,
		MaxTextSize = big and 34 or 26,
		Parent = coinPill,
	})
	TweenService:Create(popup, TweenInfo.new(0.9), { Position = UDim2.new(1, 8, 0, -30), TextTransparency = 1 }):Play()
	task.delay(1, function()
		popup:Destroy()
	end)
	local scale = coinPill:FindFirstChildOfClass("UIScale") or UIKit.new("UIScale", { Parent = coinPill })
	scale.Scale = 1.12
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function onLevelUp(tier)
	sound.PlaybackSpeed = 0.9
	sound:Play()
	Toast.Show("🎉 Party Pass เลื่อนเป็นขั้น " .. tier .. "! กดรับรางวัลได้เลย", "good")
end

-- ===== ป้ายมินิเกม =====

local function showBanner(text, sub, color)
	banner.Visible = true
	bannerText.Text = text
	bannerSub.Text = sub or ""
	banner.BackgroundColor3 = color or Colors.Header
end

local function buildVoteBar(parent)
	local bar = UIKit.new("Frame", { Size = UDim2.new(1, -20, 0, 54), Position = UDim2.new(0, 10, 1, 8), BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, Parent = parent }, {
		UIKit.corner(16),
		UIKit.stroke(Colors.Stroke, 2),
		UIKit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8) }),
	})
	for stars = 1, 5 do
		UIKit.button({ Text = string.rep("⭐", 1) .. stars, LayoutOrder = stars, Size = UDim2.fromOffset(72, 42), BackgroundColor3 = Color3.fromHSV(0.12 - stars * 0.02, 0.6 + stars * 0.06, 1), MaxTextSize = 22, Parent = bar }, function()
			if roundState.Phase == "Runway" and roundState.ModelUserId then
				local ok, message = Net.Invoke("Vote", roundState.ModelUserId, stars)
				Toast.Show(message, ok and "good" or "bad")
				if ok then
					bar.Visible = false
				end
			end
		end)
	end
	return bar
end

local waveToken = 0
local function onRoundState(state)
	roundState = state
	local skip = player:GetAttribute("SkipRounds")
	bannerBar.Visible = false
	bannerAction.Visible = false
	voteBar.Visible = false

	if state.Phase == "Intermission" then
		local name = state.Mode == "Showdown" and "👗 แฟชั่นโชว์" or "🎨 พื้นสีวิบวับ"
		showBanner(
			name .. " เริ่มใน " .. state.Time .. " วิ",
			skip and "คุณกำลังพักอยู่ (กดปุ่ม 🎮 เพื่อเข้าร่วม)" or (state.Mode == "Showdown" and "แต่งตัวให้ตรงธีม รับโหวตจากทุกคน!" or "ยืนบนสีที่เกมบอก อย่าตกสไลม์นะ!"),
			state.Mode == "Showdown" and Colors.Header or Colors.Info
		)
	elseif state.Phase == "Waiting" then
		showBanner("⏳ รอผู้เล่นเข้าร่วม...", "เปิดโหมด 🎮 เล่น เพื่อเข้าร่วมมินิเกม", Colors.Info)
	elseif state.Phase == "Starting" then
		showBanner("เตรียมตัว! 🏁", "เกมกำลังจะเริ่ม", Colors.Info)
	elseif state.Phase == "Wave" then
		showBanner("ไปยืนบนสี " .. state.ColorName .. "!", string.format("เวฟ %d/%d • เหลือ %d คน", state.Wave, state.MaxWave, state.Alive), state.Color)
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
	elseif state.Phase == "Dress" then
		showBanner("ธีม: " .. state.ThemeIcon .. " " .. state.ThemeName, "แต่งตัวให้ตรงธีม! ของในเซ็ตนี้ได้คะแนนโบนัส ✨", Colors.Header)
		bannerBar.Visible = true
		bannerBar.Size = UDim2.new(1, -20, 0, 8)
		TweenService:Create(bannerBar, TweenInfo.new(state.Time, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 8) }):Play()
		bannerAction.Visible = true
		bannerAction.Text = "👗 เปิดตู้เสื้อผ้า"
		Toast.Show("👗 ธีมรอบนี้: " .. state.ThemeIcon .. " " .. state.ThemeName .. " — เปิดร้านเพื่อแต่งตัว/ลองชุดได้เลย!", "info")
	elseif state.Phase == "Runway" then
		local isMe = state.ModelUserId == player.UserId
		local themeText = state.ThemeItems > 0 and string.format("ใส่ของธีม %d ชิ้น ✨", state.ThemeItems) or "ไม่มีของตรงธีม"
		showBanner(
			(isMe and "💃 ตาคุณแล้ว! โพสท่าเลย" or "💃 " .. state.ModelName .. " กำลังเดินแบบ"),
			string.format("คนที่ %d/%d • %s", state.Index, state.Total, themeText),
			Colors.Header
		)
		bannerBar.Visible = true
		bannerBar.Size = UDim2.new(1, -20, 0, 8)
		TweenService:Create(bannerBar, TweenInfo.new(state.Time, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 8) }):Play()
		voteBar.Visible = not isMe
	elseif state.Phase == "ShowdownResults" then
		local lines = {}
		local medals = { "🥇", "🥈", "🥉" }
		for rank, entry in state.Top do
			table.insert(lines, medals[rank] .. " " .. entry.Name .. " (" .. entry.Score .. ")")
		end
		showBanner("👑 ผลแฟชั่นโชว์ " .. state.ThemeIcon, table.concat(lines, "   "), Colors.Gold)
	end
end

-- ===== สร้าง UI =====

local function menuButton(parent, order, text, color, onClick)
	local button = UIKit.button({ Text = text, Size = UDim2.fromOffset(176, 52), LayoutOrder = order, BackgroundColor3 = color, MaxTextSize = 24, Parent = parent }, onClick)
	local dot = UIKit.new("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -10, 0, -6), BackgroundColor3 = Colors.Bad, Visible = false, ZIndex = 3, Parent = button }, {
		UIKit.corner(9),
		UIKit.stroke(Color3.new(1, 1, 1), 2),
	})
	return button, dot
end

function Hud.Init()
	local gui = UIKit.screenGui("HUD", 5)
	sound = UIKit.new("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.4, Parent = gui })

	-- มุมซ้ายบน: เงิน + XP
	local wallet = UIKit.new("Frame", { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(210, 160), BackgroundTransparency = 1, Parent = gui }, {
		UIKit.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UIKit.autoScale(wallet, 1000, 650)
	coinLabel, coinPill = currencyPill(wallet, 1, "🪙", Colors.Coin)
	gemLabel = currencyPill(wallet, 2, "💎", Colors.Gem, function()
		ShopUI.Open("Store")
	end)
	local tierPill = UIKit.new("TextButton", { LayoutOrder = 3, Size = UDim2.fromOffset(200, 36), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = true, Parent = wallet }, {
		UIKit.corner(18),
		UIKit.stroke(Colors.Header, 3),
	})
	tierPill.Activated:Connect(PartyPassUI.Open)
	tierText = UIKit.label({ Text = "🎫 0", Size = UDim2.fromOffset(60, 28), Position = UDim2.fromOffset(6, 4), MaxTextSize = 20, Parent = tierPill })
	local tierBar = UIKit.new("Frame", { Size = UDim2.new(1, -78, 0, 14), Position = UDim2.fromOffset(68, 11), BackgroundColor3 = Colors.Muted, Parent = tierPill }, { UIKit.corner(7) })
	tierFill = UIKit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = tierBar }, {
		UIKit.corner(7),
		UIKit.gradient(ColorSequence.new(Colors.Header, Colors.Gold), 0),
	})

	-- ซ้ายกลาง: เมนู
	local menu = UIKit.new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.55, 0), Size = UDim2.fromOffset(200, 320), BackgroundTransparency = 1, Parent = gui }, {
		UIKit.new("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UIKit.autoScale(menu, 1000, 650)
	menuButton(menu, 1, "🛍️ ร้านค้า", Colors.Header, ShopUI.Toggle)
	passDot = select(2, menuButton(menu, 2, "🎫 Party Pass", Colors.HeaderDark, PartyPassUI.Open))
	dailyDot = select(2, menuButton(menu, 3, "🎁 รายวัน", Colors.Gem, Panels.OpenDaily))
	menuButton(menu, 4, "🎟️ โค้ด", Colors.Coin, Panels.OpenCodes)
	joinButton = menuButton(menu, 5, "🎮 มินิเกม: เล่น", Colors.Info, function()
		local skip = not player:GetAttribute("SkipRounds")
		Net.Invoke("SetSkipRounds", skip)
		Toast.Show(skip and "พักมินิเกมแล้ว เดินเล่นชิล ๆ ได้เลย 🌴" or "เข้าร่วมมินิเกมรอบหน้า! 🎮", "info")
	end)

	-- มุมขวาบน: ข้อเสนอ Starter Pack
	offerButton = UIKit.new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 60), Size = UDim2.fromOffset(150, 96), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", Visible = false, Parent = gui }, {
		UIKit.corner(18),
		UIKit.stroke(Colors.Gold, 3),
		UIKit.gradient(ColorSequence.new(Color3.fromRGB(255, 130, 90), Color3.fromRGB(255, 90, 180)), 90),
	})
	UIKit.autoScale(offerButton, 1000, 650)
	UIKit.label({ Text = "🚀", Size = UDim2.new(1, 0, 0, 38), Position = UDim2.fromOffset(0, 4), MaxTextSize = 34, Parent = offerButton })
	UIKit.label({ Text = "STARTER PACK", Size = UDim2.new(1, -8, 0, 22), Position = UDim2.fromOffset(4, 42), TextColor3 = Color3.new(1, 1, 1), Outline = 1.5, MaxTextSize = 18, Parent = offerButton })
	offerTimer = UIKit.label({ Text = "", Size = UDim2.new(1, -8, 0, 20), Position = UDim2.fromOffset(4, 66), TextColor3 = Color3.new(1, 1, 1), MaxTextSize = 15, Parent = offerButton })
	offerButton.Activated:Connect(function()
		UIKit.click()
		ShopUI.Open("Store")
	end)
	UIKit.pulse(offerButton)

	-- ล่างซ้าย: ภารกิจมือใหม่
	tutorialCard = UIKit.new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.fromOffset(330, 62), BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, Parent = gui }, {
		UIKit.corner(16),
		UIKit.stroke(Colors.Good, 3),
	})
	UIKit.autoScale(tutorialCard, 1000, 650)
	tutorialText = UIKit.label({ Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 5), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 19, Parent = tutorialCard })
	local tBar = UIKit.new("Frame", { Size = UDim2.new(1, -16, 0, 12), Position = UDim2.fromOffset(8, 40), BackgroundColor3 = Colors.Muted, Parent = tutorialCard }, { UIKit.corner(6) })
	tutorialBar = UIKit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Colors.Good, Parent = tBar }, { UIKit.corner(6) })

	-- บนกลาง: ป้ายมินิเกม
	banner = UIKit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(500, 88), BackgroundColor3 = Colors.Header, Visible = false, Parent = gui }, {
		UIKit.corner(18),
		UIKit.stroke(Colors.Stroke, 3),
	})
	UIKit.autoScale(banner, 1000, 650)
	bannerText = UIKit.label({ Size = UDim2.new(1, -20, 0, 46), Position = UDim2.fromOffset(10, 4), TextColor3 = Color3.new(1, 1, 1), Outline = 2.5, MaxTextSize = 36, Parent = banner })
	bannerSub = UIKit.label({ Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 50), TextColor3 = Color3.new(1, 1, 1), Outline = 1.5, MaxTextSize = 18, Parent = banner })
	bannerBar = UIKit.new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -4), Size = UDim2.new(1, -20, 0, 8), BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, Parent = banner }, { UIKit.corner(4) })
	bannerAction = UIKit.button({ Size = UDim2.fromOffset(220, 46), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 8), BackgroundColor3 = Colors.Good, Visible = false, MaxTextSize = 22, Parent = banner }, function()
		local theme = roundState.ThemeSet
		ShopUI.Open("Sets")
		if theme then
			Toast.Show("หาเซ็ต " .. roundState.ThemeIcon .. " ในแท็บ 'ชุดเซ็ต' — ลองใส่ได้ฟรี แต่ขึ้นเวทีต้องเป็นของที่มีจริงนะ!", "info")
		end
	end)
	voteBar = buildVoteBar(banner)

	Net.Changed:Connect(updateData)
	if Net.Data then
		updateData(Net.Data)
	end
	Net.Get("CoinPopup").OnClientEvent:Connect(coinPopup)
	Net.Get("RoundState").OnClientEvent:Connect(onRoundState)
	Net.Get("LevelUp").OnClientEvent:Connect(onLevelUp)

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("OpenShop") then
			ShopUI.Open("Featured")
		elseif prompt:GetAttribute("OpenDaily") then
			Panels.OpenDaily()
		end
	end)

	-- Starter Pack: นับถอยหลัง + เด้งเสนอครั้งแรกหลังเข้าเกม
	local offered = false
	task.spawn(function()
		while true do
			local left = ShopUI.StarterTimeLeft()
			offerButton.Visible = left > 0
			offerTimer.Text = "⏰ " .. UIKit.formatTime(left)
			if left > 0 and not offered and Net.Data and Net.Data.Tutorial.Step > 2 then
				offered = true
				task.delay(3, function()
					if not ShopUI.IsOpen() then
						ShopUI.Open("Store")
					end
				end)
			end
			if Net.Data then
				dailyDot.Visible = Panels.CanClaimDaily()
			end
			task.wait(1)
		end
	end)
end

return Hud
