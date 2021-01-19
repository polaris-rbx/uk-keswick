--[[
    Manages saving tool order.
]]

-- Config

-- Imports
local StarterGui = game:GetService("StarterGui")
local localModules = script.Parent.Modules
local backpack = localModules:WaitForChild("RobloxGui"):FindFirstChild("Backpack")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("remotes"):WaitForChild("Backpack")
local LocalPlayer = game:GetService("Players").LocalPlayer

local updateBackpackEvent = remotes:WaitForChild("updateBackpack")
local fetchBackpackFunction = remotes:WaitForChild("fetchBackpack")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
local customBackpack = require(backpack)

local hasChanged = false
local lastSent = 0;
local minDelay = 8;

local orders = {}

customBackpack.SlotsChanged.Event:Connect(function()
    hasChanged = true
end)

LocalPlayer.CharacterRemoving:Connect(function()
    hasChanged = false
end)

customBackpack.StateChanged.Event:Connect(function(isNowOpen)

    if not isNowOpen and hasChanged and tick() - lastSent > minDelay then
        lastSent = tick()
        hasChanged = false

        local eventInfo = {}
        local slots = customBackpack:GetSlots()
        for counter = 1, 10 do
            local toolSlot = slots[counter]
            eventInfo[toolSlot.Index] = (toolSlot.Tool and toolSlot.Tool.Name) or false
        end

        orders[(LocalPlayer.Team and LocalPlayer.Team.Name) or "Neutral"] = eventInfo
        updateBackpackEvent:FireServer(eventInfo)

        StarterGui:SetCore("SendNotification", {
            Title = "Tool order saved",
            Text = "Your tool order was updated. Whenever you join this team, your tools will keep this order."
        })
    end
end)
local warningSent = false
-- todo: ensure it supports same tool multiple times
customBackpack.getSlotCallback = function(tool)
    if LocalPlayer.Team then
        local slots = customBackpack:GetSlots()
        local order = orders[LocalPlayer.Team.Name]

        -- If it's nil, it hasn't yet been fetched. Request it.
        if order == nil then
            local teamName, fetchedOrder = fetchBackpackFunction:InvokeServer(LocalPlayer.Team.Name)
        
            order = fetchedOrder;
            orders[teamName] = fetchedOrder;
        end

        -- Error/no ordering handling. If no ordering specified, allow any.
        if order == false then
            return false;
        elseif order == nil then
            -- It's still nil. It shouldn't be - successful fetches return false.
            if not warningSent then
                StarterGui:SetCore("SendNotification", {
                    Title = "Error warning",
                    Text = "Failed to fetch tool order, got fatal error. Please contact a dev."
                })
                warningSent = true
            end
            warn("Failed to fetch order!")

            -- To prevent constantly refetching, we set it to false
            orders[LocalPlayer.Team.Name] = false
        end

        -- An order exists: Apply it.
        if order then
            for index, toolName in pairs(order) do
                if toolName and toolName == tool.Name then
                    if not slots[index] then
                        warn("no slot at ", index)
                    end
                    if not slots[index].Tool then
                        return slots[index]
                    end
                    if slots[index].Tool ~= tool  then
                        -- Swap it out: An incorrect tool is in place.
                        slots[index]:MoveToInventory()
                        return slots[index]
                    end
                end
            end
        end
    end
end

updateBackpackEvent.OnClientEvent:Connect(function(teamName, config)
    orders[teamName] = config;
end)

