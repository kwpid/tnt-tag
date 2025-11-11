--[[
        Main.server.lua
        Bootstrap script that initializes all services and starts the game loop
        Supports both lobby servers (matchmaking) and game servers (reserved servers)
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

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
local QueueService = require(script.Parent.Services.QueueService)
local MatchmakingService = require(script.Parent.Services.MatchmakingService)
local GhostService = require(script.Parent.Services.GhostService)

local logger = Logger.new("Main")

logger:info("Initializing TNT PvP Game...")
logger:info("Loading configuration...")

-- Detect server type
local isGameServer = false
local reservedServerCode = game.PrivateServerId
if reservedServerCode and reservedServerCode ~= "" then
        isGameServer = true
        logger:info("Detected GAME SERVER (Reserved Server)")
else
        logger:info("Detected LOBBY SERVER")
end

-- Initialize services in dependency order
local leaderboardService = LeaderboardService.new()
local playerService = PlayerService.new(leaderboardService)
local tntService = TNTService.new()
local rewardService = RewardService.new(leaderboardService)
local messagingService = MessagingService.new()
local effectsService = EffectsService.new()
local ghostService = GhostService.new()
local matchService = MatchService.new(playerService, tntService, rewardService, messagingService, ghostService)

-- Initialize matchmaking services only for lobby servers
local queueService, matchmakingService
if not isGameServer then
        queueService = QueueService.new()
        matchmakingService = MatchmakingService.new(queueService)
end

-- Register services in global registry for access by other scripts
ServiceRegistry:register("LeaderboardService", leaderboardService)
ServiceRegistry:register("PlayerService", playerService)
ServiceRegistry:register("TNTService", tntService)
ServiceRegistry:register("RewardService", rewardService)
ServiceRegistry:register("MessagingService", messagingService)
ServiceRegistry:register("EffectsService", effectsService)
ServiceRegistry:register("MatchService", matchService)
ServiceRegistry:register("GhostService", ghostService)

if not isGameServer then
        ServiceRegistry:register("QueueService", queueService)
        ServiceRegistry:register("MatchmakingService", matchmakingService)
end

logger:info("All services initialized and registered successfully")

-- Player event handlers
Players.PlayerAdded:Connect(function(player)
        playerService:initializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
        playerService:cleanupPlayer(player)
        if ghostService then
                ghostService:cleanupPlayer(player)
        end
        if queueService then
                queueService:cleanupPlayer(player)
        end
end)

-- Server-specific game loops
if isGameServer then
        -- GAME SERVER: Wait for players then start match
        logger:info("Starting GAME SERVER loop")
        
        task.spawn(function()
                -- Wait for players to join
                local playersReady = matchService:waitForPlayersInGameServer()
                
                if playersReady then
                        -- Load map and start match
                        matchService:loadRandomMap()
                        task.wait(1)
                        matchService:startMatch()
                else
                        logger:error("Failed to gather enough players for match")
                        -- Server will shutdown or wait
                end
        end)
else
        -- LOBBY SERVER: Run matchmaking
        logger:info("Starting LOBBY SERVER loop with matchmaking")
        
        -- Start matchmaking service
        task.spawn(function()
                task.wait(2) -- Wait for services to fully initialize
                matchmakingService:startMatchmaking()
        end)
        
        -- Old game loop kept for backward compatibility (can be removed if not needed)
        task.spawn(function()
                logger:info("Starting legacy game loop (disabled in matchmaking mode)")
                
                -- You can enable this for testing without matchmaking
                local legacyModeEnabled = false
                
                if legacyModeEnabled then
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
                end
        end)
end

-- Shutdown handler
game:BindToClose(function()
        logger:info("Server shutting down, saving all player data...")
        leaderboardService:saveAll()
        logger:info("All data saved")
end)

logger:info("TNT PvP Game fully initialized and running!")
