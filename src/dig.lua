-- Improved excavation procedure

local usage = [=[
dig up|down|--resume [x [y [z]]]
Digs up a X*Y*Z cube in front of the turtle,
depositing mined items into the chest behind the
starting position if set to.
If used with --resume flag, will attempt to resume
most recent operation.
]=]

local digger = require "digger"
local expect = require "cc.expect"
local util = require "util"

local function clearStartup()
	if fs.exists(".resume") then
		fs.delete(".resume")
	end
end

local args = { ... }

if #args == 0 then
	return usage
end

expect(1, args[1], "string")
assert(util.contains({"up", "down", "--resume"}, args[1]), "first paramter must be one of 'up', 'down' or '--resume'")

local dig
if args[1] == "--resume" then
	dig = digger.load()
	if not dig then
		return "nothing to resume"
	end
else
	dig = digger.new()

	if args[1] == "down" then
		dig.dy = -1
	end

	if #args > 1 then
		dig.sx = tonumber(args[2])
		dig.sy = sx
		dig.sz = sx
		if #args > 2 then
			dig.sy = tonumber(args[3])
			if #args > 3 then
				dig.sz = tonumber(args[4])
			end
		end
	end

	assert(dig.sx > 0 and dig.sy > 0 and dig.sz > 0, "size must be positive")
	assert(dig:findBucket() or util.ask("A bucket is recommended, continue without?", true), "operation aborted")
	assert(dig:findChest() or util.ask("Chest not found, continue anyway?", true), "operation aborted")

	assert(util.ask(string.format("Excavate %dx%dx%d area? (%d blocks)?", dig.sx, dig.sy, dig.sz, dig.sx * dig.sy * dig.sz), true), "operation aborted")
end

local file = io.open(".resume", "w")

if file then
	file:write("dig --resume")
	io.close(file)
end

dig:excavate()
clearStartup()
