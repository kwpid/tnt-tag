--[[
	QueueServer.lua
	Server-side handler for queue remote events
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServiceRegistry = require(script.Parent.Shared.ServiceRegistry)
local Logger = require(script.Parent.Shared.Logger)

local logger = Logger.new("QueueServer")

-- Wait for services to be registered
task.wait(1)

local queueService = ServiceRegistry:get("QueueService")
if not queueService then
	logger:error("QueueService not found in registry!")
	return
end

-- Get or create RemoteEvents folder
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
	remoteEventsFolder = Instance.new("Folder")
	remoteEventsFolder.Name = "RemoteEvents"
	remoteEventsFolder.Parent = ReplicatedStorage
end

-- Create QueueEvent remote
local queueRemote = remoteEventsFolder:FindFirstChild("QueueEvent")
if not queueRemote then
	queueRemote = Instance.new("RemoteEvent")
	queueRemote.Name = "QueueEvent"
	queueRemote.Parent = remoteEventsFolder
end

-- Handle queue requests from clients
queueRemote.OnServerEvent:Connect(function(player, shouldQueue)
	if shouldQueue then
		local success = queueService:addToQueue(player)
		
		if success then
			queueRemote:FireClient(player, true, "You've joined the queue!")
			logger:info(player.Name .. " joined the queue")
		else
			queueRemote:FireClient(player, false, "Failed to join queue - you may already be in queue")
		end
	else
		local success = queueService:removeFromQueue(player)
		
		if success then
			queueRemote:FireClient(player, false, "You've left the queue")
			logger:info(player.Name .. " left the queue")
		else
			queueRemote:FireClient(player, false, "Failed to leave queue")
		end
	end
end)

-- Cleanup when players leave
Players.PlayerRemoving:Connect(function(player)
	queueService:removeFromQueue(player)
end)

logger:info("Queue Server initialized")
