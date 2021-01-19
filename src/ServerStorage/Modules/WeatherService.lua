-- Neztore, Jan 2021.
-- Provides weather and time of day.

-- Configuration
local INITIAL_TIME = 8 * 60

-- Imports
local Lighting = game:GetService("Lighting")


local WeatherService = {
	time = INITIAL_TIME
}

function WeatherService:Run ()
	(coroutine.wrap(function ()
		WeatherService:_doTime()
		
	end))()
end

function WeatherService:_doTime ()
	while true do
		local timeWaited = wait(1)
		self.time = self.time + timeWaited
		Lighting:SetMinutesAfterMidnight(self.time)
	end
end

return WeatherService
