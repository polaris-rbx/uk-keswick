--[[
╔═╗─╔╗──────────╔╗
║║╚╗║║─────────╔╝╚╗
║╔╗╚╝║╔══╗╔═══╗╚╗╔╝╔══╗╔═╗╔══╗
║║╚╗║║║║═╣╠══║║─║║─║╔╗║║╔╝║║═╣
║║─║║║║║═╣║║══╣─║╚╗║╚╝║║║─║║═╣
╚╝─╚═╝╚══╝╚═══╝─╚═╝╚══╝╚╝─╚══╝
	Updated: Jan 2021.
	
	Tool system
	Stores which tools players have. This is as you cannot trust the backpack as a truthful representation of which tools a player has.
	Functions giveTool and removeTool can be passed either the tool name (and the tool will be retrieved from the standard tool storage), or the tool instance to give.
	Ownership of tools is determined by their name.
	Uses CollectionService to add a HasTool_TOOLNAME tag to the Player instances.
	All HasTool_ tags are managed by this module, including upon player death or respawn.
	
	Tool ownership is updated upon death.
]]
-- Configuration
local PREFIX = "HasTool_"

-- Imports
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local ToolStorage = ServerStorage:FindFirstChild("Tools")

local ToolSystem = {
	PREFIX = PREFIX
}


function ToolSystem:Run()
	Players.PlayerAdded:Connect(function (plr)
		plr.CharacterRemoving:Connect(function ()
			local tags = CollectionService:GetTags(plr)
			-- Remove all tool tags
			for _, tag in ipairs(tags) do
				if tag:find(PREFIX) ~= nil then
					CollectionService:RemoveTag(plr, tag)
				end
			end
		end)
	end)
end

-- Awards a tool by either name or using the tool instance. To prevent issues, this method will also take a clone of the passed tool instance.
-- Returns either the new tool, or nil for failure.
-- Does *not* perform duplication check. It is possible to have more than one of the same tool.
function ToolSystem:giveTool(player, tool)
	local toolName = tool
	local backpack = player:FindFirstChild("Backpack")
	
	-- It's on the Client, so it might be unreliable.
	if not backpack then
		warn("Could not give tools to " .. player.Name .. " as they have no Backpack.")
		return nil;
	end
		
	if typeof(tool) == "Instance" then
		toolName = tool.Name
	end
	
	
	if typeof(tool) == "Instance" then
		tool:Clone().Parent = backpack
	else
		-- If it isn't a tool instance, try to get it.
		local toGive = ToolStorage:FindFirstChild(tool)
		if not toGive then
			warn("Failed to give " .. player.Name .. " " .. tool .. " as it does not exist.")
			return nil;
		end
		toGive:Clone().Parent = backpack
	end
	
	-- Add tag used for validation
	CollectionService:AddTag(player, PREFIX..toolName)
end

-- Checks whether a player should have a tool. if checkBackpack is true, it will also verify that the player actually has it in their backpack.
function ToolSystem:hasTool(player, tool, checkBackpack)
	local toolName = tool
	local backpack = player:FindFirstChild("Backpack")

	-- It's on the Client, so it might be unreliable.
	if not backpack then
		warn("Could not give tools to " .. player.Name .. " as they have no Backpack.")
		return nil;
	end

	if typeof(tool) == "Instance" then
		toolName = tool.Name
	end
	local id = PREFIX..toolName
	
	if CollectionService:HasTag(player, id) then
		if checkBackpack then
			if backpack then
				if backpack:FindFirstChild(toolName) then
					return true
				end
			else
				warn("Could not obtain " .. player.Name .. " 's backpack.")
			end

			return false
		end
		return true;
	end
	
	-- no tag
	return false
end


-- Removes a tool from the player
-- can pass either an instance or tool name
-- will only remove 1 tool from their backpack. If it's equiped, it'll be unequiped and removed
-- To delete all of a tool, use a loop.
function ToolSystem:removeTool(player, tool)
	local toolName = tool
	if typeof(tool) == "Instance" then
		toolName = tool.Name
	end
	local id = PREFIX..toolName
	
	-- remove tag
	CollectionService:RemoveTag(player, id)
	
	-- check char for tool
	local char = player.Character
	if char then
		local toolInst = char:FindFirstChild(toolName)
		if toolInst then
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid then
				humanoid:UnequipTools()
			end
			toolInst:Destroy()
			return true;
		end
	end
	
	
	-- check backpack for tool
	local backpack = player:FindFirstChild("Backpack")
	if backpack and backpack:FindFirstChild(toolName) then
		backpack:FindFirstChild(toolName):Destroy()
		return true;
	end
	
	return false;
end



-- Global util method
-- Should be called with ., not :
-- But supports either
function _G.hasTool (self, tool)
	if tool then
		return ToolSystem:hasTool(tool)
	end
	return ToolSystem:hasTool(self)
end

return ToolSystem
