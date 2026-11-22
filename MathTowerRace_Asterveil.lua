-- MATH TOWER RACE | ASTERVEIL UI
-- Uses the official Asterveil Library Lock API for the locked Premium tab.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SubmitAnswerRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SubmitAnswerRemote")
local RoundControl = ReplicatedStorage:FindFirstChild("RoundControlFolder")
local TopicControl = RoundControl and RoundControl:FindFirstChild("TopicControl")
local AnswerControl = RoundControl and RoundControl:FindFirstChild("AnswerControl")

local ASTERVEIL_URL = "https://raw.githubusercontent.com/pickapicksmm/Asterveil-Hub/refs/heads/main/Library/Source/Asterveil-UiLibrary.lua"
local okLibrary, Library = pcall(function()
    return loadstring(game:HttpGet(ASTERVEIL_URL))()
end)

if not okLibrary or type(Library) ~= "table" then
    warn("[Math Tower Race] Could not load Asterveil UI Library: " .. tostring(Library))
    return
end

local autoSolve = true
local answerDelay = 1.5
local randomize = false
local notifications = true

local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(390, 844)
local winWidth = math.max(280, math.min(430, viewport.X - 24))
local winHeight = math.max(280, math.min(430, viewport.Y - 120))

local Window = Library:CreateWindow({
    Title = "Math Tower Race",
    Size = Vector2.new(winWidth, winHeight),
})
Window:SetTitle("Math Tower Race")
Window:SetOpenSize(42)
Window:AddTag({ Text = "MATH TOWER", Icon = "calculator" })
Window:SetGame("Math Tower Race")

local Main = Window:AddTab({ Title = "Main", Icon = "calculator" })
local Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })

-- Native Asterveil Lock API: locked placeholder tab; solver controls remain unlocked.
local Premium = Window:AddTab({
    Title = "System Mode",
    Icon = "lock",
    Locked = true,
    LockText = "LOCKED",
    LockTitle = "System Mode",
    LockMessage = "System Mode is locked.",
    LockIcon = "lock",
})

local function notify(message, kind)
    if not notifications then return end
    pcall(function()
        Library:Notify({
            Title = "Math Tower Race",
            Content = tostring(message),
            Type = kind or "Info",
            Icon = "calculator",
            Duration = 3,
        })
    end)
end

-- Helpers
local function normalize(expr)
	expr = expr:gsub("=%s*%?+", "")
	expr = expr:gsub("=%s*_", "")
	expr = expr:gsub("x", "*")
	expr = expr:gsub("×", "*")
	expr = expr:gsub("÷", "/")
	return expr
end

local function replacePlain(str, find, with)
	local s, e = str:find(find, 1, true)
	if not s then
		return str
	end
	return str:sub(1, s - 1) .. with .. str:sub(e + 1)
end

local function evaluate(expr)
	local ok, result = pcall(function()
		local chunk = loadstring("return " .. normalize(expr):gsub("%s", ""))
		if not chunk then
			return nil
		end
		local value = chunk()
		if type(value) ~= "number" then
			return nil
		end
		if value == math.floor(value) then
			return tostring(math.floor(value))
		end
		return tostring(value)
	end)
	return ok and result or nil
end

local function getAnswer(i)
	return AnswerControl and AnswerControl:FindFirstChild("Answer" .. i)
end

local function submit(answer)
	if not SubmitAnswerRemote or not answer or answer == "" then
		return nil
	end
	local ok, result = pcall(function()
		return SubmitAnswerRemote:InvokeServer(answer .. "  ", "Selection_Mouse")
	end)
	return ok and result or nil
end

