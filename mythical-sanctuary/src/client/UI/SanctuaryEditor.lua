--[[
	SanctuaryEditor — โหมดจัดวางในเขตอนุรักษ์
	  • เลือกของจากกระเป๋า → ผีโปร่งแสงตามเมาส์/นิ้ว, Snap กริด 2 studs
	  • R / ปุ่มหมุน = หมุน 90°, คลิก/ยืนยัน = วาง, Esc/ปิด = ยกเลิก
	  • คลิกของที่วางแล้ว = เลือกเพื่อย้าย หรือเก็บกลับกระเป๋า
	  • สีผี: เขียว = วางได้, แดง = วางไม่ได้ (กฎเดียวกับเซิร์ฟเวอร์ใน Placement.lua)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Items)
local Net = require(Shared.Net)
local Placement = require(Shared.Placement)
local AssetLibrary = require(Shared.AssetLibrary)

local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local SanctuaryEditor = {}

local Colors = Theme.Colors
local player = Players.LocalPlayer
local bar, itemList, hint, actions
local active = false
local ghost, highlight
local placingItem, movingObjectId
local rotation = 0
local lastValid, lastX, lastZ = false, 0, 0
local pointerPosition -- สำหรับมือถือ: ตำแหน่งที่แตะล่าสุด
local renderConnection

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function origin()
	return player:GetAttribute("SanctuaryOrigin")
end

local function clearGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	placingItem, movingObjectId = nil, nil
	actions.Visible = false
end

local function makeGhost(itemId)
	clearGhost()
	local item = Items.ById[itemId]
	ghost = AssetLibrary.Create(item.AssetKey, CFrame.new())
	for _, d in ghost:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Transparency = math.max(d.Transparency, 0.45)
		elseif d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("ProximityPrompt") then
			d:Destroy()
		end
	end
	highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.6
	highlight.OutlineTransparency = 0.1
	highlight.Parent = ghost
	ghost.Parent = workspace.CurrentCamera
	placingItem = itemId
	actions.Visible = true
end

local function pointerRay()
	local camera = workspace.CurrentCamera
	local screen = pointerPosition or UserInputService:GetMouseLocation()
	return camera:ViewportPointToRay(screen.X, screen.Y)
end

local function terrainHit()
	rayParams.FilterDescendantsInstances = { workspace.Terrain }
	local ray = pointerRay()
	return workspace:Raycast(ray.Origin, ray.Direction * 600, rayParams)
end

local function update()
	local o = origin()
	if not ghost or not o or not State.Profile then
		return
	end
	local hit = terrainHit()
	if not hit then
		return
	end
	local lx = Placement.Snap(hit.Position.X - o.X)
	local lz = Placement.Snap(hit.Position.Z - o.Z)
	lastX, lastZ = lx, lz
	local ok = Placement.Validate(State.Profile.Sanctuary, placingItem, lx, lz, rotation, movingObjectId)
	lastValid = ok
	ghost:PivotTo(CFrame.new(o.X + lx, hit.Position.Y, o.Z + lz) * CFrame.Angles(0, math.rad(rotation * 90), 0))
	highlight.FillColor = ok and Color3.fromRGB(120, 230, 150) or Color3.fromRGB(240, 100, 100)
	highlight.OutlineColor = ok and Colors.GoldBright or Colors.Rose
end

local function confirm()
	if not placingItem then
		return
	end
	if not lastValid then
		local _, reason = Placement.Validate(State.Profile.Sanctuary, placingItem, lastX, lastZ, rotation, movingObjectId)
		Toast.Show(reason or "วางตรงนี้ไม่ได้", "warn")
		return
	end
	local ok, message
	if movingObjectId then
		ok, message = Net.Invoke("MoveObject", movingObjectId, lastX, lastZ, rotation)
	else
		ok, message = Net.Invoke("PlaceObject", placingItem, lastX, lastZ, rotation)
	end
	if ok then
		Toast.Show("✦ จัดวางแล้ว", "creature")
		local stillHave = State.Count(placingItem) > (movingObjectId and 0 or 1)
		if movingObjectId or not stillHave then
			clearGhost()
		end
	elseif message then
		Toast.Show(message, "warn")
	end
end

local function selectExisting()
	local ray = pointerRay()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, workspace.CurrentCamera }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
	local model = hit and hit.Instance:FindFirstAncestorWhichIsA("Model")
	while model and not model:GetAttribute("ObjectId") do
		model = model.Parent and model.Parent:FindFirstAncestorWhichIsA("Model")
	end
	if model and model:GetAttribute("OwnerId") == player.UserId then
		local objectId = model:GetAttribute("ObjectId")
		local object = State.Profile.Sanctuary.Objects[objectId]
		if object then
			makeGhost(object.Item)
			movingObjectId = objectId
			rotation = object.Rot
			hint.Text = "กำลังย้าย " .. Items.ById[object.Item].ThaiName .. " — คลิกจุดใหม่ หรือกด 'เก็บ'"
			return true
		end
	end
	return false
