--[[
╔═╗─╔╗──────────╔╗
║║╚╗║║─────────╔╝╚╗
║╔╗╚╝║╔══╗╔═══╗╚╗╔╝╔══╗╔═╗╔══╗
║║╚╗║║║║═╣╠══║║─║║─║╔╗║║╔╝║║═╣
║║─║║║║║═╣║║══╣─║╚╗║╚╝║║║─║║═╣
╚╝─╚═╝╚══╝╚═══╝─╚═╝╚══╝╚╝─╚══╝
	Updated: Jan 2021.
	
	Persistent backpack
    Allows tool order to be saved and retrieved
    Tool orders are scoped to each team. 

    This module primarily recives events and sends responses. Most processing is done on the client.
    Makes use of a clone of the Roblox core Backpack UI.

    Data store keys make use of the Player ID and team name.
]]
-- Configuration
local STORE_NAME = "PERSISTENT_BACKPACK"
local MIN_INTERVAL = 6

-- Minimum interval for batches of fetches via. Function
local GET_MIN_INTERVAL = 3
local GET_BATCH_SIZE = 4


-- Imports
local DataStoreService = game:GetService("DataStoreService")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Players = game.Players

local store = DataStoreService:GetDataStore(STORE_NAME)
local backpackRemotes = ReplicatedStorage:FindFirstChild("remotes").Backpack
local updateBackpackEvent = backpackRemotes.updateBackpack
local fetchBackpackFunction = backpackRemotes.fetchBackpack


-- Stores the timestamp of the last request made by a player
-- To prevent remote spam
local RequestTimes = {}

local PersistentBackpack = {
}


function  PersistentBackpack:Run()
    local TeamService = require(ServerStorage.Modules.TeamService)
    fetchBackpackFunction.OnServerInvoke = function(Player)

        -- Rate limiting
        local limitKey = "GET_" ..Player.UserId
        local now = tick()
        if RequestTimes[limitKey] then
            if (now - RequestTimes[limitKey].since) < GET_MIN_INTERVAL and RequestTimes[limitKey].count >= GET_BATCH_SIZE  then
                warn(Player.Name .. " has sent GET backpack events too fast.")
                return nil;
            end
            RequestTimes[limitKey] = {
                since = tick(),
                count = RequestTimes[limitKey].count + 1
            }
        else
            RequestTimes[limitKey] = {
                since = tick(),
                count = 1
            }
        end
        

        local team = Player.Team
        if team then
            local config = TeamService:getTeam(team)
            local prefix = config and config.shortName or string.sub(team.Name, 1, 35)

            local raw
            local success, err = pcall(function()
                raw = store:GetAsync(prefix..Player.UserId)
            end)
            
            if success then
                if raw then
                    return team.Name, HttpService:JSONDecode(raw)
                else
                    return team.Name, false
                end
            end
            warn(err)
        end
    end
   

    updateBackpackEvent.OnServerEvent:Connect(function(Player, newValues)
        local now = tick()
        if RequestTimes[Player.UserId] then
            if (now - RequestTimes[Player.UserId]) < MIN_INTERVAL then
                return warn(Player.Name .. " has sent backpack events too fast.")
            end
        end
        RequestTimes[Player.UserId] = tick()
        -- Validate
        for key, val in pairs(newValues) do
            if typeof(key) ~= "number" or key < 0 or key > 10 then
                return warn(Player.Name .. " provided invalid backpack data.")
            end

            if val ~= false then
                if typeof(val) ~= "string" or string.len(val) > 60 or string.len(val) == 0 then
                    return warn(Player.Name .. " provided invalid backpack data - Bad tool name.")
                end
            end
        end

        if Player.Team then
            local config = TeamService:getTeam(Player.Team)
            local prefix = config and config.shortName or string.sub(Player.Team.Name, 1, 35)

            local val = HttpService:JSONEncode(newValues)
            local success, err = pcall(function()
                store:SetAsync(prefix..Player.UserId, val)
            end)
             
            if not success then
                warn("DataStore failure: " + err)
            end
        end
    end)
end


return PersistentBackpack