-- Get all the relevant files from the repository

local args = {...}

if not fs.exists("json.lua") then
	shell.run("wget", "https://raw.githubusercontent.com/rxi/json.lua/master/json.lua")
end

if not fs.exists("download.lua") then
	shell.run("wget", "https://raw.githubusercontent.com/technomunk/cc-glib/main/download.lua")
end

shell.run("download.lua", args[1])
