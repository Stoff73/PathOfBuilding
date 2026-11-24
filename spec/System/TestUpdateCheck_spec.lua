-- Runs src/UpdateCheck.lua against a made-up release with the network and zip library stubbed.
-- Pass: each platform asks only for its own files, from its own source
-- Fail: a Windows install changes what it downloads, or a Mac install is handed Windows runtime files
describe("UpdateCheck", function()
	local sha1 = require("sha1")
	local lfs = require("lfs")

	local remoteContent = {
		["changelog.txt"] = "new changes",
		["Launch.lua"] = "new launch",
		["lua/xml.lua"] = "new xml",
		["SimpleGraphic.dll"] = "new windows host",
		["Path{space}of{space}Building.exe"] = "windows launcher",
		["libSimpleGraphic.dylib"] = "new mac host",
		["Path of Building"] = "mac launcher",
	}
	local function fileNode(name, part, extra)
		return ('<File name="%s" part="%s" sha1="%s"%s />'):format(name, part, sha1(remoteContent[name]), extra or "")
	end
	local sources = [[
		<Source part="default" url="http://upstream/" />
		<Source part="runtime" platform="win32" url="http://upstream/runtime/" />
		<Source part="program" url="http://upstream/src/" />
		<Source part="default" platform="macos" url="http://fork/" />
		<Source part="runtime" platform="macos" url="http://fork/runtime-macos.zip" />
		<Source part="program" platform="macos" url="http://fork/src/" />]]
	local remoteManifest = '<PoBVersion><Version number="9.9.9" />' .. sources
		.. fileNode("changelog.txt", "default") .. fileNode("Launch.lua", "program") .. fileNode("lua/xml.lua", "runtime")
		.. fileNode("SimpleGraphic.dll", "runtime", ' runtime="win32"')
		.. fileNode("Path{space}of{space}Building.exe", "runtime", ' runtime="win32"')
		.. fileNode("libSimpleGraphic.dylib", "runtime", ' platform="macos"')
		.. fileNode("Path of Building", "runtime", ' platform="macos"') .. "</PoBVersion>"

	local function writeFile(path, content)
		local file = assert(io.open(path, "wb"))
		file:write(content)
		file:close()
	end

	-- Sets up an installed copy that is one version behind, runs the update check and reports what it did.
	local function runUpdateCheck(platform, launcher, hostLibrary, remote)
		remote = remote or remoteManifest
		local root = os.tmpname()
		os.remove(root)
		for _, dir in ipairs({ "", "/script", "/runtime", "/runtime/lua" }) do
			lfs.mkdir(root .. dir)
		end
		local function oldNode(name, part)
			return ('<File name="%s" part="%s" sha1="%s" />'):format(name, part, sha1("old"))
		end
		writeFile(root .. "/script/manifest.xml", ('<PoBVersion><Version number="9.9.8" platform="%s" branch="master" />'):format(platform) .. sources
			.. oldNode("changelog.txt", "default") .. oldNode("Launch.lua", "program") .. oldNode("lua/xml.lua", "runtime")
			.. oldNode(hostLibrary, "runtime") .. fileNode(launcher, "runtime") .. "</PoBVersion>")
		writeFile(root .. "/runtime/" .. launcher:gsub("{space}", " "), remoteContent[launcher])

		local requested, unzipped = { }, { }
		local curl = { }
		function curl.easy()
			local easy = { }
			function easy:escape(text) return text end
			function easy:setopt_url(url) self.url = url end
			function easy:setopt() end
			function easy:setopt_writefunction(sink) self.sink = sink end
			function easy:close() end
			function easy:perform()
				table.insert(requested, self.url)
				local name = self.url:match("^http://[^/]+/(.*)$")
				local body = name == "manifest.xml" and remote or remoteContent[name:gsub("^src/", ""):gsub("^runtime/", "")] or "zip"
				if type(self.sink) == "function" then
					self.sink(body)
				else
					self.sink:write(body)
				end
				return true
			end
			return easy
		end
		local lzip = { }
		function lzip.open()
			return {
				OpenFile = function(_, name)
					table.insert(unzipped, name)
					return { Read = function() return remoteContent[name] end, Close = function() end }
				end,
				Close = function() end,
			}
		end

		local env = setmetatable({
			require = function(name)
				return name == "lcurl.safe" and curl or name == "lzip" and lzip or require(name)
			end,
			ConPrintf = function() end,
			GetScriptPath = function() return root .. "/script" end,
			GetRuntimePath = function() return root .. "/runtime" end,
			MakeDir = function(path) lfs.mkdir(path:sub(1, 1) == "/" and path or root .. "/script/" .. path) end,
		}, { __index = _G })
		local mode, errMsg = setfenv(assert(loadfile("UpdateCheck.lua")), env)()

		local function read(name)
			local file = io.open(root .. "/script/Update/" .. name, "r")
			local text = file and file:read("*a") or ""
			return text, file and file:close()
		end
		local result = { mode = mode, errMsg = errMsg, requested = table.concat(requested, "\n"), unzipped = table.concat(unzipped, "\n"),
			operations = read("opFile.txt") .. "\n" .. read("opFileRuntime.txt"), newManifest = read("manifest.xml") }
		os.execute('rm -rf "' .. root .. '"')
		return result
	end

	it("gives a Windows install the files it has always had, from upstream", function()
		local result = runUpdateCheck("win32", "Path{space}of{space}Building.exe", "SimpleGraphic.dll")
		assert.are.equal("basic", result.mode)
		for _, url in ipairs({ "http://upstream/manifest.xml", "http://upstream/changelog.txt", "http://upstream/src/Launch.lua",
			"http://upstream/runtime/lua/xml.lua", "http://upstream/runtime/SimpleGraphic.dll" }) do
			assert.is_truthy(result.requested:find(url, 1, true), "did not request " .. url)
		end
		assert.is_nil(result.requested:find("fork", 1, true))
		assert.is_nil(result.operations:find("dylib", 1, true))
		assert.is_nil(result.newManifest:find("dylib", 1, true))
		assert.is_truthy(result.operations:find('start ".*/runtime/Path of Building.exe"'))
	end)

	it("gives a Mac install only Mac files, from the fork", function()
		local result = runUpdateCheck("macos", "Path of Building", "libSimpleGraphic.dylib")
		assert.are.equal("basic", result.mode)
		for _, url in ipairs({ "http://fork/manifest.xml", "http://fork/changelog.txt", "http://fork/src/Launch.lua", "http://fork/runtime-macos.zip" }) do
			assert.is_truthy(result.requested:find(url, 1, true), "did not request " .. url)
		end
		assert.is_nil(result.requested:find("upstream", 1, true))
		assert.is_truthy(result.unzipped:find("libSimpleGraphic.dylib", 1, true))
		assert.is_truthy(result.unzipped:find("lua/xml.lua", 1, true))
		for _, text in ipairs({ result.requested, result.unzipped, result.operations, result.newManifest }) do
			assert.is_nil(text:find("%.dll"))
			assert.is_nil(text:find("%.exe"))
		end
		assert.is_truthy(result.operations:find('start ".*/runtime/Path of Building"'))
	end)

	-- GitHub serves upstream's branch when the fork has none of that name, so this can really happen
	it("refuses a release that has no build for the platform", function()
		local windowsOnly = remoteManifest:gsub('<Source [^>]-platform="macos"[^>]-/>', "")
		local result = runUpdateCheck("macos", "Path of Building", "libSimpleGraphic.dylib", windowsOnly)
		assert.is_nil(result.mode)
		assert.is_truthy(result.errMsg:find("platform", 1, true))
		assert.are.equal("\n", result.operations)
	end)
end)
