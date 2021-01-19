--[[
╔═╗─╔╗──────────╔╗
║║╚╗║║─────────╔╝╚╗
║╔╗╚╝║╔══╗╔═══╗╚╗╔╝╔══╗╔═╗╔══╗
║║╚╗║║║║═╣╠══║║─║║─║╔╗║║╔╝║║═╣
║║─║║║║║═╣║║══╣─║╚╗║╚╝║║║─║║═╣
╚╝─╚═╝╚══╝╚═══╝─╚═╝╚══╝╚╝─╚══╝
	Updated: Jan 2021.
	
	Team System
	Manages the creation and deletion of teams, the assignment of tools and changing user teams.
	Also has useful methods for interacting with Teams and their configration table.

	Depends on:
		- ReplicatedStorage.TeamList
]]

-- Configuration
-- While on these teams, players cannot change off them. These teams can also be assigned via. setTeam as if they were a normal team.
local PRISON_TEAMS = {
	{
		name = "Prisoners",
		colour = BrickColor.new("Bright violet")
	}
}


-- Imports
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Remotes =	ReplicatedStorage:FindFirstChild("remotes")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")

local TeamList = require(ReplicatedStorage.TeamList)
local Modules = ServerStorage.Modules
local ToolService = require(Modules.ToolService)

local remotes = ReplicatedStorage:FindFirstChild("remotes")
if not remotes then
	error("Cannot start: No remotes folder! Create \"remotes\" in replicated storage.")
end

local changeTeamEvent = remotes.Team.changeTeam


local TeamSystem = {}

-- Set up listeners
function TeamSystem:Run() 
	-- Create auto-assignable teams
	for _, team in ipairs(TeamList) do
		if team.autoAssignable then
			TeamSystem:_createTeam(team)
		end
	end
	
	-- Remove empty teams when a player leaves
	Players.PlayerRemoving:Connect(function (plr)
		if plr.Team then
			local config = self:getTeam(plr.Team)
			if #plr.Team:GetPlayers() == 0 then
				if not config.autoAssignable then
					plr.Team:Destroy()
				end
			end
		end          
	end)
	
	-- Handle changeTeam events
	changeTeamEvent.OnServerEvent:Connect(function(plr, team)
		if team and typeof(team) == "string" then
			if TeamSystem:canAccessTeam(plr, team) then
				TeamSystem:setTeam(plr, team)
				plr:LoadCharacter()
			end
		end
	end)
end 

-- Gives the Team tools that this player should have.
-- Uses the built in Tools module.
function TeamSystem:giveTools(player)
	local config = self:getTeam(player)
	if config then
		for _, tool in ipairs(config.tool) do
			ToolService:giveTool(player, tool)
		end
	end
	
	
end

-- Returns the configuration information for passed team, or nil for no team with that name.
-- team: Team instance or a team name.
function TeamSystem:getTeam(team)
	local teamName
	if typeof(team) == "Instance" then
		teamName = string.lower(team.Name)
	else
		teamName = string.lower(team)
	end

	for _, team in ipairs(TeamList) do
		if string.lower(team.name) == teamName then
			return team;
		end
	end
	return nil;
end

-- Sets the team of the player to the given team.
-- Returns the configuration information for passed team.
-- player: The Player instance.
-- team: Team instance or a team name.
function TeamSystem:setTeam(player, team)
	local teamConfig = self:getTeam(team)
	if not teamConfig then
		-- Check if the passed team is a prison team
		for _, prisonTeam in ipairs(PRISON_TEAMS) do
			if team == prisonTeam.name then
				return self:_assignTeam(player, prisonTeam)
			end
		end
		-- No Prison team and no team config
		error("Could not team " ..player.Name .. " to " .. team .. " as it does not exist.")
	end
	
	return self:_assignTeam(player, teamConfig)
end

-- Handles creating and assigning a player's team.
function TeamSystem:_assignTeam(player, teamConfig)
	local existingTeam = Teams:FindFirstChild(teamConfig.name)
	if existingTeam then
		player.Team = existingTeam
		return teamConfig
	end
	
	local newTeam = self:_createTeam(teamConfig)
	player.Team = newTeam
	return teamConfig
end

function TeamSystem:canAccessTeam(plr, team)
	local config = self:getTeam(team)
	if not config then
		return false;
	end
	
	if not config.id then
		return false
	end
	
	-- Process rank array
	if config.ranks then
		for _, rankNum in ipairs(config.ranks) do
			if plr:GetRankInGroup(config.id) == rankNum then
				return true;
			end
		end
	end
	
	-- Process a minimum rank
	if config.minRank then
		if plr:GetRankInGroup(config.id) >= config.minRank then
			return true;
		end
	end
	
	return false;
end

function TeamSystem:_createTeam(teamConfig)
	-- Create a new team, and assign this player to it.
	local newTeam = Instance.new("Team")
	newTeam.Name = teamConfig.name
	newTeam.TeamColor = teamConfig.colour

	if teamConfig.autoAssignable then
		newTeam.AutoAssignable = true
	else
		newTeam.AutoAssignable = false
	end

	newTeam.Parent = Teams
	return newTeam
end

return TeamSystem