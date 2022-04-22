-- Upgraded turtle that is able to go to specified coordinates

--- @class Navigator
--- @field onMove function|nil the function to invoke after a succesful move
local navigatorArchetype = {
	x = 0,
	y = 0,
	z = 0,
	dx = 0,
	dz = 1,

	forth = turtle.forward,
	back = turtle.back,
	up = turtle.up,
	down = turtle.down,
	left = turtle.turnLeft,
	right = turtle.turnRight,

	--- Go forward n or 1 step(s)
	--- @param self Navigator
	--- @param n integer|nil the number of steps to take (or 1)
	--- @return boolean success
	goForth = function(self, n)
		n = tonumber(n) or 1
		for _ = 1, math.abs(n) do
			if n > 0 then
				if self:forth() then
					self.x = self.x + self.dx
					self.z = self.z + self.dz
					if self.onMove then
						self.onMove()
					end
				else
					return false
				end
			elseif self:back() then
				self.x = self.x - self.dx
				self.z = self.z - self.dz
				if self.onMove then
					self.onMove()
				end
			else
				return false
			end
		end
		return true
	end,
	--- Go backward n or 1 step(s)
	--- @param self Navigator
	--- @param n integer|nil the number of steps to take (or 1)
	--- @return boolean success
	goBack = function(self, n)
		n = tonumber(n) or 1
		return self:goForth(-n)
	end,
	--- Go up n or 1 step(s)
	--- @param self Navigator
	--- @param n integer|nil the number of steps to take (or 1)
	--- @return boolean success
	goUp = function(self, n)
		n = tonumber(n) or 1
		for _ = 1, n do
			if self:up() then
				self.y = self.y + 1
				if self.onMove then
					self.onMove()
				end
			else
				return false
			end
		end
		return true
	end,
	--- Go down n or 1 step(s)
	--- @param self Navigator
	--- @param n integer|nil the number of steps to take (or 1)
	--- @return boolean success
	goDown = function(self, n)
		n = tonumber(n) or 1
		for i = 1, n do
			if self:down() then
				self.y = self.y - 1
				if self.onMove then
					self.onMove()
				end
			else
				return false
			end
		end
		return true
	end,
	--- Turn the navigator left
	--- @param self Navigator
	--- @return boolean success
	turnLeft = function(self)
		if self:left() then
			self.dx, self.dz = -self.dz, self.dx
			if self.onMove then
				self.onMove()
			end
			return true
		end
		return false
	end,
	--- Turn the navigator right
	--- @param self Navigator
	--- @return boolean success
	turnRight = function(self)
		if self:right() then
			self.dx, self.dz = self.dz, -self.dx
			if self.onMove then
				self.onMove()
			end
			return true
		end
		return false
	end,
	--- Turn the navigator around
	--- @param self Navigator
	--- @return boolean success
	turnAround = function(self)
		return self:turnLeft() and self:turnLeft()
	end,

	--- Turn the navigator to face in such direction, that
	--- forward motion will affect x, z coordinates accordingly
	--- @param self Navigator
	--- @param dx integer|table -1|0|1 the resulting facing direction
	--- @param dz integer|nil -1|0|1 the resulting facing direction
	--- @return boolean success
	turnTo = function(self, dx, dz)
		if type(dx) == "table" then
			dz = dx.dz
			dx = dx.dx
		end
		assert(math.abs(dx) + math.abs(dz) == 1, "invalid direction")
		if dx ~= 0 then
			if self.dx == 0 then
				if self.dz == dx then
					self:turnRight()
				else
					self:turnLeft()
				end
			else
				return self.dx == dx or self:turnAround()
			end
		else
			if self.dz == 0 then
				if self.dx == dz then
					self:turnLeft()
				else
					self:turnRight()
				end
			else
				return self.dz == dz or self:turnAround()
			end
		end
	end,
	--- Go to provided coordinates
	--- @param self Navigator
	--- @param x integer|table resulting relative x coordinate or target point
	--- @param y integer|nil resulting relative y coordinate
	--- @param z integer|nil resulting relative z coordinate
	--- @return boolean success
	goTo = function(self, x, y, z)
		if type(x) == "table" then
			z = x.z
			y = x.y
			x = x.x
		end
		assert(x and y and z, "no coordinates given")
		if self.y < y and not self:goUp(y - self.y) then
			return false
		end
		if self.y > y and not self:goDown(self.y - y) then
			return false
		end

		if self.x ~= x then
			if self.x > x then
				self:turnTo(-1, 0)
			elseif self.x < x then
				self:turnTo(1, 0)
			end
			if not self:goForth(math.abs(x - self.x)) then
				return false
			end
		end

		if self.z ~= z then
			if self.z > z then
				self:turnTo(0, -1)
			elseif self.z < z then
				self:turnTo(0, 1)
			end
			if not self:goForth(math.abs(z - self.z)) then
				return false
			end
		end

		return true
	end,
}

local navigatorMeta = {
	__index = navigatorArchetype,
}

--- Instantiate provided table as a navigator
--- @param loaded table|nil
--- @return Navigator
local function new(loaded)
	settings.unset("navigator")
	return setmetatable(loaded or {}, navigatorMeta)
end

return {
	new = new,
}
