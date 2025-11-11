--[[
        MatchService.lua
        Manages the match lifecycle: intermission, rounds, win detection, map management
]]

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Logger = require(script.Parent.Parent.Shared.Logger)
local Config = require(game.ServerStorage.Config.GameConfig)

local MatchService = {}
MatchService.__index = MatchService

local logger = Logger.new("MatchService")

function MatchService.new(playerService, tntService, rewardService, messagingService, ghostService)
        local self = setmetatable({}, MatchService)
        
        -- Validate dependencies
        assert(playerService, "MatchService requires playerService dependency")
        assert(tntService, "MatchService requires tntService dependency")
        assert(rewardService, "MatchService requires rewardService dependency")
        assert(messagingService, "MatchService requires messagingService dependency")
        
        self.playerService = playerService
        self.tntService = tntService
        self.rewardService = rewardService
        self.messagingService = messagingService
        self.ghostService = ghostService
        
        self.mapFolder = ServerStorage:WaitForChild(Config.Storage.MapFolder)
        self.currentMap = nil
        self.active = false
        self.gameStartPlayers = 0
        
        if not self.mapFolder then
                logger:error("Maps folder not found in ServerStorage")
        end
        
        logger:info("MatchService initialized with all dependencies")
        return self
end

function MatchService:isActive()
        return self.active
end

