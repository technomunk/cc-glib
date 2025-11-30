--- @alias YDirection -1|0|1

local inv = require("inventory")

local bucketSlot = inv.find("minecraft:bucket")

--- Attempt to scoop lava and refuel with it
--- @param dir YDirection
--- @return boolean
local function tryScoopRefuel(dir)
    local place, inspect
    if dir == -1 then
        place, inspect = turtle.placeDown, turtle.inspectDown
    elseif dir == 1 then
        place, inspect = turtle.placeUp, turtle.inspectUp
    else
        place, inspect = turtle.place, turtle.inspect
    end

    local detected, info = inspect()
    if detected and info.name == "minecraft:lava" then
        if bucketSlot then
            turtle.select(bucketSlot)
            place()
            turtle.refuel()
        end
        return true
    end

    return false
end

--- Dig or scoop and refuel (if lava is present) in the given direction
--- @param dir YDirection
--- @return number number of blocks dug (or scooped if negative)
local function digOrScoop(dir)
    local dig
    if dir == -1 then
        dig = turtle.digDown
    elseif dir == 1 then
        dig = turtle.digUp
    else
        dig = turtle.dig
    end

    if tryScoopRefuel(dir) then
        return -1
    end
    local count = 0
    while dig() do 
        count = count + 1
    end
    return count
end

return {
    tryScoopRefuel = tryScoopRefuel,
    digOrScoop = digOrScoop,
}
