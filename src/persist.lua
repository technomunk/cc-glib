--- Persist the given object
local function persist(o)
    local mt = getmetatable(o)
    setmetatable(o, nil)

    local file = fs.open(".persisted", "w+")
    file.write(textutils.serialise(o, { compact = true }))
    file.close()

    local name = shell.getRunningProgram()

    file = fs.open("startup", "w+")
    file.write("shell.execute(")
    file.write(name)
    file.write('"--restore")')
    file.close()

    setmetatable(o, mt)
end

--- Wrapper for persisting a setup table.
--- Note: that the metatable is discarded, so make sure to re-initialize the class after calling persistent!
---
--- @nodiscard
--- @generic T
--- @param args string[]
--- @param setup fun(args: string[]):T
--- @return T
local function wrap(args, setup)
    local result
    if args[1] == "--restore" then
        local file = fs.open(".persisted", "r")
        result = textutils.unserialize(file.readAll())
        file.close()
    else
        result = setup(args)
    end
    result.persist = persist
    return result
end

return {
    wrap = wrap
}
