#@ SimpleGraphic
-- Path of Building
--
-- Calls every host function that needs no person and prints PASS or FAIL for each.
-- Run it through the launcher:  "macos/runtime/Path of Building" macos/host_check.lua
-- It draws a test card for a few seconds, moves the pointer and uses the clipboard, then restores both.
--
local root = GetScriptPath() .. "/.."
local tmp = os.tmpname() .. "-pob"
local results, failed = { }, 0
local sub = { calls = { } }

-- A check runs in one frame, or returns a poll function (and a time limit in seconds)
-- that is called every frame until it returns true. An error in either fails the check.
local steps = { }
local function check(name, func)
	table.insert(steps, { name = name, func = func })
end
local function record(name, ok, err)
	failed = failed + (ok and 0 or 1)
	table.insert(results, (ok and "PASS " or "FAIL ") .. name .. (ok and "" or ": " .. tostring(err)))
end
-- Returns a poll function that runs each stage's function after its number of frames.
local function after(stages)
	local stage, frames = 1, 0
	return function()
		frames = frames + 1
		if frames >= stages[stage][1] then
			stages[stage][2]()
			stage, frames = stage + 1, 0
		end
		return stage > #stages
	end
end
local function exists(path)
	local file = io.open(path, "rb")
	return file and (file:close() or true) or false
end

local image, art, card = NewImageHandle(), nil, false
local drawCard = LoadModule("host_check_card", image)

do
	check("SetCallback, GetCallback", function()
		local marker = function() end
		SetCallback("OnHostCheck", marker)
		assert(GetCallback("OnHostCheck") == marker)
	end)
	check("LoadModule, PLoadModule, PCall", function()
		assert(LoadModule("../runtime/lua/base64").encode("hi") == "aGk=")
		local err, mod = PLoadModule("../runtime/lua/base64")
		assert(not err and mod.decode)
		assert(PLoadModule("no-such-module"))
		assert(PCall(error, "boom"):find("boom"))
		local none, sum = PCall(function(a, b) return a + b end, 2, 3)
		assert(not none and sum == 5)
	end)
	check("GetScreenSize, GetScreenScale", function()
		local w, h = GetScreenSize()
		assert(w > 0 and h > 0 and GetScreenScale() >= 1)
		table.insert(results, ("INFO screen %dx%d scale %g"):format(w, h, GetScreenScale()))
	end)
	check("image: Load ASYNC, IsLoading, IsValid, ImageSize, SetLoadingPriority, GetAsyncCount", function()
		local png = root .. "/src/Assets/ring.png"
		local head = io.open(png, "rb"):read(24)
		local function be(i) return head:byte(i) * 16777216 + head:byte(i + 1) * 65536 + head:byte(i + 2) * 256 + head:byte(i + 3) end
		image:Load(png, "ASYNC", "CLAMP")
		image:SetLoadingPriority(1)
		assert(type(image:IsLoading()) == "boolean" and GetAsyncCount() >= 0)
		return function()
			if image:IsLoading() then
				return false
			end
			local w, h = image:ImageSize()
			assert(image:IsValid() and w == be(17) and h == be(21), ("size %sx%s, file says %dx%d"):format(w, h, be(17), be(21)))
			return true
		end, 10
	end)
	-- LoadArtRectangle is not called: on every platform it copies each row once per pixel of width and overruns its buffer.
	check("art: NewArtHandle, Size, LoadArtArcBand", function()
		art = NewArtHandle(root .. "/src/Assets/ring.png")
		local w, h = art:Size()
		assert(w > 0 and h > 0)
		local band = NewImageHandle()
		band:LoadArtArcBand(art, math.floor(w / 2), math.floor(h / 2), 1, math.floor(w / 2) - 1)
		return after({ { 5, function() assert(band:IsValid()) end } })
	end)
	check("Texture: new, Allocate, IsValid, Info, Save, Load, StackTextures", function()
		local a, b, stack, back = Texture.new(), Texture.new(), Texture.new(), Texture.new()
		assert(a:Allocate("RGBA", 4, 4, 1, 1) and b:Allocate("RGBA", 4, 4, 1, 1) and a:IsValid() and a:Info())
		assert(stack:StackTextures({ a, b }) and stack:IsValid())
		assert(a:Save(tmp .. ".dds") and back:Load(tmp .. ".dds") and back:IsValid())
		os.remove(tmp .. ".dds")
	end)
	-- SetBlendMode is declared in src/_SimpleGraphic.def.lua but no host provides it, on Windows or macOS.
	check("drawing: SetClearColor, SetDrawLayer, GetDrawLayer, SetViewport, SetDrawColor, GetDrawColor, DrawImage, DrawImageQuad, DrawString", function()
		assert(SetBlendMode == nil, "the host now provides SetBlendMode; add it to the test card")
		SetClearColor(0, 0, 0, 1)
		SetDrawLayer(3, 2)
		assert(GetDrawLayer() == 2, "GetDrawLayer returns the sub-layer; got " .. tostring(GetDrawLayer()))
		SetDrawColor(0.25, 0.5, 0.75, 1)
		local r, g, b, a = GetDrawColor()
		assert(math.abs(r - 0.25) < 0.01 and math.abs(g - 0.5) < 0.01 and math.abs(b - 0.75) < 0.01 and a == 1)
		card = true
		return after({ { 240, function() end } })
	end)
	check("DrawStringWidth, DrawStringCursorIndex, StripEscapes", function()
		local width = DrawStringWidth(16, "VAR", "Hello")
		assert(width > 0 and DrawStringWidth(32, "VAR", "Hello") > width)
		local index = DrawStringCursorIndex(16, "VAR", "Hello", width / 2, 8)
		assert(index >= 2 and index <= 5, "index " .. index)
		assert(StripEscapes("^1red^x00FF00green") == "redgreen")
	end)
	check("SetDPIScaleOverridePercent, GetDPIScaleOverridePercent", function()
		local before = GetDPIScaleOverridePercent()
		SetDPIScaleOverridePercent(150)
		assert(GetDPIScaleOverridePercent() == 150)
		SetDPIScaleOverridePercent(before)
	end)
	LoadModule("host_check_system", check, after, exists, root, tmp, results, sub)
	check("TakeScreenshot", function()
		local folder = GetUserPath() .. "/Path of Building/Screenshots/"
		local function files()
			local names, search = { }, NewFileSearch(folder .. "*")
			while search do
				names[search:GetFileName()] = true
				if not search:NextFile() then break end
			end
			return names
		end
		local before = files()
		TakeScreenshot()
		return function()
			for name in pairs(files()) do
				if not before[name] then
					os.remove(folder .. name)
					return true
				end
			end
			return false
		end, 5
	end)
	check("image: Unload", function()
		card = false
		image:Unload()
		assert(not image:IsValid())
	end)
