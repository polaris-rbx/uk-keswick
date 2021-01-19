--[[
╔═╗─╔╗──────────╔╗
║║╚╗║║─────────╔╝╚╗
║╔╗╚╝║╔══╗╔═══╗╚╗╔╝╔══╗╔═╗╔══╗
║║╚╗║║║║═╣╠══║║─║║─║╔╗║║╔╝║║═╣
║║─║║║║║═╣║║══╣─║╚╗║╚╝║║║─║║═╣
╚╝─╚═╝╚══╝╚═══╝─╚═╝╚══╝╚╝─╚══╝
	Updated: Jan 2021.

	Client side of the hose tool.
	Uses raycast approximations of the motion of the water to ensure the path is clear. If it isn't, the water stops proportionally.              
]]
local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local emitter = tool:WaitForChild("Emitter")
local hose = tool:WaitForChild("hoseEnd")
local water = emitter:WaitForChild("water")
local UI = script:WaitForChild("hoseUI")

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local fireContainer = game.Workspace:FindFirstChild("ActiveFireBlocks")
local remotes = replicatedStorage:WaitForChild("remotes")

local follower = require(script:WaitForChild("cameraFollow"))
local mathModule = require(script:WaitForChild("projectilleMaths"))
local modes = require(replicatedStorage:WaitForChild("fireHoseModes"))

-- Constants
local REMOTES_FOLDER_NAME = "fire"
local HIT_THRESHOLD = 30
local POWER_DOWN_KEY = Enum.KeyCode.Q
local POWER_UP_KEY = Enum.KeyCode.E

if not remotes then
	return error("Hose fail: No remotes!")
end

-- Remotes
local fireRemotes = remotes:WaitForChild(REMOTES_FOLDER_NAME)
local tackleFireRemote = fireRemotes:WaitForChild("tackleFire")
local activateHoseRemote = fireRemotes:WaitForChild("activateHose")
local requestHoseEvent = fireRemotes:WaitForChild("requestHose")


-- Blacklist for non-collide parts.
local blacklist = { tool, player.Character }

-- Used to store fires that have been 'hit'. Once they have been hit a number of times, they are removed.
local fireHits = {}

local currentUI
local keyboardListener
local currentPower = 1

local debugMode = false
 
water.Enabled = false
tool.Activated:Connect(function ()
	water.Enabled = true
	-- Water is on, tool is equiped
	activateHoseRemote:FireServer(true, false, currentPower)

	RunService:BindToRenderStep("HoseWater", Enum.RenderPriority.Character.Value + 5, function()
		local hit = sendRaycast()
		if not hit then return end
		if hit:IsDescendantOf(fireContainer) then
			-- put it out
				if fireHits[hit] then
					fireHits[hit] = fireHits[hit] + 1
					if fireHits[hit] > HIT_THRESHOLD then
	
						tackleFireRemote:FireServer(hit)
						fireHits[hit] = nil
					end
				else
					-- set initial value
					fireHits[hit] = 1	
				end
		else
			-- not a fire

			if (not hit.CanCollide) or hit.Transparency == 1 then
				table.insert(blacklist, hit)
			end
		end
	end);
end)

tool.Deactivated:Connect(function ()
	water.Enabled = false
	RunService:UnbindFromRenderStep("HoseWater")
	
	-- Water is off, tool is equiped
	activateHoseRemote:FireServer(false, false)
	
end)

-- Keyboard events (Q/E)
local function onInputEnded(inputObject, gameProcessedEvent)
	if gameProcessedEvent then return end
	
	-- Next, check that the input was a keyboard event
	if inputObject.UserInputType == Enum.UserInputType.Keyboard then
		if inputObject.KeyCode == POWER_UP_KEY then
			if currentPower < #modes then
				currentPower = currentPower + 1	
			end
		elseif inputObject.KeyCode == POWER_DOWN_KEY then
			if currentPower > 1 then
				currentPower = currentPower - 1
			end
		else
			return nil
		end
		
		updatePower()
	end
end

function updatePower ()
	local opt = modes[currentPower]
	if not opt then
		currentPower = 1
		opt = modes[currentPower]
	end

	activateHoseRemote:FireServer(true, false, currentPower)
	if currentUI then
		local text = currentUI:FindFirstChild("power")
		text.Text = opt.name
		text.TextColor3 = opt.color
	end
end

