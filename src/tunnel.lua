local nav = require("nav")
local inv = require("inventory")

local bucketSlot = assert(inv.find("minecraft:bucket"), "missing a bucket to refuel with")
local detected, info = turtle.inspectDown()

assert(detected and info.name == "minecraft:chest", "need a chest to deposit into")

nav = nav.new()

local function dumpItems()
    for slot = 1,16 do
        if slot ~= bucketSlot and turtle.getItemCount(slot) ~= 0 then
            turtle.select(slot)
            assert(turtle.dropDown(), "Chest is full!")
        end
    end
end

local function returnToDump()
    local x, y, z = nav.x, nav.y, nav.z
    assert(nav:goTo(0, 0, 0), "failed to return home!")
    dumpItems()
    assert(nav:goTo(x, y, z), "failed to return to the tunnel")
end

--- @param dir -1|0|1 the direction to dig or scoop in
local function digOrScoop(dir)
    local inspect, dig, place
    if dir == -1 then
        inspect, dig, place = turtle.inspectDown, turtle.digDown, turtle.placeDown
    elseif dir == 0 then
        inspect, dig, place = turtle.inspect, turtle.dig, turtle.place
    else
        inspect, dig, place = turtle.inspectUp, turtle.digUp, turtle.placeUp
    end

    detected, info = inspect()
    if detected then
        if info.name == "minecraft:lava" then
            turtle.select(bucketSlot)
            place()
            turtle.refuel()
        else
            dig()
        end
    end
end

local function ensureInventorySpace()
    if turtle.getItemSpace(16) ~= 64 then
        returnToDump()
    end
end

local function step()
    digOrScoop(0)
    ensureInventorySpace()
    assert(nav:forth())
    digOrScoop(-1)
    ensureInventorySpace()
    digOrScoop(1)
    ensureInventorySpace()
end

for _ = 1,256 do
    step()
end
