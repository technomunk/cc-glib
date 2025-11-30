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

local dir = args[1] or "./"

if dir:sub(#dir) ~= "/" then
	dir = dir.."/"
end

local requests = {}
local pendingRequests = 0

local function requestAllFilesInDir(resp)
	local files = textutils.unserializeJSON(resp.readAll())
	for _, file in ipairs(files) do
		if file["type"] == "file" then
			local filename = string.sub(file["path"], 5)
			requests[file["download_url"]] = dir..filename
			pendingRequests = pendingRequests + 1
			http.request(file["download_url"])
		elseif file["type"] == "dir" then
			local filename = string.sub(file["path"], 5)
			fs.makeDir(dir..filename)
			url = "https://api.github.com/repos/technomunk/cc-glib/contents/"..file["path"]
			requests[url] = true
			pendingRequests = pendingRequests + 1
			http.request(url)
		else
			printError("Unknown file type:", file[type])
		end
	end
end

local resp = http.get("https://api.github.com/repos/technomunk/cc-glib/contents/src")
assert(resp.getResponseCode() == 200, "failed to get repository contents")

requestAllFilesInDir(resp)

local downloaded = 0

while pendingRequests > 0 do
	local event, url, resp = os.pullEvent()

	if event == "http_success" then
		if type(requests[url]) == "boolean" then
			requestAllFilesInDir(resp)
			downloaded = downloaded + 1
			pendingRequests = pendingRequests - 1
		elseif requests[url] then
			saveFile(requests[url], resp.readAll())
			downloaded = downloaded + 1
			pendingRequests = pendingRequests - 1
		end
	elseif event == "http_failure" then
		print("couldn't download "..requests[url]..": "..resp)
	end
end

print("downloaded", downloaded, "files")
