--[[
	Picka's Hub UI Library (single file)

	Usage:
	  local Library = loadstring(game:HttpGet("<raw url of this file>"))()
	  local Window = Library:CreateWindow({ Name = "Picka's Hub", Logo = "zap", Version = "v1.0.0", KeyStatus = "KEY" })
	  local Tab = Window:CreateTab({ Name = "General", Icon = "house" })
	  local Sub = Tab:AddSubtab({ Name = "Main" })
	  local Sec = Sub:AddSection({ Name = "Combat", Icon = "swords" })
	  Sec:AddToggle({ Name = "Auto Farm", Flag = "AutoFarm", Callback = function(v) end })
	  Library:Finish()   -- once, after everything is built

	Set getgenv().PickasUI_Demo = true before loading to open the full component demo.
	Configs/settings are saved as JSON in the executor workspace folder "PickasHub".
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.PickasHubUI and type(env.PickasHubUI.Destroy) == "function" then
	pcall(function()
		env.PickasHubUI:Destroy()
	end)
end

--==================================================================
-- Theme presets
--==================================================================
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local Presets = {}

Presets.Amethyst = {
	Background = rgb(20, 13, 38),
	Background2 = rgb(36, 21, 66),
	Secondary = rgb(26, 17, 48),
	Surface = rgb(35, 25, 62),
	Element = rgb(45, 34, 80),
	Accent = rgb(140, 100, 255),
	AccentDark = rgb(98, 68, 214),
	GradientA = rgb(163, 128, 255),
	GradientB = rgb(112, 84, 240),
	Text = rgb(244, 240, 255),
	Muted = rgb(164, 154, 200),
	Border = rgb(74, 58, 122),
	Stroke = rgb(96, 78, 152),
	Hover = rgb(60, 46, 102),
	Active = rgb(84, 66, 138),
	Disabled = rgb(98, 88, 126),
	Success = rgb(74, 222, 128),
	Warning = rgb(250, 204, 21),
	Error = rgb(248, 113, 113),
	Info = rgb(96, 165, 250),
}

local function derive(overrides)
	local t = {}
	for k, v in pairs(Presets.Amethyst) do
		t[k] = v
	end
	for k, v in pairs(overrides) do
		t[k] = v
	end
	return t
end

Presets.Violet = derive({
	Background = rgb(22, 12, 40), Background2 = rgb(40, 16, 72), Secondary = rgb(28, 15, 52),
	Surface = rgb(40, 24, 70), Element = rgb(52, 32, 90),
	Accent = rgb(168, 85, 247), AccentDark = rgb(126, 34, 206),
	GradientA = rgb(192, 132, 252), GradientB = rgb(147, 51, 234),
	Border = rgb(84, 54, 130), Stroke = rgb(108, 70, 168), Hover = rgb(66, 42, 110), Active = rgb(92, 60, 148),
})

Presets.Rose = derive({
	Background = rgb(34, 14, 28), Background2 = rgb(60, 20, 48), Secondary = rgb(42, 16, 34),
	Surface = rgb(58, 26, 48), Element = rgb(74, 36, 62),
	Accent = rgb(244, 114, 182), AccentDark = rgb(190, 50, 130),
	GradientA = rgb(249, 148, 200), GradientB = rgb(219, 80, 150),
	Muted = rgb(205, 160, 190), Border = rgb(116, 58, 96), Stroke = rgb(146, 76, 120),
	Hover = rgb(92, 44, 76), Active = rgb(120, 60, 100),
})

Presets.Ocean = derive({
	Background = rgb(11, 22, 40), Background2 = rgb(16, 40, 70), Secondary = rgb(14, 27, 48),
	Surface = rgb(22, 42, 72), Element = rgb(30, 54, 90),
	Accent = rgb(56, 189, 248), AccentDark = rgb(2, 132, 199),
	GradientA = rgb(103, 210, 252), GradientB = rgb(14, 150, 222),
	Muted = rgb(150, 176, 208), Border = rgb(48, 80, 124), Stroke = rgb(64, 104, 156),
	Hover = rgb(38, 66, 108), Active = rgb(52, 88, 138), Info = rgb(129, 140, 248),
})

Presets.Emerald = derive({
	Background = rgb(10, 26, 22), Background2 = rgb(14, 44, 36), Secondary = rgb(13, 32, 27),
	Surface = rgb(22, 46, 40), Element = rgb(30, 60, 52),
	Accent = rgb(52, 211, 153), AccentDark = rgb(5, 150, 105),
	GradientA = rgb(110, 231, 183), GradientB = rgb(16, 185, 129),
	Muted = rgb(152, 196, 182), Border = rgb(46, 92, 80), Stroke = rgb(62, 118, 102),
	Hover = rgb(38, 74, 64), Active = rgb(52, 98, 84),
})

--==================================================================
-- Library table
--==================================================================
local Library = {
	Version = "1.0.0",
	IconsURL = "https://raw.githubusercontent.com/pickapicksmm/Pickas-Hub/refs/heads/main/Icons/icons.lua",
	IconPack = "lucide",
	Presets = Presets,
	Flags = {},
	Windows = {},
	Language = "en",
	Translations = {},
	ReduceAnimations = false,
	MaxNotifications = 4,
	OrbTitle = "PICKA'S HUB",
	OrbIcon = "zap",
	ConfigureIcon = "settings",
	_bindings = {},
	_textBindings = {},
	_connections = {},
	_langCallbacks = {},
	_setters = {},
	_keybinds = {},
	_commands = {},
	_notifActive = 0,
	_notifQueue = {},
	_notifOrder = 0,
	_inited = false,
}

Library.Theme = {
	Name = "Amethyst",
	Transparency = 0,
	CornerRadius = 12,
	AnimSpeed = 1,
}
for k, v in pairs(Presets.Amethyst) do
	Library.Theme[k] = v
end

Library.LanguageList = {
	{ Code = "en", Name = "English" }, { Code = "ja", Name = "日本語" }, { Code = "zh", Name = "中文" },
	{ Code = "ko", Name = "한국어" }, { Code = "th", Name = "ไทย" }, { Code = "vi", Name = "Tiếng Việt" },
	{ Code = "tr", Name = "Türkçe" }, { Code = "pt", Name = "Português" }, { Code = "ru", Name = "Русский" },
	{ Code = "pl", Name = "Polski" }, { Code = "hu", Name = "Magyar" }, { Code = "fi", Name = "Suomi" },
	{ Code = "is", Name = "Íslenska" }, { Code = "el", Name = "Ελληνικά" }, { Code = "it", Name = "Italiano" },
	{ Code = "es", Name = "Español" }, { Code = "fr", Name = "Français" }, { Code = "de", Name = "Deutsch" },
	{ Code = "nl", Name = "Nederlands" }, { Code = "id", Name = "Indonesia" }, { Code = "ms", Name = "Melayu" },
	{ Code = "fil", Name = "Filipino" }, { Code = "sv", Name = "Svenska" }, { Code = "no", Name = "Norsk" },
	{ Code = "da", Name = "Dansk" }, { Code = "cs", Name = "Čeština" }, { Code = "sk", Name = "Slovenčina" },
	{ Code = "ro", Name = "Română" }, { Code = "uk", Name = "Українська" }, { Code = "he", Name = "עברית" },
}

local FONT = {
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
}

local LOCK_DARK = rgb(52, 38, 0)

--==================================================================
-- Built-in translations (library strings)
--==================================================================
local BUILTIN_KEYS = {
	"Search...",
	"Close UI?",
	"Are you sure you want to close the UI? You will need to execute the script again.",
	"Yes",
	"No",
	"Locked",
	"Configure",
}

local BUILTIN = {
	ja = { "検索...", "UIを閉じますか？", "UIを閉じてもよろしいですか？再度スクリプトを実行する必要があります。", "はい", "いいえ", "ロック中", "設定" },
	zh = { "搜索...", "关闭界面？", "确定要关闭界面吗？您需要重新执行脚本。", "是", "否", "已锁定", "配置" },
	ko = { "검색...", "UI를 닫을까요?", "UI를 닫으시겠습니까? 스크립트를 다시 실행해야 합니다.", "예", "아니요", "잠김", "설정" },
	th = { "ค้นหา...", "ปิด UI?", "คุณแน่ใจหรือไม่ว่าต้องการปิด UI? คุณต้องรันสคริปต์ใหม่อีกครั้ง", "ใช่", "ไม่", "ล็อก", "ตั้งค่า" },
	vi = { "Tìm kiếm...", "Đóng giao diện?", "Bạn có chắc muốn đóng giao diện? Bạn sẽ cần chạy lại script.", "Có", "Không", "Đã khóa", "Cấu hình" },
	tr = { "Ara...", "Arayüz kapatılsın mı?", "Arayüzü kapatmak istediğinizden emin misiniz? Betiği yeniden çalıştırmanız gerekecek.", "Evet", "Hayır", "Kilitli", "Yapılandır" },
	pt = { "Pesquisar...", "Fechar a interface?", "Tem certeza de que deseja fechar a interface? Você precisará executar o script novamente.", "Sim", "Não", "Bloqueado", "Configurar" },
	ru = { "Поиск...", "Закрыть интерфейс?", "Вы уверены, что хотите закрыть интерфейс? Скрипт придётся запустить заново.", "Да", "Нет", "Заблокировано", "Настройки" },
	pl = { "Szukaj...", "Zamknąć interfejs?", "Czy na pewno chcesz zamknąć interfejs? Trzeba będzie ponownie uruchomić skrypt.", "Tak", "Nie", "Zablokowane", "Konfiguracja" },
	hu = { "Keresés...", "Bezárja a felületet?", "Biztosan bezárja a felületet? Újra kell futtatnia a szkriptet.", "Igen", "Nem", "Zárolva", "Beállítások" },
	fi = { "Haku...", "Suljetaanko käyttöliittymä?", "Haluatko varmasti sulkea käyttöliittymän? Skripti täytyy suorittaa uudelleen.", "Kyllä", "Ei", "Lukittu", "Asetukset" },
	is = { "Leita...", "Loka viðmóti?", "Ertu viss um að þú viljir loka viðmótinu? Þú þarft að keyra forskriftina aftur.", "Já", "Nei", "Læst", "Stillingar" },
	el = { "Αναζήτηση...", "Κλείσιμο διεπαφής;", "Είστε βέβαιοι ότι θέλετε να κλείσετε τη διεπαφή; Θα χρειαστεί να εκτελέσετε ξανά το σενάριο.", "Ναι", "Όχι", "Κλειδωμένο", "Ρυθμίσεις" },
	it = { "Cerca...", "Chiudere l'interfaccia?", "Sei sicuro di voler chiudere l'interfaccia? Dovrai eseguire di nuovo lo script.", "Sì", "No", "Bloccato", "Configura" },
	es = { "Buscar...", "¿Cerrar la interfaz?", "¿Seguro que quieres cerrar la interfaz? Tendrás que ejecutar el script de nuevo.", "Sí", "No", "Bloqueado", "Configurar" },
	fr = { "Rechercher...", "Fermer l'interface ?", "Voulez-vous vraiment fermer l'interface ? Vous devrez exécuter à nouveau le script.", "Oui", "Non", "Verrouillé", "Configurer" },
	de = { "Suchen...", "Oberfläche schließen?", "Möchtest du die Oberfläche wirklich schließen? Du musst das Skript erneut ausführen.", "Ja", "Nein", "Gesperrt", "Konfigurieren" },
	nl = { "Zoeken...", "Interface sluiten?", "Weet je zeker dat je de interface wilt sluiten? Je moet het script opnieuw uitvoeren.", "Ja", "Nee", "Vergrendeld", "Configureren" },
	id = { "Cari...", "Tutup UI?", "Yakin ingin menutup UI? Anda perlu menjalankan skrip lagi.", "Ya", "Tidak", "Terkunci", "Konfigurasi" },
	ms = { "Cari...", "Tutup UI?", "Adakah anda pasti mahu menutup UI? Anda perlu menjalankan skrip sekali lagi.", "Ya", "Tidak", "Dikunci", "Konfigurasi" },
	fil = { "Maghanap...", "Isara ang UI?", "Sigurado ka bang isasara ang UI? Kailangan mong patakbuhin muli ang script.", "Oo", "Hindi", "Naka-lock", "I-configure" },
	sv = { "Sök...", "Stäng gränssnittet?", "Vill du verkligen stänga gränssnittet? Du måste köra skriptet igen.", "Ja", "Nej", "Låst", "Konfigurera" },
	no = { "Søk...", "Lukke grensesnittet?", "Er du sikker på at du vil lukke grensesnittet? Du må kjøre skriptet på nytt.", "Ja", "Nei", "Låst", "Konfigurer" },
	da = { "Søg...", "Luk grænsefladen?", "Er du sikker på, at du vil lukke grænsefladen? Du skal køre scriptet igen.", "Ja", "Nej", "Låst", "Konfigurer" },
	cs = { "Hledat...", "Zavřít rozhraní?", "Opravdu chcete rozhraní zavřít? Skript budete muset spustit znovu.", "Ano", "Ne", "Uzamčeno", "Nastavení" },
	sk = { "Hľadať...", "Zavrieť rozhranie?", "Naozaj chcete zavrieť rozhranie? Skript budete musieť spustiť znova.", "Áno", "Nie", "Uzamknuté", "Nastavenia" },
	ro = { "Căutare...", "Închizi interfața?", "Ești sigur că vrei să închizi interfața? Va trebui să rulezi din nou scriptul.", "Da", "Nu", "Blocat", "Configurare" },
	uk = { "Пошук...", "Закрити інтерфейс?", "Ви впевнені, що хочете закрити інтерфейс? Скрипт доведеться запустити знову.", "Так", "Ні", "Заблоковано", "Налаштування" },
	he = { "חיפוש...", "לסגור את הממשק?", "האם אתה בטוח שברצונך לסגור את הממשק? יהיה עליך להריץ את הסקריפט שוב.", "כן", "לא", "נעול", "הגדרות" },
}

for code, list in pairs(BUILTIN) do
	local t = {}
	for i, key in ipairs(BUILTIN_KEYS) do
		t[key] = list[i]
	end
	Library.Translations[code] = t
end

--==================================================================
-- Helpers
--==================================================================
local function new(class, props, children)
	local inst = Instance.new(class)
	local parent
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function merge(a, b)
	if b then
		for k, v in pairs(b) do
			a[k] = v
		end
	end
	return a
end

local function dur(t)
	if Library.ReduceAnimations then
		return 0.01
	end
	return t / math.max(Library.Theme.AnimSpeed or 1, 0.1)
end

local function tween(inst, t, props, style, dir)
	local tw = TweenService:Create(
		inst,
		TweenInfo.new(dur(t), style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Library._connections, c)
	return c
end

local function getViewport()
	local cam = workspace.CurrentCamera
	if cam and cam.ViewportSize.X > 100 then
		return cam.ViewportSize
	end
	return Vector2.new(1280, 720)
end

local function fire(cb, ...)
	if type(cb) ~= "function" then
		return
	end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(cb, table.unpack(args, 1, args.n))
		if not ok then
			warn("[PickasUI] callback error: " .. tostring(err))
		end
	end)
end

local function parseOpts(opts)
	if type(opts) == "string" then
		return { Name = opts }
	end
	return opts or {}
end

local function firstValue(t)
	for _, v in pairs(t) do
		return v
	end
	return ""
end

--==================================================================
-- Theme binding
--==================================================================
function Library:Bind(inst, prop, source)
	local function get()
		if type(source) == "function" then
			return source(self.Theme)
		end
		return self.Theme[source]
	end
	local v = get()
	if v ~= nil then
		inst[prop] = v
	end
	table.insert(self._bindings, { inst = inst, prop = prop, get = get })
end

function Library:BindCorner(corner, mult)
	self:Bind(corner, "CornerRadius", function(t)
		return UDim.new(0, math.floor(t.CornerRadius * (mult or 1)))
	end)
end

local TWEENABLE = { Color3 = true, number = true, UDim = true, UDim2 = true }

function Library:_ApplyTheme()
	local keep = {}
	for _, b in ipairs(self._bindings) do
		local inst = b.inst
		if inst and inst.Parent ~= nil then
			local ok, v = pcall(b.get)
			if ok and v ~= nil then
				if TWEENABLE[typeof(v)] then
					tween(inst, 0.25, { [b.prop] = v }, Enum.EasingStyle.Sine)
				else
					pcall(function()
						inst[b.prop] = v
					end)
				end
			end
			keep[#keep + 1] = b
		end
	end
	self._bindings = keep
end

function Library:SetTheme(t)
	if type(t) == "string" then
		local p = self.Presets[t]
		if not p then
			return false
		end
		for k, v in pairs(p) do
			self.Theme[k] = v
		end
		self.Theme.Name = t
	elseif type(t) == "table" then
		for k, v in pairs(t) do
			self.Theme[k] = v
		end
	else
		return false
	end
	self:_ApplyTheme()
	return true
end

function Library:SetThemeValue(key, value)
	self.Theme[key] = value
	self:_ApplyTheme()
end

function Library:SetReduceAnimations(state)
	self.ReduceAnimations = state and true or false
end

function Library:SetAnimationSpeed(speed)
	self.Theme.AnimSpeed = math.clamp(tonumber(speed) or 1, 0.25, 4)
end

--==================================================================
-- Translations
--==================================================================
local function resolveText(raw, lang)
	if type(raw) == "table" then
		return raw[lang] or raw.en or raw[1] or firstValue(raw)
	end
	raw = tostring(raw == nil and "" or raw)
	local tr = Library.Translations[lang]
	if tr and tr[raw] then
		return tr[raw]
	end
	return raw
end

function Library:Translate(raw)
	return resolveText(raw, self.Language)
end

function Library:BindText(inst, raw, prop)
	prop = prop or "Text"
	local entry = { inst = inst, prop = prop, raw = raw }
	inst[prop] = resolveText(raw, self.Language)
	table.insert(self._textBindings, entry)
	return entry
end

function Library:SetBoundText(entry, raw)
	if not entry then
		return
	end
	entry.raw = raw
	if entry.inst then
		entry.inst[entry.prop] = resolveText(raw, self.Language)
	end
end

function Library:AddTranslations(tbl)
	for lang, map in pairs(tbl or {}) do
		self.Translations[lang] = self.Translations[lang] or {}
		for k, v in pairs(map) do
			self.Translations[lang][k] = v
		end
	end
	self:_RefreshText()
end

function Library:_RefreshText()
	local keep = {}
	for _, e in ipairs(self._textBindings) do
		if e.inst and e.inst.Parent ~= nil then
			e.inst[e.prop] = resolveText(e.raw, self.Language)
			keep[#keep + 1] = e
		end
	end
	self._textBindings = keep
end

function Library:SetLanguage(code)
	local valid = false
	for _, l in ipairs(self.LanguageList) do
		if l.Code == code then
			valid = true
		end
	end
	if not valid then
		return false
	end
	self.Language = code
	self:_RefreshText()
	for _, cb in ipairs(self._langCallbacks) do
		fire(cb, code)
	end
	return true
end

function Library:OnLanguageChanged(cb)
	table.insert(self._langCallbacks, cb)
end

--==================================================================
-- Icons
--==================================================================
local function iconAsset(lib, name)
	if name == nil or name == false then
		return nil
	end
	if type(name) == "number" then
		return "rbxassetid://" .. tostring(name)
	end
	if type(name) ~= "string" then
		return nil
	end
	if lib.CustomIcons and lib.CustomIcons[name] then
		return lib.CustomIcons[name]
	end
	if name:match("^%d+$") then
		return "rbxassetid://" .. name
	end
	if name:find("rbxassetid://", 1, true) or name:find("rbxasset://", 1, true) then
		return name
	end
	local mod = lib.IconModule
	if mod then
		local ok, res = pcall(function()
			return mod.GetIcon(name, lib.IconPack)
		end)
		if ok and type(res) == "string" then
			return res
		end
	end
	return nil
end

function Library:_LoadIcons()
	if self.IconModule then
		return
	end
	local ok, mod = pcall(function()
		return loadstring(game:HttpGet(self.IconsURL))()
	end)
	if ok and type(mod) == "table" then
		self.IconModule = mod
		pcall(function()
			mod.SetDefault(self.IconPack)
			mod.Load(self.IconPack)
		end)
	else
		warn("[PickasUI] icon module failed to load, icons will be hidden")
	end
end

function Library:SetIconPack(name)
	self.IconPack = name
	if self.IconModule then
		pcall(function()
			self.IconModule.SetDefault(name)
		end)
	end
end

function Library:GetIcon(name)
	return iconAsset(self, name)
end

function Library:Icon(parent, name, size, colorKey)
	local asset = iconAsset(self, name)
	local img = new("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Image = asset or "",
		Visible = asset ~= nil,
		ScaleType = Enum.ScaleType.Fit,
		Parent = parent,
	})
	if colorKey then
		self:Bind(img, "ImageColor3", colorKey)
	end
	return img
end

--==================================================================
-- Interaction helpers
--==================================================================
local function makeDraggable(handle, target, onMove)
	local state = { moved = false }
	local dragging, startPointer, startPos = false, nil, nil
	connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			state.moved = false
			startPointer = input.Position
			startPos = target.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if conn then
						conn:Disconnect()
					end
				end
			end)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - startPointer
			if delta.Magnitude > 5 then
				state.moved = true
			end
			if not state.moved then
				return
			end
			local vp = getViewport()
			local size = target.AbsoluteSize
			local ap = target.AnchorPoint
			local nx = math.clamp(startPos.X.Offset + delta.X, ap.X * size.X, vp.X - (1 - ap.X) * size.X)
			local ny = math.clamp(startPos.Y.Offset + delta.Y, ap.Y * size.Y, vp.Y - (1 - ap.Y) * size.Y)
			target.Position = UDim2.fromOffset(nx, ny)
			if onMove then
				onMove()
			end
		end
	end)
	return state
end

local function ripple(container)
	local m = UserInputService:GetMouseLocation()
	local ap, as = container.AbsolutePosition, container.AbsoluteSize
	local x, y = m.X - ap.X, m.Y - ap.Y
	if x < 0 or y < 0 or x > as.X or y > as.Y then
		x, y = as.X / 2, as.Y / 2
	end
	local d = math.max(as.X, as.Y) * 2.4
	local r = new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(0, 0),
		ZIndex = 3,
		Parent = container,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = r })
	tween(r, 0.45, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 })
	task.delay(dur(0.45) + 0.05, function()
		r:Destroy()
	end)
end

--==================================================================
-- Init: gui, tooltip, notifications, orb
--==================================================================
local function getGuiParent()
	local ok, ui = pcall(function()
		return gethui and gethui()
	end)
	if ok and ui then
		return ui
	end
	ok, ui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and ui then
		return ui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

function Library:Init(opts)
	if self._inited then
		return self
	end
	opts = opts or {}
	self._inited = true

	if opts.Theme then
		self:SetTheme(opts.Theme)
	end
	if opts.Language then
		self.Language = opts.Language
	end
	if opts.IconPack then
		self.IconPack = opts.IconPack
	end
	if opts.ReduceAnimations ~= nil then
		self.ReduceAnimations = opts.ReduceAnimations
	end
	self.OrbTitle = opts.OrbTitle or self.OrbTitle
	self.OrbIcon = opts.OrbIcon or self.OrbIcon
	self.ConfigureIcon = opts.ConfigureIcon or self.ConfigureIcon

	self:_LoadIcons()

	local gui = new("ScreenGui", {
		Name = "PickasHubUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
	})
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	gui.Parent = getGuiParent()
	self.Gui = gui

	self:_BuildTooltip()
	self:_BuildNotifications()
	self:_BuildOrb()

	env.PickasHubUI = self
	return self
end

function Library:Destroy()
	for _, c in ipairs(self._connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	self._connections = {}
	self._bindings = {}
	self._textBindings = {}
	self.Windows = {}
	self._notifQueue = {}
	if self.Gui then
		self.Gui:Destroy()
		self.Gui = nil
	end
	self._inited = false
	if env.PickasHubUI == self then
		env.PickasHubUI = nil
	end
end

--==================================================================
-- Tooltip
--==================================================================
function Library:_BuildTooltip()
	local tip = new("Frame", {
		Name = "Tooltip",
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		ZIndex = 90,
		Parent = self.Gui,
	})
	self:Bind(tip, "BackgroundColor3", "Surface")
	local c = new("UICorner", { Parent = tip })
	self:BindCorner(c, 0.5)
	local s = new("UIStroke", { Thickness = 1, Parent = tip })
	self:Bind(s, "Color", "Stroke")
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
		PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = tip,
	})
	new("UISizeConstraint", { MaxSize = Vector2.new(240, 400), Parent = tip })
	local lbl = new("TextLabel", {
		BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
		Font = FONT.Medium, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "", Parent = tip,
	})
	self:Bind(lbl, "TextColor3", "Text")
	self._tip = tip
	self._tipLabel = lbl
	self._tipEntry = nil

	connect(UserInputService.InputChanged, function(input)
		if tip.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
			local m = UserInputService:GetMouseLocation()
			local vp = getViewport()
			local x = math.min(m.X + 14, vp.X - tip.AbsoluteSize.X - 6)
			local y = math.min(m.Y + 16, vp.Y - tip.AbsoluteSize.Y - 6)
			tip.Position = UDim2.fromOffset(x, y)
		end
	end)
end

function Library:_BindTooltip(guiObj, raw)
	if not raw then
		return
	end
	guiObj.MouseEnter:Connect(function()
		if self._tipEntry then
			self._tipEntry.raw = raw
		end
		self._tipLabel.Text = resolveText(raw, self.Language)
		local m = UserInputService:GetMouseLocation()
		self._tip.Position = UDim2.fromOffset(m.X + 14, m.Y + 16)
		self._tip.Visible = true
	end)
	guiObj.MouseLeave:Connect(function()
		self._tip.Visible = false
	end)
end

--==================================================================
-- Notifications
--==================================================================
local NOTIFY_TYPES = {
	Info = { key = "Info", icon = "info" },
	Success = { key = "Success", icon = "circle-check" },
	Warning = { key = "Warning", icon = "triangle-alert" },
	Error = { key = "Error", icon = "circle-x" },
	Loading = { key = "Accent", icon = "loader-circle" },
}

function Library:_BuildNotifications()
	local holder = new("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14, 1, -14),
		Size = UDim2.new(0, 300, 1, -28),
		ZIndex = 80,
		Parent = self.Gui,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = holder,
	})
	self._notifHolder = holder
end

function Library:_NextNotification()
	while #self._notifQueue > 0 do
		local n = table.remove(self._notifQueue, 1)
		if not n.Closed then
			self:_ShowNotification(n)
			return
		end
	end
end

function Library:Notify(opts)
	if not self._inited then
		self:Init()
	end
	if type(opts) == "string" then
		opts = { Description = opts }
	end
	opts = opts or {}
	local lib = self
	local n = { Opts = opts, Closed = false, Shown = false }
	function n:Close()
		self.Closed = true
		if self._close then
			self._close()
		end
	end
	function n:Update(newOpts)
		if self._update then
			self._update(newOpts or {})
		else
			merge(self.Opts, newOpts)
		end
	end
	if self._notifActive < self.MaxNotifications then
		self:_ShowNotification(n)
	else
		table.insert(lib._notifQueue, n)
	end
	return n
end

function Library:_ShowNotification(n)
	local lib = self
	self._notifActive = self._notifActive + 1
	n.Shown = true
	self._notifOrder = self._notifOrder + 1
	local o = n.Opts

	local typeName = NOTIFY_TYPES[o.Type or "Info"] and (o.Type or "Info") or "Info"
	local typeInfo = NOTIFY_TYPES[typeName]

	local wrapper = new("Frame", {
		Name = "Notification",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._notifOrder,
		Parent = self._notifHolder,
	})
	local card = new("Frame", {
		Name = "Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(340, 0),
		ClipsDescendants = true,
		Parent = wrapper,
	})
	self:Bind(card, "BackgroundColor3", "Surface")
	local cc = new("UICorner", { Parent = card })
	self:BindCorner(cc, 0.85)
	local cs = new("UIStroke", { Thickness = 1, Transparency = 0.2, Parent = card })
	self:Bind(cs, "Color", "Border")

	local bar = new("Frame", { Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, Parent = card })
	self:Bind(bar, "BackgroundColor3", function(t)
		return t[typeInfo.key]
	end)

	local icon = new("ImageLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(16, 12),
		ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0, 0), Parent = card,
	})
	self:Bind(icon, "ImageColor3", function(t)
		return t[typeInfo.key]
	end)

	local body = new("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -78, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, Parent = card,
	})
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
	new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 15), Parent = body })

	local title = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT.Bold, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1, Parent = body,
	})
	self:Bind(title, "TextColor3", "Text")
	local titleEntry = self:BindText(title, o.Title or typeName)

	local desc = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT.Regular, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2, Visible = (o.Description ~= nil), Parent = body,
	})
	self:Bind(desc, "TextColor3", "Muted")
	local descEntry = self:BindText(desc, o.Description or "")

	local closeBtn = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Parent = card,
	})
	local closeIcon = self:Icon(closeBtn, "x", 14, "Muted")
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)

	local track = new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3),
		BorderSizePixel = 0, Parent = card,
	})
	local fill = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, BackgroundTransparency = 0.2, Parent = track })
	self:Bind(fill, "BackgroundColor3", function(t)
		return t[typeInfo.key]
	end)

	local spin
	local token = 0
	local closed = false

	local function setType(name)
		typeName = NOTIFY_TYPES[name] and name or "Info"
		typeInfo = NOTIFY_TYPES[typeName]
		icon.Image = iconAsset(lib, n.Opts.Icon or typeInfo.icon) or ""
		icon.Visible = icon.Image ~= ""
		if spin then
			spin:Cancel()
			spin = nil
			icon.Rotation = 0
		end
		if typeName == "Loading" and not lib.ReduceAnimations then
			spin = TweenService:Create(icon, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })
			spin:Play()
		end
		for _, b in ipairs(lib._bindings) do
			if b.inst == bar or b.inst == icon or b.inst == fill then
				b.get = function()
					return lib.Theme[typeInfo.key]
				end
			end
		end
		bar.BackgroundColor3 = lib.Theme[typeInfo.key]
		icon.ImageColor3 = lib.Theme[typeInfo.key]
		fill.BackgroundColor3 = lib.Theme[typeInfo.key]
	end

	local function close()
		if closed then
			return
		end
		closed = true
		if spin then
			spin:Cancel()
		end
		tween(card, 0.25, { Position = UDim2.fromOffset(340, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(dur(0.25), function()
			if not wrapper.Parent then
				return
			end
			local h = wrapper.AbsoluteSize.Y
			wrapper.AutomaticSize = Enum.AutomaticSize.None
			wrapper.Size = UDim2.new(1, 0, 0, h)
			tween(wrapper, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(dur(0.2) + 0.02, function()
				wrapper:Destroy()
				lib._notifActive = math.max(0, lib._notifActive - 1)
				lib:_NextNotification()
			end)
		end)
	end

	local function startTimer(duration)
		token = token + 1
		local my = token
		fill.Size = UDim2.new(1, 0, 1, 0)
		if not duration or duration <= 0 then
			track.Visible = false
			return
		end
		track.Visible = true
		TweenService:Create(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()
		task.delay(duration, function()
			if my == token then
				close()
			end
		end)
	end

	setType(typeName)
	local duration = o.Duration
	if duration == nil then
		duration = (typeName == "Loading") and 0 or 4
	end
	startTimer(duration)

	connect(closeBtn.Activated, close)
	n._close = close
	n._update = function(new)
		merge(n.Opts, new)
		if new.Title ~= nil then
			lib:SetBoundText(titleEntry, new.Title)
		end
		if new.Description ~= nil then
			desc.Visible = true
			lib:SetBoundText(descEntry, new.Description)
		end
		if new.Type ~= nil then
			setType(new.Type)
		end
		if new.Duration ~= nil or new.Type ~= nil then
			local d = new.Duration
			if d == nil then
				d = (typeName == "Loading") and 0 or 4
			end
			startTimer(d)
		end
	end

	tween(card, 0.4, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

--==================================================================
-- Lock system (works on any frame-based element)
--==================================================================
function Library:_AttachLock(obj, frame, opts, radiusMult)
	opts = opts or {}
	local lib = self
	local overlay = new("TextButton", {
		Name = "Lock",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
		Visible = false,
		Parent = frame,
	})
	local oc = new("UICorner", { Parent = overlay })
	self:BindCorner(oc, radiusMult or 0.6)

	local tag = new("Frame", {
		Name = "Tag",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 21,
		Parent = overlay,
	})
	self:Bind(tag, "BackgroundColor3", "Warning")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = tag })
	new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 10), Parent = tag })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tag,
	})
	local li = self:Icon(tag, "lock", 12, nil)
	li.ImageColor3 = LOCK_DARK
	li.LayoutOrder = 1
	li.ZIndex = 22
	local tl = new("TextLabel", {
		BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22),
		Font = FONT.Bold, TextSize = 11, TextColor3 = LOCK_DARK, LayoutOrder = 2, ZIndex = 22, Parent = tag,
	})
	local tagEntry = self:BindText(tl, opts.LockTag or "Locked")

	obj.Locked = false
	obj._lockMessage = opts.LockMessage
	obj._frame = frame
	if self._lastIndex and self._lastIndex.Row == frame then
		self._lastIndex.Obj = obj
	end
	local lastNotify = 0

	function obj:SetLocked(state, tagText, message)
		self.Locked = state and true or false
		if tagText ~= nil then
			lib:SetBoundText(tagEntry, tagText)
		end
		if message ~= nil then
			self._lockMessage = message
		end
		if self.Locked then
			overlay.Visible = true
			tween(overlay, 0.25, { BackgroundTransparency = 0.45 })
		else
			tween(overlay, 0.2, { BackgroundTransparency = 1 })
			task.delay(dur(0.2), function()
				if not obj.Locked and overlay.Parent then
					overlay.Visible = false
				end
			end)
		end
	end

	function obj:Lock(tagText, message)
		self:SetLocked(true, tagText, message)
	end

	function obj:Unlock()
		self:SetLocked(false)
	end

	overlay.Activated:Connect(function()
		task.spawn(function()
			for _, dx in ipairs({ 6, -6, 4, -4, 0 }) do
				tween(tag, 0.04, { Position = UDim2.new(0.5, dx, 0.5, 0) }, Enum.EasingStyle.Sine)
				task.wait(dur(0.045))
			end
		end)
		if tick() - lastNotify > 1 then
			lastNotify = tick()
			lib:Notify({
				Title = "Locked",
				Description = obj._lockMessage or "Locked",
				Type = "Warning",
				Duration = 3,
			})
		end
	end)

	if opts.Locked then
		obj:SetLocked(true, opts.LockTag, opts.LockMessage)
	end
