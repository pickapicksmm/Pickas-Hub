--[[
	ASTERVEIL UI  |  Loader + API Examples
	Palitan lang ang LIB_URL kung saan mo naka-upload ang AsterveilUI.lua
	(o ilagay ang file sa executor workspace folder bilang "AsterveilUI.lua" para local ang load).
]]

local LIB_URL = "https://raw.githubusercontent.com/pickapicksmm/Pickas-Hub/refs/heads/main/AsterveilUI%20(5).lua"
local LOCAL_FILE = "AsterveilUI.lua"

------------------------------------------------------------ load library
local function loadLibrary()
	if readfile and isfile and isfile(LOCAL_FILE) then
		local ok, lib = pcall(function() return loadstring(readfile(LOCAL_FILE))() end)
		if ok and lib then return lib end
	end
	local ok, lib = pcall(function() return loadstring(game:HttpGet(LIB_URL))() end)
	if ok and lib then return lib end
	warn("[Asterveil Loader] Hindi na-load ang library: " .. tostring(lib))
end

local Library = loadLibrary()
if not Library then return end

------------------------------------------------------------ WINDOW
local Window = Library:CreateWindow({
	Title = "Asterveil",                 -- pangalan ng window
	Theme = "Space Universe",            -- Space Universe | Graphite | Silver | Midnight | Moonlight
	Folder = "Asterveil",                -- folder ng configs / cache
	ConfigName = "Default",
	ToggleKey = Enum.KeyCode.RightShift, -- show/hide
	-- Size = UDim2.fromOffset(640, 420),
	-- Logo = "rbxassetid://0",
	-- Font = Enum.Font.BuilderSansMedium, FontBold = Enum.Font.BuilderSansBold,
	Tags = {                             -- badges sa topbar (string o table)
		{Text = "v1.0", Color = "Accent"},
		{Text = "Beta", Color = "Warning"},
	},
})
if not Window then return end

------------------------------------------------------------ TAB 1: Basic controls
local Main = Window:AddTab({Title = "Main", Icon = "home"})

-- SECTION (lahat ng AddXxx ay pwede sa tab o section)
local Basic = Main:AddSection("Basic Controls")

-- Button
local btn = Basic:AddButton({
	Title = "Notify Me",
	Description = "Pindutin para magpakita ng notification",
	Icon = "bell",
	Callback = function()
		Library:Notify({Title = "Hello", Content = "Gumagana ang button!", Type = "success", Duration = 3})
	end,
})
-- btn:Click(); btn:SetCallback(fn); btn:SetTitle("..."); btn:SetDescription("...")

-- Toggle
local tgl = Basic:AddToggle({
	Title = "Auto Farm",
	Description = "Naka-save sa config via Flag",
	Default = false,
	Flag = "AutoFarm",
	Tooltip = "Ito ay tooltip kapag naka-hover",
	Tags = {{Text = "NEW", Color = "Success"}},
	Callback = function(v) print("Auto Farm:", v) end,
})
-- tgl:Set(true); tgl:Get(); tgl:Toggle()

-- Checkbox
Basic:AddCheckbox({Title = "Show ESP", Default = true, Flag = "ShowESP", Callback = function(v) print("ESP:", v) end})

-- Slider
local sld = Basic:AddSlider({
	Title = "Walk Speed",
	Min = 16, Max = 200, Default = 16, Increment = 1, Suffix = " st/s",
	Flag = "WalkSpeed",
	Callback = function(v)
		local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = v end
	end,
})
-- sld:Set(50); sld:Get(); sld:SetRange(0, 300)

-- Dropdown (single)
local dd = Basic:AddDropdown({
	Title = "Target Part",
	Options = {"Head", "Torso", "HumanoidRootPart"},
	Default = "Head",
	Flag = "TargetPart",
	Callback = function(v) print("Target:", v) end,
})
-- dd:Set("Torso"); dd:Get(); dd:SetOptions({...}); dd:Clear(); dd:Close()

