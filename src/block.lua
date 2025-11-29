local blocksAffectedByGravity = {
    ["minecraft:sand"] = true,
    ["minecraft:gravel"] = true,
    ["minecraft:red_sand"] = true
}

--- Check whether the provided block is affected by gravity
--- @param info {name:string}|string
--- @return boolean affected
local function isAffectedByGravity(info)
    local name = info.name or info
    return blocksAffectedByGravity[name] or false
end

return {
    isAffectedByGravity = isAffectedByGravity
}
