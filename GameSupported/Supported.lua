local allowedGames = {
    [17625359962] = true,  -- GameId (universe)
    [116191653750036] = true,
    [11649987817] = true, 
}

if not allowedGames[game.GameId] then
    warn("Game not supported")
    return
end

print("Game supported!")
