-- Build a wall

local args = {...}

local w, h = tonumber(args[1]), tonumber(args[2])
assert(w, "width required")
h = h or w

local itemCount = 0
local slots = {}

for i = 1, 16 do
	if turtle.compareTo(i) then
		table.insert(slots, i)
		itemCount = itemCount + turtle.getItemCount(i)
	end
end

assert(itemCount >= h * w, "not enough blocks!")

turtle.select(table.remove(slots))
local function place()
	if turtle.getItemCount() == 0 then
		turtle.select(table.remove(slots))
	end
	turtle.place()
end

local up = true

local function goUpOrDown()
	if up then
		assert(turtle.up())
	else
		assert(turtle.down())
	end
end

for x = 1, w do
	place()
	for y = 2, h do
		goUpOrDown()
		place()
	end
	up = not up
	if x < w then
		turtle.turnRight()
		assert(turtle.forward())
		turtle.turnLeft()
	end
end

if not up then
	for y = 2, h do
		turtle.down()
	end
end

print("Done")
