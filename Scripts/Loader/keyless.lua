local API = "https://pickashub-script-api.pickazhub.workers.dev"

local Games = {
    [10771421858]="PH-VJH5DU",
    [6015491985]="PH-5CTWBD",
    [10766845655] ="PH-N47WT4",
    [6035872082] ="PH-T2WFPZ", 
}

local ScriptID = Games[game.GameId]

if not ScriptID then
    warn("[PICKA'S HUB] Unsupported Game")
    return
end

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
