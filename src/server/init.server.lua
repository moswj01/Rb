--[[
	Skin Party Island — Server entry point
	ลำดับการเริ่มระบบสำคัญ: Remotes → Map → Data → Cosmetic → Shop → Monetization → Stars → Rounds
]]

local Remotes = require(script.Remotes) -- สร้าง ReplicatedStorage.Remotes ก่อนทุกอย่าง
local MapBuilder = require(script.MapBuilder)
local DataService = require(script.DataService)
local CosmeticService = require(script.CosmeticService)
local ShopService = require(script.ShopService)
local MonetizationService = require(script.MonetizationService)
local CollectibleService = require(script.CollectibleService)
local RoundService = require(script.RoundService)

local _ = Remotes
local map = MapBuilder.Build()

DataService.Init()
CosmeticService.Init()
ShopService.Init()
MonetizationService.Init()
CollectibleService.Init(map)
RoundService.Init(map)

print("🎉 Skin Party Island server ready!")
