--[[
	PartyPass — Season Pass 30 ขั้น (ฟรี + พรีเมียม)
	เล่นอะไรก็ได้ XP → เลื่อนขั้น → กดรับรางวัล
	พรีเมียม (Game Pass) ปลดล็อกชุด "ความฝันสายรุ้ง" ระดับเทพนิยายครบเซ็ต
]]

local Config = require(script.Parent.Config)

local PartyPass = {}

local Free = {}
local Premium = {}

for tier = 1, Config.PartyPass.Tiers do
	Free[tier] = { Coins = 50 + tier * 10 }
	Premium[tier] = { Coins = 150 + tier * 20 }
end

-- รางวัลพิเศษฝั่งฟรี
Free[5] = { Gems = 5 }
Free[10] = { Gems = 10 }
Free[15] = { Coins = 800 }
Free[20] = { Gems = 15 }
Free[25] = { Coins = 1500 }
Free[30] = { Item = "title_pass", Gems = 20 }

-- รางวัลพรีเมียม: ชุดสายรุ้งครบเซ็ต + เพชร (รวม 300)
Premium[1] = { Item = "trail_rainbow", Gems = 20 }
Premium[3] = { Gems = 25 }
Premium[5] = { Item = "aura_rainbow" }
Premium[8] = { Gems = 30 }
Premium[10] = { Item = "hat_rainbow_halo" }
Premium[13] = { Gems = 35 }
Premium[15] = { Item = "pet_unicorn" }
Premium[18] = { Gems = 40 }
Premium[20] = { Item = "wings_rainbow" }
Premium[23] = { Gems = 45 }
Premium[25] = { Gems = 50, Coins = 3000 }
Premium[28] = { Gems = 55 }
Premium[30] = { Item = "skin_rainbow", Coins = 5000 }

PartyPass.Free = Free
PartyPass.Premium = Premium

function PartyPass.TierFromXP(xp)
	return math.min(Config.PartyPass.Tiers, math.floor(xp / Config.PartyPass.XPPerTier))
end

function PartyPass.ProgressInTier(xp)
	local tier = PartyPass.TierFromXP(xp)
	if tier >= Config.PartyPass.Tiers then
		return 1, tier
	end
	return (xp % Config.PartyPass.XPPerTier) / Config.PartyPass.XPPerTier, tier
end

function PartyPass.Key(tier)
	return "t" .. tier
end

return PartyPass
