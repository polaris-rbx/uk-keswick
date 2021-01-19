-- Neztore, Jan 2021.
local modes = {
	{
		name = "LOW",
		color = Color3.new(0.282353, 0.780392, 0.454902),
		speed = NumberRange.new(30, 32),
		acceleration = -45,
		audioSpeed = 1
	},
	{
		name = "MEDIUM",
		color = Color3.new(1, 0.866667, 0.341176),
		speed = NumberRange.new(40, 42),
		acceleration = -45,
		audioSpeed = 1.5
	},
	{
		name = "HIGH",
		color = Color3.new(0.945098, 0.27451, 0.407843),
		speed = NumberRange.new(43, 45),
		acceleration = -32,
		audioSpeed = 2
	}
}
return modes