end

--==================================================================
-- Orb (floating button) and menu
--==================================================================
function Library:_AnyWindowVisible()
	for _, w in ipairs(self.Windows) do
		if w.Visible then
			return true
		end
	end
	return false
end

function Library:_FindWindow(kind)
	for _, w in ipairs(self.Windows) do
		if w.Kind == kind then
			return w
		end
	end
	return nil
end

function Library:_BuildOrb()
	local lib = self
	local vp = getViewport()
	local orb = new("TextButton", {
		Name = "Orb",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(44, 44),
		Position = UDim2.fromOffset(math.floor(vp.X / 2 - 22), 14),
		ZIndex = 50,
		Parent = self.Gui,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = orb })
	local og = new("UIGradient", { Rotation = 45, Parent = orb })
	self:Bind(og, "Color", function(t)
		return ColorSequence.new(t.GradientA, t.GradientB)
	end)
	local stroke = new("UIStroke", { Thickness = 2, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = orb })
	self:Bind(stroke, "Color", "Accent")
	local scale = new("UIScale", { Scale = 1, Parent = orb })

	local icon = self:Icon(orb, self.OrbIcon, 22, "Text")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.ZIndex = 51
	if not icon.Visible then
		local fb = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "⚡", TextSize = 20,
			Font = FONT.Bold, ZIndex = 51, Parent = orb,
		})
		self:Bind(fb, "TextColor3", "Text")
	end

	if not self.ReduceAnimations then
		TweenService:Create(stroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Thickness = 5, Transparency = 0.85,
		}):Play()
	end

	local backdrop = new("TextButton", {
		Name = "OrbBackdrop", Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1), ZIndex = 40, Visible = false, Parent = self.Gui,
	})

	-- Liquid capsule: the orb stays as one end, the capsule stretches out with an overshoot and the choices appear inside
	local ITEM_H, MAIN_W, CFG_W, GAP = 34, 132, 34, 6
	local capsule = new("CanvasGroup", {
		Name = "OrbMenu", BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromOffset(44, 44), Visible = false, ZIndex = 44, Parent = self.Gui,
	})
	self:Bind(capsule, "BackgroundColor3", "Surface")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = capsule })
	local capStroke = new("UIStroke", { Thickness = 1.5, Transparency = 0.2, Parent = capsule })
	self:Bind(capStroke, "Color", "Accent")

	local function makeMenuItem(w, h)
		local g = new("CanvasGroup", {
			BackgroundTransparency = 1, Size = UDim2.fromOffset(w, h), GroupTransparency = 1, ZIndex = 45, Parent = capsule,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = g })
		new("UIScale", { Scale = 0.6, Parent = g })
		local fill = new("Frame", {
			Name = "Fill", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 45, Parent = g,
		})
		local btn = new("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 47, Parent = g,
		})
		return g, btn, fill
	end

	local mainItem, mainBtn, mainFill = makeMenuItem(MAIN_W, ITEM_H)
	local mg = new("UIGradient", { Rotation = 0, Parent = mainFill })
	self:Bind(mg, "Color", function(t)
		return ColorSequence.new(t.GradientA, t.GradientB)
	end)
	local mt = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = FONT.Bold, TextSize = 12, ZIndex = 48, Parent = mainBtn,
	})
	mt.TextColor3 = Color3.new(1, 1, 1)
	self:BindText(mt, self.OrbTitle)

	local cfgItem, cfgBtn, cfgFill = makeMenuItem(CFG_W, ITEM_H)
	self:Bind(cfgFill, "BackgroundColor3", "Element")
	local ci = self:Icon(cfgBtn, self.ConfigureIcon, 18, "Accent")
	ci.AnchorPoint = Vector2.new(0.5, 0.5)
	ci.Position = UDim2.fromScale(0.5, 0.5)
	ci.ZIndex = 48
	for _, pair in ipairs({ { mainItem, mainBtn }, { cfgItem, cfgBtn } }) do
		local item, btn = pair[1], pair[2]
		local isc = item:FindFirstChildOfClass("UIScale")
		connect(btn.MouseEnter, function()
			tween(isc, 0.18, { Scale = 1.06 }, Enum.EasingStyle.Back)
		end)
		connect(btn.MouseLeave, function()
			tween(isc, 0.18, { Scale = 1 })
		end)
		connect(btn.MouseButton1Down, function()
			tween(isc, 0.08, { Scale = 0.93 })
		end)
		connect(btn.MouseButton1Up, function()
			tween(isc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
	end

	local Orb = { MenuOpen = false, Frame = orb, Icon = icon, MainItem = mainItem, CfgItem = cfgItem, Stroke = stroke, Capsule = capsule }
	self.Orb = Orb

	local function itemIn(item, x, delayT)
		local sc = item:FindFirstChildOfClass("UIScale")
		item.Position = UDim2.fromOffset(x - 14, (44 - ITEM_H) / 2)
		sc.Scale = 0.6
		item.GroupTransparency = 1
		task.delay(dur(delayT), function()
			if not Orb.MenuOpen then
				return
			end
			tween(item, 0.45, { Position = UDim2.fromOffset(x, (44 - ITEM_H) / 2) }, Enum.EasingStyle.Back)
			tween(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
			tween(item, 0.22, { GroupTransparency = 0 })
		end)
	end

	function Orb:OpenMenu()
		if self.MenuOpen then
			return
		end
		self.MenuOpen = true
		backdrop.Visible = true
		local d = orb.Size.X.Offset
		local p = orb.AbsolutePosition
		local right = (p.X + d / 2) < getViewport().X / 2
		local W = d + GAP + MAIN_W + GAP + CFG_W + GAP
		capsule.AnchorPoint = Vector2.new(right and 0 or 1, 0.5)
		capsule.Position = UDim2.fromOffset(right and p.X or (p.X + d), p.Y + d / 2)
		capsule.Size = UDim2.fromOffset(d, d)
		capsule.Visible = true
		-- stretch with an overshoot (liquid feel) while the bolt spins
		tween(capsule, 0.6, { Size = UDim2.fromOffset(W, d) }, Enum.EasingStyle.Back)
		tween(icon, 0.5, { Rotation = 180 }, Enum.EasingStyle.Back)
		if right then
			itemIn(mainItem, d + GAP, 0.12)
			itemIn(cfgItem, d + GAP + MAIN_W + GAP, 0.2)
		else
			itemIn(cfgItem, GAP, 0.12)
			itemIn(mainItem, GAP + CFG_W + GAP, 0.2)
		end
	end

	function Orb:CloseMenu()
		if not self.MenuOpen then
			return
		end
		self.MenuOpen = false
		backdrop.Visible = false
		for _, item in ipairs({ mainItem, cfgItem }) do
			tween(item, 0.14, { GroupTransparency = 1 })
			tween(item:FindFirstChildOfClass("UIScale"), 0.16, { Scale = 0.7 })
		end
		local d = orb.Size.X.Offset
		tween(icon, 0.4, { Rotation = 0 }, Enum.EasingStyle.Back)
		tween(capsule, 0.38, { Size = UDim2.fromOffset(d, d) }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		task.delay(dur(0.4), function()
			if not Orb.MenuOpen and capsule.Parent then
				capsule.Visible = false
			end
		end)
	end

	local drag = makeDraggable(orb, orb, function()
		if Orb.MenuOpen then
			Orb:CloseMenu()
		end
	end)

	connect(orb.MouseEnter, function()
		tween(scale, 0.15, { Scale = 1.08 }, Enum.EasingStyle.Back)
	end)
	connect(orb.MouseLeave, function()
		tween(scale, 0.15, { Scale = 1 })
	end)
	connect(orb.MouseButton1Down, function()
		tween(scale, 0.1, { Scale = 0.92 })
	end)
	connect(orb.MouseButton1Up, function()
		tween(scale, 0.15, { Scale = 1.08 }, Enum.EasingStyle.Back)
	end)

	connect(orb.Activated, function()
		if drag.moved then
			return
		end
		if lib:_AnyWindowVisible() then
			for _, w in ipairs(lib.Windows) do
				w:Hide()
			end
			return
		end
		if Orb.MenuOpen then
			Orb:CloseMenu()
		else
			Orb:OpenMenu()
		end
	end)
	connect(backdrop.Activated, function()
		Orb:CloseMenu()
	end)

	local function openKind(kind)
		Orb:CloseMenu()
		local w = lib:_FindWindow(kind)
		if w then
			for _, other in ipairs(lib.Windows) do
				if other ~= w then
					other:Hide()
				end
			end
			w:Show()
		else
			lib:Notify({
				Title = kind == "Configure" and "Configure" or "Window",
				Description = "This panel is not available yet.",
				Type = "Info",
			})
		end
	end

	connect(mainBtn.Activated, function()
		openKind("Main")
	end)
	connect(cfgBtn.Activated, function()
		openKind("Configure")
	end)
end

--==================================================================
-- Classes
--==================================================================
local WindowClass = {}
WindowClass.__index = WindowClass

local PageClass = {}
PageClass.__index = PageClass

local TabClass = setmetatable({}, { __index = PageClass })
TabClass.__index = TabClass

local SubtabClass = setmetatable({}, { __index = PageClass })
SubtabClass.__index = SubtabClass

local SectionClass = {}
SectionClass.__index = SectionClass

--==================================================================
-- Window
--==================================================================
function Library:CreateWindow(opts)
	opts = opts or {}
	self:Init(opts)
	local lib = self

	local vp = getViewport()
	local width = math.min(opts.Width or 640, vp.X - 24)
	local height = math.min(opts.Height or 400, vp.Y - 24)

	local win = setmetatable({
		Library = self,
		Kind = opts.Kind or "Main",
		Tabs = {},
		Visible = false,
		ActiveTab = nil,
		CurrentPage = nil,
		SidebarCollapsed = false,
		SearchQuery = "",
		Width = width,
		Height = height,
	}, WindowClass)

	local root = new("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(math.floor(vp.X / 2), math.floor(vp.Y / 2)),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = Color3.new(1, 1, 1),
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 5,
		Parent = self.Gui,
	})
	root.BackgroundTransparency = 1
	-- the gradient lives on its own frame: a UIGradient on a CanvasGroup would tint every child
	local bgFill = new("Frame", {
		Name = "Fill", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 0, Parent = root,
	})
	self:Bind(bgFill, "BackgroundTransparency", function(t)
		return math.clamp(t.Transparency, 0, 1)
	end)
	local rg = new("UIGradient", { Rotation = 120, Parent = bgFill })
	self:Bind(rg, "Color", function(t)
		return ColorSequence.new(t.Background, t.Background2)
	end)
	local rc = new("UICorner", { Parent = root })
	self:BindCorner(rc, 1.2)
	local rs = new("UIStroke", { Thickness = 1, Transparency = 0.15, Parent = root })
	self:Bind(rs, "Color", "Stroke")
	local rscale = new("UIScale", { Scale = 0.88, Parent = root })
	win.Root = root
	win.Scale = rscale

	-- Header -------------------------------------------------------
	local header = new("Frame", { Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Parent = root })
	local hline = new("Frame", {
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BorderSizePixel = 0, BackgroundTransparency = 0.5, Parent = header,
	})
	self:Bind(hline, "BackgroundColor3", "Border")

	local left = new("Frame", {
		Name = "Left", BackgroundTransparency = 1, Size = UDim2.new(1, -86, 1, 0), ClipsDescendants = true, Parent = header,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left,
	})
	new("UIPadding", { PaddingLeft = UDim.new(0, 14), Parent = left })

	if opts.Logo then
		local logo = self:Icon(left, opts.Logo, 26, nil)
		logo.LayoutOrder = 1
	end

	local titleStack = new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, Parent = left,
	})
	new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = titleStack })
	local titleLbl = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 17), AutomaticSize = Enum.AutomaticSize.X,
		Font = FONT.Bold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = titleStack,
	})
	self:Bind(titleLbl, "TextColor3", "Text")
	win._titleEntry = self:BindText(titleLbl, opts.Name or opts.Title or "Picka's Hub")
	local subLbl = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 13), AutomaticSize = Enum.AutomaticSize.X,
		Font = FONT.Regular, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2,
		Visible = opts.Subtitle ~= nil, Parent = titleStack,
	})
	self:Bind(subLbl, "TextColor3", "Muted")
	win._subEntry = self:BindText(subLbl, opts.Subtitle or "")

	local tags = new("Frame", {
		Name = "Tags", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 3, Parent = left,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tags,
	})
	win.TagHolder = tags
	win._tagCount = 0

	-- Window controls
	local controls = new("Frame", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = header,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = controls,
	})

	local function ctrl(iconName, order, hoverKey)
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1,
			BorderSizePixel = 0, LayoutOrder = order, Parent = controls,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = b })
		lib:Bind(b, "BackgroundColor3", hoverKey)
		local ic = lib:Icon(b, iconName, 16, "Muted")
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.fromScale(0.5, 0.5)
		connect(b.MouseEnter, function()
			tween(b, 0.12, { BackgroundTransparency = 0.78 })
			tween(ic, 0.12, { ImageColor3 = lib.Theme.Text })
		end)
		connect(b.MouseLeave, function()
			tween(b, 0.15, { BackgroundTransparency = 1 })
			tween(ic, 0.15, { ImageColor3 = lib.Theme.Muted })
		end)
		return b
	end

	win.Controls = controls
	win.Header = header
	win.HeaderLeft = left
	win._index = {}
	win._ctrl = ctrl
	connect(controls:GetPropertyChangedSignal("AbsoluteSize"), function()
		left.Size = UDim2.new(1, -(controls.AbsoluteSize.X + 24), 1, 0)
	 end)
	local minBtn = ctrl("minus", 1, "Hover")
	local closeBtn = ctrl("x", 2, "Error")
	connect(minBtn.Activated, function()
		win:Hide()
	end)
	connect(closeBtn.Activated, function()
		win:Confirm({
			Title = "Close UI?",
			Message = "Are you sure you want to close the UI? You will need to execute the script again.",
			OnYes = function()
				if win.Kind == "Main" then
					lib:Destroy()
				else
					win:Hide()
				end
			end,
		})
	end)

	makeDraggable(header, root)

	-- Body ---------------------------------------------------------
	local body = new("Frame", {
		Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), Parent = root,
	})

	local sidebar = new("Frame", {
		Name = "Sidebar", Size = UDim2.new(0, 176, 1, 0), BorderSizePixel = 0, ClipsDescendants = true, Parent = body,
	})
	self:Bind(sidebar, "BackgroundColor3", "Secondary")
	self:Bind(sidebar, "BackgroundTransparency", function(t)
		return math.clamp(0.25 + t.Transparency * 0.75, 0, 1)
	end)
	local sline = new("Frame", {
		Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BorderSizePixel = 0, BackgroundTransparency = 0.5, Parent = sidebar,
	})
	self:Bind(sline, "BackgroundColor3", "Border")

	local top = new("Frame", { Name = "Top", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), Parent = sidebar })
	local searchBox = new("Frame", {
		Name = "Search", Position = UDim2.fromOffset(10, 9), Size = UDim2.new(1, -54, 0, 30), Parent = top,
	})
	self:Bind(searchBox, "BackgroundColor3", "Element")
	local sbc = new("UICorner", { Parent = searchBox })
	self:BindCorner(sbc, 0.65)
	local sbs = new("UIStroke", { Thickness = 1, Transparency = 0.4, Parent = searchBox })
	self:Bind(sbs, "Color", "Border")
	local si = self:Icon(searchBox, "search", 14, "Muted")
	si.Position = UDim2.fromOffset(9, 8)
	local tb = new("TextBox", {
		Name = "Input", BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -36, 1, 0),
		Text = "", ClearTextOnFocus = false, PlaceholderText = "", Font = FONT.Medium, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = searchBox,
	})
	self:Bind(tb, "TextColor3", "Text")
	self:Bind(tb, "PlaceholderColor3", "Muted")
	self:BindText(tb, "Search...", "PlaceholderText")
	connect(tb.Focused, function()
		tween(sbs, 0.15, { Transparency = 0 })
		sbs.Color = lib.Theme.Accent
	end)
	connect(tb.FocusLost, function()
		tween(sbs, 0.15, { Transparency = 0.4 })
		sbs.Color = lib.Theme.Border
	end)
	connect(tb:GetPropertyChangedSignal("Text"), function()
		win.SearchQuery = tb.Text
		win:_FilterTabs()
	end)

	local collapseBtn = new("TextButton", {
		Name = "Collapse", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30),
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 9), Parent = top,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = collapseBtn })
	self:Bind(collapseBtn, "BackgroundColor3", "Hover")
	local cIcon = self:Icon(collapseBtn, "chevron-left", 16, "Muted")
	cIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	cIcon.Position = UDim2.fromScale(0.5, 0.5)
	connect(collapseBtn.MouseEnter, function()
		tween(collapseBtn, 0.12, { BackgroundTransparency = 0.78 })
	end)
	connect(collapseBtn.MouseLeave, function()
		tween(collapseBtn, 0.15, { BackgroundTransparency = 1 })
	end)
	connect(collapseBtn.Activated, function()
		win:SetSidebarCollapsed(not win.SidebarCollapsed)
	end)

	local tabList = new("ScrollingFrame", {
		Name = "Tabs", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48 - 62), ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = sidebar,
	})
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList })
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = tabList,
	})

	-- User card
	local card = new("Frame", {
		Name = "UserCard", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 50),
		ClipsDescendants = true, Parent = sidebar,
	})
	self:Bind(card, "BackgroundColor3", "Element")
	local cc = new("UICorner", { Parent = card })
	self:BindCorner(cc, 0.8)
	local cst = new("UIStroke", { Thickness = 1, Transparency = 0.4, Parent = card })
	self:Bind(cst, "Color", "Border")
	local avatar = new("ImageLabel", {
		Name = "Avatar", BackgroundTransparency = 0, Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(8, 8), Parent = card,
	})
	self:Bind(avatar, "BackgroundColor3", "Active")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = avatar })
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and avatar.Parent then
			avatar.Image = img
		end
	end)
	local nameStack = new("Frame", {
		Name = "Names", BackgroundTransparency = 1, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -56, 1, 0), Parent = card,
	})
	new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = nameStack })
	local dn = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = FONT.Bold, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = LocalPlayer.DisplayName,
		LayoutOrder = 1, Parent = nameStack,
	})
	self:Bind(dn, "TextColor3", "Text")
	local un = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Font = FONT.Regular, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "@" .. LocalPlayer.Name,
		LayoutOrder = 2, Parent = nameStack,
	})
	self:Bind(un, "TextColor3", "Muted")

	-- Content ------------------------------------------------------
	local content = new("Frame", {
		Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(176, 0), Size = UDim2.new(1, -176, 1, 0),
		ClipsDescendants = true, Parent = body,
	})
	local pageHolder = new("CanvasGroup", {
		Name = "Pages", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromScale(1, 1), Parent = content,
	})

	win.Sidebar = sidebar
	win.SearchBox = searchBox
	win.CollapseIcon = cIcon
	win.TabList = tabList
	win.UserCard = card
	win.Avatar = avatar
	win.Names = nameStack
	win.Content = content
	win.PageHolder = pageHolder
	win.Body = body

	-- default tags
	if opts.GameTag ~= false then
		local gt = win:AddTag(game.Name ~= "" and game.Name or "Game", "Element")
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(game.PlaceId)
			end)
			if ok and info and info.Name and gt and gt.Label.Parent then
				lib:SetBoundText(gt.Entry, info.Name)
			end
		end)
	end
	if opts.Version then
		win:AddTag(opts.Version, "Accent")
	end
	if opts.KeyStatus then
		win:AddTag(opts.KeyStatus, "Warning")
	end

	table.insert(self.Windows, win)
	if opts.AutoShow then
		win:Show()
	end
	return win
end

function WindowClass:AddTag(text, color)
	local lib = self.Library
	self._tagCount = self._tagCount + 1
	local tag = new("Frame", {
		Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = self._tagCount, Parent = self.TagHolder,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = tag })
	new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = tag })
	local key = "Element"
	local rawColor
	if typeof(color) == "Color3" then
		rawColor = color
	elseif type(color) == "string" then
		key = color
	end
	local tagStroke = new("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = tag })
	local lbl = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X,
		Font = FONT.Bold, TextSize = 11, Parent = tag,
	})
	if rawColor then
		tag.BackgroundColor3 = rawColor
		tag.BackgroundTransparency = 0.8
		lbl.TextColor3 = rawColor
		tagStroke.Color = rawColor
	elseif key == "Element" then
		lib:Bind(tag, "BackgroundColor3", "Element")
		tag.BackgroundTransparency = 0
		lib:Bind(lbl, "TextColor3", "Muted")
		lib:Bind(tagStroke, "Color", "Border")
	else
		lib:Bind(tag, "BackgroundColor3", key)
		tag.BackgroundTransparency = 0.82
		lib:Bind(lbl, "TextColor3", key)
		lib:Bind(tagStroke, "Color", key)
	end
	local entry = lib:BindText(lbl, text)
	return { Frame = tag, Label = lbl, Entry = entry }
end

function WindowClass:SetTitle(text)
	self.Library:SetBoundText(self._titleEntry, text)
end

function WindowClass:Notify(opts)
	return self.Library:Notify(opts)
end

function WindowClass:_OrbCenter()
	local o = self.Library.Orb and self.Library.Orb.Frame
	if o and o.Parent then
		local d = o.Size.X.Offset
		return UDim2.fromOffset(o.AbsolutePosition.X + d / 2, o.AbsolutePosition.Y + d / 2)
	end
	return nil
end

function WindowClass:Show()
	if self.Visible then
		return
	end
	self.Visible = true
	local root = self.Root
	local target = self._restorePos or root.Position
	self._restorePos = target
	root.Visible = true
	local from = self:_OrbCenter()
	-- the window grows out of the orb
	if from then
		root.Position = from
		self.Scale.Scale = 0.12
	else
		root.Position = target
		self.Scale.Scale = 0.88
	end
	root.GroupTransparency = 1
	tween(root, 0.6, { Position = target }, Enum.EasingStyle.Quint)
	tween(self.Scale, 0.55, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(root, 0.28, { GroupTransparency = 0 })
end

function WindowClass:Hide()
	if not self.Visible then
		return
	end
	self.Visible = false
	local root = self.Root
	self._restorePos = root.Position
	local to = self:_OrbCenter()
	-- the window is sucked back into the orb
	if to then
		tween(root, 0.4, { Position = to }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(self.Scale, 0.4, { Scale = 0.12 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(root, 0.3, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	else
		tween(self.Scale, 0.2, { Scale = 0.9 })
		tween(root, 0.18, { GroupTransparency = 1 })
	end
	task.delay(dur(0.42), function()
		if not self.Visible and root.Parent then
			root.Visible = false
			root.Position = self._restorePos
		end
	end)
end

function WindowClass:Toggle()
	if self.Visible then
		self:Hide()
	else
		self:Show()
	end
end

function WindowClass:Destroy()
	self.Library:Destroy()
end

function WindowClass:Confirm(opts)
	local lib = self.Library
	opts = opts or {}
	local overlay = new("TextButton", {
		Name = "DialogOverlay", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 100, Parent = self.Root,
	})
	tween(overlay, 0.2, { BackgroundTransparency = 0.45 })

	local dlg = new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(math.min(300, self.Width - 40), 0), AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 1, ZIndex = 101, Parent = overlay,
	})
	lib:Bind(dlg, "BackgroundColor3", "Surface")
	local dc = new("UICorner", { Parent = dlg })
	lib:BindCorner(dc, 1)
	local ds = new("UIStroke", { Thickness = 1, Parent = dlg })
	lib:Bind(ds, "Color", "Stroke")
	local dscale = new("UIScale", { Scale = 0.9, Parent = dlg })

	local inner = new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = dlg,
	})
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16), Parent = inner,
	})
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })

	local t = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.Y, Font = FONT.Bold,
		TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = inner,
	})
	lib:Bind(t, "TextColor3", "Text")
	lib:BindText(t, opts.Title or "Confirm")
	local m = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = FONT.Regular,
		TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = inner,
	})
	lib:Bind(m, "TextColor3", "Muted")
	lib:BindText(m, opts.Message or "")

	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 3, Parent = inner })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = row,
	})

	local closing = false
	local function dismiss()
		if closing then
			return
		end
		closing = true
		tween(overlay, 0.18, { BackgroundTransparency = 1 })
		tween(dlg, 0.18, { GroupTransparency = 1 })
		tween(dscale, 0.18, { Scale = 0.92 })
		task.delay(dur(0.2), function()
			overlay:Destroy()
		end)
	end

	local function mkButton(label, order, primary)
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, Size = UDim2.new(0.5, -4, 1, 0), LayoutOrder = order, ClipsDescendants = true, Parent = row,
		})
		local bc = new("UICorner", { Parent = b })
		lib:BindCorner(bc, 0.65)
		local bl = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = FONT.Bold, TextSize = 13, ZIndex = 2, Parent = b,
		})
		lib:Bind(bl, "TextColor3", "Text")
		lib:BindText(bl, label)
		if primary then
			b.BackgroundColor3 = Color3.new(1, 1, 1)
			local g = new("UIGradient", { Rotation = 0, Parent = b })
			lib:Bind(g, "Color", function(th)
				return ColorSequence.new(th.GradientA, th.GradientB)
			end)
		else
			lib:Bind(b, "BackgroundColor3", "Element")
			connect(b.MouseEnter, function()
				tween(b, 0.12, { BackgroundColor3 = lib.Theme.Hover })
			end)
			connect(b.MouseLeave, function()
				tween(b, 0.15, { BackgroundColor3 = lib.Theme.Element })
			end)
		end
		connect(b.MouseButton1Down, function()
			ripple(b)
		end)
		return b
	end

	local noBtn = mkButton(opts.No or "No", 1, false)
	local yesBtn = mkButton(opts.Yes or "Yes", 2, true)
	connect(noBtn.Activated, function()
		dismiss()
		fire(opts.OnNo)
	end)
	connect(yesBtn.Activated, function()
		dismiss()
		fire(opts.OnYes)
	end)

	tween(dlg, 0.2, { GroupTransparency = 0 })
	tween(dscale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

function WindowClass:SetSidebarCollapsed(state)
	state = state and true or false
	if self.SidebarCollapsed == state then
		return
	end
	self.SidebarCollapsed = state
	local w = state and 56 or 176
	tween(self.Sidebar, 0.28, { Size = UDim2.new(0, w, 1, 0) })
	tween(self.Content, 0.28, { Position = UDim2.fromOffset(w, 0), Size = UDim2.new(1, -w, 1, 0) })
	tween(self.CollapseIcon, 0.28, { Rotation = state and 180 or 0 })
	tween(self.Avatar, 0.28, { Position = UDim2.fromOffset(state and 3 or 8, 8) })
	self.SearchBox.Visible = not state
	self.Names.Visible = not state
	for _, tab in ipairs(self.Tabs) do
		tab.Label.Visible = not state
		tab.Dot.Visible = (not state) and tab._active
	end
end

function WindowClass:_FilterTabs()
	local q = string.lower(self.SearchQuery or "")
	local lib = self.Library
	for _, tab in ipairs(self.Tabs) do
		local match = q == ""
		if not match then
			if string.find(string.lower(lib:Translate(tab.Name)), q, 1, true) then
				match = true
			else
				for _, raw in ipairs(tab._search) do
					if string.find(string.lower(lib:Translate(raw)), q, 1, true) then
						match = true
						break
					end
				end
			end
		end
		tab.Button.Visible = match
	end
end

function WindowClass:_LayoutContent(animate)
	local tab = self.ActiveTab
	local h = 0
	if tab and #tab.Subtabs > 0 then
		h = tab.SubCollapsed and 22 or 46
		tween(tab.Holder, animate and 0.2 or 0, { Size = UDim2.new(1, 0, 0, h) })
	end
	tween(self.PageHolder, animate and 0.2 or 0, { Position = UDim2.fromOffset(0, h), Size = UDim2.new(1, 0, 1, -h) })
end

function WindowClass:_ShowPage(page)
	if self.CurrentPage and self.CurrentPage ~= page then
		self.CurrentPage.Scroll.Visible = false
	end
	self.CurrentPage = page
	local dx = (self._slideDir or 0) * 56
	self._slideDir = 0
	page.Scroll.Position = UDim2.fromOffset(dx, dx == 0 and 8 or 0)
	page.Scroll.Visible = true
	self.PageHolder.GroupTransparency = 1
	tween(self.PageHolder, 0.25, { GroupTransparency = 0 })
	tween(page.Scroll, 0.42, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
end

function WindowClass:SelectTab(tab)
	if tab.Locked then
		self.Library:Notify({
			Title = "Locked",
			Description = tab._lockMessage or "Locked",
			Type = "Warning",
			Duration = 3,
		})
		return
	end
	local prev = self.ActiveTab
	if prev == tab then
		return
	end
	if prev then
		prev:_SetActive(false)
		prev.Holder.Visible = false
	end
	self.ActiveTab = tab
	tab:_SetActive(true)
	local page = tab
	if #tab.Subtabs > 0 then
		tab.Holder.Visible = true
		local sub = tab.ActiveSub or tab.Subtabs[1]
		tab.ActiveSub = sub
		for _, s in ipairs(tab.Subtabs) do
			s:_SetActive(s == sub, true)
		end
		page = sub
	end
	self:_LayoutContent(false)
	self:_ShowPage(page)
end

--==================================================================
-- Tabs
--==================================================================
local function newPage(win, columns)
	local lib = win.Library
	columns = columns or ((win.Width - 176) >= 430 and 2 or 1)
	local scroll = new("ScrollingFrame", {
		Name = "Page", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false,
		ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = win.PageHolder,
	})
	lib:Bind(scroll, "ScrollBarImageColor3", "Accent")
	new("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14), Parent = scroll,
	})
	local wrap = new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = scroll,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = wrap,
	})
	local cols = {}
	for i = 1, columns do
		local col = new("Frame", {
			Name = "Column" .. i, BackgroundTransparency = 1, Size = UDim2.new(1 / columns, -(10 * (columns - 1)) / columns, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, Parent = wrap,
		})
		new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col })
		cols[i] = col
	end
	return scroll, cols, columns
end

local function initPage(obj, win, columns)
	local scroll, cols, count = newPage(win, columns)
	obj.Scroll = scroll
	obj.Columns = cols
	obj.ColumnCount = count
	obj._nextCol = 0
	obj._order = 0
end

