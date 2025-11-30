local name = os.getComputerLabel()
local chat = peripheral.find("chatBox")

if not chat then
    for slot = 1,16 do
        local detail = turtle.getItemDetail(slot)
        if detail and detail.name == "advancedperipherals:chat_box" then
            chat = slot
            break
        end
    end
end

--- Inform the user about something
--- @param message string
local function inform(message)
    if type(chat) == "table" then
        chat.sendMessage(message, name, "<>")
    elseif type(chat) == "number" then
        turtle.select(chat)
        turtle.equipRight()
        peripheral.wrap("right").sendMessage(message, name, "<>")
        turtle.equipRight()
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
