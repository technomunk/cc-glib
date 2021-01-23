-- Module for interacting with turtle's inventory

-- Check if 2 items are equal
local function eq(a, b)
	return a == b
end

-- Check if the provided collection contains provided item
local function contains(col, it)
	for i, val in ipairs(col) do
		if val == it then
			return true
		end
	end
	return false
end

-- Get the item slot containing provided item(s)
local function slot(items)
	local find = nil
	if type(items) == "string" then
		find = eq
	elseif type(items) == "table" then
		find = find
	else
		error("slot expects item name or array of items")
	end
	for i=1, 16 do
		details = turtle.getItemDetail(i)
		if details and find(items, details.name) then
			return i
		end
	end
	return nil
end

-- Check if the inventory is full
local function is_full()
	for i=1, 16 do
		if turtle.getItemCount(i) == 0 then
			return false
		end
	end
	return true
end

return {
	slot = slot,
	is_full = is_full,
}
