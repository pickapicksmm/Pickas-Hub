-- PICKA'S HUB — PIANO RHYTHM TILES (PHLibrary)
-- Status key used in comments:
--   [CAPTURED]   call shape taken from your captured remotes
--   [UNVERIFIED] assumption that must be checked in-game (set CFG.Debug = true)
--   [LEARNED]    filled in at runtime from the game's own client calls

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- Key System lock. Everything except General (built into PHLibrary) and Auto Tiles stays locked while this is false.
-- NOTE: this is only a UI/logic switch in a client-side file. There is no key check behind it yet.
local KEY_UNLOCKED = false

local CFG = {
    Debug = false,        -- prints diagnostics to the console (never prints the webhook URL)
    HitOffsetMs = 0,      -- shifts the tap timing ratio (ms, small values)
    -- [UNVERIFIED] which queue remote belongs to which mode:
    ModeAction = { ["1v1"] = "duelQueue", ["4 Player"] = "battleQueue" },
    QueueRetrySeconds = 45,
    DailyRetrySeconds = 300,
}

local function dbg(...)
    if CFG.Debug then print("[PickasHub]", ...) end
end

------------------------------------------------------------------ UI
local URL = "https://raw.githubusercontent.com/pickapicksmm/Pickas-Hub/refs/heads/main/Libray.src/PHLibrary.lua"
-- remember which ScreenGuis are ours, so UI-button pressing never clicks the hub's own controls
local PG0 = LP:FindFirstChild("PlayerGui")
local guisBefore, LibGuis = {}, {}
if PG0 then for _, g in ipairs(PG0:GetChildren()) do guisBefore[g] = true end end
local Library = loadstring(game:HttpGet(URL))()