-- Solver
local function findAnswer()
	local nameValue = TopicControl and TopicControl:FindFirstChild("TopicName")
	local typeValue = TopicControl and TopicControl:FindFirstChild("TopicType")
	local topic = nameValue and nameValue.Value or ""
	local topicType = typeValue and typeValue.Value or ""

	if topic == "" or not AnswerControl then
		return nil
	end

	-- Plain arithmetic: match the computed result against the options
	local computed = evaluate(topic)
	if computed then
		for i = 1, 4 do
			local a = getAnswer(i)
			if a and a.Value ~= "" and a.Value == computed then
				return computed
			end
		end
	end

	-- Odd or even
	if topicType == "odd_or_even" then
		local n = tonumber(topic:match("(%d+)"))
		if n then
			local want = n % 2 == 0 and "even" or "odd"
			for i = 1, 4 do
				local a = getAnswer(i)
				if a and a.Value:lower() == want then
					return a.Value
				end
			end
		end
	end

	-- Comparison: try each option in place of the ???
	if topicType == "simpleComparison" then
		for i = 1, 4 do
			local a = getAnswer(i)
			if a and a.Value ~= "" and tonumber(a.Value) ~= nil then
				local ok, result = pcall(function()
					local expr = replacePlain(normalize(topic), "???", a.Value)
					local chunk = loadstring("return " .. expr)
					return chunk and chunk()
				end)
				if ok and result == true then
					return a.Value
				end
			end
		end
	end

	-- Rounding
	if topicType == "rounding" then
		local n = tonumber(topic:match("([%d%.]+)"))
		if n then
			local places = topic:find("whole", 1, true) and 0
				or topic:find("tenth", 1, true) and 1
				or topic:find("hundredth", 1, true) and 2
				or topic:find("thousandth", 1, true) and 3
				or nil
			if places then
				local scale = 10 ^ places
				local rounded = math.floor(n * scale + 0.5) / scale
				for i = 1, 4 do
					local a = getAnswer(i)
					local v = a and a.Value ~= "" and tonumber(a.Value)
					if v and math.abs(v - rounded) < 0.0001 then
						return a.Value
					end
				end
			end
		end
	end

	-- Sequences
	if topicType == "seq_arithmetic" or topicType == "seq_geometric" then
		local nums = {}
		for num in topic:gmatch("(-?%d+%.?%d*)") do
			table.insert(nums, tonumber(num))
		end
		if #nums >= 2 then
			local nextValue
			if topicType == "seq_arithmetic" then
				nextValue = nums[#nums] + (nums[2] - nums[1])
			else
				local ratio = nums[1] == 0 and 0 or (nums[2] / nums[1])
				nextValue = nums[#nums] * ratio
			end
			local target = math.floor(nextValue + 0.5)
			for i = 1, 4 do
				local a = getAnswer(i)
				if a and tonumber(a.Value) == target then
					return a.Value
				end
			end
		end
	end

	return nil
end

local function fallbackAnswer()
	for i = 1, 4 do
		local a = getAnswer(i)
		if a and a.Value ~= "" then
			return a.Value
		end
	end
	return nil
end

local function report(result)
	if not result then
		notify("Failed to submit", "Error")
	elseif result.correct then
		notify("Correct! +" .. tostring(result.score or 0), "Success")
	elseif result.correctAnswer then
		notify("Wrong: " .. tostring(result.correctAnswer), "Warning")
	else
		notify("Wrong answer", "Warning")
	end
end

local function solve()
	if not autoSolve then
		return
	end

	notify("Solving...")
	local answer = findAnswer() or fallbackAnswer()
	if not answer then
		notify("Couldn't find answer", "Error")
		return
	end

	notify("Answer: " .. answer)

	local delay = answerDelay
	if randomize then
		delay = math.max(0.1, delay + (math.random() * 0.8 - 0.4))
	end
	task.wait(delay)

	if not autoSolve then
		return
	end

	notify("Submitting...")
	report(submit(answer))
end


Main:AddProfile({ Status = "Math Tower Race" })
Main:AddSection({ Title = "Auto Solver" })
Main:AddParagraph({
    Title = "Math Tower Race",
    Content = "Automatically solve the current question and submit the matching answer.",
})

Main:AddToggle({
    Title = "Auto Solve",
    Default = true,
    Flag = "AutoSolve",
    Callback = function(value)
        autoSolve = value
        notify(value and "Auto Solve enabled" or "Auto Solve disabled", value and "Success" or "Warning")
    end,
})

Main:AddButton({
    Title = "Solve Current Question",
    ButtonText = "Solve Now",
    Icon = "zap",
    Callback = function()
        local answer = findAnswer() or fallbackAnswer()
        if not answer then
            notify("No question or answer options found", "Error")
            return
        end
        notify("Answer: " .. tostring(answer))
        report(submit(answer))
    end,
})

Main:AddSection({ Title = "Answer Timing" })
Main:AddSlider({
    Title = "Answer Delay",
    Min = 0.1,
    Max = 5,
    Step = 0.1,
    Default = 1.5,
    Suffix = "s",
    Flag = "AnswerDelay",
    Tooltip = "Delay before submitting the answer",
    Callback = function(value)
        answerDelay = value
    end,
})

Main:AddToggle({
    Title = "Randomize Delay",
    Default = false,
    Flag = "RandomizeDelay",
    Callback = function(value)
        randomize = value
    end,
})

Settings:AddSection({ Title = "Notifications" })
Settings:AddToggle({
    Title = "Notifications",
    Default = true,
    Flag = "Notifications",
    Callback = function(value)
        notifications = value
    end,
})

Settings:AddParagraph({
    Title = "Recommended Settings",
    Content = "Suggested Answer Delay: 1.5 seconds. Randomize Delay is optional.",
})

Settings:AddButton({
    Title = "Check Current Question",
    ButtonText = "Check",
    Icon = "search",
    Callback = function()
        local topicName = TopicControl and TopicControl:FindFirstChild("TopicName")
        local topic = topicName and topicName.Value or ""
        local answer = findAnswer()
        notify(topic ~= "" and ("Question: " .. topic) or "No active question", topic ~= "" and "Info" or "Warning")
        if answer then notify("Detected answer: " .. tostring(answer), "Success") end
    end,
})

Library:Notify({
    Title = "Math Tower Race",
    Content = "Asterveil UI loaded. Auto Solve is ON.",
    Type = "Success",
    Icon = "check-circle",
    Duration = 5,
})

-- Trigger on each new question
if TopicControl then
	local topicName = TopicControl:FindFirstChild("TopicName")
	if topicName then
		topicName:GetPropertyChangedSignal("Value"):Connect(function()
			if topicName.Value ~= "" then
				solve()
			end
		end)
		if topicName.Value ~= "" then
			task.spawn(solve)
		end
	end
end
