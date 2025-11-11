--[[
	MessagingService.lua
	Handles all UI messages and announcements to players
]]

local Players = game:GetService("Players")

local Logger = require(script.Parent.Parent.Shared.Logger)
local Config = require(game.ServerStorage.Config.GameConfig)

local MessagingService = {}
MessagingService.__index = MessagingService

local logger = Logger.new("MessagingService")

function MessagingService.new()
	local self = setmetatable({}, MessagingService)
	return self
end

function MessagingService:broadcastToAll(text)
	for _, player in pairs(Players:GetPlayers()) do
		self:sendToPlayer(player, text)
	end
	logger:debug("Broadcast: " .. text)
end

function MessagingService:sendToPlayer(player, text)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return false
	end
	
	local mainGUI = gui:FindFirstChild("MainGUI")
	if not mainGUI then
		return false
	end
	
	local timerText = mainGUI:FindFirstChild("RoundTimer")
	if timerText and timerText:IsA("TextLabel") then
		timerText.Text = text
		return true
	end
	
	return false
end

function MessagingService:broadcastIntermission(seconds)
	local message = string.format(Config.Messages.IntermissionFormat, seconds)
	self:broadcastToAll(message)
end

function MessagingService:broadcastTNTTimer(seconds)
	local message = string.format(Config.Messages.TNTTimerFormat, seconds)
	self:broadcastToAll(message)
end

function MessagingService:broadcastWinner(playerDisplayName)
	local message = string.format(Config.Messages.WinnerFormat, playerDisplayName)
	self:broadcastToAll(message)
end

function MessagingService:broadcastEliminated(playerNames)
	local message = string.format(Config.Messages.EliminatedFormat, table.concat(playerNames, ", "))
	self:broadcastToAll(message)
end

function MessagingService:broadcastWaitingForPlayers()
	self:broadcastToAll(Config.Messages.WaitingForPlayers)
end

function MessagingService:broadcastIntermissionCancelled()
	self:broadcastToAll(Config.Messages.IntermissionCancelled)
end

function MessagingService:broadcastAllHaveTNT()
	self:broadcastToAll(Config.Messages.AllHaveTNT)
end

return MessagingService
