--[[
╔═╗─╔╗──────────╔╗
║║╚╗║║─────────╔╝╚╗
║╔╗╚╝║╔══╗╔═══╗╚╗╔╝╔══╗╔═╗╔══╗
║║╚╗║║║║═╣╠══║║─║║─║╔╗║║╔╝║║═╣
║║─║║║║║═╣║║══╣─║╚╗║╚╝║║║─║║═╣
╚╝─╚═╝╚══╝╚═══╝─╚═╝╚══╝╚╝─╚══╝
	Updated: Jan 2021.
	
	
Fire system, local component.
This script handles replicating player torso rotations and hose pipes.
Handles all hose replication - including, interestingly, the local player.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("remotes")
local fireRemotes = remotes:WaitForChild("fire")

local rotateBody = fireRemotes:WaitForChild("rotateBody")
local moveHose = fireRemotes:WaitForChild("moveHose")
local localPlayer = game.Players.LocalPlayer


local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local Head = localChar:WaitForChild("Head")
local Neck = Head:WaitForChild("Neck")

local Torso = localChar:WaitForChild("UpperTorso")
local Waist = Torso:WaitForChild("Waist")

local RunService = game:GetService("RunService")

-- The Neck origin is generally the same for all players?
local NeckOriginC0 = Neck.C0
local WaistOriginC0 = Waist.C0

local hoseParts = {}

-- Whether or not a render binding is in place
local bound = false;
local partCount = 0
local RUN_SERVICE_KEY = "HosePositionFollow"

rotateBody.OnClientEvent:Connect(function (Character, neckAngleOne, neckAngleTwo, headAngleOne, headAngleTwo)
	if Character == game.Players.LocalPlayer.Character then
		return warn("Recieved character change for self!")
	end
	-- Check if it's close
	if Character then
		local Head = Character:WaitForChild("Head")
		local Neck = Head:WaitForChild("Neck")
		local Torso = Character:WaitForChild("UpperTorso")

		local Waist = Torso:WaitForChild("Waist")

		local neckC0 = Neck.C0:lerp(NeckOriginC0 * CFrame.Angles(neckAngleOne,neckAngleTwo, 0), 0.5 / 2)
		local waistC0 = Waist.C0:lerp(WaistOriginC0 * CFrame.Angles(headAngleOne, headAngleTwo, 0), 0.5 / 2)
		Neck.C0 = neckC0
		Waist.C0 = waistC0
	end
end)

-- Seperate function to deal with scoping issues
function bindRunService ()
	RunService:BindToRenderStep(RUN_SERVICE_KEY, Enum.RenderPriority.Last.Value - 10, function()
		for userId, info in pairs(hoseParts) do
			local origin = info.origin
			local targetPart = info.targetPart
			local hosePart = info.hosePart

			if origin and origin.Parent ~= nil and targetPart and targetPart ~= nil and hosePart and hosePart.Parent ~= nil then
				-- Calculate the new hose lengths and send them to the clients
				local endPos = targetPart.Position
				local originPos = origin.Position

				local distance = (originPos - endPos).Magnitude


				local size = Vector3.new(0.3, 0.3, distance + 0.5)
				local cframe = CFrame.new(originPos, endPos) * CFrame.new(0, 0, -distance/2)
				hosePart.Size = size
				hosePart.CFrame = cframe
				
			elseif origin.Parent == nil or targetPart.Parent == nil or hosePart.Parent == nil then
				-- One or both of the parts have been removed - stop syncing them
				hoseParts[userId] = nil
			end
		end
	end)
end

moveHose.OnClientEvent:Connect(function (addNew, plr, origin, endPart, hosePart)
	if addNew then
		-- add a new hose part
		hoseParts[plr.UserId] = {
			origin = origin,
			targetPart = endPart,
			hosePart = hosePart
		}
		partCount = partCount + 1
		if not bound then
			bound = true
			bindRunService()
		end
	else
		-- Remove an existing hose part
		hoseParts[plr.UserId] = nil
		partCount = partCount - 1
		if partCount == 0 then
			bound = false

			RunService:UnbindFromRenderStep(RUN_SERVICE_KEY)
		end
	end
end)