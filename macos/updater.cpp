// Path of Building
//
// macOS update helper: applies the runtime part of an update once the application has exited,
// then starts the application again. Windows uses Update.exe.
//
// It carries out the operations file itself, as src/UpdateApply.lua does, so that it loads no
// library the update might replace. Launch.lua starts it as:
//   Update UpdateApply.lua Update/opFileRuntime.txt
//
#include <spawn.h>
#include <sys/stat.h>
#include <unistd.h>

#include <cstdio>
#include <fstream>
#include <regex>
#include <string>
#include <vector>

extern char** environ;

// Windows holds the helper back with file locks until the application has gone. macOS has none.
static void waitForApplicationToExit()
{
	const pid_t application = getppid();
	for (int tenths = 0; tenths < 300 && getppid() == application; ++tenths) {
		usleep(100000);
	}
}

static std::string withSpaces(std::string path)
{
	static const std::string marker = "{space}";
	for (auto at = path.find(marker); at != std::string::npos; at = path.find(marker, at)) {
		path.replace(at, marker.size(), " ");
	}
	return path;
}

// Replaces the file in one step, keeping its permissions, so a launcher stays executable.
static bool moveFile(const std::string& from, const std::string& to)
{
	std::ifstream in(from, std::ios::binary);
	if (!in) {
		fprintf(stderr, "couldn't open %s\n", from.c_str());
		return false;
	}
	const std::string staged = to + ".updating";
	std::ofstream out(staged, std::ios::binary | std::ios::trunc);
	out << in.rdbuf();
	out.close();
	if (!out) {
		fprintf(stderr, "couldn't write %s\n", staged.c_str());
		return false;
	}
	struct stat existing;
	if (stat(to.c_str(), &existing) == 0) {
		chmod(staged.c_str(), existing.st_mode);
	}
	if (rename(staged.c_str(), to.c_str()) != 0) {
		fprintf(stderr, "couldn't replace %s\n", to.c_str());
		return false;
	}
	remove(from.c_str());
	return true;
}

static void start(const std::string& target)
{
	// An application inside a bundle is opened as the bundle, so that it comes to the front.
	std::vector<std::string> args{ target };
	const auto bundleEnd = target.find(".app/Contents/MacOS/");
	if (bundleEnd != std::string::npos) {
		args = { "/usr/bin/open", "-n", target.substr(0, bundleEnd + 4) };
	}
	std::vector<char*> argv;
	for (std::string& arg : args) {
		argv.push_back(arg.data());
	}
	argv.push_back(nullptr);
	pid_t pid;
	posix_spawn(&pid, argv[0], nullptr, nullptr, argv.data(), environ);
}

int main(int argc, char** argv)
{
	if (argc < 3) {
		fprintf(stderr, "Usage: Update UpdateApply.lua <operations file>\n");
		return 1;
	}
	waitForApplicationToExit();

	std::vector<std::string> lines;
	{
		std::ifstream operations(argv[2]);
		for (std::string line; std::getline(operations, line);) {
			lines.push_back(line);
		}
	}
	remove(argv[2]);

	static const std::regex two(R"re((\w+) "(.*)" "(.*)")re"), one(R"re((\w+) "(.*)")re");
	for (const std::string& line : lines) {
		std::smatch match;
		if (std::regex_match(line, match, two) && match[1] == "move") {
			moveFile(match[2], withSpaces(match[3]));
		} else if (std::regex_match(line, match, one) && match[1] == "delete") {
			remove(match[2].str().c_str());
		} else if (std::regex_match(line, match, one) && match[1] == "start") {
			start(withSpaces(match[2]));
		}
	}
	return 0;
}
