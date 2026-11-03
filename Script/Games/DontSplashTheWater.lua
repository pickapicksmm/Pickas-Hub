--[[
    PICKA'S HUB
    Game: Don't Splash the Water
    UI: PHLibrary 3.0.0
]]

--// LOAD PH LIBRARY
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/pickapicksmm/Pickas-Hub/refs/heads/main/Libray.src/PHLibrary.lua"
))()

Library:SetAccent(Color3.fromRGB(157, 0, 255))

--// SERVICES
local Players = game:GetSe1rvice("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

--// CONFIGURATION
local Config = {
    PlayerESP = false,
    MonsterESP = false,
    SafeESP = false,
    CodeESP = false
}

--// WINDOW
local Window = Library:CreateWindow({
    Title = "PICKA'S HUB",
    Game = "Don't Splash the Water",
    Tag = "v1.0.0"
})

--// MAIN TAB STRUCTURE
local Visual = Window:AddTab({
    Title = "Visual",
    Icon = "eye"
})

--// VISUAL SUBTABS (order: ESP | Setting)
local ESP = Visual:AddSubTab({
    Title = "ESP"
})

local Setting = Visual:AddSubTab({
    Title = "Setting"
})

--// ESP CONFIGURATION
local ESPConfig = {
    Player = {
        Color = Color3.fromRGB(0, 255, 0),
        Name = "PLAYER"
    },

    Monster = {
        Color = Color3.fromRGB(255, 0, 0),
        Name = "MONSTER"
    },

    Safe = {
        Color = Color3.fromRGB(255, 255, 0),
        Name = "SAFE PATH"
    },

    Code = {
        Color = Color3.fromRGB(180, 0, 255),
        Name = "CODE SNAP"
    }
}

local Visuals = {}

--// MAIN FUNCTIONS
local function GetCategory(obj)
    if not obj or not obj.Parent then
        return nil
    end

    local name = string.lower(obj.Name)

    if obj.Name == "Monster"
    or obj.Name == "BlindMonster"
    or obj:FindFirstChild("ListenerTorso")
    or string.find(name, "monster") then
        return "Monster"
    end

    if obj:IsA("Model") then
        local player = Players:GetPlayerFromCharacter(obj)

        if player and player ~= LP then
            return "Player"
        end
    end

    if string.find(name, "code")
    or string.find(name, "snap")
    or obj.Name == "CodeSign" then
        return "Code"
    end

    if string.find(name, "path")
    or string.find(name, "safe")
    or string.find(name, "platform")
    or obj.Name == "SafePlatform" then
        return "Safe"
    end

    return nil
end

local function IsEnabled(category)
    if category == "Player" then
        return Config.PlayerESP
    elseif category == "Monster" then
        return Config.MonsterESP
    elseif category == "Safe" then
        return Config.SafeESP
    elseif category == "Code" then
        return Config.CodeESP
    end

    return false
end

local function RemoveVisual(obj)
    local data = Visuals[obj]

    if data then
        if data.Highlight then
            data.Highlight:Destroy()
        end

        if data.Billboard then
            data.Billboard:Destroy()
        end

        Visuals[obj] = nil
    end
end

local function CreateVisuals(obj, category)
    if not obj or not obj.Parent then
        return
    end

    if Visuals[obj] then
        return
    end

    local cfg = ESPConfig[category]

    if not cfg then
        return
    end

    local part = obj:FindFirstChild("ListenerTorso")
        or obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChildWhichIsA("BasePart")
        or (obj:IsA("BasePart") and obj)

    if not part then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "Game_ESP_Highlight"
    highlight.FillColor = cfg.Color
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.Adornee = obj
    highlight.Parent = obj

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Game_ESP_Billboard"
    billboard.Size = UDim2.fromOffset(160, 40)
    billboard.AlwaysOnTop = true
    billboard.ExtentsOffset = Vector3.new(0, 4, 0)
    billboard.Adornee = part
    billboard.Parent = obj

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = cfg.Color
    label.TextSize = 13
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = billboard

    Visuals[obj] = {
        Highlight = highlight,
        Billboard = billboard,
        Label = label,
        Part = part,
        Category = category
    }
end

--// ESP SCANNER
local function CheckInstance(obj)
    local category = GetCategory(obj)

    if category and IsEnabled(category) then
        CreateVisuals(obj, category)
    end
end

local function RefreshESP()
    for obj, data in pairs(Visuals) do
        if not IsEnabled(data.Category) then
            RemoveVisual(obj)
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        CheckInstance(obj)
    end
end

workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        CheckInstance(obj)
    end)
end)

--// ESP UPDATE
RunService.RenderStepped:Connect(function()
    local character = LP.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    for obj, data in pairs(Visuals) do
        if not obj.Parent or not data.Part.Parent then
            RemoveVisual(obj)
        elseif root then
            local distance = (
                root.Position - data.Part.Position
            ).Magnitude

            data.Label.Text = string.format(
                "%s [%d Studs]",
                ESPConfig[data.Category].Name,
                math.floor(distance)
            )
        end
    end
end)

--// VISUAL > ESP
ESP:AddToggle({
    Title = "Player ESP",
    Default = Config.PlayerESP,
    Callback = function(value)
        Config.PlayerESP = value
        RefreshESP()
    end
})

ESP:AddToggle({
    Title = "Monster ESP",
    Default = Config.MonsterESP,
    Callback = function(value)
        Config.MonsterESP = value
        RefreshESP()
    end
})

ESP:AddToggle({
    Title = "Safe Path ESP",
    Default = Config.SafeESP,
    Callback = function(value)
        Config.SafeESP = value
        RefreshESP()
    end
})

ESP:AddToggle({
    Title = "Code Snap ESP",
    Default = Config.CodeESP,
    Callback = function(value)
        Config.CodeESP = value
        RefreshESP()
    end
})

--// VISUAL > SETTING
Setting:AddParagraph({
    Title = "PICKA'S HUB",
    Content = "Welcome to Picka's Hub. Don't Splash the Water game interface."
})

Setting:AddLabel({
    Title = "Engine Status: Loaded",
    Color = Color3.fromRGB(80, 220, 140)
})

Setting:AddButton({
    Title = "Refresh ESP",
    ButtonText = "Refresh",
    Icon = "refresh-cw",
    Callback = function()
        RefreshESP()
    end
})

Setting:AddButton({
    Title = "Clear ESP",
    ButtonText = "Clear",
    Icon = "trash",
    Callback = function()
        for obj in pairs(Visuals) do
            RemoveVisual(obj)
        end
    end
})

--// INITIAL SCAN
RefreshESP()

print("[PICKA'S HUB] Don't Splash the Water loaded successfully.")
