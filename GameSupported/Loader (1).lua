-- Supported games: [UniverseId] = script URL
local Games = {
	[897772] = "https://raw.githubusercontent.com/pickapicksmm/Source/refs/heads/main/MathTowerRace.lua",
}

local universeId = game.GameId
local url = Games[universeId]

if not url then
	warn("[Loader] This game is not supported. Universe ID: " .. tostring(universeId))
	return
end

local ok, source = pcall(game.HttpGet, game, url)
if not ok or not source or source == "" then
	warn("[Loader] Failed to download the script for Universe ID " .. tostring(universeId))
	return
end

local chunk, err = loadstring(source)
if not chunk then
	warn("[Loader] Failed to compile the script: " .. tostring(err))
	return
end

chunk()
