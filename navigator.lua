-- Navigator adaptor for turtles

local dirs = require "dirs"
local util = require "util"

local nav = {
	path = {},
	coords = vector.new(),
	dir = 'n',

	-- Move the navigator forward (toward its heading) n steps
	fwd = function(self, n)
		assert(type(self) == "table")
		n = n or 1
		local invdir = dirs.inv(self.dir)
		for i=1, n do
			assert(turtle.forward())
			if util.last(self.path) == invdir then
				table.remove(self.path)
			else
				table.insert(self.path, self.dir)
			end
			self.coords = dirs.apply(self.dir, self.coords)
		end
	end,
	-- Move the navigator back (away from its heading) n steps
	bck = function(self, n)
		assert(type(self) == "table")
		n = n or 1
		local invdir = dirs.invdir(self.dir)
		for i=1, n do
			assert(turtle.back())
			if util.last(self.path) == self.dir then
				table.remove(self.path)
			else
				table.insert(self.path, invdir)
			end
			self.coords = dirs.apply(invdir, self.coords)
		end
	end,
	-- Move the navigator up n steps
	up = function(self, n)
		assert(type(self) == "table")
		n = n or 1
		for i=1, n do
			assert(turtle.up())
			if util.last(self.path) == 'd' then
				table.remove(self.path)
			else
				table.insert(self.path, 'u')
			end
			self.coords = dirs.apply('u', self.coords)
		end
	end,
	-- Move the navigator down n steps
	dwn = function(self, n)
		assert(type(self) == "table")
		n = n or 1
		for i=1, n do
			assert(turtle.down())
			if util.last(self.path) == 'u' then
				table.remove(self.path)
			else
				table.insert(self.path, 'd')
			end
			self.coords = dirs.apply('d', self.coords)
		end
	end,
	-- Rotate the navigator left
	trn_left = function(self)
		assert(type(self) == "table")
		self.dir = dirs.leftdir(self.dir)
	end,
	-- Rotate the navigator right
	trn_right = function(self)
		assert(type(self) == "table")
		self.dir = dirs.rightdir(self.dir)
	end,
	-- Rotate the navigator to face the provided direction
	face = function(self, dir)
		assert(type(self) == "table")
		assert(dirs.is_heading(dir))
		local turns = coords.leftsto(self.dir, dir)
		if turns == 3 then
			self:trn_right()
		elseif turns == 2 then
			self:trn_right()
			self:trn_right()
		elseif turns == 1 then
			self:trn_left()
		end
	end,
	-- Navigate the navigator through with the provided directions
	follow = function(self, path)
		for i, dir in path do
			if dir == 'u' then
				self:up()
			elseif dir == 'd' then
				self:dwn()
			elseif dir == self.dir then
				self:fwd()
			elseif dir == dirs.inv(dir) then
				self:bck()
			elseif dir == dirs.get_left(self.dir) then
				self:trn_left()
				self:fwd()
			elseif dir == dirs.get_right(self.dir) then
				self:trn_right()
				self:fwd()
			else
				error("invalid direction")
			end
		end
	end,
	-- Return home walking on already walked coordinates
	return_home = function(self)
		self.path = dirs.deloop(self.path)
		self:follow(dirs.reverse(self.path))
	end,
	-- Check whether the navigator has enough fuel to go to
	-- provided coordinates
	has_fuel_to_go_to = function(self, coords)
		local x_delta = coords.x - self.coords.x
		local y_delta = coords.y - self.coords.y
		local z_delta = coords.z - self.coords.z
		return x_delta + y_delta + z_delta
	end,
	-- Go directly to provided coordinates
	go_to = function(self, coords)
		if self.coords.x < coords.x then
			self:face('e')
		elseif self.coords.x > coords.x then
			self:face('w')
		end
		while self.coords.x ~= coords.x do
			self:fwd()
		end

		if self.coords.z < coords.z then
			self:face('s')
		elseif self.coords.z > coords.z then
			self:face('n')
		end
		while self.coords.z ~= coords.z do
			self:fwd()
		end

		while self.coords.y < coords.y do
			self:up()
		end
		while self.coords.y > coords.y do
			self:dwn()
		end
	end,
	-- Go home directly, do not retrace path
	go_home = function(self)
		self:go_to(vector.new())
		self:set_home()
	end,
	-- Set the current position as home for the navigator
	set_home = function(self)
		self.path = {}
		self.coords = vector.new()
	end,
}

local nav_meta = {
	__index = nav
}

local function new(o)
	o = o or {}
	setmetatable(o, nav_meta)
	o.dir = 'n'
	o.coord = dirs.newpos()
	o.moves = {}
	return o
end

return {
	new = new,
}
