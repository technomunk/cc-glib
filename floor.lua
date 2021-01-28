-- Build a wall

local args = {...}

local l, w = tonumber(args[1]), tonumber(args[2])
assert(l, "length required")
w = w or l

local itemCount = 0
local slots = {}

for i = 1, 16 do
	if turtle.compareTo(i) then
		table.insert(slots, i)
		itemCount = itemCount + turtle.getItemCount(i)
	end
end

assert(itemCount >= l * w, "not enough blocks!")

turtle.select(table.remove(slots))
local function place()
	if turtle.getItemCount() == 0 then
		turtle.select(table.remove(slots))
	end
	turtle.placeDown()
end

local right = true

local function turnLeftOrRight()
	if right then
		turtle.turnRight()
	else
		turtle.turnLeft()
	end
end

for x = 1, w do
	place()
	for z = 2, l do
		assert(turtle.forward())
		place()
	end
	if x < w then
		turnLeftOrRight()
		assert(turtle.forward())
		turnLeftOrRight()
		right = not right
	end
end

print("Done")
