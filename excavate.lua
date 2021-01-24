-- Improved excavation procedure

local usage = [=[
excavate up|down [x [y [z]]]
Excavates a X*Y*Z cube in front of the turtle,
depositing mined items into the chest behind the
starting position if set to.]=]

local args = {...}

if #args == 0 then
	return usage
end

local util = require "util"
local inv = require "inventory"
local block = require "block"

assert(type(args[1]) == "string" and (args[1] == "up" or args[1] == "down"), "excavate expects up or down")
local dy = 1
if args[1] == "down" then
	dy = -1
end
local sx, sy, sz = 16, 16, 16

if #args > 1 then
	sx = tonumber(args[2])
	sy = sx
	sz = sx
	if #args > 2 then
		sy = tonumber(args[3])
		if #args > 3 then
			sz = tonumber(args[4])
		end
	end
end

assert(sx > 0 and sy > 0 and sz > 0, "excavate requires positive size")

local bucket_slot = inv.slot("minecraft:bucket")

if not bucket_slot and not util.ask("A bucket is recommended, continue without?") then
	error("Operation aborted")
end

turtle.turnLeft()
turtle.turnLeft()
local chest = block.is_chest(turtle.inspect())
if not chest and not util.ask("Chest not found, continue anyway?") then
	error("Operation aborted")
end
turtle.turnLeft()
turtle.turnLeft()

if sy > 256 then
	sy = 256
end

if not util.ask("Excavate "..sx.."x"..sy.."x"..sz.." area? ("..sx*sy*sz.." blocks)?") then
	error("Operation aborted")
end

sx = sx - 1
sy = sy - 1
sz = sz - 1

if dy < 0 then
	sy = -sy
end

local px, py, pz = 0, 0, 0
local dx, dz = 0, 1
local dug, scooped = 0, 0

local function turn_left()
	if turtle.turnLeft() then
		dx, dz = -dz, dx
	end
end

local function turn_right()
	if turtle.turnRight() then
		dx, dz = dz, -dx
	end
end

local function up()
	if turtle.up() then
		py = py + 1
		return true
	end
	return false
end

local function down()
	if turtle.down() then
		py = py - 1
		return true
	end
	return false
end

local function forward()
	if turtle.forward() then
		px = px + dx
		pz = pz + dz
		return true
	end
	return false
end

local function go_to(x, y, z, fx, fz)
	while py > y do
		down()
	end
	while py < y do
		up()
	end

	if px < x then
		while dx ~= 1 do
			turn_left()
		end
	elseif px > x then
		while dx ~= -1 do
			turn_left()
		end
	end
	while px ~= x do
		forward()
	end

	if pz < z then
		while dz ~= 1 do
			turn_left()
		end
	elseif pz > z then
		while dz ~= -1 do
			turn_left()
		end
	end
	while pz ~= z do
		forward()
	end

	while dx ~= fx or dz ~= fz do
		turn_left()
	end
end

local function return_resources()
	local x,y,z,fx,fz = px,py,pz,dx,dy
	go_to(0, 0, 0, 0, -1)
	for i=1, 16 do
		if i ~= bucket_slot then
			turtle.select(i)
			turtle.drop()
		end
	end
	if bucket_slot then
		turtle.select(bucket_slot)
	end
	go_to(x, y, z, fx, fz)
end

local function return_if_full_inv()
	if chest and inv.is_full() then
		return_resources()
	end
end

local function _dig_or_scoop(inspect, dig, scoop)
	if bucket_slot then
		found, b = inspect()
		if found then
			if block.is_lava(b) then
				scoop()
				turtle.refuel()
				scooped = scooped + 1
				return true
			else
				return_if_full_inv()
				if dig() then
					dug = dug + 1
					return true
				else
					return false
				end
			end
		else
			return true
		end
	else
		return_if_full_inv()
		if dig() then
			dug = dug + 1
			return true
		else
			return false
		end
	end
end

local function dig_or_scoop()
	return _dig_or_scoop(turtle.inspect, turtle.dig, turtle.place)
end

local function dig_or_scoop_up()
	return _dig_or_scoop(turtle.inspectUp, turtle.digUp, turtle.placeUp)
end

local function dig_or_scoop_down()
	return _dig_or_scoop(turtle.inspectDown, turtle.digDown, turtle.placeDown)
end

local function progress()
	dig_or_scoop()
	if forward() then
		if dy > 0 then
			if py < sy then
				dig_or_scoop_up()
			end
		else
			if py > sy then
				dig_or_scoop_down()
			end
		end
		return true
	else
		return false
	end
end

local function finish()
	go_to(0, 0, 0, 0, -1)
	if chest then
		for i=1, 16 do
			if i ~= bucket_slot then
				turtle.select(i)
				turtle.drop()
			end
		end
	end
	print("Done mining.")
	if dug > 0 then
		print("Dug "..dug.." blocks.")
	end
	if scooped > 0 then
		print("Scooped "..scooped.." buckets of lava.")
	end
	return dug, scooped
end

local right = true
local function turn()
	if right then
		turn_right()
	else
		turn_left()
	end
end

if bucket_slot then
	turtle.select(bucket_slot)
end

if py ~= sy then
	if dy > 0 then
		dig_or_scoop_up()
	else
		dig_or_scoop_down()
	end
end

local done = false
repeat
	for x=0, sx do
		for z=1, sz do
			if not progress() then
				return finish()
			end
		end
		turn()
		if x ~= sx and not progress() then
			return finish()
		end
		turn()
		if x ~= sx then
			right = not right
		end
	end

	if math.abs(sy - py) < 2 then
		done = true
	else
		if dy > 0 then
			if not up() then return finish() end
			dig_or_scoop_up()
			if not up() then return finish() end
		else
			if not down() then return finish() end
			dig_or_scoop_down()
			if not down() then return finish() end
		end
	end
until done

return finish()
