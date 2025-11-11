--[[
	TNTService.lua
	Manages all TNT-related logic: assignment, transfer, accessories
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Logger = require(script.Parent.Parent.Shared.Logger)
local Config = require(game.ServerStorage.Config.GameConfig)

local TNTService = {}
TNTService.__index = TNTService

local logger = Logger.new("TNTService")

function TNTService.new()
	local self = setmetatable({}, TNTService)
	self.tntFolder = ServerStorage:WaitForChild(Config.Storage.TNTFolder)
	
	if not self.tntFolder then
		logger:error("TNT folder not found in ServerStorage")
	end
	
	return self
end

function TNTService:getEquippedTNT(player)
	local equippedTNT = player:GetAttribute("EquippedTNT")
	if not equippedTNT or equippedTNT == "" then
		return Config.TNT.DefaultTNT
	end
	return equippedTNT
end

function TNTService:attachTNTAccessory(player)
	local char = player.Character
	if not char then
		logger:warn("Cannot attach TNT: no character for " .. player.Name)
		return false
	end
	
	local head = char:FindFirstChild("Head")
	if not head then
		logger:warn("Cannot attach TNT: no head for " .. player.Name)
		return false
	end
	
	-- Remove existing TNT accessories
	self:removeTNTAccessory(player)
	
	local equippedTNTName = self:getEquippedTNT(player)
	local tntTemplate = self.tntFolder:FindFirstChild(equippedTNTName)
	
	if tntTemplate and tntTemplate:IsA("Accessory") then
		local tntClone = tntTemplate:Clone()
		tntClone.Name = "TNT_" .. equippedTNTName
		tntClone.Parent = char
		logger:debug("Attached " .. equippedTNTName .. " to " .. player.Name)
		return true
	else
		-- Fallback to default TNT
		local defaultTNT = self.tntFolder:FindFirstChild(Config.TNT.DefaultTNT)
		if defaultTNT and defaultTNT:IsA("Accessory") then
			local tntClone = defaultTNT:Clone()
			tntClone.Name = "TNT_" .. Config.TNT.DefaultTNT
			tntClone.Parent = char
			logger:warn("Attached default TNT to " .. player.Name .. " (equipped TNT not found)")
			return true
		end
	end
	
	logger:error("Failed to attach any TNT to " .. player.Name)
	return false
end

function TNTService:removeTNTAccessory(player)
	local char = player.Character
	if not char then
		return
	end
	
	for _, acc in pairs(char:GetChildren()) do
		if acc:IsA("Accessory") and acc.Name:find("TNT_") then
			acc:Destroy()
		end
	end
end

function TNTService:resetAllTNT()
	for _, player in pairs(Players:GetPlayers()) do
		player:SetAttribute("HasTNT", false)
		self:removeTNTAccessory(player)
	end
	logger:debug("Reset all TNT")
end

function TNTService:assignInitialTNT(teamPlayers)
	if #teamPlayers < 1 then
		logger:warn("Cannot assign TNT: no players provided")
		return
	end
	
	-- Calculate how many players should start with TNT
	local count = Config.TNT.InitialTNTCount.Min
	
	if #teamPlayers >= Config.TNT.InitialTNTCount.ThresholdForMultiple then
		local percentCount = math.floor(#teamPlayers * Config.TNT.InitialTNTCount.MaxPercent)
		count = math.min(Config.TNT.InitialTNTCount.MaxAbsolute, percentCount)
	end
	
	-- Randomly assign TNT
	local chosen = {}
	while #chosen < count and #chosen < #teamPlayers do
		local pick = teamPlayers[math.random(1, #teamPlayers)]
		if not table.find(chosen, pick) then
			pick:SetAttribute("HasTNT", true)
			self:attachTNTAccessory(pick)
			table.insert(chosen, pick)
			logger:debug("Assigned TNT to " .. pick.Name)
		end
	end
	
	logger:info("Assigned TNT to " .. #chosen .. " player(s)")
	return chosen
end

function TNTService:transferTNT(fromPlayer, toPlayer)
	if not fromPlayer:GetAttribute("HasTNT") then
		logger:debug("Transfer failed: " .. fromPlayer.Name .. " doesn't have TNT")
		return false
	end
	
	if toPlayer:GetAttribute("HasTNT") then
		logger:debug("Transfer failed: " .. toPlayer.Name .. " already has TNT")
		return false
	end
	
	-- Transfer
	fromPlayer:SetAttribute("HasTNT", false)
	toPlayer:SetAttribute("HasTNT", true)
	
	self:removeTNTAccessory(fromPlayer)
	self:attachTNTAccessory(toPlayer)
	
	logger:info("Transferred TNT: " .. fromPlayer.Name .. " -> " .. toPlayer.Name)
	return true
end

function TNTService:equipTNTSkin(player, tntName)
	if self.tntFolder:FindFirstChild(tntName) then
		player:SetAttribute("EquippedTNT", tntName)
		logger:info(player.Name .. " equipped " .. tntName)
		
		-- Update accessory if player currently has TNT
		if player:GetAttribute("HasTNT") then
			self:attachTNTAccessory(player)
		end
		
		return true
	else
		logger:warn("TNT skin not found: " .. tntName)
		return false
	end
end

function TNTService:getAvailableTNTs()
	local tnts = {}
	for _, tnt in pairs(self.tntFolder:GetChildren()) do
		if tnt:IsA("Accessory") then
			table.insert(tnts, tnt.Name)
		end
	end
	return tnts
end

function TNTService:getPlayersWithTNT(teamPlayers)
	local playersWithTNT = {}
	for _, player in pairs(teamPlayers) do
		if player:GetAttribute("HasTNT") then
			table.insert(playersWithTNT, player)
		end
	end
	return playersWithTNT
end

function TNTService:allPlayersHaveTNT(teamPlayers)
	for _, player in pairs(teamPlayers) do
		if not player:GetAttribute("HasTNT") then
			return false
		end
	end
	return true
end

return TNTService
