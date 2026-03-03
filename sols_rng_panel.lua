--[[
Sols RNG Helper Panel (LocalScript)
Drop into StarterPlayerScripts or execute in a local environment.
Features:
1) Aura roll/stat tracking
2) Probability calculator for aura odds
3) Grind planner (ETA to target aura)
4) Loadout/progression strategy optimizer
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "SolsRNGHelperPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "MainPanel"
main.Size = UDim2.new(0, 520, 0, 430)
main.Position = UDim2.new(0, 24, 0, 60)
main.BackgroundColor3 = Color3.fromRGB(22, 25, 30)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(90, 100, 120)
stroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 34)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(240, 245, 255)
title.Text = "Sols RNG Helper Panel"
title.Parent = main

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 20)
subtitle.Position = UDim2.new(0, 10, 0, 40)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextColor3 = Color3.fromRGB(170, 175, 185)
subtitle.Text = "Track rolls • Calculate odds • Plan grind • Optimize strategy"
subtitle.Parent = main

local function makeSection(y, h, name)
	local section = Instance.new("Frame")
	section.Size = UDim2.new(1, -20, 0, h)
	section.Position = UDim2.new(0, 10, 0, y)
	section.BackgroundColor3 = Color3.fromRGB(31, 35, 42)
	section.BorderSizePixel = 0
	section.Parent = main

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = section

	local s = Instance.new("TextLabel")
	s.Size = UDim2.new(1, -16, 0, 18)
	s.Position = UDim2.new(0, 8, 0, 6)
	s.BackgroundTransparency = 1
	s.Font = Enum.Font.GothamBold
	s.TextSize = 13
	s.TextXAlignment = Enum.TextXAlignment.Left
	s.TextColor3 = Color3.fromRGB(215, 225, 255)
	s.Text = name
	s.Parent = section

	return section
end

local function makeInput(parent, x, y, w, placeholder)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, w, 0, 28)
	box.Position = UDim2.new(0, x, 0, y)
	box.BackgroundColor3 = Color3.fromRGB(42, 48, 58)
	box.TextColor3 = Color3.fromRGB(238, 240, 245)
	box.PlaceholderColor3 = Color3.fromRGB(140, 145, 155)
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.PlaceholderText = placeholder
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Parent = parent

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = box

	return box
end

local function makeButton(parent, x, y, w, text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, w, 0, 28)
	button.Position = UDim2.new(0, x, 0, y)
	button.BackgroundColor3 = Color3.fromRGB(85, 115, 245)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = parent

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = button

	return button
end

local function makeLabel(parent, x, y, w, h, text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, w, 0, h)
	lbl.Position = UDim2.new(0, x, 0, y)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Gotham
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.TextSize = 12
	lbl.TextColor3 = Color3.fromRGB(225, 229, 238)
	lbl.TextWrapped = true
	lbl.Text = text
	lbl.Parent = parent
	return lbl
end

local trackerSection = makeSection(68, 98, "1) Aura Roll Tracker")
local calcSection = makeSection(172, 78, "2) Probability Calculator")
local grindSection = makeSection(256, 78, "3) Grind Planner")
local optimizeSection = makeSection(340, 82, "4) Loadout Optimizer")

-- 1) Tracker
local auraNameInput = makeInput(trackerSection, 8, 28, 150, "Aura name (e.g. Ethereal)")
local auraOddsInput = makeInput(trackerSection, 166, 28, 100, "1 in N")
local addRollButton = makeButton(trackerSection, 274, 28, 90, "Log Roll")
local resetStatsButton = makeButton(trackerSection, 370, 28, 90, "Reset")
resetStatsButton.BackgroundColor3 = Color3.fromRGB(160, 70, 70)

local trackerStats = makeLabel(
	trackerSection,
	8,
	60,
	500,
	32,
	"Rolls: 0 | Best Aura: N/A | Avg rarity (1 in N): 0"
)

local state = {
	totalRolls = 0,
	bestAuraName = "N/A",
	bestAuraOdds = 0,
	totalOdds = 0,
	auraCounts = {}
}

local function refreshTrackerText()
	local avg = state.totalRolls > 0 and (state.totalOdds / state.totalRolls) or 0
	trackerStats.Text = string.format(
		"Rolls: %d | Best Aura: %s (1 in %s) | Avg rarity (1 in N): %.2f",
		state.totalRolls,
		state.bestAuraName,
		state.bestAuraOdds > 0 and tostring(state.bestAuraOdds) or "N/A",
		avg
	)
end

local function logAuraRoll(auraName, oddsN)
	state.totalRolls += 1
	state.totalOdds += oddsN
	state.auraCounts[auraName] = (state.auraCounts[auraName] or 0) + 1

	if oddsN > state.bestAuraOdds then
		state.bestAuraOdds = oddsN
		state.bestAuraName = auraName
	end

	refreshTrackerText()
end

