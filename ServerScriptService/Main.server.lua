--[[
        Main.server.lua
        Bootstrap script that initializes all services and starts the game loop
]]

local Players = game:GetService("Players")

local Logger = require(script.Parent.Shared.Logger)
local ServiceRegistry = require(script.Parent.Shared.ServiceRegistry)
local Config = require(game.ServerStorage.Config.GameConfig)

-- Import all services
local LeaderboardService = require(script.Parent.Services.LeaderboardService)
local PlayerService = require(script.Parent.Services.PlayerService)
local TNTService = require(script.Parent.Services.TNTService)
local RewardService = require(script.Parent.Services.RewardService)
local MessagingService = require(script.Parent.Services.MessagingService)
local EffectsService = require(script.Parent.Services.EffectsService)
local MatchService = require(script.Parent.Services.MatchService)

local logger = Logger.new("Main")

logger:info("Initializing TNT PvP Game...")
logger:info("Loading configuration...")

-- Initialize services in dependency order
local leaderboardService = LeaderboardService.new()
local playerService = PlayerService.new(leaderboardService)
local tntService = TNTService.new()
local rewardService = RewardService.new(leaderboardService)
local messagingService = MessagingService.new()
local effectsService = EffectsService.new()
local matchService = MatchService.new(playerService, tntService, rewardService, messagingService)

-- Register services in global registry for access by other scripts
ServiceRegistry:register("LeaderboardService", leaderboardService)
ServiceRegistry:register("PlayerService", playerService)
ServiceRegistry:register("TNTService", tntService)
ServiceRegistry:register("RewardService", rewardService)
ServiceRegistry:register("MessagingService", messagingService)
ServiceRegistry:register("EffectsService", effectsService)
ServiceRegistry:register("MatchService", matchService)

logger:info("All services initialized and registered successfully")

-- Player event handlers
Players.PlayerAdded:Connect(function(player)
        playerService:initializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
        playerService:cleanupPlayer(player)
end)

-- Game loop with error handling
task.spawn(function()
        logger:info("Starting game loop")
        
        while true do
                local success, err = pcall(function()
                        task.wait(1)
                        
                        local lobbyTeam = playerService:getLobbyTeam()
                        if not lobbyTeam then
                                logger:warn("Lobby team not found, skipping loop iteration")
                                return
                        end
                        
                        local activeLobbyPlayers = playerService:getActiveTeamPlayers(lobbyTeam)
                        
                        if not matchService:isActive() and #activeLobbyPlayers >= Config.Match.MinPlayers then
                                local intermissionSuccess = matchService:runIntermission()
                                
                                if intermissionSuccess then
                                        local finalCheck = playerService:getActiveTeamPlayers(lobbyTeam)
                                        if #finalCheck >= Config.Match.MinPlayers then
                                                matchService:startMatch()
                                        end
                                end
                        elseif not matchService:isActive() then
                                messagingService:broadcastWaitingForPlayers()
                        end
                end)
                
                if not success then
                        logger:error("Game loop error", err)
                        task.wait(5)
                end
        end
end)

-- Shutdown handler
game:BindToClose(function()
        logger:info("Server shutting down, saving all player data...")
        leaderboardService:saveAll()
        logger:info("All data saved")
end)

logger:info("TNT PvP Game fully initialized and running!")
