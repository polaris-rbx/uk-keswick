return nil;
--[[
╔═╗─╔╗──────────╔╗
║║╚╗║║─────────╔╝╚╗
║╔╗╚╝║╔══╗╔═══╗╚╗╔╝╔══╗╔═╗╔══╗
║║╚╗║║║║═╣╠══║║─║║─║╔╗║║╔╝║║═╣
║║─║║║║║═╣║║══╣─║╚╗║╚╝║║║─║║═╣
╚╝─╚═╝╚══╝╚═══╝─╚═╝╚══╝╚╝─╚══╝
	Updated: Jan 2021.

Fire system for RFUK, Keswick by Neztore.
Owing to the complexity of this system, I've opted to write documentation in a readme file of sorts, together with the code.
Strap in, because I hated writing a lot of it and explaining it is going to be even worse.

* The hose itself
	A hose is issued server side, and all clients in the game are informed of this. The FireLocal script will handle moving it to the position of it 
	must be in. It handles this for all players - even the player that it belongs to.
	
* Server side
	The Fire service module contains a number of tables. It keeps a track of every hose, player with hose and hoseSource in the game and in use at any
	given time.
	The events module is responsible for handling RemoteEvents, including replicating body and neck rotations across all clients.
	

* Issuing hoses (Server side)
Scripts which wish to issue a hose should require the "Fires" module, and use the method "giveHose", passing it:
		- The Player instance to give a hose to
		- The part that caused the activation, or where the hose 'pipe' should emit from.
	
	The module will perform duplication checks to ensure:
		- A user cannot have two hoses
		- A source cannot have > 1 user.

* Adding new buildings that can catch fire
	To make a building catch fire, outline it's walls and floor with a series of fire blocks. Then move it to ServerStorage.FireBlocks,
	within a Subfolder with the building name. This folder name will be used in announcements etc.

]]