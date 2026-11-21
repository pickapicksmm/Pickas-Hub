--[[
	Asterveil UI | FULL EXAMPLES (every component & element)
	Run this in your executor:
	loadstring(game:HttpGet("https://raw.githubusercontent.com/pickapicksmm/Asterveil-Hub/refs/heads/main/Library/Source/Examples.lua"))()
]]

local URL = "https://raw.githubusercontent.com/pickapicksmm/Pickas-Hub/refs/heads/main/AsterveilUI%20(4).lua"

local ok, Library = pcall(function() return loadstring(game:HttpGet(URL))() end)
if not ok or type(Library) ~= "table" then
	warn("[Asterveil] Failed to load library: " .. tostring(Library))
	return
end

local Window = Library:CreateWindow({
	Title = "Asterveil Hub",
	ToggleKey = Enum.KeyCode.RightShift,
	Tags = {{Text = "v1.0", Color = "Success"}}, -- extra tags beside the title (game + device tags are automatic)
	-- Logo = getcustomasset("MyLogo.png"),      -- optional custom logo (PNG/JPG, GIF is not supported by Roblox)
})
if not Window then return end -- error was printed with warn()

------------------------------------------------------------------ TAB 1: BASIC
local Basic = Window:CreateTab({Title = "Basic", Icon = "mouse-pointer-click", Tag = {Text = "NEW", Color = "Success"}})

local Btns = Basic:AddSection("Buttons & Toggles")

Btns:AddButton({
	Title = "Button", Description = "Click me", Icon = "zap",
	Tooltip = "This is a tooltip (hover the button)",
	ContextMenu = { -- right click (PC) or hold (mobile)
		{Title = "Copy", Icon = "copy", Callback = function() Library:Notify({Title = "Context", Content = "Copy clicked"}) end},
		{Title = "Delete", Icon = "trash-2", Callback = function() Library:Notify({Title = "Context", Content = "Delete clicked", Type = "warning"}) end},
	},
	Callback = function() Library:Notify({Title = "Button", Content = "Clicked!", Type = "success"}) end,
})

local tog = Btns:AddToggle({Title = "Toggle", Description = "On / Off", Default = false, Flag = "Demo.Toggle",
	Callback = function(v) print("Toggle:", v) end})

Btns:AddCheckbox({Title = "Checkbox", Default = true, Flag = "Demo.Checkbox", Callback = function(v) print("Checkbox:", v) end})

Btns:AddButton({Title = "Toggle the toggle (SetValue)", Callback = function() tog:Set(not tog:Get()) end})

local Inputs = Basic:AddSection("Inputs")

Inputs:AddSlider({Title = "Slider", Min = 0, Max = 100, Default = 50, Suffix = "%", Flag = "Demo.Slider",
	Callback = function(v) print("Slider:", v) end})
Inputs:AddSlider({Title = "Decimal Slider", Min = 0, Max = 5, Increment = 0.1, Default = 1.5, Flag = "Demo.Decimal"})

Inputs:AddDropdown({Title = "Dropdown", Options = {"Nearest", "Boss", "Elite"}, Default = "Nearest", Flag = "Demo.Dropdown",
	Callback = function(v) print("Dropdown:", v) end})
Inputs:AddDropdown({Title = "Multi Dropdown", Options = {"Sword", "Bow", "Staff", "Shield"}, Multi = true, Default = {"Sword"}, Flag = "Demo.Multi",
	Callback = function(list) print("Multi:", table.concat(list, ", ")) end})
Inputs:AddDropdown({Title = "Searchable Dropdown", Options = {"Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliet"}, Flag = "Demo.Search"})

Inputs:AddTextbox({Title = "Textbox", Placeholder = "type here...", Flag = "Demo.Text",
	Callback = function(text, enter) print("Text:", text, enter) end})
Inputs:AddInput({Title = "Numeric Input", Placeholder = "numbers only", Numeric = true, Flag = "Demo.Number"})

