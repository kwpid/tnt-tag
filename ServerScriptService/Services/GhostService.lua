--[[
        GhostService.lua
        Manages ghost spectator mode for eliminated players
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(script.Parent.Parent.Shared.Logger)
local Config = require(game.ServerStorage.Config.GameConfig)

local GhostService = {}
GhostService.__index = GhostService

local logger = Logger.new("GhostService")

function GhostService.new()
        local self = setmetatable({}, GhostService)
        
        self.ghosts = {}
        self.ghostStates = {} -- Store original part states
        
        -- Get remote events
        local remotesFolder = ReplicatedStorage:WaitForChild(Config.Remotes.RemotesFolder)
        self.showBackToLobbyEvent = remotesFolder:WaitForChild(Config.Remotes.ShowBackToLobbyEvent)
        self.hideBackToLobbyEvent = remotesFolder:WaitForChild(Config.Remotes.HideBackToLobbyEvent)
        
        logger:info("GhostService initialized")
        return self
end

function GhostService:makeGhost(player)
        if self:isGhost(player) then
                logger:warn("Player already a ghost: " .. player.Name)
                return false
        end
        
        local character = player.Character
        if not character then
                logger:warn("Cannot make ghost - no character: " .. player.Name)
                return false
        end
        
        -- Mark player as ghost
        player:SetAttribute("IsGhost", true)
        self.ghosts[player.UserId] = true
        
        -- Store original part states before modifying
        local originalStates = {}
        for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                        originalStates[part] = {
                                Transparency = part.Transparency,
                                CanCollide = part.CanCollide,
                                CanTouch = part.CanTouch,
                        }
                        
                        -- Apply ghost properties
                        part.Transparency = Config.Ghost.Transparency or 0.5
                        part.CanCollide = false
                        part.CanTouch = false
                elseif part:IsA("Decal") or part:IsA("Texture") then
                        originalStates[part] = {
                                Transparency = part.Transparency,
                        }
                        
                        -- Apply ghost properties
                        part.Transparency = Config.Ghost.Transparency or 0.5
                end
        end
        
        -- Store original humanoid state
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
                originalStates.HumanoidPlatformStand = humanoid.PlatformStand
        end
        
        self.ghostStates[player.UserId] = originalStates
        
        -- Disable character collision
        if humanoid then
                humanoid.PlatformStand = true
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
        
        -- Enable flying
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.Name = "GhostVelocity"
                bodyVelocity.Parent = rootPart
                
                local bodyGyro = Instance.new("BodyGyro")
                bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
                bodyGyro.P = 10000
                bodyGyro.Name = "GhostGyro"
                bodyGyro.Parent = rootPart
        end
        
        logger:info("Player converted to ghost: " .. player.Name)
        
        -- Show BACK TO LOBBY button for this player
        if self.showBackToLobbyEvent then
                self.showBackToLobbyEvent:FireClient(player, false, nil)
        end
        
        return true
end

function GhostService:removeGhost(player)
        if not self:isGhost(player) then
                return false
        end
        
        player:SetAttribute("IsGhost", false)
        self.ghosts[player.UserId] = nil
        
        -- Get stored original states
        local originalStates = self.ghostStates[player.UserId]
        
        -- Fully restore character
        if player.Character then
                local character = player.Character
                
                -- Remove ghost components
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                        local ghostVelocity = rootPart:FindFirstChild("GhostVelocity")
                        if ghostVelocity then
                                ghostVelocity:Destroy()
                        end
                        
                        local ghostGyro = rootPart:FindFirstChild("GhostGyro")
                        if ghostGyro then
                                ghostGyro:Destroy()
                        end
                end
                
                -- Restore parts to their original states
                if originalStates then
                        for part, state in pairs(originalStates) do
                                if typeof(part) == "Instance" and part.Parent then
                                        if part:IsA("BasePart") or part:IsA("MeshPart") then
                                                part.Transparency = state.Transparency
                                                part.CanCollide = state.CanCollide
                                                part.CanTouch = state.CanTouch
                                        elseif part:IsA("Decal") or part:IsA("Texture") then
                                                part.Transparency = state.Transparency
                                        end
                                end
                        end
                        
                        -- Restore humanoid state
                        local humanoid = character:FindFirstChild("Humanoid")
                        if humanoid and originalStates.HumanoidPlatformStand ~= nil then
                                humanoid.PlatformStand = originalStates.HumanoidPlatformStand
                                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                else
                        -- Fallback: use sensible defaults if no state was stored
                        logger:warn("No original state found for player, using defaults: " .. player.Name)
                        
                        for _, part in ipairs(character:GetDescendants()) do
                                if part:IsA("BasePart") or part:IsA("MeshPart") then
                                        part.Transparency = 0
                                        part.CanCollide = true
                                        part.CanTouch = true
                                elseif part:IsA("Decal") or part:IsA("Texture") then
                                        part.Transparency = 0
                                end
                        end
                        
                        local humanoid = character:FindFirstChild("Humanoid")
                        if humanoid then
                                humanoid.PlatformStand = false
                                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                end
        end
        
        -- Clear stored state
        self.ghostStates[player.UserId] = nil
        
        -- Hide BACK TO LOBBY button for this player
        if self.hideBackToLobbyEvent then
                self.hideBackToLobbyEvent:FireClient(player)
        end
        
        logger:info("Removed ghost mode from player: " .. player.Name)
        return true
end

function GhostService:isGhost(player)
        return self.ghosts[player.UserId] == true
end

function GhostService:hideGhostsFromEachOther()
        -- This runs on a loop to ensure ghosts can't see each other
        for userId, _ in pairs(self.ghosts) do
                local player = Players:GetPlayerByUserId(userId)
                
                if player and player.Character then
                        for otherUserId, _ in pairs(self.ghosts) do
                                if userId ~= otherUserId then
                                        local otherPlayer = Players:GetPlayerByUserId(otherUserId)
                                        
                                        if otherPlayer and otherPlayer.Character then
                                                -- Make other ghost invisible to this ghost
                                                for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
                                                        if part:IsA("BasePart") or part:IsA("MeshPart") then
                                                                -- Set LocalTransparencyModifier for client-side invisibility
                                                                -- This would need to be done via a client script
                                                        end
                                                end
                                        end
                                end
                        end
                end
        end
end

function GhostService:cleanupPlayer(player)
        self:removeGhost(player)
        
        -- Clean up any stale state entries
        if self.ghostStates[player.UserId] then
                self.ghostStates[player.UserId] = nil
        end
end

function GhostService:cleanupAllGhosts()
        -- Remove ghost mode from all players
        for userId, _ in pairs(self.ghosts) do
                local player = Players:GetPlayerByUserId(userId)
                if player then
                        self:removeGhost(player)
                else
                        -- Clean up stale entries for disconnected players
                        self.ghosts[userId] = nil
                        self.ghostStates[userId] = nil
                end
        end
        logger:info("Cleaned up all ghosts")
end

return GhostService
