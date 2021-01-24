-- Upgraded turtle that is able to go to specified coordinates

local nav = {
	x = 0,
	y = 0,
	z = 0,
	dx = 0,
	dz = 1,

	forth = turtle.forward,
	back = turtle.back,
	up = turtle.up,
	down = turtle.down,

	-- Go forward n or 1 step(s)
	goForth = function(self, n)
		n = tonumber(n) or 1
		for i = 1, math.abs(n) do
			if n > 0 then
				if self:forth() then
					self.x = self.x + self.dx
					self.z = self.z + self.dz
				else
					return false
				end
			elseif self:back() then
				self.x = self.x - self.dx
				self.z = self.z - self.dz
			else
				return false
			end
		end
		return true
	end,
	-- Go backward n or 1 step(s)
	goBack = function(self, n)
		n = tonumber(n) or 1
		return self:goForth(-n)
	end,
	-- Go up n or 1 step(s)
	goUp = function(self, n)
		n = tonumber(n) or 1
		for i = 1, n do
			if self:up() then
				self.y = self.y + 1
			else
				return false
			end
		end
		return true
	end,
	-- Go down n or 1 step(s)
	goDown = function(self, n)
		n = tonumber(n) or 1
		for i = 1, n do
			if self:down() then
				self.y = self.y - 1
			else
				return false
			end
		end
		return true
	end,
	-- Turn the navigator left
	turnLeft = function(self)
		if turtle.turnLeft() then
			self.dx, self.dz = -self.dz, self.dx
			return true
		end
		return false
	end,
	-- Turn the navigator right
	turnRight = function(self)
		if turtle.turnRight() then
			self.dx, self.dz = self.dz, -self.dx
			return true
		end
		return false
	end,
	-- Turn the navigator around
	turnAround = function(self)
		return self:turnLeft() and self:turnLeft()
	end,
	
	-- Turn the navigator to face in such direction, that
	-- forward motion will affect x, z coordinates accordingly
	turnTo = function(self, dx, dy)
		assert(math.abs(dx) + math.abs(dy) == 1, "invalid direction")
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
	-- Go to provided coordinates
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
			self:turnTo(1, 0)
			self:goForth(x - self.x)
		end
		
		if self.z ~= z then
			self:turnTo(0, 1)
			self:goForth(z - self.z)
		end
	end,
}

local nav_meta = {
	__index = nav,
}

local function new()
	return setmetatable({
		x = 0,
		y = 0,
		z = 0,
	}, nav_meta)
end

return {
	new = new,
}