function WindowClass:CreateTab(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local win = self

	local tab = setmetatable({
		Window = self, Library = lib, Name = opts.Name or "Tab", Subtabs = {}, _search = {},
		Locked = false, SubCollapsed = false, _active = false,
	}, TabClass)
	tab.Tab = tab
	initPage(tab, self, opts.Columns)

	local btn = new("TextButton", {
		Name = "Tab", Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1,
		LayoutOrder = #self.Tabs + 1, Parent = self.TabList,
	})
	lib:Bind(btn, "BackgroundColor3", "Accent")
	local bc = new("UICorner", { CornerRadius = UDim.new(0, 9), Parent = btn })
	local bs = new("UIStroke", { Thickness = 1, Transparency = 1, Parent = btn })
	lib:Bind(bs, "Color", "Accent")

	local icon = lib:Icon(btn, opts.Icon, 16, nil)
	icon.Position = UDim2.fromOffset(12, 10)
	lib:Bind(icon, "ImageColor3", function(t)
		return tab._active and t.Accent or t.Muted
	end)

	local label = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(opts.Icon and 38 or 12, 0), Size = UDim2.new(1, -(opts.Icon and 62 or 36), 1, 0),
		Font = FONT.Medium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
	})
	lib:Bind(label, "TextColor3", function(t)
		return tab._active and t.Text or t.Muted
	end)
	lib:BindText(label, tab.Name)

	local dot = new("Frame", {
		Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Visible = false, Parent = btn,
	})
	lib:Bind(dot, "BackgroundColor3", "Accent")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

	local lockIcon = lib:Icon(btn, "lock", 14, "Warning")
	lockIcon.AnchorPoint = Vector2.new(1, 0.5)
	lockIcon.Position = UDim2.new(1, -10, 0.5, 0)
	lockIcon.Visible = false

	tab.Button = btn
	tab.Label = label
	tab.Dot = dot
	tab.LockIcon = lockIcon
	tab.IconImage = icon

	-- subtab holder
	local availW = math.max(self.Width - 176 - 80, 120)
	local holder = new("Frame", {
		Name = "SubtabHolder", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Visible = false, Parent = self.Content,
	})
	local pill = new("ScrollingFrame", {
		Name = "Pill", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -10, 0.5, 0), Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X, BorderSizePixel = 0, Parent = holder,
	})
	lib:Bind(pill, "BackgroundColor3", "Secondary")
	pill.BackgroundTransparency = 0.3
	local pc = new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })
	local ps = new("UIStroke", { Thickness = 1, Transparency = 0.35, Parent = pill })
	lib:Bind(ps, "Color", "Border")
	new("UISizeConstraint", { MaxSize = Vector2.new(availW, 34), Parent = pill })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = pill,
	})
	new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = pill })

	local chev = new("TextButton", {
		Name = "SubCollapse", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(26, 26),
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Parent = holder,
	})
	local chIcon = lib:Icon(chev, "chevron-down", 16, "Muted")
	chIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	chIcon.Position = UDim2.fromScale(0.5, 0.5)
	connect(chev.Activated, function()
		tab.SubCollapsed = not tab.SubCollapsed
		pill.Visible = not tab.SubCollapsed
		tween(chIcon, 0.2, { Rotation = tab.SubCollapsed and 180 or 0 })
		chev.Position = UDim2.new(1, -10, 0.5, 0)
		win:_LayoutContent(true)
	end)

	tab.Holder = holder
	tab.Pill = pill

	function tab:_SetActive(state)
		self._active = state
		tween(btn, 0.18, { BackgroundTransparency = state and 0.78 or 1 })
		tween(bs, 0.18, { Transparency = state and 0.45 or 1 })
		tween(label, 0.18, { TextColor3 = state and lib.Theme.Text or lib.Theme.Muted })
		tween(icon, 0.18, { ImageColor3 = state and lib.Theme.Accent or lib.Theme.Muted })
		dot.Visible = state and not win.SidebarCollapsed
	end

	function tab:SetLocked(state, tagText, message)
		self.Locked = state and true or false
		if message ~= nil then
			self._lockMessage = message
		end
		lockIcon.Visible = self.Locked
		dot.Visible = self._active and not self.Locked and not win.SidebarCollapsed
	end
	function tab:Lock(tagText, message)
		self:SetLocked(true, tagText, message)
	end
	function tab:Unlock()
		self:SetLocked(false)
	end

	-- hover
	connect(btn.MouseEnter, function()
		if not tab._active then
			tween(btn, 0.12, { BackgroundTransparency = 0.9 })
		end
	end)
	connect(btn.MouseLeave, function()
		if not tab._active then
			tween(btn, 0.15, { BackgroundTransparency = 1 })
		end
	end)
	connect(btn.Activated, function()
		win:SelectTab(tab)
	end)

	if opts.Locked then
		tab:SetLocked(true, opts.LockTag, opts.LockMessage)
	end
	if win.SidebarCollapsed then
		label.Visible = false
	end

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 and not tab.Locked then
		self:SelectTab(tab)
	end
	return tab
end

function TabClass:AddSubtab(opts)
	opts = parseOpts(opts)
	local win = self.Window
	local lib = self.Library
	local tab = self

	local sub = setmetatable({
		Window = win, Library = lib, Tab = tab, Name = opts.Name or "Subtab", Locked = false, _active = false,
	}, SubtabClass)
	initPage(sub, win, opts.Columns)

	local btn = new("TextButton", {
		Name = "Subtab", Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Font = FONT.Bold, TextSize = 13,
		LayoutOrder = #tab.Subtabs + 1, Parent = tab.Pill,
	})
	lib:Bind(btn, "BackgroundColor3", "Active")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = btn })
	local padding = new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), Parent = btn })
	local bscale = new("UIScale", { Scale = 1, Parent = btn })
	lib:Bind(btn, "TextColor3", function(t)
		return sub._active and t.Text or t.Muted
	end)
	lib:BindText(btn, sub.Name)

	local lockIcon = lib:Icon(btn, "lock", 12, "Warning")
	lockIcon.AnchorPoint = Vector2.new(1, 0.5)
	lockIcon.Position = UDim2.new(1, 18, 0.5, 0)
	lockIcon.Visible = false

	sub.Button = btn

	function sub:_SetActive(state, instant)
		self._active = state
		if instant then
			btn.BackgroundTransparency = state and 0.15 or 1
			btn.TextColor3 = state and lib.Theme.Text or lib.Theme.Muted
			return
		end
		if state then
			bscale.Scale = 0.9
			btn.BackgroundTransparency = 1
			tween(btn, 0.18, { BackgroundTransparency = 0.15 })
			tween(bscale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
			tween(btn, 0.15, { TextColor3 = lib.Theme.Text })
		else
			tween(btn, 0.12, { BackgroundTransparency = 1 })
			tween(btn, 0.15, { TextColor3 = lib.Theme.Muted })
		end
	end

	function sub:SetLocked(state, tagText, message)
		self.Locked = state and true or false
		if message ~= nil then
			self._lockMessage = message
		end
		lockIcon.Visible = self.Locked
		padding.PaddingRight = UDim.new(0, self.Locked and 32 or 16)
	end
	function sub:Lock(tagText, message)
		self:SetLocked(true, tagText, message)
	end
	function sub:Unlock()
		self:SetLocked(false)
	end

	connect(btn.MouseEnter, function()
		if not sub._active then
			tween(btn, 0.12, { TextColor3 = lib.Theme.Text })
		end
	end)
	connect(btn.MouseLeave, function()
		if not sub._active then
			tween(btn, 0.15, { TextColor3 = lib.Theme.Muted })
		end
	end)
	connect(btn.Activated, function()
		if sub.Locked then
			lib:Notify({ Title = "Locked", Description = sub._lockMessage or "Locked", Type = "Warning", Duration = 3 })
			return
		end
		if tab.ActiveSub == sub then
			return
		end
		local oldIdx, newIdx = 0, 0
		for n, x in ipairs(tab.Subtabs) do
			if x == tab.ActiveSub then
				oldIdx = n
			end
			if x == sub then
				newIdx = n
			end
		end
		win._slideDir = (newIdx >= oldIdx) and 1 or -1
		if tab.ActiveSub then
			tab.ActiveSub:_SetActive(false)
		end
		tab.ActiveSub = sub
		sub:_SetActive(true)
		win:_ShowPage(sub)
	end)

	if opts.Locked then
		sub:SetLocked(true, opts.LockTag, opts.LockMessage)
	end

	table.insert(tab.Subtabs, sub)
	table.insert(tab._search, sub.Name)

	if #tab.Subtabs == 1 then
		-- the tab now uses subtabs; the base page is no longer shown
		tab.Scroll.Visible = false
		if win.ActiveTab == tab then
			tab.Holder.Visible = true
			if not sub.Locked then
				tab.ActiveSub = sub
				sub:_SetActive(true, true)
				win:_LayoutContent(true)
				win:_ShowPage(sub)
			else
				win:_LayoutContent(true)
			end
		end
	end
	return sub
end

--==================================================================
-- Page / Section
--==================================================================
function PageClass:AddSection(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local colIndex = opts.Column
	if not colIndex then
		self._nextCol = (self._nextCol % self.ColumnCount) + 1
		colIndex = self._nextCol
	end
	colIndex = math.clamp(colIndex, 1, self.ColumnCount)
	local col = self.Columns[colIndex]
	self._order = self._order + 1

	local frame = new("Frame", {
		Name = "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self._order, Parent = col,
	})
	lib:Bind(frame, "BackgroundColor3", "Surface")
	lib:Bind(frame, "BackgroundTransparency", function(t)
		return math.clamp(t.Transparency * 0.6, 0, 1)
	end)
	local fc = new("UICorner", { Parent = frame })
	lib:BindCorner(fc, 0.9)
	local fs = new("UIStroke", { Thickness = 1, Transparency = 0.3, Parent = frame })
	lib:Bind(fs, "Color", "Border")
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })

	local section = setmetatable({ Library = lib, Page = self, Frame = frame, Name = opts.Name }, SectionClass)

	if opts.Name then
		local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 1, Parent = frame })
		local x = 12
		if opts.Icon then
			local ic = lib:Icon(head, opts.Icon, 16, "Accent")
			ic.Position = UDim2.fromOffset(12, 10)
			x = 34
		end
		local tl = new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -(x + 12), 1, 0), Font = FONT.Bold,
			TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
		})
		lib:Bind(tl, "TextColor3", "Text")
		section.TitleEntry = lib:BindText(tl, opts.Name)
		table.insert(self.Tab._search, opts.Name)
	end

	local content = new("Frame", {
		Name = "Content", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = frame,
	})
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, opts.Name and 0 or 10), PaddingBottom = UDim.new(0, 10),
		Parent = content,
	})
	section.Content = content
	section._order = 0

	lib:_AttachLock(section, frame, opts, 0.9)
	return section
end

local function defaultSection(page)
	if not page._default then
		page._default = page:AddSection({})
	end
	return page._default
end

for _, m in ipairs({ "AddButton", "AddToggle", "AddLabel", "AddParagraph", "AddDivider" }) do
	PageClass[m] = function(self, ...)
		local s = defaultSection(self)
		return s[m](s, ...)
	end
end

function SectionClass:SetTitle(text)
	self.Library:SetBoundText(self.TitleEntry, text)
end

--==================================================================
-- Element row builder
--==================================================================
function Library:_BuildRow(section, opts, reserve)
	local parent = section.Content
	section._order = section._order + 1
	local row = new("Frame", {
		Name = "Element", Size = UDim2.new(1, 0, 0, 38), AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true,
		LayoutOrder = section._order, Parent = parent,
	})
	self:Bind(row, "BackgroundColor3", "Element")
	self:Bind(row, "BackgroundTransparency", function(t)
		return math.clamp(t.Transparency * 0.5, 0, 1)
	end)
	local rc = new("UICorner", { Parent = row })
	self:BindCorner(rc, 0.55)
	local rs = new("UIStroke", { Thickness = 1, Transparency = 0.4, Parent = row })
	self:Bind(rs, "Color", "Border")

	local padL = 12
	local iconImg
	if opts.Icon then
		iconImg = self:Icon(row, opts.Icon, 16, "Accent")
		iconImg.Position = UDim2.fromOffset(12, 11)
		padL = 36
	end

	local left = new("Frame", {
		Name = "Left", BackgroundTransparency = 1, Position = UDim2.fromOffset(padL, 0),
		Size = UDim2.new(1, -(padL + (reserve or 12) + 12), 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = row,
	})
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left })
	new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = left })

	local title = new("TextLabel", {
		Name = "Title", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT.Medium, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = left,
	})
	self:Bind(title, "TextColor3", "Text")
	local titleEntry = self:BindText(title, opts.Name or "")

	local desc = new("TextLabel", {
		Name = "Description", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT.Regular, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2,
		Visible = opts.Description ~= nil, Parent = left,
	})
	self:Bind(desc, "TextColor3", "Muted")
	local descEntry = self:BindText(desc, opts.Description or "")

	local bodyFrame = new("Frame", {
		Name = "Body", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3, Visible = false, Parent = left,
	})
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bodyFrame })
	new("UIPadding", { PaddingTop = UDim.new(0, 6), Parent = bodyFrame })

	local right = new("Frame", {
		Name = "Right", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 9),
		Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Parent = row,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = right,
	})

	if opts.Badge then
		local badge = new("TextLabel", {
			Name = "Badge", Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, Font = FONT.Bold, TextSize = 10,
			BackgroundTransparency = 0.8, LayoutOrder = 1, Parent = right,
		})
		self:Bind(badge, "BackgroundColor3", "Accent")
		self:Bind(badge, "TextColor3", "Accent")
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badge })
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = badge })
		self:BindText(badge, opts.Badge)
	end

	local hit = new("TextButton", {
		Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = row,
	})

	connect(hit.MouseEnter, function()
		tween(row, 0.12, { BackgroundColor3 = self.Theme.Hover })
	end)
	connect(hit.MouseLeave, function()
		tween(row, 0.15, { BackgroundColor3 = self.Theme.Element })
	end)
	connect(hit.MouseButton1Down, function()
		ripple(row)
	end)

	if opts.Tooltip then
		self:_BindTooltip(row, opts.Tooltip)
	end
	if section.Page and section.Page.Tab and opts.Name then
		table.insert(section.Page.Tab._search, opts.Name)
	end

	local idx
	local pg = section.Page
	if pg and pg.Window and pg.Window._index and pg.Tab and pg.Tab.Button and opts.Name then
		idx = { Name = opts.Name, Row = row, Page = pg, Tab = pg.Tab }
		table.insert(pg.Window._index, idx)
	end
	self._lastIndex = idx

	return {
		Row = row, Left = left, Title = title, TitleEntry = titleEntry, Desc = desc, DescEntry = descEntry,
		Right = right, Hit = hit, Icon = iconImg, Body = bodyFrame, Index = idx,
	}
end

function Library:_RegisterFlag(flag, getter, setter)
	if not flag then
		return
	end
	self._setters[flag] = { get = getter, set = setter, default = getter() }
	self.Flags[flag] = getter()
end

--==================================================================
-- Elements
--==================================================================
function SectionClass:AddLabel(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	self._order = self._order + 1
	local obj = { Type = "Label" }
	local lbl = new("TextLabel", {
		Name = "Label", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT.Medium, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = self._order, Parent = self.Content,
	})
	lib:Bind(lbl, "TextColor3", "Muted")
	local entry = lib:BindText(lbl, opts.Name or opts.Text or "")
	obj.Frame = lbl
	function obj:SetText(text)
		lib:SetBoundText(entry, text)
	end
	function obj:SetVisible(v)
		lbl.Visible = v
	end
	function obj:Destroy()
		lbl:Destroy()
	end
	return obj
end

function SectionClass:AddParagraph(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	self._order = self._order + 1
	local obj = { Type = "Paragraph" }
	local f = new("Frame", {
		Name = "Paragraph", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self._order, Parent = self.Content,
	})
	lib:Bind(f, "BackgroundColor3", "Element")
	f.BackgroundTransparency = 0.5
	local fc = new("UICorner", { Parent = f })
	lib:BindCorner(fc, 0.55)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = f,
	})
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = f })
	local t = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.Y, Font = FONT.Bold, TextSize = 13,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Visible = opts.Name ~= nil, Parent = f,
	})
	lib:Bind(t, "TextColor3", "Text")
	local te = lib:BindText(t, opts.Name or "")
	local b = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = FONT.Regular, TextSize = 12,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = f,
	})
	lib:Bind(b, "TextColor3", "Muted")
	local be = lib:BindText(b, opts.Content or opts.Text or opts.Description or "")
	obj.Frame = f
	function obj:SetTitle(x)
		t.Visible = true
		lib:SetBoundText(te, x)
	end
	function obj:SetContent(x)
		lib:SetBoundText(be, x)
	end
	function obj:Destroy()
		f:Destroy()
	end
	return obj
end

function SectionClass:AddDivider(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	self._order = self._order + 1
	local f = new("Frame", {
		Name = "Divider", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = self._order, Parent = self.Content,
	})
	local line = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0,
		BackgroundTransparency = 0.5, Parent = f,
	})
	lib:Bind(line, "BackgroundColor3", "Border")
	if opts.Name or opts.Text then
		local t = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 16),
			AutomaticSize = Enum.AutomaticSize.X, Font = FONT.Bold, TextSize = 11, BorderSizePixel = 0, Parent = f,
		})
		lib:Bind(t, "TextColor3", "Muted")
		lib:Bind(t, "BackgroundColor3", "Surface")
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = t })
		lib:BindText(t, opts.Name or opts.Text)
	end
	return { Type = "Divider", Frame = f }
end

local function pressFx(lib, parts)
	local row = parts.Row
	local stroke = row:FindFirstChildOfClass("UIStroke")
	local function down()
		tween(row, 0.08, { BackgroundColor3 = lib.Theme.Active })
		if stroke then
			tween(stroke, 0.08, { Color = lib.Theme.Accent, Transparency = 0.05 })
		end
		pcall(ripple, row)
	end
	local function up()
		tween(row, 0.45, { BackgroundColor3 = lib.Theme.Element }, Enum.EasingStyle.Quint)
		if stroke then
			tween(stroke, 0.45, { Color = lib.Theme.Border, Transparency = 0.4 }, Enum.EasingStyle.Quint)
		end
	end
	connect(parts.Hit.MouseButton1Down, down)
	connect(parts.Hit.MouseButton1Up, up)
	connect(parts.Hit.MouseLeave, up)
end
Library._pressFx = pressFx

function SectionClass:AddButton(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local reserve = 12 + 26
	if opts.Badge then
		reserve = reserve + 64
	end
	local parts = lib:_BuildRow(self, opts, reserve)
	local obj = { Type = "Button", Name = opts.Name, Frame = parts.Row, Disabled = opts.Disabled == true, Loading = false }
	pressFx(lib, parts)

	local chev = lib:Icon(parts.Right, opts.RightIcon or "chevron-right", 16, "Muted")
	chev.LayoutOrder = 5
	local spin
	connect(parts.Hit.MouseEnter, function()
		tween(chev, 0.25, { Rotation = 0, ImageColor3 = lib.Theme.Accent }, Enum.EasingStyle.Back)
	end)
	connect(parts.Hit.MouseLeave, function()
		if not obj.Loading then
			tween(chev, 0.25, { ImageColor3 = lib.Theme.Muted })
		end
	end)

	local function applyDisabled()
		parts.Title.TextTransparency = obj.Disabled and 0.5 or 0
		chev.ImageTransparency = obj.Disabled and 0.5 or 0
	end
	applyDisabled()

	connect(parts.Hit.Activated, function()
		if obj.Disabled or obj.Loading or obj.Locked then
			return
		end
		fire(opts.Callback)
	end)

	function obj:Fire()
		if not (obj.Disabled or obj.Loading or obj.Locked) then
			fire(opts.Callback)
		end
	end
	function obj:SetText(text)
		lib:SetBoundText(parts.TitleEntry, text)
	end
	function obj:SetDescription(text)
		parts.Desc.Visible = true
		lib:SetBoundText(parts.DescEntry, text)
	end
	function obj:SetDisabled(state)
		obj.Disabled = state and true or false
		applyDisabled()
	end
	function obj:SetLoading(state)
		obj.Loading = state and true or false
		if obj.Loading then
			chev.Image = iconAsset(lib, "loader-circle") or chev.Image
			if not spin and not lib.ReduceAnimations then
				spin = TweenService:Create(chev, TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })
				spin:Play()
			end
		else
			if spin then
				spin:Cancel()
				spin = nil
			end
			chev.Rotation = 0
			chev.Image = iconAsset(lib, opts.RightIcon or "chevron-right") or chev.Image
		end
	end
	function obj:SetVisible(v)
		parts.Row.Visible = v
	end
	function obj:Destroy()
		parts.Row:Destroy()
	end

	lib:_AttachLock(obj, parts.Row, opts, 0.55)
	if opts.Loading then
		obj:SetLoading(true)
	end
	return obj
end

function SectionClass:AddToggle(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local win = self.Page.Window
	local reserve = 12 + 44
	if opts.Badge then
		reserve = reserve + 64
	end
	if opts.Status then
		reserve = reserve + 34
	end
	local hasKey = opts.Keybind ~= nil and UserInputService.KeyboardEnabled
	if hasKey then
		reserve = reserve + 46
	end

	local parts = lib:_BuildRow(self, opts, reserve)
	local obj = {
		Type = "Toggle", Name = opts.Name, Frame = parts.Row, Value = opts.Default == true,
		Disabled = opts.Disabled == true, Color = opts.Color, KeybindValue = opts.Keybind,
	}
	if hasKey then
		lib._keybinds[#lib._keybinds + 1] = obj
	end

	local status
	if opts.Status then
		status = new("TextLabel", {
			Size = UDim2.fromOffset(28, 20), BackgroundTransparency = 1, Font = FONT.Bold, TextSize = 10, LayoutOrder = 2, Parent = parts.Right,
		})
		lib:Bind(status, "TextColor3", "Muted")
	end

	if hasKey then
		local chip = new("TextLabel", {
			Name = "Chip", Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, Font = FONT.Bold, TextSize = 10, BackgroundTransparency = 0.4,
			Text = opts.Keybind.Name, LayoutOrder = 3, Parent = parts.Right,
		})
		lib:Bind(chip, "BackgroundColor3", "Surface")
		lib:Bind(chip, "TextColor3", "Muted")
		new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = chip })
		new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = chip })
	end

	local switch = new("Frame", { Size = UDim2.fromOffset(38, 20), LayoutOrder = 4, Parent = parts.Right })
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switch })
	lib:Bind(switch, "BackgroundColor3", function(t)
		if obj.Value then
			return obj.Color or t.Accent
		end
		return t.Border
	end)
	local knob = new("Frame", {
		Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), Parent = switch,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local kscale = new("UIScale", { Scale = 1, Parent = knob })
	local glow = new("UIStroke", { Thickness = 0, Transparency = 0.6, Parent = switch })
	lib:Bind(glow, "Color", function(t)
		return obj.Color or t.Accent
	end)

	local function render(animate)
		local target = obj.Value and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		local color = obj.Value and (obj.Color or lib.Theme.Accent) or lib.Theme.Border
		if animate then
			tween(knob, 0.3, { Position = target }, Enum.EasingStyle.Back)
			tween(switch, 0.2, { BackgroundColor3 = color })
			tween(glow, 0.25, { Thickness = obj.Value and 2 or 0 })
			tween(knob, 0.12, { Size = UDim2.fromOffset(21, 14) })
			task.delay(dur(0.12), function()
				tween(knob, 0.35, { Size = UDim2.fromOffset(14, 14) }, Enum.EasingStyle.Back)
			end)
		else
			knob.Position = target
			switch.BackgroundColor3 = color
			glow.Thickness = obj.Value and 2 or 0
		end
		if status then
			status.Text = obj.Value and "ON" or "OFF"
		end
		if opts.Flag then
			lib.Flags[opts.Flag] = obj.Value
		end
	end
	render(false)

	local function set(value, silent, animate)
		value = value and true or false
		if obj.Value == value then
			return
		end
		obj.Value = value
		render(animate ~= false)
		if not silent then
			fire(opts.Callback, value)
		end
	end

	Library._pressFx(lib, parts)
	connect(parts.Hit.Activated, function()
		if obj.Disabled or obj.Locked then
			return
		end
		set(not obj.Value, false, true)
	end)

	if hasKey then
		connect(UserInputService.InputBegan, function(input, processed)
			if processed or obj.Disabled or obj.Locked then
				return
			end
			if obj.KeybindValue and input.KeyCode == obj.KeybindValue and win.Visible then
				set(not obj.Value, false, true)
			end
		end)
	end

	function obj:Set(value, silent)
		set(value, silent, true)
	end
	function obj:Get()
		return obj.Value
	end
	function obj:GetKeybind()
		return obj.KeybindValue
	end
	function obj:SetKeybind(k)
		obj.KeybindValue = k
		local c = parts.Right:FindFirstChild("Chip")
		if c then
			c.Text = k and k.Name or "None"
		end
	end
	function obj:SetColor(c)
		obj.Color = c
		render(true)
	end
	function obj:SetText(text)
		lib:SetBoundText(parts.TitleEntry, text)
	end
	function obj:SetDescription(text)
		parts.Desc.Visible = true
		lib:SetBoundText(parts.DescEntry, text)
	end
	function obj:SetDisabled(state)
		obj.Disabled = state and true or false
		parts.Title.TextTransparency = obj.Disabled and 0.5 or 0
	end
	function obj:SetVisible(v)
		parts.Row.Visible = v
	end
	function obj:Destroy()
		parts.Row:Destroy()
	end

	lib:_RegisterFlag(opts.Flag, function()
		return obj.Value
	end, function(v)
		obj:Set(v, not Library._fireOnLoad)
	end)

	lib:_AttachLock(obj, parts.Row, opts, 0.55)

	if opts.Default and opts.Callback and opts.FireOnLoad then
		fire(opts.Callback, obj.Value)
	end
	return obj
end


--==================================================================
-- PART 2: Shared helpers and input components
--==================================================================
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function fmtNum(v, inc)
	inc = inc or 1
	if inc >= 1 and inc == math.floor(inc) then
		return tostring(math.floor(v + 0.5))
	end
	local frac = tostring(inc):match("%.(%d+)")
	return string.format("%." .. (frac and #frac or 0) .. "f", v)
end

local function snap(v, min, max, inc)
	inc = inc or 1
	v = math.floor((v - min) / inc + 0.5) * inc + min
	v = math.clamp(v, min, max)
	return tonumber(string.format("%.6f", v))
end

local function toHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function fromHex(txt)
	local r, g, b = tostring(txt):match("^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
	if r then
		return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
	end
	return nil
end

Library.Util = { toHex = toHex, fromHex = fromHex, snap = snap, fmtNum = fmtNum }

function Library:_Round(inst, mult)
	local c = new("UICorner", { Parent = inst })
	self:BindCorner(c, mult or 0.55)
	return c
end

function Library:_Text(parent, text, size, font, colorKey, props)
	local l = new("TextLabel", merge({
		BackgroundTransparency = 1, Font = font or FONT.Medium, TextSize = size or 13,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "",
	}, props))
	l.Parent = parent
	self:Bind(l, "TextColor3", colorKey or "Text")
	local e
	if text ~= false then
		e = self:BindText(l, text or "")
	end
	return l, e
end

function Library:_Field(parent, props)
	local f = new("Frame", merge({ Size = UDim2.new(1, 0, 0, 30) }, props))
	f.Parent = parent
	self:Bind(f, "BackgroundColor3", "Secondary")
	self:_Round(f, 0.5)
	local s = new("UIStroke", { Thickness = 1, Transparency = 0.4, Parent = f })
	self:Bind(s, "Color", "Border")
	return f, s
end

function Library:_SmallButton(parent, text, cb, style)
	local lib = self
	local b = new("TextButton", {
		Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
		ClipsDescendants = true, Parent = parent,
	})
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = b })
	self:_Round(b, 0.5)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
		Font = FONT.Bold, TextSize = 12, ZIndex = 2, Parent = b,
	})
	local e
	if style == "primary" then
		b.BackgroundColor3 = Color3.new(1, 1, 1)
		local g = new("UIGradient", { Rotation = 0, Parent = b })
		self:Bind(g, "Color", function(t)
			return ColorSequence.new(t.GradientA, t.GradientB)
		end)
		l.TextColor3 = Color3.new(1, 1, 1)
	else
		self:Bind(b, "BackgroundColor3", "Element")
		self:Bind(l, "TextColor3", "Text")
		connect(b.MouseEnter, function()
			tween(b, 0.12, { BackgroundColor3 = lib.Theme.Hover })
		end)
		connect(b.MouseLeave, function()
			tween(b, 0.15, { BackgroundColor3 = lib.Theme.Element })
		end)
	end
	if text ~= false then
		e = self:BindText(l, text or "")
	end
	connect(b.MouseButton1Down, function()
		ripple(b)
	end)
	connect(b.Activated, function()
		fire(cb)
	end)
	return b, l, e
end

function Library:_DragArea(area, cb)
	local dragging = false
	local scroller
	connect(area.InputBegan, function(input)
		if isPress(input) then
			dragging = true
			scroller = area:FindFirstAncestorOfClass("ScrollingFrame")
			if scroller then
				scroller.ScrollingEnabled = false
			end
			cb(input.Position)
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if scroller then
						scroller.ScrollingEnabled = true
					end
					if conn then
						conn:Disconnect()
					end
				end
			end)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			cb(input.Position)
		end
	end)
end

