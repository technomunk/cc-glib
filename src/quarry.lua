local nav = require("nav")
local prompt = require("prompt")
local inv = require("inventory")
local persist = require("persist")

local function setup(args)
    local result = {}

    result.tx = assert(tonumber(args[1]), "need width")
    result.tz = tonumber(args[2]) or result.tx

    result.bucketSlot = inv.find("minecraft:bucket")

    local detected, info = turtle.inspectUp()
    result.chestPresent = detected and info.name == "minecraft:chest"

    assert(result.chestPresent or prompt.confirm("Continue without chest?"))
    assert(result.bucketSlot or prompt.confirm("Continue without a bucket?"))

    prompt.confirm("Quarry " .. result.tx .. "x" .. result.tz .. " area?")
    return result
end

local quarry = persist.wrap({ ... }, setup)

quarry = nav.new(quarry)
local meta = getmetatable(quarry)
-- monkeypatch onUpdate to persist the quarry
meta.__index.onUpdate = persist.persist

local function dumpInventory()
    for slot = 1, 16 do
        if slot ~= quarry.bucketSlot then
            turtle.select(slot)
            assert(turtle.dropUp())
        end
    end
    turtle.select(1)
end

local function dumpItemsAtBase()
    local cp = quarry:checkpoint()
    local cpv = { x = cp.x, y = 0, z = cp.z }
    assert(quarry:goTo(cpv))
    assert(quarry:goTo(0, 0, 0))
    dumpInventory()
    assert(quarry:goTo(cp))
end

local function ensureInventorySpace()
    if turtle.getItemSpace(16) == 64 then
        return
    end
    dumpItemsAtBase()
end

local function tryScoop(dir)
    local place, inspect
    if dir == -1 then
        place, inspect = turtle.placeDown, turtle.inspectDown
    elseif dir == 0 then
        place, inspect = turtle.place, turtle.inspect
    else
        place, inspect = turtle.placeUp, turtle.inspectUp
    end

    local detected, info = inspect()
    if detected and info.name == "minecraft:lava" then
        turtle.select(quarry.bucketSlot)
        place()
        turtle.refuel()
        return true
    end
    return false
end

local function digOrScoop(dir)
    local dig
    if dir == -1 then
        dig = turtle.digDown
    elseif dir == 0 then
        dig = turtle.dig
    else
        dig = turtle.digUp
    end

    if quarry.bucketSlot and not tryScoop(dir) then
        ensureInventorySpace()
        dig()
    end
end

local function digLine()
    for z = quarry.z, quarry.tz - 1, quarry.dz do
        digOrScoop(-1)
        digOrScoop(1)
        local nextZ = z + quarry.dz
        if nextZ == 0 or nextZ == quarry.tz - 1 then
            return true
        end
        digOrScoop(0)
        if not quarry:forth() then
            return false
        end
    end
    return true
end

local function digLayer(dx)
    local turn
    if dx > 0 then
        turn = quarry.turnRight
    else
        turn = quarry.turnLeft
    end

    for x = quarry.x, quarry.tx, dx do
        if not digLine() then
            return false
        end
        local nextX = x + dx
        if nextX == 0 or nextX == quarry.tx - 1 then
            return true
        end
        turn(quarry)
        digOrScoop(0)
        if not quarry:forth() then
            return false
        end
        turn(quarry)
    end
    return true
end

local dx = 1
if quarry:isAt(0, 0, 0) then
    turtle.digDown()
    quarry:down()
else
    if quarry.dz == 0 then
        dx = quarry.dx
        digOrScoop(0)
        assert(quarry:forth())
        if dx == 1 then
            quarry:turnRight()
        else
            quarry:turnLeft()
        end
    end
end

while digLayer(dx) do
    dx = -dx
    for _ = 1, 2 do
        digOrScoop(-1)
        quarry:down()
    end
end

quarry:goTo(0, 0, 0)
dumpInventory()
print("Done!")
