#!/usr/bin/env lua

--[[
        validate.lua
        Simple Lua syntax validator for Roblox game files
        This script checks that all Lua files have valid syntax
]]

print("=== Roblox TNT PvP - Code Validation ===")
print("")

local function checkFile(filepath)
        local file = io.open(filepath, "r")
        if not file then
                print("❌ Could not open file: " .. filepath)
                return false
        end
        
        local content = file:read("*all")
        file:close()
        
        local func, err = load(content, filepath)
        if func then
                print("✓ " .. filepath)
                return true
        else
                print("❌ " .. filepath)
                print("   Error: " .. tostring(err))
                return false
        end
end

local files = {
        -- Config
        "ServerStorage/Config/GameConfig.lua",
        
        -- Services
        "ServerScriptService/Services/LeaderboardService.lua",
        "ServerScriptService/Services/PlayerService.lua",
        "ServerScriptService/Services/TNTService.lua",
        "ServerScriptService/Services/RewardService.lua",
        "ServerScriptService/Services/MessagingService.lua",
        "ServerScriptService/Services/EffectsService.lua",
        "ServerScriptService/Services/MatchService.lua",
        
        -- Shared
        "ServerScriptService/Shared/Logger.lua",
        "ServerScriptService/Shared/ServiceRegistry.lua",
        "ReplicatedStorage/Shared/Constants.lua",
        
        -- Scripts
        "ServerScriptService/Main.server.lua",
        "ServerScriptService/PVPServer.lua",
        "StarterPlayerScripts/PVPClient.lua",
}

print("Checking " .. #files .. " Lua files for syntax errors...")
print("")

local allValid = true
for _, filepath in ipairs(files) do
        if not checkFile(filepath) then
                allValid = false
        end
end

print("")
if allValid then
        print("✅ All files have valid Lua syntax!")
        print("")
        print("Note: This project contains Roblox game code that requires")
        print("the Roblox platform to run. Use Roblox Studio and a tool")
        print("like Rojo to sync this code to your Roblox place.")
        os.exit(0)
else
        print("❌ Some files have syntax errors. Please fix them.")
        os.exit(1)
end
