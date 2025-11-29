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

return {
    confirm = confirm
}
