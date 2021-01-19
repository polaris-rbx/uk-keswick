--[[
╔═╗─╔╗──────────╔╗
║║╚╗║║─────────╔╝╚╗
║╔╗╚╝║╔══╗╔═══╗╚╗╔╝╔══╗╔═╗╔══╗
║║╚╗║║║║═╣╠══║║─║║─║╔╗║║╔╝║║═╣
║║─║║║║║═╣║║══╣─║╚╗║╚╝║║║─║║═╣
╚╝─╚═╝╚══╝╚═══╝─╚═╝╚══╝╚╝─╚══╝
	Updated: Jan 2021.
]]
local FireService = {
	playersWithHose = {},
	hoseParts = {},
	hoseStartParts = {},
	skipCount = 0,
	heartbeatConnection = nil,
	hoseCount = 0,
	-- Used to store fire hit counts
	hitCount = {}
}

local config = require(script.config)
local events = require(script.events)(FireService)
local FireManager = require(script.FireManager)
FireManager:Run(FireService)

-- Imports
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")

-- Stored a heartbeat event, while it is active
local HOSE_TOOL_NAME = config.HOSE_TOOL_NAME
local MAX_DISTANCE = config.MAX_DISTANCE




-- Main Runner
function FireService:Run()
	local fireBlocks = workspace:FindFirstChild(config.FIRE_BLOCKS_FOLDER)

	if not fireBlocks then
		fireBlocks = Instance.new("Folder")
		fireBlocks.Name = config.FIRE_BLOCKS_FOLDER
		fireBlocks.Parent = game.Workspace
	end
	self.fireBlocks = fireBlocks
	
	 game.Players.PlayerRemoving:Connect(function(plr)
		if FireService.playersWithHose[plr.UserId] then
			FireService:removeHose(plr)
		end
		
	end)
end

--[[
	Allocate a hose to a player. Both clones the hose and connects it.
	Stores the hose internally for remote validation
]]
function FireService:giveHose(plr, partToBind)
	if self.playersWithHose[plr.UserId] then return false end
	for userId, part in pairs(self.hoseStartParts) do
		if part == partToBind then
			-- It is already in use
			return false
		end
	end
	print("Giving a hose to " .. plr.Name .. " - " .. plr.UserId)
	local character = plr.Character or plr.CharacterAdded:wait()
	
	local hose = script:FindFirstChild(config.HOSE_TOOL_NAME):Clone()
	hose.Parent = plr:WaitForChild("Backpack")
	
	-- Equip the tool
	if  character.Humanoid then
		character.Humanoid:EquipTool(hose)
		
		local onDied = character.Humanoid.Died:Connect(function ()
			print(plr.Name .. " has died with a hose!")
			FireService:removeHose(plr)
		end)
		
		self.playersWithHose[plr.UserId] = onDied
	else
		warn(plr.Name .. " has no character!")
	end
	
	self.hoseStartParts[plr.UserId] = partToBind
	self.hoseCount = self.hoseCount + 1
end



function FireService:removeHose(plr)
	warn("Removing " .. plr.Name .. " hose ")
	-- Remove them from the playersWithHose list
	if self.playersWithHose[plr.UserId] then
		self.playersWithHose[plr.UserId]:Disconnect()
		self.playersWithHose[plr.UserId] = nil
	end
	local part = self:getHosePart(plr.UserId)
	if part then
		part:Destroy()
	end
	
	self.hoseStartParts[plr.UserId] = nil
	FireService:setHosePart(plr.UserId, nil)
	
	-- Check if they have hose and remove it
	local backpack = plr:WaitForChild("Backpack")
	local character = plr.character
	local hose = character:FindFirstChild(HOSE_TOOL_NAME) or backpack:FindFirstChild(HOSE_TOOL_NAME)
	
	if hose and character then
		character.Humanoid:UnequipTools()
		wait(0.1)
		hose:Destroy()
	end
	self.hoseCount = self.hoseCount + 1
	if self.hoseCount == 0 and self.heartbeatConnection ~= nil then
		print("Stopping heartbeat!")
		self.heartbeatConnection:Disconnect()
		self.heartbeatConnection = nil
	end
end

function FireService:getHosePart(userId)
	return FireService.hoseParts[userId]
end

function FireService:setHosePart(userId, newPart)
	FireService.hoseParts[userId] = newPart
	return FireService.hoseParts[userId]
end

function FireService:hasHose (plrOrId)
	local id;
	if typeof(plrOrId) == "number" then
		id = plrOrId
	else
		id = plrOrId.UserId
	end
	if self.playersWithHose[id] then
		return true
	else
		return false
	end
end

return FireService