-- New texts go into PHLibrary's OWN language system (its LANGMAP / LANGS / LANGIDX tables, read from
-- Library.T's upvalues), so the library's Language dropdown and SetLanguage translate them too.
-- Needs debug.getupvalue; without it the new texts simply stay English.
local NEW_KEYS = { "Claim", "Auto Play", "Matchmaking", "Endless", "Rewards", "Discord Webhook", "Auto Tiles", "Auto Match", "Match Mode", "Auto Endless", "Claim Daily Rewards", "Auto Claim Quest", "Webhook URL", "Start", "Stop", "Form Stats", "Match found.", "Notifications started.", "Notifications stopped.", "Invalid Discord webhook URL.", "URL saved.", "Save a valid URL first.", "Key System Mode Only" }
local NEW_TR = {
    zh = { "领取", "自动演奏", "匹配", "无尽", "奖励", "Discord Webhook", "自动点击方块", "自动匹配", "匹配模式", "自动无尽", "领取每日奖励", "自动领取任务", "Webhook 链接", "开始", "停止", "统计数据", "已找到对局。", "通知已开启。", "通知已停止。", "Discord Webhook 链接无效。", "链接已保存。", "请先保存有效的链接。", "仅限密钥系统模式" },
    pt = { "Resgatar", "Jogo automático", "Matchmaking", "Infinito", "Recompensas", "Webhook do Discord", "Notas automáticas", "Partida automática", "Modo de partida", "Infinito automático", "Resgatar recompensas diárias", "Resgatar missões auto", "URL do webhook", "Iniciar", "Parar", "Estatísticas", "Partida encontrada.", "Notificações iniciadas.", "Notificações paradas.", "URL de webhook do Discord inválida.", "URL salva.", "Salve uma URL válida primeiro.", "Somente modo Key System" },
    ru = { "Получить", "Автоигра", "Подбор матча", "Бесконечный", "Награды", "Вебхук Discord", "Авто-тайлы", "Авто-матч", "Режим матча", "Авто-бесконечный", "Получать ежедневные награды", "Авто-получение квестов", "URL вебхука", "Запустить", "Остановить", "Статистика", "Матч найден.", "Уведомления запущены.", "Уведомления остановлены.", "Недопустимый URL вебхука Discord.", "URL сохранён.", "Сначала сохраните корректный URL.", "Только в режиме Key System" },
    hi = { "प्राप्त करें", "ऑटो प्ले", "मैचमेकिंग", "एंडलेस", "इनाम", "Discord वेबहुक", "ऑटो टाइल्स", "ऑटो मैच", "मैच मोड", "ऑटो एंडलेस", "दैनिक इनाम प्राप्त करें", "ऑटो क्वेस्ट प्राप्त करें", "वेबहुक URL", "शुरू करें", "रोकें", "आँकड़े", "मैच मिल गया।", "सूचनाएँ शुरू हुईं।", "सूचनाएँ रोकी गईं।", "अमान्य Discord वेबहुक URL।", "URL सहेजा गया।", "पहले एक मान्य URL सहेजें।", "केवल Key System मोड" },
    es = { "Reclamar", "Juego automático", "Emparejamiento", "Infinito", "Recompensas", "Webhook de Discord", "Notas automáticas", "Partida automática", "Modo de partida", "Infinito automático", "Reclamar recompensas diarias", "Reclamar misiones auto", "URL del webhook", "Iniciar", "Detener", "Estadísticas", "Partida encontrada.", "Notificaciones iniciadas.", "Notificaciones detenidas.", "URL de webhook de Discord no válida.", "URL guardada.", "Guarda primero una URL válida.", "Solo modo Key System" },
    it = { "Riscuoti", "Gioco automatico", "Matchmaking", "Infinito", "Ricompense", "Webhook Discord", "Tile automatici", "Partita automatica", "Modalità partita", "Infinito automatico", "Riscuoti ricompense giornaliere", "Riscuoti missioni auto", "URL webhook", "Avvia", "Ferma", "Statistiche", "Partita trovata.", "Notifiche avviate.", "Notifiche fermate.", "URL webhook Discord non valido.", "URL salvato.", "Salva prima un URL valido.", "Solo modalità Key System" },
    tr = { "Topla", "Otomatik Oyun", "Eşleştirme", "Sonsuz", "Ödüller", "Discord Webhook", "Otomatik Karolar", "Otomatik Maç", "Maç Modu", "Otomatik Sonsuz", "Günlük Ödülleri Topla", "Görevleri Otomatik Topla", "Webhook URL", "Başlat", "Durdur", "İstatistikler", "Maç bulundu.", "Bildirimler başlatıldı.", "Bildirimler durduruldu.", "Geçersiz Discord webhook URL.", "URL kaydedildi.", "Önce geçerli bir URL kaydedin.", "Yalnızca Key System Modu" },
    id = { "Klaim", "Main Otomatis", "Pencarian Match", "Endless", "Hadiah", "Webhook Discord", "Tile Otomatis", "Match Otomatis", "Mode Match", "Endless Otomatis", "Klaim Hadiah Harian", "Klaim Quest Otomatis", "URL Webhook", "Mulai", "Berhenti", "Statistik", "Match ditemukan.", "Notifikasi dimulai.", "Notifikasi dihentikan.", "URL webhook Discord tidak valid.", "URL disimpan.", "Simpan URL yang valid dulu.", "Hanya Mode Key System" },
    af = { "Eis", "Outomatiese Speel", "Pasmaak", "Eindeloos", "Belonings", "Discord-webhook", "Outomatiese Teëls", "Outomatiese Wedstryd", "Wedstrydmodus", "Outomatiese Eindeloos", "Eis Daaglikse Belonings", "Outomatiese Opdrag-eis", "Webhook-URL", "Begin", "Stop", "Statistiek", "Wedstryd gevind.", "Kennisgewings begin.", "Kennisgewings gestop.", "Ongeldige Discord-webhook-URL.", "URL gestoor.", "Stoor eers 'n geldige URL.", "Slegs Key System-modus" },
    ja = { "受け取る", "自動プレイ", "マッチメイキング", "エンドレス", "報酬", "Discord Webhook", "自動タイル", "自動マッチ", "マッチモード", "自動エンドレス", "デイリー報酬を受け取る", "クエスト自動受け取り", "Webhook URL", "開始", "停止", "統計", "マッチが見つかりました。", "通知を開始しました。", "通知を停止しました。", "Discord WebhookのURLが無効です。", "URLを保存しました。", "先に有効なURLを保存してください。", "キーシステムモード限定" },
    vi = { "Nhận", "Tự động chơi", "Ghép trận", "Vô tận", "Phần thưởng", "Webhook Discord", "Tự động bấm ô", "Tự động ghép trận", "Chế độ trận", "Tự động Vô tận", "Nhận thưởng hằng ngày", "Tự động nhận nhiệm vụ", "URL Webhook", "Bắt đầu", "Dừng", "Thống kê", "Đã tìm thấy trận.", "Đã bật thông báo.", "Đã dừng thông báo.", "URL webhook Discord không hợp lệ.", "Đã lưu URL.", "Hãy lưu một URL hợp lệ trước.", "Chỉ ở chế độ Key System" },
    th = { "รับ", "เล่นอัตโนมัติ", "จับคู่", "ไม่สิ้นสุด", "รางวัล", "Discord Webhook", "แตะไทล์อัตโนมัติ", "จับคู่อัตโนมัติ", "โหมดแมตช์", "ไม่สิ้นสุดอัตโนมัติ", "รับรางวัลรายวัน", "รับเควสอัตโนมัติ", "URL Webhook", "เริ่ม", "หยุด", "สถิติ", "พบแมตช์แล้ว", "เริ่มการแจ้งเตือนแล้ว", "หยุดการแจ้งเตือนแล้ว", "URL Discord Webhook ไม่ถูกต้อง", "บันทึก URL แล้ว", "กรุณาบันทึก URL ที่ถูกต้องก่อน", "เฉพาะโหมด Key System เท่านั้น" },
    ar = { "استلام", "لعب تلقائي", "المطابقة", "لا نهائي", "المكافآت", "Discord Webhook", "نقر البلاط تلقائيًا", "مطابقة تلقائية", "وضع المطابقة", "لا نهائي تلقائي", "استلام المكافآت اليومية", "استلام المهام تلقائيًا", "رابط Webhook", "ابدأ", "إيقاف", "الإحصائيات", "تم العثور على مباراة.", "بدأت الإشعارات.", "توقفت الإشعارات.", "رابط Discord Webhook غير صالح.", "تم حفظ الرابط.", "احفظ رابطًا صالحًا أولًا.", "وضع نظام المفتاح فقط" },
    fa = { "دریافت", "بازی خودکار", "مچ‌میکینگ", "بی‌پایان", "جوایز", "وب‌هوک Discord", "ضربه خودکار تایل‌ها", "مچ خودکار", "حالت مچ", "بی‌پایان خودکار", "دریافت جوایز روزانه", "دریافت خودکار مأموریت", "نشانی وب‌هوک", "شروع", "توقف", "آمار", "مچ پیدا شد.", "اعلان‌ها شروع شد.", "اعلان‌ها متوقف شد.", "نشانی وب‌هوک Discord نامعتبر است.", "نشانی ذخیره شد.", "ابتدا یک نشانی معتبر ذخیره کنید.", "فقط حالت Key System" },
}