Inputs:AddKeybind({Title = "Keybind (Press)", Default = Enum.KeyCode.F, Flag = "Demo.Key",
	Callback = function() Library:Notify({Title = "Keybind", Content = "F pressed"}) end})
Inputs:AddKeybind({Title = "Keybind (Hold)", Default = Enum.KeyCode.G, Mode = "Hold", Flag = "Demo.KeyHold",
	Callback = function(down) print("Hold:", down) end})

Inputs:AddColorPicker({Title = "Color Picker", Default = Color3.fromRGB(139, 92, 246), Flag = "Demo.Color",
	Callback = function(c) print("Color:", c) end})

local Texts = Basic:AddSection("Text Elements")
Texts:AddLabel("This is a Label")
Texts:AddParagraph({Title = "Paragraph", Content = "Paragraphs wrap automatically and can hold longer text with a title."})
Texts:AddRichText({Text = "<b>Rich</b> <i>Text</i> with <font color=\"#a78bfa\">colors</font>!"})
Texts:AddDivider()
Texts:AddSeparator("Separator")
Texts:AddCopyField({Title = "Copy", Text = "https://discord.gg/Xd6Xay6VsW"})
Texts:AddSearchBar({Placeholder = "Filter this section..."})

------------------------------------------------------------------ TAB 2: ADVANCED
local Adv = Window:CreateTab({Title = "Advanced", Icon = "layers"})

local Prog = Adv:AddSection("Progress")
local bar = Prog:AddProgressBar({Title = "Progress Bar", Value = 30})
local circ = Prog:AddCircularProgress({Title = "Circular Progress", Value = 60})
Prog:AddSlider({Title = "Drive both", Min = 0, Max = 100, Default = 40, Callback = function(v) bar:Set(v); circ:Set(v) end})

local Nav = Adv:AddSection("Subtabs & Pages")
local subs = Nav:AddSubtabs({"General", "Visuals", "Misc"}, {Callback = function(name) print("Subtab:", name) end})
subs["General"]:AddLabel("General subtab content")
subs["General"]:AddToggle({Title = "General Toggle"})
subs["Visuals"]:AddToggle({Title = "ESP"})
subs["Visuals"]:AddColorPicker({Title = "ESP Color", Default = Color3.fromRGB(255, 80, 80)})
subs["Misc"]:AddButton({Title = "Misc Button"})
Nav:AddPageSelector({Pages = 5, Default = 1, Callback = function(p) print("Page:", p) end})

local Cont = Adv:AddSection("Containers")
local acc1 = Cont:AddCollapsible({Title = "Accordion 1", Group = "acc", Open = true})
acc1:AddToggle({Title = "Inside Accordion 1"})
local acc2 = Cont:AddCollapsible({Title = "Accordion 2", Group = "acc"})
acc2:AddSlider({Title = "Inside Accordion 2", Min = 0, Max = 10, Default = 5})
local sub = Cont:AddSubsection("Subsection")
sub:AddButton({Title = "Button in Subsection"})
local grid = Cont:AddGrid({Columns = 2})
grid:AddButton({Title = "Grid 1"})
grid:AddButton({Title = "Grid 2"})
grid:AddButton({Title = "Grid 3"})
grid:AddButton({Title = "Grid 4"})

local View = Adv:AddSection("Viewport")
View:AddViewport({Height = 150}) -- spinning planet (ViewportFrame)
-- View:AddVideo({Video = "rbxassetid://0", Height = 140, Looped = true}) -- VideoFrame