function Library:_Expander(parts, height)
	local panel = new("Frame", {
		Name = "Panel", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true,
		Visible = false, Parent = parts.Body,
	})
	local ex = { Panel = panel, Height = height or 100, IsOpen = false }
	function ex:Open()
		if self.IsOpen then
			return
		end
		self.IsOpen = true
		parts.Body.Visible = true
		panel.Visible = true
		tween(panel, 0.25, { Size = UDim2.new(1, 0, 0, self.Height) })
		if self.OnToggle then
			self.OnToggle(true)
		end
	end
	function ex:Close()
		if not self.IsOpen then
			return
		end
		self.IsOpen = false
		tween(panel, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
		task.delay(dur(0.22), function()
			if not ex.IsOpen and panel.Parent then
				panel.Visible = false
				parts.Body.Visible = false
			end
		end)
		if self.OnToggle then
			self.OnToggle(false)
		end
	end
	function ex:Toggle()
		if self.IsOpen then
			self:Close()
		else
			self:Open()
		end
	end
	function ex:Resize(h)
		self.Height = h
		if self.IsOpen then
			tween(panel, 0.2, { Size = UDim2.new(1, 0, 0, h) })
		end
	end
	return ex
end

-- Common finishing for stacked elements
function Library:_Finish(obj, parts, opts, getter, setter)
	local lib = self
	obj.Frame = parts.Row
	obj.Name = obj.Name or opts.Name
	function obj:SetText(t)
		lib:SetBoundText(parts.TitleEntry, t)
	end
	function obj:SetDescription(t)
		parts.Desc.Visible = true
		lib:SetBoundText(parts.DescEntry, t)
	end
	function obj:SetVisible(v)
		parts.Row.Visible = v
	end
	function obj:SetDisabled(s)
		obj.Disabled = s and true or false
		parts.Title.TextTransparency = obj.Disabled and 0.5 or 0
	end
	function obj:Destroy()
		parts.Row:Destroy()
	end
	if opts.Flag and getter then
		self:_RegisterFlag(opts.Flag, getter, setter)
	end
	self:_AttachLock(obj, parts.Row, opts, 0.55)
end

local function setFlag(opts, v)
	if opts.Flag then
		Library.Flags[opts.Flag] = v
	end
end

--==================================================================
-- Slider
--==================================================================
function SectionClass:AddSlider(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 64)
	parts.Hit.Visible = false
	parts.Body.Visible = true
	local min, max, inc = opts.Min or 0, opts.Max or 100, opts.Increment or 1
	local suffix = opts.Suffix or ""
	local obj = { Type = "Slider", Min = min, Max = max, Value = snap(opts.Default or min, min, max, inc) }

	local valLbl = lib:_Text(parts.Right, false, 12, FONT.Bold, "Accent", {
		Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Right,
	})

	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = parts.Body })
	local track = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 6), Parent = holder,
	})
	lib:Bind(track, "BackgroundColor3", "Border")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), Parent = track })
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	local fg = new("UIGradient", { Parent = fill })
	lib:Bind(fg, "Color", function(t)
		return ColorSequence.new(t.GradientB, t.GradientA)
	end)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = track,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local ks = new("UIStroke", { Thickness = 2, Parent = knob })
	lib:Bind(ks, "Color", "Accent")
	local area = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 14, 1, 0),
		Position = UDim2.fromOffset(-7, 0), ZIndex = 5, Parent = holder,
	})

	local function render(animate)
		local frac = (obj.Value - min) / math.max(max - min, 1e-9)
		valLbl.Text = fmtNum(obj.Value, inc) .. suffix
		if animate then
			tween(fill, 0.15, { Size = UDim2.new(frac, 0, 1, 0) })
			tween(knob, 0.15, { Position = UDim2.new(frac, 0, 0.5, 0) })
		else
			fill.Size = UDim2.new(frac, 0, 1, 0)
			knob.Position = UDim2.new(frac, 0, 0.5, 0)
		end
		setFlag(opts, obj.Value)
	end
	render(false)

	lib:_DragArea(area, function(pos)
		if obj.Disabled or obj.Locked then
			return
		end
		local frac = math.clamp((pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = snap(min + frac * (max - min), min, max, inc)
		if v ~= obj.Value then
			obj.Value = v
			render(false)
			fire(opts.Callback, v)
		end
	end)

	function obj:Set(v, silent)
		v = snap(tonumber(v) or min, min, max, inc)
		if v == obj.Value then
			return
		end
		obj.Value = v
		render(true)
		if not silent then
			fire(opts.Callback, v)
		end
	end
	function obj:Get()
		return obj.Value
	end
	function obj:SetRange(a, b)
		min, max = a, b
		obj.Min, obj.Max = a, b
		obj.Value = snap(obj.Value, min, max, inc)
		render(true)
	end

	lib:_Finish(obj, parts, opts, function()
		return obj.Value
	end, function(v)
		obj:Set(v, not Library._fireOnLoad)
	end)
	return obj
end

function SectionClass:AddRangeSlider(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 90)
	parts.Hit.Visible = false
	parts.Body.Visible = true
	local min, max, inc = opts.Min or 0, opts.Max or 100, opts.Increment or 1
	local d = opts.Default or { min, max }
	local obj = { Type = "RangeSlider", Min = min, Max = max, Low = snap(d[1] or min, min, max, inc), High = snap(d[2] or max, min, max, inc) }
	local valLbl = lib:_Text(parts.Right, false, 12, FONT.Bold, "Accent", {
		Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = parts.Body })
	local track = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 6), Parent = holder,
	})
	lib:Bind(track, "BackgroundColor3", "Border")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, Parent = track })
	lib:Bind(fill, "BackgroundColor3", "Accent")
	local function mkKnob()
		local k = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = track,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = k })
		local s = new("UIStroke", { Thickness = 2, Parent = k })
		lib:Bind(s, "Color", "Accent")
		return k
	end
	local k1, k2 = mkKnob(), mkKnob()
	local area = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 14, 1, 0),
		Position = UDim2.fromOffset(-7, 0), ZIndex = 5, Parent = holder,
	})
	local function render()
		local span = math.max(max - min, 1e-9)
		local a, b = (obj.Low - min) / span, (obj.High - min) / span
		fill.Position = UDim2.new(a, 0, 0, 0)
		fill.Size = UDim2.new(b - a, 0, 1, 0)
		k1.Position = UDim2.new(a, 0, 0.5, 0)
		k2.Position = UDim2.new(b, 0, 0.5, 0)
		valLbl.Text = fmtNum(obj.Low, inc) .. " - " .. fmtNum(obj.High, inc)
		setFlag(opts, { obj.Low, obj.High })
	end
	render()
	local active
	lib:_DragArea(area, function(pos)
		if obj.Disabled or obj.Locked then
			return
		end
		local frac = math.clamp((pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = snap(min + frac * (max - min), min, max, inc)
		if not active or (pos.X ~= pos.X) then
			active = nil
		end
		if not active then
			active = (math.abs(v - obj.Low) <= math.abs(v - obj.High)) and "low" or "high"
			task.delay(0.3, function()
				active = nil
			end)
		end
		if active == "low" then
			obj.Low = math.min(v, obj.High)
		else
			obj.High = math.max(v, obj.Low)
		end
		render()
		fire(opts.Callback, obj.Low, obj.High)
	end)
	function obj:Set(a, b, silent)
		obj.Low = snap(a or min, min, max, inc)
		obj.High = snap(b or max, min, max, inc)
		if obj.Low > obj.High then
			obj.Low, obj.High = obj.High, obj.Low
		end
		render()
		if not silent then
			fire(opts.Callback, obj.Low, obj.High)
		end
	end
	function obj:Get()
		return obj.Low, obj.High
	end
	lib:_Finish(obj, parts, opts, function()
		return { obj.Low, obj.High }
	end, function(v)
		if type(v) == "table" then
			obj:Set(v[1], v[2], not Library._fireOnLoad)
		end
	end)
	return obj
end

--==================================================================
-- Checkbox / Radio / Rating / Stepper
--==================================================================
function SectionClass:AddCheckbox(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 36)
	local obj = { Type = "Checkbox", Value = opts.Default == true }
	local box = new("Frame", { Size = UDim2.fromOffset(20, 20), Parent = parts.Right })
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = box })
	local bs = new("UIStroke", { Thickness = 1.5, Parent = box })
	local check = lib:Icon(box, "check", 14, nil)
	check.ImageColor3 = Color3.new(1, 1, 1)
	check.AnchorPoint = Vector2.new(0.5, 0.5)
	check.Position = UDim2.fromScale(0.5, 0.5)
	lib:Bind(box, "BackgroundColor3", function(t)
		return obj.Value and t.Accent or t.Secondary
	end)
	lib:Bind(bs, "Color", function(t)
		return obj.Value and t.Accent or t.Border
	end)
	local function render(animate)
		local bg = obj.Value and lib.Theme.Accent or lib.Theme.Secondary
		local st = obj.Value and lib.Theme.Accent or lib.Theme.Border
		if animate then
			tween(box, 0.18, { BackgroundColor3 = bg })
			tween(bs, 0.18, { Color = st })
			tween(check, 0.2, { ImageTransparency = obj.Value and 0 or 1 }, Enum.EasingStyle.Back)
		else
			box.BackgroundColor3 = bg
			bs.Color = st
			check.ImageTransparency = obj.Value and 0 or 1
		end
		setFlag(opts, obj.Value)
	end
	render(false)
	connect(parts.Hit.Activated, function()
		if obj.Disabled or obj.Locked then
			return
		end
		obj.Value = not obj.Value
		render(true)
		fire(opts.Callback, obj.Value)
	end)
	function obj:Set(v, silent)
		obj.Value = v and true or false
		render(true)
		if not silent then
			fire(opts.Callback, obj.Value)
		end
	end
	function obj:Get()
		return obj.Value
	end
	lib:_Finish(obj, parts, opts, function()
		return obj.Value
	end, function(v)
		obj:Set(v, not Library._fireOnLoad)
	end)
	return obj
end

function SectionClass:AddRadio(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 12)
	parts.Hit.Visible = false
	parts.Body.Visible = true
	local options = opts.Options or {}
	local obj = { Type = "Radio", Value = opts.Default or options[1] }
	local items = {}
	local function render(animate)
		for _, it in ipairs(items) do
			local on = it.value == obj.Value
			tween(it.dot, animate and 0.2 or 0, { Size = on and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
			tween(it.ring, animate and 0.15 or 0, { Color = on and lib.Theme.Accent or lib.Theme.Border })
			tween(it.label, animate and 0.15 or 0, { TextColor3 = on and lib.Theme.Text or lib.Theme.Muted })
		end
		setFlag(opts, obj.Value)
	end
	for i, o in ipairs(options) do
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = i, Parent = parts.Body,
		})
		local circle = new("Frame", {
			BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
			Parent = b,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = circle })
		local ring = new("UIStroke", { Thickness = 1.5, Parent = circle })
		lib:Bind(ring, "Color", "Border")
		local dot = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0), Parent = circle,
		})
		lib:Bind(dot, "BackgroundColor3", "Accent")
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		local lbl = lib:_Text(b, tostring(o), 12, FONT.Medium, "Muted", {
			Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -26, 1, 0),
		})
		items[#items + 1] = { value = o, dot = dot, ring = ring, label = lbl }
		connect(b.Activated, function()
			if obj.Disabled or obj.Locked then
				return
			end
			obj.Value = o
			render(true)
			fire(opts.Callback, o)
		end)
	end
	render(false)
	function obj:Set(v, silent)
		obj.Value = v
		render(true)
		if not silent then
			fire(opts.Callback, v)
		end
	end
	function obj:Get()
		return obj.Value
	end
	lib:_Finish(obj, parts, opts, function()
		return obj.Value
	end, function(v)
		obj:Set(v, not Library._fireOnLoad)
	end)
	return obj
end

function SectionClass:AddRating(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local count = opts.Max or 5
	local parts = lib:_BuildRow(self, opts, count * 20 + 12)
	local obj = { Type = "Rating", Value = opts.Default or 0, Max = count }
	local stars = {}
	local function render()
		for i, s in ipairs(stars) do
			tween(s, 0.12, { TextColor3 = i <= obj.Value and lib.Theme.Warning or lib.Theme.Border })
		end
		setFlag(opts, obj.Value)
	end
	for i = 1, count do
		local s = new("TextButton", {
			Text = "★", Font = FONT.Bold, TextSize = 18, BackgroundTransparency = 1, AutoButtonColor = false,
			Size = UDim2.fromOffset(20, 20), LayoutOrder = i, ZIndex = 4, Parent = parts.Right,
		})
		s.TextColor3 = lib.Theme.Border
		stars[i] = s
		connect(s.Activated, function()
			if obj.Disabled or obj.Locked then
				return
			end
			obj.Value = (obj.Value == i) and 0 or i
			render()
			fire(opts.Callback, obj.Value)
		end)
	end
	render()
	parts.Hit.Visible = false
	function obj:Set(v, silent)
		obj.Value = math.clamp(v or 0, 0, count)
		render()
		if not silent then
			fire(opts.Callback, obj.Value)
		end
	end
	function obj:Get()
		return obj.Value
	end
	lib:_Finish(obj, parts, opts, function()
		return obj.Value
	end, function(v)
		obj:Set(v, not Library._fireOnLoad)
	end)
	return obj
end

function SectionClass:AddStepper(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 112)
	parts.Hit.Visible = false
	local min, max, step = opts.Min or 0, opts.Max or 100, opts.Step or opts.Increment or 1
	local obj = { Type = "Stepper", Value = math.clamp(opts.Default or min, min, max) }
	local function mk(txt, order)
		local b = new("TextButton", {
			Text = txt, Font = FONT.Bold, TextSize = 14, AutoButtonColor = false, Size = UDim2.fromOffset(22, 22), LayoutOrder = order,
			ZIndex = 4, Parent = parts.Right,
		})
		lib:Bind(b, "BackgroundColor3", "Secondary")
		lib:Bind(b, "TextColor3", "Text")
		lib:_Round(b, 0.4)
		return b
	end
	local minus = mk("-", 1)
	local val = lib:_Text(parts.Right, false, 12, FONT.Bold, "Accent", {
		Size = UDim2.fromOffset(40, 22), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2,
	})
	local plus = mk("+", 3)
	local function render()
		val.Text = fmtNum(obj.Value, step)
		setFlag(opts, obj.Value)
	end
	render()
	local function change(d)
		if obj.Disabled or obj.Locked then
			return
		end
		local v = math.clamp(snap(obj.Value + d, min, max, step), min, max)
		if v ~= obj.Value then
			obj.Value = v
			render()
			fire(opts.Callback, v)
		end
	end
	connect(minus.Activated, function()
		change(-step)
	end)
	connect(plus.Activated, function()
		change(step)
	end)
	function obj:Set(v, silent)
		obj.Value = math.clamp(tonumber(v) or min, min, max)
		render()
		if not silent then
			fire(opts.Callback, obj.Value)
		end
	end
	function obj:Get()
		return obj.Value
	end
	lib:_Finish(obj, parts, opts, function()
		return obj.Value
	end, function(v)
		obj:Set(v, not Library._fireOnLoad)
	end)
	return obj
end

--==================================================================
-- Textbox family
--==================================================================
function SectionClass:AddTextbox(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local multiline = opts.Multiline == true
	local parts = lib:_BuildRow(self, opts, 12)
	parts.Hit.Visible = false
	parts.Body.Visible = true
	if not opts.Name then
		parts.Title.Visible = false
		parts.Body.UIPadding.PaddingTop = UDim.new(0, 0)
	end
	local obj = { Type = multiline and "TextArea" or "Textbox", Value = opts.Default or "" }
	local field, fstroke = lib:_Field(parts.Body, { Size = UDim2.new(1, 0, 0, multiline and 84 or 30) })
	local x = 10
	if opts.Icon then
		local ic = lib:Icon(field, opts.Icon, 14, "Muted")
		ic.Position = UDim2.fromOffset(9, multiline and 9 or 8)
		x = 30
	end
	local tb = new("TextBox", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -(x + 8), 1, 0), Text = obj.Value,
		ClearTextOnFocus = opts.ClearOnFocus == true, PlaceholderText = "", Font = FONT.Medium, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, MultiLine = multiline, TextWrapped = multiline,
		TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, Parent = field,
	})
	new("UIPadding", { PaddingTop = UDim.new(0, multiline and 8 or 0), Parent = tb })
	lib:Bind(tb, "TextColor3", "Text")
	lib:Bind(tb, "PlaceholderColor3", "Muted")
	lib:BindText(tb, opts.Placeholder or "", "PlaceholderText")
	connect(tb.Focused, function()
		tween(fstroke, 0.15, { Transparency = 0 })
		fstroke.Color = lib.Theme.Accent
	end)
	local function commit(enter)
		obj.Value = tb.Text
		setFlag(opts, obj.Value)
		fire(opts.Callback, obj.Value, enter)
	end
	connect(tb.FocusLost, function(enter)
		tween(fstroke, 0.15, { Transparency = 0.4 })
		fstroke.Color = lib.Theme.Border
		commit(enter)
	end)
	connect(tb:GetPropertyChangedSignal("Text"), function()
		if opts.Numeric then
			local clean = tb.Text:gsub("[^%d%.%-]", "")
			if clean ~= tb.Text then
				tb.Text = clean
				return
			end
		end
		if opts.MaxLength and #tb.Text > opts.MaxLength then
			tb.Text = tb.Text:sub(1, opts.MaxLength)
			return
		end
		if opts.LiveUpdate then
			commit(false)
		end
	end)
	function obj:Set(v, silent)
		tb.Text = tostring(v or "")
		obj.Value = tb.Text
		setFlag(opts, obj.Value)
		if not silent then
			fire(opts.Callback, obj.Value, false)
		end
	end
	function obj:Get()
		return tb.Text
	end
	function obj:Focus()
		tb:CaptureFocus()
	end
	obj.TextBox = tb
	lib:_Finish(obj, parts, opts, function()
		return obj.Value
	end, function(v)
		obj:Set(v, not Library._fireOnLoad)
	end)
	return obj
end

function SectionClass:AddTextArea(opts)
	opts = merge({}, parseOpts(opts))
	opts.Multiline = true
	return self:AddTextbox(opts)
end

function SectionClass:AddSearchBar(opts)
	opts = merge({}, parseOpts(opts))
	opts.Icon = opts.Icon or "search"
	if opts.LiveUpdate == nil then
		opts.LiveUpdate = true
	end
	opts.Placeholder = opts.Placeholder or "Search..."
	return self:AddTextbox(opts)
end

function SectionClass:AddNumberInput(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 12)
	parts.Hit.Visible = false
	parts.Body.Visible = true
	local min, max, step = opts.Min or 0, opts.Max or 100, opts.Step or opts.Increment or 1
	local obj = { Type = "NumberInput", Value = math.clamp(opts.Default or min, min, max) }
	local field, fstroke = lib:_Field(parts.Body, { Size = UDim2.new(1, 0, 0, 30) })
	local function mk(txt, pos)
		local b = new("TextButton", {
			Text = txt, Font = FONT.Bold, TextSize = 14, AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30),
			Position = pos, ZIndex = 3, Parent = field,
		})
		lib:Bind(b, "TextColor3", "Accent")
		return b
	end
	local minus = mk("-", UDim2.fromOffset(0, 0))
	local plus = new("TextButton", {
		Text = "+", Font = FONT.Bold, TextSize = 14, AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30),
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), ZIndex = 3, Parent = field,
	})
	lib:Bind(plus, "TextColor3", "Accent")
	local tb = new("TextBox", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -60, 1, 0), Text = "", Font = FONT.Bold,
		TextSize = 12, ClearTextOnFocus = false, Parent = field,
	})
	lib:Bind(tb, "TextColor3", "Text")
	local function render()
		tb.Text = fmtNum(obj.Value, step)
		setFlag(opts, obj.Value)
	end
	render()
	local function set(v, silent)
		v = math.clamp(snap(tonumber(v) or obj.Value, min, max, step), min, max)
		local changed = v ~= obj.Value
		obj.Value = v
		render()
		if changed and not silent then
			fire(opts.Callback, v)
		end
	end
	connect(tb.FocusLost, function()
		set(tb.Text)
	end)
	connect(minus.Activated, function()
		if not (obj.Disabled or obj.Locked) then
			set(obj.Value - step)
		end
	end)
	connect(plus.Activated, function()
		if not (obj.Disabled or obj.Locked) then
			set(obj.Value + step)
		end
	end)
	function obj:Set(v, silent)
		set(v, silent)
	end
	function obj:Get()
		return obj.Value
	end
	lib:_Finish(obj, parts, opts, function()
		return obj.Value
	end, function(v)
		set(v, not Library._fireOnLoad)
	end)
	return obj
end

--==================================================================
-- Keybind
--==================================================================
function SectionClass:AddKeybind(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 90)
	local obj = { Type = "Keybind", KeybindValue = opts.Default }
	local chip = new("TextButton", {
		Name = "Chip", Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, AutoButtonColor = false, Font = FONT.Bold,
		TextSize = 11, ZIndex = 4, Text = "", Parent = parts.Right,
	})
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = chip })
	lib:Bind(chip, "BackgroundColor3", "Secondary")
	lib:Bind(chip, "TextColor3", "Accent")
	lib:_Round(chip, 0.45)
	parts.Hit.Visible = false
	local listening = false
	local function render()
		chip.Text = listening and "..." or (obj.KeybindValue and obj.KeybindValue.Name or "None")
		setFlag(opts, obj.KeybindValue and obj.KeybindValue.Name or "")
	end
	render()
	connect(chip.Activated, function()
		if obj.Disabled or obj.Locked then
			return
		end
		listening = true
		render()
	end)
	connect(UserInputService.InputBegan, function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				if input.KeyCode == Enum.KeyCode.Escape then
					obj.KeybindValue = nil
				else
					obj.KeybindValue = input.KeyCode
				end
				render()
				fire(opts.Callback, obj.KeybindValue)
			end
			return
		end
		if processed or obj.Disabled or obj.Locked then
			return
		end
		if obj.KeybindValue and input.KeyCode == obj.KeybindValue then
			fire(opts.OnPress)
		end
	end)
	function obj:SetKeybind(k)
		obj.KeybindValue = k
		render()
	end
	function obj:GetKeybind()
		return obj.KeybindValue
	end
	function obj:Set(k, silent)
		obj.KeybindValue = (typeof(k) == "EnumItem") and k or (Enum.KeyCode[tostring(k)])
		render()
		if not silent then
			fire(opts.Callback, obj.KeybindValue)
		end
	end
	function obj:Get()
		return obj.KeybindValue
	end
	lib._keybinds[#lib._keybinds + 1] = obj
	lib:_Finish(obj, parts, opts, function()
		return obj.KeybindValue and obj.KeybindValue.Name or ""
	end, function(v)
		obj:Set(v ~= "" and v or nil, not Library._fireOnLoad)
	end)
	return obj
end

--==================================================================
-- Dropdown (single / multi / searchable)
--==================================================================
local function normalizeOptions(list)
	local out = {}
	for _, o in ipairs(list or {}) do
		if type(o) == "table" then
			if o.Header then
				out[#out + 1] = { header = true, Name = o.Header }
			else
				out[#out + 1] = {
					Name = o.Name or tostring(o.Value), Value = o.Value ~= nil and o.Value or o.Name,
					Description = o.Description, Icon = o.Icon,
				}
			end
		else
			out[#out + 1] = { Name = tostring(o), Value = o }
		end
	end
	return out
end

function SectionClass:AddDropdown(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local multi = opts.Multi == true
	local parts = lib:_BuildRow(self, opts, 150)
	parts.Hit.Size = UDim2.new(1, 0, 0, 38)
	local obj = { Type = "Dropdown", Multi = multi, Value = nil, Selected = {}, Options = normalizeOptions(opts.Options or opts.Values) }

	local valLbl = lib:_Text(parts.Right, false, 12, FONT.Medium, "Muted", {
		Size = UDim2.fromOffset(100, 20), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 2,
	})
	local chev = lib:Icon(parts.Right, "chevron-down", 16, "Muted")
	chev.LayoutOrder = 3

	local ex = lib:_Expander(parts, 120)
	local searchH = opts.Searchable and 34 or 0
	local footerH = multi and 30 or 0

	local searchBox
	if opts.Searchable then
		local f = lib:_Field(ex.Panel, { Size = UDim2.new(1, 0, 0, 30) })
		local si = lib:Icon(f, "search", 14, "Muted")
		si.Position = UDim2.fromOffset(9, 8)
		searchBox = new("TextBox", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -36, 1, 0), Text = "", ClearTextOnFocus = false,
			PlaceholderText = "", Font = FONT.Medium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
		})
		lib:Bind(searchBox, "TextColor3", "Text")
		lib:Bind(searchBox, "PlaceholderColor3", "Muted")
		lib:BindText(searchBox, "Search...", "PlaceholderText")
	end

	local list = new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, searchH), Size = UDim2.new(1, 0, 0, 100),
		ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = ex.Panel,
	})
	lib:Bind(list, "ScrollBarImageColor3", "Accent")
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	new("UIPadding", { PaddingRight = UDim.new(0, 5), Parent = list })

	local footer
	if multi then
		footer = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = ex.Panel })
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = footer,
		})
	end

	local itemFrames = {}

	local function valueArray()
		local arr = {}
		for _, o in ipairs(obj.Options) do
			if not o.header and obj.Selected[o.Value] then
				arr[#arr + 1] = o.Value
			end
		end
		return arr
	end

	local function refreshText()
		if multi then
			local names = {}
			for _, o in ipairs(obj.Options) do
				if not o.header and obj.Selected[o.Value] then
					names[#names + 1] = lib:Translate(o.Name)
				end
			end
			if #names == 0 then
				valLbl.Text = lib:Translate(opts.Placeholder or "Select...")
			elseif #names <= 2 then
				valLbl.Text = table.concat(names, ", ")
			else
				valLbl.Text = #names .. " selected"
			end
		else
			local name
			for _, o in ipairs(obj.Options) do
				if not o.header and o.Value == obj.Value then
					name = lib:Translate(o.Name)
				end
			end
			valLbl.Text = name or lib:Translate(opts.Placeholder or "Select...")
		end
	end

	local function layout()
		local h = 0
		for _, it in ipairs(itemFrames) do
			if it.frame.Visible then
				h = h + it.h + 2
			end
		end
		local listH = math.clamp(h, 20, 150)
		list.Size = UDim2.new(1, 0, 0, listH)
		if footer then
			footer.Position = UDim2.fromOffset(0, searchH + listH + 4)
		end
		ex:Resize(searchH + listH + (multi and footerH or 0) + 2)
	end

	local function paint()
		for _, it in ipairs(itemFrames) do
			if not it.header then
				local on
				if multi then
					on = obj.Selected[it.value] == true
				else
					on = obj.Value == it.value
				end
				tween(it.label, 0.12, { TextColor3 = on and lib.Theme.Accent or lib.Theme.Text })
				tween(it.check, 0.12, { ImageTransparency = on and 0 or 1 })
			end
		end
	end

	local function fireCb()
		setFlag(opts, multi and valueArray() or obj.Value)
		fire(opts.Callback, multi and valueArray() or obj.Value)
	end

	local function rebuild()
		for _, it in ipairs(itemFrames) do
			it.frame:Destroy()
		end
		itemFrames = {}
		for i, o in ipairs(obj.Options) do
			if o.header then
				local hd = lib:_Text(list, o.Name, 10, FONT.Bold, "Muted", {
					Size = UDim2.new(1, 0, 0, 22), LayoutOrder = i, TextTransparency = 0.2,
				})
				itemFrames[#itemFrames + 1] = { frame = hd, h = 22, header = true, name = o.Name }
			else
				local b = new("TextButton", {
					Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, Parent = list,
				})
				lib:Bind(b, "BackgroundColor3", "Hover")
				lib:_Round(b, 0.45)
				local x = 8
				if o.Icon then
					local ic = lib:Icon(b, o.Icon, 14, "Accent")
					ic.Position = UDim2.fromOffset(8, 7)
					x = 28
				end
				local lbl = lib:_Text(b, o.Name, 12, FONT.Medium, "Text", { Position = UDim2.fromOffset(x, 0), Size = UDim2.new(0.6, -x, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
				if o.Description then
					lib:_Text(b, o.Description, 10, FONT.Regular, "Muted", {
						AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -28, 0, 0), Size = UDim2.new(0.4, -30, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
					})
				end
				local check = lib:Icon(b, "check", 14, "Accent")
				check.AnchorPoint = Vector2.new(1, 0.5)
				check.Position = UDim2.new(1, -8, 0.5, 0)
				check.ImageTransparency = 1
				check.Visible = true
				connect(b.MouseEnter, function()
					tween(b, 0.1, { BackgroundTransparency = 0.6 })
				end)
				connect(b.MouseLeave, function()
					tween(b, 0.12, { BackgroundTransparency = 1 })
				end)
				connect(b.Activated, function()
					if obj.Disabled or obj.Locked then
						return
					end
					if multi then
						obj.Selected[o.Value] = not obj.Selected[o.Value] or nil
					else
						obj.Value = o.Value
						if not opts.KeepOpen then
							ex:Close()
						end
					end
					paint()
					refreshText()
					fireCb()
				end)
				itemFrames[#itemFrames + 1] = { frame = b, h = 28, label = lbl, check = check, value = o.Value, name = o.Name }
			end
		end
		paint()
		refreshText()
		layout()
	end

	if searchBox then
		connect(searchBox:GetPropertyChangedSignal("Text"), function()
			local q = string.lower(searchBox.Text)
			for _, it in ipairs(itemFrames) do
				if q == "" then
					it.frame.Visible = true
				else
					it.frame.Visible = (not it.header) and string.find(string.lower(lib:Translate(it.name)), q, 1, true) ~= nil
				end
			end
			layout()
		end)
	end

	local function setSelection(v)
		obj.Selected = {}
		if multi then
			for _, x in ipairs(type(v) == "table" and v or {}) do
				obj.Selected[x] = true
			end
		else
			obj.Value = v
		end
	end
	if opts.Default ~= nil then
		setSelection(opts.Default)
	end

	if multi then
		lib:_SmallButton(footer, "Select All", function()
			for _, o in ipairs(obj.Options) do
				if not o.header then
					obj.Selected[o.Value] = true
				end
			end
			paint()
			refreshText()
			fireCb()
		end)
		lib:_SmallButton(footer, "Clear", function()
			obj.Selected = {}
			paint()
			refreshText()
			fireCb()
		end)
	end

	ex.OnToggle = function(open)
		tween(chev, 0.2, { Rotation = open and 180 or 0 })
	end
	connect(parts.Hit.Activated, function()
		if obj.Disabled or obj.Locked then
			return
		end
		ex:Toggle()
	end)

	rebuild()

	function obj:Set(v, silent)
		setSelection(v)
		paint()
		refreshText()
		setFlag(opts, multi and valueArray() or obj.Value)
		if not silent then
			fire(opts.Callback, multi and valueArray() or obj.Value)
		end
	end
	function obj:Get()
		return multi and valueArray() or obj.Value
	end
	function obj:GetSelected()
		return valueArray()
	end
	function obj:SelectAll()
		for _, o in ipairs(obj.Options) do
			if not o.header then
				obj.Selected[o.Value] = true
			end
		end
		paint()
		refreshText()
		fireCb()
	end
	function obj:ClearSelection()
		obj.Selected = {}
		obj.Value = nil
		paint()
		refreshText()
		fireCb()
	end
	function obj:SetOptions(list, keep)
		obj.Options = normalizeOptions(list)
		if not keep then
			obj.Selected = {}
			obj.Value = nil
		end
		rebuild()
	end
	function obj:Open()
		ex:Open()
	end
	function obj:Close()
		ex:Close()
	end

	lib:_Finish(obj, parts, opts, function()
		return multi and valueArray() or obj.Value
	end, function(v)
		obj:Set(v, not Library._fireOnLoad)
	end)
	return obj
end

function SectionClass:AddMultiDropdown(opts)
	opts = merge({}, parseOpts(opts))
	opts.Multi = true
	return self:AddDropdown(opts)
end

function SectionClass:AddSearchableDropdown(opts)
	opts = merge({}, parseOpts(opts))
	opts.Searchable = true
	return self:AddDropdown(opts)
end

--==================================================================
-- Color picker / gradient picker
--==================================================================
function SectionClass:AddColorPicker(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 52)
	parts.Hit.Size = UDim2.new(1, 0, 0, 38)
	local obj = { Type = "ColorPicker", Value = opts.Default or Color3.fromRGB(140, 100, 255) }
	local h, s, v = obj.Value:ToHSV()

	local swatch = new("Frame", { Size = UDim2.fromOffset(30, 18), Parent = parts.Right })
	new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = swatch })
	local sws = new("UIStroke", { Thickness = 1, Transparency = 0.2, Parent = swatch })
	lib:Bind(sws, "Color", "Stroke")

	local ex = lib:_Expander(parts, 152)
	local sv = new("Frame", { Size = UDim2.new(1, 0, 0, 96), ClipsDescendants = true, Parent = ex.Panel })
	lib:_Round(sv, 0.5)
	local white = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sv })
	new("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
	local black = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv })
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
	local svMarker = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 3, Parent = sv,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = svMarker })
	new("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Parent = svMarker })
	local svArea = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = sv })

	local hue = new("Frame", { Position = UDim2.fromOffset(0, 102), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = Color3.new(1, 1, 1), Parent = ex.Panel })
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hue })
	local keys = {}
	for i = 0, 6 do
		keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, 0.9999), 1, 1))
	end
	new("UIGradient", { Color = ColorSequence.new(keys), Parent = hue })
	local hueMarker = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 18), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = hue,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 3), Parent = hueMarker })
	new("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.5, Parent = hueMarker })
	local hueArea = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = hue })

	local hexField = lib:_Field(ex.Panel, { Position = UDim2.fromOffset(0, 122), Size = UDim2.new(1, 0, 0, 28) })
	local hexBox = new("TextBox", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), Font = FONT.Bold, TextSize = 12,
		ClearTextOnFocus = false, Text = "", Parent = hexField,
	})
	lib:Bind(hexBox, "TextColor3", "Text")

	local function apply(silent, fromHex)
		obj.Value = Color3.fromHSV(h, s, v)
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svMarker.Position = UDim2.new(s, 0, 1 - v, 0)
		hueMarker.Position = UDim2.new(h, 0, 0.5, 0)
		swatch.BackgroundColor3 = obj.Value
		if not fromHex then
			hexBox.Text = toHex(obj.Value)
		end
		if opts.Flag then
			Library.Flags[opts.Flag] = toHex(obj.Value)
		end
		if not silent then
			fire(opts.Callback, obj.Value)
		end
	end
	apply(true)

	lib:_DragArea(svArea, function(pos)
		if obj.Disabled or obj.Locked then
			return
		end
		s = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
		v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
		apply(false)
	end)
	lib:_DragArea(hueArea, function(pos)
		if obj.Disabled or obj.Locked then
			return
		end
		h = math.clamp((pos.X - hue.AbsolutePosition.X) / math.max(hue.AbsoluteSize.X, 1), 0, 0.9999)
		apply(false)
	end)
	connect(hexBox.FocusLost, function()
		local c = fromHex(hexBox.Text)
		if c then
			h, s, v = c:ToHSV()
			apply(false, false)
		else
			hexBox.Text = toHex(obj.Value)
		end
	end)

	connect(parts.Hit.Activated, function()
		if obj.Disabled or obj.Locked then
			return
		end
		ex:Toggle()
	end)

	function obj:Set(c, silent)
		if typeof(c) == "string" then
			c = fromHex(c)
		end
		if typeof(c) == "Color3" then
			h, s, v = c:ToHSV()
			apply(silent)
		end
	end
	function obj:Get()
		return obj.Value
	end
	lib:_Finish(obj, parts, opts, function()
		return toHex(obj.Value)
	end, function(x)
		obj:Set(x, not Library._fireOnLoad)
	end)
	return obj
end

function SectionClass:AddGradientPicker(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local obj = { Type = "GradientPicker" }
	local a = opts.DefaultA or Color3.fromRGB(163, 128, 255)
	local b = opts.DefaultB or Color3.fromRGB(112, 84, 240)
	local prev = self:AddParagraph({ Name = opts.Name or "Gradient", Content = "" })
	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = Color3.new(1, 1, 1), Parent = prev.Frame })
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
	local grad = new("UIGradient", { Parent = bar })
	local function render(silent)
		grad.Color = ColorSequence.new(a, b)
		obj.Value = ColorSequence.new(a, b)
		if not silent then
			fire(opts.Callback, a, b, obj.Value)
		end
	end
	render(true)
	obj.A = self:AddColorPicker({ Name = "Color A", Default = a, Flag = opts.Flag and (opts.Flag .. ".A"), Callback = function(c)
		a = c
		render(false)
	end })
	obj.B = self:AddColorPicker({ Name = "Color B", Default = b, Flag = opts.Flag and (opts.Flag .. ".B"), Callback = function(c)
		b = c
		render(false)
	end })
	function obj:Set(c1, c2, silent)
		a, b = c1 or a, c2 or b
		obj.A:Set(a, true)
		obj.B:Set(b, true)
		render(silent)
	end
	function obj:Get()
		return obj.Value
	end
	obj.Frame = prev.Frame
	return obj
end

--==================================================================
-- Date / Time / File pickers
--==================================================================
local MONTHS = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }

