local module = {}
local RunService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage:WaitForChild("remotes")

if not remotes then
	return warn("Hose fail: No remotes!")
end
local rotateEvent = remotes:WaitForChild("fire"):WaitForChild("rotateBody")

local Player = game.Players.LocalPlayer
local PlayerMouse = Player:GetMouse()

local Camera = workspace.CurrentCamera

local Character = Player.Character or Player.CharacterAdded:Wait()
local Head = Character:WaitForChild("Head")
local Neck = Head:WaitForChild("Neck")

local Torso = Character:WaitForChild("UpperTorso")
local Waist = Torso:WaitForChild("Waist")

local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local NeckOriginC0 = Neck.C0
local WaistOriginC0 = Waist.C0

local originalNeck
local originalWaist

Neck.MaxVelocity = 1/3

local following = false
function module.followMouse ()
	if following then return false end
	following = true
	
	if Neck then
		originalNeck = Neck.C0
	end
	if Waist then
		originalWaist = Waist.C0
	end
	local lastNeck = CFrame.ne
	local lastWaist = 0
	
	RunService:BindToRenderStep("HoseBodyRotate", Enum.RenderPriority.Character.Value + 6, function()
		local CameraCFrame = Camera.CoordinateFrame
		if Character:FindFirstChild("UpperTorso") and Character:FindFirstChild("Head") then
			local TorsoLookVector = Torso.CFrame.lookVector
			local HeadPosition = Head.CFrame.p

			if Neck and Waist then
				if Camera.CameraSubject:IsDescendantOf(Character) or Camera.CameraSubject:IsDescendantOf(Player) then
					local Point = PlayerMouse.Hit.p

					local Distance = (Head.CFrame.p - Point).magnitude
					local Difference = Head.CFrame.Y - Point.Y
					
					local neckAngleOne = -(math.atan(Difference / Distance))
					local neckAngleTwo = (((HeadPosition - Point).Unit):Cross(TorsoLookVector)).Y
					
					local waistAngleOne = -(math.atan(Difference / Distance))
					local waistAngletwo =  (((HeadPosition - Point).Unit):Cross(TorsoLookVector)).Y * 0.5
					
					local neckC0 = Neck.C0:lerp(NeckOriginC0 * CFrame.Angles(neckAngleOne,neckAngleTwo, 0), 0.5 / 2)
					local waistC0 = Waist.C0:lerp(WaistOriginC0 * CFrame.Angles(waistAngleOne, waistAngletwo, 0), 0.5 / 2)
					
					Neck.C0 = neckC0
					Waist.C0 = waistC0
	
					if neckAngleOne ~= lastNeck or waistAngleOne ~= lastWaist then
						rotateEvent:FireServer(neckAngleOne, neckAngleTwo, waistAngleOne, waistAngletwo)
					end
					
					lastNeck = neckAngleOne
					lastWaist = waistAngleOne
				end
			end
		end	
	end)
end

function module.stopFollowing ()
	following = false
	RunService:UnbindFromRenderStep("HoseBodyRotate")
	
	rotateEvent:FireServer(originalNeck, originalWaist)
end

return module
