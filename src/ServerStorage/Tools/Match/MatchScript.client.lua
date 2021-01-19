--[[
╔═╗─╔╗──────────╔╗
║║╚╗║║─────────╔╝╚╗
║╔╗╚╝║╔══╗╔═══╗╚╗╔╝╔══╗╔═╗╔══╗
║║╚╗║║║║═╣╠══║║─║║─║╔╗║║╔╝║║═╣
║║─║║║║║═╣║║══╣─║╚╗║╚╝║║║─║║═╣
╚╝─╚═╝╚══╝╚═══╝─╚═╝╚══╝╚╝─╚══╝
	Updated: Jan 2021.
	Match tool code.
]]
local tool = script.Parent

local player = game:GetService("Players").LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("remotes"):WaitForChild("fire")
local setFireFunction = remotes:WaitForChild("setFire")

local UI = script:WaitForChild("matchUi")


-- used for basic rate limiting on clicks
local lastSent = os.time()
-- 3 seconds
local RATE_LIMIT = 3

tool.Activated:Connect(function ()
	if os.time() - lastSent > RATE_LIMIT then
		-- Send request
		lastSent = os.time()
		local lit = setFireFunction:InvokeServer()
		local text = UI.text
		if lit then
			text.Text = "Fire lit! Get out of  there!"
			UI.text.TextColor3 = Color3.new(0.282353, 0.780392, 0.454902)
			script.light:Play()
		else
			text.Text = "Couldn't find anything flammible. "
			text.TextColor3 =  Color3.new(0.945098, 0.27451, 0.407843)
		end
		
		delay(5, function ()
			text.Text = "Click to attempt to light fire."
			text.TextColor3 =  Color3.new(1, 1, 1)
		end)
	end
end)

tool.equipped:Connect(function ()
	UI.Parent = player.PlayerGui
	UI.Enabled = true
end)

tool.Unequipped:Connect(function ()
	UI.Parent = script
	UI.Enabled = false
end)