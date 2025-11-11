# Roblox PvP TNT Game - Matchmaking Edition

## Project Overview
Professional Roblox PvP game with **lobby-based matchmaking**, **regional player pairing**, **ghost spectator mode**, and **sub-place game servers**. Players queue from lobby servers, get matched with players in their region, teleport to dedicated game servers, and eliminated players become flying ghost spectators.

## Important Note
**This project cannot run directly in Replit.** Roblox games require the Roblox game engine and must be run through Roblox Studio or the Roblox platform. However, this Replit includes a **syntax validation workflow** to check all Lua files for errors.

## Recent Updates (Latest)
✅ **Matchmaking System Implementation** with:
- Queue system with client UI for joining/leaving matchmaking
- Regional matchmaking (pairs players in same region)
- TeleportService integration for reserved game servers
- Ghost spectator mode (eliminated players fly around invisibly)
- Dual-mode server support (lobby servers vs game servers)
- Complete state restoration after ghost mode
- Professional error handling and logging

## Project Structure

```
ServerScriptService/
├── Main.server.lua              # Bootstrap (lobby or game server mode)
├── QueueServer.lua              # Queue remote event handler
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
    ├── MatchService.lua         # Game loop & round management
    ├── QueueService.lua         # Queue state management
    ├── MatchmakingService.lua   # Regional matchmaking & teleportation
    └── GhostService.lua         # Ghost spectator mode

ServerStorage/Config/
└── GameConfig.lua               # Central configuration

ReplicatedStorage/Shared/
└── Constants.lua                # Shared client/server constants

StarterPlayerScripts/
├── PVPClient.lua                # Client input handling
├── QueueClient.lua              # Queue button UI handler
└── GhostClient.lua              # Ghost visibility & flying controls
```

## Key Features

### Matchmaking System
- **Queue-based matchmaking** - Players click a button to join queue
- **Regional pairing** - Automatically groups players by region (NA, EU, AS, OC, SA)
- **Reserved servers** - Creates dedicated game servers using TeleportService
- **Flexible player counts** - 2-25 players per match
- **Cross-server** - Queue from any lobby server in your game

### Ghost Spectator Mode
- **Fly around as ghost** - Eliminated players become invisible flying spectators
- **Full controls** - WASD for movement, Space/Shift for up/down
- **Hidden from others** - Ghosts can't see other ghosts, players can't see ghosts
- **State preservation** - Original character appearance fully restored after match
- **Automatic cleanup** - Ghosts reset properly between rounds

### Dual Server Architecture
- **Lobby servers** - Run matchmaking, host queue system
- **Game servers** - Reserved servers for actual matches
- **Automatic detection** - Main.server.lua detects server type
- **Independent logic** - Each server type runs appropriate game loop

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
- Tune matchmaking, ghost mode, match timings, rewards, PvP mechanics
- Built-in validation on startup

## Configuration
Edit `ServerStorage/Config/GameConfig.lua` to change:
- **Matchmaking** - Min/max players, game place ID, timeouts
- **Ghost Mode** - Transparency, fly speed, enable/disable
- **Match settings** - Round time, intermission time
- **Reward calculations** - Cash, XP, multipliers
- **PvP mechanics** - Range, knockback, cooldowns
- **UI messages** - Custom text for all game states

## Setup Instructions

### 1. Create Sub-Place for Game Servers
1. In Roblox Studio, go to **Home** > **Game Settings** > **Places**
2. Click **"+ Add Place"** to create a new sub-place
3. Name it "Game Server" or similar
4. Copy the **Place ID** of this new sub-place
5. In `GameConfig.lua`, set `Config.Matchmaking.GamePlaceId` to this ID

### 2. Create Queue Button GUI
1. In Roblox Studio, insert a **ScreenGui** into **StarterGui**
2. Rename it to **"QueueGUI"**
3. Insert a **TextButton** into the ScreenGui
4. Rename the button to **"Button"**
5. Position and style the button as desired
6. The QueueClient.lua script will automatically handle the button clicks

### 3. Set Up Teams
1. Create two teams in the **Teams** service:
   - **"Lobby"** team (for players waiting in lobby)
   - **"Game"** team (for players in active matches)

### 4. Sync Code with Rojo
1. Open terminal and run:
   ```bash
   rojo serve
   ```
2. In Roblox Studio, connect to the Rojo server
3. Sync all code to both your lobby place and game server sub-place

### 5. Configure ServerStorage
1. In **ServerStorage**, create a folder named **"Maps"**
2. Add your map models to this folder
3. Each map should have a part named **"MapSpawn"** for player spawn location

### 6. Test the System
1. Publish both the lobby place and game server sub-place
2. Test with at least 2 players
3. Click the queue button in the lobby
4. Players will be matched and teleported to a game server
5. Eliminated players will become ghosts
6. Winner returns all players to lobby state

## Validation
Run the **Validate Syntax** workflow in Replit to check all Lua files for syntax errors before syncing to Roblox.

## Technical Notes
- **TeleportService** - Reserved servers for matchmaking
- **LocalizationService** - Detects player regions for matchmaking
- **MessagingService** - Cross-server communication (future enhancement)
- **DataStoreService** - Player data persistence
- **Service registry pattern** - Dependency management
- **State preservation** - Ghost mode stores/restores original character properties
- **Dual bootstrap** - Main.server.lua detects lobby vs game server mode
- **Error handling** - Comprehensive pcall guards and structured logging
- **JSON-serializable data** - Inventory system ready for expansion

## Game Flow

### Lobby Server Flow
1. Players spawn in lobby
2. Click "Join Queue" button
3. QueueService adds player to queue
4. MatchmakingService groups players by region
5. When enough players found, creates reserved server
6. Teleports matched players to game server

### Game Server Flow
1. Server waits for players (2-25 players, 60s timeout)
2. Loads random map from ServerStorage
3. Starts match countdown (10 seconds)
4. Match begins - TNT mechanics activate
5. Eliminated players become flying ghosts
6. Last player standing wins
7. All ghosts restored to normal
8. Match ends (could teleport back to lobby or shutdown server)

See README.md for complete documentation.
