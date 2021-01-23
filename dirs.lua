-- Directions and their application to vectors

-- How directions change position
local directions = {
	d = vector.new(0, -1, 0),
	e = vector.new(1, 0, 0),
	n = vector.new(0, 0, -1),
	s = vector.new(0, 0, 1),
	u = vector.new(0, 1, 0),
	w = vector.new(-1, 0, 0),
}

-- Resulting heading after turning left
local lefts = {
	e = 'n',
	n = 'w',
	s = 'e',
	w = 's',
}

-- Resulting heading after turning right
local rights = {
	e = 's',
	n = 'e',
	s = 'w',
	w = 'n',
}

-- Opposite directions
local invdirs = {
	d = 'u',
	e = 'w',
	n = 's',
	s = 'n',
	u = 'd',
	w = 'e',
}

-- Check if the provided variable is a valid direction
local function is_dir(dir)
	return type(dir) == "string"
		and #dir == 1
		and string.find('densuw', dir)
end

-- Check if the provided variable is a valid heading
local function is_heading(dir)
	return type(dir) == "string"
		and #dir == 1
		and string.find('ensw', dir)
end

-- Get the direction after turning left
local function get_left(dir)
	return lefts[dir]
end

-- Get the direction after turning right
local function get_right(dir)
	return rights[dir]
end

-- Get the inverse of the provided direction(s)
local function inv(dir)
	return invdirs[dir]
end

-- Get the number of left turns needed to be performed
-- to get from a to b
local function lefts_to(a, b)
	assert(is_heading(a))
	assert(is_heading(b))
	local turns = 0
	while a ~= b do
		b = lefts[b]
		turns = turns + 1
	end
	return turns
end

-- Get the reverse (returning or backtracking) directions
local function reverse(dirs)
	if type(dirs) == "string" then
		dirs = into(dirs)
	end
	local result = {}
	for i=#dirs, 1, -1 do
		result[#result + 1] = inv(dirs[i])
	end
	return result
end

-- Apply a direction to vector coordinates n times
local function apply(dir, vec)
	return vec + directions[dir]
end

-- Convert stringified directions into workable path
local function into(dirs)
	local result = {}
	for i=1,#dirs do
		local c = dirs:sub(i,i)
		assert(is_dir(c))
		table.insert(result, c)
	end
	return result
end

-- Get the index of the provided coordinate in the provided path
local function idx_of(path, coord)
	for i, pt in ipairs(path) do
		if coord.x == pt.x and coord.y == pt.y and coord.z == pt.z then
			return i
		end
	end
	return nil
end

-- Remove any looping paths from the provided directions string
local function deloop(path)
	if type(path) == "string" then
		path = into(path)
	end

	local state = vector.new()
	local points = { state, }
	local result = {}

	for idx, dir in ipairs(path) do
		state = apply(dir, state)
		local index = idx_of(points, state)
		if index then
			for i=index+1, #points do
				table.remove(points)
				table.remove(result)
			end
		else
			table.insert(points, state)
			table.insert(result, dir)
		end
	end
	return result
end

return {
	is_dir = is_dir,
	is_heading = is_heading,
	get_left = get_left,
	get_right = get_right,
	inv = inv,
	lefts_to = lefts_to,
	into = into,
	reverse = reverse,
	apply = apply,
	deloop = deloop,
}