local Pop = Adv:AddSection("Popups & Notifications")
Pop:AddButton({Title = "Notify: Info", Callback = function() Library:Notify({Title = "Info", Content = "Information message", Type = "info"}) end})
Pop:AddButton({Title = "Notify: Success", Callback = function() Library:Notify({Title = "Success", Content = "It worked!", Type = "success"}) end})
Pop:AddButton({Title = "Notify: Warning", Callback = function() Library:Notify({Title = "Warning", Content = "Be careful", Type = "warning"}) end})
Pop:AddButton({Title = "Notify: Error", Callback = function() Library:Notify({Title = "Error", Content = "Something failed", Type = "error"}) end})
Pop:AddButton({Title = "Dialog", Callback = function()
	Library:Dialog({Title = "Dialog", Content = "This is a modal dialog.", Buttons = {{Title = "Close"}, {Title = "OK", Primary = true, Callback = function() print("OK") end}}})
end})
Pop:AddButton({Title = "Confirm Dialog", Callback = function()
	Library:Confirm("Are you sure?", "This action needs confirmation.", function() print("Yes") end, function() print("No") end)
end})
Pop:AddButton({Title = "Command Palette (or Ctrl + K)", Callback = function() Library:OpenPalette() end})
Pop:AddButton({Title = "Context Menu at cursor", Callback = function()
	Library:ContextMenu({{Title = "Option A", Icon = "star"}, {Title = "Option B", Icon = "heart"}})
end})

------------------------------------------------------------------ TAB 3: LOCKS & TAGS
local Lt = Window:CreateTab({Title = "Locks & Tags", Icon = "lock", Tag = {Text = "HOT", Color = "Error"}})

local Tags = Lt:AddSection({Title = "Tags", Tag = {Text = "BETA", Color = "Warning"}})
Tags:AddToggle({Title = "Tag: NEW", Tag = {Text = "NEW", Color = "Success"}})
Tags:AddToggle({Title = "Tag: HOT", Tag = {Text = "HOT", Color = "Error"}})
Tags:AddToggle({Title = "Tag with icon", Tag = {Text = "PRO", Color = "Accent3", Icon = "crown"}})
Tags:AddToggle({Title = "Multiple tags", Tags = {{Text = "v2", Color = "Accent2"}, {Text = "FAST", Color = "Success"}}})
Tags:AddButton({Title = "Custom color tag", Tag = {Text = "CUSTOM", Color = Color3.fromRGB(255, 170, 0)}})

local Locks = Lt:AddSection("Locks")
Locks:AddButton({Title = "Locked Button", Locked = true, LockReason = "Level 50 required"})
Locks:AddToggle({Title = "Locked Toggle", Locked = true, LockReason = "Premium only", Tag = {Text = "VIP", Color = "Accent3"}})
local vip = Locks:AddSlider({Title = "Runtime lock/unlock", Min = 0, Max = 100, Default = 10})
vip:Lock("Locked at runtime")
Locks:AddToggle({Title = "Unlock the slider above", Callback = function(v) if v then vip:Unlock() else vip:Lock("Locked at runtime") end end})

local lockSec = Lt:AddSection({Title = "Lock a whole section", Tag = "DEMO"})
lockSec:AddToggle({Title = "Inside the section"})
lockSec:AddSlider({Title = "Also inside", Min = 0, Max = 10, Default = 3})
Lt:AddSection("Controls"):AddToggle({Title = "Lock the section above", Callback = function(v)
	if v then lockSec:Lock("Section locked") else lockSec:Unlock() end
end})

local lsub = Lt:AddSubtabs({"Open", "Locked"})
lsub["Open"]:AddLabel("This subtab is open.")
lsub["Locked"]:AddLabel("Hidden content")
lsub["Locked"]:Lock("Coming soon")

------------------------------------------------------------------ TAB 4: SYSTEM
local Sys = Window:CreateTab({Title = "System", Icon = "cpu"})

