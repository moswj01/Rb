--[[
	CosmeticService — สวมใส่ไอเท็มบนตัวละคร (ใช้ CosmeticBuilders ร่วมกับหน้าร้าน)
	- รองรับ: สกิน, หมวก, ปีก, สัตว์เลี้ยง, หาง, ออร่า, ฉายา
	- "ลองใส่" (Try On): ใส่ของที่ยังไม่ได้ซื้อชั่วคราว 20 วิ — คนอื่นในเซิร์ฟก็เห็น (โฆษณาไปในตัว)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ItemCatalog = require(Shared.ItemCatalog)
local CB = require(Shared.CosmeticBuilders)
local DataService = require(script.Parent.DataService)

local CosmeticService = {}

local states = {} -- [Player] = state
local petsFolder
local stashRoot

local CLOTHING = { Shirt = true, Pants = true, ShirtGraphic = true, BodyColors = true }

local function track(state, instance)
	table.insert(state.Created, instance)
	return instance
end

local function torsoOf(character)
	return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
end

-- ===== appliers =====

local Appliers = {}

Appliers.Skin = function(_player, character, state, item)
	if item.Id == "skin_classic" then
		return
	end
	for _, child in character:GetChildren() do
		if CLOTHING[child.ClassName] then
			child.Parent = state.Stash
		end
	end
	for part in state.Original do
		if part.Parent == character then
			CB.ApplySkinToPart(item, part)
		end
	end
	if item.Glow then
		local torso = torsoOf(character)
		if torso then
			local glow = track(state, Instance.new("PointLight"))
			glow.Color = item.Colors[1]
			glow.Range = 8
			glow.Brightness = 1.2
			glow.Parent = torso
		end
	end
end

local function hideHats(character, state)
	for _, accessory in character:GetChildren() do
		if accessory:IsA("Accessory") and accessory.AccessoryType == Enum.AccessoryType.Hat then
			local handle = accessory:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") and state.Hidden[handle] == nil then
				state.Hidden[handle] = handle.Transparency
				handle.Transparency = 1
			end
		end
	end
end

Appliers.Hat = function(_player, character, state, item)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local build = CB.Build(item, head.CFrame * CFrame.new(0, head.Size.Y / 2, 0))
	if not build then
		return
	end
	hideHats(character, state)
	CB.Attach(build, head)
	build.Model.Name = "CosmeticHat"
	build.Model.Parent = track(state, build.Model) and character
end

Appliers.Wings = function(_player, character, state, item)
	local torso = torsoOf(character)
	if not torso then
		return
	end
	local build = CB.Build(item, torso.CFrame * CFrame.new(0, 0.2, torso.Size.Z / 2))
	if not build then
		return
	end
	CB.Attach(build, torso)
	build.Model.Name = "CosmeticWings"
	build.Model.Parent = track(state, build.Model) and character
end

Appliers.Trail = function(_player, character, state, item)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _, instance in CB.CreateTrail(item, root) do
		track(state, instance)
	end
end

Appliers.Aura = function(_player, character, state, item)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if item.Style == "Orbit" then
		local build = CB.Build(item, root.CFrame)
		if build then
			CB.Attach(build, root)
			build.Model.Name = "CosmeticAura"
			build.Model.Parent = track(state, build.Model) and character
		end
	else
		for _, instance in CB.CreateAuraEffects(item, root) do
			track(state, instance)
		end
	end
end

Appliers.Title = function(_player, character, state, item)
	local head = character:FindFirstChild("Head")
	if head then
		track(state, CB.CreateTitle(item, head))
	end
end

Appliers.Pet = function(player, character, state, item)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local offset = Vector3.new(2.6, 1.6, 2.6)
	local start = root.CFrame * CFrame.new(offset)
	local build = CB.Build(item, start)
	if not build or not build.Body then
		return
	end
	local body = build.Body
	CB.Attach(build, body)
	body.Massless = false
	build.Model.PrimaryPart = body
	build.Model.Name = player.Name .. "_Pet"

	local petAttachment = Instance.new("Attachment")
	petAttachment.CFrame = body.CFrame:ToObjectSpace(start)
	petAttachment.Parent = body
	local target = track(state, Instance.new("Attachment"))
	target.Name = "PetTarget"
	target.Position = offset
	target.Parent = root

	local align = Instance.new("AlignPosition")
	align.Attachment0 = petAttachment
	align.Attachment1 = target
	align.MaxForce = 1e6
	align.Responsiveness = 16
	align.Parent = body

	local orient = Instance.new("AlignOrientation")
	orient.Attachment0 = petAttachment
	orient.Attachment1 = target
	orient.MaxTorque = 1e6
	orient.Responsiveness = 16
	orient.Parent = body

	build.Model.Parent = petsFolder
	pcall(function()
		body:SetNetworkOwner(player)
	end)
	state.Pet = build.Model
end

-- ===== state management =====

local function restore(state)
	for _, instance in state.Created do
		instance:Destroy()
	end
	table.clear(state.Created)
	if state.Pet then
		state.Pet:Destroy()
		state.Pet = nil
	end
	for _, child in state.Stash:GetChildren() do
		child.Parent = state.Character
	end
	for part, original in state.Original do
		if part.Parent then
			part.Color = original.Color
			part.Material = original.Material
			part.Reflectance = original.Reflectance
			part.Transparency = original.Transparency
			CollectionService:RemoveTag(part, "Rainbow")
		end
	end
	for handle, transparency in state.Hidden do
		if handle.Parent then
			handle.Transparency = transparency
		end
	end
	table.clear(state.Hidden)
end

local function destroyState(player)
	local state = states[player]
	if not state then
		return
	end
	for _, instance in state.Created do
		instance:Destroy()
	end
	if state.Pet then
		state.Pet:Destroy()
	end
	state.Stash:Destroy()
	states[player] = nil
end

-- ของที่ "แสดงผล" อยู่จริง (รวมของที่กำลังลองใส่)
function CosmeticService.GetVisibleOutfit(player)
	local data = DataService.Get(player)
	local outfit = {}
	if not data then
		return outfit
	end
	for categoryId, itemId in data.Equipped do
		if data.Owned[itemId] then
			outfit[categoryId] = itemId
		end
	end
	local state = states[player]
	if state and state.TryOn then
		outfit[state.TryOn.Category] = state.TryOn.ItemId
	end
	return outfit
end

function CosmeticService.Apply(player)
	local state = states[player]
	local character = player.Character
	if not state or not character or state.Character ~= character then
		return
	end
	restore(state)
	local outfit = CosmeticService.GetVisibleOutfit(player)
	for _, category in ItemCatalog.Categories do
		local item = outfit[category.Id] and ItemCatalog.ById[outfit[category.Id]]
		if item and item.Category == category.Id then
			local ok, err = pcall(Appliers[category.Id], player, character, state, item)
			if not ok then
				warn("[CosmeticService] ใส่", item.Id, "ไม่สำเร็จ:", err)
			end
		end
	end
end

function CosmeticService.TryOn(player, itemId)
	local state = states[player]
	local item = ItemCatalog.ById[itemId]
	if not state or not item then
		return false
	end
	local token = {}
	state.TryOn = { Category = item.Category, ItemId = itemId, Token = token }
	CosmeticService.Apply(player)
	task.delay(Config.TryOnSeconds, function()
		local current = states[player]
		if current and current.TryOn and current.TryOn.Token == token then
			current.TryOn = nil
			CosmeticService.Apply(player)
		end
	end)
	return true
end

function CosmeticService.ClearTryOn(player)
	local state = states[player]
	if state and state.TryOn then
		state.TryOn = nil
		CosmeticService.Apply(player)
	end
end

local function onCharacter(player, character)
	destroyState(player)
	local waited = 0
	while not player:HasAppearanceLoaded() and waited < 6 do
		waited += task.wait(0.1)
	end
	if player.Character ~= character or not character.Parent then
		return
	end

	local stash = Instance.new("Folder")
	stash.Name = tostring(player.UserId)
	stash.Parent = stashRoot

	local original = {}
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			original[part] = { Color = part.Color, Material = part.Material, Reflectance = part.Reflectance, Transparency = part.Transparency }
		end
	end

	states[player] = { Character = character, Original = original, Stash = stash, Hidden = {}, Created = {}, Pet = nil, TryOn = nil }

	while not DataService.Get(player) and player.Parent do
		task.wait(0.2)
	end
	CosmeticService.Apply(player)
end

function CosmeticService.Init()
	petsFolder = Instance.new("Folder")
	petsFolder.Name = "Pets"
	petsFolder.Parent = workspace

	stashRoot = Instance.new("Folder")
	stashRoot.Name = "CosmeticStash"
	stashRoot.Parent = ServerStorage

	local function onPlayer(player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(destroyState)
end

return CosmeticService
