--[[
	LeaderboardService.lua
	Manages player data persistence with DataStore and JSON inventory support
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Logger = require(script.Parent.Parent.Shared.Logger)
local Config = require(game.ServerStorage.Config.GameConfig)

local LeaderboardService = {}
LeaderboardService.__index = LeaderboardService

local DATASTORE_NAME = "PlayerData_V1"
local logger = Logger.new("LeaderboardService")

-- Default player data structure
local DEFAULT_DATA = {
	wins = 0,
	streak = 0,
	highestStreak = 0,
	cash = 0,
	xp = 0,
	weeklyWins = 0,
	weeklyHighestStreak = 0,
	inventory = {}, -- JSON-serializable inventory for future use
}

function LeaderboardService.new()
	local self = setmetatable({}, LeaderboardService)
	self.playerDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
	self.playerCache = {} -- Cache loaded data
	self.saveQueue = {} -- Track players needing saves
	
	-- Auto-save loop
	task.spawn(function()
		self:startAutoSave()
	end)
	
	return self
end

function LeaderboardService:getPlayerKey(player)
	return "Player_" .. player.UserId
end

function LeaderboardService:loadPlayerData(player)
	local key = self:getPlayerKey(player)
	
	for attempt = 1, Config.Data.RetryAttempts do
		local success, data = pcall(function()
			return self.playerDataStore:GetAsync(key)
		end)
		
		if success then
			if data then
				logger:info("Loaded data for " .. player.Name)
				-- Merge with defaults to handle new fields
				local mergedData = {}
				for k, v in pairs(DEFAULT_DATA) do
					mergedData[k] = (data[k] ~= nil) and data[k] or v
				end
				self.playerCache[player] = mergedData
				return mergedData
			else
				logger:info("No existing data for " .. player.Name .. ", using defaults")
				self.playerCache[player] = self:deepCopy(DEFAULT_DATA)
				return self.playerCache[player]
			end
		else
			logger:warn("Load attempt " .. attempt .. " failed for " .. player.Name, data)
			if attempt < Config.Data.RetryAttempts then
				task.wait(Config.Data.RetryDelay)
			end
		end
	end
	
	-- Fallback to defaults
	logger:error("Failed to load data for " .. player.Name .. " after all retries")
	self.playerCache[player] = self:deepCopy(DEFAULT_DATA)
	return self.playerCache[player]
end

function LeaderboardService:savePlayerData(player, data)
	local key = self:getPlayerKey(player)
	data = data or self.playerCache[player]
	
	if not data then
		logger:warn("No data to save for " .. player.Name)
		return false
	end
	
	for attempt = 1, Config.Data.RetryAttempts do
		local success, err = pcall(function()
			self.playerDataStore:SetAsync(key, data)
		end)
		
		if success then
			logger:info("Saved data for " .. player.Name)
			return true
		else
			logger:warn("Save attempt " .. attempt .. " failed for " .. player.Name, err)
			if attempt < Config.Data.RetryAttempts then
				task.wait(Config.Data.RetryDelay)
			end
		end
	end
	
	logger:error("Failed to save data for " .. player.Name .. " after all retries")
	return false
end

function LeaderboardService:getPlayerData(player)
	return self.playerCache[player]
end

function LeaderboardService:updateStat(player, statName, value)
	local data = self.playerCache[player]
	if data then
		data[statName] = value
		self:markForSave(player)
	else
		logger:warn("Attempted to update stat for player with no cached data: " .. player.Name)
	end
end

function LeaderboardService:incrementStat(player, statName, amount)
	local data = self.playerCache[player]
	if data then
		data[statName] = (data[statName] or 0) + amount
		self:markForSave(player)
	else
		logger:warn("Attempted to increment stat for player with no cached data: " .. player.Name)
	end
end

function LeaderboardService:createLeaderstats(player)
	local data = self.playerCache[player]
	if not data then
		logger:error("Cannot create leaderstats without loaded data for " .. player.Name)
		return
	end
	
	-- Remove existing leaderstats if any
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		existing:Destroy()
	end
	
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	-- Create IntValues for leaderboard display
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = data.wins
	wins.Parent = leaderstats
	
	local streak = Instance.new("IntValue")
	streak.Name = "Streak"
	streak.Value = data.streak
	streak.Parent = leaderstats
	
	local highestStreak = Instance.new("IntValue")
	highestStreak.Name = "HighestStreak"
	highestStreak.Value = data.highestStreak
	highestStreak.Parent = leaderstats
	
	-- Create other stats (not in leaderstats folder)
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data.cash
	cash.Parent = player
	
	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = data.xp
	xp.Parent = player
	
	local weeklyWins = Instance.new("IntValue")
	weeklyWins.Name = "WeeklyWins"
	weeklyWins.Value = data.weeklyWins
	weeklyWins.Parent = player
	
	local weeklyHighestStreak = Instance.new("IntValue")
	weeklyHighestStreak.Name = "WeeklyHighestStreak"
	weeklyHighestStreak.Value = data.weeklyHighestStreak
	weeklyHighestStreak.Parent = player
	
	-- Connect change listeners to update cache
	wins.Changed:Connect(function(newValue)
		self:updateStat(player, "wins", newValue)
	end)
	
	streak.Changed:Connect(function(newValue)
		self:updateStat(player, "streak", newValue)
	end)
	
	highestStreak.Changed:Connect(function(newValue)
		self:updateStat(player, "highestStreak", newValue)
	end)
	
	cash.Changed:Connect(function(newValue)
		self:updateStat(player, "cash", newValue)
	end)
	
	xp.Changed:Connect(function(newValue)
		self:updateStat(player, "xp", newValue)
	end)
	
	weeklyWins.Changed:Connect(function(newValue)
		self:updateStat(player, "weeklyWins", newValue)
	end)
	
	weeklyHighestStreak.Changed:Connect(function(newValue)
		self:updateStat(player, "weeklyHighestStreak", newValue)
	end)
	
	logger:info("Created leaderstats for " .. player.Name)
end

function LeaderboardService:markForSave(player)
	self.saveQueue[player] = true
end

function LeaderboardService:startAutoSave()
	while true do
		task.wait(Config.Data.AutoSaveInterval)
		logger:info("Auto-save triggered")
		self:saveAll()
	end
end

function LeaderboardService:saveAll()
	for player, _ in pairs(self.saveQueue) do
		if player and player.Parent then
			self:savePlayerData(player)
			self.saveQueue[player] = nil
		end
	end
end

function LeaderboardService:playerLeaving(player)
	self:savePlayerData(player)
	self.playerCache[player] = nil
	self.saveQueue[player] = nil
end

-- Inventory methods (JSON support for future)
function LeaderboardService:setInventoryItem(player, itemId, itemData)
	local data = self.playerCache[player]
	if data then
		data.inventory[itemId] = itemData
		self:markForSave(player)
		logger:debug("Set inventory item for " .. player.Name, itemId)
	end
end

function LeaderboardService:getInventoryItem(player, itemId)
	local data = self.playerCache[player]
	return data and data.inventory[itemId]
end

function LeaderboardService:removeInventoryItem(player, itemId)
	local data = self.playerCache[player]
	if data and data.inventory[itemId] then
		data.inventory[itemId] = nil
		self:markForSave(player)
		logger:debug("Removed inventory item for " .. player.Name, itemId)
	end
end

function LeaderboardService:getInventory(player)
	local data = self.playerCache[player]
	return data and data.inventory or {}
end

-- Utility
function LeaderboardService:deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = self:deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

return LeaderboardService
