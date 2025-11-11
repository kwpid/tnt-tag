--[[
	RewardService.lua
	Handles all reward calculations and distributions (cash, XP, streaks)
]]

local Players = game:GetService("Players")

local Logger = require(script.Parent.Parent.Shared.Logger)
local Config = require(game.ServerStorage.Config.GameConfig)

local RewardService = {}
RewardService.__index = RewardService

local logger = Logger.new("RewardService")

function RewardService.new(leaderboardService)
	local self = setmetatable({}, RewardService)
	self.leaderboardService = leaderboardService
	return self
end

function RewardService:calculateCashReward(placement, totalPlayers, isWinner)
	local baseCash = Config.Rewards.Cash.Base
	local playerBonus = totalPlayers * Config.Rewards.Cash.PlayerCountBonus
	local placementBonus = (totalPlayers - placement + 1) * Config.Rewards.Cash.PlacementMultiplier
	
	local totalCash = baseCash + playerBonus + placementBonus
	
	if isWinner then
		totalCash = totalCash * Config.Rewards.Cash.WinnerMultiplier
	end
	
	return math.floor(totalCash)
end

function RewardService:calculateXPReward(placement, totalPlayers, isWinner)
	if isWinner then
		return Config.Rewards.XP.Max
	end
	
	-- Calculate XP based on placement (higher placement = more XP)
	local placementBonus = (totalPlayers - placement) * Config.Rewards.XP.PerPlacement
	local totalXP = Config.Rewards.XP.Base + placementBonus
	
	-- Cap XP at MAX_XP - 1 for non-winners
	return math.min(totalXP, Config.Rewards.XP.Max - 1)
end

function RewardService:awardCash(player, amount, reason)
	local cash = player:FindFirstChild("Cash")
	if cash and cash:IsA("IntValue") then
		cash.Value = cash.Value + amount
		logger:info(player.Name .. " received " .. amount .. " cash: " .. reason)
		return true
	else
		logger:warn("Cannot award cash to " .. player.Name .. ": Cash stat not found")
		return false
	end
end

function RewardService:awardXP(player, amount, reason)
	local xp = player:FindFirstChild("XP")
	if xp and xp:IsA("IntValue") then
		xp.Value = xp.Value + amount
		logger:info(player.Name .. " received " .. amount .. " XP: " .. reason)
		return true
	else
		logger:warn("Cannot award XP to " .. player.Name .. ": XP stat not found")
		return false
	end
end

function RewardService:awardPlacementRewards(player, placement, totalPlayers)
	local cashReward = self:calculateCashReward(placement, totalPlayers, false)
	local xpReward = self:calculateXPReward(placement, totalPlayers, false)
	
	local reason = "Eliminated in round (Place #" .. placement .. ")"
	self:awardCash(player, cashReward, reason)
	self:awardXP(player, xpReward, reason)
	
	-- Reset streak on elimination
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local streak = stats:FindFirstChild("Streak")
		if streak then
			streak.Value = 0
		end
	end
	
	logger:info(string.format("Awarded placement rewards to %s: %d cash, %d XP", 
		player.Name, cashReward, xpReward))
end

function RewardService:awardWinnerRewards(player, totalPlayers)
	local cashReward = self:calculateCashReward(1, totalPlayers, true)
	local xpReward = Config.Rewards.XP.Max
	
	self:awardCash(player, cashReward, "🏆 Victory! (1st Place)")
	self:awardXP(player, xpReward, "🏆 Victory! (1st Place)")
	
	-- Update win stats
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local wins = stats:FindFirstChild("Wins")
		if wins then
			wins.Value = wins.Value + 1
		end
		
		local streak = stats:FindFirstChild("Streak")
		if streak then
			streak.Value = streak.Value + 1
			
			local highestStreak = stats:FindFirstChild("HighestStreak")
			if highestStreak and streak.Value > highestStreak.Value then
				highestStreak.Value = streak.Value
			end
		end
	end
	
	-- Update weekly stats
	local weeklyWins = player:FindFirstChild("WeeklyWins")
	if weeklyWins then
		weeklyWins.Value = weeklyWins.Value + 1
	end
	
	local weeklyHighestStreak = player:FindFirstChild("WeeklyHighestStreak")
	if weeklyHighestStreak and stats then
		local currentStreak = stats:FindFirstChild("Streak")
		if currentStreak and currentStreak.Value > weeklyHighestStreak.Value then
			weeklyHighestStreak.Value = currentStreak.Value
		end
	end
	
	logger:info(string.format("Awarded winner rewards to %s: %d cash, %d XP", 
		player.Name, cashReward, xpReward))
end

return RewardService
