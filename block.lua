-- Block inspection library

-- Check if the inspected block is scoopable lava
local function is_lava(exists, block)
	block = block or exists
	return exists and block.name == "minecraft:lava" and block.state.level == 0
end

-- Check if hte inspected block is a chest
local function is_chest(exists, block)
	block = block or exists
	return exists and block.tags["forge/chests"]
end

return {
	is_lava = is_lava,
	is_chest = is_chest,
}
