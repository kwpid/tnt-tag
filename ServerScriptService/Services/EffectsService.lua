--[[
	EffectsService.lua
	Handles visual and audio effects for the game
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Logger = require(script.Parent.Parent.Shared.Logger)
local Config = require(game.ServerStorage.Config.GameConfig)

local EffectsService = {}
EffectsService.__index = EffectsService

local logger = Logger.new("EffectsService")

function EffectsService.new()
	local self = setmetatable({}, EffectsService)
	return self
end

function EffectsService:createExplosionEffect(player)
	local char = player.Character
	if not char then
		return false
	end
	
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	
	-- Create visual explosion (no damage)
	local explosion = Instance.new("Explosion")
	explosion.Position = hrp.Position
	explosion.BlastRadius = 10
	explosion.BlastPressure = 0 -- No knockback/damage
	explosion.Visible = true
	explosion.Parent = Workspace
	
	Debris:AddItem(explosion, 3)
	
	logger:debug("Created explosion effect for " .. player.Name)
	return true
end

function EffectsService:applyKnockback(attacker, target)
	if not attacker.Character or not target.Character then
		return false
	end
	
	local rootA = attacker.Character:FindFirstChild("HumanoidRootPart")
	local rootT = target.Character:FindFirstChild("HumanoidRootPart")
	
	if not (rootA and rootT) then
		return false
	end
	
	local direction = (rootT.Position - rootA.Position).Unit
	direction = Vector3.new(direction.X, 0, direction.Z).Unit
	
	local knockbackForce = direction * Config.PvP.Knockback.Horizontal + 
		Vector3.new(0, Config.PvP.Knockback.Vertical, 0)
	
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "MinecraftKnockback"
	bodyVelocity.Velocity = knockbackForce
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.P = 8000
	bodyVelocity.Parent = rootT
	
	Debris:AddItem(bodyVelocity, Config.PvP.Knockback.Duration)
	
	return true
end

function EffectsService:flashRedGlow(player)
	local char = player.Character
	if not char then
		return false
	end
	
	-- Remove existing glow
	local existing = char:FindFirstChild("PvPGlow")
	if existing then
		existing:Destroy()
	end
	
	-- Create new glow
	local highlight = Instance.new("Highlight")
	highlight.Name = "PvPGlow"
	highlight.Adornee = char
	highlight.FillColor = Color3.new(1, 0, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 1
	highlight.Parent = char
	
	Debris:AddItem(highlight, Config.PvP.GlowDuration)
	
	return true
end

function EffectsService:playSwingAnimation(player)
	local char = player.Character
	if not char then
		return false
	end
	
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	
	local animFolder = ReplicatedStorage:FindFirstChild("Animations")
	if not animFolder then
		logger:warn("Animations folder not found in ReplicatedStorage")
		return false
	end
	
	local animObj = animFolder:FindFirstChild("ArmSwing")
	if not animObj then
		logger:warn("ArmSwing animation not found")
		return false
	end
	
	local track = humanoid:LoadAnimation(animObj)
	track:Play()
	
	return true
end

function EffectsService:playHitSound(player)
	local char = player.Character
	if not char then
		return false
	end
	
	local soundFolder = ReplicatedStorage:FindFirstChild("Sounds")
	if not soundFolder then
		logger:warn("Sounds folder not found in ReplicatedStorage")
		return false
	end
	
	local soundTemplate = soundFolder:FindFirstChild("HitSound")
	if not soundTemplate then
		logger:warn("HitSound not found")
		return false
	end
	
	local sound = soundTemplate:Clone()
	sound.Name = "HitSFX"
	sound.Parent = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	sound.TimePosition = 0.34
	sound:Play()
	
	Debris:AddItem(sound, 2)
	
	return true
end

function EffectsService:playHitFeedback(attacker, target)
	self:applyKnockback(attacker, target)
	self:flashRedGlow(target)
	self:playHitSound(target)
	self:playSwingAnimation(attacker)
end

return EffectsService