function cleanUp ()
	water.Enabled = false
	RunService:UnbindFromRenderStep("HoseWater")
	RunService:UnbindFromRenderStep("HoseFollow")

	-- Water is off, tool is unequiped
	activateHoseRemote:FireServer(false, true)
	follower.stopFollowing()
	
	if currentUI then
		currentUI:Destroy()
		currentUI = nil
	end
	if keyboardListener then
		keyboardListener:Disconnect()
		keyboardListener = nil
	end
end

tool.equipped:Connect(function ()
	follower.followMouse()
	currentUI = UI:Clone()
	currentUI.Parent = player.PlayerGui
	keyboardListener =  userInputService.InputEnded:Connect(onInputEnded)
	updatePower()

	activateHoseRemote:FireServer(false, false)
	
	requestHoseEvent:FireServer()
	
	-- Death binding
	local character = player.Character
	if character then
		local e
		local function died ()
			warn("Died! stopping")	
			e:Disconnect()
			cleanUp()
		end
		e = character.Humanoid.Died:Connect(died)
	end
end)
tool.Unequipped:Connect(cleanUp)

local isBound = false


-- Send the full (Two part) raycast to find where the water lands.
-- Modifes the water such that it lands on the object it hits
-- Returns the hit part, if any.
function sendRaycast ()
	-- Offset to try and make it match the curve better.
	local waterSpeed = ((water.Speed.Max - water.Speed.Min) / 2) + water.Speed.Min
	local motionValues = mathModule.getProjectileValues(emitter.CFrame.LookVector, emitter.Position, (waterSpeed), water.Acceleration.Y)
	
	-- Cast the first ray
	local hitPart, pos = sendRaycastPart(emitter.Position, motionValues.firstVector)

	if hitPart then
		water.Lifetime = NumberRange.new(mathModule.getLifetimeOne ( emitter.Position, pos, waterSpeed))
		drawRay(emitter.Position, pos)
		return hitPart
	end
	

	-- Second (Downward) raycast. Starts at the 'top' of the water curve
	-- Second vector is not given if it was pointed towards the ground.
	if not motionValues.secondVector then
		warn("no second vector!!!")
		return nil
	end
	drawRay(motionValues.midpoint, emitter.Position)
	local hit, pos = sendRaycastPart(motionValues.midpoint, motionValues.secondVector)
	createPartAt(motionValues.midpoint)
	
	if hit then
		drawRay(motionValues.midpoint, pos)
		createPartAt(pos)
	
		-- Set lifetime to the distance from 'peak' to hit object, plus the lifetime for part A of the curve.
		-- Plus a small offset to account for the approximation
		local life = mathModule.getLifetimeTwo (emitter.Position, pos, waterSpeed, motionValues.midpoint)
		water.Lifetime = NumberRange.new(life)
		return hit
	end
	drawRay(motionValues.midpoint, motionValues.midpoint + motionValues.secondVector, BrickColor.new("Really red"))
	-- no hits - reset lifetime
	water.Lifetime = NumberRange.new(motionValues.time)
end


--[[
Sends a raycast part from {start} in direction/length {lengthVector}.
Return nil for no hit, or a tuple of (Part hit, distance travelled, intersectionPos)
]]--
function sendRaycastPart (start, lengthVector)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = blacklist
	raycastParams.IgnoreWater = true
	
	
	local raycast = workspace:Raycast(start, lengthVector, raycastParams)

	if raycast then
		local hit = raycast.Instance
		-- Calculate the lifetime distance
		return hit, raycast.Position
	end
	return nil
end


-- Get the lifetime that should be used for a given distance
-- Uses dist = speed * time
function getLifetime (d)
	return NumberRange.new(d / water.Speed.Max)
end



-- DEBUG - Create visual representation of the rays.
function createPartAt (pos)
	if (not debugMode) then return nil end
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.25, 0.25, 0.25)
	p.Anchored = true
	p.Transparency = 0.5
	p.Position = pos
	p.BrickColor = BrickColor.Random()
	p.CanCollide = false
	p.Parent = game.Workspace
	table.insert(blacklist, p)
end

function drawRay (origin, endPos, colour)
	if (not debugMode) then return nil end
	local distance = (origin - endPos).Magnitude
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(0.1, 0.1, distance)
	p.CFrame = CFrame.new(origin, endPos)*CFrame.new(0, 0, -distance/2)	
	p.CanCollide = false
	if colour then
		p.BrickColor = colour
	end
	
	p.Parent = game.Workspace
	table.insert(blacklist, p)
end


