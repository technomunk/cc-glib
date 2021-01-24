-- Improved excavation procedure

local usage = [=[
dig up|down [x [y [z]]]
Digs up a X*Y*Z cube in front of the turtle,
depositing mined items into the chest behind the
starting position if set to.]=]

local args = {...}

if #args == 0 then
	return usage
end

local util = require "util"
local inv = require "inventory"
local block = require "block"
local navigator = require "navigator"

assert(type(args[1]) == "string" and (args[1] == "up" or args[1] == "down"), "dig expects up or down")
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

assert(sx > 0 and sy > 0 and sz > 0, "dig requires positive size")

local bucketSlot = inv.slot("minecraft:bucket")

if not bucketSlot and not util.ask("A bucket is recommended, continue without?") then
	error("Operation aborted")
end

turtle.turnLeft()
turtle.turnLeft()
local chest = block.isChest(turtle.inspect())
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

local minY, maxY = 0, sy

if dy < 0 then
	minY, maxY = -sy, 0
end

local nav = navigator.new()
local dug, scooped = 0, 0

local function returnItems()
	local x, y, z, dx, dz = nav.x, nav.y, nav.z, nav.dx, nav.dz
	nav:goTo(0, 0, 0)
	nav:turnTo(0, -1)
	for i=1, 16 do
		if i ~= bucketSlot then
			turtle.select(i)
			turtle.drop()
		end
	end
	if bucketSlot then
		turtle.select(bucketSlot)
	end
	nav:goTo(x, y, z)
	nav:turnTo(dx, dz)
end

local function returnItemsIfFullInv()
	if chest and inv.is_full() then
		returnItems()
	end
end

local function _digOrScoop(inspect, dig, scoop)
	if bucketSlot then
		found, b = inspect()
		if found then
			if block.isLava(b) then
				scoop()
				turtle.refuel()
				scooped = scooped + 1
				return true
			else
				returnItemsIfFullInv()
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
		returnItemsIfFullInv()
		if dig() then
			dug = dug + 1
			return true
		else
			return false
		end
	end
end

local function digOrScoop()
	return _digOrScoop(turtle.inspect, turtle.dig, turtle.place)
end

local function digOrScoopUp()
	return _digOrScoop(turtle.inspectUp, turtle.digUp, turtle.placeUp)
end

local function digOrScoopDown()
	return _digOrScoop(turtle.inspectDown, turtle.digDown, turtle.placeDown)
end

local function progress()
	digOrScoop()
	if nav:goForth() then
		if nav.y < maxY then
			digOrScoopUp()
		end
		if nav.y > minY then
			digOrScoopDown()
		end
		return true
	else
		return false
	end
end

local function finish()
	nav:goTo(0, 0, 0)
	nav:turnTo(0, -1)
	if chest then
		for i=1, 16 do
			if i ~= bucketSlot then
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
		nav:turnRight()
	else
		nav:turnLeft()
	end
end

if bucketSlot then
	turtle.select(bucketSlot)
end

if sy > 0 then
	if dy > 0 then
		digOrScoopUp()
		if not nav:goUp() then
			return finish()
		end
		if nav.y < maxY then
			digOrScoopUp()
		end
	else
		digOrScoopDown()
		if not nav:goDown() then
			return finish()
		end
		if nav.y > minY then
			digOrScoopDown()
		end
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

	if sy - math.abs(nav.y) < 3 then
		done = true
	else
		if dy > 0 then
			if not nav:goUp() then return finish() end
			digOrScoopUp()
			if not nav:goUp() then return finish() end
			if nav.y < maxY then
				digOrScoopUp()
				if not nav:goUp() then return finish() end
				if nav.y < maxY then digOrScoopUp() end
			end
		else
			if not nav:goDown() then return finish() end
			digOrScoopDown()
			if not nav:goDown() then return finish() end
			if nav.y > minY then
				digOrScoopDown()
				if not nav:goDown() then return finish() end
				if nav.y > minY then digOrScoopDown() end
			end
		end
	end
until done

return finish()