-- Dropdown (multi)
Basic:AddDropdown({
	Title = "Teams",
	Options = {"Red", "Blue", "Green", "Yellow"},
	Multi = true,
	Default = {"Red"},
	Flag = "Teams",
	Callback = function(list) print("Teams:", table.concat(list or {}, ", ")) end,
})

-- Textbox
Basic:AddTextbox({
	Title = "Player Name",
	Placeholder = "Mag-type ng pangalan...",
	Default = "",
	Numeric = false,
	ClearOnFocus = false,
	Flag = "PlayerName",
	Callback = function(text) print("Name:", text) end,
	OnFocus = function() end,
	OnBlur = function(text) end,
})

-- Keybind (Mode: "Press" o "Hold")
Basic:AddKeybind({
	Title = "Fly Key",
	Default = Enum.KeyCode.F,
	Mode = "Press",
	Flag = "FlyKey",
	Callback = function() Library:Notify({Content = "Fly key pressed", Duration = 1.5}) end,
	OnChanged = function(key) print("Bound:", key and key.Name or "None") end,
})

-- Color Picker
Basic:AddColorPicker({
	Title = "ESP Color",
	Default = Color3.fromRGB(220, 224, 232),
	Flag = "ESPColor",
	Callback = function(c) print("Color:", c) end,
})

------------------------------------------------------------ Display elements
local Display = Main:AddSection("Display Elements")
Display:AddLabel("Simpleng label")
Display:AddLabel("Label na may option", {Size = 14, Color = "SubText"})
Display:AddRichText({Text = "<b>Rich</b> <font color=\"#d0d4dc\">Text</font> supported", Size = 13})
Display:AddParagraph({Title = "Paragraph", Content = "Mahabang paliwanag na awtomatikong nagwa-wrap sa maraming linya."})
Display:AddSeparator("Separator")
Display:AddDivider()
Display:AddCopyField({Title = "Discord", Text = "https://discord.gg/Xd6Xay6VsW"})
local prog = Display:AddProgressBar({Title = "Progress", Description = "Loading...", Value = 40, Max = 100})
local cprog = Display:AddCircularProgress({Value = 65, Max = 100})
-- prog:Set(80); cprog:Set(90)
Display:AddGameCard() -- game info card

------------------------------------------------------------ TAB 2: Layouts
local Layout = Window:AddTab({Title = "Layouts", Icon = "layout-grid"})

-- Subtabs
local subs = Layout:AddSubtabs({"General", "Combat", "Visuals"}, {
	Callback = function(i) print("Subtab:", i) end,
})
subs["General"]:AddToggle({Title = "Option sa General", Flag = "GenOpt"})
subs["Combat"]:AddSlider({Title = "Aim FOV", Min = 10, Max = 360, Default = 90, Flag = "AimFOV"})
subs[3]:AddCheckbox({Title = "Chams", Flag = "Chams"}) -- pwede ring index
-- subs:Select("Combat"); subs:Next(); subs:Back()

-- Collapsible / Accordion
local col = Layout:AddCollapsible({Title = "Advanced Settings", Open = false})
col:AddToggle({Title = "Debug Mode", Flag = "Debug"})
col:AddSlider({Title = "Tick Rate", Min = 1, Max = 60, Default = 30, Flag = "Tick"})

-- Subsection
local sub = Layout:AddSection("Sections"):AddSubsection("Subsection")
sub:AddLabel("Nasa loob ng subsection")

-- Grid (2 columns)
local grid = Layout:AddGrid({Columns = 2, CellHeight = 40})
grid:AddButton({Title = "One", Callback = function() Library:Notify("One") end})
grid:AddButton({Title = "Two", Callback = function() Library:Notify("Two") end})
grid:AddButton({Title = "Three", Callback = function() Library:Notify("Three") end})
grid:AddButton({Title = "Four", Callback = function() Library:Notify("Four") end})

-- Page selector
Layout:AddPageSelector({Pages = 5, Default = 1, Callback = function(p) print("Page", p) end})

-- Search bar
Layout:AddSearchBar({Placeholder = "Hanapin..."})

