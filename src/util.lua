-- General language utilities

-- Get Nth element of a string or array
local function nth(col, idx)
	assert(type(idx) == "number", "nth requires an index")
	local ty = type(col)
	assert(ty == "table" or ty == "string", "nth expects string or array")
	if #ty == 0 then
		return nil
	end
	if ty == "table" then
		return col[idx]
	elseif ty == "string" then
		return col:sub(idx, idx)
	end
end

-- Get the first element of a string or array
local function first(col)
	return nth(col, 1)
end

-- Get the last element of a string or array
local function last(col)
	return nth(col, #col)
end

-- Get the index of the first occurance of the provided
-- element in the provided string or array
local function index(col, el, cmp)
	if not cmp then
		cmp = function(a, b) return a == b end
	end
	local ty = type(col)
	if ty == "string" then
		col:find(el)
	elseif ty == "table" then
		for i, v in ipairs(col) do
			if cmp(v, el) then
				return i
			end
		end
		return nil
	else
		error("index expects string or array")
	end
end

-- Check if the provided collection contains provided element
local function contains(col, el)
	assert(type(col) == "table", "contain requires a collection")
	for i, v in ipairs(col) do
		if v == el then
			return true
		end
	end
	return false
end

-- Prompt the user for a yes/no answer
local function promptYesNo()
	io.write("(y/n)")
	local ans = nil
	repeat
		ans = io.read()
	until ans == 'y' or ans == 'yes' or ans == 'n' or ans == 'no'
	return ans == 'y' or ans == 'yes'
end

-- Ask the user a yes/no question
local function ask(question)
	io.write(question)
	return promptYesNo()
end

return {
	last = last,
	first = first,
	last = last,
	contains = contains,
	promptYesNo = promptYesNo,
	ask = ask,
}
