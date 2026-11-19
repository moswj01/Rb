--[[
	Analytics — ส่งข้อมูลเข้า Creator Dashboard (Analytics > Economy / Funnels)
	ใช้ดูว่าเงินในเกมไหลเข้า-ออกทางไหน และผู้เล่นใหม่หลุดตรงขั้นไหนของ tutorial
	ทุกคำสั่งห่อด้วย pcall: ถ้า API เปลี่ยน/ใช้ไม่ได้ เกมก็ยังทำงานปกติ
]]

local AnalyticsService = game:GetService("AnalyticsService")

local Analytics = {}

local function safe(fn)
	local ok, err = pcall(fn)
	if not ok then
		warn("[Analytics]", err)
	end
end

-- flow: "Source" (ได้เงิน) | "Sink" (ใช้เงิน)
-- transactionType: "Gameplay" | "Shop" | "IAP" | "TimedReward" | "Onboarding" | "ContextualPurchase"
function Analytics.Economy(player, flow, currency, amount, balance, transactionType, sku)
	if amount <= 0 then
		return
	end
	safe(function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType[flow],
			currency,
			amount,
			balance,
			transactionType,
			sku
		)
	end)
end

function Analytics.Onboarding(player, step, stepName)
	safe(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
end

function Analytics.Custom(player, eventName, value)
	safe(function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1)
	end)
end

return Analytics
