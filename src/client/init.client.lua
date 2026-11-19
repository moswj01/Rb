-- Skin Party Island — Client entry point
local Net = require(script.Net)
local Toast = require(script.Toast)
local ShopUI = require(script.ShopUI)
local Panels = require(script.Panels)
local Hud = require(script.Hud)
local Effects = require(script.Effects)

Net.Init()
Toast.Init()
ShopUI.Init()
Panels.Init()
Hud.Init()
Effects.Init()

task.delay(2, function()
	Toast.Show("ยินดีต้อนรับสู่ Skin Party Island! 🎉 เก็บดาว ⭐ เพื่อซื้อสกินกันเลย", "good")
end)
