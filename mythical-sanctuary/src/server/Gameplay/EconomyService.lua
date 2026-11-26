--[[
	EconomyService — ร้านค้า, เก็บสมุนไพร, ปรุงยา, บันทึกการตั้งค่า
	ตรวจระยะทางจริงทุกครั้ง (ต้องอยู่ใกล้ร้าน/หม้อยา/สมุนไพร) — กันการโกงจาก client
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Net = require(Shared.Net)

local DataService = require(script.Parent.Parent.Data.DataService)
local Inventory = require(script.Parent.Inventory)
local QuestService = require(script.Parent.QuestService)

local EconomyService = {}

local forageCooldown = {} -- [userId][nodeId] = os.clock() ที่เก็บได้อีก
local interactables
local npcPosition
local environment

local function rootOf(player)
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function nearCauldron(player)
	local root = rootOf(player)
	if not root then
		return false
	end
	for _, part in CollectionService:GetTagged("Cauldron") do
		if (part.Position - root.Position).Magnitude < 16 then
			return true
		end
	end
	return false
end

local function nearShop(player)
	local root = rootOf(player)
	local shop = npcPosition("npc_bramble")
	return root and shop and (root.Position - shop).Magnitude < 20
end

local function forage(player, nodeId)
	local node = type(nodeId) == "string" and interactables[nodeId]
	local root = rootOf(player)
	if not node or node.Kind ~= "Forage" or not root then
		return false
	end
	if (root.Position - node.Position).Magnitude > Config.Forage.InteractDistance + 4 then
		return false, "เข้าไปใกล้อีกนิด"
	end
	if node.Item == "wisp_lily" and environment and not environment.IsNight() then
		return false, "ลิลลี่ดวงไฟยังหุบอยู่… มันจะบานตอนค่ำ"
	end
	local userCd = forageCooldown[player.UserId] or {}
	forageCooldown[player.UserId] = userCd
	local now = os.clock()
	if userCd[nodeId] and userCd[nodeId] > now then
		return false, string.format("ยังไม่งอกใหม่ (อีก %d วินาที)", math.ceil(userCd[nodeId] - now))
	end
	userCd[nodeId] = now + Config.Forage.RespawnSeconds
	local amount = math.random() < 0.25 and 2 or 1
	Inventory.Add(player, node.Item, amount)
	local data = DataService.Get(player)
	data.Stats.Foraged += amount
	Inventory.AddXP(player, 4)
	QuestService.Progress(player, "Forage", node.Item, amount)
	DataService.Push(player)
	return true, { Item = node.Item, Amount = amount, Respawn = Config.Forage.RespawnSeconds }
end

local function craft(player, recipeId)
	local recipe = type(recipeId) == "string" and Items.RecipeById[recipeId]
	if not recipe then
		return false, "ไม่พบสูตรนี้"
	end
	if not nearCauldron(player) then
		return false, "ต้องอยู่ใกล้หม้อยา"
	end
	if not Inventory.HasAll(player, recipe.Inputs) then
		return false, "วัตถุดิบไม่พอ"
	end
	for itemId, amount in recipe.Inputs do
		Inventory.Remove(player, itemId, amount)
	end
	task.wait(recipe.Seconds) -- เวลาปรุง (client เล่นแอนิเมชันหม้อเดือด)
	Inventory.Add(player, recipe.Output, recipe.Amount)
	local data = DataService.Get(player)
	if data then
		data.Stats.Brewed += 1
	end
	Inventory.AddXP(player, 15)
	QuestService.Progress(player, "Craft", recipe.Output, recipe.Amount)
	DataService.Push(player)
	return true, Items.ById[recipe.Output].ThaiName
end

local function buy(player, itemId, amount)
	local item = type(itemId) == "string" and Items.ById[itemId]
	amount = type(amount) == "number" and math.clamp(math.floor(amount), 1, 50) or 1
	if not item or not item.Price then
		return false, "สินค้านี้ไม่มีขาย"
	end
	if not nearShop(player) then
		return false, "ต้องอยู่ที่ร้านของแบรมเบิล"
	end
	if not Inventory.SpendCoins(player, item.Price * amount) then
		return false, "Lumen ไม่พอ"
	end
	Inventory.Add(player, itemId, amount)
	DataService.Push(player)
	return true
end

local function sell(player, itemId, amount)
	local item = type(itemId) == "string" and Items.ById[itemId]
	amount = type(amount) == "number" and math.clamp(math.floor(amount), 1, 99) or 1
	if not item or not item.SellPrice then
		return false, "ร้านไม่รับซื้อของชิ้นนี้"
	end
	if not nearShop(player) then
		return false, "ต้องอยู่ที่ร้านของแบรมเบิล"
	end
	if not Inventory.Remove(player, itemId, amount) then
		return false, "ของไม่พอ"
	end
	Inventory.AddCoins(player, item.SellPrice * amount)
	DataService.Push(player)
	return true
end

local VALID_GRAPHICS = { Auto = true, Low = true, Medium = true, High = true }

local function saveSettings(player, settings)
	local data = DataService.Get(player)
	if not data or type(settings) ~= "table" then
		return false
	end
	if type(settings.Music) == "number" then
		data.Settings.Music = math.clamp(settings.Music, 0, 1)
	end
	if type(settings.Sfx) == "number" then
		data.Settings.Sfx = math.clamp(settings.Sfx, 0, 1)
	end
	if VALID_GRAPHICS[settings.Graphics] then
		data.Settings.Graphics = settings.Graphics
	end
	if type(settings.ShowHints) == "boolean" then
		data.Settings.ShowHints = settings.ShowHints
	end
	return true
end

function EconomyService.Init(world, npcLookup, env)
	interactables = world.Interactables
	npcPosition = function(id)
		local npc = npcLookup(id)
		return npc and npc.Position
	end
	environment = env
	Net.Handle("Forage", forage, 0.3)
	Net.Handle("Craft", craft, 1)
	Net.Handle("Buy", buy, 0.2)
	Net.Handle("Sell", sell, 0.2)
	Net.Handle("SaveSettings", saveSettings, 1)
	Players.PlayerRemoving:Connect(function(player)
		forageCooldown[player.UserId] = nil
	end)
end

return EconomyService
