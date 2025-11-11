--[[
	QueueService.lua
	Manages player queue state for matchmaking
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(script.Parent.Parent.Shared.Logger)
local Config = require(game.ServerStorage.Config.GameConfig)

local QueueService = {}
QueueService.__index = QueueService

local logger = Logger.new("QueueService")

function QueueService.new()
	local self = setmetatable({}, QueueService)
	
	self.queuedPlayers = {}
	
	logger:info("QueueService initialized")
	return self
end

function QueueService:addToQueue(player)
	if self:isInQueue(player) then
		logger:warn("Player already in queue: " .. player.Name)
		return false
	end
	
	self.queuedPlayers[player.UserId] = {
		player = player,
		queuedAt = os.time(),
	}
	
	player:SetAttribute("InQueue", true)
	logger:info("Added player to queue: " .. player.Name)
	return true
end

function QueueService:removeFromQueue(player)
	if not self:isInQueue(player) then
		return false
	end
	
	self.queuedPlayers[player.UserId] = nil
	player:SetAttribute("InQueue", false)
	logger:info("Removed player from queue: " .. player.Name)
	return true
end

function QueueService:isInQueue(player)
	return self.queuedPlayers[player.UserId] ~= nil
end

function QueueService:getQueuedPlayers()
	local players = {}
	for _, data in pairs(self.queuedPlayers) do
		if data.player and data.player.Parent == Players then
			table.insert(players, data.player)
		end
	end
	return players
end

function QueueService:getQueueSize()
	return #self:getQueuedPlayers()
end

function QueueService:clearQueue()
	for _, data in pairs(self.queuedPlayers) do
		if data.player then
			data.player:SetAttribute("InQueue", false)
		end
	end
	self.queuedPlayers = {}
	logger:info("Queue cleared")
end

function QueueService:cleanupPlayer(player)
	self:removeFromQueue(player)
end

return QueueService
