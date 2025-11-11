# Roblox PvP TNT Game

## Project Overview
This is a **Roblox game project** written in Lua. It's a PvP (Player vs Player) game where players pass TNT to each other by hitting, and players holding TNT when the timer expires are eliminated.

## Important Note
**This project cannot run directly in Replit.** Roblox games require the Roblox game engine and must be run through Roblox Studio or the Roblox platform.

## Project Structure
- `ServerScriptService/CoreGame.lua` - Main game loop, round management, TNT mechanics, cash/XP rewards
- `ServerScriptService/PVPServer.lua` - Server-side PvP hit detection and TNT transfer logic
- `StarterPlayerScripts/PVPClient.lua` - Client-side input handling and raycast targeting

## Game Features
- TNT hot potato mechanics
- Round-based elimination system
- Cash and XP reward system
- Win streaks and leaderboards
- Multiple TNT skin support
- Knockback and visual effects

## How to Use This Project
To use this Roblox game code:
1. Open Roblox Studio
2. Use a tool like **Rojo** to sync this code to your Roblox place
3. Set up the required game structure:
   - Teams: "Lobby" and "Game"
   - ServerStorage folders: "Maps" and "TNT" (with TNT accessories)
   - ReplicatedStorage: RemoteEvents folder with "PvPEvent"
   - Workspace: SpawnLocation for lobby
4. Publish and test in Roblox

## Why This Can't Run in Replit
Roblox games use Roblox's proprietary game engine services like:
- `game:GetService()` for Players, Teams, Workspace, etc.
- Roblox's physics and rendering engine
- Roblox's networking and multiplayer infrastructure

These services don't exist outside the Roblox platform.
