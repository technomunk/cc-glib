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

--- Check if the provided collection contains provided element
--- @param col table collection to search for provided item
--- @param el any element for which to search the said collection
--- @return boolean found the element is part of provided collection
local function contains(col, el)
	assert(type(col) == "table", "contain requires a collection")
	for i, v in ipairs(col) do
		if v == el then
			return true
		end
	end
	return false
end

local YES_VALUES = {"y", "yes", "+"}
local NO_VALUES = {"n", "no", "-"}

--- Prompt the user for a yes/no answer
--- @param default boolean|nil the default value if the user just presses enter
--- @return boolean yes whether the user answered "yes"
local function promptYesNo(default)
	if default == nil then
		io.write("[y/n]")
	elseif default then
		io.write("[Y/n]")
	else
		io.write("[y/N]")
	end

	local ans = nil
	repeat
		ans = io.read():lower()
	until (ans == "" and default ~= nil) or contains(YES_VALUES, ans) or contains(NO_VALUES, ans)
	return (ans == "" and default ~= nil) or contains(YES_VALUES, ans)
end

--- Ask the user a yes/no question
--- @param question string the question prompt to ask the user
--- @param default boolean|nil the default value if the user just presses enter
--- @return boolean yes whether the user answered "yes"
local function ask(question, default)
	io.write(question)
	return promptYesNo(default)
end

--- Print the progress bar on the screen
--- @param done number amount of work done
--- @param total number|nil total amount of work to be done (or 1)
local function printProgress(done, total)
	total = total or 1.0
	local color = term.getTextColor()
	term.clearLine()
	term.setTextColor(colors.yellow)
	term.write(string.format("%d/%d", done, total))
	term.setTextColor(colors.magenta)
	term.write(string.format(" %2d%%", done / total * 100))
	term.setTextColor(color)
	local x, y = term.getCursorPos()
	term.setCursorPos(1, y)
end

--- Get both the minimal and the maximal values from the provided arguments
--- @param x number
--- @param ... number
--- @return number min
--- @return number max
local function minmax(x, ...)
	local min = math.min(x, unpack(arg))
	local max = math.max(x, unpack(arg))
	return min, max
end

return {
	first = first,
	last = last,
	contains = contains,
	promptYesNo = promptYesNo,
	ask = ask,
	printProgress = printProgress,
	minmax = minmax,
}