addRollButton.MouseButton1Click:Connect(function()
	local auraName = auraNameInput.Text ~= "" and auraNameInput.Text or "Unknown"
	local oddsN = tonumber(auraOddsInput.Text)
	if not oddsN or oddsN <= 0 then
		trackerStats.Text = "Enter a valid positive number for odds (N in 1/N)."
		return
	end
	logAuraRoll(auraName, oddsN)
end)

resetStatsButton.MouseButton1Click:Connect(function()
	state.totalRolls = 0
	state.bestAuraName = "N/A"
	state.bestAuraOdds = 0
	state.totalOdds = 0
	state.auraCounts = {}
	refreshTrackerText()
end)

-- 2) Probability calculator
local calcOddsInput = makeInput(calcSection, 8, 28, 120, "Aura odds N")
local calcAttemptsInput = makeInput(calcSection, 136, 28, 120, "Attempts")
local calcButton = makeButton(calcSection, 264, 28, 90, "Calculate")
local calcOutput = makeLabel(calcSection, 8, 58, 500, 16, "Chance result will appear here.")

calcButton.MouseButton1Click:Connect(function()
	local oddsN = tonumber(calcOddsInput.Text)
	local attempts = tonumber(calcAttemptsInput.Text)

	if not oddsN or oddsN <= 0 or not attempts or attempts <= 0 then
		calcOutput.Text = "Enter valid positive numbers for odds and attempts."
		return
	end

	local singleChance = 1 / oddsN
	local atLeastOne = 1 - (1 - singleChance) ^ attempts
	calcOutput.Text = string.format(
		"Single roll: %.8f%% | At least one in %d rolls: %.4f%%",
		singleChance * 100,
		attempts,
		atLeastOne * 100
	)
end)

-- 3) Grind planner
local grindOddsInput = makeInput(grindSection, 8, 28, 130, "Target aura odds N")
local grindRPMInput = makeInput(grindSection, 146, 28, 130, "Rolls / minute")
local grindButton = makeButton(grindSection, 284, 28, 90, "Estimate")
local grindOutput = makeLabel(grindSection, 8, 58, 500, 16, "ETA appears here.")

grindButton.MouseButton1Click:Connect(function()
	local oddsN = tonumber(grindOddsInput.Text)
	local rpm = tonumber(grindRPMInput.Text)

	if not oddsN or oddsN <= 0 or not rpm or rpm <= 0 then
		grindOutput.Text = "Enter valid target odds and rolls/minute."
		return
	end

	local expectedRolls = oddsN
	local totalMinutes = expectedRolls / rpm
	local hours = totalMinutes / 60
	grindOutput.Text = string.format(
		"Expected rolls: %.0f | Estimated time: %.1f min (%.2f h)",
		expectedRolls,
		totalMinutes,
		hours
	)
end)

-- 4) Loadout optimizer
local optimizeRPMInput = makeInput(optimizeSection, 8, 28, 130, "Base rolls/min")
local optimizeOddsInput = makeInput(optimizeSection, 146, 28, 130, "Target odds N")
local optimizeButton = makeButton(optimizeSection, 284, 28, 90, "Optimize")
local optimizeOutput = makeLabel(optimizeSection, 8, 58, 500, 20, "Recommended setup appears here.")

local strategies = {
	{ name = "Balanced", rollMultiplier = 1.15, luckMultiplier = 1.20 },
	{ name = "Speed Focus", rollMultiplier = 1.45, luckMultiplier = 1.00 },
	{ name = "Luck Focus", rollMultiplier = 1.00, luckMultiplier = 1.55 },
	{ name = "Endgame Mix", rollMultiplier = 1.30, luckMultiplier = 1.35 }
}

optimizeButton.MouseButton1Click:Connect(function()
	local baseRPM = tonumber(optimizeRPMInput.Text)
	local targetOdds = tonumber(optimizeOddsInput.Text)

	if not baseRPM or baseRPM <= 0 or not targetOdds or targetOdds <= 0 then
		optimizeOutput.Text = "Enter valid base rolls/min and target odds."
		return
	end

	local best = nil

	for _, s in ipairs(strategies) do
		local boostedRPM = baseRPM * s.rollMultiplier
		local effectiveOdds = targetOdds / s.luckMultiplier
		local expectedMinutes = effectiveOdds / boostedRPM

		if not best or expectedMinutes < best.expectedMinutes then
			best = {
				name = s.name,
				rpm = boostedRPM,
				effectiveOdds = effectiveOdds,
				expectedMinutes = expectedMinutes
			}
		end
	end

	optimizeOutput.Text = string.format(
		"Best: %s | Effective odds: 1 in %.0f | Effective RPM: %.1f | ETA: %.1f min",
		best.name,
		best.effectiveOdds,
		best.rpm,
		best.expectedMinutes
	)
end)

refreshTrackerText()

-- Optional API calls for other scripts
_G.SolsRNGPanel = {
	LogAuraRoll = logAuraRoll,
	GetState = function()
		return state
	end
}
