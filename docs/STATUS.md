# Status

<!-- Kept by the agents working here: what's built now, how to run it, what isn't built yet, and the log of who did what. Updated all the time, as AGENTS.md sets out. -->

This folder holds Path of Building Community as it stands on its `dev` branch, with no changes of our own to the code yet. The first brief, `docs/briefs/01-macos.md`, asks for the program to run natively on macOS. The owner has confirmed it and approved its plan, `docs/plans/01-macos.md`. The plan is being built on the branch `01-macos`. Phase 1 of 6 is done: the program builds and runs natively on this MacBook from this folder, in Dev Mode. It is not yet an application bundle, and the later phases' checks (specs, every host function, every feature, updates) have not been made.

The folder is a git repository on the branch `dev`, tracking `origin/dev` on the fork `https://github.com/Stoff73/PathOfBuilding.git`. The code matches `origin/dev` at `f4a77c589`. The process docs are committed on `dev`. Nothing has been pushed.

## Running it

- The application: `./runtime/Path{space}of{space}Building.exe`, a Windows executable. Run from this folder it starts in Dev Mode, as `CONTRIBUTING.md` describes.
- Headless, from the command line: `cd src && LUA_PATH='../runtime/lua/?.lua;../runtime/lua/?/init.lua' luajit HeadlessWrapper.lua`.
- The tests: `docker-compose up` from the root, or `busted --lua=luajit` with LuaJIT and busted installed.
- On this machine Docker is installed; `lua`, `luajit` and `busted` are not. The tests have not been run here yet.
- On a Mac: `macos/build.sh` builds the runtime into `macos/runtime/`, then `"macos/runtime/Path of Building"` starts the program in Dev Mode. It needs Xcode's command line tools, CMake and Ninja. The first build compiles the dependencies and takes about an hour on this MacBook; later builds restore them from vcpkg's cache and take about three minutes. The staged runtime is 27 MB, the build folder 66 MB and the host checkout with vcpkg 425 MB.

## What's built

`docs/rundown.md` describes the files one by one. It predates some of them.

| Folder | Its job |
|---|---|
| `src/Modules/` | 36 modules: the program's modes (`Main`, `Build`, `BuildList`), the calculation engine (`Calc*.lua`), modifier parsing (`ModParser`, `ModTools`), data loading (`Data`) and shared helpers (`Common`, `Utils`) |
| `src/Classes/` | 79 classes: the UI controls and tabs, and the model behind them (`Item`, `ModDB`, `ModList`, `PassiveSpec`, `PassiveTree`) |
| `src/Data/` | Game data: gems, skills, item bases, uniques, mods and `ModCache.lua`. Mostly generated |
| `src/Export/` | The exporter: reads the game's files and writes `src/Data` |
| `src/TreeData/` | Passive tree data and images, by game version |
| `src/Assets/` | Images used by the UI |
| `spec/` | The busted specs in `spec/System`, and saved test builds in `spec/TestBuilds` |
| `tests/` | The test for `fix_ascendancy_positions.py` |
| `runtime/` | The Windows host binaries and vendored Lua libraries |
| `macos/` | The Mac launcher, the build script and its vcpkg triplet, and `macos/SimpleGraphic`, our fork of the host as a submodule with its macOS changes on the local branch `macos` |
| `docs/` | The docs: process templates, this file, the standards and the upstream tutorials |
| `.github/` | CI: tests, the ModCache check, the spell check and the release workflows |

Rules the checks enforce today: every spec passes, `src/Data/ModCache.lua` matches the parser, and changed files pass the spell check. All three run in CI only.

## API

None. This is a desktop application with no HTTP API.

## Not built yet

- macOS support beyond phase 1 of `docs/plans/01-macos.md`: the specs on the Mac, the host functions that are still stubs (starting a process, cloud provider names, on-screen error messages, the global cursor position), trackpad scrolling and cursor checks, the application bundle, `pob://` links, and updates from the fork.
- The pre-commit hook and the 200-line file check that the plan template and the standards refer to.

## Log

<!-- Newest first. Append-only: never rewrite or remove another agent's line. Time comes from `date`. -->

| Date | Time | Agent | What was done | Brief or plan |
|---|---|---|---|---|
| 2026-11-23 | 21:03 GMT | Claude Code (claude-fable-5-2) | Built phase 1. Created the fork `Stoff73/PathOfBuilding-SimpleGraphic` and added it as the submodule `macos/SimpleGraphic`; its macOS changes are committed on the local branch `macos` and not pushed. Wrote `macos/build.sh`, `macos/launcher.cpp` and the vcpkg triplet. The program now starts natively in Dev Mode, opens a Windows-saved test build and draws the tree, Calcs tab and build list correctly. Switched to ANGLE's OpenGL backend because the Iris Pro lacks the Metal level ANGLE needs (decision 19). Fixed a LuaJIT patch crash and text missing on Retina. All six criteria ticked. Test builds copied to `src/Builds/`, which git ignores, for later phases. | `docs/plans/01-macos.md` phase 1 |
| 2026-11-23 | 14:26 GMT | Claude Code (claude-fable-5-2) | The owner approved the plan and answered its eight questions. Recorded the answers in the plan and in `docs/DECISIONS.md` (decisions 16 to 18 added, the rest marked approved). Committed the process docs to `dev` and cut the branch `01-macos`. Nothing pushed. | `docs/plans/01-macos.md` |
| 2026-11-23 | 12:19 GMT | Claude Code (claude-fable-5-2) | Wrote the plan for macOS after reading the upstream host and launcher sources (cloned to a scratch folder, not into this repository) and this repository's launch and update code. Six phases, a parity checklist and eight questions for the owner. Created `docs/DECISIONS.md` with its 15 decisions. Recorded the owner's decision that shortcuts use Ctrl in the brief. Waiting for the owner's review. No code changed. | `docs/plans/01-macos.md` |
| 2026-11-23 | 12:19 GMT | Claude Code (claude-fable-5-2) | The owner confirmed the brief, adding that shortcuts use Ctrl. | `docs/briefs/01-macos.md` |
| 2026-11-23 | 11:55 GMT | Claude Code (claude-fable-5-2) | Wrote the brief for running natively on macOS, from the owner's request and their answers: native app, this Intel MacBook only, updates from the fork, exporter stays on Windows. Waiting for the owner to confirm it. No code changed. | `docs/briefs/01-macos.md` |
| 2026-11-23 | 11:45 GMT | Claude Code (claude-fable-5-2) | Put the folder under git: initialised it, added the fork as `origin`, fetched `dev` and pointed the local `dev` at `origin/dev` (`f4a77c589`) without changing any file. The code matched exactly; only the process docs are untracked. Nothing committed or pushed. | None: setup |
| 2026-11-23 | 11:35 GMT | Claude Code (claude-fable-5-2) | Created `AGENTS.md` with the brief, plan and build process. Rewrote `docs/CODE_STANDARDS.md` for this codebase. Rewrote this file to describe the codebase and added this log. No code changed. | None: docs only |
