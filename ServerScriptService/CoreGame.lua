local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local MIN_PLAYERS = 2
local ROUND_TIME = 30
local INTERMISSION = 10
local LOBBY_TEAM = Teams:FindFirstChild("Lobby")
local GAME_TEAM = Teams:FindFirstChild("Game")
local MAP_FOLDER = ServerStorage:WaitForChild("Maps")
local TNT_FOLDER = ServerStorage:WaitForChild("TNT")

-- Cash reward settings
local BASE_CASH_REWARD = 10  
local WINNER_MULTIPLIER = 5 
local PLACEMENT_MULTIPLIER = 0.5  
local PLAYER_COUNT_BONUS = 2  

-- XP reward settings
local MAX_XP = 100  -- Maximum XP for winning
local BASE_XP = 10   -- Base XP for participating
local XP_PER_PLACEMENT = 8  -- XP bonus per placement position (higher placement = more XP)

local currentMap = nil
local roundTimer = 0
local active = false
local gameStartPlayers = 0  

local playersSetup = {}

local function broadcastUIText(text)
	for _, player in pairs(Players:GetPlayers()) do
		local gui = player:FindFirstChildOfClass("PlayerGui")
		if gui then
			local mainGUI = gui:FindFirstChild("MainGUI")
			if mainGUI then
				local timerText = mainGUI:FindFirstChild("RoundTimer")
				if timerText and timerText:IsA("TextLabel") then
					timerText.Text = text
				end
			end
		end
	end
end

local function setupPlayerStats(player)
	if playersSetup[player] then
		return
	end

	local stats = player:WaitForChild("leaderstats", 5)
	if not stats then return end

	stats:WaitForChild("Wins", 5)
	stats:WaitForChild("Streak", 5)
	stats:WaitForChild("HighestStreak", 5)

	player:WaitForChild("Cash", 5)
	player:WaitForChild("XP", 5)  -- Wait for XP stat

	playersSetup[player] = true
end

local function getActiveTeamPlayers(team)
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team == team and not player:GetAttribute("AFK") then
			table.insert(result, player)
		end
	end
	return result
end

local function calculateCashReward(placement, totalPlayers, isWinner)
	local baseCash = BASE_CASH_REWARD
	local playerBonus = totalPlayers * PLAYER_COUNT_BONUS
	local placementBonus = (totalPlayers - placement + 1) * PLACEMENT_MULTIPLIER

	local totalCash = baseCash + playerBonus + placementBonus

	if isWinner then
		totalCash = totalCash * WINNER_MULTIPLIER
	end

	return math.floor(totalCash)
end

local function calculateXPReward(placement, totalPlayers, isWinner)
	if isWinner then
		return MAX_XP  -- Winner gets maximum XP
	end

	-- Calculate XP based on placement (higher placement = more XP)
	local placementBonus = (totalPlayers - placement) * XP_PER_PLACEMENT
	local totalXP = BASE_XP + placementBonus

	-- Cap XP at MAX_XP - 1 for non-winners
	return math.min(totalXP, MAX_XP - 1)
end

local function awardCash(player, amount, reason)
	local cash = player:FindFirstChild("Cash")
	if cash then
		cash.Value = cash.Value + amount

		local gui = player:FindFirstChildOfClass("PlayerGui")
		if gui then
			local message = "💰 +" .. amount .. " cash! " .. reason
			print(player.Name .. " received " .. amount .. " cash: " .. reason)
		end
	end
end

local function awardXP(player, amount, reason)
	local xp = player:FindFirstChild("XP")
	if xp then
		xp.Value = xp.Value + amount

		local gui = player:FindFirstChildOfClass("PlayerGui")
		if gui then
			local message = "⭐ +" .. amount .. " XP! " .. reason
			print(player.Name .. " received " .. amount .. " XP: " .. reason)
		end
	end
end

