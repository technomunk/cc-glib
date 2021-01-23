-- Relative navigable coordinates

local directions = {
	d = function(pos, n) pos.y = pos.y - n end,
	e = function(pos, n) pos.x = pos.x + n end,
	n = function(pos, n) pos.z = pos.z - n end,
	s = function(pos, n) pos.z = pos.z + n end,
	u = function(pos, n) pos.y = pos.y + n end,
	w = function(pos, n) pos.w = pos.x - n end,
}

-- Check if the provided variable is a valid direction
function isdir(var)
	return type(var) == "string"
		and #var == 1
		and string.find('neswud', var)
end

local position = {
	--- Move self in provided direction
	move = function(self, dir, n)
		assert(isdir(dir))
		n = n or 1
		directions[dir](self)
	end,
}

local position_metatable = {
	__index = position,
}

-- Construct an instance of positional coordinates
function newpos(x, y, z)
	return setmetatable({
		x = tonumber(x) or 0,
		y = tonumber(y) or 0,
		z = tonumber(z) or 0,
	}, position_metatable)
end
