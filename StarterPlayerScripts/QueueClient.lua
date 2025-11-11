--[[
	QueueClient.lua
	Client-side queue management for matchmaking
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents folder and queue remote
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEventsFolder then
	warn("RemoteEvents folder not found!")
	return
end

local queueRemote = remoteEventsFolder:WaitForChild("QueueEvent", 10)
if not queueRemote then
	warn("QueueEvent remote not found!")
	return
end

-- Wait for QueueGUI
local queueGUI = playerGui:WaitForChild("QueueGUI", 10)
if not queueGUI then
	warn("QueueGUI not found in PlayerGui! Please create a ScreenGui named 'QueueGUI' with a button named 'Button'")
	return
end

local queueButton = queueGUI:WaitForChild("Button", 10)
if not queueButton then
	warn("Button not found in QueueGUI!")
	return
end

local inQueue = false

-- Update button appearance based on queue state
local function updateButton()
	if inQueue then
		queueButton.Text = "Leave Queue"
		queueButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	else
		queueButton.Text = "Join Queue"
		queueButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	end
end

-- Handle button click
queueButton.MouseButton1Click:Connect(function()
	inQueue = not inQueue
	updateButton()
	
	-- Send queue request to server
	queueRemote:FireServer(inQueue)
end)

-- Listen for queue state updates from server
queueRemote.OnClientEvent:Connect(function(isInQueue, message)
	inQueue = isInQueue
	updateButton()
	
	if message then
		-- Display message to player (you can enhance this with a proper notification system)
		print(message)
	end
end)

-- Initialize button
updateButton()

print("Queue Client initialized")
