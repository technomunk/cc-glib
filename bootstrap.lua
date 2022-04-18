-- Get all the relevant files from the repository

local args = {...}
local outDir = (args[0] or "gnet").."/"

shell.run("wget", "https://raw.githubusercontent.com/rxi/json.lua/master/json.lua", "json")

local json = require("json")

local response = http.get("https://api.github.com/repos/technomunk/cc-glib/contents/src")
assert(response.getResponseCode() == 200, "failed to get repository contents")

local files = json.decode(response.readAll())
for _, file in ipairs(files) do
	assert(file["type"], "unsupported file type: "..file["type"])
	local name = file["name"]
	name = name:sub(1, (name:find("%.lua") or 0) - 1)
	shell.run("wget", file["download_url"], outDir..name)
end
