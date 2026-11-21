-- ASTERVEIL HUB — PIANO RHYTHM TILES (Asterveil UI Library)
-- Status key used in comments:
--   [CAPTURED]   call shape taken from your captured remotes
--   [UNVERIFIED] assumption that must be checked in-game (set CFG.Debug = true)
--   [LEARNED]    filled in at runtime from the game's own client calls

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

local CFG = {
    Debug = false,        -- prints diagnostics to the console (never prints the webhook URL)
    HitOffsetMs = 0,      -- shifts the tap timing ratio (ms, small values)
    -- [UNVERIFIED] which queue remote belongs to which mode:
    ModeAction = { ["1v1"] = "duelQueue", ["4 Player"] = "battleQueue" },
    QueueRetrySeconds = 45,
    DailyRetrySeconds = 300,
}

local function dbg(...)
    if CFG.Debug then print("[AsterveilHub]", ...) end
end

------------------------------------------------------------------ Asterveil UI
local URL = "https://raw.githubusercontent.com/pickapicksmm/Asterveil-Hub/refs/heads/main/Library/Source/Asterveil-UiLibrary.lua"
local PG0 = LP:FindFirstChild("PlayerGui")
local guisBefore, LibGuis = {}, {}
if PG0 then for _, g in ipairs(PG0:GetChildren()) do guisBefore[g] = true end end

local okLibrary, Library = pcall(function()
    return loadstring(game:HttpGet(URL))()
end)
if not okLibrary or type(Library) ~= "table" then
    warn("[Asterveil Hub] Failed to load Asterveil UI Library: " .. tostring(Library))
    return
end

local function N(t, c, ty)
    pcall(function()
        Library:Notify({ Title = t, Content = c, Type = ty or "Info", Duration = 4 })
    end)
end

-- Asterveil native Space Universe black-and-silver theme.
local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(390, 844)
local panelWidth = math.max(280, math.min(430, viewport.X - 24))
local panelHeight = math.max(260, math.min(340, viewport.Y - 120))
local Window = Library:CreateWindow({
    Title = "Asterveil Hub",
    Size = Vector2.new(panelWidth, panelHeight),
})
Window:SetTitle("Asterveil Hub")
Window:SetOpenSize(42)
Window:AddTag({ Text = "Piano Rhythm Tiles", Icon = "music" })
Window:SetGame("Piano Rhythm Tiles")

-- Hide the full panel immediately; the small floating Asterveil button reopens it.
-- SetVisible/Toggle are native methods in the linked Asterveil library.
Window:SetVisible(false)

if PG0 then
    for _, g in ipairs(PG0:GetChildren()) do
        if not guisBefore[g] then LibGuis[g] = true end
    end
end

local PianoTab = Window:AddTab({ Title = "Piano", Icon = "music" })
local RewardsTab = Window:AddTab({ Title = "Rewards", Icon = "gift" })
local WebhookTab = Window:AddTab({ Title = "Webhook", Icon = "webhook" })

local Piano_ = PianoTab:AddSubTab({ Title = "Main" })
local Match_ = PianoTab:AddSubTab({ Title = "Matchmaking" })
local Endless_ = PianoTab:AddSubTab({ Title = "Endless" })
local Rewards_ = RewardsTab:AddSubTab({ Title = "Main" })
local Hook_ = WebhookTab:AddSubTab({ Title = "Discord" })

------------------------------------------------------------------ State
local S = {
    AutoTiles = false, AutoMatch = false, Mode = "1v1",
    AutoEndless = false, AutoDaily = false,
    songs = 0, total = 0,                 -- Form Stats (this session)
    match = nil, queuedAt = nil,
    inRun = false, lastMode = nil, endlessBlocked = false,
    endSongs = 0, endScore = 0, rewardTotals = {},
    curSong = nil, curScore = 0,
    dailyIds = {},
}

local Remotes = RS:WaitForChild("Remotes", 10)
local Request = Remotes and Remotes:WaitForChild("Request", 10)
if not Request then
    N("Piano", "Remotes.Request not found. Wrong game or not loaded yet.", "Error")
    return
end