local function injectLanguages()
    if not (debug and debug.getupvalue and Library.T) then return false end
    local LANGMAP, LANGS, LANGIDX
    local i = 1
    while true do
        local ok, name, val = pcall(debug.getupvalue, Library.T, i)
        if not ok or name == nil then break end
        if type(val) == "table" then
            if rawget(val, "English") == "en" then LANGMAP = val
            elseif type(rawget(val, "zh")) == "table" then LANGS = val
            elseif rawget(val, "General") ~= nil then LANGIDX = val end
        end
        i += 1
    end
    if not (LANGMAP and LANGS and LANGIDX) then return false end
    local idx = 0
    for _, v in pairs(LANGIDX) do if v > idx then idx = v end end
    for k, key in ipairs(NEW_KEYS) do
        if not LANGIDX[key] then
            idx += 1
            LANGIDX[key] = idx
            for code, arr in pairs(NEW_TR) do
                if LANGS[code] then LANGS[code][idx] = arr[k] end
            end
            Library._has[key] = true
        end
    end
    return true
end
local langInjected = injectLanguages()

local function N(t, c, ty)
    pcall(function()
        Library:Notify({ Title = t, Content = c, Type = ty or "Info" })
    end)
end


Library:SetAccent(Color3.fromRGB(157, 0, 255))

