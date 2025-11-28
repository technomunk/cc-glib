--- Collection of utilities for managing turtle inventory

--- Find the slot with the provided item name
--- @param name string the full qualified name of the item to search for
--- @return number|nil slot containing the item or nil if the turtle doesn't have the provided item
local function find(name)
    for slot in 1,16 do
        local info = turtle.getItemDetail(slot)
        if info.name == name then
            return slot
        end
    end
    return nil
end

return {
    find = find
}
