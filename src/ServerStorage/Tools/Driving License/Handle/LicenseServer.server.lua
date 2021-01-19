--> Group ID for the rank displayed. <--
local group = 5267910


--> Actual code, does not need to be touched. <--
local surface = script.Parent.SurfaceGui
local billboard = script.Parent.BillboardGui.Background


function getCreatedDate(plr) 
    local DAY_TO_SECOND = 86400
    local currentTime = os.time()
    local age = plr.AccountAge
    local accountCreatedTime = currentTime - (age * DAY_TO_SECOND)
    return os.date("%d/%m/%Y", accountCreatedTime)
end

function addYearToCurrentDate(toAdd)
	local currentTime = os.time()
	local yearsToAdd = 86400 * 365
	local currentTimeWithAddedTime = currentTime + (yearsToAdd * toAdd)
	return os.date("%d/%m/%Y", currentTimeWithAddedTime)
end

script.Parent.Parent.Equipped:Connect(function()
	local player = game.Players:GetPlayerFromCharacter(script.Parent.Parent.Parent)
	surface.UserName.Text = "1. " .. player.Name
	surface.UserID.Text = "2. " .. player.UserId
	surface.Rank.Text = "4a. " .. player:GetRoleInGroup(group)
	surface.UserImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
	surface.Age.Text = "3. " .. player.AccountAge .. " Days Old"
	surface["Date of Birth"].Text = "4b. " .. getCreatedDate(player)
	surface.LicenceGiven.Text = "5. " .. os.date("%d/%m/%Y")
	surface.Expiry.Text = "7. " .. addYearToCurrentDate(10)
	
	billboard.UserName.Text = "1. " .. player.Name
	billboard.UserID.Text = "2. " .. player.UserId
	billboard.Rank.Text = "4a. " .. player:GetRoleInGroup(group)
	billboard.UserImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
	billboard.Age.Text = "3. " .. player.AccountAge .. " Days Old"
	billboard["Date of Birth"].Text = "4b. " .. getCreatedDate(player)
	billboard.LicenceGiven.Text = "5. " .. os.date("%d/%m/%Y")
	billboard.Expiry.Text = "7. " .. addYearToCurrentDate(10)
	script:Destroy()
end)