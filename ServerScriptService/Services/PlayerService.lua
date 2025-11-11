--[[
	PlayerService.lua
	Handles player management, initialization, and teleportation
]]

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Logger = require(script.Parent.Parent.Shared.Logger)
local Config = require(game.ServerStorage.Config.GameConfig)

local PlayerService = {}
PlayerService.__index = PlayerService

local logger = Logger.new("PlayerService")

function PlayerService.new(leaderboardService)
	local self = setmetatable({}, PlayerService)
	self.leaderboardService = leaderboardService
	self.lobbyTeam = Teams:FindFirstChild(Config.Teams.LobbyTeam)
	self.gameTeam = Teams:FindFirstChild(Config.Teams.GameTeam)
	
	if not self.lobbyTeam then
		logger:error("Lobby team not found: " .. Config.Teams.LobbyTeam)
	end
	if not self.gameTeam then
		logger:error("Game team not found: " .. Config.Teams.GameTeam)
	end
	
	return self
end

function PlayerService:initializePlayer(player)
	logger:info("Initializing player: " .. player.Name)
	
	-- Set default attributes
	player:SetAttribute("HasTNT", false)
	player:SetAttribute("CanHit", false)
	player:SetAttribute("EquippedTNT", Config.TNT.DefaultTNT)
	player:SetAttribute("AFK", false)
	
	-- Assign to lobby team
	player.Team = self.lobbyTeam
	
	-- Load and create leaderboard data
	local data = self.leaderboardService:loadPlayerData(player)
	self.leaderboardService:createLeaderstats(player)
	
	logger:info("Player initialized: " .. player.Name)
end

function PlayerService:cleanupPlayer(player)
	logger:info("Cleaning up player: " .. player.Name)
	self.leaderboardService:playerLeaving(player)
end

function PlayerService:clearGameAttributes(player)
	-- Clear game-specific attributes but keep persistent ones
	local preservedAttributes = {
		"AFK",
		"EquippedTNT",
		"Leaderboard_Wins",
		"Leaderboard_Streak",
	}
	
	for attrName, _ in pairs(player:GetAttributes()) do
		local shouldPreserve = false
		for _, preserved in ipairs(preservedAttributes) do
			if attrName == preserved then
				shouldPreserve = true
				break
			end
		end
		
		if not shouldPreserve then
			player:SetAttribute(attrName, nil)
		end
	end
end

function PlayerService:getTeamPlayers(team)
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team == team then
			table.insert(result, player)
		end
	end
	return result
end

function PlayerService:getActiveTeamPlayers(team)
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team == team and not player:GetAttribute("AFK") then
			table.insert(result, player)
		end
	end
	return result
end

function PlayerService:teleportPlayerToLobby(player)
	local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then
		logger:warn("No spawn location found in workspace")
		return false
	end
	
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		logger:warn("Cannot teleport player without character: " .. player.Name)
		return false
	end
	
	local hrp = char.HumanoidRootPart
	hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
	
	-- Reset player health and states
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
		humanoid.PlatformStand = false
		humanoid.Sit = false
	end
	
	-- Clear velocity
	local bodyVelocity = hrp:FindFirstChild("BodyVelocity")
	if bodyVelocity then
		bodyVelocity:Destroy()
	end
	
	player:SetAttribute("CanHit", false)
	
	logger:debug("Teleported player to lobby: " .. player.Name)
	return true
end

function PlayerService:teleportTeamToLobby(team)
	local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then
		logger:error("No spawn location found")
		return
	end
	
	for _, player in pairs(self:getTeamPlayers(team)) do
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			player:LoadCharacter()
			task.wait(0.5)
		end
		
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
		end
	end
end

function PlayerService:teleportTeamToMap(team, mapSpawn)
	if not mapSpawn then
		logger:error("No map spawn provided")
		return
	end
	
	for _, player in pairs(self:getTeamPlayers(team)) do
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			player:LoadCharacter()
			task.wait(0.5)
		end
		
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = mapSpawn.CFrame + Vector3.new(0, 3, 0)
			
			player:SetAttribute("CanHit", false)
			
			-- Enable hitting after short delay
			task.delay(1, function()
				if player and player.Team == team then
					player:SetAttribute("CanHit", true)
				end
			end)
		end
	end
end

function PlayerService:movePlayersToGame()
	local activePlayers = self:getActiveTeamPlayers(self.lobbyTeam)
	
	for _, player in pairs(activePlayers) do
		player.Team = self.gameTeam
	end
	
	-- Move AFK players back to lobby
	for _, player in pairs(Players:GetPlayers()) do
		if player:GetAttribute("AFK") then
			player.Team = self.lobbyTeam
		end
	end
	
	logger:info("Moved " .. #activePlayers .. " players to game")
	return #activePlayers
end

function PlayerService:moveAllToLobby()
	for _, player in pairs(Players:GetPlayers()) do
		player.Team = self.lobbyTeam
		player:SetAttribute("HasTNT", false)
		player:SetAttribute("CanHit", false)
	end
	logger:info("Moved all players to lobby")
end

function PlayerService:getLobbyTeam()
	return self.lobbyTeam
end

function PlayerService:getGameTeam()
	return self.gameTeam
end

return PlayerService
