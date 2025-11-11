local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PvPEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PvPEvent")

-- Slightly increased range
local reach = 16

local function getTargetPlayer()
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then return nil end

	local mouse = player:GetMouse()
	local mouseHit = mouse.Hit.Position
	local origin = head.Position
	local direction = (mouseHit - origin).Unit * reach

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {player.Character}
	rayParams.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, rayParams)

	if result then
		local hitPart = result.Instance
		local hitCharacter = hitPart:FindFirstAncestorOfClass("Model")
		local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)

		if hitPlayer and hitPlayer ~= player then
			local targetHRP = hitPlayer.Character and hitPlayer.Character:FindFirstChild("HumanoidRootPart")
			if targetHRP then
				local obstructionParams = RaycastParams.new()
				obstructionParams.FilterType = Enum.RaycastFilterType.Blacklist
				obstructionParams.FilterDescendantsInstances = {player.Character, hitPlayer.Character}
				obstructionParams.IgnoreWater = true

				local toTarget = targetHRP.Position - origin
				local obstruction = workspace:Raycast(origin, toTarget, obstructionParams)

				if not obstruction or not obstruction.Instance.CanCollide then
					return hitPlayer
				end
			end
		end
	end

	-- More forgiving check using Region3 and angle dot
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = otherPlayer.Character.HumanoidRootPart
			local dist = (hrp.Position - origin).Magnitude

			if dist <= reach + 1.5 then -- slightly larger radius
				local directionToPlayer = (hrp.Position - origin).Unit
				local aimDirection = (mouseHit - origin).Unit
				local dot = directionToPlayer:Dot(aimDirection)

				if dot >= 0.75 then -- more angle forgiveness
					local obstructionParams = RaycastParams.new()
					obstructionParams.FilterType = Enum.RaycastFilterType.Blacklist
					obstructionParams.FilterDescendantsInstances = {player.Character, otherPlayer.Character}
					obstructionParams.IgnoreWater = true

					local toTarget = hrp.Position - origin
					local obstruction = workspace:Raycast(origin, toTarget, obstructionParams)

					if not obstruction or not obstruction.Instance.CanCollide then
						return otherPlayer
					end
				end
			end
		end
	end

	return nil
end

local function onInput()
	local target = getTargetPlayer()
	if target then
		PvPEvent:FireServer(target)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.Gamepad1 then
		onInput()
	end
end)
