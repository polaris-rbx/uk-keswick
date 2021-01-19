local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local Mouse = Player:GetMouse()
local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Tracks = {}
local InputType = Enum.UserInputType
local IsEquipped = false
local BeganConnection, EndedConnection

function playAnimation(animName)
	if Tracks[animName] then
		Tracks[animName]:Play()
	else
		local anim = Tool:FindFirstChild(animName)
		if anim and Tool.Parent and Tool.Parent:FindFirstChild("Humanoid") then
			Tracks[animName] = Tool.Parent.Humanoid:LoadAnimation(anim)
			playAnimation(animName)
		end
	end
end

function stopAnimation(animName)
	if Tracks[animName] then
		Tracks[animName]:Stop()
	end
end

function inputBegan(input)
	if input.UserInputType == InputType.MouseButton1 then
		playAnimation("Animation")
		wait(.6)
		local lp = game.Players.LocalPlayer
		local ms = lp:GetMouse()
		if not IsEquipped then return end
		Remote:FireServer(ms.Hit)
	end
end

function onEquip()
	BeganConnection = UIS.InputBegan:connect(inputBegan)
	IsEquipped = true
end

function onUnequip()
	if BeganConnection then
		BeganConnection:disconnect()
		BeganConnection = nil
		IsEquipped = false
	end
end

Tool.Equipped:connect(onEquip)
Tool.Unequipped:connect(onUnequip)