local Window = Library:CreateWindow({
    Title = "Picka's Hub",
    OpenSize = 48,
    ToggleKey = Enum.KeyCode.RightShift,
    FloatImage = 109882288573862, -- rbxassetid://109882288573862
})
Window:AddTag({ Text = "v1.0", Icon = "tag" })
Window:SetUserCard({ Status = "Online" })
if PG0 then
    for _, g in ipairs(PG0:GetChildren()) do
        if not guisBefore[g] then LibGuis[g] = true end
    end
end

-- General is built into PHLibrary: NOT created here.
local PianoTab = Window:AddTab({ Title = "Piano", Icon = "music" })
local OthersTab = Window:AddTab({ Title = "Claim", Icon = "gift" })
local WebhookTab = Window:AddTab({ Title = "Webhook", Icon = "webhook" })

local Piano_ = PianoTab:AddSubTab({ Title = "Main", Icon = "music" })
local Others_ = OthersTab:AddSubTab({ Title = "Main", Icon = "layout-grid" })
local Hook_ = WebhookTab:AddSubTab({ Title = "Main", Icon = "webhook" })

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
local FILE = "PickasHub/piano_webhook.txt"

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
    if not (KEY_UNLOCKED and WH.running and WH.url) then return end
    local f = {}
    for _, kv in ipairs(fields) do
        f[#f + 1] = { name = kv[1], value = (tostring(kv[2]) ~= "" and tostring(kv[2]) or "-"):sub(1, 1000), inline = false }
    end
    table.insert(WH.queue, {
        title = title, color = color, fields = f,
        footer = { text = "Picka's Hub" },
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

------------------------------------------------------------------ Stats card
local function statsText()
    return string.format("Song Played : %d\nTotal Scored : %d", S.songs, S.total)
end

local card
if KEY_UNLOCKED then
    local ok, obj = pcall(function() return Others_:AddParagraph({ Title = "Form Stats", Content = statsText() }) end)
    card = ok and obj or nil
end

local function refreshStats()
    if card and card.Set then pcall(card.Set, card, statsText()) end
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

------------------------------------------------------------------ Controls
-- Yellow "Key System Mode Only" tag drawn inside the locked control's own row (under its title).
local YELLOW = Color3.fromRGB(255, 190, 70)
local function tagRow(ref)
    if KEY_UNLOCKED or not ref or not ref.Frame then return ref end
    local r = ref.Frame
    r.Size = UDim2.new(1, 0, 0, 56)
    local tl = ref._tl
    if tl then
        tl.Position = UDim2.fromOffset(10, 6)
        tl.Size = UDim2.new(tl.Size.X.Scale, tl.Size.X.Offset, 0, 20)
    end
    local chip = Instance.new("Frame")
    chip.Name = "KeyTag"
    chip.AutomaticSize = Enum.AutomaticSize.X
    chip.Size = UDim2.fromOffset(0, 18)
    chip.Position = UDim2.fromOffset(10, 31)
    chip.BackgroundColor3 = YELLOW
    chip.BackgroundTransparency = 0.82
    local cr = Instance.new("UICorner") cr.CornerRadius = UDim.new(1, 0) cr.Parent = chip
    local st = Instance.new("UIStroke") st.Color = YELLOW st.Transparency = 0.35 st.Parent = chip
    local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 7) pad.PaddingRight = UDim.new(0, 8) pad.Parent = chip
    local lay = Instance.new("UIListLayout")
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.VerticalAlignment = Enum.VerticalAlignment.Center
    lay.Padding = UDim.new(0, 4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = chip
    pcall(function()
        local ic = Library.Icon(chip, "lock", 11, YELLOW)
        ic.LayoutOrder = 0
    end)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.LayoutOrder = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 10
    lbl.TextColor3 = YELLOW
    lbl.Text = "Key System Mode Only"
    lbl.Parent = chip
    pcall(function() Library:_tr(lbl, "Text", "Key System Mode Only") end) -- uses PHLibrary's own language system
    chip.Parent = r
    return ref
end

-- Locked while KEY_UNLOCKED is false: the toggle snaps back off and nothing is applied.
local function KToggle(tab, o, apply)
    local ref
    o.Callback = function(v)
        if not KEY_UNLOCKED then
            if v then
                if ref then pcall(function() ref:Set(false) end) end
                N("Key System Mode Only", nil, "Warning")
            end
            return
        end
        apply(v)
    end
    ref = tab:AddToggle(o)
    tagRow(ref)
    return ref
end

Piano_:AddSection({ Title = "Auto Play" })

-- Auto Tiles: NOT locked
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

Piano_:AddSection({ Title = "Matchmaking" })
KToggle(Piano_, { Title = "Auto Match", Default = false, Flag = "AutoMatch" },
    function(v) S.AutoMatch = v; S.queuedAt = nil end)
local modeDD
modeDD = tagRow(Piano_:AddDropdown({
    Title = "Match Mode", Options = { "1v1", "4 Player" }, Default = "1v1", Flag = "MatchMode",
    Callback = function(v)
        if not KEY_UNLOCKED then
            if v ~= "1v1" and modeDD then pcall(function() modeDD:Set("1v1") end) end
            return
        end
        S.Mode = v; S.queuedAt = nil
    end,
}))

Piano_:AddSection({ Title = "Endless" })
KToggle(Piano_, { Title = "Auto Endless", Default = false, Flag = "AutoEndless" },
    function(v) S.AutoEndless = v; if v then S.endlessBlocked = false end end)

Others_:AddSection({ Title = "Rewards" })
KToggle(Others_, { Title = "Claim Daily Rewards", Default = false, Flag = "ClaimDaily" }, function(v)
    S.AutoDaily = v
    if v then task.spawn(claimTick, true) end
end)
KToggle(Others_, { Title = "Auto Claim Quest", Default = false, Flag = "AutoClaimQuest" }, function(v)
    S.AutoQuest = v
    if v then task.spawn(claimTick, true) end
end)

Hook_:AddSection({ Title = "Discord Webhook" })
local pending = ""
tagRow(Hook_:AddInput({
    Title = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(v) if KEY_UNLOCKED then pending = tostring(v or "") end end, -- no Flag: never written to config files
}))
local function WBtn(o, fn)
    local cb = o.Callback
    o.Callback = function()
        if not KEY_UNLOCKED then N("Key System Mode Only", nil, "Warning") return end
        fn()
    end
    tagRow(Hook_:AddButton(o))
end
WBtn({ Title = "Save", ButtonText = "Save", Icon = "save" }, function()
    local u = validUrl(pending)
    if not u then N("Webhook", "Invalid Discord webhook URL.", "Error") return end
    WH.url = u
    local ok = pcall(function()
        if makefolder and not isfolder("PickasHub") then makefolder("PickasHub") end
        writefile(FILE, u)
    end)
    N("Webhook", ok and "URL saved." or "URL accepted for this session (could not write file).", ok and "Success" or "Warning")
end)
WBtn({ Title = "Start", ButtonText = "Start", Icon = "play" }, function()
    if not WH.url then N("Webhook", "Save a valid URL first.", "Error") return end
    WH.running = true
    N("Webhook", "Notifications started.", "Success")
end)
WBtn({ Title = "Stop", ButtonText = "Stop", Icon = "square" }, function()
    WH.running = false
    WH.queue = {}
    N("Webhook", "Notifications stopped.", "Info")
end)

N("Picka's Hub", "Piano loaded." .. string.format(" Engine: %s | Observer: %s",
    PC and "found" or "NOT found", hooked and "on" or "off"), "Info")
if not langInjected then
    N("Language", "Executor lacks debug.getupvalue: the new texts stay English.", "Warning")
end
