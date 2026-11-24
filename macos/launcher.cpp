// Path of Building
//
// macOS launcher: finds the launch script, loads the host library named on its
// first line and runs the script in it. Windows uses PathOfBuilding-Launcher.
//
#include <dlfcn.h>
#include <mach-o/dyld.h>

#include <climits>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

namespace fs = std::filesystem;

// A launch script starts with "#@ <host library>".
static bool readHostName(const fs::path& script, std::string& host)
{
	std::ifstream file(script);
	std::string line;
	if (!file || !std::getline(file, line)) {
		return false;
	}
	if (line.rfind("\xEF\xBB\xBF", 0) == 0) {
		line.erase(0, 3);
	}
	if (line.rfind("#@", 0) != 0) {
		return false;
	}
	const auto first = line.find_first_not_of(" \t\r", 2);
	const auto last = line.find_last_not_of(" \t\r");
	host = first == std::string::npos ? "" : line.substr(first, last - first + 1);
	return true;
}

static fs::path runtimeDir()
{
	char path[PATH_MAX];
	uint32_t size = sizeof(path);
	if (_NSGetExecutablePath(path, &size) != 0) {
		return fs::current_path();
	}
	return fs::canonical(path).parent_path();
}

static bool findLaunchScript(const fs::path& runtime, fs::path& script, std::string& host)
{
	const fs::path candidates[] = {
		runtime / "Launch.lua",
		runtime / "src/Launch.lua",
		runtime / "../Resources/Launch.lua", // inside the application bundle
		runtime / "../src/Launch.lua",       // <repository>/runtime
		runtime / "../../src/Launch.lua",    // <repository>/macos/runtime
	};
	for (const fs::path& candidate : candidates) {
		if (readHostName(candidate, host)) {
			script = fs::canonical(candidate);
			return true;
		}
	}
	return false;
}

int main(int argc, char** argv)
{
	const fs::path runtime = runtimeDir();
	std::vector<std::string> args(argv + 1, argv + argc);

	std::string host;
	fs::path script;
	if (!args.empty() && readHostName(args[0], host)) {
		// The host reads a relative path as relative to the runtime folder, not to where we were started.
		args[0] = fs::canonical(args[0]).string();
	} else {
		if (!findLaunchScript(runtime, script, host)) {
			fprintf(stderr, "ERROR: Could not find a valid launcher lua file.\n");
			return 1;
		}
		args.insert(args.begin(), script.string());
	}

	// LuaJIT has no executable-relative search path on macOS, so name the runtime folder.
	const std::string base = runtime.string();
	setenv("LUA_PATH", (base + "/lua/?.lua;" + base + "/lua/?/init.lua;./?.lua;./?/init.lua").c_str(), 1);
	setenv("LUA_CPATH", (base + "/?.so").c_str(), 1);

	const fs::path library = runtime / ("lib" + host + ".dylib");
	void* handle = dlopen(library.c_str(), RTLD_NOW | RTLD_GLOBAL);
	if (!handle) {
		fprintf(stderr, "ERROR: Could not load '%s': %s\n", library.c_str(), dlerror());
		return 1;
	}
	using RunLuaFile = int (*)(int, char**);
	auto run = reinterpret_cast<RunLuaFile>(dlsym(handle, "RunLuaFileAsWin"));
	if (!run) {
		fprintf(stderr, "ERROR: '%s' does not appear to be a Path of Building library.\n", library.c_str());
		return 1;
	}

	std::vector<char*> cargs;
	for (std::string& arg : args) {
		cargs.push_back(arg.data());
	}
	return run(static_cast<int>(cargs.size()), cargs.data());
}
