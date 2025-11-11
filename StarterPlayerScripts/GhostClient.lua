--[[
	GhostClient.lua
	Client-side ghost mode handling - makes other ghosts invisible and enables flying controls
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local flySpeed = 50
local moveDirection = Vector3.new(0, 0, 0)

-- Hide other ghosts from this player
local function hideGhosts()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer:GetAttribute("IsGhost") then
			if otherPlayer.Character then
				for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") or part:IsA("MeshPart") then
						part.LocalTransparencyModifier = 1
					elseif part:IsA("Decal") or part:IsA("Texture") then
						part.Transparency = 1
					end
				end
			end
		end
	end
end

-- Make alive players visible if we're a ghost
local function updateVisibility()
	if not player:GetAttribute("IsGhost") then
		return
	end
	
	hideGhosts()
	
	-- Make sure alive players are visible
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and not otherPlayer:GetAttribute("IsGhost") then
			if otherPlayer.Character then
				for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") or part:IsA("MeshPart") then
						part.LocalTransparencyModifier = 0
					end
				end
			end
		end
	end
end

-- Handle flying controls for ghosts
local function handleFlying()
	if not player:GetAttribute("IsGhost") then
		flying = false
		return
	end
	
	local character = player.Character
	if not character then
		return
	end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end
	
	local bodyVelocity = rootPart:FindFirstChild("GhostVelocity")
	if not bodyVelocity then
		return
	end
	
	local bodyGyro = rootPart:FindFirstChild("GhostGyro")
	if not bodyGyro then
		return
	end
	
	-- Enable flying
	flying = true
	bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
	
	-- Calculate movement direction
	local cameraCFrame = camera.CFrame
	local forward = cameraCFrame.LookVector
	local right = cameraCFrame.RightVector
	
	local direction = Vector3.new(0, 0, 0)
	
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		direction = direction + forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		direction = direction - forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		direction = direction - right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		direction = direction + right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		direction = direction + Vector3.new(0, 1, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		direction = direction - Vector3.new(0, 1, 0)
	end
	
	if direction.Magnitude > 0 then
		direction = direction.Unit
	end
	
	bodyVelocity.Velocity = direction * flySpeed
	bodyGyro.CFrame = cameraCFrame
end

-- Run visibility and flying updates
RunService.RenderStepped:Connect(function()
	updateVisibility()
	handleFlying()
end)

-- Update when character respawns
player.CharacterAdded:Connect(function()
	task.wait(0.5)
	updateVisibility()
end)

-- Update when other players spawn
Players.PlayerAdded:Connect(function(otherPlayer)
	otherPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		updateVisibility()
	end)
end)

print("Ghost Client initialized")
