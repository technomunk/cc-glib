--- @param name? string
--- @return string
local function stateName(name)
    return ".s" .. (name or "")
end

--- Persist the given object
--- @param object table
--- @param name? string
local function persist(object, name)
    local mt = getmetatable(object)
    setmetatable(object, nil)

    local file = fs.open(stateName(name), "w+")
    file.write(textutils.serialise(object, { compact = true }))
    file.close()

    setmetatable(object, mt)
end

--- Start the current program as startup. Intended to be used along with wrap() and persist() helpers
local function writeStartup()
    local file = fs.open("startup", "w+")
    file.write('shell.execute("')
    file.write(shell.getRunningProgram())
    file.write('", "--restore")')
    file.close()
end

--- Wrapper for persisting a setup table.
--- Note: that the metatable is discarded, so make sure to re-initialize the class after calling persistent!
---
--- @nodiscard
--- @generic T: table
--- @param args string[]
--- @param init T|fun(args: string[]):T
--- @param name? string
--- @return T
local function wrap(args, init, name)
    local result
    if args[1] == "--restore" then
        local file = fs.open(stateName(name), "r")
        result = textutils.unserialize(file.readAll())
        file.close()
    else
        if type(init) == "function" then
            result = init(args)
        else
            result = init
        end
        persist(result, name)
    end
    return result
end

local function cleanup()
    fs.remove("startup")
end

return {
    wrap = wrap,
    persist = persist,
    writeStartup = writeStartup,
    cleanup = cleanup,
}
