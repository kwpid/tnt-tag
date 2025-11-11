--[[
	Constants.lua
	Shared constants between client and server
]]

local Constants = {}

-- PvP Constants (client needs these for raycast)
Constants.HitRange = 16
Constants.HitRangeTolerance = 1.5
Constants.AimDotThreshold = 0.75

-- Remote Event Names
Constants.RemoteEvents = {
	PvP = "PvPEvent",
}

return Constants
