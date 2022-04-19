-- Download the glib files to provided directory

--- Save the provided string contents into a file with provided name
--- @param filename string
--- @param content string
local function saveFile(filename, content)
	local file = fs.open(filename, "w")
	assert(file, "could not open "..filename)
	file.write(content)
	file.close()
end

local args = {...}

local dir = args[1] or "glib"

if dir:sub(#dir) ~= "/" then
	dir = dir.."/"
end

local json = require("json")

local response = http.get("https://api.github.com/repos/technomunk/cc-glib/contents/src")
assert(response.getResponseCode() == 200, "failed to get repository contents")

local files = json.decode(response.readAll())
local expectedFiles = {}

for _, file in ipairs(files) do
	assert(file["type"], "unsupported file type: "..file["type"])
	http.request(file["download_url"])
	expectedFiles[file["download_url"]] = dir..file["name"]
end

local downloaded, failed = 0, 0

while (downloaded + failed) < #expectedFiles do
	local eventData = os.pullEvent()
	local event = eventData[1]
	local url, err

	if event == "http_success" then
		url, response = eventData[2], eventData[3]
		saveFile(expectedFiles[url], response.readAll())
		downloaded = downloaded + 1
	elseif event == "http_failure" then
		url, err = eventData[2], eventData[3]
		print("couldn't download "..expectedFiles[url]..": "..err)
		failed = failed + 1
	end
end

print("downloaded "..downloaded.."/"..#expectedFiles.." files")
