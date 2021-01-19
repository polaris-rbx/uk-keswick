--[[
	Teams List
		The teams module contains team information including allowed tools, wages, group ids and more and is the primary way of configuring teams
		in-game. 
		It allows all team/group information to be stored in a single location - and for team instances to be dynamically created.

		It is imported within the server side Teams module, and on the client to show the correct teams in the team change menu.
		
		Global tools should be awarded with the StarterPack.
		
		The Prisoner Team is not included here. It it is created and destroyed seperately for the simple reason that the majority of these properties
		do not apply to it.
		---
		The module itself
		
		Either minRank OR ranks MUST be specified. To allow anyone to join, provide 0 as either the minRank or as one of the ranks values. 
		It is a flat array of Tables with the following values. A ? denotes an optional field:
		
		id 		 		Number 			    The group id. Used for group icon etc.
		minRank 		Number?	 			The minimum rank to join the team. People this rank and higher have access Ignored if group id is not specified.
		ranks			Table<Number>?		The rank(s) required to join this team. If both ranks and minRank are specified, ranks will take priority.
		name			String				The team name,
		shortName		String				A shortened representation of the team name, used in radio and the like.
		colour			BrickColor			The team colour
		wage			Number				The wage of members within this team.
		bankId			Number?				The bank identifier for this team.
		radioAccess 	Boolean				Whether or not this team can access the radio.
		tools			Table<String|Tool>	An array of either references to tool instances, or the names of tools in the standard tool storage.
											Tools are given via. the standard tools module to allow ownership to verified.
		autoAssignable	boolean?			Value to give the "AutoAssignable" team value. If this is ommitted or nil, it will be set to false.
		
]]


-- TODO: Review wage and bankId values. Using values from London.
local teams = {
	{
		id = 5267910,
		name = "Visitors",
		shortName = "VIS",
		colour = BrickColor.new("Medium stone grey"),
		wage = 200,
		bankId = 3,
		radioAccess = false,
		tools = {},
		ranks = {0, 1},
		autoAssignable = true	
	},
	{
		id = 5267910,
		name = "Citizens",
		shortName = "CIV",
		minRank = 3,
		colour = BrickColor.new("Sand red"),
		wage = 400,
		bankId = 3,
		radioAccess = false,
		tools = {},
		autoAssignable = false	
	},
	{
		id = 5271357,
		name = "Development & Administration",
		shortName = "D&A",
		colour = BrickColor.new("Dark taupe"),
		wage = 0,
		radioAccess = true,
		tools = {},
		minRank = 1 
	},
	{
		id = 5268402,
		-- TODO: Get proper name
		name = "Police service",
		shortName = "POL",
		minRank = 2,
		colour = BrickColor.new("Bright blue"),
		wage = 1150,
		radioAccess = true,
		tools = {}	
	},
	{
		["autoAssignable"] = false,
		["colour"] = BrickColor.new("Deep orange"),
		-- Royal family group
		["id"] = 5268358,
		-- Monarch rank
		ranks = {253},
		["name"] = "His Most Britannic Majesty",
		["radioAccess"] = true,
		["shortName"] = "HM",
		["tools"] = {},
		["wage"] = 10000
	},
	{
		["autoAssignable"] = false,
		["colour"] = BrickColor.new("Gold"),
		["id"] = 5268358,
		["name"] = "Royal Family",
		["radioAccess"] = true,
		["shortName"] = "RF",
		["tools"] = {},
		["wage"] = 5000,
		minRank = 1
	},
	{
		["autoAssignable"] = false,
		["colour"] = BrickColor.new("Plum"),
		["name"] = "Deputy Prime Minister",
		["radioAccess"] = true,
		["shortName"] = "DPM",
		["tools"] = {},
		ranks = {12},
		["wage"] = 800,
		id = 5267910,
	},
	{
		["autoAssignable"] = false,
		["colour"] = BrickColor.new("Mid gray"),
		["name"] = "Prime Minister",
		["radioAccess"] = true,
		["shortName"] = "PM",
		["tools"] = {},
		["wage"] = 800,
		ranks = {13},
		id = 5267910,
	},
	{
		["autoAssignable"] = false,
		["colour"] = BrickColor.new("Daisy orange"),
		["id"] = 5268397,
		["name"] = "Ambulance Service",
		["radioAccess"] = true,
		["shortName"] = "AS",
		["tools"] = {},
		["wage"] = 1100,
		minRank = 1
	},
	{
		["autoAssignable"] = false,
		["colour"] = BrickColor.new("Bright red"),
		["id"] = 5268264,
		["name"] = "Fire Brigade",
		["radioAccess"] = true,
		["shortName"] = "LFB",
		["tools"] = {},
		["wage"] = 1100,
		minRank = 1
	}
}


return teams