function SectionClass:AddDatePicker(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 100)
	parts.Hit.Size = UDim2.new(1, 0, 0, 38)
	local now = os.date("*t")
	local d = opts.Default or { Year = now.year, Month = now.month, Day = now.day }
	local obj = { Type = "DatePicker", Value = { Year = d.Year, Month = d.Month, Day = d.Day } }
	local view = { Year = d.Year, Month = d.Month }

	local valLbl = lib:_Text(parts.Right, false, 12, FONT.Bold, "Accent", {
		Size = UDim2.fromOffset(80, 20), TextXAlignment = Enum.TextXAlignment.Right,
	})
	local ex = lib:_Expander(parts, 196)
	local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Parent = ex.Panel })
	local prevB = new("TextButton", { Text = "<", Font = FONT.Bold, TextSize = 14, BackgroundTransparency = 1, Size = UDim2.fromOffset(28, 24), Parent = head })
	lib:Bind(prevB, "TextColor3", "Accent")
	local nextB = new("TextButton", {
		Text = ">", Font = FONT.Bold, TextSize = 14, BackgroundTransparency = 1, Size = UDim2.fromOffset(28, 24),
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Parent = head,
	})
	lib:Bind(nextB, "TextColor3", "Accent")
	local title = lib:_Text(head, false, 12, FONT.Bold, "Text", {
		Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -56, 1, 0), TextXAlignment = Enum.TextXAlignment.Center,
	})
	local grid = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 166), Parent = ex.Panel })
	new("UIGridLayout", {
		CellSize = UDim2.new(1 / 7, -3, 0, 22), CellPadding = UDim2.fromOffset(3, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid,
	})

	local function pad(n)
		return string.format("%02d", n)
	end
	local function render()
		valLbl.Text = string.format("%d-%s-%s", obj.Value.Year, pad(obj.Value.Month), pad(obj.Value.Day))
		setFlag(opts, valLbl.Text)
	end
	local function build()
		for _, c in ipairs(grid:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		title.Text = MONTHS[view.Month] .. " " .. view.Year
		for i, w in ipairs({ "S", "M", "T", "W", "T", "F", "S" }) do
			lib:_Text(grid, false, 10, FONT.Bold, "Muted", { Text = w, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = i })
		end
		local first = os.date("*t", os.time({ year = view.Year, month = view.Month, day = 1, hour = 12 })).wday
		local days = os.date("*t", os.time({ year = view.Year, month = view.Month + 1, day = 0, hour = 12 })).day
		for i = 1, first - 1 do
			new("Frame", { BackgroundTransparency = 1, LayoutOrder = 7 + i, Parent = grid })
		end
		for day = 1, days do
			local sel = obj.Value.Year == view.Year and obj.Value.Month == view.Month and obj.Value.Day == day
			local b = new("TextButton", {
				Text = tostring(day), Font = FONT.Medium, TextSize = 11, AutoButtonColor = false, LayoutOrder = 7 + first - 1 + day,
				BackgroundTransparency = sel and 0 or 1, Parent = grid,
			})
			b.BackgroundColor3 = lib.Theme.Accent
			b.TextColor3 = sel and Color3.new(1, 1, 1) or lib.Theme.Text
			lib:_Round(b, 0.45)
			connect(b.Activated, function()
				if obj.Disabled or obj.Locked then
					return
				end
				obj.Value = { Year = view.Year, Month = view.Month, Day = day }
				render()
				build()
				fire(opts.Callback, obj.Value, valLbl.Text)
			end)
		end
	end
	connect(prevB.Activated, function()
		view.Month = view.Month - 1
		if view.Month < 1 then
			view.Month = 12
			view.Year = view.Year - 1
		end
		build()
	end)
	connect(nextB.Activated, function()
		view.Month = view.Month + 1
		if view.Month > 12 then
			view.Month = 1
			view.Year = view.Year + 1
		end
		build()
	end)
	render()
	build()
	connect(parts.Hit.Activated, function()
		if not (obj.Disabled or obj.Locked) then
			ex:Toggle()
		end
	end)
	function obj:Get()
		return obj.Value, valLbl.Text
	end
	function obj:Set(t, silent)
		if type(t) == "table" and t.Year then
			obj.Value = { Year = t.Year, Month = t.Month, Day = t.Day }
			view.Year, view.Month = t.Year, t.Month
			render()
			build()
			if not silent then
				fire(opts.Callback, obj.Value, valLbl.Text)
			end
		end
	end
	lib:_Finish(obj, parts, opts, function()
		return valLbl.Text
	end, function(x)
		local y, m, dd = tostring(x):match("(%d+)-(%d+)-(%d+)")
		if y then
			obj:Set({ Year = tonumber(y), Month = tonumber(m), Day = tonumber(dd) }, true)
		end
	end)
	return obj
end

function SectionClass:AddTimePicker(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 70)
	parts.Hit.Visible = false
	local d = opts.Default or { Hour = 12, Minute = 0 }
	local obj = { Type = "TimePicker", Hour = d.Hour, Minute = d.Minute }
	local function mk(txt, order)
		local b = new("TextButton", {
			Text = txt, Font = FONT.Bold, TextSize = 13, AutoButtonColor = false, Size = UDim2.fromOffset(20, 22), LayoutOrder = order, ZIndex = 4, Parent = parts.Right,
		})
		lib:Bind(b, "BackgroundColor3", "Secondary")
		lib:Bind(b, "TextColor3", "Accent")
		lib:_Round(b, 0.4)
		return b
	end
	local hm = mk("-", 1)
	local hv = lib:_Text(parts.Right, false, 12, FONT.Bold, "Text", { Size = UDim2.fromOffset(22, 22), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2 })
	local hp = mk("+", 3)
	lib:_Text(parts.Right, false, 12, FONT.Bold, "Muted", { Text = ":", Size = UDim2.fromOffset(6, 22), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 4 })
	local mm = mk("-", 5)
	local mv = lib:_Text(parts.Right, false, 12, FONT.Bold, "Text", { Size = UDim2.fromOffset(22, 22), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 6 })
	local mp = mk("+", 7)
	local function render()
		hv.Text = string.format("%02d", obj.Hour)
		mv.Text = string.format("%02d", obj.Minute)
		setFlag(opts, hv.Text .. ":" .. mv.Text)
	end
	render()
	local function change(hd, md)
		if obj.Disabled or obj.Locked then
			return
		end
		obj.Hour = (obj.Hour + hd) % 24
		obj.Minute = (obj.Minute + md) % 60
		render()
		fire(opts.Callback, obj.Hour, obj.Minute, hv.Text .. ":" .. mv.Text)
	end
	connect(hm.Activated, function()
		change(-1, 0)
	end)
	connect(hp.Activated, function()
		change(1, 0)
	end)
	connect(mm.Activated, function()
		change(0, -(opts.MinuteStep or 5))
	end)
	connect(mp.Activated, function()
		change(0, opts.MinuteStep or 5)
	end)
	function obj:Get()
		return obj.Hour, obj.Minute
	end
	function obj:Set(h, m, silent)
		obj.Hour, obj.Minute = h % 24, m % 60
		render()
		if not silent then
			fire(opts.Callback, obj.Hour, obj.Minute)
		end
	end
	lib:_Finish(obj, parts, opts, function()
		return hv.Text .. ":" .. mv.Text
	end, function(x)
		local hh, mi = tostring(x):match("(%d+):(%d+)")
		if hh then
			obj:Set(tonumber(hh), tonumber(mi), true)
		end
	end)
	return obj
end

function SectionClass:AddFilePicker(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 120)
	parts.Hit.Size = UDim2.new(1, 0, 0, 38)
	local obj = { Type = "FilePicker", Value = opts.Default, Folder = opts.Folder or "" }
	local valLbl = lib:_Text(parts.Right, false, 12, FONT.Medium, "Muted", {
		Size = UDim2.fromOffset(100, 20), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local ex = lib:_Expander(parts, 150)
	local pathLbl = lib:_Text(ex.Panel, false, 10, FONT.Bold, "Muted", { Size = UDim2.new(1, 0, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd })
	local list = new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 1, -20), ScrollBarThickness = 3,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = ex.Panel,
	})
	lib:Bind(list, "ScrollBarImageColor3", "Accent")
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local function shortName(p)
		return tostring(p):match("([^/\\]+)$") or tostring(p)
	end
	local function render()
		valLbl.Text = obj.Value and shortName(obj.Value) or lib:Translate("Select...")
		setFlag(opts, obj.Value or "")
	end
	local function browse(folder)
		obj.Folder = folder
		pathLbl.Text = folder == "" and "/" or folder
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		if type(listfiles) ~= "function" then
			lib:_Text(list, "File access is not available.", 11, FONT.Regular, "Muted", { Size = UDim2.new(1, 0, 0, 22) })
			return
		end
		local ok, entries = pcall(listfiles, folder)
		if not ok then
			entries = {}
		end
		local order = 0
		local function add(label, iconName, cb)
			order = order + 1
			local b = new("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = order, Parent = list,
			})
			lib:Bind(b, "BackgroundColor3", "Hover")
			lib:_Round(b, 0.4)
			local ic = lib:Icon(b, iconName, 14, "Accent")
			ic.Position = UDim2.fromOffset(6, 5)
			lib:_Text(b, false, 11, FONT.Medium, "Text", { Text = label, Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -30, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
			connect(b.MouseEnter, function()
				tween(b, 0.1, { BackgroundTransparency = 0.6 })
			end)
			connect(b.MouseLeave, function()
				tween(b, 0.12, { BackgroundTransparency = 1 })
			end)
			connect(b.Activated, cb)
		end
		if folder ~= "" then
			add("..", "corner-left-up", function()
				browse(folder:match("^(.*)[/\\][^/\\]*$") or "")
			end)
		end
		for _, p in ipairs(entries) do
			local isDir = type(isfolder) == "function" and isfolder(p)
			if isDir then
				add(shortName(p), "folder", function()
					browse(p)
				end)
			elseif not opts.Extensions or table.find(opts.Extensions, (p:match("%.([^%.]+)$") or ""):lower()) then
				add(shortName(p), "file", function()
					obj.Value = p
					render()
					ex:Close()
					fire(opts.Callback, p)
				end)
			end
		end
	end
	render()
	ex.OnToggle = function(open)
		if open then
			browse(obj.Folder)
		end
	end
	connect(parts.Hit.Activated, function()
		if not (obj.Disabled or obj.Locked) then
			ex:Toggle()
		end
	end)
	function obj:Get()
		return obj.Value
	end
	function obj:Set(p, silent)
		obj.Value = p
		render()
		if not silent then
			fire(opts.Callback, p)
		end
	end
	lib:_Finish(obj, parts, opts, function()
		return obj.Value or ""
	end, function(x)
		obj:Set(x ~= "" and x or nil, not Library._fireOnLoad)
	end)
	return obj
end

-- aliases
SectionClass.AddSwitch = SectionClass.AddToggle
SectionClass.AddRadioButton = SectionClass.AddRadio
SectionClass.AddStarRating = SectionClass.AddRating
SectionClass.AddCounter = SectionClass.AddStepper
SectionClass.AddInput = SectionClass.AddTextbox
SectionClass.AddInputField = SectionClass.AddTextbox
SectionClass.AddDualSlider = SectionClass.AddRangeSlider
SectionClass.AddMultiSelectMenu = SectionClass.AddMultiDropdown
SectionClass.AddSelectMenu = SectionClass.AddDropdown
SectionClass.AddColorGradientPicker = SectionClass.AddGradientPicker

--==================================================================
-- PART 3: Overlays, window extras, layout components
--==================================================================
local TYPE_ICON = { Success = "circle-check", Warning = "triangle-alert", Error = "circle-x", Info = "info" }

function Library:_Host(win)
	if win and win.Root then
		return win.Root
	end
	return self.Gui
end

-- Dim overlay that dismisses on click. Returns overlay, close()
function Library:_Backdrop(host, z, dim, onClose)
	local overlay = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = z, Parent = host,
	})
	if dim and dim > 0 then
		tween(overlay, 0.2, { BackgroundTransparency = 1 - dim })
	end
	local closed = false
	local function close(after)
		if closed then
			return
		end
		closed = true
		tween(overlay, 0.18, { BackgroundTransparency = 1 })
		task.delay(dur(0.22), function()
			overlay:Destroy()
		end)
		if after then
			after()
		end
	end
	connect(overlay.Activated, function()
		if onClose then
			onClose(close)
		else
			close()
		end
	end)
	return overlay, close
end

function Library:_Panel(parent, z, radiusMult)
	local p = new("CanvasGroup", { BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = z, Active = true, Parent = parent })
	self:Bind(p, "BackgroundColor3", "Surface")
	self:BindCorner(new("UICorner", { Parent = p }), radiusMult or 1)
	local s = new("UIStroke", { Thickness = 1, Parent = p })
	self:Bind(s, "Color", "Stroke")
	return p, s
end

--------------------------------------------------------------------
-- Modal / Dialog / Alert / Confirmation
--------------------------------------------------------------------
function Library:Modal(opts)
	opts = opts or {}
	local lib = self
	local host = self:_Host(opts.Window)
	local obj = {}
	local overlay, close = self:_Backdrop(host, 120, 0.55, function(c)
		if opts.Dismissable ~= false then
			c()
		end
	end)
	local width = math.min(opts.Width or 320, (host.AbsoluteSize.X > 0 and host.AbsoluteSize.X or 600) - 30)
	local dlg = self:_Panel(overlay, 121)
	dlg.AnchorPoint = Vector2.new(0.5, 0.5)
	dlg.Position = UDim2.fromScale(0.5, 0.5)
	dlg.Size = UDim2.fromOffset(width, 0)
	dlg.AutomaticSize = Enum.AutomaticSize.Y
	dlg.GroupTransparency = 1
	local sc = new("UIScale", { Scale = 0.9, Parent = dlg })
	local inner = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = dlg })
	new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16), Parent = inner })
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })

	local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = inner })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), Parent = head })
	local ticon = opts.Icon or TYPE_ICON[opts.Type or ""]
	if ticon then
		local ic = self:Icon(head, ticon, 18, nil)
		ic.ImageColor3 = self.Theme[opts.Type or "Accent"] or self.Theme.Accent
	end
	self:_Text(head, opts.Title or "Dialog", 15, FONT.Bold, "Text", { Size = UDim2.new(1, -30, 1, 0) })
	if opts.Message then
		self:_Text(inner, opts.Message, 12, FONT.Regular, "Muted", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = 2,
		})
	end
	local body = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = inner })
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
	obj.Body = body
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 4, Parent = inner })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = row,
	})
	local buttons = opts.Buttons or { { Text = "OK", Primary = true } }
	for i, b in ipairs(buttons) do
		local btn = self:_SmallButton(row, b.Text or "OK", function()
			if b.Callback then
				fire(b.Callback)
			end
			if b.Close ~= false then
				obj:Close()
			end
		end, b.Primary and "primary" or nil)
		btn.LayoutOrder = i
		btn.Size = UDim2.fromOffset(0, 30)
	end
	function obj:Close()
		tween(dlg, 0.18, { GroupTransparency = 1 })
		tween(sc, 0.18, { Scale = 0.92 })
		close()
		if opts.OnClose then
			fire(opts.OnClose)
		end
	end
	tween(dlg, 0.2, { GroupTransparency = 0 })
	tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	return obj
end
Library.Dialog = Library.Modal

function Library:Alert(opts)
	opts = merge({}, opts)
	opts.Type = opts.Type or "Info"
	opts.Buttons = opts.Buttons or { { Text = "OK", Primary = true } }
	return self:Modal(opts)
end

function Library:ConfirmDialog(opts)
	opts = merge({}, opts)
	local yes, no = opts.OnYes, opts.OnNo
	opts.Buttons = {
		{ Text = opts.No or "No", Callback = no },
		{ Text = opts.Yes or "Yes", Primary = true, Callback = yes },
	}
	return self:Modal(opts)
end

--------------------------------------------------------------------
-- Context menu / Popover
--------------------------------------------------------------------
function Library:ContextMenu(items, pos)
	local lib = self
	pos = pos or UserInputService:GetMouseLocation()
	local overlay, close = self:_Backdrop(self.Gui, 200, 0)
	local menu = self:_Panel(overlay, 201, 0.8)
	menu.Size = UDim2.fromOffset(170, 0)
	menu.AutomaticSize = Enum.AutomaticSize.Y
	local vp = getViewport()
	menu.Position = UDim2.fromOffset(math.min(pos.X, vp.X - 180), math.min(pos.Y, vp.Y - (#items * 28 + 16)))
	new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = menu })
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	menu.GroupTransparency = 1
	tween(menu, 0.15, { GroupTransparency = 0 })
	for i, it in ipairs(items or {}) do
		if it.Divider then
			local d = new("Frame", { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = i, Parent = menu })
			self:Bind(d, "BackgroundColor3", "Border")
		else
			local b = new("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = i, ZIndex = 202, Parent = menu,
			})
			self:Bind(b, "BackgroundColor3", "Hover")
			self:_Round(b, 0.45)
			local x = 8
			if it.Icon then
				local ic = self:Icon(b, it.Icon, 14, it.Danger and "Error" or "Accent")
				ic.Position = UDim2.fromOffset(8, 6)
				x = 28
			end
			self:_Text(b, it.Name or "", 12, FONT.Medium, it.Danger and "Error" or "Text", { Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x, 1, 0), ZIndex = 203 })
			connect(b.MouseEnter, function()
				tween(b, 0.1, { BackgroundTransparency = 0.6 })
			end)
			connect(b.MouseLeave, function()
				tween(b, 0.12, { BackgroundTransparency = 1 })
			end)
			connect(b.Activated, function()
				close()
				fire(it.Callback)
			end)
		end
	end
	return { Close = close }
end

function Library:AttachContextMenu(guiObj, items)
	connect(guiObj.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:ContextMenu(type(items) == "function" and items() or items)
		end
	end)
end

function Library:Popover(anchor, opts)
	opts = opts or {}
	local overlay, close = self:_Backdrop(self.Gui, 200, 0)
	local pop = self:_Panel(overlay, 201, 0.9)
	pop.Size = UDim2.fromOffset(opts.Width or 200, 0)
	pop.AutomaticSize = Enum.AutomaticSize.Y
	local vp = getViewport()
	local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
	pop.Position = UDim2.fromOffset(math.clamp(ap.X, 6, vp.X - (opts.Width or 200) - 6), math.min(ap.Y + as.Y + 6, vp.Y - 100))
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = pop })
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = pop })
	if opts.Title then
		self:_Text(pop, opts.Title, 13, FONT.Bold, "Text", { Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1 })
	end
	if opts.Content then
		self:_Text(pop, opts.Content, 12, FONT.Regular, "Muted", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = 2,
		})
	end
	pop.GroupTransparency = 1
	tween(pop, 0.18, { GroupTransparency = 0 })
	return { Close = close, Frame = pop }
end

--------------------------------------------------------------------
-- Command palette / global search
--------------------------------------------------------------------
function Library:RegisterCommand(cmd)
	table.insert(self._commands, cmd)
	return cmd
end

function WindowClass:GoTo(page)
	local tab = page.Tab or page
	self:SelectTab(tab)
	if page ~= tab and tab.ActiveSub ~= page then
		if tab.ActiveSub then
			tab.ActiveSub:_SetActive(false)
		end
		tab.ActiveSub = page
		page:_SetActive(true)
		self:_ShowPage(page)
	end
end

function Library:OpenCommandPalette()
	if self._palette then
		return
	end
	local lib = self
	local overlay, close = self:_Backdrop(self.Gui, 300, 0.5, function(c)
		lib._palette = nil
		c()
	end)
	local pal = self:_Panel(overlay, 301, 1)
	pal.AnchorPoint = Vector2.new(0.5, 0)
	pal.Position = UDim2.new(0.5, 0, 0, 70)
	pal.Size = UDim2.fromOffset(math.min(420, getViewport().X - 24), 0)
	pal.AutomaticSize = Enum.AutomaticSize.Y
	pal.GroupTransparency = 1
	local psc = new("UIScale", { Scale = 0.95, Parent = pal })
	tween(pal, 0.18, { GroupTransparency = 0 })
	tween(psc, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = pal })
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = pal })
	local f = self:_Field(pal, { Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 1 })
	local si = self:Icon(f, "search", 14, "Accent")
	si.Position = UDim2.fromOffset(10, 10)
	local tb = new("TextBox", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -40, 1, 0), Text = "", ClearTextOnFocus = false,
		Font = FONT.Medium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, PlaceholderText = "", ZIndex = 302, Parent = f,
	})
	self:Bind(tb, "TextColor3", "Text")
	self:Bind(tb, "PlaceholderColor3", "Muted")
	self:BindText(tb, "Search commands and settings...", "PlaceholderText")
	local list = new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 220), ScrollBarThickness = 3, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = 2, ZIndex = 302, Parent = pal,
	})
	self:Bind(list, "ScrollBarImageColor3", "Accent")
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local function closePal()
		lib._palette = nil
		tween(pal, 0.15, { GroupTransparency = 1 })
		close()
	end
	lib._palette = { Close = closePal }

	local function entries()
		local out = {}
		for _, c in ipairs(lib._commands) do
			out[#out + 1] = { name = c.Name, desc = c.Description, icon = c.Icon or "terminal", run = c.Callback, kind = "Command" }
		end
		for _, w in ipairs(lib.Windows) do
			for _, ix in ipairs(w._index or {}) do
				out[#out + 1] = {
					name = ix.Name, desc = (ix.Tab and ix.Tab.Name or ""), icon = "layers", kind = "Setting",
					run = function()
						for _, other in ipairs(lib.Windows) do
							if other ~= w then
								other:Hide()
							end
						end
						w:Show()
						w:GoTo(ix.Page)
						if ix.Row and ix.Row.Parent then
							local st = ix.Row:FindFirstChildOfClass("UIStroke")
							if st then
								st.Color = lib.Theme.Accent
								tween(st, 0.2, { Transparency = 0 })
								task.delay(1.2, function()
									if st.Parent then
										tween(st, 0.4, { Transparency = 0.4 })
										st.Color = lib.Theme.Border
									end
								end)
							end
						end
					end,
				}
			end
		end
		return out
	end

	local function render()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local q = string.lower(tb.Text)
		local n = 0
		for _, e in ipairs(entries()) do
			local hay = string.lower(lib:Translate(e.name) .. " " .. tostring(e.desc or ""))
			if q == "" or string.find(hay, q, 1, true) then
				n = n + 1
				if n > 40 then
					break
				end
				local b = new("TextButton", {
					Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = n, ZIndex = 303, Parent = list,
				})
				lib:Bind(b, "BackgroundColor3", "Hover")
				lib:_Round(b, 0.5)
				local ic = lib:Icon(b, e.icon, 16, "Accent")
				ic.Position = UDim2.fromOffset(8, 9)
				lib:_Text(b, e.name, 12, FONT.Medium, "Text", { Position = UDim2.fromOffset(34, 2), Size = UDim2.new(1, -110, 0, 16), ZIndex = 304, TextTruncate = Enum.TextTruncate.AtEnd })
				lib:_Text(b, tostring(e.desc or ""), 10, FONT.Regular, "Muted", { Position = UDim2.fromOffset(34, 17), Size = UDim2.new(1, -110, 0, 14), ZIndex = 304, TextTruncate = Enum.TextTruncate.AtEnd })
				lib:_Text(b, e.kind, 10, FONT.Bold, "Muted", {
					AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(60, 34), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 304,
				})
				connect(b.MouseEnter, function()
					tween(b, 0.1, { BackgroundTransparency = 0.6 })
				end)
				connect(b.MouseLeave, function()
					tween(b, 0.12, { BackgroundTransparency = 1 })
				end)
				connect(b.Activated, function()
					closePal()
					fire(e.run)
				end)
			end
		end
	end
	connect(tb:GetPropertyChangedSignal("Text"), render)
	render()
	tb:CaptureFocus()
end
Library.OpenGlobalSearch = Library.OpenCommandPalette

function Library:CloseCommandPalette()
	if self._palette then
		self._palette.Close()
	end
end

connect(UserInputService.InputBegan, function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.K and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
		if Library._palette then
			Library:CloseCommandPalette()
		elseif Library.Gui then
			Library:OpenCommandPalette()
		end
	end
end)

--------------------------------------------------------------------
-- Banner / Side panel / Bottom sheet
--------------------------------------------------------------------
function WindowClass:Banner(opts)
	opts = opts or {}
	local lib = self.Library
	local kind = opts.Type or "Info"
	local b = new("Frame", {
		Size = UDim2.new(1, -24, 0, 34), Position = UDim2.new(0, 12, 0, -40), ZIndex = 60, BackgroundColor3 = lib.Theme[kind] or lib.Theme.Info, BackgroundTransparency = 0.12, Parent = self.Body,
	})
	lib:BindCorner(new("UICorner", { Parent = b }), 0.65)
	local ic = lib:Icon(b, opts.Icon or TYPE_ICON[kind], 16, nil)
	ic.Position = UDim2.fromOffset(10, 9)
	ic.ImageColor3 = Color3.new(1, 1, 1)
	ic.ZIndex = 61
	local t = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -70, 1, 0), Font = FONT.Bold, TextSize = 12,
		TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 61, Parent = b,
	})
	lib:BindText(t, opts.Text or "")
	local x = new("TextButton", { Text = "×", Font = FONT.Bold, TextSize = 16, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(26, 34), ZIndex = 62, Parent = b })
	local function dismiss()
		tween(b, 0.25, { Position = UDim2.new(0, 12, 0, -40) })
		task.delay(dur(0.3), function()
			b:Destroy()
		end)
	end
	connect(x.Activated, dismiss)
	tween(b, 0.35, { Position = UDim2.new(0, 12, 0, 8) }, Enum.EasingStyle.Back)
	if opts.Duration then
		task.delay(opts.Duration, function()
			if b.Parent then
				dismiss()
			end
		end)
	end
	return { Close = dismiss, Frame = b }
end

local function slidePanel(win, opts, fromBottom)
	local lib = win.Library
	opts = opts or {}
	local overlay, close = lib:_Backdrop(win.Root, 90, 0.4, function(c)
		c()
	end)
	local p = lib:_Panel(overlay, 91, 0.9)
	local obj = {}
	local size = opts.Size or (fromBottom and 200 or 220)
	if fromBottom then
		p.AnchorPoint = Vector2.new(0, 1)
		p.Size = UDim2.new(1, 0, 0, size)
		p.Position = UDim2.new(0, 0, 1, size)
	else
		p.AnchorPoint = Vector2.new(1, 0)
		p.Size = UDim2.new(0, size, 1, 0)
		p.Position = UDim2.new(1, size, 0, 0)
	end
	local inner = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 92, Parent = p })
	new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = inner })
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })
	if opts.Title then
		lib:_Text(inner, opts.Title, 14, FONT.Bold, "Text", { Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1, ZIndex = 93 })
	end
	if opts.Content then
		lib:_Text(inner, opts.Content, 12, FONT.Regular, "Muted", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = 2, ZIndex = 93,
		})
	end
	obj.Body = inner
	obj.Frame = p
	tween(p, 0.35, { Position = fromBottom and UDim2.new(0, 0, 1, 0) or UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quint)
	function obj:Close()
		tween(p, 0.25, { Position = fromBottom and UDim2.new(0, 0, 1, size) or UDim2.new(1, size, 0, 0) })
		close()
	end
	return obj
end

function WindowClass:SidePanel(opts)
	return slidePanel(self, opts, false)
end

function WindowClass:BottomSheet(opts)
	return slidePanel(self, opts, true)
end

--------------------------------------------------------------------
-- Window extras: header buttons, footer, maximize, resize
--------------------------------------------------------------------
function WindowClass:AddHeaderButton(icon, cb, order)
	local b = self._ctrl(icon, order or 0, "Hover")
	connect(b.Activated, function()
		fire(cb, self)
	end)
	return b
end

function WindowClass:EnableHeaderButtons(set)
	set = set or {}
	local lib = self.Library
	local win = self
	if set.Search then
		self:AddHeaderButton("search", function()
			lib:OpenCommandPalette()
		end, -5)
	end
	if set.Refresh then
		self:AddHeaderButton("refresh-cw", set.OnRefresh or function()
			lib:Notify({ Title = "Refreshed", Type = "Success", Duration = 2 })
		end, -4)
	end
	if set.Settings then
		self:AddHeaderButton("settings", set.OnSettings or function()
			local c = lib:_FindWindow("Configure")
			if c then
				c:Show()
			end
		end, -3)
	end
	if set.Profile then
		self:AddHeaderButton("user", set.OnProfile or function()
			lib:Popover(win.UserCard, { Title = game:GetService("Players").LocalPlayer.DisplayName, Content = "@" .. game:GetService("Players").LocalPlayer.Name })
		end, -2)
	end
	if set.Maximize then
		self:AddHeaderButton("maximize", function()
			win:ToggleMaximize()
		end, -1)
	end
	if set.Back then
		self:AddHeaderButton("arrow-left", set.OnBack, -6)
	end
end

function WindowClass:ToggleMaximize()
	local root = self.Root
	local vp = getViewport()
	if not self._maximized then
		self._restore = { root.Size, root.Position }
		self._maximized = true
		tween(root, 0.3, { Size = UDim2.fromOffset(vp.X - 24, vp.Y - 24), Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2) })
	else
		self._maximized = false
		tween(root, 0.3, { Size = self._restore[1], Position = self._restore[2] })
	end
	task.delay(dur(0.32), function()
		self.Width = root.AbsoluteSize.X
		self.Height = root.AbsoluteSize.Y
	end)
end

function WindowClass:SetFooter(text)
	local lib = self.Library
	if not self.Footer then
		local f = new("Frame", {
			Name = "Footer", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 176, 1, 0), Size = UDim2.new(1, -176, 0, 22), ZIndex = 8, Parent = self.Root,
		})
		lib:Bind(f, "BackgroundColor3", "Secondary")
		f.BackgroundTransparency = 0.3
		local l = lib:_Text(f, false, 10, FONT.Medium, "Muted", { Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), ZIndex = 9 })
		self.Footer = f
		self._footerLabel = l
		self._footerEntry = lib:BindText(l, text or "")
		self.Content.Size = UDim2.new(1, -176, 1, -22)
	else
		lib:SetBoundText(self._footerEntry, text or "")
	end
end

function WindowClass:SetResizable(minW, minH)
	local lib = self.Library
	local win = self
	minW, minH = minW or 460, minH or 300
	local grip = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(18, 18), ZIndex = 30, Parent = self.Root,
	})
	local gi = lib:Icon(grip, "grip", 12, "Muted")
	gi.Position = UDim2.fromOffset(4, 4)
	local dragging, startP, startS
	connect(grip.InputBegan, function(input)
		if isPress(input) then
			dragging, startP, startS = true, input.Position, win.Root.AbsoluteSize
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					win.Width, win.Height = win.Root.AbsoluteSize.X, win.Root.AbsoluteSize.Y
					if c then
						c:Disconnect()
					end
				end
			end)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			local d = input.Position - startP
			win.Root.Size = UDim2.fromOffset(math.max(minW, startS.X + d.X), math.max(minH, startS.Y + d.Y))
		end
	end)
end

--------------------------------------------------------------------
-- Dock / Floating button / Mini window
--------------------------------------------------------------------
function Library:Dock(items, opts)
	opts = opts or {}
	local lib = self
	local dock = self:_Panel(self.Gui, 40, 1)
	dock.AnchorPoint = Vector2.new(0.5, 1)
	dock.Position = UDim2.new(0.5, 0, 1, -14)
	dock.Size = UDim2.fromOffset(0, 44)
	dock.AutomaticSize = Enum.AutomaticSize.X
	new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = dock })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = dock })
	for i, it in ipairs(items or {}) do
		local b = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(34, 34), LayoutOrder = i, ZIndex = 41, Parent = dock })
		self:Bind(b, "BackgroundColor3", "Hover")
		self:_Round(b, 0.7)
		local ic = self:Icon(b, it.Icon, 18, "Text")
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.fromScale(0.5, 0.5)
		ic.ZIndex = 42
		if it.Tooltip then
			self:_BindTooltip(b, it.Tooltip)
		end
		local sc = new("UIScale", { Parent = b })
		connect(b.MouseEnter, function()
			tween(b, 0.12, { BackgroundTransparency = 0.6 })
			tween(sc, 0.2, { Scale = 1.15 }, Enum.EasingStyle.Back)
		end)
		connect(b.MouseLeave, function()
			tween(b, 0.15, { BackgroundTransparency = 1 })
			tween(sc, 0.15, { Scale = 1 })
		end)
		connect(b.Activated, function()
			fire(it.Callback)
		end)
	end
	return { Frame = dock, SetVisible = function(_, v)
		dock.Visible = v
	end }
end

function Library:FloatingButton(opts)
	opts = opts or {}
	local fab = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromOffset(getViewport().X - 18, getViewport().Y - 18), Size = UDim2.fromOffset(opts.Size or 48, opts.Size or 48), ZIndex = 45, Parent = self.Gui,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fab })
	local g = new("UIGradient", { Rotation = 45, Parent = fab })
	self:Bind(g, "Color", function(t)
		return ColorSequence.new(t.GradientA, t.GradientB)
	end)
	local ic = self:Icon(fab, opts.Icon or "plus", 22, nil)
	ic.ImageColor3 = Color3.new(1, 1, 1)
	ic.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.Position = UDim2.fromScale(0.5, 0.5)
	ic.ZIndex = 46
	local sc = new("UIScale", { Parent = fab })
	connect(fab.MouseEnter, function()
		tween(sc, 0.15, { Scale = 1.1 }, Enum.EasingStyle.Back)
	end)
	connect(fab.MouseLeave, function()
		tween(sc, 0.15, { Scale = 1 })
	end)
	connect(fab.Activated, function()
		tween(ic, 0.25, { Rotation = ic.Rotation + 90 }, Enum.EasingStyle.Back)
		fire(opts.Callback)
	end)
	makeDraggable(fab, fab)
	return { Frame = fab, Destroy = function()
		fab:Destroy()
	end }
