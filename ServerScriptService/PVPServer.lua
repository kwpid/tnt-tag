local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local PvPEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PvPEvent")
local TNT_FOLDER = ServerStorage:WaitForChild("TNT")

local debounceTable = {}

local function getDistance(p1, p2)
	return (p1.Position - p2.Position).Magnitude
end

local function isEligible(player, target)
	if not player.Character or not target.Character then return false end
	if not player.Character:FindFirstChild("HumanoidRootPart") then return false end
	if not target.Character:FindFirstChild("HumanoidRootPart") then return false end
	if player == target then return false end

	if not player.Team or not target.Team then return false end
	if player.Team.Name ~= "Game" or target.Team.Name ~= "Game" then return false end

	local distance = getDistance(player.Character.HumanoidRootPart, target.Character.HumanoidRootPart)
	if distance > 16 then return false end

	return true
end

local function applyKnockback(attacker, target)
	local rootA = attacker.Character:FindFirstChild("HumanoidRootPart")
	local rootT = target.Character:FindFirstChild("HumanoidRootPart")
	if not (rootA and rootT) then return end

	local direction = (rootT.Position - rootA.Position).Unit
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	local knockbackForce = direction * 35 + Vector3.new(0, 8, 0)

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "MinecraftKnockback"
	bodyVelocity.Velocity = knockbackForce
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.P = 8000
	bodyVelocity.Parent = rootT

	Debris:AddItem(bodyVelocity, 0.15)
end

local function flashRedGlow(player)
	local char = player.Character
	if not char then return end

	local existing = char:FindFirstChild("PvPGlow")
	if existing then existing:Destroy() end

	local highlight = Instance.new("Highlight")
	highlight.Name = "PvPGlow"
	highlight.Adornee = char
	highlight.FillColor = Color3.new(1, 0, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 1
	highlight.Parent = char

	Debris:AddItem(highlight, 0.15)
end

local function playSwingAnimation(player)
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animFolder = ReplicatedStorage:FindFirstChild("Animations")
	local animObj = animFolder and animFolder:FindFirstChild("ArmSwing")
	if not animObj then return end

	local track = humanoid:LoadAnimation(animObj)
	track:Play()
end

local function playHitSound(targetPlayer)
	local char = targetPlayer.Character
	if not char then return end

	local soundFolder = ReplicatedStorage:FindFirstChild("Sounds")
	local soundTemplate = soundFolder and soundFolder:FindFirstChild("HitSound")
	if not soundTemplate then return end
	local sound = soundTemplate:Clone()
	sound.Name = "HitSFX"
	sound.Parent = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	sound.TimePosition = 0.34
	sound:Play()
	Debris:AddItem(sound, 2)
end

local function getEquippedTNT(player)
	local equippedTNT = player:GetAttribute("EquippedTNT")
	if not equippedTNT or equippedTNT == "" then
		return "TNT" 
	end
	return equippedTNT
end

local function attachTNT(player)
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	for _, acc in pairs(char:GetChildren()) do
		if acc:IsA("Accessory") and acc.Name:find("TNT_") then
			acc:Destroy()
		end
	end

	local equippedTNTName = getEquippedTNT(player)
	local tntTemplate = TNT_FOLDER:FindFirstChild(equippedTNTName)

	if tntTemplate and tntTemplate:IsA("Accessory") then
		local tntClone = tntTemplate:Clone()
		tntClone.Name = "TNT_" .. equippedTNTName 
		tntClone.Parent = char
		print("Attached " .. equippedTNTName .. " to " .. player.Name .. " via PvP")
	else
		local defaultTNT = TNT_FOLDER:FindFirstChild("TNT")
		if defaultTNT and defaultTNT:IsA("Accessory") then
			local tntClone = defaultTNT:Clone()
			tntClone.Name = "TNT"
			tntClone.Parent = char
			print("Attached default TNT to " .. player.Name .. " via PvP (equipped TNT not found)")
		end
	end
end

local function removeTNT(player)
	local char = player.Character
	if not char then return end

	for _, acc in pairs(char:GetChildren()) do
		if acc:IsA("Accessory") and acc.Name:find("TNT_") then
			acc:Destroy()
		end
	end
end

local function tryTransferTNT(attacker, target)
	if not attacker:GetAttribute("HasTNT") then return end
	if target:GetAttribute("HasTNT") then return end

	attacker:SetAttribute("HasTNT", false)
	target:SetAttribute("HasTNT", true)

	removeTNT(attacker)
	attachTNT(target)
end

PvPEvent.OnServerEvent:Connect(function(player, target)
	if not target or not target:IsA("Player") then return end
	if not isEligible(player, target) then return end

	if not player:GetAttribute("CanHit") or not target:GetAttribute("CanHit") then return end

	if debounceTable[player] and tick() - debounceTable[player] < 0.01 then return end
	debounceTable[player] = tick()

	local humanoid = target.Character and target.Character:FindFirstChild("Humanoid")
	if humanoid then
		applyKnockback(player, target)
		flashRedGlow(target)
		playHitSound(target)
		playSwingAnimation(player)
		tryTransferTNT(player, target)
	end
end)
