local fireConfig = {
	HOSE_TOOL_NAME = "Firehose",
	REMOTES_FOLDER_NAME = "fire",
	MAX_DISTANCE = 200,
	FIRE_BLOCKS_FOLDER = "ActiveFireBlocks",
	FIRE_BLOCKS_STORAGE = "FireBlocks",
	-- A fire must be 'hit' 5 times for it to go out
	FIRE_HITS_TO_EXT = 5,
	FIRE_HITS_TO_HALF = 3,
	-- may need to be reduced if regen is off
	FIRE_DAMAGE = 25
}

return fireConfig
