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

local response = http.get("https://api.github.com/repos/technomunk/cc-glib/contents/src")
assert(response.getResponseCode() == 200, "failed to get repository contents")

local files = textutils.unserializeJSON(response.readAll())
local filenames = {}
local expectedFiles = 0

for _, file in ipairs(files) do
	assert(file["type"], "unsupported file type: "..file["type"])
	http.request(file["download_url"])
	filenames[file["download_url"]] = dir..file["name"]
	expectedFiles = expectedFiles + 1
end

local downloaded, failed = 0, 0

while (downloaded + failed) < expectedFiles do
	local event, url, response = os.pullEvent()

	if event == "http_success" then
		saveFile(filenames[url], response.readAll())
		downloaded = downloaded + 1
	elseif event == "http_failure" then
		print("couldn't download "..filenames[url]..": "..response)
		failed = failed + 1
	end
end

print("downloaded "..downloaded.."/"..expectedFiles.." files")
