-- Path of Building
--
-- Prints every calculated output of every build in spec/TestBuilds, at full precision,
-- one per line, so that two platforms' output can be compared with diff.
-- Run from src/:  luajit ../macos/dump_build_outputs.lua | grep '^OUT' | sort
--
dofile("HeadlessWrapper.lua")

-- The outputs nest two levels at most (such as MainHand.AverageDamage); anything deeper is shared game data.
local maxDepth = 3

local function dump(prefix, value, depth)
	if type(value) == "table" then
		if depth >= maxDepth then
			return
		end
		for key, child in pairs(value) do
			if type(key) == "string" or type(key) == "number" then
				dump(prefix .. "." .. tostring(key), child, depth + 1)
			end
		end
	elseif type(value) == "number" then
		print(("OUT\t%s\t%.17g"):format(prefix, value))
	elseif type(value) == "string" or type(value) == "boolean" then
		print(("OUT\t%s\t%s"):format(prefix, tostring(value)))
	end
end

local lfs = require("lfs")
local root = "../spec/TestBuilds"
for version in lfs.dir(root) do
	if version:sub(1, 1) ~= "." and lfs.attributes(root .. "/" .. version, "mode") == "directory" then
		for file in lfs.dir(root .. "/" .. version) do
			if file:match("%.xml$") then
				local handle = assert(io.open(root .. "/" .. version .. "/" .. file, "r"))
				loadBuildFromXML(handle:read("*a"), file)
				handle:close()
				dump(version .. "/" .. file, build.calcsTab.mainOutput, 0)
			end
		end
	end
end
