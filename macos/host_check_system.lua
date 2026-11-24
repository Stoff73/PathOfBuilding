-- Path of Building
--
-- The host checks that touch the system: files, the pointer, the clipboard, processes and the network.
-- Loaded by host_check.lua.
--
local check, after, exists, root, tmp, results, sub = ...

check("GetScriptPath, GetRuntimePath, GetUserPath, GetWorkDir, SetWorkDir", function()
	assert(exists(GetScriptPath() .. "/host_check.lua"), "script path " .. tostring(GetScriptPath()))
	assert(exists(GetRuntimePath() .. "/libSimpleGraphic.dylib"), "runtime path " .. tostring(GetRuntimePath()))
	assert(GetUserPath():match("/Documents$"), "user path " .. tostring(GetUserPath()))
	local before = GetWorkDir()
	SetWorkDir(GetRuntimePath())
	assert(GetWorkDir() == GetRuntimePath(), "work dir " .. tostring(GetWorkDir()))
	SetWorkDir(before)
	assert(GetWorkDir() == before)
end)
check("MakeDir, RemoveDir, NewFileSearch and its handle", function()
	assert(MakeDir(tmp) and MakeDir(tmp .. "/sub"))
	local file = io.open(tmp .. "/a.txt", "w")
	file:write("12345")
	file:close()
	local search = NewFileSearch(tmp .. "/*.txt")
	assert(search and search:GetFileName() == "a.txt" and search:GetFileSize() == 5)
	assert(search:GetFileModifiedTime() > 0 and not search:NextFile())
	local dirs = NewFileSearch(tmp .. "/*", true)
	assert(dirs and dirs:GetFileName() == "sub")
	assert(not NewFileSearch(tmp .. "/*.none"))
	os.remove(tmp .. "/a.txt")
	assert(RemoveDir(tmp .. "/sub") and RemoveDir(tmp) and not NewFileSearch(tmp))
end)
check("GetCloudProvider", function()
	assert(GetCloudProvider("/tmp/build.xml") == nil)
	local provider = GetCloudProvider(os.getenv("HOME") .. "/Library/CloudStorage/OneDrive-Personal/build.xml")
	assert(provider == "OneDrive", "provider " .. tostring(provider))
end)
check("Deflate, Inflate", function()
	local text = ("Path of Building "):rep(200)
	local packed = Deflate(text)
	assert(#packed < #text and Inflate(packed) == text)
	assert(Inflate(Deflate(text, true)) == text)
end)
check("GetTime", function()
	local start = GetTime()
	return after({ { 10, function() assert(GetTime() > start) end } })
end)
check("Copy, Paste", function()
	local before = Paste()
	Copy("host check ✓ clipboard")
	assert(Paste() == "host check ✓ clipboard")
	Copy(before or "")
end)
check("GetCursorPos, SetCursorPos, ShowCursor, SetForeground, IsKeyDown, SetWindowTitle", function()
	SetForeground()
	local beforeX, beforeY
	local function expect(x, y)
		local gotX, gotY = GetCursorPos()
		assert(math.abs(gotX - x) <= 1 and math.abs(gotY - y) <= 1, ("asked %d,%d got %d,%d"):format(x, y, gotX, gotY))
	end
	return after({
		{ 30, function() beforeX, beforeY = GetCursorPos() SetCursorPos(100, 60) end },
		{ 10, function() expect(100, 60) SetCursorPos(333, 211) end },
		{ 10, function() expect(333, 211) SetCursorPos(beforeX, beforeY) end },
		{ 1, function()
			ShowCursor(false)
			ShowCursor(true)
			assert(IsKeyDown("CTRL") == false and IsKeyDown("LEFTBUTTON") == false)
			SetWindowTitle("Path of Building host check (title set)")
		end },
	})
end)
check("ConPrintf, ConPrintTable, ConExecute, ConClear, SetProfiling", function()
	ConPrintf("host check %d %s", 1, "ok")
	ConPrintTable({ a = 1, b = { c = 2 } })
	ConExecute("set vid_resizable 3")
	ConClear()
	SetProfiling(true)
	SetProfiling(false)
end)
check("SpawnProcess", function()
	SpawnProcess("/usr/bin/touch", '"' .. tmp .. ' spawned"')
	return function()
		if not exists(tmp .. " spawned") then
			return false
		end
		os.remove(tmp .. " spawned")
		return true
	end, 5
end)
check("LaunchSubScript, IsSubScriptRunning, OnSubCall, OnSubFinished, lcurl.safe over HTTPS", function()
	local id = LaunchSubScript([[
		local url = ...
		local curl = require("lcurl.safe")
		local body = ""
		local easy = curl.easy()
		easy:setopt_url(url)
		easy:setopt_writefunction(function(data) body = body .. data return true end)
		local _, err = easy:perform()
		local code = easy:getinfo(curl.INFO_RESPONSE_CODE)
		easy:close()
		Progress("downloaded", #body)
		return code, #body, err and err:msg(), GetScriptPath()
	]], "GetScriptPath", "Progress", "https://raw.githubusercontent.com/PathOfBuildingCommunity/PathOfBuilding/dev/manifest.cfg")
	assert(id and type(IsSubScriptRunning(id)) == "boolean")
	return function()
		if not sub.finished then
			return false
		end
		local _, code, size, err, scriptPath = unpack(sub.finished)
		assert(code == 200 and size > 0, ("code %s size %s error %s"):format(tostring(code), tostring(size), tostring(err)))
		assert(sub.calls.Progress and sub.calls.Progress[1] == "downloaded" and sub.calls.GetScriptPath, "OnSubCall was not called for Progress and GetScriptPath")
		assert(scriptPath == GetScriptPath(), "subscript's GetScriptPath gave " .. tostring(scriptPath))
		return true
	end, 30
end)
check("OnSubError, AbortSubScript", function()
	LaunchSubScript("error('deliberate')", "", "")
	local id
	return after({
		{ 60, function()
			assert(sub.error and tostring(sub.error[2]):find("deliberate"), "no OnSubError")
			id = LaunchSubScript("local t = os.clock() while os.clock() - t < 20 do end", "", "")
		end },
		{ 10, function() assert(IsSubScriptRunning(id), "the looping subscript is not running") AbortSubScript(id) end },
		-- Once a subscript has gone its ID is no longer valid, and asking about it is an error.
		{ 60, function() local ok, running = pcall(IsSubScriptRunning, id) assert(not ok or not running, "still running after AbortSubScript") end },
	})
end)
check("lzip", function()
	local zip = assert(require("lzip").open(root .. "/runtime-win32.zip"))
	local file = assert(zip:OpenFile("Update.exe"))
	assert(#file:Read("*a") == 171008)
	file:Close()
	zip:Close()
end)
check("lua-utf8", function()
	local utf8 = require("lua-utf8")
	assert(utf8.len("héllo ✓") == 7 and utf8.upper("é") == "É")
end)
check("socket", function()
	local server = assert(require("socket").tcp4())
	assert(server:bind("localhost", 0))
	server:close()
end)
table.insert(results, "INFO by hand: OpenURL, Restart, key and mouse callbacks, full screen and resizing")
