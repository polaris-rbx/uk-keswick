-- Handles setting, putting out and otherwise managing fires.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local config = require(script.Parent.config)
local FireManager = {
	
}

function FireManager:Run(FireService)
	self.FireService = FireService
	FireManager.activefireBlocks = game.workspace:WaitForChild(config.FIRE_BLOCKS_FOLDER)
	FireManager.storedFireBlocks = ServerStorage[config.FIRE_BLOCKS_STORAGE]
	
	self.remotes = ReplicatedStorage:WaitForChild("remotes")[config.REMOTES_FOLDER_NAME]
	local setFireRemote = self.remotes:WaitForChild("setFire")
	
	setFireRemote.OnServerInvoke = function (plr)
		-- Look for Fire blocks nearby
		local found = self:playerIsNear(plr)
		
		if found then
			FireManager:setFire(found.Name)
			return true
		else
			return false
		end
	end
	
	coroutine.wrap(function()
		while wait(5) do
			if #FireManager.activefireBlocks:GetChildren() > 0 then
				for _, plr in pairs(game.Players:GetChildren()) do
					if FireManager:playerIsNear(plr) then
						local char = plr.Character
						if char and char.Humanoid then
							char.Humanoid:TakeDamage(config.FIRE_DAMAGE)
						end
					end
				end
			end
		end
	end)()
	
end

function FireManager:setFire(buildingName)
	if self.storedFireBlocks:FindFirstChild(buildingName) == nil then
		return warn("Could not set fire: Invalid building name: " ..buildingName)
	end
	local storedBuilding = self.storedFireBlocks[buildingName]
	
	local activeBlocks = game.workspace:WaitForChild(config.FIRE_BLOCKS_FOLDER)
	if activeBlocks:FindFirstChild(buildingName) ~= nil then
		-- re-move and re-ignite the fire
		self.activeFireBlocks[buildingName]:Destroy()
	end
	
	delay(5, function ()
		local newFire = storedBuilding:Clone()
		newFire.Parent = activeBlocks
		self:_igniteBlocks(newFire)		
	end)

end

function FireManager:_igniteBlocks(parentFolder)
	for _, fireBlock in pairs(parentFolder:GetChildren()) do
		script.Fire:Clone().Parent = fireBlock
		script.Smoke:Clone().Parent = fireBlock
	end
	
	local sound = script.fireSound:Clone()
	sound.Parent = parentFolder:GetChildren()[1]
	sound:Play()
end

function FireManager:extinuishFire(buildingName)
	
	
end


function FireManager:playerIsNear(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")
	
	for _, building in pairs(self.storedFireBlocks:GetChildren()) do
		for _, fireBlock in pairs(building:GetChildren()) do
			local distance = (root.Position - fireBlock.Position).magnitude
			if distance > 200 then
				-- If it's more than 200, we can assume this building isn't near.
				break;
			elseif distance < 8 then
				return building
			end
		end

		return nil
	end
end

return FireManager
