-- Block inspection library

-- Check if the inspected block is scoopable lava
local function isLava(exists, block)
	block = block or exists
	return exists and block.name == "minecraft:lava" and block.state.level == 0
end

-- Check if hte inspected block is a chest
local function isChest(exists, block)
	block = block or exists
	return exists and block.tags["forge:chests"]
end

return {
	isLava = isLava,
	isChest = isChest,
}
