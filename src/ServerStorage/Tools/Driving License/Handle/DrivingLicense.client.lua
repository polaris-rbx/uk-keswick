local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local licenseName = script.Parent.Parent.Name

local mouse = LocalPlayer:GetMouse()
local localUi = script.Parent:FindFirstChild("BillboardGui")

if localUi then
	localUi.Enabled = true
end

-- Show other player's ID on hover
local shownUi;
mouse.Move:Connect(function()
	-- If mouse is over a driving license being held
	if mouse.Target and mouse.Target.Parent and mouse.Target.Parent.Name == licenseName then
		-- Locally show it
		local ui = mouse.Target:FindFirstChild("BillboardGui")
		if ui then
			shownUi = ui
			ui.Enabled = true
		end
	else
		-- A UI is showing, but we are no longer hovering over one.
		if shownUi then
			shownUi.Enabled = false
			shownUi = nil
		end
	end
end)


