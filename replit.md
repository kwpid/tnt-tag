# Roblox PvP TNT Game - Professional Edition

## Project Overview
Professional Roblox PvP game with **modular service architecture**, comprehensive **DataStore persistence**, **JSON inventory system**, and easy configuration. Players pass TNT by hitting each other, and players holding TNT when the timer expires are eliminated.

## Important Note
**This project cannot run directly in Replit.** Roblox games require the Roblox game engine and must be run through Roblox Studio or the Roblox platform. However, this Replit includes a **syntax validation workflow** to check all Lua files for errors.

## Recent Refactoring (Completed)
✅ **Complete professional refactoring completed** with:
- Modular service architecture with dependency injection
- Centralized configuration system
- DataStore persistence with auto-save and retry logic
- JSON-ready inventory system for future features
- Professional error handling and logging
- Service registry for shared singleton instances

## Project Structure

```
ServerScriptService/
├── Main.server.lua              # Bootstrap & service initialization
├── PVPServer.lua                # PvP hit handling
├── Shared/
│   ├── Logger.lua               # Structured logging utility
│   └── ServiceRegistry.lua      # Shared service instances
└── Services/
    ├── LeaderboardService.lua   # DataStore & stats with JSON inventory
    ├── PlayerService.lua        # Player lifecycle & teleportation
    ├── TNTService.lua           # TNT mechanics & accessories
    ├── RewardService.lua        # Cash/XP calculations & streaks
    ├── MessagingService.lua     # UI messages & announcements
    ├── EffectsService.lua       # Visual & audio effects
    └── MatchService.lua         # Game loop & round management

ServerStorage/Config/
└── GameConfig.lua               # Central configuration

ReplicatedStorage/Shared/
└── Constants.lua                # Shared client/server constants

StarterPlayerScripts/
└── PVPClient.lua                # Client input handling
```

## Key Features

### Modular Architecture
- **Service-based design** with clear separation of concerns
- **Dependency injection** for testability
- **ServiceRegistry** for shared singleton instances
- **Comprehensive error handling** with pcall guards and logging

### Data Persistence
- **DataStore integration** with retry logic
- **Auto-save** every 5 minutes
- **JSON inventory support** ready for future features
- **Save on player leave** and server shutdown

### Easy Configuration
- **Single config file** (`GameConfig.lua`) for all settings
- Tune match timings, rewards, PvP mechanics without touching code
- Built-in validation on startup

### Professional Error Handling
- **Structured Logger** with context and severity levels
- **Retry logic** for DataStore operations
- **Graceful degradation** when assets missing
- **Protected async operations**

## Configuration
Edit `ServerStorage/Config/GameConfig.lua` to change:
- Match settings (players, timings)
- Reward calculations (cash, XP, multipliers)
- PvP mechanics (range, knockback, cooldowns)
- UI messages and text

## How to Use This Project
1. Open **Roblox Studio**
2. Use **Rojo** to sync this code to your Roblox place:
   ```bash
   rojo serve
   ```
3. Set up required game structure (see README.md for details)
4. Publish and test in Roblox

## Validation
Run the **Validate Syntax** workflow in Replit to check all Lua files for syntax errors before syncing to Roblox.

## Technical Notes
- Uses DataStoreService for persistence
- Service registry pattern for dependency management
- Error handling with pcall and structured logging
- JSON-serializable inventory data structure
- Professional code organization following Roblox best practices

See README.md for complete documentation.
