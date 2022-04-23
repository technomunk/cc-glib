--- A digger class that can persistently excavate an area through redstone

local block = require "block"
local inventory = require "inventory"
local navigator = require "navigator"
local util = require "util"


--- Get the X direction of clearing of the level at provided Y coordinate
--- @param y integer
--- @return integer sign -1 or 1
local function levelSignX(y)
	return 1 - 2 * (math.floor((y + 1) / 3) % 2)
end

--- An excavator turtle upgrade
--- Note that the cuboid excavated is always relative to navigator origin.
--- @class Digger
--- @field sx integer horizontal size to dig (orthogonal to initial direction)
--- @field sy integer vertical size to dig
--- @field sz integer horizontal size to dig (parallel to initial direction)
--- @field dx integer 1|-1 the overall horizontal direction to dig
--- @field dy integer 1|-1 the overall vertical direction to dig
--- @field bucketSlot? integer the slot with the bucket if it is in the inventory
--- @field navigator Navigator the navigation class to use
--- @field chest boolean whether deposit items to a chest
--- @field dug integer number of blocks dug
--- @field scooped integer number of buckets of lava scooped for fuel
--- @field waypoint? table {x, y, z, dx, dz} navigator state to return to
--- @field done integer number of steps completed
--- @field total integer total number of steps
local diggerArchetype = {
	sx = 0,
	sy = 0,
	sz = 0,

	dx = 1,
	dy = 1,

	chest = false,
	dug = 0,
	scooped = 0,

	done = 0,
	total = 0,

	--- Find the bucket slot
	--- @param self Digger
	--- @return integer|nil slotIndex of the slot with the bucket
	findBucket = function(self)
		self.bucketSlot = inventory.slot("minecraft:bucket")
		if self.bucketSlot then
			turtle.select(self.bucketSlot)
		end
		return self.bucketSlot
	end,

	--- Look for an inventory to deposit items to
	--- @param self Digger
	--- @return boolean exists whether the chest exists
	findChest = function(self)
		assert(
			self.navigator.x == 0
			and self.navigator.y == 0
			and self.navigator.z == 0
			and self.navigator.dx == 0
			and self.navigator.dz == 1,
			"Must be at origin to find chest!"
		)
		self.navigator:turnTo(0, -1)
		self.chest = block.isChest(turtle.inspect())
		self.navigator:turnTo(0, 1)
		return self.chest
	end,

	--- Dump the inventory into the chest in front of the digger
	dumpInventory = function(self)
		if self.chest then
			for i = 1, 16 do
				if i ~= self.bucketSlot then
					turtle.select(i)
					turtle.drop()
				end
			end
			if self.bucketSlot then
				turtle.select(self.bucketSlot)
			end
		end
	end,

	--- Go to the home base and depost items into the chest.
	--- @param self Digger
	returnItems = function(self)
		if not self.waypoint then
			self.waypoint = {
				x = self.navigator.x,
				y = self.navigator.y,
				z = self.navigator.z,
				dx = self.navigator.dx,
				dz = self.navigator.dz,
			}
		end

		if self.navigator.y > 0 and turtle.detectDown() then
			assert(turtle.digDown(), "failed to make path home")
			self.dug = self.dug + 1
		elseif self.nav.y < 0 then
			assert(turtle.digUp(), "failed to make path home")
			self.dug = self.dug + 1
		end

		assert(self.navigator:goTo(0, 0, 0), "failed to return home")
		self.navigator:turnTo(0, -1)

		self:dumpInventory()

		assert(self.navigator:goTo(0, 0, self.waypoint.z), "failed to return to digging")
		assert(self.navigator:goTo(self.waypoint.x, 0, self.waypoint.z), "failed to return to digging")
		assert(self.navigator:goTo(self.waypoint), "failed to return to digging")
		self.navigator:turnTo(self.waypoint)
		self.waypoint = nil
	end,

	--- Go to the chest and deposit items if the inventory is full
	--- @param self Digger
	returnItemsIfFullInv = function(self)
		if self.chest and inventory.isFull() then
			self:returnItems()
		end
	end,

	--- Turn toward the next line to excavate
	--- @param self Digger
	--- @param right boolean whether to turn right
	--- @return boolean success
	turn = function(self, right)
		if right then
			return self.navigator:turnRight()
		else
			return self.navigator:turnLeft()
		end
	end,

	--- Repeatedly dig any detected blocks. This is done to handle falling blocks like gravel.
	--- @param self Digger
	--- @param detect function to use for detecting blocks in a given direction
	--- @param dig function to use to dig in a given direction
	--- @return boolean success
	digGravel = function(self, detect, dig)
		while detect() do
			self:returnItemsIfFullInv()
			if dig() then
				self.dug = self.dug + 1
			else
				return false
			end
		end
		return true
	end,

	--- Check if inspected block is lava. If it is - scoop it, otherwise dig it.
	--- @param self Digger
	--- @param inspect function to use for inspecting a block. Should be identical to turlte.insepct*
	--- @param dig function to use for digging the block. Should be identical to turlte.dig*
	--- @param scoop function to use for scooping the block with a bucket. Should be identical to turtle.place*
	--- @return boolean success
	digOrScoop = function(self, inspect, dig, scoop)
		if self.bucketSlot then
			if block.isLava(inspect()) then
				scoop()
				turtle.refuel()
				self.scooped = self.scooped + 1
				print("Refueled, fuel level: " .. turtle.getFuelLevel())
				return true
			end
		end

		return dig()
	end,

	--- Check if the block in front is lava. If it is - scoop it, otherwise dig it.
	--- @param self Digger
	--- @return boolean success
	digOrScoopForth = function(self)
		return self:digOrScoop(
			turtle.inspect,
			function() return self:digGravel(turtle.detect, turtle.dig) end,
			turtle.place
		)
	end,

	--- Check if the block above is lava. If it is - scoop it, otherwise dig it.
	--- @param self Digger
	--- @return boolean success
	digOrScoopUp = function(self)
		return self:digOrScoop(
			turtle.inspectUp,
			function() return self:digGravel(turtle.detectUp, turtle.digUp) end,
			turtle.placeUp
		)
	end,

	--- Check if the block above is lava. If it is - scoop it, otherwise dig it.
	--- @param self Digger
	--- @return boolean success
	digOrScoopDown = function(self)
		return self:digOrScoop(
			turtle.inspectDown,
			function() return self:digGravel(turtle.detectDown, turtle.digDown) end,
			turtle.placeDown
		)
	end,

	--- Make a step in the right direction
	--- @param self Digger
	--- @return boolean success
	progress = function(self)
		self:digOrScoopForth()
		self.done = self.done + 1
		if not self.navigator:goForth() then
			return false
		end

		local minY, maxY = util.minmax(0, (self.sy - 1) * self.dy)

		if self.navigator.y < maxY then
			self:digOrScoopUp()
			self.done = self.done + 1
		end
		if self.navigator.y > minY then
			self:digOrScoopDown()
			self.done = self.done + 1
		end

		util.printProgress(self.done, self.total)
		return true
	end,

	--- Make the final trip home
	--- @param self Digger
	--- @param message? string the message to print after returning home
	finish = function(self, message)
		assert(self.navigator:goTo(0, 0, 0), "failed to return home")
		self.navigator:turnTo(0, -1)
		self:dumpInventory()
		print("Done mining.")
		if self.dug > 0 then
			print("Dug " .. self.dug .. " blocks.")
		end
		if self.scooped > 0 then
			print("Scooped " .. self.scooped .. " buckets of lava.")
		end
		if message then
			print(message)
		end
		settings.unset("digger")
		settings.save(".glib")
	end,

	--- Clear a Z line that the turtle faces
	--- @param self Digger
	--- @return boolean success
	clearLine = function(self)
		assert(self.navigator.dz == -1 or self.navigator.dz == 1)
		local targetZ = math.max(0, (self.sz - 1) * self.navigator.dz)
		for _ = 0, math.abs(targetZ - self.navigator.z) do
			if not self:progress() then
				return false
			end
		end
		return true
	end,

	--- Clear a horizotnal level by digging out lines along Z axis
	--- Assumes the leve up to Digger's current position has been cleared
	--- @param self Digger
	--- @return boolean success
	clearLevel = function(self)
		if self.navigator.x % 2 == 0 then
			self.navigator:turnTo(0, 1)
		else
			self.navigator:turnTo(0, -1)
		end

		local xSign = levelSignX(self.navigator.y)
		local targetX = math.max(0, (self.sx - 1) * xSign * self.dx)
		local rowSign = 1 - 2 * (self.navigator % 2)
		local rightTurn = (xSign * self.dx * rowSign) == 1

		for _ = 0, math.abs(targetX - self.navigator.x) do
			if not self:clearLine() then
				return false
			end

			-- exit early to avoid unnecessary dancing
			if self.navigator.x == targetX then
				return true
			end

			self:turn(rightTurn)
			if not self:progress() then
				return false
			end
			self:turn(rightTurn)
			rightTurn = not rightTurn
		end
		return true
	end,

	--- Go to the next level
	--- @param self Digger
	--- @return boolean success
	nextLevel = function(self)
		local minY, maxY = util.minmax(0, (self.sy - 1) * self.dy)
		if self.dy > 0 then
			if not self:digOrScoopUp() or not self.navigator:goUp() then
				return false
			end
			if self.navigator.y < maxY then
				return self:digOrScoopUp()
			end
		else
			if not self:digOrScoopDown() or not self.navigator:goDown() then
				return false
			end
			if self.navigator.y > minY then
				return self:digOrScoopDown()
			end
		end
	end,

	--- Begin the digging procedure. Uses class fields as arguments.
	--- @param self Digger
	excavate = function(self)
		assert(self.sx > 0 and self.sy > 0 and self.sz > 0, "size to dig must be positive!")

		self.total = self.sx * self.sy * self.sz
		self:findBucket()

		self:returnItemsIfFullInv()

		if self.navigator:atOrigin() and self.sy > 1 then
			if not self:nextLevel() then
				return self:finish("stopped early: setup height")
			end
		end

		repeat
			if not self:clearLevel() then
				return self:finish("stopped early: clearLevel")
			end

			if self.sy - math.abs(self.navigator.y) < 2 then
				self.done = self.total
			else
				if not self:nextLevel() or not self:nextLevel() then
					return self:finish("sopped early: nextLevel")
				end
			end
		until self.done >= self.total
	end,
}

local diggerMeta = { __index = diggerArchetype }

--- Instantiate a new digger
--- @param digger? table A table with digger parameters or none. Used for composition.
--- @return Digger New digger instance. Note that if loaded table was provided, it is returned.
local function new(digger)
	settings.load(".glib")
	settings.unset("digger")
	digger = setmetatable(digger or {}, diggerMeta)

	digger.navigator = navigator.new(digger.navigator)
	local function persist()
		digger.navigator.onMove = nil
		settings.set("glib.digger", digger)
		settings.save(".glib")
		digger.navigator.onMove = persist
	end
	persist()

	return digger
end

--- Load the digger from settings
--- @return Digger?
local function load()
	settings.load(".glib")
	local digger = settings.get("glib.digger", nil)
	if not digger then
		return
	end

	digger.navigator = navigator.new(digger.navigator)
	local function persist()
		digger.navigator.onMove = nil
		settings.set("glib.digger", digger)
		settings.save(".glib")
		digger.navigator.onMove = persist
	end
	persist()

	setmetatable(digger, diggerMeta)

	return digger
end

return {
	new = new,
	load = load,
}
