local nav = require("nav")
local inv = require("inventory")
local block = require("block")
local prompt = require("prompt")
local chat = require("chat")

local bucketSlot = inv.find("minecraft:bucket")
local torchSlot = inv.find("minecraft:torch")
local detected, info = turtle.inspectDown()

local chestPresent = detected and info.name == "minecraft:chest"

chat.errorIfNot(chestPresent or prompt.confirm("Continue without chest?"))
chat.errorIfNot(bucketSlot or prompt.confirm("Continue without a bucket?"))
chat.errorIfNot(torchSlot or prompt.confirm("Continue without torches?"))

local torchCount = 0
if torchSlot then
    torchCount = turtle.getItemCount(torchSlot)
end

nav = nav.new()

local function dumpItems()
    for slot = 1, 16 do
        if slot ~= bucketSlot and turtle.getItemCount(slot) ~= 0 then
            turtle.select(slot)
            chat.errorIfNot(turtle.dropDown(), "chest is full!")
        end
    end
end

local function returnToDump()
    local x, y, z = nav.x, nav.y, nav.z
    chat.errorIfNot(nav:goTo(0, 0, 0), "failed to return home!")
    dumpItems()
    chat.errorIfNot(nav:goTo(x, y, z), "failed to return to the tunnel")
end

local cooldown = 0

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
            if bucketSlot then
                turtle.select(bucketSlot)
                place()
                turtle.refuel()
            end
        elseif cooldown <= 0 and string.find(info.name, "ore") then
            chat.inform("Hit "..info.name)
            cooldown = 10
        else
            dig()
            cooldown = cooldown - 1
            if block.isAffectedByGravity(info) then
                repeat
                    sleep(0.1)
                    dig()
                until not inspect()
            end
        end
    end
end

local function ensureInventorySpace()
    if turtle.getItemSpace(16) ~= 64 then
        if chestPresent then
            returnToDump()
        else
            chat.inform("Inventory full, returning home")
            nav:goTo(0, 0, 0)
            error("No chest to dump into")
        end
    end
end

local function step()
    digOrScoop(0)
    ensureInventorySpace()
    if not nav:forth() then
        chat.inform("Bumped into something, returning home")
        nav:goTo(0, 0, 0)
        error("Couldn't continue")
    end
    digOrScoop(-1)
    ensureInventorySpace()
    digOrScoop(1)
    ensureInventorySpace()
end

local s = 0
while true do
    step()
    s = s + 1
    if s % 10 == 0 and torchSlot then
        turtle.select(torchSlot)
        if turtle.placeDown() then
            torchCount = torchCount - 1
            if torchCount == 0 then
                break
            end
        end
    end
    if s % 100 == 0 then
        chat.inform("Dug "..s.." blocks!")
    end
end

chat.errorIfNot(nav:goTo(0, 0, 0), "Couldn't return home")
dumpItems()
chat.inform("Done digging!")
