local inv = require("lib.inventory")
local prompt = require("lib.prompt")
local persist = require("lib.persist")
local dig = require("lib.dig")

local bucketSlot = inv.find("minecraft:bucket")

--- @class Config
--- @field torchSlot number|nil
--- @field chestPresent boolean
--- @return Config
local function setup()
    local detected, info = turtle.inspectDown()

    local result = {
        chestPresent = detected and info.name == "minecraft:chest",
        torchSlot = inv.find("minecraft:torch")
    }

    assert(result.chestPresent or prompt.confirm("Continue without chest?"))
    assert(bucketSlot or prompt.confirm("Continue without a bucket?"))
    assert(result.torchSlot or prompt.confirm("Continue without torches?"))

    return result
end


---@type Config
local config = persist.wrap({...}, setup, "config")
local state = persist.wrap({ ... }, { workPos = 0, curPos = 0 }, "state")

local function forth()
    if turtle.forward() then
        state.curPos = state.curPos + 1
        state.workPos = math.max(state.workPos, state.curPos)
        persist.persist(state, "state")
        return true
    end
    return false
end

local function back()
    if turtle.back() then
        state.curPos = state.curPos - 1
        persist.persist(state, "state")
        return true
    end
    return false
end

local function goHome()
    for z = state.curPos, 1, -1 do
        assert(back())
    end
end

local function goToWork()
    for z = state.curPos, state.workPos - 1 do
        assert(forth())
    end
end

local function dumpItems()
    for slot = 1, 16 do
        if slot ~= bucketSlot and slot ~= config.torchSlot and turtle.getItemCount(slot) ~= 0 then
            turtle.select(slot)
            assert(turtle.dropDown(), "chest is full!")
        end
    end
end

local function ensureInventorySpace()
    if turtle.getItemCount(16) ~= 0 then
        goHome()
        dumpItems()
        goToWork()
    end
end

local function step()
    dig.digOrScoop(0)
    ensureInventorySpace()
    if not forth() then
        goHome()
        error("Couldn't continue")
    end
    dig.digOrScoop(1)
    ensureInventorySpace()
    dig.digOrScoop(-1)
    ensureInventorySpace()
end

local function attemptTorch()
    if config.torchSlot == nil then return true end
    if turtle.getItemCount(config.torchSlot) > 1 then
        turtle.select(config.torchSlot)
        turtle.placeDown()
        return true
    end
    return false
end

persist.writeStartup()
ensureInventorySpace()
local steps = state.curPos
while true do
    if steps % 10 == 9 then
       if not attemptTorch() then break end
    end
    step()
    steps = steps + 1
end

goHome()
dumpItems()
persist.cleanup()
print("Done!")