local function now() return os.time() end
local function ts() return "<t:" .. now() .. ":F>" end
local function call(x) if type(x) == "function" then local ok, r = pcall(x); return ok and r or nil end return x end

------------------------------------------------------------------ Webhook
local WH = { url = nil, running = false, queue = {}, lastErr = 0 }
local httpRequest = (syn and syn.request) or http_request or request or (http and http.request)
local FILE = "AsterveilHub/piano_webhook.txt"

local function validUrl(u)
    if type(u) ~= "string" then return nil end
    u = u:match("^%s*(.-)%s*$")
    local host = u:match("^https://([%w%.]+)/api/webhooks/%d+/[%w_%-]+$")
    local allowed = { ["discord.com"] = 1, ["discordapp.com"] = 1, ["ptb.discord.com"] = 1, ["canary.discord.com"] = 1 }
    if host and allowed[host] then return u end
end

pcall(function()
    if isfile and isfile(FILE) then WH.url = validUrl(readfile(FILE)) end
end)

local function clean(s) return (tostring(s):gsub("[%c@`]", "")) end

local VIOLET, GREEN, RED = 0x9D00FF, 0x22C55E, 0xF43F5E
-- fields = { {name, value}, ... }; timestamps use Discord's <t:unix:F> format inside the values
local function whPush(title, color, fields)
    if not (WH.running and WH.url) then return end
    local f = {}
    for _, kv in ipairs(fields) do
        f[#f + 1] = { name = kv[1], value = (tostring(kv[2]) ~= "" and tostring(kv[2]) or "-"):sub(1, 1000), inline = false }
    end
    table.insert(WH.queue, {
        title = title, color = color, fields = f,
        footer = { text = "Asterveil Hub" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
    })
end

task.spawn(function()
    while true do
        task.wait(1.2)
        local msg = WH.queue[1]
        if msg and WH.running and WH.url then
            if not httpRequest then
                table.remove(WH.queue, 1)
                N("Webhook", "This executor has no HTTP request function. Cannot send.", "Error")
            else
                local ok, res = pcall(httpRequest, {
                    Url = WH.url, Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode({ embeds = { msg }, allowed_mentions = { parse = {} } }),
                })
                local code = ok and res and res.StatusCode
                if code and code >= 200 and code < 300 then
                    table.remove(WH.queue, 1)
                elseif code == 429 then
                    task.wait(3) -- keep message, retry
                else
                    table.remove(WH.queue, 1)
                    if os.clock() - WH.lastErr > 10 then
                        WH.lastErr = os.clock()
                        N("Webhook", "Sending failed. Check the URL." .. (code and (" (HTTP " .. code .. ")") or ""), "Error")
                    end
                end
            end
        elseif not WH.running then
            WH.queue = {}
        end
    end
end)

------------------------------------------------------------------ Stats text
local function statsText()
    return string.format("Song Played : %d\nTotal Scored : %d", S.songs, S.total)
end

------------------------------------------------------------------ Engine adapter (Auto Tiles)
-- Interface taken from the game's own client module (PlayerScripts.Client.Engine), as seen in the
-- script you supplied: phase(), chart().tiles[{t,lane,hold}], songTime(), runId(), gate(),
-- fallAt(tile, ratio), press(lane, clock), release(lane, clock), stats(), currentSong().
local PC
do
    local ps = LP:FindFirstChild("PlayerScripts")
    local client = ps and ps:FindFirstChild("Client")
    local m = client and client:FindFirstChild("Engine")
    if m then
        local ok, mod = pcall(require, m)
        if ok and type(mod) == "table" then PC = mod end
    end
end

local function engineOK()
    if not PC then return false, "Engine module not found (game updated?)" end
    for _, f in ipairs({ "phase", "chart", "songTime", "runId", "press", "release", "fallAt" }) do
        if type(PC[f]) ~= "function" then return false, "Engine." .. f .. " missing" end
    end
    return true
end

local function clientPlaying()
    if not engineOK() then return false end
    local ok, ph = pcall(PC.phase)
    return ok and (ph == "playing" or ph == "countdown" or ph == "gated")
end

local tapIdx, holds, lastRun = 1, {}, nil
RunService.Heartbeat:Connect(function()
    if not S.AutoTiles or not PC then return end
    local ok, err = pcall(function()
        local run = PC.runId()
        if run ~= lastRun then lastRun, tapIdx, holds = run, 1, {} end
        local phase, chart, t, clk = PC.phase(), PC.chart(), PC.songTime(), os.clock()
        local tiles = chart and chart.tiles
        if not tiles then return end
        if phase == "gated" and type(PC.gate) == "function" then
            local g = PC.gate()
            if g then
                while tapIdx <= #tiles and tiles[tapIdx].t <= g.t + 1e-5 do
                    local tl = tiles[tapIdx]; tapIdx += 1
                    PC.press(tl.lane, clk)
                    if tl.hold then holds[#holds + 1] = { at = t + tl.hold * 0.96, lane = tl.lane } end
                end
            end
        elseif phase == "playing" then
            local ratio = 0.80 + (CFG.HitOffsetMs / 1000) -- same timing ratio the game's engine uses for perfects
            while tapIdx <= #tiles do
                local tl = tiles[tapIdx]
                if t < PC.fallAt(tl, ratio) then break end
                tapIdx += 1
                PC.press(tl.lane, clk)
                if tl.hold then holds[#holds + 1] = { at = t + tl.hold * 0.96, lane = tl.lane } end
            end
            for i = #holds, 1, -1 do
                if t >= holds[i].at then
                    PC.release(holds[i].lane, clk)
                    table.remove(holds, i)
                end
            end
        end
    end)
    if not ok then dbg("tile loop error", err) end
end)

------------------------------------------------------------------ Stats / events
local function songName()
    if not PC then return nil end
    local s = call(PC.currentSong)
    if type(s) == "string" then return s end
    if type(s) == "table" then return s.title or s.name or s.id or s.songId end
end

local function curScore()
    local st = PC and call(PC.stats)
    if type(st) == "table" then return tonumber(st.score) end
end

local function songCompleted(score)
    S.songs += 1
    S.total += (score or 0)
    if S.lastMode == "endless" then
        S.endSongs += 1
        S.endScore += (score or 0)
    end
    refreshStats()
end

local function mergeRewards(res)
    if type(res) ~= "table" then return end
    local rw = res.rewards or res.reward
    if type(rw) == "table" then
        for k, v in pairs(rw) do
            if type(v) == "number" then S.rewardTotals[tostring(k)] = (S.rewardTotals[tostring(k)] or 0) + v end
        end
    end
    for _, k in ipairs({ "coins", "xp", "gems", "cash" }) do
        if type(res[k]) == "number" then S.rewardTotals[k] = (S.rewardTotals[k] or 0) + res[k] end
    end
end

local function rewardsText()
    local parts = {}
    for k, v in pairs(S.rewardTotals) do parts[#parts + 1] = k .. ": " .. v end
    table.sort(parts)
    return #parts > 0 and table.concat(parts, ", ") or "None reported by server"
end

local function endlessEnded(finalScore)
    local total = (finalScore and finalScore > 0) and finalScore or S.endScore -- [UNVERIFIED] endRun score is the run total
    whPush("ENDLESS ENDED", VIOLET, {
        { "Song Played", S.endSongs }, { "Rewards", rewardsText() },
        { "Total Score", total }, { "Time", ts() },
    })
    S.endSongs, S.endScore, S.rewardTotals = 0, 0, {}
end

local function learnDaily(action, args)
    -- [CAPTURED] questClaim {period="daily", id=...}: remember ids the game itself claims
    if action == "questClaim" and type(args) == "table" and args.period == "daily" and type(args.id) == "string" then
        S.dailyIds[args.id] = true
    end
end

local function onRequest(action, args, res)
    if type(args) ~= "table" then args = {} end
    if action == "startRun" then
        S.runSeq = (S.runSeq or 0) + 1
        S.inRun = true
        S.lastMode = args.mode
    elseif action == "endRun" then
        S.inRun = false
        local score = tonumber(args.score) or 0
        if args.finished == true then songCompleted(score) end
        mergeRewards(res)
        if S.lastMode == "endless" then endlessEnded(score) end
        S.lastMode = nil
        S.curSong, S.curScore = nil, 0
    else
        learnDaily(action, args)
    end
end

-- Read-only observer: forwards the game's own Request calls unchanged.
local hooked = false
if hookmetamethod and getnamecallmethod and checkcaller then
    local old
    old = hookmetamethod(game, "__namecall", (newcclosure or function(f) return f end)(function(self, ...)
        if self == Request and getnamecallmethod() == "InvokeServer" and not checkcaller() then
            local a1, a2 = ...
            local res = table.pack(old(self, ...))
            task.spawn(onRequest, a1, a2, res[1])
            return table.unpack(res, 1, res.n)
        end
        return old(self, ...)
    end))
    hooked = true
else
    N("Piano", "Executor lacks hookmetamethod: run-end detection, stats and daily-learning are unsupported.", "Warning")
end

-- Endless per-song detection by polling the current song [UNVERIFIED]
task.spawn(function()
    while true do
        task.wait(0.5)
        local name = songName()
        if name then
            if S.curSong and name ~= S.curSong and S.lastMode == "endless" and S.inRun then
                songCompleted(S.curScore)
                whPush("Song " .. S.endSongs .. " Success", VIOLET, {
                    { "Song", clean(S.curSong) }, { "Status", "Still Playing" },
                    { "Score", S.curScore or 0 }, { "Time", ts() },
                })
                S.curScore = 0
            end
            S.curSong = name
            S.curScore = curScore() or S.curScore
        end
    end
end)

------------------------------------------------------------------ Match detection
local function resolve(v)
    local id, name, disp
    if typeof(v) == "Instance" and v:IsA("Player") then id, name, disp = v.UserId, v.Name, v.DisplayName
    elseif type(v) == "number" then id = v
    elseif type(v) == "string" then name = v
    elseif type(v) == "table" then
        id = v.userId or v.UserId or v.id
        name = v.name or v.Name or v.username
        disp = v.displayName or v.DisplayName
    end
    if id and id == LP.UserId then return nil end
    if name and name == LP.Name then return nil end
    local p = id and Players:GetPlayerByUserId(id) or (name and Players:FindFirstChild(name))
    if p then name, disp = p.Name, p.DisplayName end
    if id and not name then pcall(function() name = Players:GetNameFromUserIdAsync(id) end) end
    if not (name or disp) then return nil end
    return string.format("%s (%s)", clean(disp or name), clean(name or disp))
end

local function enemyText(t)
    local list = {}
    for _, k in ipairs({ "opponent", "enemy", "rival", "opponents", "players" }) do
        local v = t[k]
        if v ~= nil then
            if type(v) == "table" and #v > 0 then
                for _, e in ipairs(v) do local r = resolve(e); if r then list[#list + 1] = r end end
            else
                local r = resolve(v); if r then list[#list + 1] = r end
            end
            if #list > 0 then break end
        end
    end
    return #list > 0 and table.concat(list, ", ") or "Unknown (server did not send it)"
end

local function onMatchPayload(t)
    local id = t.matchId
    if id == nil then return end
    local endedKey = t.final == true or t.completed == true or t.winner ~= nil or t.result ~= nil or t.won ~= nil
    if not S.match and not endedKey then
        S.match = { id = id, enemy = enemyText(t), t = os.clock() }
        S.queuedAt = nil
        whPush("MATCH FOUND", VIOLET, { { "Enemy", S.match.enemy }, { "Time Found", ts() } })
        N("Auto Match", "Match found.", "Success")
    elseif S.match and S.match.id == id and endedKey then
        local res = "Unknown"
        if t.won == true then res = "You Win!!" elseif t.won == false then res = "You Lose!!"
        elseif t.winner ~= nil then
            res = (t.winner == LP.UserId or t.winner == LP.Name) and "You Win!!" or "You Lose!!"
        elseif type(t.result) == "string" then
            res = t.result:lower():find("win") and "You Win!!" or "You Lose!!"
        end
        local score = tonumber(t.score) or (type(t.scores) == "table" and tonumber(t.scores[LP.UserId] or t.scores[tostring(LP.UserId)])) or S.curScore or 0
        whPush("MATCH END", res == "You Win!!" and GREEN or (res == "You Lose!!" and RED or VIOLET), {
            { "Result", res }, { "Enemy", S.match.enemy }, { "Score", score }, { "Time End", ts() },
        })
        S.match = nil
    end
end

local function onServerEvent(name, ...)
    for _, a in ipairs({ ... }) do
        if type(a) == "table" then
            dbg("event", name, a.matchId and "has matchId" or "")
            onMatchPayload(a)
        end
    end
end

for _, r in ipairs(Remotes:GetDescendants()) do
    if r:IsA("RemoteEvent") then
        r.OnClientEvent:Connect(function(...) onServerEvent(r.Name, ...) end)
    end
end

------------------------------------------------------------------ Loops
-- Auto Match
task.spawn(function()
    while true do
        task.wait(2)
        if S.match and os.clock() - S.match.t > 900 then S.match = nil end -- stale guard
        if S.AutoMatch and not S.match and not S.inRun
            and (not S.queuedAt or os.clock() - S.queuedAt > CFG.QueueRetrySeconds) then
            local action = CFG.ModeAction[S.Mode]
            local ok, res = pcall(Request.InvokeServer, Request, action) -- [CAPTURED] shape, [UNVERIFIED] mode mapping
            S.queuedAt = os.clock()
            dbg("queue", action, ok, typeof(res))
            if not ok then N("Auto Match", "Queue request failed.", "Error") end
        end
    end
end)

-- Auto Endless
local pressUiButton
local function tele(t) pcall(Request.InvokeServer, Request, "telemetry", t) end

local function getStore()
    local sh = RS:FindFirstChild("Shared")
    local ui = sh and (sh:FindFirstChild("UI") or sh)
    local m = ui and ui:FindFirstChild("Store")
    if m then
        local ok, mod = pcall(require, m)
        if ok and type(mod) == "table" then return mod end
    end
end

local function waitPlaying(sec)
    local t0 = os.clock()
    while os.clock() - t0 < sec do
        if clientPlaying() then return true end
        task.wait(0.5)
    end
    return false
end

-- A direct startRun only creates a server-side run (your screenshot showed the client never entered play).
-- So the client has to be driven. Three routes are tried in order; all route details are [UNVERIFIED]:
--   1) press the game's own buttons by text ("endless", then "play"/"start")
--   2) the client Store: set{screen="play", mode="endless"} (the Store.set{screen,song} shape is from the other script)
--   3) your captured direct sequence (telemetry, startRun, telemetry)
local function startEndless()
    S.inRun, S.lastMode = true, "endless"
    local seq = S.runSeq or 0
    local function started() return (S.runSeq or 0) > seq or clientPlaying() end

    if pressUiButton({ "endless" }) then
        task.wait(1)
        pressUiButton({ "play", "start" })
        waitPlaying(8)
    end
    if not started() then
        local st = getStore()
        if st and type(st.set) == "function" then
            pcall(st.set, { screen = "play", mode = "endless" })
            waitPlaying(8)
        end
    end
    if not started() then
        tele({ input = "touch", mode = "endless", event = "play_requested" })
        local ok = pcall(Request.InvokeServer, Request, "startRun", { mode = "endless" })
        if not ok then
            S.inRun = false
            N("Auto Endless", "startRun failed. Retrying shortly.", "Error")
            task.wait(5)
            return
        end
        tele({ input = "touch", event = "screen", screen = "play" })
        waitPlaying(8)
    end
    if not clientPlaying() and (S.runSeq or 0) == seq then
        S.inRun, S.endlessBlocked = false, true
        N("Auto Endless", "The game never entered play (tried UI, Store and direct start). Restarts paused; toggle off/on to retry.", "Warning")
    end
end

task.spawn(function()
    while true do
        task.wait(1.5)
        if S.AutoEndless and not S.endlessBlocked and not S.inRun and not S.match then
            startEndless()
        end
    end
end)

-- UI helper: press a visible game button by its text (e.g. "Try Again"). [UNVERIFIED] works only if the
-- game's buttons expose Activated / MouseButton1Click connections.
function pressUiButton(patterns)
    if not getconnections then return false end
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    local function shown(o)
        while o and o ~= pg do
            if LibGuis[o] then return false end
            if o:IsA("GuiObject") and not o.Visible then return false end
            if o:IsA("ScreenGui") and not o.Enabled then return false end
            o = o.Parent
        end
        return true
    end
    for _, b in ipairs(pg:GetDescendants()) do
        if (b:IsA("TextButton") or b:IsA("ImageButton")) and shown(b) then
            local txt = b:IsA("TextButton") and b.Text or ""
            for _, d in ipairs(b:GetDescendants()) do
                if d:IsA("TextLabel") then txt ..= " " .. d.Text end
            end
            txt = txt:lower()
            for _, pat in ipairs(patterns) do
                if txt:find(pat, 1, true) then
                    local fired = false
                    for _, sig in ipairs({ "Activated", "MouseButton1Click" }) do
                        local ok, conns = pcall(getconnections, b[sig])
                        if ok then for _, c in ipairs(conns) do pcall(function() c:Fire() end); fired = true end end
                    end
                    if fired then dbg("pressed UI button:", txt) return true end
                end
            end
        end
    end
    return false
end

-- Endless watchdog: if the client sits on "failed"/"finished" for 4s without the game calling endRun,
-- treat the run as dead so Auto Endless starts a new one. [UNVERIFIED] phase names come from the Engine module.
do
    local deadSince
    task.spawn(function()
        while true do
            task.wait(1)
            local ok, ph = false, nil
            if PC and type(PC.phase) == "function" then ok, ph = pcall(PC.phase) end
            if S.AutoEndless and S.inRun and S.lastMode == "endless" and ok and (ph == "failed" or ph == "finished") then
                deadSince = deadSince or os.clock()
                if os.clock() - deadSince > 4 then
                    deadSince = nil
                    endlessEnded(S.curScore)
                    S.curSong, S.curScore = nil, 0
                    local seq = S.runSeq or 0
                    local clicked = pressUiButton({ "try again", "retry", "play again" })
                    if clicked then task.wait(3) end
                    if not (clicked and (S.runSeq or 0) > seq) then
                        -- the game did not start a new run itself: fall back to Auto Endless' own start
                        S.inRun, S.lastMode = false, nil
                    end
                end
            else
                deadSince = nil
            end
        end
    end)
end

-- Claim Daily Rewards / Auto Claim Quest
-- [CAPTURED] questClaim {period="daily", id="d_endless100"}; "quests" call.
-- [UNVERIFIED] the "quests" response layout: entries with a string id flagged claimable/complete/done are claimed.
-- Period comes from the entry's period field, else the parent key (daily/weekly/monthly), else a "d_" prefix.
local function periodOf(node, hint)
    if type(node.period) == "string" then return node.period:lower() end
    if hint then return hint end
    if node.id:match("^d_") then return "daily" end
end

local function collectQuests(node, out, depth, hint)
    if depth > 6 or type(node) ~= "table" then return end
    if type(node.id) == "string" and node.claimed ~= true
        and (node.claimable == true or node.complete == true or node.completed == true or node.done == true) then
        local p = periodOf(node, hint)
        if p then out[node.id] = p end
    end
    for k, v in pairs(node) do
        if type(v) == "table" then
            local h = hint
            if type(k) == "string" then
                local kl = k:lower()
                if kl:find("daily") then h = "daily" elseif kl:find("weekly") then h = "weekly"
                elseif kl:find("monthly") then h = "monthly" end
            end
            collectQuests(v, out, depth + 1, h)
        end
    end
end

local function claimQuests(onlyDaily)
    local found = {}
    local ok, res = pcall(Request.InvokeServer, Request, "quests")
    if ok then collectQuests(res, found, 0, nil) end
    dbg("quests response", ok, typeof(res))
    for id in pairs(S.dailyIds) do found[id] = "daily" end
    S.dailyIds = {}
    local sent = 0
    for id, period in pairs(found) do
        if not onlyDaily or period == "daily" then
            if pcall(Request.InvokeServer, Request, "questClaim", { period = period, id = id }) then sent += 1 end
            task.wait(0.5)
        end
    end
    return sent
end

local function claimTick(announceEmpty)
    if not (S.AutoQuest or S.AutoDaily) then return end
    local n = claimQuests(not S.AutoQuest)
    if n > 0 then N("Claim", n .. " " .. "claim request(s) sent.", "Success")
    elseif announceEmpty then N("Claim", "Nothing claimable detected right now.", "Info") end
end

task.spawn(function()
    while true do
        task.wait(CFG.DailyRetrySeconds)
        claimTick(false)
    end
end)

------------------------------------------------------------------ Asterveil controls
Piano_:AddProfile({ Display = LP.DisplayName, Name = LP.Name, Status = "Piano Rhythm Tiles" })
Piano_:AddSection({ Title = "Auto Play" })

local tilesToggle
tilesToggle = Piano_:AddToggle({
    Title = "Auto Tiles", Default = false, Flag = "AutoTiles",
    Callback = function(v)
        if v then
            local ok, why = engineOK()
            if not ok then
                S.AutoTiles = false
                N("Auto Tiles", "Unsupported: " .. why, "Error")
                if tilesToggle then pcall(function() tilesToggle:Set(false) end) end
                return
            end
        end
        S.AutoTiles = v
    end,
})

Match_:AddSection({ Title = "Matchmaking" })
Match_:AddToggle({
    Title = "Auto Match", Default = false, Flag = "AutoMatch",
    Callback = function(v) S.AutoMatch = v; S.queuedAt = nil end,
})
Match_:AddDropdown({
    Title = "Match Mode", Options = { "1v1", "4 Player" }, Default = "1v1", Flag = "MatchMode",
    Callback = function(v) S.Mode = v; S.queuedAt = nil end,
})

Endless_:AddSection({ Title = "Endless Mode" })
Endless_:AddToggle({
    Title = "Auto Endless", Default = false, Flag = "AutoEndless",
    Callback = function(v) S.AutoEndless = v; if v then S.endlessBlocked = false end end,
})

Rewards_:AddSection({ Title = "Rewards" })
Rewards_:AddToggle({
    Title = "Claim Daily Rewards", Default = false, Flag = "ClaimDaily",
    Callback = function(v)
        S.AutoDaily = v
        if v then task.spawn(claimTick, true) end
    end,
})
Rewards_:AddToggle({
    Title = "Auto Claim Quest", Default = false, Flag = "AutoClaimQuest",
    Callback = function(v)
        S.AutoQuest = v
        if v then task.spawn(claimTick, true) end
    end,
})
Rewards_:AddSection({ Title = "Session Statistics" })
local card = Rewards_:AddParagraph({ Title = "Form Stats", Content = statsText() })

local function refreshStats()
    if card and card.Set then pcall(card.Set, card, statsText()) end
end

Hook_:AddSection({ Title = "Discord Webhook" })
local pending = ""
Hook_:AddInput({
    Title = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(v) pending = tostring(v or "") end,
})
Hook_:AddButton({
    Title = "Save webhook", ButtonText = "Save", Icon = "save",
    Callback = function()
        local u = validUrl(pending)
        if not u then N("Webhook", "Invalid Discord webhook URL.", "Error") return end
        WH.url = u
        local ok = pcall(function()
            if makefolder and not isfolder("AsterveilHub") then makefolder("AsterveilHub") end
            writefile(FILE, u)
        end)
        N("Webhook", ok and "URL saved." or "URL accepted for this session (could not write file).", ok and "Success" or "Warning")
    end,
})
Hook_:AddButton({
    Title = "Start notifications", ButtonText = "Start", Icon = "play",
    Callback = function()
        if not WH.url then N("Webhook", "Save a valid URL first.", "Error") return end
        WH.running = true
        N("Webhook", "Notifications started.", "Success")
    end,
})
Hook_:AddButton({
    Title = "Stop notifications", ButtonText = "Stop", Icon = "square",
    Callback = function()
        WH.running = false
        WH.queue = {}
        N("Webhook", "Notifications stopped.", "Info")
    end,
})


