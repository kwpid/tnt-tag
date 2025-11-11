--[[
        PVPServer.lua
        Refactored PvP hit handler using service architecture
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Logger = require(script.Parent.Shared.Logger)
local ServiceRegistry = require(script.Parent.Shared.ServiceRegistry)
local Config = require(game.ServerStorage.Config.GameConfig)

local PvPEvent = ReplicatedStorage:WaitForChild(Config.Remotes.RemotesFolder):WaitForChild(Config.Remotes.PvPEvent)

local logger = Logger.new("PVPServer")
local debounceTable = {}

-- Wait for services to be registered by Main.server.lua
local tntService, effectsService
task.spawn(function()
        -- Wait for services to be available
        local maxWait = 10
        local waited = 0
        while waited < maxWait do
                tntService = ServiceRegistry:get("TNTService")
                effectsService = ServiceRegistry:get("EffectsService")
                
                if tntService and effectsService then
                        logger:info("Services loaded from registry")
                        break
                end
                
                task.wait(0.1)
                waited = waited + 0.1
        end
        
        if not tntService or not effectsService then
                logger:error("Failed to load services from registry, creating fallback instances")
                local TNTService = require(script.Parent.Services.TNTService)
                local EffectsService = require(script.Parent.Services.EffectsService)
                tntService = TNTService.new()
                effectsService = EffectsService.new()
        end
end)

local function getDistance(p1, p2)
        return (p1.Position - p2.Position).Magnitude
end

local function isEligible(player, target)
        if not player.Character or not target.Character then
                return false
        end
        if not player.Character:FindFirstChild("HumanoidRootPart") then
                return false
        end
        if not target.Character:FindFirstChild("HumanoidRootPart") then
                return false
        end
        if player == target then
                return false
        end
        
        if not player.Team or not target.Team then
                return false
        end
        if player.Team.Name ~= Config.Teams.GameTeam or target.Team.Name ~= Config.Teams.GameTeam then
                return false
        end
        
        local distance = getDistance(
                player.Character.HumanoidRootPart,
                target.Character.HumanoidRootPart
        )
        
        if distance > Config.PvP.MaxHitRange then
                return false
        end
        
        return true
end

PvPEvent.OnServerEvent:Connect(function(player, target)
        if not target or not target:IsA("Player") then
                return
        end
        
        -- Wait for services to be loaded
        if not tntService or not effectsService then
                logger:warn("Services not yet loaded, ignoring hit")
                return
        end
        
        if not isEligible(player, target) then
                return
        end
        
        if not player:GetAttribute("CanHit") or not target:GetAttribute("CanHit") then
                return
        end
        
        -- Debounce check
        if debounceTable[player] and tick() - debounceTable[player] < Config.PvP.HitCooldown then
                return
        end
        debounceTable[player] = tick()
        
        local humanoid = target.Character and target.Character:FindFirstChild("Humanoid")
        if humanoid then
                -- Play hit effects
                effectsService:playHitFeedback(player, target)
                
                -- Try to transfer TNT
                tntService:transferTNT(player, target)
                
                logger:debug(player.Name .. " hit " .. target.Name)
        end
end)

logger:info("PvP Server initialized")
