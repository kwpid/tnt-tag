--[[
	LobbyServer.lua
	Handles teleporting players back to the main lobby place
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local Logger = require(script.Parent.Shared.Logger)
local ServiceRegistry = require(script.Parent.Shared.ServiceRegistry)
local Config = require(game.ServerStorage.Config.GameConfig)

local logger = Logger.new("LobbyServer")

-- Throttle table to prevent spam
local teleportThrottle = {}
local THROTTLE_TIME = 5 -- seconds

-- Wait for remote events folder
local remotesFolder = ReplicatedStorage:WaitForChild(Config.Remotes.RemotesFolder)
local lobbyTeleportEvent = remotesFolder:WaitForChild(Config.Remotes.LobbyTeleportEvent)

-- Handle teleport requests
lobbyTeleportEvent.OnServerEvent:Connect(function(player)
	-- Throttle check
	if teleportThrottle[player.UserId] and tick() - teleportThrottle[player.UserId] < THROTTLE_TIME then
		logger:warn("Teleport throttled for: " .. player.Name)
		return
	end
	teleportThrottle[player.UserId] = tick()
	
	-- Check if MainLobbyPlaceId is configured
	if not Config.Matchmaking.MainLobbyPlaceId then
		logger:error("MainLobbyPlaceId not configured in GameConfig!")
		return
	end
	
	logger:info("Teleporting player to main lobby: " .. player.Name)
	
	-- Clean up ghost state
	local ghostService = ServiceRegistry:get("GhostService")
	if ghostService and ghostService:isGhost(player) then
		ghostService:removeGhost(player)
	end
	
	-- Teleport player
	local success, errorMessage = pcall(function()
		TeleportService:TeleportAsync(Config.Matchmaking.MainLobbyPlaceId, {player})
	end)
	
	if not success then
		logger:error("Failed to teleport player: " .. tostring(errorMessage))
	end
end)

logger:info("LobbyServer initialized")