end

local function renderItems()
	Theme.clear(itemList)
	local profile = State.Profile
	if not profile then
		return
	end
	local any = false
	for _, item in Items.List do
		local count = profile.Inventory[item.Id] or 0
		if item.Placeable and count > 0 then
			any = true
			Theme.button({ Text = string.format("%s ×%d", item.ThaiName, count), Size = UDim2.fromOffset(150, 40), Style = placingItem == item.Id and "Primary" or "Secondary", TextSize = 15, Parent = itemList }, function()
				makeGhost(item.Id)
				rotation = 0
				hint.Text = "คลิกตำแหน่งเพื่อวาง · R หมุน · Esc ยกเลิก"
				renderItems()
			end)
		end
	end
	if not any then
		Theme.text({ Text = "ไม่มีของตกแต่งในกระเป๋า — ซื้อได้ที่ร้านของแบรมเบิล", Size = UDim2.fromOffset(420, 40), TextSize = 15, TextColor3 = Colors.IvoryDim, Parent = itemList })
	end
end

function SanctuaryEditor.Toggle()
	if active then
		SanctuaryEditor.Stop()
	else
		SanctuaryEditor.Start()
	end
end

function SanctuaryEditor.Start()
	if active or State.Zone ~= "Sanctuary" then
		return
	end
	active = true
	hint.Text = "เลือกของด้านล่าง หรือคลิกของที่วางแล้วเพื่อย้าย"
	renderItems()
	Theme.show(bar, true)
	renderConnection = RunService.RenderStepped:Connect(update)
end

function SanctuaryEditor.Stop()
	active = false
	clearGhost()
	bar.Visible = false
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
end

function SanctuaryEditor.Init(gui)
	bar = Theme.panel({ Name = "SanctuaryEditor", Size = UDim2.fromOffset(820, 150), Position = UDim2.new(0.5, 0, 1, -20), AnchorPoint = Vector2.new(0.5, 1), Visible = false, Parent = gui })
	Theme.scale(bar, 980, 680)
	Theme.title({ Text = "จัดวางเขตอนุรักษ์", Size = UDim2.fromOffset(300, 28), Position = UDim2.fromOffset(20, 10), TextSize = 24, Parent = bar })
	hint = Theme.text({ Size = UDim2.new(1, -360, 0, 20), Position = UDim2.fromOffset(320, 14), TextSize = 15, TextColor3 = Colors.IvoryDim, Parent = bar })
	itemList = Theme.new("ScrollingFrame", { Size = UDim2.new(1, -40, 0, 52), Position = UDim2.fromOffset(20, 44), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), Parent = bar }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
	})
	actions = Theme.new("Frame", { Size = UDim2.new(1, -40, 0, 40), Position = UDim2.fromOffset(20, 100), BackgroundTransparency = 1, Visible = false, Parent = bar }, {
		Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
	})
	Theme.button({ Text = "หมุน (R)", Size = UDim2.fromOffset(120, 36), Style = "Secondary", Parent = actions }, function()
		rotation = (rotation + 1) % 4
	end)
	Theme.button({ Text = "ยืนยัน", Size = UDim2.fromOffset(120, 36), Parent = actions }, confirm)
	Theme.button({ Text = "เก็บเข้ากระเป๋า", Size = UDim2.fromOffset(150, 36), Style = "Secondary", Parent = actions }, function()
		if movingObjectId then
			local ok, message = Net.Invoke("RemoveObject", movingObjectId)
			Toast.Show(ok and "เก็บกลับกระเป๋าแล้ว" or (message or "เก็บไม่ได้"), ok and "info" or "warn")
			clearGhost()
		end
	end)
	Theme.button({ Text = "ปิด", Size = UDim2.fromOffset(90, 36), Style = "Secondary", Position = UDim2.new(1, -110, 0, 100), Parent = bar }, SanctuaryEditor.Stop)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not active then
			return
		end
		if input.KeyCode == Enum.KeyCode.R and not processed then
			rotation = (rotation + 1) % 4
		elseif input.KeyCode == Enum.KeyCode.Escape then
			if placingItem then
				clearGhost()
			else
				SanctuaryEditor.Stop()
			end
		elseif (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not processed then
			if input.UserInputType == Enum.UserInputType.Touch then
				pointerPosition = Vector2.new(input.Position.X, input.Position.Y)
				if not placingItem then
					selectExisting()
				end
				update()
				return -- มือถือ: แตะเพื่อเล็ง แล้วกด "ยืนยัน"
			end
			if placingItem then
				confirm()
			else
				selectExisting()
			end
		end
	end)
	State.Changed:Connect(function()
		if active then
			renderItems()
		end
	end)
	State.ZoneChanged:Connect(function(zone)
		if zone ~= "Sanctuary" and active then
			SanctuaryEditor.Stop()
		end
	end)
end

return SanctuaryEditor
