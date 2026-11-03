local API = "https://pickashub-script-api.pickazhub.workers.dev"

local Games = {
    [1234567890]="PH-66QFE2",
    [9876543210]="PH-Y66SXU",
}

local ScriptID = Games[game.GameId]

if not ScriptID then
    warn("[PICKA'S HUB] Unsupported Game")
    return
end

-- Key verification is not integrated yet.
-- Add your key verification before fetching the script.

local Success, Source = pcall(function()
    return game:HttpGet(API .. "/file/" .. ScriptID)
end)

if not Success or type(Source) ~= "string" or #Source == 0 then
    warn("[PICKA'S HUB] Failed to fetch script")
    return
end

local Fn, Error = loadstring(Source)

if not Fn then
    warn("[PICKA'S HUB] Compile error:", Error)
    return
end

local RunSuccess, RunError = pcall(Fn)

if not RunSuccess then
    warn("[PICKA'S HUB] Runtime error:", RunError)
end
