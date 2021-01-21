local Radio = {
}

-- Configuration
-- Max characters in tag
local TAG_LIMIT = 4

local STATE_CODES = {"On Duty", "On Patrol, Available", "At Station, Available",
"Break, Unavailable", "En Route, Unavailable", "On Scene", "Committed, Available",
"Committed, Unavailable", "Off Duty", "Recieved"}

-- Imports
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Chat = game:GetService("Chat")

local remotes = ReplicatedStorage:FindFirstChild("remotes").radio
-- Used to pass events to clients.
local addMessageEvent = remotes.addMessage
local addStateEvent = remotes.addMessage

--[[
    PlayerRadios Schema
    Key: UserId (Player.UserId)
    Value: Table:
        active: boolean,
        state: number,
        callsign: string,
        // Only present if the radio is stolen. User id of the owner.
        originalOwner: int64?,
        originalOwnerName: string?

]]
local PlayerRadios = {}

function Radio:Run()
    -- Todo:
    -- Check on Respawn if have access. If they do, give it to them.
    -- If they aren't in the list, put them in it.
    -- If they don't, make sure they aren't in it.
    -- TODO: Check if Radio is active!
    -- This can be done via. an event fired when it is disabled or enabled, and updating this value when the user respawns.
    Chat:RegisterChatCallback(Enum.ChatCallbackType.OnServerReceivingMessage, function(message)
        -- Chat messages can be from non-players
        if message.SpeakerUserId then
            local player = Players:GetPlayerByUserId(message.SpeakerUserId)
            -- Ensure they have a radio, and that they've provided a valid message.
            if player and message.Message and message.MessageLength ~= 0 then
                local userRadio =  Radio:GetRadio(player)
                if userRadio.active then

                -- Check if Message contains "SN", where N is any number
                local StatusCode = message.Message:match("S%d")
                if StatusCode then
                    -- Parse code, and if valid do not send message into normal chat.
                    local num = tonumber(string.sub(StatusCode, 2))

                    if num and STATE_CODES[num] then
                        Radio:AddStateCode(player, num)
                        message.ShouldDeliver = false;
                        return message;
                    end
                end

                spawn(function()
                    local filteredMessage = Chat:FilterStringForBroadcast(message.Message, player)
                    Radio:AddMessage(player, message.Message, message.ExtraData.NameColor)
                end)
                end

            
            end
        end
        -- Always return the message
        return message;
    end)
end

function Radio:GetRadio(playerOrId)
    if typeof(playerOrId) == "instance" then
        return PlayerRadios[playerOrId.UserId]
    end
    return PlayerRadios[playerOrId]
end

-- Adds a new message
function Radio:AddMessage(Player, message, colour)
    local userRadio = PlayerRadios[Player.UserId]
    if not userRadio then
        warn("User " .. Player.Name .. " does not have a radio, but AddMessage was called.")
        return false;
    end

    local username = Player.Name
    if userRadio.originalOwner then
        local originalOwner = Player:GetPlayerByUserId(userRadio.originalOwner)
        
        if originalOwner then
            username = originalOwner.Name
            if originalOwner.TeamColor then
                colour = originalOwner.TeamColor.Color
            end
        else
            username = userRadio.originalOwnerName
        end
    end

    return addMessageEvent:FireAllClients(username, userRadio.callsign, userRadio.state)
end

function Radio:AddStateCode(Player, code)
    local userRadio = PlayerRadios[Player.UserId]
    if not userRadio then
        warn("User " .. Player.Name .. " does not have a radio, but AddStateCode was called.")
        return false;
    end

    local id = Player.UserId or userRadio.originalOwner
    local username = Player.Name or userRadio.originalOwnerName
    
    -- UserId, username, newStateCode, newStateString, callsign
    return addStateEvent:FireAllClients(id, username, code, STATE_CODES[code], userRadio.callsign)
end

function Radio:AddPanic(Player)
    local userRadio = PlayerRadios[Player.UserId]
    if not userRadio then
        warn("User " .. Player.Name .. " does not have a radio, but AddPanic was called.")
        return false;
    end
end




return Radio;