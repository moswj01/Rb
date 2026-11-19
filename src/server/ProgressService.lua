--[[
	ProgressService — XP / Party Pass / ภารกิจมือใหม่ / ฉายาความสำเร็จ
	ระบบ "ความก้าวหน้า" คือสิ่งที่ทำให้คนกลับมาเล่นทุกวัน (Retention)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ItemCatalog = require(Shared.ItemCatalog)
local PartyPass = require(Shared.PartyPass)

local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local Rewards = require(script.Parent.Rewards)
local Analytics = require(script.Parent.Analytics)

local ProgressService = {}

local MAX_XP = Config.PartyPass.Tiers * Config.PartyPass.XPPerTier

-- ===== XP / Party Pass =====

function ProgressService.AddXP(player, amount)
	local data = DataService.Get(player)
	if not data or amount <= 0 then
		return
	end
	local before = PartyPass.TierFromXP(data.Pass.XP)
	data.Pass.XP = math.min(MAX_XP, data.Pass.XP + amount)
	local after = PartyPass.TierFromXP(data.Pass.XP)
	if after > before then
		Remotes.LevelUp:FireClient(player, after)
	end
end

function ProgressService.AddTiers(player, tiers)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local current = PartyPass.TierFromXP(data.Pass.XP)
	local target = math.min(Config.PartyPass.Tiers, current + tiers)
	data.Pass.XP = math.max(data.Pass.XP, target * Config.PartyPass.XPPerTier)
	Remotes.LevelUp:FireClient(player, target)
end

local function claimPassTier(player, tier, track)
	local data = DataService.Get(player)
	if not data then
		return false, "กำลังโหลดข้อมูล..."
	end
	if type(tier) ~= "number" or tier % 1 ~= 0 or tier < 1 or tier > Config.PartyPass.Tiers then
		return false, "ขั้นไม่ถูกต้อง"
	end
	if track ~= "Free" and track ~= "Premium" then
		return false, "ไม่ถูกต้อง"
	end
	if PartyPass.TierFromXP(data.Pass.XP) < tier then
		return false, "ยังไม่ถึงขั้นนี้ เล่นต่ออีกนิดนะ!"
	end
	if track == "Premium" and not player:GetAttribute("PartyPass") then
		return false, "ต้องมี Party Pass พรีเมียมก่อน 🎫"
	end
	local key = PartyPass.Key(tier)
	if data.Pass[track][key] then
		return false, "รับไปแล้ว"
	end
	data.Pass[track][key] = true
	local reward = (track == "Free" and PartyPass.Free or PartyPass.Premium)[tier]
	local summary = Rewards.Grant(player, reward, "TimedReward", "PartyPass_" .. track .. "_" .. tier)
	DataService.Push(player)
	return true, "🎫 ขั้น " .. tier .. ": ได้รับ " .. summary
end

-- ===== ภารกิจมือใหม่ =====

function ProgressService.Tutorial(player, eventId, amount)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local tutorial = data.Tutorial
	local step = Config.Tutorial[tutorial.Step]
	if not step or step.Id ~= eventId then
		return
	end
	tutorial.Progress += amount or 1
	if tutorial.Progress >= step.Goal then
		tutorial.Step += 1
		tutorial.Progress = 0
		local summary = Rewards.Grant(player, step.Reward, "Onboarding", "Tutorial_" .. step.Id)
		Remotes.Notify(player, "✅ ภารกิจสำเร็จ! ได้รับ " .. summary, "good")
		Analytics.Onboarding(player, tutorial.Step, "Tutorial_" .. step.Id)
	end
	DataService.Push(player)
end

-- ===== ฉายาจากความสำเร็จ =====

function ProgressService.CheckAchievements(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local changed = false
	for _, item in ItemCatalog.List do
		local req = item.Requirement
		if req and not data.Owned[item.Id] and (data.Stats[req.Stat] or 0) >= req.Value then
			Rewards.GiveItem(player, item.Id)
			Remotes.Notify(player, "🏅 ปลดล็อกฉายา " .. item.Text .. "!", "good")
			changed = true
		end
	end
	if changed then
		DataService.Push(player)
	end
end

function ProgressService.Init()
	Remotes.ClaimPassTier.OnServerInvoke = claimPassTier
	DataService.OnLoaded(function(player)
		ProgressService.CheckAchievements(player)
	end)
end

return ProgressService
