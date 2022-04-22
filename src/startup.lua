--- Run the command found in .resume file if it exists

local file = io.open(".resume", "r")

if not file then
	return
end

local command = file:read()
io.close(file)

shell.run(command)
