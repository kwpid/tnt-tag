# Roblox TNT PvP Game - Professional Edition

A fully refactored, professional Roblox PvP game with modular architecture, comprehensive leaderboard system with JSON inventory support, and easy configuration.

## 🎮 Game Overview

TNT hot-potato style PvP elimination game where players pass TNT by hitting each other. Players holding TNT when the timer expires are eliminated. Last player standing wins!

## ✨ Features

- **Modular Service Architecture** - Clean separation of concerns
- **DataStore Persistence** - All stats saved with retry logic
- **JSON Inventory System** - Ready for future inventory features
- **Easy Configuration** - Change all game settings in one file
- **Professional Logging** - Structured error handling and debugging
- **Comprehensive Rewards** - Cash, XP, streaks, and placement-based rewards
- **Multiple TNT Skins** - Equipped TNT skin support
- **Visual Effects** - Explosions, knockback, hit feedback
- **Weekly Stats** - Track weekly wins and streaks

## 📁 Project Structure

```
ServerScriptService/
├── Main.server.lua           # Bootstrap script
├── PVPServer.lua             # PvP hit handling
├── Shared/
│   └── Logger.lua            # Logging utility
└── Services/
    ├── LeaderboardService.lua # DataStore & stats management
    ├── PlayerService.lua      # Player management & teleportation
    ├── TNTService.lua         # TNT logic & accessories
    ├── RewardService.lua      # Cash/XP calculations
    ├── MessagingService.lua   # UI messages & announcements
    ├── EffectsService.lua     # Visual & audio effects
    └── MatchService.lua       # Game loop & rounds

ServerStorage/
└── Config/
    └── GameConfig.lua         # Central configuration

ReplicatedStorage/
└── Shared/
    └── Constants.lua          # Shared client/server constants

StarterPlayerScripts/
└── PVPClient.lua              # Client-side input handling
```

## ⚙️ Configuration

All game settings are centralized in `ServerStorage/Config/GameConfig.lua`:

```lua
-- Match Settings
Config.Match = {
    MinPlayers = 2,
    RoundTime = 30,
    IntermissionTime = 10,
}

-- Reward Settings
Config.Rewards = {
    Cash = { Base = 10, WinnerMultiplier = 5, ... },
    XP = { Max = 100, Base = 10, ... },
}

-- PvP Settings
Config.PvP = {
    MaxHitRange = 16,
    Knockback = { Horizontal = 35, Vertical = 8 },
}
```

Simply edit values in GameConfig.lua to tune gameplay without touching core logic!

## 🗄️ Leaderboard & Data System

### Automatic Data Persistence

- All player data automatically saves to DataStore
- Retry logic with configurable attempts
- Auto-save every 5 minutes
- Saves on player leave and server shutdown

### Data Structure

```lua
{
    wins = 0,
    streak = 0,
    highestStreak = 0,
    cash = 0,
    xp = 0,
    weeklyWins = 0,
    weeklyHighestStreak = 0,
    inventory = {}, -- JSON-ready for future items
}
```

### Inventory System (Ready for Expansion)

The LeaderboardService includes full JSON inventory support:

```lua
-- Add inventory items
LeaderboardService:setInventoryItem(player, "item_tnt_gold", {
    equipped = true,
    purchaseDate = os.time(),
})

-- Get inventory
local inventory = LeaderboardService:getInventory(player)
```

## 🎯 Service Architecture

### LeaderboardService
- DataStore operations with retry logic
- JSON serialization for inventory
- Automatic stat synchronization
- Cache management

### PlayerService
- Player initialization & cleanup
- Team management
- Teleportation utilities
- AFK detection

### TNTService
- TNT assignment logic
- Accessory management
- TNT skin system
- Transfer mechanics

### RewardService
- Placement-based rewards
- Cash & XP calculations
- Streak tracking
- Winner bonuses

### MatchService
- Game loop management
- Round logic
- Map loading/cleanup
- Win detection

### MessagingService
- Centralized UI updates
- Broadcast utilities
- Configurable messages

### EffectsService
- Visual explosions
- Knockback physics
- Hit feedback
- Animation/sound playback

## 🚀 Required Roblox Setup

### Teams
1. Create team: **"Lobby"**
2. Create team: **"Game"**

### ServerStorage
1. Create folder: **"Maps"**
   - Add map models with a **"MapSpawn"** part
2. Create folder: **"TNT"**
   - Add TNT accessories (must be Accessory objects)

### ReplicatedStorage
1. Create folder: **"RemoteEvents"**
   - Add RemoteEvent: **"PvPEvent"**
2. Create folder: **"Animations"** (optional)
   - Add Animation: **"ArmSwing"**
3. Create folder: **"Sounds"** (optional)
   - Add Sound: **"HitSound"**

### Workspace
- Add **SpawnLocation** for lobby spawn

### PlayerGui
- Create **ScreenGui** named: **"MainGUI"**
- Add **TextLabel** named: **"RoundTimer"** for game messages

## 🔧 Development

### Syncing with Rojo

This project is designed to work with Rojo for version control:

```bash
rojo serve
```

Then sync in Roblox Studio.

### Adding New Features

The modular architecture makes it easy to extend:

1. **New Service**: Create in `Services/` folder
2. **Inject Dependencies**: Pass required services to constructor
3. **Initialize**: Add to `Main.server.lua` bootstrap
4. **Configure**: Add settings to `GameConfig.lua`

### Logging

All services use the Logger utility:

```lua
local logger = Logger.new("ServiceName")
logger:info("Information message")
logger:warn("Warning message")
logger:error("Error message")
```

## 📊 Stats Tracked

### Per-Player Stats
- Wins (leaderstats)
- Current Streak (leaderstats)
- Highest Streak (leaderstats)
- Cash
- XP
- Weekly Wins
- Weekly Highest Streak

### Persistent Data
All stats automatically save to DataStore with backup/retry logic.

## 🎨 TNT Skin System

Players can equip different TNT skins:

```lua
-- Server-side
TNTService:equipTNTSkin(player, "TNT_Gold")

-- Get available skins
local skins = TNTService:getAvailableTNTs()
```

Add new TNT skins by placing Accessory objects in `ServerStorage/TNT/`.

## 🐛 Error Handling

- Structured logging with context
- Retry logic for DataStore operations
- Graceful degradation when assets missing
- Protected async operations with pcall

## 🔐 Security

- Server-authoritative hit detection
- Eligibility checks for all PvP actions
- Debounce protection
- Attribute validation

## 📝 License

This is a Roblox game project. Use and modify as needed for your Roblox games.

## 🤝 Contributing

When making changes:
1. Follow the existing service architecture
2. Add configuration to `GameConfig.lua`
3. Use the Logger utility
4. Test with multiple players
5. Verify DataStore saves correctly

---

**Note**: This project requires the Roblox platform and cannot run outside of Roblox Studio.
