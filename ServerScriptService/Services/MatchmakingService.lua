--[[
	MatchmakingService.lua
	Handles cross-server matchmaking, region detection, and teleportation to game servers
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalizationService = game:GetService("LocalizationService")
local MessagingService = game:GetService("MessagingService")

local Logger = require(script.Parent.Parent.Shared.Logger)
local Config = require(game.ServerStorage.Config.GameConfig)

local MatchmakingService = {}
MatchmakingService.__index = MatchmakingService

local logger = Logger.new("MatchmakingService")

function MatchmakingService.new(queueService)
	local self = setmetatable({}, MatchmakingService)
	
	assert(queueService, "MatchmakingService requires queueService dependency")
	
	self.queueService = queueService
	self.regionGroups = {}
	self.matchmakingActive = false
	
	logger:info("MatchmakingService initialized")
	return self
end

function MatchmakingService:getPlayerRegion(player)
	local success, result = pcall(function()
		local country = LocalizationService:GetCountryRegionForPlayerAsync(player)
		return self:mapCountryToRegion(country)
	end)
	
	if success then
		return result
	else
		logger:warn("Failed to get region for player: " .. player.Name)
		return "Unknown"
	end
end

function MatchmakingService:mapCountryToRegion(country)
	-- Map countries to general regions
	local regionMap = {
		-- North America
		["US"] = "NA", ["CA"] = "NA", ["MX"] = "NA",
		
		-- Europe
		["GB"] = "EU", ["FR"] = "EU", ["DE"] = "EU", ["IT"] = "EU", 
		["ES"] = "EU", ["NL"] = "EU", ["PL"] = "EU", ["SE"] = "EU",
		["NO"] = "EU", ["FI"] = "EU", ["DK"] = "EU", ["BE"] = "EU",
		["CH"] = "EU", ["AT"] = "EU", ["PT"] = "EU", ["GR"] = "EU",
		["CZ"] = "EU", ["RO"] = "EU", ["HU"] = "EU", ["IE"] = "EU",
		
		-- Asia
		["JP"] = "AS", ["KR"] = "AS", ["CN"] = "AS", ["IN"] = "AS",
		["SG"] = "AS", ["TH"] = "AS", ["VN"] = "AS", ["PH"] = "AS",
		["ID"] = "AS", ["MY"] = "AS", ["TW"] = "AS", ["HK"] = "AS",
		
		-- Oceania
		["AU"] = "OC", ["NZ"] = "OC",
		
		-- South America
		["BR"] = "SA", ["AR"] = "SA", ["CL"] = "SA", ["CO"] = "SA",
		["PE"] = "SA", ["VE"] = "SA", ["UY"] = "SA",
	}
	
	return regionMap[country] or "Unknown"
end

function MatchmakingService:groupPlayersByRegion()
	local queuedPlayers = self.queueService:getQueuedPlayers()
	local groups = {}
	
	for _, player in ipairs(queuedPlayers) do
		local region = self:getPlayerRegion(player)
		
		if not groups[region] then
			groups[region] = {}
		end
		
		table.insert(groups[region], player)
	end
	
	return groups
end

function MatchmakingService:findMatch()
	local regionGroups = self:groupPlayersByRegion()
	
	for region, players in pairs(regionGroups) do
		if #players >= Config.Matchmaking.MinPlayers then
			local matchPlayers = {}
			
			-- Take up to MaxPlayers from this region
			for i = 1, math.min(#players, Config.Matchmaking.MaxPlayers) do
				table.insert(matchPlayers, players[i])
			end
			
			logger:info(string.format("Found match in region %s with %d players", region, #matchPlayers))
			return matchPlayers
		end
	end
	
	return nil
end

function MatchmakingService:createGameServer(players)
	if #players < Config.Matchmaking.MinPlayers then
		logger:warn("Not enough players to create game server")
		return false
	end
	
	-- Get the game place ID from config
	local gamePlaceId = Config.Matchmaking.GamePlaceId
	
	if not gamePlaceId then
		logger:error("GamePlaceId not configured! Cannot create game server.")
		return false
	end
	
	local success, reservedCode = pcall(function()
		return TeleportService:ReserveServer(gamePlaceId)
	end)
	
	if not success then
		logger:error("Failed to reserve server: " .. tostring(reservedCode))
		return false
	end
	
	logger:info("Created reserved server with code: " .. reservedCode)
	
	-- Remove players from queue before teleporting
	for _, player in ipairs(players) do
		self.queueService:removeFromQueue(player)
	end
	
	-- Teleport players to the reserved server
	local teleportSuccess = self:teleportPlayersToServer(players, gamePlaceId, reservedCode)
	
	return teleportSuccess
end

function MatchmakingService:teleportPlayersToServer(players, placeId, reservedCode)
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = reservedCode
	options.ShouldReserveServer = false
	
	local success, errorMsg = pcall(function()
		TeleportService:TeleportAsync(placeId, players, options)
	end)
	
	if success then
		logger:info(string.format("Teleported %d players to game server", #players))
		return true
	else
		logger:error("Failed to teleport players: " .. tostring(errorMsg))
		
		-- Re-add players to queue if teleport failed
		for _, player in ipairs(players) do
			self.queueService:addToQueue(player)
		end
		
		return false
	end
end

function MatchmakingService:startMatchmaking()
	if self.matchmakingActive then
		return
	end
	
	self.matchmakingActive = true
	logger:info("Matchmaking started")
	
	task.spawn(function()
		while self.matchmakingActive do
			task.wait(Config.Matchmaking.MatchmakingInterval or 2)
			
			local matchPlayers = self:findMatch()
			
			if matchPlayers then
				self:createGameServer(matchPlayers)
			end
		end
	end)
end

function MatchmakingService:stopMatchmaking()
	self.matchmakingActive = false
	logger:info("Matchmaking stopped")
end

return MatchmakingService