-- TNT explosion effect (visual/audio only, no damage)
local function explodePlayer(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		-- Create a purely visual explosion effect
		local explosion = Instance.new("Explosion")
		explosion.Position = hrp.Position
		explosion.BlastRadius = 10 -- Visual size
		explosion.BlastPressure = 0 -- No knockback/damage
		explosion.Visible = true -- Show the explosion effect
		explosion.Parent = Workspace

		-- Clean up the explosion after a short time
		Debris:AddItem(explosion, 3)
	end
end

-- Teleport player to lobby spawn
local function teleportPlayerToLobby(player)
	local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then return end

	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrp = char.HumanoidRootPart

		-- Teleport the player
		hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)

		-- Reset player's health and states
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
			humanoid.PlatformStand = false
			humanoid.Sit = false
		end

		-- Clear any velocity
		if hrp:FindFirstChild("BodyVelocity") then
			hrp.BodyVelocity:Destroy()
		end

		-- Disable player interaction temporarily
		player:SetAttribute("CanHit", false)

		print(player.Name .. " teleported to lobby after TNT explosion")
	end
end

-- Get player's equipped TNT (defaults to "TNT" if none equipped)
local function getEquippedTNT(player)
	local equippedTNT = player:GetAttribute("EquippedTNT")
	if not equippedTNT or equippedTNT == "" then
		return "TNT" -- Default TNT
	end
	return equippedTNT
end

-- Attach TNT accessory based on player's equipped TNT
local function attachTNTAccessory(player)
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	-- Remove any existing TNT accessories
	for _, acc in pairs(char:GetChildren()) do
		if acc:IsA("Accessory") and acc.Name:find("TNT") then
			acc:Destroy()
		end
	end

	local equippedTNTName = getEquippedTNT(player)
	local tntAcc = TNT_FOLDER:FindFirstChild(equippedTNTName)

	if tntAcc and tntAcc:IsA("Accessory") then
		local cloneAcc = tntAcc:Clone()
		cloneAcc.Name = "TNT_" .. equippedTNTName -- Prefix to identify it as active TNT
		cloneAcc.Parent = char
		print("Attached " .. equippedTNTName .. " to " .. player.Name)
	else
		-- Fallback to default TNT if equipped TNT doesn't exist
		local defaultTNT = TNT_FOLDER:FindFirstChild("TNT")
		if defaultTNT and defaultTNT:IsA("Accessory") then
			local cloneAcc = defaultTNT:Clone()
			cloneAcc.Name = "TNT_TNT"
			cloneAcc.Parent = char
			print("Attached default TNT to " .. player.Name .. " (equipped TNT not found)")
		end
	end
end

-- Reset TNT
local function resetTNTAttributes()
	for _, player in pairs(Players:GetPlayers()) do
		player:SetAttribute("HasTNT", false)
		local char = player.Character
		if char then
			for _, acc in pairs(char:GetChildren()) do
				if acc:IsA("Accessory") and acc.Name:find("TNT_") then
					acc:Destroy()
				end
			end
		end
	end
end

