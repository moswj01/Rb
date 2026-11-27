--[[
	MainMenu — หน้าจอเปิดเกมแบบ cinematic
	กล้องค่อย ๆ โคจรรอบหอนาฬิกาตอนผู้เล่นเพิ่งเข้า + ชื่อเกมตัวทอง + ปุ่ม "เริ่มการผจญภัย"
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldLayout = require(Shared.WorldLayout)

local Theme = require(script.Parent.Theme)

local MainMenu = {}

local Colors = Theme.Colors

function MainMenu.Show(gui, onPlay)
	local camera = workspace.CurrentCamera
	local root = Theme.new("Frame", { Name = "MainMenu", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })
	local vignette = Theme.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Colors.MidnightDeep, BackgroundTransparency = 0.2, Parent = root }, {
		Theme.new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.45, 0.85), NumberSequenceKeypoint.new(1, 0.1) }),
		}),
	})
	local center = Theme.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(820, 300), BackgroundTransparency = 1, Parent = root })
	Theme.scale(center, 1000, 700)
	local title = Theme.title({ Text = "Mythical Sanctuary", Size = UDim2.new(1, 0, 0, 90), TextSize = 84, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, Parent = center })
	Theme.new("UIStroke", { Color = Colors.MidnightDeep, Thickness = 2, Transparency = 0.2, Parent = title })
	local subtitle = Theme.text({ Text = "ดินแดนแห่งสัตว์ในตำนาน · ผู้พิทักษ์คนใหม่ได้มาถึงแล้ว", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 96), TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, Parent = center })
	Theme.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 138), Size = UDim2.fromOffset(260, 1), BackgroundColor3 = Colors.Gold, BorderSizePixel = 0, Parent = center })
	local play = Theme.button({ Text = "เริ่มการผจญภัย", Size = UDim2.fromOffset(260, 52), Position = UDim2.new(0.5, 0, 0, 170), AnchorPoint = Vector2.new(0.5, 0), TextSize = 22, Visible = false, Parent = center })
	local loading = Theme.text({ Text = "กำลังปลุกป่าให้ตื่น…", Size = UDim2.new(1, 0, 0, 48), Position = UDim2.fromOffset(0, 184), TextSize = 17, TextColor3 = Colors.IvoryDim, TextXAlignment = Enum.TextXAlignment.Center, Parent = center })

	TweenService:Create(title, TweenInfo.new(2.2), { TextTransparency = 0 }):Play()
	TweenService:Create(subtitle, TweenInfo.new(3), { TextTransparency = 0.05 }):Play()

	-- กล้อง cinematic
	camera.CameraType = Enum.CameraType.Scriptable
	-- StreamingEnabled: ยังไม่มีตัวละคร → ขอให้เซิร์ฟเวอร์ส่งภูมิประเทศรอบหอนาฬิกามาก่อน (ไม่งั้นบ้านลอยไม่มีพื้น)
	task.spawn(function()
		pcall(function()
			Players.LocalPlayer:RequestStreamAroundAsync(WorldLayout.Landmarks[1].Pos + Vector3.new(0, WorldLayout.Village.Height, 0), 20)
		end)
	end)
	local focus = WorldLayout.Landmarks[1].Pos + Vector3.new(0, WorldLayout.Village.Height + 34, 0)
	local angle = 0
	local orbit = RunService.RenderStepped:Connect(function(dt)
		angle += dt * 0.05
		local eye = focus + Vector3.new(math.cos(angle) * 150, 30 + math.sin(angle * 0.7) * 10, math.sin(angle) * 150)
		camera.CFrame = CFrame.lookAt(eye, focus - Vector3.new(0, 12, 0))
	end)

	-- แสดงความคืบหน้าจริงจากเซิร์ฟเวอร์
	local STAGES = {
		Environment = "ตั้งค่าท้องฟ้าและแสง",
		["World props"] = "จัดวางหมู่บ้านและป่า",
		NPC = "ชาวบ้านกำลังตื่นนอน",
		Data = "เปิดสมุดบันทึกของคุณ",
		Creatures = "สัตว์ในป่ากำลังออกมา",
	}
	task.spawn(function()
		local started = os.clock()
		while loading.Parent and loading.Visible do
			local progress = workspace:GetAttribute("BootProgress") or 0
			local stage = workspace:GetAttribute("BootStage")
			local text = string.format("กำลังปลุกป่าให้ตื่น… %d%%", progress)
			if STAGES[stage] then
				text = text .. " · " .. STAGES[stage]
			end
			if os.clock() - started > 90 then
				text = text .. "\n(นานผิดปกติ — เปิด View › Output แท็บ Server เพื่อดูข้อความ ❌)"
			end
			loading.Text = text
			task.wait(0.25)
		end
	end)

	-- รอจนตัวละครพร้อม
	task.spawn(function()
		local player = Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		character:WaitForChild("HumanoidRootPart")
		loading.Visible = false
		play.Visible = true
	end)

	play.Activated:Connect(function()
		play.Visible = false
		orbit:Disconnect()
		local character = Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		TweenService:Create(vignette, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(title, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
		TweenService:Create(subtitle, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
		camera.CameraType = Enum.CameraType.Custom
		if humanoid then
			camera.CameraSubject = humanoid
		end
		task.delay(0.9, function()
			root:Destroy()
		end)
		onPlay()
	end)
end

return MainMenu
