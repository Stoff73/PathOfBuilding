// Path of Building
//
// macOS launcher: finds the launch script, loads the host library named on its
// first line and runs the script in it. Windows uses PathOfBuilding-Launcher.
//
#import <Cocoa/Cocoa.h>

#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <spawn.h>
#include <unistd.h>

#include <climits>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

namespace fs = std::filesystem;

extern char** environ;

// A pob:// link. Windows passes one as the first argument. macOS sends it as an event, which arrives
// once the host has started the application's event loop, by when the arguments have been handed over.
static std::vector<std::string> startArgs;
static bool startedWithLink = false;
static NSDate* startTime = nil;

@interface LinkReceiver : NSObject
@end

@implementation LinkReceiver
- (void)openLink:(NSAppleEventDescriptor*)event withReply:(NSAppleEventDescriptor*)reply
{
	NSString* link = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	if (!link) {
		return;
	}
	// The program reads one link, its first argument after the script, so pass this one alone.
	std::vector<std::string> args;
	for (const std::string& arg : startArgs) {
		if (arg.compare(0, 4, "pob:") != 0) {
			args.push_back(arg);
		}
	}
	args.push_back([link UTF8String]);
	std::vector<char*> argv;
	for (std::string& arg : args) {
		argv.push_back(arg.data());
	}
	argv.push_back(nullptr);
	// The link that opened the application arrives in its first moments, before it has a window:
	// start again with the link as an argument. A link followed later opens in a second copy, as on Windows.
	if (!startedWithLink && [startTime timeIntervalSinceNow] > -5.0) {
		execv(argv[0], argv.data());
	}
	pid_t pid;
	posix_spawn(&pid, argv[0], nullptr, nullptr, argv.data(), environ);
}
@end

// The event loop itself is left to the host, whose start-up installs the menu bar and Quit.
static void receiveLinks(int argc, char** argv)
{
	char path[PATH_MAX];
	uint32_t size = sizeof(path);
	startArgs.push_back(_NSGetExecutablePath(path, &size) == 0 ? path : argv[0]);
	for (int i = 1; i < argc; ++i) {
		startArgs.push_back(argv[i]);
		startedWithLink = startedWithLink || strncmp(argv[i], "pob:", 4) == 0;
	}
	startTime = [[NSDate alloc] init];
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:[[LinkReceiver alloc] init]
		andSelector:@selector(openLink:withReply:)
		forEventClass:kInternetEventClass
		andEventID:kAEGetURL];
}

// Nobody sees standard error when the application is started from Finder.
static int fail(const std::string& message)
{
	fprintf(stderr, "ERROR: %s\n", message.c_str());
	NSAlert* alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Path of Building could not start"];
	[alert setInformativeText:[NSString stringWithUTF8String:message.c_str()]];
	[alert runModal];
	return 1;
}

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
	receiveLinks(argc, argv);

	std::string host;
	fs::path script;
	if (!args.empty() && readHostName(args[0], host)) {
		// The host reads a relative path as relative to the runtime folder, not to where we were started.
		args[0] = fs::canonical(args[0]).string();
	} else {
		if (!findLaunchScript(runtime, script, host)) {
			return fail("Could not find a valid launcher lua file.");
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
		return fail("Could not load '" + library.string() + "': " + dlerror());
	}
	using RunLuaFile = int (*)(int, char**);
	auto run = reinterpret_cast<RunLuaFile>(dlsym(handle, "RunLuaFileAsWin"));
	if (!run) {
		return fail("'" + library.string() + "' does not appear to be a Path of Building library.");
	}

	std::vector<char*> cargs;
	for (std::string& arg : args) {
		cargs.push_back(arg.data());
	}
	return run(static_cast<int>(cargs.size()), cargs.data());
}
