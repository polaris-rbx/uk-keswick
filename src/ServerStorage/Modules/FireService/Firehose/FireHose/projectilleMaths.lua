--[[
╔═╗─╔╗──────────╔╗
║║╚╗║║─────────╔╝╚╗
║╔╗╚╝║╔══╗╔═══╗╚╗╔╝╔══╗╔═╗╔══╗
║║╚╗║║║║═╣╠══║║─║║─║╔╗║║╔╝║║═╣
║║─║║║║║═╣║║══╣─║╚╗║╚╝║║║─║║═╣
╚╝─╚═╝╚══╝╚═══╝─╚═╝╚══╝╚╝─╚══╝
	Updated: Jan 2021.

	Projectille motion calculator, for a fire hose.
		Calculates key values needed to estminate and raycast it.
		Many, many braincells were harmed in the making of this script
		Writing this has allowed me to realise something: I bitterly, bitterly despise Mathematics. There is no joy to sweating over some equations and working
		with 3D vectors. None.
]]




--[[
	Returns: Table of values:
		firstVector: Vector3: The target vector to use for first raycast. Goes from Start point to midpoint.
		secondVector: Vector3: The target vector for the second raycast. Goes fro midpoint to endpoint
		midpoint: Vector3: The position of the midpoint.
		time: Seconds: The amount of time required for the entire motion.
		
		Midpoint and secondVector are not always present: If the initial vector is horizontal or points towards, only firstVector and time will be present.

]]
local module = {}
function module.getProjectileValues(emissionVector, emissionPosition, velocity, acceleration)
	local returnValues = {
		firstVector = nil,
		secondVector = nil,
		midpoint = nil,
		time = nil
	}
	local angle = module.getAngleFromVector(emissionVector)
	
	-- Common values
	local initialVerticalVelocity = velocity * math.sin(angle)
	local horizontalVelocity = velocity * math.cos(angle)
	local initialHeight = emissionPosition.Y
	
	if angle <= 0 then
		-- The emitter is pointed down. do something clever.
		local verticalDisplacement = initialHeight
		-- work out horizontal displacement
		-- determine final vertical velocity
		local finalVerticalVelocity = math.sqrt((initialVerticalVelocity ^2) + (2 * acceleration * -verticalDisplacement))                               
		local timeTaken = (2 *verticalDisplacement) / (initialVerticalVelocity + finalVerticalVelocity)
		local horizontalDisplacement = timeTaken * horizontalVelocity
		
		returnValues.firstVector = emissionVector * module.getHyp(horizontalDisplacement, verticalDisplacement)
		returnValues.time = timeTaken
		return returnValues
	end
	
	-- Using the vertical axis to calculate:
	-- 1. Find time to midpoint
	local timeToMidpoint = (-initialVerticalVelocity) / acceleration
	
	-- 2. Find Vertical distance change
	local verticalDist = (timeToMidpoint * 0.5) * (initialVerticalVelocity)

	-- 3. Find Horizontal height change
	local horizontalDist = (horizontalVelocity * timeToMidpoint)
	
	local dist = math.sqrt((verticalDist ^ 2) + (horizontalDist ^ 2))
	-- firstVector calculated
	returnValues.firstVector = emissionVector * dist
	
	-- Get the midpoint
	returnValues.midpoint = returnValues.firstVector + emissionPosition
	
	-- Second vector
	local fullVerticalDisplacement = initialHeight + verticalDist
	
	-- Time taken. Displacement is negative, as its going down.
	local timeToFall = math.sqrt((2 * -fullVerticalDisplacement) / acceleration)
	local horizontalDistTwo = horizontalVelocity * timeToFall
	
	-- Increased by 1.5 in-case the distance is esp. far
	local vectorTwoDist = module.getHyp(horizontalDistTwo, fullVerticalDisplacement)
	
	local xSpeed = returnValues.firstVector.X / timeToMidpoint
	local zSpeed = returnValues.firstVector.Z / timeToMidpoint
	
	local secondX = xSpeed * timeToFall
	local secondZ = zSpeed * timeToFall
	
	returnValues.secondVector =  Vector3.new(secondX, -fullVerticalDisplacement, secondZ) * 2
	returnValues.time = timeToFall + timeToMidpoint
	
	return returnValues
end

function module.getLifetimeOne (emissionPos, vectorHitPos, speed)
	return (vectorHitPos - emissionPos).magnitude / speed
end
-- Where it is passed the peak.
function module.getLifetimeTwo (emissionPos, vectorHitPos, speed, midPoint)
	local timeOne = module.getLifetimeOne(emissionPos, midPoint, speed)
	local res = timeOne + ((midPoint - vectorHitPos).magnitude / speed) 
	return res
end

function module.getAngleFromVector (vec)
	local horizontalHyp = math.sqrt((vec.X ^ 2) + (vec.Z ^ 2))
	if horizontalHyp == 0 then
		return nil
	end
	local dist = math.atan(vec.Y/horizontalHyp)
	return dist
end

-- Returns the hypoteneuse from the vertical, horizontal values.
function module.getHyp (horizontal, vertical)
	return math.sqrt((horizontal ^ 2) + (vertical ^ 2))
end

function getSign (num)
	if num >= 0 then
		return 1
	end	
	return -1
end



return module