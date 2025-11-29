local chat = peripheral.find("chatBox")
local name = os.getComputerLabel()

--- Inform the user about something
--- @param message string
local function inform(message)
    if chat then
        chat.sendMessage(message, name, "<>")
    else
        print(message)
    end
end

--- Assert the condition and inform the user of the error if it's false
--- @generic T
--- @param condition T
--- @param message? string
--- @return T
local function errorIfNot(condition, message)
    if not condition then
        if message then
            inform(message)
        end
        error(message)
    end
    return condition
end

return {
    inform = inform,
    errorIfNot = errorIfNot,
}
