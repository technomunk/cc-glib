local inv = require("inventory")
local completion = require("cc.completion")

local y = 0

local bucketSlot = assert(inv.find("minecraft:bucket"), "No bucket for refueling")
local curSlot = turtle.getSelectedSlot()
local curSlotItems = 0

local function ensureHaveItems()
    if curSlotItems ~= 0 then return end
    for slot = 1, 16 do
        if slot ~= bucketSlot then
            curSlotItems = turtle.getItemCount(slot)
            curSlot = slot
            if curSlotItems ~= 0 then
                return
            end
        end
    end
    error("Out of items")
end

local function placeWall()
    local detected, info = turtle.inspect()
    if detected and info.name == "minecraft:lava" then
        turtle.select(bucketSlot)
        turtle.place()
        turtle.refuel()
    end

    turtle.select(curSlot)
    if turtle.place() then
        curSlotItems = curSlotItems - 1
        ensureHaveItems()
    end
end

local function placeWallsAllAround()
    for _ = 1,4 do
        placeWall()
        turtle.turnLeft()
    end
end

local function step()
    local detected, info = turtle.inspectDown()
    if detected and info.name == "minecraft:lava" then
        turtle.select(bucketSlot)
        turtle.placeDown()
        turtle.refuel()
    end
end

write("current y:")
local cur_y = read()

for _ = cur_y, 16, -1 do
    step()
end

for _ = 16,cur_y do
    turtle.up()
end
print("Done!")
