-- Skin Party Island v2 — Client entry point
local Net = require(script.Net)
local Toast = require(script.Toast)
local Celebration = require(script.Celebration)
local ShopUI = require(script.ShopUI)
local PartyPassUI = require(script.PartyPassUI)
local Panels = require(script.Panels)
local Hud = require(script.Hud)
local Effects = require(script.Effects)

Net.Init()
Toast.Init()
Celebration.Init()
ShopUI.Init()
PartyPassUI.Init()
Panels.Init()
Hud.Init()
Effects.Init()

ShopUI.OnOpenPartyPass = PartyPassUI.Open

task.delay(2, function()
	Toast.Show("ยินดีต้อนรับสู่ Skin Party Island! 🎉 ทำภารกิจมุมซ้ายล่างเพื่อรับของฟรี", "good")
end)
