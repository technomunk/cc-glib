local nav = require("nav")
local inv = require("inventory")

local bucketSlot = assert(inv.find("minecraft:bucket"), "missing a bucket to refuel with")
local detected, info = turtle.inspectDown()

local chat = peripheral.find("chatBox")
local name = os.getComputerLabel()

assert(detected and info.name == "minecraft:chest", "need a chest to deposit into")

nav = nav.new()

local function inform(message)
    if chat then
        chat.sendMessage(message, name, "<>")
    else
        print(message)
    end
end

local function informAndStopOnFail(condition, message)
    if not condition then
        inform("error: " .. message)
    end
    os.exit(false)
end

local function dumpItems()
    for slot = 1, 16 do
        if slot ~= bucketSlot and turtle.getItemCount(slot) ~= 0 then
            turtle.select(slot)
            informAndStopOnFail(turtle.dropDown(), "chest is full!")
        end
    end
end

local function returnToDump()
    local x, y, z = nav.x, nav.y, nav.z
    informAndStopOnFail(nav:goTo(0, 0, 0), "failed to return home!")
    dumpItems()
    informAndStopOnFail(nav:goTo(x, y, z), "failed to return to the tunnel")
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
            if info.name == "minecraft:gravel" or info.name == "minecraft:sand" then
                repeat
                    sleep(0.2)
                    dig()
                until not inspect()
            end
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
    informAndStopOnFail(nav:forth(), "bumped into something")
    digOrScoop(-1)
    ensureInventorySpace()
    digOrScoop(1)
    ensureInventorySpace()
end

for _ = 1, 256 do
    step()
end
informAndStopOnFail(nav:goTo(0, 0, 0), "Couldn't return home")
dumpItems()
inform("Done digging!")