end

function Library:MiniWindow(opts)
	opts = opts or {}
	local lib = self
	local w = self:_Panel(self.Gui, 35, 1)
	w.Position = UDim2.fromOffset(40, 120)
	w.Size = UDim2.fromOffset(opts.Width or 220, 0)
	w.AutomaticSize = Enum.AutomaticSize.Y
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = w })
	local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1, ZIndex = 36, Parent = w })
	self:_Text(head, opts.Title or "Mini", 12, FONT.Bold, "Text", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -44, 1, 0), ZIndex = 37 })
	local x = new("TextButton", { Text = "×", Font = FONT.Bold, TextSize = 16, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 0), Size = UDim2.fromOffset(26, 30), ZIndex = 38, Parent = head })
	self:Bind(x, "TextColor3", "Muted")
	connect(x.Activated, function()
		w:Destroy()
	end)
	local body = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, ZIndex = 36, Parent = w })
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = body })
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
	makeDraggable(head, w)
	return { Frame = w, Body = body, Destroy = function()
		w:Destroy()
	end, AddLabel = function(_, text)
		return lib:_Text(body, text, 12, FONT.Medium, "Text", { Size = UDim2.new(1, 0, 0, 18), ZIndex = 37 })
	end }
end

--==================================================================
-- Layout components (sections)
--==================================================================
function SectionClass:AddAccordion(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 40)
	parts.Hit.Size = UDim2.new(1, 0, 0, 38)
	local obj = { Type = "Accordion", Open = false }
	local chev = lib:Icon(parts.Right, "chevron-down", 16, "Muted")
	local ex = lib:_Expander(parts, 0)
	local lines = opts.Items or (opts.Content and { opts.Content }) or {}
	local h = 6
	for _, line in ipairs(lines) do
		local l = lib:_Text(ex.Panel, line, 12, FONT.Regular, "Muted", { Position = UDim2.fromOffset(0, h - 6), Size = UDim2.new(1, 0, 0, 18), TextWrapped = true })
		h = h + 20
	end
	ex:Resize(h)
	ex.Height = h
	ex.OnToggle = function(o)
		obj.Open = o
		tween(chev, 0.2, { Rotation = o and 180 or 0 })
		fire(opts.Callback, o)
	end
	connect(parts.Hit.Activated, function()
		if not (obj.Locked or obj.Disabled) then
			ex:Toggle()
		end
	end)
	function obj:Toggle()
		ex:Toggle()
	end
	obj.Panel = ex.Panel
	lib:_Finish(obj, parts, opts)
	if opts.Default then
		ex:Open()
	end
	return obj
end
SectionClass.AddCollapsible = SectionClass.AddAccordion
SectionClass.AddExpandablePanel = SectionClass.AddAccordion

function SectionClass:AddChips(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 12)
	parts.Hit.Visible = false
	parts.Body.Visible = true
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parts.Body })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
	local obj = { Type = "Chips", Value = {} }
	local chips = {}
	for i, c in ipairs(opts.Items or {}) do
		local b = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = i, Parent = holder })
		new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = b })
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = b })
		local l = lib:_Text(b, c, 11, FONT.Bold, "Text", { Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Center })
		chips[i] = { b = b, name = c }
		local function paint()
			local on = obj.Value[c]
			tween(b, 0.15, { BackgroundColor3 = on and lib.Theme.Accent or lib.Theme.Secondary })
		end
		b.BackgroundColor3 = lib.Theme.Secondary
		connect(b.Activated, function()
			if opts.Selectable == false or obj.Locked then
				return
			end
			if opts.Single then
				obj.Value = {}
			end
			obj.Value[c] = not obj.Value[c] or nil
			for _, ch in ipairs(chips) do
				tween(ch.b, 0.15, { BackgroundColor3 = obj.Value[ch.name] and lib.Theme.Accent or lib.Theme.Secondary })
			end
			fire(opts.Callback, obj.Value)
		end)
	end
	function obj:Get()
		return obj.Value
	end
	lib:_Finish(obj, parts, opts)
	return obj
end
SectionClass.AddTags = SectionClass.AddChips
SectionClass.AddBadges = SectionClass.AddChips

function SectionClass:AddCard(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local kind = opts.Kind or "Info"
	local parts = lib:_BuildRow(self, merge({}, { Name = false }), 12)
	parts.Title.Visible = false
	parts.Hit.Visible = false
	parts.Body.Visible = true
	parts.Body.UIPadding.PaddingTop = UDim.new(0, 0)
	local obj = { Type = "Card" }
	local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parts.Body })
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
	if kind == "Profile" then
		local top = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), Parent = box })
		local av = new("ImageLabel", { Size = UDim2.fromOffset(40, 40), Image = opts.Image or "", Parent = top })
		lib:Bind(av, "BackgroundColor3", "Active")
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = av })
		lib:_Text(top, opts.Title or "", 13, FONT.Bold, "Text", { Position = UDim2.fromOffset(50, 4), Size = UDim2.new(1, -50, 0, 18) })
		lib:_Text(top, opts.Subtitle or "", 11, FONT.Regular, "Muted", { Position = UDim2.fromOffset(50, 22), Size = UDim2.new(1, -50, 0, 16) })
	elseif kind == "Stat" then
		local v = lib:_Text(box, false, 24, FONT.Bold, "Accent", { Size = UDim2.new(1, 0, 0, 30), Text = tostring(opts.Value or "0") })
		lib:_Text(box, opts.Title or "", 11, FONT.Medium, "Muted", { Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 2 })
		if opts.Delta then
			local up = tostring(opts.Delta):sub(1, 1) ~= "-"
			lib:_Text(box, false, 11, FONT.Bold, up and "Success" or "Error", { Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 3, Text = (up and "▲ " or "▼ ") .. tostring(opts.Delta) })
		end
		function obj:SetValue(x)
			v.Text = tostring(x)
		end
	else
		if opts.Icon then
			local ic = lib:Icon(box, opts.Icon, 22, "Accent")
		end
		lib:_Text(box, opts.Title or "", 13, FONT.Bold, "Text", { Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 2 })
		if opts.Content then
			lib:_Text(box, opts.Content, 12, FONT.Regular, "Muted", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = 3 })
		end
	end
	lib:_Finish(obj, parts, opts)
	return obj
end
SectionClass.AddInfoCard = function(self, o)
	return self:AddCard(merge(merge({}, parseOpts(o)), { Kind = "Info" }))
end
SectionClass.AddFeatureCard = SectionClass.AddInfoCard
SectionClass.AddStatCard = function(self, o)
	return self:AddCard(merge(merge({}, parseOpts(o)), { Kind = "Stat" }))
end
SectionClass.AddProfileCard = function(self, o)
	return self:AddCard(merge(merge({}, parseOpts(o)), { Kind = "Profile" }))
end

function SectionClass:AddBreadcrumb(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, merge({}, {}), 12)
	parts.Title.Visible = false
	parts.Hit.Visible = false
	parts.Body.Visible = true
	parts.Body.UIPadding.PaddingTop = UDim.new(0, 0)
	local h = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = parts.Body })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = h })
	local obj = { Type = "Breadcrumb" }
	local items = opts.Items or {}
	for i, it in ipairs(items) do
		local last = i == #items
		local b = lib:_Text(h, it, 12, last and FONT.Bold or FONT.Medium, last and "Accent" or "Muted", { Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = i * 2 })
		if not last then
			lib:_Text(h, false, 12, FONT.Regular, "Muted", { Text = "/", Size = UDim2.fromOffset(8, 20), LayoutOrder = i * 2 + 1 })
		end
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddPagination(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 12)
	parts.Hit.Visible = false
	local obj = { Type = "Pagination", Page = opts.Default or 1, Pages = opts.Pages or 5 }
	local label = lib:_Text(parts.Right, false, 12, FONT.Bold, "Accent", { Size = UDim2.fromOffset(52, 22), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2 })
	local function mk(txt, order, d)
		local b = new("TextButton", { Text = txt, Font = FONT.Bold, TextSize = 13, AutoButtonColor = false, Size = UDim2.fromOffset(22, 22), LayoutOrder = order, ZIndex = 4, Parent = parts.Right })
		lib:Bind(b, "BackgroundColor3", "Secondary")
		lib:Bind(b, "TextColor3", "Text")
		lib:_Round(b, 0.4)
		connect(b.Activated, function()
			obj:Set(obj.Page + d)
		end)
	end
	mk("<", 1, -1)
	mk(">", 3, 1)
	local function render()
		label.Text = obj.Page .. " / " .. obj.Pages
	end
	render()
	function obj:Set(p, silent)
		p = math.clamp(p, 1, obj.Pages)
		if p == obj.Page then
			return
		end
		obj.Page = p
		render()
		if not silent then
			fire(opts.Callback, p)
		end
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddIconButton(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 40)
	local obj = { Type = "IconButton" }
	local b = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(26, 26), ZIndex = 4, Parent = parts.Right })
	lib:Bind(b, "BackgroundColor3", "Accent")
	lib:_Round(b, 0.6)
	local ic = lib:Icon(b, opts.ButtonIcon or opts.Icon or "mouse-pointer-click", 14, nil)
	ic.ImageColor3 = Color3.new(1, 1, 1)
	ic.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.Position = UDim2.fromScale(0.5, 0.5)
	local function go()
		if obj.Locked or obj.Disabled then
			return
		end
		ripple(b)
		fire(opts.Callback)
	end
	connect(b.Activated, go)
	connect(parts.Hit.Activated, go)
	lib:_Finish(obj, parts, opts)
	return obj
end

-- Tab group inside a page (segmented control)
function SectionClass:AddSegmented(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 12)
	parts.Hit.Visible = false
	parts.Body.Visible = true
	local obj = { Type = "Segmented", Value = opts.Default or (opts.Options or {})[1] }
	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 28), Parent = parts.Body })
	lib:Bind(bar, "BackgroundColor3", "Secondary")
	lib:_Round(bar, 0.6)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = bar })
	local n = #(opts.Options or {})
	local btns = {}
	for i, o in ipairs(opts.Options or {}) do
		local b = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.new(1 / n, 0, 1, 0), LayoutOrder = i, BackgroundTransparency = 1, Parent = bar })
		lib:Bind(b, "BackgroundColor3", "Accent")
		lib:_Round(b, 0.6)
		local l = lib:_Text(b, o, 11, FONT.Bold, "Muted", { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
		btns[o] = { b = b, l = l }
		connect(b.Activated, function()
			if not obj.Locked then
				obj:Set(o)
			end
		end)
	end
	local function render()
		for o, x in pairs(btns) do
			local on = o == obj.Value
			tween(x.b, 0.18, { BackgroundTransparency = on and 0 or 1 })
			tween(x.l, 0.18, { TextColor3 = on and Color3.new(1, 1, 1) or lib.Theme.Muted })
		end
	end
	render()
	function obj:Set(v, silent)
		obj.Value = v
		render()
		if opts.Flag then
			Library.Flags[opts.Flag] = v
		end
		if not silent then
			fire(opts.Callback, v)
		end
	end
	function obj:Get()
		return obj.Value
	end
	lib:_Finish(obj, parts, opts, function()
		return obj.Value
	end, function(v)
		obj:Set(v, not Library._fireOnLoad)
	end)
	return obj
end
SectionClass.AddTabGroup = SectionClass.AddSegmented

--==================================================================
-- PART 4: Animation helpers, data display, charts
--==================================================================
Library.Anim = {}

function Library:_TweenNumber(from, to, t, cb, style)
	local nv = new("NumberValue", { Value = from })
	local c = nv.Changed:Connect(cb)
	local tw = TweenService:Create(nv, TweenInfo.new(dur(t), style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Value = to })
	tw:Play()
	tw.Completed:Connect(function()
		c:Disconnect()
		cb(to)
		nv:Destroy()
	end)
	return tw
end

function Library:_Loop(inst, fn)
	task.spawn(function()
		while inst.Parent and Library._inited do
			local ok = pcall(fn)
			if not ok then
				break
			end
		end
	end)
end

local A = Library.Anim

function A.Fade(inst, to, t)
	if inst:IsA("CanvasGroup") then
		return tween(inst, t or 0.25, { GroupTransparency = to })
	end
	return tween(inst, t or 0.25, { BackgroundTransparency = to })
end

function A.Slide(inst, fromOffset, t)
	local target = inst.Position
	inst.Position = target + fromOffset
	return tween(inst, t or 0.3, { Position = target })
end

function A.Scale(inst, from, t)
	local sc = inst:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = inst })
	sc.Scale = from or 0.85
	return tween(sc, t or 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

function A.Bounce(inst, t)
	local sc = inst:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = inst })
	sc.Scale = 0.7
	return tween(sc, t or 0.5, { Scale = 1 }, Enum.EasingStyle.Bounce)
end

function A.Spring(inst, t)
	local sc = inst:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = inst })
	sc.Scale = 0.6
	return tween(sc, t or 0.6, { Scale = 1 }, Enum.EasingStyle.Elastic)
end

function A.Shake(inst)
	local o = inst.Position
	task.spawn(function()
		for i = 1, 6 do
			inst.Position = o + UDim2.fromOffset(((i % 2 == 0) and 1 or -1) * (7 - i), 0)
			task.wait(0.03)
		end
		inst.Position = o
	end)
end

function A.Rotate(inst, speed)
	Library:_Loop(inst, function()
		inst.Rotation = (inst.Rotation + (speed or 4)) % 360
		task.wait()
	end)
end

function A.Pulse(inst, lo, hi)
	local sc = inst:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = inst })
	Library:_Loop(inst, function()
		tween(sc, 0.8, { Scale = hi or 1.08 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(dur(0.8))
		tween(sc, 0.8, { Scale = lo or 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(dur(0.8))
	end)
end

function A.Glow(stroke, lo, hi)
	Library:_Loop(stroke, function()
		tween(stroke, 1, { Transparency = lo or 0.1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(dur(1))
		tween(stroke, 1, { Transparency = hi or 0.7 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(dur(1))
	end)
end

function A.Shimmer(frame)
	local g = new("UIGradient", {
		Rotation = 20, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.55),
		}), Parent = frame,
	})
	Library:_Loop(frame, function()
		g.Offset = Vector2.new(-1, 0)
		tween(g, 1.2, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Linear)
		task.wait(dur(1.3))
	end)
	return g
end

function A.GradientFlow(frame, speed)
	local g = frame:FindFirstChildOfClass("UIGradient") or new("UIGradient", { Parent = frame })
	Library:_Loop(frame, function()
		g.Rotation = (g.Rotation + (speed or 1)) % 360
		task.wait()
	end)
end

function A.Typewriter(label, text, delay)
	task.spawn(function()
		label.Text = ""
		for i = 1, #text do
			if not label.Parent then
				return
			end
			label.Text = text:sub(1, i)
			task.wait(delay or 0.03)
		end
	end)
end

function A.Ripple(container)
	ripple(container)
end

--------------------------------------------------------------------
-- Ring / pie primitive (radial segments)
--------------------------------------------------------------------
function Library:_Ring(parent, size, thick, o)
	o = o or {}
	local N = o.Segments or 60
	local start, arc = o.Start or 0, o.Arc or 360
	local r = size / 2
	local pie = thick >= r - 0.5
	local holder = new(pie and "CanvasGroup" or "Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Parent = parent })
	if pie then
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = holder })
	end
	local rm = r - thick / 2
	local w = (2 * math.pi * (pie and r or rm) * (arc / 360) / N) * 1.18 + 1
	local segs = {}
	for i = 1, N do
		local a = start + (i - 0.5) / N * arc
		local rad = math.rad(a)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Size = UDim2.fromOffset(w, thick), Rotation = a,
			Position = UDim2.fromOffset(r + rm * math.sin(rad), r - rm * math.cos(rad)), BackgroundColor3 = self.Theme.Border, Parent = holder,
		})
		segs[i] = f
	end
	local ring = { Frame = holder, Segments = segs, N = N, Fraction = 0 }
	local lib = self
	function ring:SetFraction(p, onColor, offColor)
		ring.Fraction = p
		onColor = onColor or lib.Theme.Accent
		offColor = offColor or lib.Theme.Border
		for i, f in ipairs(segs) do
			f.BackgroundColor3 = ((i - 0.5) / N <= p) and onColor or offColor
		end
	end
	function ring:Animate(p, t)
		lib:_TweenNumber(ring.Fraction, p, t or 0.6, function(v)
			ring:SetFraction(v)
		end)
	end
	function ring:SetSlices(values, colors)
		local total = 0
		for _, v in ipairs(values) do
			total = total + v
		end
		local acc, idx = 0, 1
		for i, f in ipairs(segs) do
			local pos = (i - 0.5) / N * total
			while idx < #values and pos > acc + values[idx] do
				acc = acc + values[idx]
				idx = idx + 1
			end
			f.BackgroundColor3 = colors[(idx - 1) % #colors + 1]
		end
	end
	ring:SetFraction(0)
	return ring
end

local function stackRow(sec, opts, reserve)
	local lib = sec.Library
	local parts = lib:_BuildRow(sec, opts, reserve or 12)
	parts.Hit.Visible = false
	parts.Body.Visible = true
	if not opts.Name then
		parts.Title.Visible = false
		parts.Body.UIPadding.PaddingTop = UDim.new(0, 0)
	end
	return lib, parts
end
Library._stack = stackRow

local CHART_COLORS = function(t)
	return { t.Accent, t.Info, t.Success, t.Warning, t.Error, t.GradientA }
end

--------------------------------------------------------------------
-- Progress bars
--------------------------------------------------------------------
function SectionClass:AddProgressBar(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 56)
	local obj = { Type = "ProgressBar", Value = opts.Default or 0, Max = opts.Max or 100 }
	local lbl = lib:_Text(parts.Right, false, 12, FONT.Bold, "Accent", { Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Right })
	local track = new("Frame", { Size = UDim2.new(1, 0, 0, 8), Parent = parts.Body })
	lib:Bind(track, "BackgroundColor3", "Border")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track })
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	local g = new("UIGradient", { Parent = fill })
	lib:Bind(g, "Color", function(t)
		return ColorSequence.new(t.GradientB, t.GradientA)
	end)
	local function render(animate)
		local f = math.clamp(obj.Value / obj.Max, 0, 1)
		lbl.Text = math.floor(f * 100 + 0.5) .. "%"
		if animate then
			tween(fill, 0.4, { Size = UDim2.new(f, 0, 1, 0) })
		else
			fill.Size = UDim2.new(f, 0, 1, 0)
		end
	end
	render(false)
	function obj:Set(v)
		obj.Value = v
		render(true)
	end
	function obj:Get()
		return obj.Value
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddLoadingBar(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "LoadingBar" }
	local track = new("Frame", { Size = UDim2.new(1, 0, 0, 6), ClipsDescendants = true, Parent = parts.Body })
	lib:Bind(track, "BackgroundColor3", "Border")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local fill = new("Frame", { Size = UDim2.new(0.35, 0, 1, 0), Position = UDim2.fromScale(-0.4, 0), Parent = track })
	lib:Bind(fill, "BackgroundColor3", "Accent")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	lib:_Loop(track, function()
		fill.Position = UDim2.fromScale(-0.4, 0)
		tween(fill, 1.1, { Position = UDim2.fromScale(1.05, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(dur(1.2))
	end)
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddCircularProgress(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "CircularProgress", Value = opts.Default or 0, Max = opts.Max or 100 }
	local size = opts.Size or 90
	local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size + 4), Parent = parts.Body })
	local gauge = opts.Gauge == true
	local ring = lib:_Ring(box, size, opts.Thickness or 9, gauge and { Start = -135, Arc = 270 } or nil)
	ring.Frame.AnchorPoint = Vector2.new(0.5, 0)
	ring.Frame.Position = UDim2.new(0.5, 0, 0, 2)
	local lbl = lib:_Text(ring.Frame, false, 15, FONT.Bold, "Text", { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
	local function render(animate)
		local f = math.clamp(obj.Value / obj.Max, 0, 1)
		lbl.Text = math.floor(f * 100 + 0.5) .. "%"
		if animate then
			ring:Animate(f, 0.6)
		else
			ring:SetFraction(f)
		end
	end
	render(false)
	function obj:Set(v)
		obj.Value = v
		render(true)
	end
	function obj:Get()
		return obj.Value
	end
	lib:_Finish(obj, parts, opts)
	return obj
end
SectionClass.AddCircularGauge = function(self, o)
	return self:AddCircularProgress(merge(merge({}, parseOpts(o)), { Gauge = true }))
end

function SectionClass:AddSpinner(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Spinner" }
	local size = opts.Size or 28
	local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size + 4), Parent = parts.Body })
	local ring = lib:_Ring(box, size, 4, { Segments = 24 })
	ring.Frame.AnchorPoint = Vector2.new(0.5, 0)
	ring.Frame.Position = UDim2.new(0.5, 0, 0, 2)
	for i, f in ipairs(ring.Segments) do
		f.BackgroundColor3 = lib.Theme.Accent
		f.BackgroundTransparency = 1 - (i / 24)
	end
	A.Rotate(ring.Frame, 7)
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddSkeleton(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Skeleton" }
	for i = 1, opts.Lines or 3 do
		local b = new("Frame", { Size = UDim2.new(i == (opts.Lines or 3) and 0.6 or 1, 0, 0, 12), ClipsDescendants = true, LayoutOrder = i, Parent = parts.Body })
		lib:Bind(b, "BackgroundColor3", "Border")
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = b })
		A.Shimmer(b)
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddTyping(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Typing" }
	local l = lib:_Text(parts.Body, false, 12, FONT.Medium, "Accent", { Size = UDim2.new(1, 0, 0, 18) })
	local texts = opts.Texts or { opts.Text or "Typing..." }
	task.spawn(function()
		local i = 1
		while l.Parent do
			local txt = lib:Translate(texts[i])
			for n = 1, #txt do
				if not l.Parent then
					return
				end
				l.Text = txt:sub(1, utf8.offset(txt, n + 1) and (utf8.offset(txt, n + 1) - 1) or #txt) .. "▍"
				task.wait(0.05)
			end
			task.wait(1.2)
			i = i % #texts + 1
		end
	end)
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddStatus(opts)
	opts = parseOpts(opts)
	local lib = self.Library
	local parts = lib:_BuildRow(self, opts, 90)
	parts.Hit.Visible = false
	local obj = { Type = "Status", State = opts.State or "Online" }
	local dot = new("Frame", { Size = UDim2.fromOffset(10, 10), LayoutOrder = 2, Parent = parts.Right })
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
	local lbl = lib:_Text(parts.Right, false, 12, FONT.Bold, "Text", { Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 1 })
	local colors = { Online = "Success", Offline = "Error", Idle = "Warning", Busy = "Warning", Info = "Info" }
	local sc = new("UIScale", { Parent = dot })
	local function render()
		dot.BackgroundColor3 = lib.Theme[colors[obj.State] or "Info"]
		lbl.Text = lib:Translate(obj.State)
	end
	render()
	A.Pulse(dot, 0.8, 1.25)
	function obj:Set(s)
		obj.State = s
		render()
	end
	lib:_Finish(obj, parts, opts)
	return obj
end
SectionClass.AddStatusIndicator = SectionClass.AddStatus

function SectionClass:AddAvatar(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Avatar" }
	local size = opts.Size or 56
	local img = new("ImageLabel", { Size = UDim2.fromOffset(size, size), Parent = parts.Body })
	lib:Bind(img, "BackgroundColor3", "Active")
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = img })
	local st = new("UIStroke", { Thickness = 2, Parent = img })
	lib:Bind(st, "Color", "Accent")
	task.spawn(function()
		local uid = opts.UserId or game:GetService("Players").LocalPlayer.UserId
		local ok, url = pcall(function()
			return game:GetService("Players"):GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and img.Parent then
			img.Image = url
		end
	end)
	lib:_Finish(obj, parts, opts)
	return obj
end

--------------------------------------------------------------------
-- Charts
--------------------------------------------------------------------
function SectionClass:AddDonutChart(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "DonutChart" }
	local size = opts.Size or 100
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size), Parent = parts.Body })
	local ring = lib:_Ring(row, size, opts.Pie and size / 2 or 16, { Segments = 72 })
	local legend = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(size + 14, 0), Size = UDim2.new(1, -(size + 14), 1, 0), Parent = row })
	new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), Parent = legend })
	local function render(data)
		for _, c in ipairs(legend:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local vals, cols = {}, CHART_COLORS(lib.Theme)
		for i, d in ipairs(data) do
			vals[i] = d.Value
			local l = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = i, Parent = legend })
			local dot = new("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(0, 3), BackgroundColor3 = cols[(i - 1) % #cols + 1], Parent = l })
			new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
			lib:_Text(l, d.Name .. "  " .. tostring(d.Value), 11, FONT.Medium, "Text", { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -14, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
		end
		if #vals > 0 then
			ring:SetSlices(vals, cols)
		end
	end
	render(opts.Data or {})
	function obj:SetData(d)
		render(d)
	end
	lib:_Finish(obj, parts, opts)
	return obj
end
SectionClass.AddPieChart = function(self, o)
	return self:AddDonutChart(merge(merge({}, parseOpts(o)), { Pie = true }))
end

function SectionClass:AddBarChart(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "BarChart" }
	local H = opts.Height or 110
	local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, H + 18), Parent = parts.Body })
	local area = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, H), Parent = box })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = area })
	local labels = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, H + 2), Size = UDim2.new(1, 0, 0, 14), Parent = box })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = labels })
	local function render(data)
		for _, c in ipairs(area:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for _, c in ipairs(labels:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local mx, n = 1, #data
		for _, d in ipairs(data) do
			mx = math.max(mx, d.Value)
		end
		for i, d in ipairs(data) do
			local w = UDim2.new(1 / math.max(n, 1), -6 * (n - 1) / math.max(n, 1), 0, 0)
			local bar = new("Frame", { Size = UDim2.new(w.X.Scale, w.X.Offset, 0, 0), LayoutOrder = i, BackgroundColor3 = Color3.new(1, 1, 1), Parent = area })
			new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = bar })
			local g = new("UIGradient", { Rotation = 90, Parent = bar })
			lib:Bind(g, "Color", function(t)
				return ColorSequence.new(t.GradientA, t.GradientB)
			end)
			tween(bar, 0.5, { Size = UDim2.new(w.X.Scale, w.X.Offset, 0, math.max(2, d.Value / mx * (H - 4))) }, Enum.EasingStyle.Back)
			lib:_Text(labels, d.Name, 10, FONT.Medium, "Muted", { Size = UDim2.new(w.X.Scale, w.X.Offset, 1, 0), LayoutOrder = i, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
		end
	end
	render(opts.Data or {})
	function obj:SetData(d)
		render(d)
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddLineChart(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "LineChart" }
	local H = opts.Height or 100
	local area = new("Frame", { Size = UDim2.new(1, 0, 0, H), ClipsDescendants = false, Parent = parts.Body })
	lib:Bind(area, "BackgroundColor3", "Secondary")
	lib:_Round(area, 0.5)
	local plot = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20), Parent = area })
	local function render(values)
		for _, c in ipairs(plot:GetChildren()) do
			c:Destroy()
		end
		local n = #values
		if n < 2 then
			return
		end
		local mn, mx = math.huge, -math.huge
		for _, v in ipairs(values) do
			mn, mx = math.min(mn, v), math.max(mx, v)
		end
		if mx == mn then
			mx = mn + 1
		end
		local W, Hh = math.max(plot.AbsoluteSize.X, 100), math.max(plot.AbsoluteSize.Y, 60)
		local pts = {}
		for i, v in ipairs(values) do
			pts[i] = Vector2.new((i - 1) / (n - 1) * W, Hh - (v - mn) / (mx - mn) * Hh)
		end
		for i = 1, n - 1 do
			local a, b = pts[i], pts[i + 1]
			local d = b - a
			local seg = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(d.Magnitude + 1, 2), Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
				Rotation = math.deg(math.atan2(d.Y, d.X)), BorderSizePixel = 0, BackgroundTransparency = 1, Parent = plot,
			})
			seg.BackgroundColor3 = lib.Theme.Accent
			task.delay(i * 0.03, function()
				if seg.Parent then
					tween(seg, 0.3, { BackgroundTransparency = 0 })
				end
			end)
		end
		for _, p in ipairs(pts) do
			local dot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(p.X, p.Y), Parent = plot })
			dot.BackgroundColor3 = Color3.new(1, 1, 1)
			new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		end
	end
	local data = opts.Data or {}
	task.defer(function()
		render(data)
	end)
	connect(plot:GetPropertyChangedSignal("AbsoluteSize"), function()
		render(data)
	end)
	function obj:SetData(d)
		data = d
		render(d)
	end
	lib:_Finish(obj, parts, opts)
	return obj
end
SectionClass.AddGraph = SectionClass.AddLineChart

--------------------------------------------------------------------
-- Lists, grids, tables, trees
--------------------------------------------------------------------
function SectionClass:AddList(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "List", Items = {} }
	local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parts.Body })
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
	local function render()
		for _, c in ipairs(box:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for i, it in ipairs(obj.Items) do
			local b = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, Parent = box })
			lib:Bind(b, "BackgroundColor3", "Secondary")
			lib:_Round(b, 0.45)
			local x = 10
			if it.Icon then
				local ic = lib:Icon(b, it.Icon, 14, "Accent")
				ic.Position = UDim2.fromOffset(8, 7)
				x = 30
			end
			lib:_Text(b, it.Name or tostring(it), 12, FONT.Medium, "Text", { Position = UDim2.fromOffset(x, 0), Size = UDim2.new(0.6, -x, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
			if it.Value then
				lib:_Text(b, tostring(it.Value), 11, FONT.Bold, "Accent", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0.4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right })
			end
			connect(b.MouseEnter, function()
				tween(b, 0.1, { BackgroundColor3 = lib.Theme.Hover })
			end)
			connect(b.MouseLeave, function()
				tween(b, 0.12, { BackgroundColor3 = lib.Theme.Secondary })
			end)
			connect(b.Activated, function()
				fire(opts.Callback, it, i)
			end)
		end
	end
	for i, it in ipairs(opts.Items or {}) do
		obj.Items[i] = type(it) == "table" and it or { Name = tostring(it) }
	end
	render()
	function obj:SetItems(items)
		obj.Items = {}
		for i, it in ipairs(items) do
			obj.Items[i] = type(it) == "table" and it or { Name = tostring(it) }
		end
		render()
	end
	function obj:Add(it)
		obj.Items[#obj.Items + 1] = type(it) == "table" and it or { Name = tostring(it) }
		render()
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddGrid(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Grid" }
	local cols = opts.Columns or 3
	local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parts.Body })
	new("UIGridLayout", { CellSize = UDim2.new(1 / cols, -6, 0, opts.CellHeight or 54), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
	for i, it in ipairs(opts.Items or {}) do
		local b = new("TextButton", { Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = box })
		lib:Bind(b, "BackgroundColor3", "Secondary")
		lib:_Round(b, 0.6)
		local y = 0
		if it.Icon then
			local ic = lib:Icon(b, it.Icon, 20, "Accent")
			ic.AnchorPoint = Vector2.new(0.5, 0)
			ic.Position = UDim2.new(0.5, 0, 0, 8)
			y = 14
		end
		lib:_Text(b, it.Name or tostring(it), 11, FONT.Medium, "Text", { Size = UDim2.new(1, -8, 1, y), Position = UDim2.fromOffset(4, y > 0 and 12 or 0), TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true })
		connect(b.MouseEnter, function()
			tween(b, 0.1, { BackgroundColor3 = lib.Theme.Hover })
		end)
		connect(b.MouseLeave, function()
			tween(b, 0.12, { BackgroundColor3 = lib.Theme.Secondary })
		end)
		connect(b.Activated, function()
			fire(opts.Callback, it, i)
		end)
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddTable(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Table", Rows = opts.Rows or {}, Columns = opts.Columns or {} }
	local ncol = math.max(#obj.Columns, 1)
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 24), Parent = parts.Body })
	lib:Bind(head, "BackgroundColor3", "Secondary")
	lib:_Round(head, 0.45)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, opts.Height or 120), ScrollBarThickness = 3, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = parts.Body,
	})
	lib:Bind(scroll, "ScrollBarImageColor3", "Accent")
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
	local sortCol, asc = nil, true
	local function cell(parent, text, c, bold, key)
		return lib:_Text(parent, text, 11, bold and FONT.Bold or FONT.Medium, key, {
			Position = UDim2.new((c - 1) / ncol, 8, 0, 0), Size = UDim2.new(1 / ncol, -10, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3,
		})
	end
	local function render()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local rows = table.clone(obj.Rows)
		if sortCol then
			table.sort(rows, function(a, b)
				local x, y = a[sortCol], b[sortCol]
				if tonumber(x) and tonumber(y) then
					x, y = tonumber(x), tonumber(y)
				else
					x, y = tostring(x), tostring(y)
				end
				if asc then
					return x < y
				end
				return x > y
			end)
		end
		for i, r in ipairs(rows) do
			local f = new("Frame", { Size = UDim2.new(1, -4, 0, 24), LayoutOrder = i, BackgroundTransparency = (i % 2 == 0) and 0.6 or 1, Parent = scroll })
			lib:Bind(f, "BackgroundColor3", "Secondary")
			lib:_Round(f, 0.4)
			for c = 1, ncol do
				cell(f, tostring(r[c] == nil and "" or r[c]), c, false, "Text")
			end
		end
	end
	for c, name in ipairs(obj.Columns) do
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.new((c - 1) / ncol, 0, 0, 0), Size = UDim2.new(1 / ncol, 0, 1, 0), Parent = head,
		})
		cell(head, name, c, true, "Accent")
		if opts.Sortable ~= false then
			connect(b.Activated, function()
				if sortCol == c then
					asc = not asc
				end
				sortCol = c
				render()
			end)
		end
	end
	render()
	function obj:SetRows(rows)
		obj.Rows = rows
		render()
	end
	function obj:AddRow(r)
		table.insert(obj.Rows, r)
		render()
	end
	lib:_Finish(obj, parts, opts)
	return obj
