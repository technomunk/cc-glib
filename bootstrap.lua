-- Get all the relevant files from the repository

local args = {...}
local outDir = (args[0] or "glib").."/"

if not fs.exists("json.lua") then
	shell.run("wget", "https://raw.githubusercontent.com/rxi/json.lua/master/json.lua")
end

local json = require("json")

local response = http.get("https://api.github.com/repos/technomunk/cc-glib/contents/src")
assert(response.getResponseCode() == 200, "failed to get repository contents")

local files = json.decode(response.readAll())
for _, file in ipairs(files) do
	assert(file["type"], "unsupported file type: "..file["type"])
	shell.run("wget", file["download_url"], outDir..file["name"])
end
