-- Contains all hose-related event handlers only.
local runService = game:GetService("RunService")
return function (FireService)
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local remotes = replicatedStorage:WaitForChild("remotes")
	local config = require(script.Parent.config)
	local modes = require(replicatedStorage:FindFirstChild("fireHoseModes"))
	
	if not remotes then
		return error("FireModule: Failed to start - Could not find remotes!")
	end

	-- Remotes
	local fireRemotes = remotes:WaitForChild(config.REMOTES_FOLDER_NAME)
	local tackleFireRemote = fireRemotes:WaitForChild("tackleFire")
	local activateHoseRemote = fireRemotes:WaitForChild("activateHose")
	local rotateBodyRemote = fireRemotes:WaitForChild("rotateBody")
	local moveHoseRemote = fireRemotes:WaitForChild("moveHose")
	local requestHoseFunction = fireRemotes:FindFirstChild("requestHose")
	
	-- Handles water and give/remove hose
	-- Fired when button is clicked to activate water, when mouse is released to stop water
	-- Fired when the player unequips the tool
	activateHoseRemote.OnServerEvent:Connect(function (plr, hoseOn, unequiped, modeNum)
		if unequiped then
			return FireService:removeHose(plr)
		end

		local character = plr.Character	
		local hose = character:WaitForChild(config.HOSE_TOOL_NAME)
		local emitter = hose:WaitForChild("Emitter")
		
		if modeNum and modeNum >= 1 and modes[modeNum] ~= nil then
			local currentMode = modes[modeNum]
			emitter.water.Speed = currentMode.speed
			emitter.water.Acceleration = Vector3.new(0, currentMode.acceleration, 0)

			emitter.SpraySound.PlaybackSpeed = currentMode.audioSpeed
			if not emitter.SpraySound.IsPlaying then
				emitter.SpraySound:Play()
			end

		end


		if hoseOn then
			emitter.SpraySound:Play()
			emitter.water.Enabled = true

		else
			emitter.SpraySound:Stop()
			emitter.water.Enabled = false
		end
	end)


	tackleFireRemote.OnServerEvent:Connect(function (plr, fireBlock)
		local character = plr.Character
		-- Check if it's close
		if fireBlock and fireBlock.Parent and fireBlock:IsDescendantOf(game.Workspace:FindFirstChild(config.FIRE_BLOCKS_FOLDER)) and character ~= nil then
			local root = character:WaitForChild("HumanoidRootPart")
			local distance = (root.Position - fireBlock.Position).magnitude

			if distance > config.MAX_DISTANCE then
				FireService:removeHose(plr)
				return warn(plr.Name .." trying to put out fire from impossible distance of " .. distance .. "!")
			end
			if FireService.hitCount[fireBlock] then
				FireService.hitCount[fireBlock] = FireService.hitCount[fireBlock] + 1
			else
				FireService.hitCount[fireBlock] = 1
			end
			
			local count = FireService.hitCount[fireBlock]
			if  count > config.FIRE_HITS_TO_EXT then
				if #fireBlock.Parent:GetChildren() == 1 then
					print(fireBlock.Parent.Name .. " is no longer on fire...")
				end
				fireBlock:Destroy()
				FireService.hitCount[fireBlock] = nil
			elseif count > config.FIRE_HITS_TO_HALF then
				for _, i in pairs (fireBlock:GetChildren()) do
					if i:IsA("ParticleEmitter") then
						i.Rate = i.Rate / 2
					end
				end
			end

			
		end
	end)
	
	rotateBodyRemote.OnServerEvent:Connect(function (plr, neckAngleOne, neckAngleTwo, headAngleOne, headAngleTwo)
		local Character = plr.Character
		-- Check if it's close
		if FireService:hasHose(plr) and Character then
			-- inform all clients
			for _, player in pairs(game.Players:GetPlayers()) do
				if player.UserId ~= plr.UserId then
					rotateBodyRemote:FireClient(player, Character, neckAngleOne, neckAngleTwo, headAngleOne, headAngleTwo )
				end
			end
		end
	end)
	
	requestHoseFunction.OnServerEvent:Connect(function (plr)
		warn(plr.Name .. " requested a hose!")
		if not FireService:hasHose(plr) then
			warn("User " .. plr.Name .. " tried to get a pipe without a hose.")
			return false
		end
		if FireService:getHosePart(plr.UserId) then
			warn(plr.Name " already has a hose part.")
			return false
		end
		local startPart = FireService.hoseStartParts[plr.UserId]
		if not startPart then
			warn("Failed to obtain start part!!")
			return false
		end
		-- Create a new hose part
		local newHose = Instance.new("Part")
		newHose.Name = "hosePart" .. plr.UserId
		newHose.BrickColor = BrickColor.new("Crimson")
		newHose.Anchored = true
		newHose.CanCollide = false
		newHose.Position = startPart.Position
		newHose.Material = Enum.Material.Plastic
		newHose.TopSurface = Enum.SurfaceType.Smooth
		newHose.BottomSurface = Enum.SurfaceType.Smooth
		newHose.Size = Vector3.new(1, 1, 1)

		newHose.Parent = game.Workspace
		FireService:setHosePart(plr.UserId, newHose)
		
		local character = plr.Character
		if not character then return warn("Could not obtain character!") end
		local hose = character:FindFirstChild(config.HOSE_TOOL_NAME)
		local endPoint = hose:WaitForChild("hoseEnd")
		
		
		-- Informing all clients about the new hose
		moveHoseRemote:FireAllClients(true, plr, startPart, endPoint, newHose)

		-- Inform the client about the newly created hose
		-- This remote is primarily used to turn water on/off etc
		-- But it used from Server-> Client to inform of hose, only.
		print("Telling " .. plr.Name .. " about their hose")
		return startPart, newHose
		
	end)
	
	
	return {
		fireRemotes = fireRemotes,
		tackleFireRemote = tackleFireRemote,
		activateHoseRemote = activateHoseRemote,
		rotateBodyRemote = rotateBodyRemote,
		moveHoseRemote = moveHoseRemote
	}
end