end
SectionClass.AddDataTable = SectionClass.AddTable

function SectionClass:AddTreeView(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "TreeView" }
	local root = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parts.Body })
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = root })
	local function build(parent, nodes, depth)
		for i, n in ipairs(nodes) do
			local hasKids = n.Children and #n.Children > 0
			local wrap = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, Parent = parent })
			new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = wrap })
			local b = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1, Parent = wrap })
			lib:Bind(b, "BackgroundColor3", "Hover")
			lib:_Round(b, 0.4)
			local x = 6 + depth * 16
			local arrow
			if hasKids then
				arrow = lib:Icon(b, "chevron-right", 12, "Muted")
				arrow.Position = UDim2.fromOffset(x, 6)
			end
			local ic = lib:Icon(b, n.Icon or (hasKids and "folder" or "file"), 14, "Accent")
			ic.Position = UDim2.fromOffset(x + 16, 5)
			lib:_Text(b, n.Name, 12, FONT.Medium, "Text", { Position = UDim2.fromOffset(x + 36, 0), Size = UDim2.new(1, -(x + 40), 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
			local kids
			if hasKids then
				kids = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = n.Open == true, LayoutOrder = 2, Parent = wrap })
				new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = kids })
				build(kids, n.Children, depth + 1)
				if n.Open then
					arrow.Rotation = 90
				end
			end
			connect(b.MouseEnter, function()
				tween(b, 0.1, { BackgroundTransparency = 0.6 })
			end)
			connect(b.MouseLeave, function()
				tween(b, 0.12, { BackgroundTransparency = 1 })
			end)
			connect(b.Activated, function()
				if kids then
					kids.Visible = not kids.Visible
					tween(arrow, 0.2, { Rotation = kids.Visible and 90 or 0 })
				end
				fire(opts.Callback, n)
			end)
		end
	end
	build(root, opts.Nodes or {}, 0)
	lib:_Finish(obj, parts, opts)
	return obj
end

--------------------------------------------------------------------
-- Timeline / feed / changelog / panels
--------------------------------------------------------------------
function SectionClass:AddTimeline(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Timeline" }
	local items = opts.Items or {}
	for i, it in ipairs(items) do
		local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, Parent = parts.Body })
		new("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingBottom = UDim.new(0, 8), Parent = row })
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
		local dot = new("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(-20, 3), Parent = row })
		lib:Bind(dot, "BackgroundColor3", "Accent")
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		if i < #items then
			local line = new("Frame", { Size = UDim2.new(0, 2, 1, 4), Position = UDim2.new(0, -16, 0, 13), BorderSizePixel = 0, Parent = row })
			lib:Bind(line, "BackgroundColor3", "Border")
		end
		lib:_Text(row, it.Title or "", 12, FONT.Bold, "Text", { Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1 })
		if it.Time then
			lib:_Text(row, it.Time, 10, FONT.Medium, "Accent", { Size = UDim2.new(1, 0, 0, 12), LayoutOrder = 2 })
		end
		if it.Description then
			lib:_Text(row, it.Description, 11, FONT.Regular, "Muted", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = 3 })
		end
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddActivityFeed(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "ActivityFeed", Count = 0 }
	local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parts.Body })
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
	function obj:Push(text, icon, typ)
		obj.Count = obj.Count + 1
		local f = new("CanvasGroup", { Size = UDim2.new(1, 0, 0, 26), LayoutOrder = -obj.Count, GroupTransparency = 1, Parent = box })
		lib:Bind(f, "BackgroundColor3", "Secondary")
		lib:_Round(f, 0.45)
		local ic = lib:Icon(f, icon or "activity", 14, nil)
		ic.ImageColor3 = lib.Theme[typ or "Accent"] or lib.Theme.Accent
		ic.Position = UDim2.fromOffset(8, 6)
		lib:_Text(f, text, 11, FONT.Medium, "Text", { Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -90, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
		lib:_Text(f, false, 10, FONT.Regular, "Muted", { Text = os.date("%H:%M:%S"), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(56, 26), TextXAlignment = Enum.TextXAlignment.Right })
		tween(f, 0.3, { GroupTransparency = 0 })
		local kids = box:GetChildren()
		if #kids > 31 then
			for _, k in ipairs(kids) do
				if k:IsA("CanvasGroup") and k.LayoutOrder == -(obj.Count - 30) then
					k:Destroy()
				end
			end
		end
	end
	for _, it in ipairs(opts.Items or {}) do
		obj:Push(it.Text or it, it.Icon, it.Type)
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddCodeBlock(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 40)
	local obj = { Type = "CodeBlock", Code = opts.Code or "" }
	local cp = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(24, 20), ZIndex = 4, Parent = parts.Right })
	local ci = lib:Icon(cp, "copy", 14, "Muted")
	ci.AnchorPoint = Vector2.new(0.5, 0.5)
	ci.Position = UDim2.fromScale(0.5, 0.5)
	cp.BackgroundTransparency = 1
	local box = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parts.Body })
	lib:Bind(box, "BackgroundColor3", "Secondary")
	lib:_Round(box, 0.5)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = box })
	local t = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Code, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Text = obj.Code, Parent = box,
	})
	lib:Bind(t, "TextColor3", "Accent")
	connect(cp.Activated, function()
		if type(setclipboard) == "function" then
			setclipboard(obj.Code)
			lib:Notify({ Title = "Copied", Type = "Success", Duration = 2 })
		end
	end)
	function obj:SetCode(c)
		obj.Code = c
		t.Text = c
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

local LOG_COLORS = { Info = "Text", Success = "Success", Warning = "Warning", Error = "Error", Muted = "Muted" }

function SectionClass:AddConsole(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Console", Lines = 0 }
	local h = opts.Height or 130
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, h + (opts.Terminal and 30 or 0)), Parent = parts.Body })
	lib:Bind(frame, "BackgroundColor3", "Secondary")
	lib:_Round(frame, 0.5)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, h - 12), ScrollBarThickness = 3,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = frame,
	})
	lib:Bind(scroll, "ScrollBarImageColor3", "Accent")
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
	function obj:Log(text, level)
		obj.Lines = obj.Lines + 1
		local l = lib:_Text(scroll, false, 11, nil, LOG_COLORS[level or "Info"] or "Text", {
			Font = Enum.Font.Code, Text = (opts.Timestamps and ("[" .. os.date("%H:%M:%S") .. "] ") or "") .. tostring(text), Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = obj.Lines,
		})
		if obj.Lines > (opts.MaxLines or 200) then
			local first = scroll:FindFirstChildOfClass("TextLabel")
			if first then
				first:Destroy()
			end
		end
		task.defer(function()
			scroll.CanvasPosition = Vector2.new(0, 1e6)
		end)
	end
	function obj:Clear()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextLabel") then
				c:Destroy()
			end
		end
	end
	if opts.Terminal then
		local f = new("Frame", { Position = UDim2.new(0, 6, 1, -28), Size = UDim2.new(1, -12, 0, 24), Parent = frame })
		lib:Bind(f, "BackgroundColor3", "Element")
		lib:_Round(f, 0.5)
		lib:_Text(f, false, 12, FONT.Bold, "Accent", { Text = ">", Size = UDim2.fromOffset(16, 24), Position = UDim2.fromOffset(6, 0) })
		local tb = new("TextBox", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -28, 1, 0), Text = "", ClearTextOnFocus = false,
			Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, PlaceholderText = "command...", Parent = f,
		})
		lib:Bind(tb, "TextColor3", "Text")
		lib:Bind(tb, "PlaceholderColor3", "Muted")
		connect(tb.FocusLost, function(enter)
			if enter and tb.Text ~= "" then
				local c = tb.Text
				tb.Text = ""
				obj:Log("> " .. c, "Muted")
				fire(opts.OnCommand, c, obj)
				tb:CaptureFocus()
			end
		end)
	end
	for _, l in ipairs(opts.Lines or {}) do
		obj:Log(type(l) == "table" and l[1] or l, type(l) == "table" and l[2] or nil)
	end
	lib:_Finish(obj, parts, opts)
	return obj
end
SectionClass.AddTerminal = function(self, o)
	return self:AddConsole(merge(merge({}, parseOpts(o)), { Terminal = true }))
end
SectionClass.AddLogViewer = function(self, o)
	return self:AddConsole(merge(merge({}, parseOpts(o)), { Timestamps = true }))
end

function SectionClass:AddChangelog(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Changelog" }
	local kinds = { Added = "Success", Fixed = "Info", Changed = "Warning", Removed = "Error" }
	for i, v in ipairs(opts.Versions or {}) do
		local box = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, Parent = parts.Body })
		lib:Bind(box, "BackgroundColor3", "Secondary")
		lib:_Round(box, 0.55)
		new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = box })
		new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
		lib:_Text(box, v.Version .. (v.Date and ("  ·  " .. v.Date) or ""), 12, FONT.Bold, "Accent", { Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 0 })
		for j, c in ipairs(v.Changes or {}) do
			local kind, text = "Added", c
			if type(c) == "table" then
				kind, text = c[1], c[2]
			end
			local l = lib:_Text(box, text, 11, FONT.Regular, "Text", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = j })
			l.Text = "• " .. lib:Translate(text)
		end
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function SectionClass:AddWelcomePanel(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, { }, 12)
	local obj = { Type = "WelcomePanel" }
	local box = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.new(1, 1, 1), Parent = parts.Body })
	lib:_Round(box, 0.6)
	local g = new("UIGradient", { Rotation = 30, Transparency = NumberSequence.new(0.3, 0.55), Parent = box })
	lib:Bind(g, "Color", function(t)
		return ColorSequence.new(t.GradientA, t.GradientB)
	end)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = box })
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
	local t = lib:_Text(box, opts.Title or "Welcome", 15, FONT.Bold, "Text", { Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1 })
	t.TextColor3 = Color3.new(1, 1, 1)
	local m = lib:_Text(box, opts.Message or "", 12, FONT.Regular, "Text", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = 2 })
	m.TextColor3 = Color3.new(1, 1, 1)
	if opts.ButtonText then
		local b = lib:_SmallButton(box, opts.ButtonText, opts.Callback)
		b.LayoutOrder = 3
	end
	lib:_Finish(obj, parts, {})
	return obj
end
SectionClass.AddUpdatePanel = SectionClass.AddWelcomePanel

function SectionClass:AddDashboard(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Dashboard", Tiles = {} }
	local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parts.Body })
	local cols = opts.Columns or 2
	new("UIGridLayout", { CellSize = UDim2.new(1 / cols, -6, 0, 64), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
	for i, s in ipairs(opts.Stats or {}) do
		local f = new("Frame", { LayoutOrder = i, Parent = box })
		lib:Bind(f, "BackgroundColor3", "Secondary")
		lib:_Round(f, 0.6)
		local v = lib:_Text(f, false, 20, FONT.Bold, "Accent", { Text = tostring(s.Value or 0), Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 26) })
		lib:_Text(f, s.Title or "", 11, FONT.Medium, "Muted", { Position = UDim2.fromOffset(10, 32), Size = UDim2.new(1, -20, 0, 14) })
		if s.Delta then
			local up = tostring(s.Delta):sub(1, 1) ~= "-"
			lib:_Text(f, false, 10, FONT.Bold, up and "Success" or "Error", { Text = (up and "▲ " or "▼ ") .. tostring(s.Delta), Position = UDim2.fromOffset(10, 46), Size = UDim2.new(1, -20, 0, 12) })
		end
		obj.Tiles[s.Title or i] = v
	end
	function obj:SetStat(title, value)
		if obj.Tiles[title] then
			obj.Tiles[title].Text = tostring(value)
		end
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

function Library:ViewImage(image)
	local lib = self
	local overlay, close = self:_Backdrop(self.Gui, 400, 0.7)
	local img = new("ImageLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 300),
		Image = tostring(image):match("^%d+$") and ("rbxassetid://" .. image) or tostring(image), ScaleType = Enum.ScaleType.Fit, ZIndex = 401, ImageTransparency = 1, Parent = overlay,
	})
	tween(img, 0.25, { ImageTransparency = 0 })
	A.Scale(img, 0.8, 0.35)
end

function SectionClass:AddImage(opts)
	opts = parseOpts(opts)
	local lib, parts = stackRow(self, opts, 12)
	local obj = { Type = "Image" }
	local function mk(src, parent, w)
		local b = new("ImageButton", {
			Size = UDim2.fromOffset(w or 0, opts.Height or 110), BackgroundTransparency = 0, AutoButtonColor = false, ScaleType = Enum.ScaleType.Crop, Parent = parent,
			Image = tostring(src):match("^%d+$") and ("rbxassetid://" .. src) or tostring(src),
		})
		lib:Bind(b, "BackgroundColor3", "Secondary")
		lib:_Round(b, 0.6)
		connect(b.Activated, function()
			if opts.Viewer ~= false then
				lib:ViewImage(src)
			end
		end)
		return b
	end
	if opts.Images then
		local sc = new("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, (opts.Height or 110) + 8), ScrollBarThickness = 3, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, Parent = parts.Body,
		})
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = sc })
		for _, src in ipairs(opts.Images) do
			mk(src, sc, opts.Width or 150)
		end
	else
		local b = mk(opts.Image or "", parts.Body, 0)
		b.Size = UDim2.new(1, 0, 0, opts.Height or 110)
	end
	lib:_Finish(obj, parts, opts)
	return obj
end
SectionClass.AddGallery = SectionClass.AddImage
SectionClass.AddImageViewer = SectionClass.AddImage

--==================================================================
-- PART 5: File storage (JSON), configs, settings, fonts, registries
--==================================================================
local FS = { mem = {} }
Library.FS = FS
Library.Config = { Folder = "PickasHub", Current = nil, AutoSave = false, AutoLoad = nil }

function FS.available()
	return type(writefile) == "function" and type(readfile) == "function"
end

function FS.folder(path)
	if type(makefolder) == "function" and type(isfolder) == "function" then
		pcall(function()
			if not isfolder(path) then
				makefolder(path)
			end
		end)
	end
end

function FS.write(path, text)
	if FS.available() then
		local ok = pcall(writefile, path, text)
		if ok then
			return true
		end
	end
	FS.mem[path] = text
	return false
end

function FS.read(path)
	if FS.available() and type(isfile) == "function" then
		local ok, res = pcall(function()
			if isfile(path) then
				return readfile(path)
			end
			return nil
		end)
		if ok and res then
			return res
		end
	end
	return FS.mem[path]
end

function FS.delete(path)
	if type(delfile) == "function" then
		pcall(delfile, path)
	end
	FS.mem[path] = nil
end