function MatchService:loadRandomMap()
        local maps = self.mapFolder:GetChildren()
        if #maps == 0 then
                logger:error("No maps found in Maps folder")
                return false
        end
        
        local chosen = maps[math.random(1, #maps)]:Clone()
        chosen.Parent = Workspace
        self.currentMap = chosen
        
        logger:info("Loaded map: " .. chosen.Name)
        return true
end

function MatchService:clearMap()
        if self.currentMap then
                self.currentMap:Destroy()
                self.currentMap = nil
                logger:debug("Cleared current map")
        end
end

function MatchService:getMapSpawn()
        if not self.currentMap then
                return nil
        end
        return self.currentMap:FindFirstChild("MapSpawn")
end

function MatchService:checkForWinner()
        local gameTeam = self.playerService:getGameTeam()
        local remaining = self.playerService:getTeamPlayers(gameTeam)
        
        if #remaining == 1 then
                local winner = remaining[1]
                logger:info("Winner detected: " .. winner.Name)
                
                self.messagingService:broadcastWinner(winner.DisplayName)
                self.rewardService:awardWinnerRewards(winner, self.gameStartPlayers)
                
                -- Clean up all ghosts before moving to lobby
                if self.ghostService then
                        self.ghostService:cleanupAllGhosts()
                end
                
                -- Move all to lobby and cleanup
                self.playerService:moveAllToLobby()
                self:clearMap()
                self.playerService:teleportTeamToLobby(self.playerService:getLobbyTeam())
                self:clearAllPlayerAttributes()
                
                return true
        end
        
        return false
end

function MatchService:clearAllPlayerAttributes()
        local Players = game:GetService("Players")
        for _, player in pairs(Players:GetPlayers()) do
                self.playerService:clearGameAttributes(player)
        end
end

function MatchService:playRound()
        self.tntService:resetAllTNT()
        
        local gameTeam = self.playerService:getGameTeam()
        local gamePlayers = self.playerService:getTeamPlayers(gameTeam)
        
        self.tntService:assignInitialTNT(gamePlayers)
        
        local roundTimer = Config.Match.RoundTime
        
        while roundTimer > 0 do
                self.messagingService:broadcastTNTTimer(roundTimer)
                task.wait(1)
                roundTimer = roundTimer - 1
                
                if self:checkForWinner() then
                        return
                end
                
                -- Check if all players have TNT (early explosion)
                local currentGamePlayers = self.playerService:getTeamPlayers(gameTeam)
                if self.tntService:allPlayersHaveTNT(currentGamePlayers) then
                        self.messagingService:broadcastAllHaveTNT()
                        break
                end
        end
        
        -- Eliminate players with TNT
        self:eliminateTNTPlayers()
        task.wait(3)
        
        -- Teleport survivors back to map
        local mapSpawn = self:getMapSpawn()
        if mapSpawn then
                self.playerService:teleportTeamToMap(gameTeam, mapSpawn)
        end
        
        self:checkForWinner()
end

function MatchService:eliminateTNTPlayers()
        local gameTeam = self.playerService:getGameTeam()
        local lobbyTeam = self.playerService:getLobbyTeam()
        local remainingPlayers = self.playerService:getTeamPlayers(gameTeam)
        local eliminatedPlayers = {}
        
        local Players = game:GetService("Players")
        
        for _, player in pairs(Players:GetPlayers()) do
                if player.Team == gameTeam and player:GetAttribute("HasTNT") then
                        local placement = #remainingPlayers
                        
                        -- Award placement rewards
                        self.rewardService:awardPlacementRewards(player, placement, self.gameStartPlayers)
                        
                        -- Create explosion effect
                        local EffectsService = require(script.Parent.EffectsService)
                        local effects = EffectsService.new()
                        effects:createExplosionEffect(player)
                        
                        -- Remove from game
                        player.Team = lobbyTeam
                        player:SetAttribute("HasTNT", false)
                        table.insert(eliminatedPlayers, player.DisplayName)
                        
                        -- Remove TNT accessory
                        self.tntService:removeTNTAccessory(player)
                        
                        -- Convert to ghost instead of teleporting to lobby
                        if Config.Ghost.Enabled and self.ghostService then
                                task.wait(0.5)
                                self.ghostService:makeGhost(player)
                        else
                                -- Fallback to old behavior (teleport to lobby)
                                task.wait(0.5)
                                self.playerService:teleportPlayerToLobby(player)
                        end
                end
        end
        
        if #eliminatedPlayers > 0 then
                self.messagingService:broadcastEliminated(eliminatedPlayers)
        end
end

function MatchService:startMatch()
        if self.active then
                logger:warn("Cannot start match: already active")
                return
        end
        
        self.active = true
        logger:info("Starting match")
        
        -- Count active players
        local lobbyTeam = self.playerService:getLobbyTeam()
        local activePlayers = self.playerService:getActiveTeamPlayers(lobbyTeam)
        self.gameStartPlayers = #activePlayers
        
        -- Move players to game team
        self.playerService:movePlayersToGame()
        self.playerService:teleportTeamToLobby(lobbyTeam)
        
        task.wait(1)
        
        -- Teleport to map
        local mapSpawn = self:getMapSpawn()
        if mapSpawn then
                local gameTeam = self.playerService:getGameTeam()
                self.playerService:teleportTeamToMap(gameTeam, mapSpawn)
        end
        
        -- Play rounds until winner
        local gameTeam = self.playerService:getGameTeam()
        while #self.playerService:getTeamPlayers(gameTeam) > 1 do
                self:playRound()
        end
        
        -- Final cleanup
        local Players = game:GetService("Players")
        for _, player in pairs(Players:GetPlayers()) do
                player:SetAttribute("CanHit", false)
        end
        
        if self:checkForWinner() then
                task.wait(3)
                self.messagingService:broadcastWaitingForPlayers()
        end
        
        -- Clean up all ghosts at match end
        if self.ghostService then
                self.ghostService:cleanupAllGhosts()
        end
        
        task.wait(3)
        self.tntService:resetAllTNT()
        self:clearAllPlayerAttributes()
        self.playerService:teleportTeamToLobby(lobbyTeam)
        
        self.active = false
        logger:info("Match ended")
end

function MatchService:runIntermission()
        local lobbyTeam = self.playerService:getLobbyTeam()
        local intermissionTime = Config.Match.IntermissionTime
        
        for i = intermissionTime, 1, -1 do
                local activePlayers = self.playerService:getActiveTeamPlayers(lobbyTeam)
                
                if #activePlayers < Config.Match.MinPlayers then
                        self.messagingService:broadcastIntermissionCancelled()
                        task.wait(2)
                        return false
                end
                
                if i == 3 then
                        self:clearMap()
                        self:loadRandomMap()
                end
                
                self.messagingService:broadcastIntermission(i)
                task.wait(1)
        end
        
        -- Final check
        local activePlayers = self.playerService:getActiveTeamPlayers(lobbyTeam)
        if #activePlayers >= Config.Match.MinPlayers then
                return true
        end
        
        return false
end

function MatchService:waitForPlayersInGameServer()
        local Players = game:GetService("Players")
        local startTime = os.time()
        local timeout = Config.Matchmaking.WaitForPlayersTimeout or 60
        local minPlayers = Config.Matchmaking.MinPlayers
        local maxPlayers = Config.Matchmaking.MaxPlayers
        
        logger:info("Waiting for players to join game server...")
        
        while true do
                local playerCount = #Players:GetPlayers()
                local elapsed = os.time() - startTime
                
                -- Check if we have enough players to start
                if playerCount >= minPlayers then
                        local countdown = 10
                        
                        -- Give time for more players to join
                        while countdown > 0 do
                                playerCount = #Players:GetPlayers()
                                
                                if playerCount >= maxPlayers then
                                        logger:info("Max players reached, starting match!")
                                        return true
                                end
                                
                                self.messagingService:broadcastToAll(
                                        string.format("Starting in %d seconds... (%d/%d players)", 
                                        countdown, playerCount, maxPlayers)
                                )
                                
                                task.wait(1)
                                countdown = countdown - 1
                        end
                        
                        -- Start the match
                        logger:info(string.format("Starting match with %d players", playerCount))
                        return true
                end
                
                -- Check timeout
                if elapsed >= timeout then
                        logger:warn("Timed out waiting for players")
                        
                        if playerCount >= 2 then
                                logger:info("Starting anyway with minimum players")
                                return true
                        else
                                logger:error("Not enough players, cannot start match")
                                return false
                        end
                end
                
                -- Update waiting message
                self.messagingService:broadcastToAll(
                        string.format("Waiting for players... (%d/%d)", playerCount, minPlayers)
                )
                
                task.wait(1)
        end
end

return MatchService
