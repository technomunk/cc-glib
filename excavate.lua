-- Improved excavation procedure

local usage = [=[
excavate up|down [[radius|x], y, z]
Excavates a X*Y*Z cube in front of the turtle,
depositing mined items into the chest behind the
starting position if set to.]=]

local args = {...}

if #args == 0 then
	return usage
end

local util = require "util"
local inv = require "inventory"

assert(type(args[1]) == "string" and (args[1] == "up" or args[1] == "down"), "excavate expects up or down")
local dy = 1
if args[1] == "down" then
	dy = -1
end
local sx, sy, sz = 16, 16, 16

if #args > 1 then
	sx = tonumber(args[2])
	if sx < 1 then
		error("excavate expects a valid radius")
	end
	if #args > 3 then
		sy = tonumber(args[3])
		sz = tonumber(args[4])
		if sy < 1 or sz < 1 then
			error("excavate expects positive size")
		end
	else
		sy = sx
		sz = sx
	end
end

local chest = false
if util.ask("Is there a chest behind turtle?") then
	chest = true
elseif not util.ask("Continue anyway?") then
	error("Operation aborted")
end

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
local bucket_slot = inv.slot("minecraft:bucket")

local function turn_left()
	turtle.turnLeft()
	dx, dz = -dz, dx
end

local function turn_right()
	turtle.turnRight()
	dx, dz = dz, -dx
end

local function up()
	local ok = turtle.up()
	py = py + 1
	return ok
end

local function down()
	local ok = turtle.down()
	py = py - 1
	return ok
end

local function forward()
	local ok = turtle.forward()
	px = px + dx
	pz = pz + dz
	return ok
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

local function is_lava(block)
	return block.name == "minecraft:lava" and block.state.level == 0
end

local function _dig_or_scoop(inspect, dig, scoop)
	if bucket_slot then
		found, block = inspect()
		if found then
			if is_lava(block) then
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
	if forward() or (dig_or_scoop() and forward()) then
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
			if not up() or not (up() or dig_or_scoop_up() or up()) then
				return finish()
			end
		else
			if not down() or not (down() or dig_or_scoop_down() or down() then
				return finish()
			end
		end
	end
until done

return finish()
