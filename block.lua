-- Block inspection library

local util = require "util"

-- Check if the inspected block is scoopable lava
local function isLava(exists, block)
	block = block or exists
	return exists and block.name == "minecraft:lava" and block.state.level == 0
end

-- Check if the inspected block is a chest
local function isChest(exists, block)
	block = block or exists
	return exists and (block.tags["forge:chests"] or block.name:find("chest"))
end

local fallingBlocks = {
	"minecraft:gravel",
	"minecraft:sand",
}

-- Check if the provided block is affected by gravity
local function falls(exists, block)
	block = block or exists
	return exists and util.contains(fallingBlocks, block.name)
end

return {
	isLava = isLava,
	isChest = isChest,
	falls = falls,
}
