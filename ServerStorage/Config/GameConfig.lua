--[[
	GameConfig.lua
	Central configuration for all game settings
	Modify values here to tune gameplay without touching core logic
]]

local Config = {}

-- Match Settings
Config.Match = {
	MinPlayers = 2,
	RoundTime = 30, -- seconds per round
	IntermissionTime = 10, -- seconds before match starts
}

-- Team Names
Config.Teams = {
	LobbyTeam = "Lobby",
	GameTeam = "Game",
}

-- Reward Settings
Config.Rewards = {
	Cash = {
		Base = 10,
		WinnerMultiplier = 5,
		PlacementMultiplier = 0.5,
		PlayerCountBonus = 2,
	},
	XP = {
		Max = 100, -- Maximum XP for winning
		Base = 10, -- Base XP for participating
		PerPlacement = 8, -- XP bonus per placement position
	},
}

-- TNT Settings
Config.TNT = {
	DefaultTNT = "TNT",
	InitialTNTCount = {
		Min = 1, -- Minimum TNT players at start
		MaxPercent = 0.25, -- Max 25% of players start with TNT
		MaxAbsolute = 3, -- Never more than 3 TNT players
		ThresholdForMultiple = 5, -- Need at least this many players for multiple TNT
	},
}

-- PvP Settings
Config.PvP = {
	MaxHitRange = 16, -- studs
	HitCooldown = 0.01, -- seconds between hits
	Knockback = {
		Horizontal = 35,
		Vertical = 8,
		Duration = 0.15,
	},
	GlowDuration = 0.15,
}

-- UI Messages
Config.Messages = {
	WaitingForPlayers = "Waiting for players..",
	IntermissionFormat = "⌛ Intermission: %ds",
	IntermissionCancelled = "⚠️ Intermission cancelled - not enough active players!",
	TNTTimerFormat = "💣 TNT explodes in: %ds",
	AllHaveTNT = "💥 Everyone has TNT! Exploding early...",
	WinnerFormat = "🏆 Winner: %s",
	EliminatedFormat = "💥 BOOM! Eliminated: %s",
}

-- Storage Folders
Config.Storage = {
	MapFolder = "Maps",
	TNTFolder = "TNT",
}

-- Remote Events
Config.Remotes = {
	PvPEvent = "PvPEvent",
	RemotesFolder = "RemoteEvents",
}

-- Data Settings
Config.Data = {
	AutoSaveInterval = 300, -- Auto-save every 5 minutes
	RetryAttempts = 3,
	RetryDelay = 1, -- seconds
}

-- Validation
local function validateConfig()
	assert(Config.Match.MinPlayers >= 2, "MinPlayers must be at least 2")
	assert(Config.Match.RoundTime > 0, "RoundTime must be positive")
	assert(Config.Rewards.Cash.Base >= 0, "Base cash reward must be non-negative")
	assert(Config.Rewards.XP.Max > 0, "Max XP must be positive")
	assert(Config.PvP.MaxHitRange > 0, "Hit range must be positive")
end

validateConfig()

return Config
