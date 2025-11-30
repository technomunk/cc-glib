local answers = {
    ["y"] = true,
    ["yes"] = true,
    ["+"] = true,
    ["n"] = false,
    ["no"] = false,
    ["-"] = false
}

--- Get user confirmation
--- @param message string
--- @param default? boolean the default answer if the answer is empty
--- @return boolean confirmed
local function confirm(message, default)
    write(message)
    if default == nil then
        write(" [y/n]")
    elseif default then
        write(" [Y/n]")
    else
        write(" [y/N]")
    end

    local answer
    repeat
        answer = read()
        if string.len(answer) == 0 then
            answer = default
        else
            answer = answers[answer]
        end
    until answer ~= nil

    --- @cast answer boolean
    return answer
end

--- Prompt the user for some input
--- @generic T
--- @param message string
---@param transform fun(input: string):T
local function prompt(message, transform)
    write(message)
    local result = nil
    while result == nil do
        result = transform(read())
        if result == nil then
            write("Invalid input, try again:")
        end
    end
    return result
end

return {
    confirm = confirm,
    prompt = prompt,
}
