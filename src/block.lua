-- Block inspection library

local util = require "util"

-- Check if the inspected block is scoopable lava
local function isLava(exists, block)
	block = block or exists
	return exists and block.name == "minecraft:lava" and block.state.level == 0
end

-- Check if the inspected block is an inventory
local function isStorage(exists, block)
	return exists and (block.name:find("chest") or block.name:find("barrel"))
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
	isStorage = isStorage,
	falls = falls,
}