function FS.list(folder)
	local out, seen = {}, {}
	if type(listfiles) == "function" then
		local ok, files = pcall(listfiles, folder)
		if ok and type(files) == "table" then
			for _, f in ipairs(files) do
				f = tostring(f):gsub("\\", "/")
				if not seen[f] then
					seen[f] = true
					out[#out + 1] = f
				end
			end
		end
	end
	for p in pairs(FS.mem) do
		if p:sub(1, #folder) == folder and not seen[p] then
			seen[p] = true
			out[#out + 1] = p
		end
	end
	return out
end

local function cfgFolder()
	return Library.Config.Folder .. "/configs"
end

local function cleanName(n)
	n = tostring(n or ""):gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	return n
end

local function encValue(v)
	local t = typeof(v)
	if t == "Color3" then
		return { __t = "c3", hex = toHex(v) }
	elseif t == "EnumItem" then
		return { __t = "enum", s = tostring(v) }
	elseif t == "table" then
		local o = {}
		for k, x in pairs(v) do
			o[k] = encValue(x)
		end
		return o
	end
	return v
end

local function decValue(v)
	if type(v) == "table" then
		if v.__t == "c3" then
			return fromHex(v.hex) or Color3.new(1, 1, 1)
		elseif v.__t == "enum" then
			local en, nm = tostring(v.s):match("^Enum%.(%w+)%.(%w+)$")
			if en and nm then
				local ok, r = pcall(function()
					return Enum[en][nm]
				end)
				if ok then
					return r
				end
			end
			return nil
		end
		local o = {}
		for k, x in pairs(v) do
			o[k] = decValue(x)
		end
		return o
	end
	return v
end
Library.Util.encode = encValue
Library.Util.decode = decValue

function Library:GetConfigData()
	local flags = {}
	for flag, entry in pairs(self._setters) do
		local ok, v = pcall(entry.get)
		if ok and v ~= nil then
			flags[flag] = encValue(v)
		end
	end
	return { Format = 1, Library = "PickasUI", Version = self.Version, Saved = os.time(), Flags = flags }
end

function Library:ApplyConfigData(data)
	if type(data) ~= "table" or type(data.Flags) ~= "table" then
		return false, "invalid config"
	end
	self._fireOnLoad = true
	local n = 0
	for flag, v in pairs(data.Flags) do
		local entry = self._setters[flag]
		if entry then
			if pcall(entry.set, decValue(v)) then
				n = n + 1
			end
		end
	end
	self._fireOnLoad = false
	return true, n
end

function Library:ListConfigs()
	FS.folder(self.Config.Folder)
	FS.folder(cfgFolder())
	local out = {}
	for _, p in ipairs(FS.list(cfgFolder())) do
		local n = p:match("([^/]+)%.json$")
		if n then
			out[#out + 1] = n
		end
	end
	table.sort(out)
	return out
end

function Library:SaveConfig(name)
	name = cleanName(name)
	if name == "" then
		return false, "Enter a config name."
	end
	FS.folder(self.Config.Folder)
	FS.folder(cfgFolder())
	local ok, json = pcall(function()
		return HttpService:JSONEncode(self:GetConfigData())
	end)
	if not ok then
		return false, "Could not encode config."
	end
	FS.write(cfgFolder() .. "/" .. name .. ".json", json)
	self.Config.Current = name
	self._lastSaved = json
	return true
end

function Library:LoadConfig(name)
	name = cleanName(name)
	local raw = FS.read(cfgFolder() .. "/" .. name .. ".json")
	if not raw then
		return false, "Config not found."
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok then
		return false, "Config file is corrupted."
	end
	local ok2, n = self:ApplyConfigData(data)
	if ok2 then
		self.Config.Current = name
		self._lastSaved = raw
	end
	return ok2, n
end

function Library:DeleteConfig(name)
	name = cleanName(name)
	FS.delete(cfgFolder() .. "/" .. name .. ".json")
	if self.Config.Current == name then
		self.Config.Current = nil
	end
	return true
end

function Library:RenameConfig(old, new_)
	old, new_ = cleanName(old), cleanName(new_)
	if new_ == "" then
		return false, "Enter a new name."
	end
	local raw = FS.read(cfgFolder() .. "/" .. old .. ".json")
	if not raw then
		return false, "Config not found."
	end
	FS.write(cfgFolder() .. "/" .. new_ .. ".json", raw)
	FS.delete(cfgFolder() .. "/" .. old .. ".json")
	if self.Config.Current == old then
		self.Config.Current = new_
	end
	return true
end

function Library:ExportConfig()
	local ok, json = pcall(function()
		return HttpService:JSONEncode(self:GetConfigData())
	end)
	if not ok then
		return nil
	end
	if type(setclipboard) == "function" then
		pcall(setclipboard, json)
	end
	return json
end

function Library:ImportConfig(json, saveAs)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(data) ~= "table" then
		return false, "Invalid JSON."
	end
	local ok2, n = self:ApplyConfigData(data)
	if ok2 and saveAs and cleanName(saveAs) ~= "" then
		self:SaveConfig(saveAs)
	end
	return ok2, n
end

function Library:ResetConfig()
	self._fireOnLoad = true
	for _, entry in pairs(self._setters) do
		if entry.default ~= nil then
			pcall(entry.set, entry.default)
		end
	end
	self._fireOnLoad = false
end

function Library:SetAutoSave(state)
	self.Config.AutoSave = state and true or false
	self:SaveSettings()
end

-- auto-save loop: re-saves the current config when any value changed
task.spawn(function()
	while true do
		task.wait(4)
		if not Library._inited and env.PickasHubUI ~= Library then
			break
		end
		if Library.Config.AutoSave and Library.Config.Current then
			local ok, json = pcall(function()
				return HttpService:JSONEncode(Library:GetConfigData())
			end)
			if ok then
				-- ignore the timestamp when comparing
				local a = json:gsub('"Saved":%d+', "")
				local b = (Library._lastSaved or ""):gsub('"Saved":%d+', "")
				if a ~= b then
					Library:SaveConfig(Library.Config.Current)
				end
			end
		end
	end
end)

--------------------------------------------------------------------
-- Settings (language, theme, sizes) saved as settings.json
--------------------------------------------------------------------
local THEME_KEYS = {
	"Background", "Background2", "Secondary", "Surface", "Element", "Accent", "AccentDark", "GradientA", "GradientB",
	"Text", "Muted", "Border", "Stroke", "Hover", "Active", "Disabled", "Success", "Warning", "Error", "Info",
}
Library.ThemeKeys = THEME_KEYS
Library.Settings = { OrbSize = 44, FontName = "Gotham", FontScale = 1 }

function Library:SaveSettings()
	local colors = {}
	for _, k in ipairs(THEME_KEYS) do
		colors[k] = toHex(self.Theme[k])
	end
	local s = {
		Language = self.Language, ThemeName = self.Theme.Name, Colors = colors, Transparency = self.Theme.Transparency,
		CornerRadius = self.Theme.CornerRadius, AnimSpeed = self.Theme.AnimSpeed, ReduceAnimations = self.ReduceAnimations,
		OrbSize = self.Settings.OrbSize, FontName = self.Settings.FontName, FontScale = self.Settings.FontScale,
		AutoSave = self.Config.AutoSave, AutoLoad = self.Config.AutoLoad, CustomThemes = self._customThemes or {},
	}
	FS.folder(self.Config.Folder)
	local ok, json = pcall(function()
		return HttpService:JSONEncode(s)
	end)
	if ok then
		FS.write(self.Config.Folder .. "/settings.json", json)
	end
end

function Library:LoadSettings()
	local raw = FS.read(self.Config.Folder .. "/settings.json")
	if not raw then
		return false
	end
	local ok, s = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(s) ~= "table" then
		return false
	end
	self._customThemes = s.CustomThemes or {}
	for name, cols in pairs(self._customThemes) do
		local t = {}
		for k, hex in pairs(cols) do
			t[k] = fromHex(hex)
		end
		self.Presets[name] = derive(t)
	end
	if s.Colors then
		local t = {}
		for k, hex in pairs(s.Colors) do
			t[k] = fromHex(hex)
		end
		self:SetTheme(t)
		self.Theme.Name = s.ThemeName or self.Theme.Name
	end
	if s.Transparency then
		self.Theme.Transparency = s.Transparency
	end
	if s.CornerRadius then
		self.Theme.CornerRadius = s.CornerRadius
	end
	self:_ApplyTheme()
	if s.AnimSpeed then
		self:SetAnimationSpeed(s.AnimSpeed)
	end
	if s.ReduceAnimations ~= nil then
		self.ReduceAnimations = s.ReduceAnimations
	end
	if s.Language then
		self:SetLanguage(s.Language)
	end
	if s.OrbSize then
		self:SetOrbSize(s.OrbSize)
	end
	if s.FontName then
		self:SetFont(s.FontName)
	end
	if s.FontScale then
		self:SetFontScale(s.FontScale)
	end
	self.Config.AutoSave = s.AutoSave == true
	self.Config.AutoLoad = s.AutoLoad
	return true
end

-- wrap Init: load saved settings, then optionally auto-load a config
do
	local origInit = Library.Init
	function Library:Init(opts)
		if self._inited then
			return self
		end
		origInit(self, opts)
		opts = opts or {}
		if opts.ConfigFolder then
			self.Config.Folder = opts.ConfigFolder
		end
		if opts.LoadSettings ~= false then
			pcall(function()
				self:LoadSettings()
			end)
		end
		return self
	end
end

function Library:AutoLoadConfig()
	if self.Config.AutoLoad and self.Config.AutoLoad ~= "" then
		return self:LoadConfig(self.Config.AutoLoad)
	end
	return false
end

function Library:SetTransparency(v)
	self.Theme.Transparency = math.clamp(v, 0, 0.8)
	self:_ApplyTheme()
end

function Library:SetCornerRadius(v)
	self.Theme.CornerRadius = math.clamp(math.floor(v), 0, 30)
	self:_ApplyTheme()
end

function Library:SetOrbSize(px)
	px = math.clamp(math.floor(px), 28, 90)
	self.Settings.OrbSize = px
	local o = self.Orb
	if o and o.Frame then
		tween(o.Frame, 0.2, { Size = UDim2.fromOffset(px, px) })
		if o.Icon then
			tween(o.Icon, 0.2, { Size = UDim2.fromOffset(math.floor(px * 0.5), math.floor(px * 0.5)) })
		end
	end
end

--------------------------------------------------------------------
-- Fonts
--------------------------------------------------------------------
Library.Fonts = {
	Gotham = { Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold },
	Montserrat = { Enum.Font.Montserrat, Enum.Font.Montserrat, Enum.Font.GothamBold },
	SourceSans = { Enum.Font.SourceSans, Enum.Font.SourceSansSemibold, Enum.Font.SourceSansBold },
	Ubuntu = { Enum.Font.Ubuntu, Enum.Font.Ubuntu, Enum.Font.Ubuntu },
	Arial = { Enum.Font.Arial, Enum.Font.Arial, Enum.Font.ArialBold },
	Roboto = { Enum.Font.Roboto, Enum.Font.Roboto, Enum.Font.RobotoCondensed },
	Fredoka = { Enum.Font.FredokaOne, Enum.Font.FredokaOne, Enum.Font.FredokaOne },
}

function Library:RegisterFont(name, regular, medium, bold)
	self.Fonts[name] = { regular, medium or regular, bold or medium or regular }
end

local function eachText(root, fn)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			fn(d)
		end
	end
end

function Library:SetFont(name)
	local set = self.Fonts[name]
	if not set or not self.Gui then
		self.Settings.FontName = name
		return false
	end
	local old = self.Fonts[self.Settings.FontName] or self.Fonts.Gotham
	local map = {}
	for i = 3, 1, -1 do
		map[old[i]] = set[i]
	end
	eachText(self.Gui, function(t)
		if t.Font ~= Enum.Font.Code and map[t.Font] then
			t.Font = map[t.Font]
		end
	end)
	FONT.Regular, FONT.Medium, FONT.Bold = set[1], set[2], set[3]
	self.Settings.FontName = name
	return true
end

function Library:SetFontScale(scale)
	scale = math.clamp(scale, 0.8, 1.3)
	self.Settings.FontScale = scale
	if not self.Gui then
		return
	end
	eachText(self.Gui, function(t)
		local base = t:GetAttribute("_base")
		if not base then
			base = t.TextSize
			t:SetAttribute("_base", base)
		end
		t.TextSize = math.max(8, math.floor(base * scale + 0.5))
	end)
end

--------------------------------------------------------------------
-- Registries: custom themes, icons, components
--------------------------------------------------------------------
function Library:RegisterTheme(name, colors)
	self.Presets[name] = derive(colors or {})
	return self.Presets[name]
end

function Library:SaveCustomTheme(name)
	name = cleanName(name)
	if name == "" then
		return false
	end
	local cols = {}
	for _, k in ipairs(THEME_KEYS) do
		cols[k] = toHex(self.Theme[k])
	end
	self._customThemes = self._customThemes or {}
	self._customThemes[name] = cols
	local t = {}
	for k, hex in pairs(cols) do
		t[k] = fromHex(hex)
	end
	self.Presets[name] = derive(t)
	self.Theme.Name = name
	self:SaveSettings()
	return true
end

function Library:ExportTheme()
	local cols = {}
	for _, k in ipairs(THEME_KEYS) do
		cols[k] = toHex(self.Theme[k])
	end
	local ok, json = pcall(function()
		return HttpService:JSONEncode({ Name = self.Theme.Name, Colors = cols })
	end)
	if ok and type(setclipboard) == "function" then
		pcall(setclipboard, json)
	end
	return ok and json or nil
end

function Library:ImportTheme(json)
	local ok, d = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(d) ~= "table" or type(d.Colors) ~= "table" then
		return false
	end
	local t = {}
	for k, hex in pairs(d.Colors) do
		t[k] = fromHex(hex)
	end
	self:SetTheme(t)
	return true
end

Library.CustomIcons = {}
function Library:RegisterIcon(name, assetId)
	self.CustomIcons[name] = type(assetId) == "number" and ("rbxassetid://" .. assetId) or tostring(assetId)
end

Library.CustomComponents = {}
function Library:RegisterComponent(name, builder)
	self.CustomComponents[name] = builder
	SectionClass["Add" .. name] = function(sec, opts)
		return builder(sec, parseOpts(opts), sec.Library)
	end
end

function SectionClass:AddCustom(name, opts)
	local b = self.Library.CustomComponents[name]
	if not b then
		warn("[PickasUI] unknown custom component: " .. tostring(name))
		return nil
	end
	return b(self, parseOpts(opts), self.Library)
end

-- dynamic component: builds from a table description
function SectionClass:AddDynamic(desc)
	local method = "Add" .. tostring(desc.Type)
	local f = self[method]
	if not f then
		warn("[PickasUI] unknown component type: " .. tostring(desc.Type))
		return nil
	end
	return f(self, desc)
end

function SectionClass:AddDynamicList(list)
	local out = {}
	for i, d in ipairs(list) do
		out[i] = self:AddDynamic(d)
	end
	return out
end

--------------------------------------------------------------------
-- Keybind manager
--------------------------------------------------------------------
function SectionClass:AddKeybindManager(opts)
	opts = parseOpts(opts)
	local lib, parts = Library._stack(self, opts, 12)
	local obj = { Type = "KeybindManager" }
	local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parts.Body })
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
	local listening
	local function render()
		for _, c in ipairs(box:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local used = {}
		for _, k in ipairs(lib._keybinds) do
			if k.KeybindValue then
				used[k.KeybindValue] = (used[k.KeybindValue] or 0) + 1
			end
		end
		if #lib._keybinds == 0 then
			lib:_Text(box, "No keybinds registered.", 11, FONT.Regular, "Muted", { Size = UDim2.new(1, 0, 0, 20) })
		end
		for i, k in ipairs(lib._keybinds) do
			local f = new("Frame", { Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, Parent = box })
			lib:Bind(f, "BackgroundColor3", "Secondary")
			lib:_Round(f, 0.45)
			lib:_Text(f, k.Name or k.Title or "Keybind", 12, FONT.Medium, "Text", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -110, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
			local conflict = k.KeybindValue and used[k.KeybindValue] > 1
			local b = new("TextButton", {
				Text = listening == k and "..." or (k.KeybindValue and k.KeybindValue.Name or "None"), Font = FONT.Bold, TextSize = 11, AutoButtonColor = false,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(90, 20), Parent = f,
			})
			lib:Bind(b, "BackgroundColor3", "Element")
			b.TextColor3 = conflict and lib.Theme.Warning or lib.Theme.Accent
			lib:_Round(b, 0.4)
			connect(b.Activated, function()
				listening = k
				render()
			end)
		end
	end
	connect(UserInputService.InputBegan, function(input)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			local k = listening
			listening = nil
			if input.KeyCode == Enum.KeyCode.Escape then
				k:SetKeybind(nil)
			else
				k:SetKeybind(input.KeyCode)
			end
			render()
		end
	end)
	render()
	function obj:Refresh()
		render()
	end
	lib:_Finish(obj, parts, opts)
	return obj
end

--------------------------------------------------------------------
-- Patches: custom icons + translatable library strings
--------------------------------------------------------------------
do
	local origIcon = Library.GetIcon
	function Library:GetIcon(name)
		if type(name) == "string" and self.CustomIcons[name] then
			return self.CustomIcons[name]
		end
		return origIcon(self, name)
	end
end

--==================================================================
-- PART 6: Forwarding, Configure window, translations, demo
--==================================================================

-- Pages (tabs / subtabs) can add any component directly (a default section is created)
for name, fn in pairs(SectionClass) do
	if type(name) == "string" and name:sub(1, 3) == "Add" and type(fn) == "function" and rawget(PageClass, name) == nil then
		PageClass[name] = function(self, ...)
			local s = defaultSection(self)
			return s[name](s, ...)
		end
	end
end

function Library:QueueSaveSettings()
	if self._saveQ then
		return
	end
	self._saveQ = true
	task.delay(1, function()
		self._saveQ = false
		if self._inited then
			self:SaveSettings()
		end
	end)
end

--------------------------------------------------------------------
-- Translations for library-owned strings (other languages fall back to English)
--------------------------------------------------------------------
do
	local keys = {
		"Configs", "Settings", "Theme", "Keybinds", "Preview", "Save", "Load", "Delete", "Language", "Color Palette",
		"Floating Button Size", "UI Transparency", "Corner Radius", "Animation Speed", "Reduce Animations", "Auto Save",
		"Reset", "Import", "Export", "Rename", "Config Name", "Saved Configs",
	}
	local data = {
		ja = { "設定ファイル", "設定", "テーマ", "キーバインド", "プレビュー", "保存", "読み込み", "削除", "言語", "カラーパレット", "フローティングボタンのサイズ", "UIの透明度", "角の丸み", "アニメーション速度", "アニメーションを減らす", "自動保存", "リセット", "インポート", "エクスポート", "名前を変更", "設定名", "保存済み設定" },
		zh = { "配置", "设置", "主题", "按键绑定", "预览", "保存", "加载", "删除", "语言", "调色板", "悬浮按钮大小", "界面透明度", "圆角", "动画速度", "减少动画", "自动保存", "重置", "导入", "导出", "重命名", "配置名称", "已保存的配置" },
		ko = { "구성", "설정", "테마", "단축키", "미리보기", "저장", "불러오기", "삭제", "언어", "색상 팔레트", "플로팅 버튼 크기", "UI 투명도", "모서리 둥글기", "애니메이션 속도", "애니메이션 줄이기", "자동 저장", "초기화", "가져오기", "내보내기", "이름 바꾸기", "구성 이름", "저장된 구성" },
		es = { "Configuraciones", "Ajustes", "Tema", "Atajos", "Vista previa", "Guardar", "Cargar", "Eliminar", "Idioma", "Paleta de colores", "Tamaño del botón flotante", "Transparencia de la interfaz", "Radio de las esquinas", "Velocidad de animación", "Reducir animaciones", "Guardado automático", "Restablecer", "Importar", "Exportar", "Renombrar", "Nombre de la configuración", "Configuraciones guardadas" },
		fil = { "Mga Config", "Mga Setting", "Tema", "Mga Keybind", "Preview", "I-save", "I-load", "Tanggalin", "Wika", "Paleta ng Kulay", "Laki ng Floating Button", "Transparency ng UI", "Bilog ng Sulok", "Bilis ng Animation", "Bawasan ang Animation", "Auto Save", "I-reset", "I-import", "I-export", "Palitan ang Pangalan", "Pangalan ng Config", "Mga Naka-save na Config" },
		pt = { "Configurações salvas", "Configurações", "Tema", "Atalhos", "Pré-visualização", "Salvar", "Carregar", "Excluir", "Idioma", "Paleta de cores", "Tamanho do botão flutuante", "Transparência da interface", "Raio dos cantos", "Velocidade da animação", "Reduzir animações", "Salvamento automático", "Redefinir", "Importar", "Exportar", "Renomear", "Nome da configuração", "Configurações salvas" },
		ru = { "Конфигурации", "Настройки", "Тема", "Горячие клавиши", "Предпросмотр", "Сохранить", "Загрузить", "Удалить", "Язык", "Цветовая палитра", "Размер плавающей кнопки", "Прозрачность интерфейса", "Скругление углов", "Скорость анимации", "Уменьшить анимацию", "Автосохранение", "Сбросить", "Импорт", "Экспорт", "Переименовать", "Название конфигурации", "Сохранённые конфигурации" },
		fr = { "Configurations", "Paramètres", "Thème", "Raccourcis", "Aperçu", "Enregistrer", "Charger", "Supprimer", "Langue", "Palette de couleurs", "Taille du bouton flottant", "Transparence de l'interface", "Rayon des coins", "Vitesse d'animation", "Réduire les animations", "Sauvegarde auto", "Réinitialiser", "Importer", "Exporter", "Renommer", "Nom de la configuration", "Configurations enregistrées" },
		de = { "Konfigurationen", "Einstellungen", "Design", "Tastenbelegung", "Vorschau", "Speichern", "Laden", "Löschen", "Sprache", "Farbpalette", "Größe des schwebenden Buttons", "UI-Transparenz", "Eckenradius", "Animationsgeschwindigkeit", "Animationen reduzieren", "Automatisch speichern", "Zurücksetzen", "Importieren", "Exportieren", "Umbenennen", "Konfigurationsname", "Gespeicherte Konfigurationen" },
		tr = { "Yapılandırmalar", "Ayarlar", "Tema", "Tuş Atamaları", "Önizleme", "Kaydet", "Yükle", "Sil", "Dil", "Renk Paleti", "Yüzen Düğme Boyutu", "Arayüz Şeffaflığı", "Köşe Yuvarlaklığı", "Animasyon Hızı", "Animasyonları Azalt", "Otomatik Kaydet", "Sıfırla", "İçe Aktar", "Dışa Aktar", "Yeniden Adlandır", "Yapılandırma Adı", "Kayıtlı Yapılandırmalar" },
		id = { "Konfigurasi", "Pengaturan", "Tema", "Pintasan", "Pratinjau", "Simpan", "Muat", "Hapus", "Bahasa", "Palet Warna", "Ukuran Tombol Mengambang", "Transparansi UI", "Radius Sudut", "Kecepatan Animasi", "Kurangi Animasi", "Simpan Otomatis", "Atur Ulang", "Impor", "Ekspor", "Ganti Nama", "Nama Konfigurasi", "Konfigurasi Tersimpan" },
		vi = { "Cấu hình", "Cài đặt", "Giao diện", "Phím tắt", "Xem trước", "Lưu", "Tải", "Xóa", "Ngôn ngữ", "Bảng màu", "Kích thước nút nổi", "Độ trong suốt giao diện", "Bo góc", "Tốc độ hiệu ứng", "Giảm hiệu ứng", "Tự động lưu", "Đặt lại", "Nhập", "Xuất", "Đổi tên", "Tên cấu hình", "Cấu hình đã lưu" },
		th = { "คอนฟิก", "การตั้งค่า", "ธีม", "ปุ่มลัด", "ตัวอย่าง", "บันทึก", "โหลด", "ลบ", "ภาษา", "จานสี", "ขนาดปุ่มลอย", "ความโปร่งใสของ UI", "ความโค้งมุม", "ความเร็วแอนิเมชัน", "ลดแอนิเมชัน", "บันทึกอัตโนมัติ", "รีเซ็ต", "นำเข้า", "ส่งออก", "เปลี่ยนชื่อ", "ชื่อคอนฟิก", "คอนฟิกที่บันทึกไว้" },
	}
	for code, list in pairs(data) do
		Library.Translations[code] = Library.Translations[code] or {}
		for i, k in ipairs(keys) do
			Library.Translations[code][k] = list[i]
		end
	end
end

--------------------------------------------------------------------
-- Configure window
--------------------------------------------------------------------
function Library:_BuildConfigure(parentOpts)
	local lib = self
	local win = self:CreateWindow({
		Name = "Configure", Subtitle = "Configs & Settings", Logo = self.ConfigureIcon, Kind = "Configure", GameTag = false,
		Width = 600, Height = 410, Configure = false,
	})
	win:AddTag(self.Version and ("v" .. self.Version) or "v1", "Accent")
	local tab = win:CreateTab({ Name = "Configure", Icon = self.ConfigureIcon })
	local pickers = {}

	local function note(ok, msg, okText)
		lib:Notify({
			Title = ok and (okText or "Done") or "Error", Description = ok and (type(msg) == "number" and (msg .. " values applied") or "") or tostring(msg),
			Type = ok and "Success" or "Error", Duration = 3,
		})
	end

	-- Configs ---------------------------------------------------
	local cfg = tab:AddSubtab({ Name = "Configs" })
	local manage = cfg:AddSection({ Name = "Manage", Icon = "save", Column = 1 })
	local nameBox = manage:AddTextbox({ Name = "Config Name", Placeholder = "my-config", MaxLength = 32 })
	local list = manage:AddDropdown({ Name = "Saved Configs", Options = lib:ListConfigs(), Placeholder = "Select..." })
	local function refresh()
		list:SetOptions(lib:ListConfigs())
	end
	local function pick()
		local n = list:Get()
		if n == nil or n == "" then
			n = nameBox:Get()
		end
		return n
	end
	manage:AddButton({
		Name = "Save", Icon = "save", Description = "Save all current values", Callback = function()
			local n = nameBox:Get()
			if n == "" then
				n = list:Get() or ""
			end
			local ok, err = lib:SaveConfig(n)
			note(ok, err, "Saved")
			refresh()
			if ok then
				list:Set(lib.Config.Current, true)
			end
		end,
	})
	manage:AddButton({
		Name = "Load", Icon = "folder-open", Callback = function()
			local ok, res = lib:LoadConfig(pick() or "")
			note(ok, res, "Loaded")
		end,
	})
	manage:AddButton({
		Name = "Delete", Icon = "trash-2", Callback = function()
			local n = pick()
			if not n or n == "" then
				return note(false, "Select a config first.")
			end
			win:Confirm({
				Title = "Delete config?", Message = "This cannot be undone.", OnYes = function()
					lib:DeleteConfig(n)
					refresh()
					note(true, "", "Deleted")
				end,
			})
		end,
	})
	local renameBox = manage:AddTextbox({ Name = "Rename", Placeholder = "New name", MaxLength = 32 })
	manage:AddButton({
		Name = "Rename", Icon = "pencil", Callback = function()
			local ok, err = lib:RenameConfig(list:Get() or "", renameBox:Get())
			note(ok, err, "Renamed")
			refresh()
		end,
	})

	local share = cfg:AddSection({ Name = "Share & Automation", Icon = "share-2", Column = 2 })
	local importBox = share:AddTextArea({ Name = "Import", Placeholder = "Paste config JSON here..." })
	share:AddButton({
		Name = "Import", Icon = "download", Callback = function()
			local ok, res = lib:ImportConfig(importBox:Get(), nameBox:Get())
			note(ok, res, "Imported")
			refresh()
		end,
	})
	share:AddButton({
		Name = "Export", Icon = "upload", Description = "Copies the JSON to your clipboard", Callback = function()
			local json = lib:ExportConfig()
			if json then
				importBox:Set(json, true)
				note(true, "", type(setclipboard) == "function" and "Copied to clipboard" or "JSON placed in the box")
			else
				note(false, "Could not export.")
			end
		end,
	})
	share:AddToggle({
		Name = "Auto Save", Description = "Re-saves the loaded config when values change", Default = lib.Config.AutoSave, Callback = function(v)
			lib:SetAutoSave(v)
		end,
	})
	share:AddToggle({
		Name = "Auto Load", Description = "Loads the selected config on startup", Default = lib.Config.AutoLoad ~= nil and lib.Config.AutoLoad ~= "", Callback = function(v)
			lib.Config.AutoLoad = v and (list:Get() or lib.Config.Current) or nil
			lib:SaveSettings()
		end,
	})
	share:AddButton({
		Name = "Reset", Icon = "rotate-ccw", Description = "Restore default values", Callback = function()
			win:Confirm({
				Title = "Reset all values?", Message = "Every saved flag returns to its default.", OnYes = function()
					lib:ResetConfig()
					note(true, "", "Reset")
				end,
			})
		end,
	})
	local where = FS.available() and (lib.Config.Folder .. "/configs  (.json)") or "Memory only (executor has no file access)"
	share:AddLabel({ Name = where, Icon = "folder" })

	-- Settings --------------------------------------------------
	local set = tab:AddSubtab({ Name = "Settings" })
	local gen = set:AddSection({ Name = "Interface", Icon = "sliders-horizontal", Column = 1 })
	local langOpts = {}
	for _, l in ipairs(lib.LanguageList) do
		langOpts[#langOpts + 1] = { Name = l.Name, Value = l.Code, Description = l.Code }
	end
	gen:AddDropdown({
		Name = "Language", Icon = "languages", Options = langOpts, Searchable = true, Default = lib.Language, Callback = function(code)
			if code then
				lib:SetLanguage(code)
				lib:QueueSaveSettings()
			end
		end,
	})
	local names = {}
	for n in pairs(lib.Presets) do
		names[#names + 1] = n
	end
	table.sort(names)
	local palette = gen:AddDropdown({
		Name = "Color Palette", Icon = "palette", Options = names, Default = lib.Theme.Name, Callback = function(n)
			if n and lib:SetTheme(n) then
				for k, p in pairs(pickers) do
					p:Set(lib.Theme[k], true)
				end
				lib:QueueSaveSettings()
			end
		end,
	})
	gen:AddSlider({
		Name = "Floating Button Size", Icon = "circle-dot", Min = 28, Max = 90, Default = lib.Settings.OrbSize, Suffix = " px", Callback = function(v)
			lib:SetOrbSize(v)
			lib:QueueSaveSettings()
		end,
	})
	gen:AddSlider({
		Name = "UI Transparency", Icon = "blend", Min = 0, Max = 60, Default = math.floor(lib.Theme.Transparency * 100), Suffix = "%", Callback = function(v)
			lib:SetTransparency(v / 100)
			lib:QueueSaveSettings()
		end,
	})
	gen:AddSlider({
		Name = "Corner Radius", Icon = "square", Min = 0, Max = 24, Default = lib.Theme.CornerRadius, Callback = function(v)
			lib:SetCornerRadius(v)
			lib:QueueSaveSettings()
		end,
	})

	local look = set:AddSection({ Name = "Animation & Text", Icon = "sparkles", Column = 2 })
	look:AddSlider({
		Name = "Animation Speed", Min = 0.5, Max = 3, Increment = 0.1, Default = lib.Theme.AnimSpeed, Suffix = "x", Callback = function(v)
			lib:SetAnimationSpeed(v)
			lib:QueueSaveSettings()
		end,
	})
	look:AddToggle({
		Name = "Reduce Animations", Default = lib.ReduceAnimations, Callback = function(v)
			lib:SetReduceAnimations(v)
			lib:QueueSaveSettings()
		end,
	})
	local fonts = {}
	for n in pairs(lib.Fonts) do
		fonts[#fonts + 1] = n
	end
	table.sort(fonts)
	look:AddDropdown({
		Name = "Font", Icon = "type", Options = fonts, Default = lib.Settings.FontName, Callback = function(n)
			if n then
				lib:SetFont(n)
				lib:QueueSaveSettings()
			end
		end,
	})
	look:AddSlider({
		Name = "Font Size", Min = 80, Max = 130, Default = math.floor(lib.Settings.FontScale * 100), Suffix = "%", Callback = function(v)
			lib:SetFontScale(v / 100)
			lib:QueueSaveSettings()
		end,
	})

	look:AddButton({
		Name = "Reset Appearance", Icon = "rotate-ccw", Description = "Back to the default dark purple theme", Callback = function()
			lib:SetTheme("Amethyst")
			lib:SetTransparency(0)
			lib:SetCornerRadius(12)
			lib:SetAnimationSpeed(1)
			lib:SetReduceAnimations(false)
			lib:SetOrbSize(44)
			lib:SetFont("Gotham")
			lib:SetFontScale(1)
			for k, p in pairs(pickers) do
				p:Set(lib.Theme[k], true)
			end
			lib:SaveSettings()
			lib:Notify({ Title = "Appearance reset", Type = "Success", Duration = 2 })
		end,
	})

	-- Theme editor ----------------------------------------------
	local th = tab:AddSubtab({ Name = "Theme" })
	local colors = th:AddSection({ Name = "Colors", Icon = "droplet", Column = 1 })
	for _, k in ipairs({ "Accent", "GradientA", "GradientB", "Background", "Background2", "Surface", "Element", "Text", "Muted", "Border" }) do
		pickers[k] = colors:AddColorPicker({
			Name = k, Default = lib.Theme[k], Callback = function(c)
				lib:SetThemeValue(k, c)
				lib:QueueSaveSettings()
			end,
		})
	end
	local status = th:AddSection({ Name = "Status Colors", Icon = "circle-alert", Column = 2 })
	for _, k in ipairs({ "Success", "Warning", "Error", "Info" }) do
		pickers[k] = status:AddColorPicker({
			Name = k, Default = lib.Theme[k], Callback = function(c)
				lib:SetThemeValue(k, c)
				lib:QueueSaveSettings()
			end,
		})
	end
	local custom = th:AddSection({ Name = "Custom Themes", Icon = "wand-sparkles", Column = 2 })
	local themeName = custom:AddTextbox({ Name = "Theme name", Placeholder = "My Theme", MaxLength = 24 })
	custom:AddButton({
		Name = "Save", Icon = "save", Description = "Save the current colors as a theme", Callback = function()
			local ok = lib:SaveCustomTheme(themeName:Get())
			note(ok, "Enter a theme name.", "Theme saved")
		end,
	})
	local themeJson = custom:AddTextArea({ Name = "Theme JSON", Placeholder = "Paste a theme JSON..." })
	custom:AddButton({
		Name = "Import", Icon = "download", Callback = function()
			local ok = lib:ImportTheme(themeJson:Get())
			if ok then
				for k, p in pairs(pickers) do
					p:Set(lib.Theme[k], true)
				end
				lib:QueueSaveSettings()
			end
			note(ok, "Invalid theme JSON.", "Theme imported")
		end,
	})
	custom:AddButton({
		Name = "Export", Icon = "upload", Callback = function()
			local j = lib:ExportTheme()
			if j then
				themeJson:Set(j, true)
			end
			note(j ~= nil, "Could not export.", "Theme exported")
		end,
	})

	-- Keybinds ---------------------------------------------------
	local kb = tab:AddSubtab({ Name = "Keybinds", Columns = 1 })
	local ks = kb:AddSection({ Name = "Keybind Manager", Icon = "keyboard" })
	local mgr = ks:AddKeybindManager({})
	ks:AddButton({
		Name = "Refresh", Icon = "refresh-cw", Callback = function()
			mgr:Refresh()
		end,
	})
	ks:AddButton({
		Name = "Open Command Palette", Icon = "terminal", Description = "Shortcut: Ctrl + K", Callback = function()
			lib:OpenCommandPalette()
		end,
	})

	-- Preview ----------------------------------------------------
	local pv = tab:AddSubtab({ Name = "Preview" })
	local p1 = pv:AddSection({ Name = "Live Preview", Icon = "eye", Column = 1 })
	p1:AddButton({ Name = "Sample button", Icon = "mouse-pointer-click", Callback = function()
		lib:Notify({ Title = "Preview", Description = "Button pressed", Type = "Info", Duration = 2 })
	end })
	p1:AddToggle({ Name = "Sample toggle", Description = "Changes reflect instantly", Default = true })
	p1:AddSlider({ Name = "Sample slider", Min = 0, Max = 100, Default = 40 })
	p1:AddProgressBar({ Name = "Sample progress", Default = 65 })
	p1:AddChips({ Name = "Chips", Items = { "Alpha", "Beta", "Gamma" } })
	local p2 = pv:AddSection({ Name = "Components", Icon = "layout-grid", Column = 2 })
	p2:AddDropdown({ Name = "Sample dropdown", Options = { "One", "Two", "Three" }, Default = "One" })
	p2:AddCheckbox({ Name = "Sample checkbox", Default = true })
	p2:AddRadio({ Name = "Sample radio", Options = { "A", "B", "C" }, Default = "A" })
	p2:AddStatus({ Name = "Status", State = "Online" })
	p2:AddCircularProgress({ Name = "Circular", Default = 72, Size = 70 })

	lib._cfgWin = win
	return win
end

do
	local origCreate = Library.CreateWindow
	function Library:CreateWindow(opts)
		opts = opts or {}
		local w = origCreate(self, opts)
		if (opts.Kind or "Main") == "Main" and opts.Configure ~= false and not self._cfgBuilt then
			self._cfgBuilt = true
			task.defer(function()
				if self._inited then
					local ok, err = pcall(function()
						self:_BuildConfigure(opts)
					end)
					if not ok then
						warn("[PickasUI] Configure window failed: " .. tostring(err))
					end
				end
			end)
		end
		return w
	end
end

-- Call once after building all windows: applies saved font size, registers default commands, auto-loads config
function Library:Finish()
	local lib = self
	if self._finished then
		return self
	end
	self._finished = true
	task.defer(function()
		if lib.Settings.FontScale and lib.Settings.FontScale ~= 1 then
			lib:SetFontScale(lib.Settings.FontScale)
		end
		lib:AutoLoadConfig()
	end)
	self:RegisterCommand({ Name = "Open Configure", Description = "Configs, language, theme", Icon = "settings", Callback = function()
		local c = lib:_FindWindow("Configure")
		if c then
			for _, w in ipairs(lib.Windows) do
				if w ~= c then
					w:Hide()
				end
			end
			c:Show()
		end
	end })
	self:RegisterCommand({ Name = "Toggle UI", Description = "Show or hide the windows", Icon = "eye", Callback = function()
		local main = lib:_FindWindow("Main")
		if main then
			main:Toggle()
		end
	end })
	self:RegisterCommand({ Name = "Reset all values", Description = "Return every flag to default", Icon = "rotate-ccw", Callback = function()
		lib:ResetConfig()
	end })
	for name in pairs(self.Presets) do
		self:RegisterCommand({ Name = "Theme: " .. name, Description = "Switch color palette", Icon = "palette", Callback = function()
			lib:SetTheme(name)
			lib:QueueSaveSettings()
		end })
	end
	return self
end

--------------------------------------------------------------------
-- Demo
--------------------------------------------------------------------
function Library:Demo()
	local lib = self
	lib:AddTranslations({
		fil = { ["Welcome to Picka's Hub"] = "Maligayang pagdating sa Picka's Hub" },
		ja = { ["Welcome to Picka's Hub"] = "Picka's Hubへようこそ" },
		es = { ["Welcome to Picka's Hub"] = "Bienvenido a Picka's Hub" },
	})
	local win = lib:CreateWindow({
		Name = "Picka's Hub", Subtitle = "Component demo", Logo = "zap", Version = "v" .. lib.Version, KeyStatus = "KEY", AutoShow = false,
	})
	win:EnableHeaderButtons({ Search = true, Settings = true, Maximize = true })
	win:SetFooter("Ctrl + K opens the command palette")
	win:SetResizable(520, 340)

	-- Home
	local home = win:CreateTab({ Name = "Home", Icon = "house" })
	local overview = home:AddSubtab({ Name = "Overview" })
	local charts = home:AddSubtab({ Name = "Charts" })
	local c1 = overview:AddSection({ Name = "Welcome", Icon = "sparkles", Column = 1 })
	c1:AddWelcomePanel({ Title = { en = "Welcome to Picka's Hub", fil = "Maligayang pagdating sa Picka's Hub", ja = "Picka's Hubへようこそ" }, Message = "Tap the orb to switch between the hub and Configure.", ButtonText = "Say hi", Callback = function()
		lib:Notify({ Title = "Hello!", Description = "Everything is translatable.", Type = "Success" })
	end })
	c1:AddDashboard({ Stats = { { Title = "Kills", Value = 128, Delta = "+12" }, { Title = "Coins", Value = "4.2K", Delta = "-3" } } })
	c1:AddStatus({ Name = "Server", State = "Online" })
	c1:AddActivityFeed({ Name = "Activity", Items = { { Text = "Config loaded", Icon = "folder-open", Type = "Success" }, { Text = "Theme changed", Icon = "palette" } } })
	local c2 = overview:AddSection({ Name = "Actions", Icon = "mouse-pointer-click", Column = 2 })
	c2:AddToggle({ Name = "Auto Farm", Description = "Farms automatically", Icon = "zap", Flag = "AutoFarm", Keybind = Enum.KeyCode.F, Status = true })
	c2:AddToggle({ Name = "Kill Aura", Locked = true, LockTag = "PREMIUM", LockMessage = "Kill Aura needs a premium key." })
	c2:AddSlider({ Name = "Walk Speed", Min = 16, Max = 120, Default = 16, Flag = "WalkSpeed", Suffix = " sps" })
	c2:AddDropdown({ Name = "Target", Options = { "Nearest", "Lowest HP", "Highest HP" }, Default = "Nearest", Flag = "Target" })
	c2:AddButton({ Name = "Show notification", Icon = "bell", Callback = function()
		lib:Notify({ Title = "Success", Description = "It works.", Type = "Success" })
	end })
	local d1 = charts:AddSection({ Name = "Charts", Icon = "chart-column", Column = 1 })
	d1:AddLineChart({ Name = "FPS", Data = { 58, 60, 55, 61, 59, 62, 57, 60 } })
	d1:AddBarChart({ Name = "Per day", Data = { { Name = "Mon", Value = 4 }, { Name = "Tue", Value = 9 }, { Name = "Wed", Value = 6 }, { Name = "Thu", Value = 12 } } })
	local d2 = charts:AddSection({ Name = "Rings", Icon = "chart-pie", Column = 2 })
	d2:AddDonutChart({ Name = "Split", Data = { { Name = "Farm", Value = 50 }, { Name = "PvP", Value = 30 }, { Name = "Other", Value = 20 } } })
	d2:AddCircularGauge({ Name = "CPU", Default = 64 })
	d2:AddProgressBar({ Name = "Download", Default = 45 })
	d2:AddLoadingBar({ Name = "Loading" })

	-- Inputs
	local inputs = win:CreateTab({ Name = "Inputs", Icon = "sliders-horizontal" })
	local basic = inputs:AddSubtab({ Name = "Basic" })
	local pick = inputs:AddSubtab({ Name = "Pickers" })
	local b1 = basic:AddSection({ Name = "Text", Icon = "type", Column = 1 })
	b1:AddTextbox({ Name = "Username", Placeholder = "Type here...", Flag = "Username" })
	b1:AddSearchBar({ Placeholder = "Search...", Callback = function() end })
	b1:AddNumberInput({ Name = "Amount", Min = 0, Max = 999, Default = 10, Flag = "Amount" })
	b1:AddTextArea({ Name = "Notes", Placeholder = "Multiline..." })
	local b2 = basic:AddSection({ Name = "Choices", Icon = "list-checks", Column = 2 })
	b2:AddCheckbox({ Name = "Enable feature", Default = true, Flag = "Feature" })
	b2:AddRadio({ Name = "Mode", Options = { "Legit", "Rage", "Silent" }, Default = "Legit", Flag = "Mode" })
	b2:AddStepper({ Name = "Count", Min = 0, Max = 20, Default = 5, Flag = "Count" })
	b2:AddRating({ Name = "Rating", Default = 3, Flag = "Rating" })
	b2:AddSegmented({ Name = "View", Options = { "List", "Grid", "Table" }, Default = "List" })
	b2:AddMultiDropdown({ Name = "Targets", Options = { "Players", "NPCs", "Bosses", "Chests" }, Default = { "Players" }, Flag = "Targets" })
	local p1 = pick:AddSection({ Name = "Pickers", Icon = "pipette", Column = 1 })
	p1:AddColorPicker({ Name = "ESP Color", Default = Color3.fromRGB(255, 80, 120), Flag = "EspColor" })
	p1:AddGradientPicker({ Name = "Gradient" })
	p1:AddKeybind({ Name = "Menu key", Default = Enum.KeyCode.RightShift, Flag = "MenuKey" })
	local p2 = pick:AddSection({ Name = "Date & Time", Icon = "calendar", Column = 2 })
	p2:AddDatePicker({ Name = "Date", Flag = "Date" })
	p2:AddTimePicker({ Name = "Time", Flag = "Time" })
	p2:AddRangeSlider({ Name = "Range", Min = 0, Max = 100, Default = { 20, 70 }, Flag = "Range" })
	p2:AddFilePicker({ Name = "File", Extensions = { "json", "lua", "txt" }, Flag = "File" })

	-- Display
	local disp = win:CreateTab({ Name = "Display", Icon = "layout-dashboard" })
	local data = disp:AddSubtab({ Name = "Data" })
	local misc = disp:AddSubtab({ Name = "Panels" })
	local a1 = data:AddSection({ Name = "Table & List", Icon = "table", Column = 1 })
	a1:AddTable({ Name = "Players", Columns = { "Name", "Score", "Ping" }, Rows = { { "Alice", 120, 40 }, { "Bob", 95, 60 }, { "Cara", 210, 30 } } })
	a1:AddList({ Name = "Items", Items = { { Name = "Sword", Icon = "swords", Value = "x1" }, { Name = "Potion", Icon = "flask-conical", Value = "x5" } } })
	a1:AddGrid({ Name = "Grid", Items = { { Name = "Farm", Icon = "wheat" }, { Name = "Mine", Icon = "pickaxe" }, { Name = "Fish", Icon = "fish" } } })
	local a2 = data:AddSection({ Name = "Tree & Code", Icon = "folder-tree", Column = 2 })
	a2:AddTreeView({ Name = "Files", Nodes = { { Name = "Scripts", Open = true, Children = { { Name = "main.lua" }, { Name = "utils.lua" } } }, { Name = "Assets", Children = { { Name = "icon.png" } } } } })
	a2:AddCodeBlock({ Name = "Snippet", Code = 'print("Hello Picka")\nlocal x = 1 + 1' })
	a2:AddConsole({ Name = "Console", Terminal = true, Lines = { "Ready.", { "All systems go", "Success" } }, OnCommand = function(cmd, con)
		con:Log("You ran: " .. cmd, "Info")
	end })
	local m1 = misc:AddSection({ Name = "Cards", Icon = "layout-panel-top", Column = 1 })
	m1:AddCard({ Kind = "Stat", Title = "Total coins", Value = "12,480", Delta = "+8%" })
	m1:AddCard({ Kind = "Info", Icon = "info", Title = "Tip", Content = "Press Ctrl + K to search every setting." })
	m1:AddAccordion({ Name = "FAQ", Items = { "Configs are saved as JSON.", "Language changes apply instantly." } })
	m1:AddBreadcrumb({ Items = { "Home", "Display", "Panels" } })
	m1:AddPagination({ Name = "Page", Pages = 8 })
	m1:AddChips({ Name = "Tags", Items = { "Fast", "Safe", "New" } })
	local m2 = misc:AddSection({ Name = "Timeline & Changelog", Icon = "history", Column = 2 })
	m2:AddTimeline({ Items = { { Title = "v1.0", Time = "Today", Description = "First release" }, { Title = "v1.1", Time = "Soon", Description = "More components" } } })
	m2:AddChangelog({ Versions = { { Version = "v1.0.0", Date = "2026-11", Changes = { "Initial release", "30 languages" } } } })
	m2:AddSkeleton({ Name = "Loading content" })
	m2:AddSpinner({})
	m2:AddTyping({ Texts = { "Initializing...", "Almost there..." } })

	-- Overlays
	local over = win:CreateTab({ Name = "Overlays", Icon = "layers", Columns = 1 })
	local o = over:AddSection({ Name = "Try them" })
	o:AddButton({ Name = "Modal", Icon = "app-window", Callback = function()
		lib:Modal({ Window = win, Title = "Hello", Message = "This is a modal dialog.", Buttons = { { Text = "Close" }, { Text = "OK", Primary = true } } })
	end })
	o:AddButton({ Name = "Alert", Icon = "triangle-alert", Callback = function()
		lib:Alert({ Window = win, Title = "Warning", Message = "Something needs attention.", Type = "Warning" })
	end })
	o:AddButton({ Name = "Banner", Icon = "megaphone", Callback = function()
		win:Banner({ Text = "Server restarting soon", Type = "Warning", Duration = 4 })
	end })
	o:AddButton({ Name = "Side panel", Icon = "panel-right", Callback = function()
		win:SidePanel({ Title = "Side Panel", Content = "Slides in from the right." })
	end })
	o:AddButton({ Name = "Bottom sheet", Icon = "panel-bottom", Callback = function()
		win:BottomSheet({ Title = "Bottom Sheet", Content = "Slides up from the bottom." })
	end })
	o:AddButton({ Name = "Context menu", Icon = "menu", Callback = function()
		lib:ContextMenu({ { Name = "Copy", Icon = "copy" }, { Name = "Paste", Icon = "clipboard" }, { Divider = true }, { Name = "Delete", Icon = "trash-2", Danger = true } })
	end })
	o:AddButton({ Name = "Command palette", Icon = "terminal", Callback = function()
		lib:OpenCommandPalette()
	end })
	o:AddButton({ Name = "Floating button", Icon = "plus", Callback = function()
		lib:FloatingButton({ Icon = "plus", Callback = function()
			lib:Notify({ Title = "FAB", Type = "Info", Duration = 2 })
		end })
	end })
	o:AddButton({ Name = "Mini window", Icon = "app-window-mac", Callback = function()
		local m = lib:MiniWindow({ Title = "Mini" })
		m:AddLabel("Draggable mini window")
	end })

	-- Locks
	local locked = win:CreateTab({ Name = "Admin", Icon = "shield", Locked = true, LockMessage = "Admins only." })

	lib:Finish()
	return win
end

--==================================================================
-- Export
--==================================================================
env.PickasHubUI = Library
if env.PickasUI_Demo then
	Library:Demo()
end
return Library
