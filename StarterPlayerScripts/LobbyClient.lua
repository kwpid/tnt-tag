--[[
	LobbyClient.lua
	Handles "BACK TO LOBBY" button UI and click events
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for config
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

-- Get remote events
local remotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local lobbyTeleportEvent = remotesFolder:WaitForChild("LobbyTeleportEvent")
local showBackToLobbyEvent = remotesFolder:WaitForChild("ShowBackToLobbyEvent")
local hideBackToLobbyEvent = remotesFolder:WaitForChild("HideBackToLobbyEvent")

-- Wait for GUI
local backToLobbyGui = playerGui:WaitForChild("BackToLobbyGUI")
local button = backToLobbyGui:WaitForChild("Button")
local timerLabel = backToLobbyGui:WaitForChild("Timer")

-- Hide by default
backToLobbyGui.Enabled = false

-- Handle button click
button.MouseButton1Click:Connect(function()
	lobbyTeleportEvent:FireServer()
	button.Text = "Teleporting..."
	button.Active = false
end)

-- Show button event
showBackToLobbyEvent.OnClientEvent:Connect(function(showTimer, countdown)
	backToLobbyGui.Enabled = true
	button.Active = true
	button.Text = "BACK TO LOBBY"
	
	if showTimer and countdown then
		-- Show countdown timer
		timerLabel.Visible = true
		timerLabel.Text = string.format("Auto-teleport in %ds", countdown)
		
		-- Update countdown
		task.spawn(function()
			for i = countdown, 1, -1 do
				if not backToLobbyGui.Enabled then break end
				timerLabel.Text = string.format("Auto-teleport in %ds", i)
				task.wait(1)
			end
			timerLabel.Text = "Teleporting..."
		end)
	else
		timerLabel.Visible = false
	end
end)

-- Hide button event
hideBackToLobbyEvent.OnClientEvent:Connect(function()
	backToLobbyGui.Enabled = false
	timerLabel.Visible = false
end)

print("LobbyClient initialized")
