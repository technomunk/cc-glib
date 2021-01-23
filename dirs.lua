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

-- Remove any looping paths from the provided directions string
local function deloop(dirs)
	local path = {}
	local index_to_state = {}
	local state_to_index = {}
	local state = vector.new()
	for idx, dir in ipairs(dirs) do
		state = apply(dir, state)
		local state_index = state_to_index[state]
		if state_index then
			for i=state_index, #path do
				table.remove(path)
				index_to_state[i] = nil
				state_to_index[state] = nil
			end
		else
			table.insert(path, dir)
			index_to_state[#path] = state
			state_to_index[state] = #path
		end
	end
	return path
end


return {
	is_dir = is_dir,
	is_heading = is_heading,
	get_left = get_left,
	get_right = get_right,
	inv = inv,
	lefts_to = lefts_to,
	reverse = reverse,
	apply = apply,
	deloop = deloop,
}