-- Locked section
local locked = Layout:AddSection({Title = "Premium", Locked = true, LockReason = "Premium only", Tags = {{Text = "VIP", Color = "Warning"}}})
locked:AddToggle({Title = "Premium Feature"})
-- locked:Unlock(); locked:Lock("reason")

-- Viewport (3D preview) at Video
-- Layout:AddViewport({Height = 140, Object = workspace.SomeModel})
-- Layout:AddVideo({Video = "rbxassetid://0", Height = 140, Looped = true, Volume = 0})

------------------------------------------------------------ TAB 3: Popups / Utilities
local Util = Window:AddTab({Title = "Popups", Icon = "message-square"})
local pop = Util:AddSection("Notifications")
for _, kind in ipairs({"info", "success", "warning", "error"}) do
	pop:AddButton({Title = "Notify: " .. kind, Callback = function()
		Library:Notify({Title = kind:upper(), Content = "Halimbawa ng " .. kind .. " notification", Type = kind, Duration = 4})
	end})
end

local dlg = Util:AddSection("Dialogs & Menus")
dlg:AddButton({Title = "Confirm Dialog", Callback = function()
	Library:Confirm("Sigurado ka?", "Ito ay halimbawa ng confirm dialog.",
		function() Library:Notify({Content = "Confirmed", Type = "success"}) end,
		function() Library:Notify({Content = "Cancelled", Type = "warning"}) end)
end})
dlg:AddButton({Title = "Custom Dialog", Callback = function()
	Library:Dialog({
		Title = "Custom",
		Content = "May sarili kang mga button dito.",
		Buttons = {
			{Title = "Close"},
			{Title = "Okay", Primary = true, Callback = function() print("OK") end},
		},
	})
end})
dlg:AddButton({Title = "Context Menu", Callback = function()
	Library:ContextMenu({
		{Title = "Copy", Icon = "copy", Callback = function() print("copy") end},
		{Title = "Delete", Icon = "trash", Callback = function() print("delete") end},
	})
end})
-- Right-click / long-press menu sa kahit anong row:
dlg:AddButton({Title = "Row na may Context Menu (right-click)", ContextMenu = {
	{Title = "Action A", Callback = function() print("A") end},
	{Title = "Action B", Callback = function() print("B") end},
}})

------------------------------------------------------------ Command palette
Library:AddCommand("Say Hello", function() Library:Notify("Hello from palette!") end, "Custom")
-- Ctrl/Cmd + K para buksan ang palette

------------------------------------------------------------ Config / Theme / Window APIs
local api = Util:AddSection("Library API")
api:AddButton({Title = "Save Config", Callback = function() Library:SaveConfig("Default") end})
api:AddButton({Title = "Load Config", Callback = function() Library:LoadConfig("Default") end})
api:AddButton({Title = "Theme: Space Universe", Callback = function() Library:SetTheme("Space Universe") end})
api:AddButton({Title = "Theme: Moonlight", Callback = function() Library:SetTheme("Moonlight") end})
api:AddButton({Title = "Custom Accent", Callback = function() Library:SetTheme({Accent = Color3.fromRGB(255, 255, 255)}) end})
api:AddButton({Title = "Language: Tagalog", Callback = function() Library:SetLanguage("Tagalog") end})
api:AddButton({Title = "Language: English", Callback = function() Library:SetLanguage("English") end})
api:AddButton({Title = "Window Transparency 30%", Callback = function() Window:SetTransparency(0.3) end})
api:AddButton({Title = "Rename Window", Callback = function() Window:SetTitle("Asterveil Hub") end})
api:AddButton({Title = "Unload UI", Callback = function() Library:Unload() end})

------------------------------------------------------------ Reading values / flags
-- Library.Flags.AutoFarm  --> ang element object; gamitin ang :Get() para sa value
task.spawn(function()
	while task.wait(1) do
		if Library.Unloaded then break end
		if Library.Flags.AutoFarm and Library.Flags.AutoFarm:Get() then
			-- gawin dito ang auto farm
		end
	end
end)

Library:Notify({Title = "Asterveil", Content = "Loaded sa " .. tostring(Library.Device) .. ". Pindutin ang RightShift para i-toggle.", Type = "success", Duration = 5})
