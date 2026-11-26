--[[
	NpcService — ชาวบ้านที่มีชีวิต: เดินตามตารางเวลา (ชั่วโมงในเกม) ไปตลาด/บ้าน/จัตุรัส
	โมเดล: ReplicatedStorage/Assets/NPC_<id> (ตัวละครออกแบบเฉพาะ) ถ้าไม่มีใช้ตัวมนุษย์มาตรฐานชั่วคราว
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldLayout = require(Shared.WorldLayout)
local TerrainBuilder = require(script.Parent.TerrainBuilder)

local NpcService = {}

local npcs = {} -- [id] = { Def, Model, Humanoid, Root }

-- แอนิเมชันมาตรฐานของ Roblox (R15) สำหรับ NPC ชั่วคราว
local ANIM_IDLE = "rbxassetid://507766666"
local ANIM_WALK = "rbxassetid://507777826"

local PALETTES = {
	npc_elder = { Color3.fromRGB(110, 80, 140), Color3.fromRGB(230, 214, 190) },
	npc_bramble = { Color3.fromRGB(90, 120, 70), Color3.fromRGB(200, 160, 120) },
	npc_willow = { Color3.fromRGB(60, 110, 100), Color3.fromRGB(240, 220, 200) },
	npc_quill = { Color3.fromRGB(50, 60, 110), Color3.fromRGB(210, 190, 160) },
	npc_pip = { Color3.fromRGB(200, 120, 80), Color3.fromRGB(250, 220, 190) },
	npc_rowan = { Color3.fromRGB(120, 90, 60), Color3.fromRGB(180, 140, 110) },
}

local function ground(pos)
	return Vector3.new(pos.X, TerrainBuilder.HeightAt(pos.X, pos.Z) + 3, pos.Z)
end

local function createModel(def)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local source = assets and assets:FindFirstChild("NPC_" .. def.Id)
	if source then
		return source:Clone(), false
	end
	local palette = PALETTES[def.Id] or PALETTES.npc_pip
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = palette[2]
	description.LeftArmColor = palette[2]
	description.RightArmColor = palette[2]
	description.TorsoColor = palette[1]
	description.LeftLegColor = palette[1]
	description.RightLegColor = palette[1]
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		return nil
	end
	return model, true
end

local function loadTrack(humanoid, id)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	return ok and track or nil
end

local function currentTarget(def)
	local hour = Lighting.ClockTime
	local chosen = def.Schedule[#def.Schedule]
	for _, entry in def.Schedule do
		if hour >= entry.Hour then
			chosen = entry
		end
	end
	return chosen.Pos
end

function NpcService.Lookup(id)
	local npc = npcs[id]
	if not npc or not npc.Root.Parent then
		return nil
	end
	return { Position = npc.Root.Position, Role = npc.Def.Role, Name = npc.Def.ThaiName }
end

function NpcService.Init()
	local folder = Instance.new("Folder")
	folder.Name = "NPCs"
	folder.Parent = workspace
	for _, def in WorldLayout.Npcs do
		local model, placeholder = createModel(def)
		if model then
			model.Name = def.Id
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			humanoid.DisplayName = def.ThaiName
			humanoid.NameDisplayDistance = 40
			humanoid.WalkSpeed = 7
			model:PivotTo(CFrame.new(ground(currentTarget(def))))
			model:SetAttribute("NpcId", def.Id)
			model:SetAttribute("Role", def.Role)
			if placeholder then
				model:SetAttribute("Placeholder", true)
				CollectionService:AddTag(model, "Placeholder")
			end
			model.Parent = folder
			pcall(function()
				root:SetNetworkOwner(nil)
			end)
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "คุย"
			prompt.ObjectText = def.ThaiName
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt:SetAttribute("Npc", def.Id)
			prompt:SetAttribute("Role", def.Role)
			prompt.Parent = root
			npcs[def.Id] = { Def = def, Model = model, Humanoid = humanoid, Root = root, Idle = loadTrack(humanoid, ANIM_IDLE), Walk = loadTrack(humanoid, ANIM_WALK) }
		end
	end

	task.spawn(function()
		while true do
			for _, npc in npcs do
				if npc.Root.Parent then
					local target = ground(currentTarget(npc.Def))
					local distance = (target - npc.Root.Position) * Vector3.new(1, 0, 1)
					if distance.Magnitude > 4 then
						npc.Humanoid:MoveTo(target)
						if npc.Walk and not npc.Walk.IsPlaying then
							npc.Walk:Play(0.3)
							if npc.Idle then
								npc.Idle:Stop(0.3)
							end
						end
					elseif npc.Idle and not npc.Idle.IsPlaying then
						npc.Idle:Play(0.3)
						if npc.Walk then
							npc.Walk:Stop(0.3)
						end
					end
				end
			end
			task.wait(1.5)
		end
	end)
end

return NpcService