-- Assign TNT
local function assignInitialTNT()
	local gamePlayers = getTeamPlayers(GAME_TEAM)

	local count = 1
	if #gamePlayers > 5 then
		count = math.min(3, math.floor(#gamePlayers * 0.25))
	end

	local chosen = {}
	while #chosen < count do
		local pick = gamePlayers[math.random(1, #gamePlayers)]
		if not table.find(chosen, pick) then
			pick:SetAttribute("HasTNT", true)
			attachTNTAccessory(pick)
			table.insert(chosen, pick)
		end
	end
end

local function clearPlayerAttributes()
	for _, player in pairs(Players:GetPlayers()) do
		for attrName, attrValue in pairs(player:GetAttributes()) do
			if attrName ~= "AFK" and attrName ~= "EquippedTNT" and attrName ~= "Leaderboard_Wins" and attrName ~= "Leaderboard_Streak" then
				player:SetAttribute(attrName, nil)
			end
		end
	end
end

local function eliminateTNTPlayers()
	local remainingPlayers = getTeamPlayers(GAME_TEAM)
	local eliminatedPlayers = {}

	for _, player in pairs(Players:GetPlayers()) do
		if player.Team == GAME_TEAM and player:GetAttribute("HasTNT") then

			local placement = #remainingPlayers
			local cashReward = calculateCashReward(placement, gameStartPlayers, false)
			local xpReward = calculateXPReward(placement, gameStartPlayers, false)

			awardCash(player, cashReward, "Eliminated in round (Place #" .. placement .. ")")
			awardXP(player, xpReward, "Eliminated in round (Place #" .. placement .. ")")

			-- Create explosion effect at player's position (visual only)
			explodePlayer(player)

			-- Remove player from game and reset attributes
			player.Team = LOBBY_TEAM
			player:SetAttribute("HasTNT", false)
			table.insert(eliminatedPlayers, player)

			-- Remove TNT accessory
			local char = player.Character
			if char then
				for _, acc in pairs(char:GetChildren()) do
					if acc:IsA("Accessory") and acc.Name:find("TNT_") then
						acc:Destroy()
					end
				end
			end

			-- Teleport player to lobby after a brief delay to show explosion
			task.wait(0.5)
			teleportPlayerToLobby(player)

			-- Reset player streak
			local stats = player:FindFirstChild("leaderstats")
			if stats and stats:FindFirstChild("Streak") then
				stats.Streak.Value = 0
			end
		end
	end

	if #eliminatedPlayers > 0 then
		local eliminatedNames = {}
		for _, player in pairs(eliminatedPlayers) do
			table.insert(eliminatedNames, player.DisplayName)
		end
		local message = "💥 BOOM! Eliminated: " .. table.concat(eliminatedNames, ", ")
		broadcastUIText(message)
	end
end

local function clearMap()
	if currentMap then
		currentMap:Destroy()
		currentMap = nil
	end
end

local function loadMap()
	local maps = MAP_FOLDER:GetChildren()
	if #maps == 0 then return end
	local chosen = maps[math.random(1, #maps)]:Clone()
	chosen.Parent = Workspace
	currentMap = chosen
end

function getTeamPlayers(team)
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team == team then
			table.insert(result, player)
		end
	end
	return result
end

local function teleportToMapSpawn()
	if not currentMap then return end
	local spawn = currentMap:FindFirstChild("MapSpawn")
	if not spawn then return end

	for _, player in pairs(getTeamPlayers(GAME_TEAM)) do
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			player:LoadCharacter()
			task.wait(0.5)
		end
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)

			player:SetAttribute("CanHit", false)

			task.delay(1, function()
				if player and player.Team == GAME_TEAM then
					player:SetAttribute("CanHit", true)
				end
			end)
		end
	end
end

local function teleportToLobbySpawn()
	local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then return end

	for _, player in pairs(getTeamPlayers(LOBBY_TEAM)) do
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			player:LoadCharacter()
			task.wait(0.5)
		end
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
		end
	end
end

local function checkForWinner()
	local remaining = getTeamPlayers(GAME_TEAM)
	if #remaining == 1 then
		local winner = remaining[1]
		print("Winner is:", winner.Name)
		broadcastUIText("🏆 Winner: " .. winner.DisplayName)

		local winnerCash = calculateCashReward(1, gameStartPlayers, true)
		local winnerXP = MAX_XP  -- Winner gets maximum XP

		awardCash(winner, winnerCash, "🏆 Victory! (1st Place)")
		awardXP(winner, winnerXP, "🏆 Victory! (1st Place)")

		local stats = winner:FindFirstChild("leaderstats")
		if stats then
			if stats:FindFirstChild("Wins") then
				stats.Wins.Value += 1
			end
			if stats:FindFirstChild("Streak") then
				stats.Streak.Value += 1
				local streak = stats.Streak.Value
				local highest = stats:FindFirstChild("HighestStreak")
				if highest and streak > highest.Value then
					highest.Value = streak
				end
			end
		end

		if winner:FindFirstChild("WeeklyWins") then
			winner.WeeklyWins.Value += 1
		end
		if winner:FindFirstChild("WeeklyHighestStreak") and stats and stats:FindFirstChild("Streak") then
			if stats.Streak.Value > winner.WeeklyHighestStreak.Value then
				winner.WeeklyHighestStreak.Value = stats.Streak.Value
			end
		end

		for _, player in pairs(Players:GetPlayers()) do
			player.Team = LOBBY_TEAM
			player:SetAttribute("HasTNT", false)
			player:SetAttribute("CanHit", false)
		end

		clearMap()
		teleportToLobbySpawn()
		clearPlayerAttributes()

		return true
	end
	return false
end

local function playRound()
	resetTNTAttributes()
	assignInitialTNT()

	roundTimer = ROUND_TIME
	while roundTimer > 0 do
		broadcastUIText("💣 TNT explodes in: " .. roundTimer .. "s")
		task.wait(1)
		roundTimer -= 1

		if checkForWinner() then
			return
		end

		local allHaveTNT = true
		for _, player in ipairs(getTeamPlayers(GAME_TEAM)) do
			if not player:GetAttribute("HasTNT") then
				allHaveTNT = false
				break
			end
		end

		if allHaveTNT then
			broadcastUIText("💥 Everyone has TNT! Exploding early...")
			break 
		end
	end

	eliminateTNTPlayers()
	wait(3)
	teleportToMapSpawn()
	checkForWinner()
end

-- Start game loop
function startGameLoop()
	active = true

	gameStartPlayers = 0
	for _, player in pairs(getTeamPlayers(LOBBY_TEAM)) do
		if not player:GetAttribute("AFK") then
			gameStartPlayers += 1
		end
	end

	for _, player in pairs(Players:GetPlayers()) do
		if player.Team == LOBBY_TEAM and not player:GetAttribute("AFK") then
			player.Team = GAME_TEAM
		end
	end

	for _, player in pairs(Players:GetPlayers()) do
		if player:GetAttribute("AFK") then
			player.Team = LOBBY_TEAM
		end
	end
	teleportToLobbySpawn()

	wait(1)
	teleportToMapSpawn()
	assignInitialTNT()

	while #getTeamPlayers(GAME_TEAM) > 1 do
		playRound()
	end

	for _, player in pairs(Players:GetPlayers()) do
		player:SetAttribute("CanHit", false)
	end

	if checkForWinner() then
		task.wait(3) 
		broadcastUIText("Waiting for players..")
	end
	wait(3)
	resetTNTAttributes()
	clearPlayerAttributes()
	teleportToLobbySpawn()
	active = false
end

-- Function to equip TNT (can be called from other scripts)
function equipTNT(player, tntName)
	if TNT_FOLDER:FindFirstChild(tntName) then
		player:SetAttribute("EquippedTNT", tntName)
		print(player.Name .. " equipped " .. tntName)

		-- If player currently has TNT, update their accessory
		if player:GetAttribute("HasTNT") then
			attachTNTAccessory(player)
		end

		return true
	else
		warn("TNT '" .. tntName .. "' not found in TNT folder")
		return false
	end
end

-- Function to get all available TNT accessories
function getAvailableTNTs()
	local tnts = {}
	for _, tnt in pairs(TNT_FOLDER:GetChildren()) do
		if tnt:IsA("Accessory") then
			table.insert(tnts, tnt.Name)
		end
	end
	return tnts
end

task.spawn(function()
	while true do
		task.wait(1)
		local lobbyPlayers = getTeamPlayers(LOBBY_TEAM)
		local activeLobbyPlayers = getActiveTeamPlayers(LOBBY_TEAM)

		if not active and #activeLobbyPlayers >= MIN_PLAYERS then
			local intermissionActive = true

			for i = INTERMISSION, 1, -1 do
				activeLobbyPlayers = getActiveTeamPlayers(LOBBY_TEAM)

				if #activeLobbyPlayers < MIN_PLAYERS then
					intermissionActive = false
					broadcastUIText("⚠️ Intermission cancelled - not enough active players!")
					task.wait(2)
					break
				end

				if i == 3 then
					clearMap()
					loadMap()
				end
				broadcastUIText("⌛ Intermission: " .. i .. "s")
				task.wait(1)
			end
			if intermissionActive and #getActiveTeamPlayers(LOBBY_TEAM) >= MIN_PLAYERS then
				startGameLoop()
			end
		elseif not active then
			local totalPlayers = #lobbyPlayers
			local activePlayers = #activeLobbyPlayers

			if totalPlayers > 0 and activePlayers < MIN_PLAYERS then
				local afkCount = totalPlayers - activePlayers
				broadcastUIText("Waiting for players..")
			else
				broadcastUIText("Waiting for players..")
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("HasTNT", false)
	player:SetAttribute("CanHit", false)
	player:SetAttribute("EquippedTNT", "TNT") -- Default to standard TNT
	player.Team = LOBBY_TEAM

	setupPlayerStats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playersSetup[player] = nil
end)