end

local main = { }
local current, poll, deadline = 0, nil, nil
function main:OnInit()
	SetWindowTitle("Path of Building host check")
	ConExecute("set vid_mode 8")
	RenderInit("DPI_AWARE")
end
function main:OnFrame()
	if card then
		drawCard()
	end
	if poll then
		local ok, finished = pcall(poll)
		if not ok or finished or GetTime() > deadline then
			record(steps[current].name, ok and finished, ok and "timed out" or finished)
			poll = nil
		end
	elseif current < #steps then
		current = current + 1
		local ok, nextPoll, seconds = pcall(steps[current].func)
		if ok and nextPoll then
			poll, deadline = nextPoll, GetTime() + (seconds or 30) * 1000
		else
			record(steps[current].name, ok, nextPoll)
		end
	elseif not main.done then
		main.done = true
		Exit()
	end
end
-- As Launch.lua does: a subscript's call to a host function arrives here to be made on its behalf.
function main:OnSubCall(name, ...)
	sub.calls[name] = { ... }
	if _G[name] then
		return _G[name](...)
	end
end
function main:OnSubError(id, message) sub.error = { id, message } end
function main:OnSubFinished(id, ...) sub.finished = { id, ... } end
function main:CanExit() main.canExitAsked = true return true end
function main:OnExit()
	table.insert(results, ("INFO screen at exit %dx%d scale %g"):format(GetScreenSize(), select(2, GetScreenSize()), GetScreenScale()))
	table.insert(results, (main.canExitAsked and "PASS" or "INFO not asked:") .. " callbacks: OnInit, OnFrame, CanExit, OnExit")
	print(table.concat(results, "\n"))
	print(("%d failed"):format(failed))
end
SetMainObject(main)