local Th = Sys:AddSection("Theme & Language")
local themeNames = {}
for name in pairs(Library.Themes) do themeNames[#themeNames + 1] = name end
table.sort(themeNames)
Th:AddDropdown({Title = "Set Theme (API)", Options = themeNames, Default = "Space", NoSave = true, Callback = function(v) Library:SetTheme(v) end})
Th:AddDropdown({Title = "Set Language (API)", Options = Library.Languages, Default = "English", NoSave = true, Translate = false, Callback = function(v) Library:SetLanguage(v) end})

local Wn = Sys:AddSection("Window API")
Wn:AddSlider({Title = "SetTransparency", Min = 0, Max = 90, Default = 6, Suffix = "%", NoSave = true, Callback = function(v) Window:SetTransparency(v / 100) end})
Wn:AddSlider({Title = "SetCorner", Min = 0, Max = 24, Default = 14, NoSave = true, Callback = function(v) Window:SetCorner(v) end})
Wn:AddButton({Title = "Hide window (press RightShift or tap the logo)", Callback = function() Window:SetVisible(false) end})
Wn:AddButton({Title = "SetTitle", Callback = function() Window:SetTitle("Asterveil Hub " .. math.random(1, 99)) end})

local Cf = Sys:AddSection("Config API")
Cf:AddButton({Title = "SaveConfig('Example')", Icon = "save", Callback = function() Library:SaveConfig("Example") end})
Cf:AddButton({Title = "LoadConfig('Example')", Icon = "download", Callback = function() Library:LoadConfig("Example") end})
Cf:AddButton({Title = "ResetConfig()", Icon = "rotate-ccw", Callback = function() Library:ResetConfig() end})
Cf:AddButton({Title = "Log to Console (Settings > Console)", Callback = function()
	Library:Log("Hello from the example!", "info")
	Library:Log("Success log", "success")
	Library:Log("Warning log", "warn")
	Library:Log("Error log", "error")
end})

------------------------------------------------------------------ TAB 5: TRANSLATION
local Tr = Window:CreateTab({Title = "Translation", Icon = "languages"})

local Sw = Tr:AddSection("Switch language")
for _, name in ipairs({"English", "Mandarin Chinese", "Japanese", "Korean", "Spanish", "Tagalog", "Indonesian", "Arabic", "Russian"}) do
	Sw:AddButton({Title = name, Translate = false, Callback = function() Library:SetLanguage(name) end})
end
Sw:AddDropdown({Title = "All 20 languages", Options = Library.Languages, Default = "English", Translate = false, NoSave = true,
	Callback = function(v) Library:SetLanguage(v) end})

local Dm = Tr:AddSection("Everything translates automatically")
Dm:AddLabel("This label is translated automatically.")
Dm:AddParagraph({Title = "Paragraph title", Content = "Paragraph content is translated too."})
Dm:AddToggle({Title = "Toggle title", Description = "Descriptions are translated as well"})
Dm:AddDropdown({Title = "Dropdown", Options = {"Apple", "Banana", "Cherry"}, Default = "Apple"})
Dm:AddToggle({Title = "Not translated (Translate = false)", Translate = false})
Dm:AddButton({Title = "Notify (notifications translate too)", Callback = function()
	Library:Notify({Title = "Hello", Content = "This notification follows the selected language.", Type = "info"})
end})
local n = 0
Dm:AddButton({Title = "Add a new element at runtime", Callback = function()
	n = n + 1
	Dm:AddToggle({Title = "New element " .. n, Description = "Added at runtime, translated automatically"})
end})
Dm:AddButton({Title = "Print Library.Translate('Settings')", Callback = function()
	print(Library.Translate("Settings") or "(English / not translated yet)")
end})

------------------------------------------------------------------ TAB 6: LOCKED TAB
local Premium = Window:CreateTab({Title = "Premium", Icon = "crown", Tag = "VIP", Locked = true, LockReason = "Premium members only"})
Premium:AddLabel("Premium content")
-- Premium:Unlock()

Library:Notify({Title = "Asterveil", Content = "All components loaded. Tap the gear icon for Info, Console, Configure and Settings.", Type = "success", Duration = 6})
Window:LoadAutoConfig() -- call last so a saved config can apply
