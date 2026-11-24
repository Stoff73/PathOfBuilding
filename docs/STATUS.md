# Status

<!-- Kept by the agents working here: what's built now, how to run it, what isn't built yet, and the log of who did what. Updated all the time, as AGENTS.md sets out. -->

This folder holds Path of Building Community as it stands on its `dev` branch, with no changes of our own to the code yet. The first brief, `docs/briefs/01-macos.md`, asks for the program to run natively on macOS. The owner has confirmed it and approved its plan, `docs/plans/01-macos.md`. The plan is being built on the branch `01-macos`. Phase 1 of 6 is done: the program builds and runs natively on this MacBook from this folder, in Dev Mode. It is not yet an application bundle. Phase 2 of 6 is done as well: the Mac and the CI image pass the same 909 checks, produce identical outputs for the five test builds and regenerate an identical mod cache. The later phases' checks (every host function, every feature, updates) have not been made.

The folder is a git repository on the branch `dev`, tracking `origin/dev` on the fork `https://github.com/Stoff73/PathOfBuilding.git`. The code matches `origin/dev` at `f4a77c589`. The process docs are committed on `dev`. Nothing has been pushed.

## Where work stopped

Phases 1, 2, 4 and 5 of `docs/plans/01-macos.md` are done. Phase 3 is done as far as an agent can take it. Phase 6 has not been started. The session stopped on 2026-11-24 with everything committed on the branch `01-macos` and nothing running.

Phase 6, in order:

1. Make `macos/build.sh` fetch the host's own pinned sources on a fresh checkout, so the written steps are short. `git submodule update --init --depth 1` inside `macos/SimpleGraphic` does not land on the pinned commits, and `dep/compressonator` wants Git LFS, which is not installed. What works, per nested submodule: `git -c filter.lfs.smudge= -c filter.lfs.process= -c filter.lfs.required=false fetch --depth 1 origin <pinned sha>`, then check that commit out.
2. Write the docs: a Mac section in `CONTRIBUTING.md` (build, run, package, test), the publishing steps in `RELEASE.md` (they are in the plan under "Decisions made while building"), `macos/` in `docs/rundown.md`, and in `docs/CODE_STANDARDS.md` the rules that the host's files keep their line endings, most being CRLF, and that the published manifest lives on `macos-release` only.
3. `LICENSE.md`: the Mac runtime links OpenSSL, which Windows does not. The file also does not name GLFW, zlib, zstd, libwebp, luasocket, luautf8, sol2, imgui, glm or compressonator, some of which Windows ships too.
4. Write the owner's demonstration checklist as `docs/macos-demonstration.md`. It carries every line the plan leaves open: the by-hand lines of parity checklist part A, all of parts B and C, the fatal error alert, trackpad scrolling, dragging the window between the two displays, a real `pob://` link, and pressing the Update button.
5. Verify: a fresh clone built from the written steps alone (the host submodule has to come from this folder's copy, because its commits are not pushed); the suite on the Mac with `macos/build/rocks/bin/busted --exclude-pattern=TestTreeTab` and in the CI image, including `TestUpdateCheck_spec.lua`, which has only been run on the Mac; and `git diff --stat origin/dev -- runtime runtime-win32.zip manifest.xml` printing nothing.
6. The demonstration with the owner, then the plan's "Lessons".

What the next agent needs to know that the code does not say:

- Send no synthetic key or mouse input to the desktop (decision 22). Windows can be captured without input: `screencapture -x -o -l <window id>`.
- Ask the owner before every push. Nothing goes to the host fork. `macos-release` is pushed, at `ef674adcd`. `01-macos` and the docs commit on local `dev` are not pushed.
- Docker Desktop hung twice here and strains this 16 GB Mac. Start it with `open -g -a Docker`, put a hard time limit on every `docker` command, and quit it when the run is done.
- `macos/build/` is ignored by git and holds things that are costly to remake: the vcpkg build tree, busted in `rocks/`, `hedit.py` for edits to the host that keep its line endings, and `test/Path of Building.app`, an installed copy at the second release.
- Starting the packaged application creates `~/Documents/Path of Building/`. It is there now, holding an empty `Builds` folder. `src/Builds/` holds three test builds copied for testing; git ignores it.

## Running it

- The application: `./runtime/Path{space}of{space}Building.exe`, a Windows executable. Run from this folder it starts in Dev Mode, as `CONTRIBUTING.md` describes.
- Headless, from the command line: `cd src && LUA_PATH='../runtime/lua/?.lua;../runtime/lua/?/init.lua;./?.lua;./?/init.lua' luajit HeadlessWrapper.lua < /dev/null`. Without the last two path entries it fails to find `Data.PearlSupports`; on an error it waits for a key press, hence `< /dev/null`.
- The tests: `docker-compose up` from the root, or `busted --lua=luajit` with LuaJIT and busted installed.
- On this machine the specs run two ways: in the CI image with Docker, and natively with `macos/build/rocks/bin/busted`, which is busted 2.2.0 installed by LuaRocks for the LuaJIT in `macos/build/host/vcpkg_installed/x64-osx-pob/tools/luajit/`. Both give 909 passing checks and no failures when `spec/System/TestTreeTab_spec.lua` is excluded; that file has a check that never finishes, on both, as it does in upstream's CI. Add `--exclude-pattern=TestTreeTab` until it is fixed.
- On a Mac: `macos/build.sh` builds the runtime into `macos/runtime/`, then `"macos/runtime/Path of Building"` starts the program in Dev Mode. `python3 macos/package.py` then assembles `macos/build/Path of Building.app`, which runs in installed mode and keeps builds and settings in `~/Documents/Path of Building/`. Until a release is published to the fork's `macos-release` branch it reports "Update check failed" at start, which is harmless. It needs Xcode's command line tools, CMake and Ninja; `CONTRIBUTING.md` has the steps, including installing busted. `macos/build.sh` fetches the host's pinned sources itself. The first build compiles the dependencies and takes about an hour on this MacBook; later builds restore them from vcpkg's cache and take about three minutes. The staged runtime is 27 MB, the build folder 66 MB and the host checkout with vcpkg 425 MB.

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
| `macos/` | The Mac launcher and update helper, the build and packaging scripts, the vcpkg triplet, the host checks, and `macos/SimpleGraphic`, our fork of the host as a submodule with its macOS changes on the local branch `macos`. `docs/rundown.md` lists the files |
| `docs/` | The docs: process templates, this file, the standards and the upstream tutorials |
| `.github/` | CI: tests, the ModCache check, the spell check and the release workflows |

Rules the checks enforce today: every spec passes, `src/Data/ModCache.lua` matches the parser, and changed files pass the spell check. All three run in CI only.

## API

None. This is a desktop application with no HTTP API.

## Not built yet

- macOS support still to do in `docs/plans/01-macos.md`: the owner's demonstration, `docs/macos-demonstration.md`, which carries every check that needs a person at the keyboard and trackpad, and a key for screenshots on the MacBook's own keyboard, which waits on the owner's decision.
- The pre-commit hook and the 200-line file check that the plan template and the standards refer to.

## Log

<!-- Newest first. Append-only: never rewrite or remove another agent's line. Time comes from `date`. -->

| Date | Time | Agent | What was done | Brief or plan |
|---|---|---|---|---|
| 2026-11-24 | 15:44 GMT | Claude Code (claude-fable-5-2) | Stopped at the owner's request so the session's context can be cleared. Wrote "Where work stopped" in this file: the six steps of phase 6, in order, and what the next agent needs to know. Everything is committed on `01-macos`; nothing is running. | `docs/plans/01-macos.md` phase 6 |
| 2026-11-24 | 15:42 GMT | Claude Code (claude-fable-5-2) | Phase 5. With the owner's go-ahead, pushed a new branch `macos-release` to `Stoff73/PathOfBuilding` twice: a first release, then the real tree as an update to it. An installed copy of the first found the second, staged the changed Lua file and the new launcher, and after the apply steps were run from the shell the launcher was replaced, still executable, and the application restarted and reported no further update. The test build in Documents kept its checksum. Not done: pressing the Update button, which is left for the demonstration, and the updater spec in the CI image. `dev` on GitHub is untouched and nothing was pushed to the host fork. | `docs/plans/01-macos.md` phase 5 |
| 2026-11-24 | 14:53 GMT | Claude Code (claude-fable-5-2) | Built phase 4 and the update code. `macos/package.py` assembles `Path of Building.app`; it runs in installed mode, keeps builds and settings in Documents, opens a Windows-saved build with the right figures, quits normally and handles `pob://` links. Mac-saved builds give identical outputs in the CI image. Wrote the update helper, three changes to `UpdateCheck.lua` with a spec that passes on the Mac, and macOS support in `update_manifest.py`. Found that GitHub serves upstream's `master` for the fork, so the Mac application now follows `macos-release` and refuses any release without a Mac runtime (decisions 23 to 25). Not done: every feature by hand, a real link import, and publishing. | `docs/plans/01-macos.md` phases 4 and 5 |
| 2026-11-24 | 13:46 GMT | Claude Code (claude-fable-5-2) | Phase 3, part done. Host changes for macOS committed in the submodule: starting a process, the Documents folder, cloud provider names, on-screen fatal errors, the screenshot folder, pointer position in pixels, trackpad scrolling, Option + arrow, and ANGLE's layer following the display's scale. Fixed three host faults that only showed on the Mac (`lzip` field width, file search on folders, a dropped error message). Wrote `macos/host_check.lua`: 25 checks pass on both displays. Not done: the checks that need key and mouse input, the fatal error alert seen on screen, and the performance figures. While testing with synthetic input, two clicks and six scroll steps went to the owner's Chrome window, which was in front of the test window; synthetic input is stopped until the owner says how to proceed. | `docs/plans/01-macos.md` phase 3 |
| 2026-11-24 | 12:53 GMT | Claude Code (claude-fable-5-2) | Finished phase 2. The owner decided that `TestTreeTab_spec.lua` is an accepted exception and that the Mac is judged against the CI image (decisions 20 and 21); the brief and plan record the change. Wrote `macos/dump_build_outputs.lua`: 4,398 calculated outputs across the five test builds are identical on the Mac and in the CI image at 17 significant digits. With the 909 matching checks and the byte-identical mod cache, all four phase 2 criteria are ticked. Docker Desktop hung twice during this work and was restarted; it is now quit. | `docs/plans/01-macos.md` phase 2 |
| 2026-11-24 | 08:58 GMT | Claude Code (claude-fable-5-2) | Measured phase 2. Mac and CI image both pass 909 checks with none failing, excluding `TestTreeTab_spec.lua`, which never finishes on either (nor reliably in upstream's CI). The regenerated mod cache is byte-identical on the Mac and in the CI image, and both add 24 entries the committed file lacks. The stored test-build outputs date from 2022 and no longer match the code anywhere; the Mac-against-CI-image comparison that replaces them is half done, because the system stopped the run when memory ran low. Phase 2 is not ticked: three criteria need the owner's decision. Corrected the headless command in the standards. Installed LuaRocks with Homebrew and busted into `macos/build/rocks`. No code changed. | `docs/plans/01-macos.md` phase 2 |
| 2026-11-23 | 21:03 GMT | Claude Code (claude-fable-5-2) | Built phase 1. Created the fork `Stoff73/PathOfBuilding-SimpleGraphic` and added it as the submodule `macos/SimpleGraphic`; its macOS changes are committed on the local branch `macos` and not pushed. Wrote `macos/build.sh`, `macos/launcher.cpp` and the vcpkg triplet. The program now starts natively in Dev Mode, opens a Windows-saved test build and draws the tree, Calcs tab and build list correctly. Switched to ANGLE's OpenGL backend because the Iris Pro lacks the Metal level ANGLE needs (decision 19). Fixed a LuaJIT patch crash and text missing on Retina. All six criteria ticked. Test builds copied to `src/Builds/`, which git ignores, for later phases. | `docs/plans/01-macos.md` phase 1 |
| 2026-11-23 | 14:26 GMT | Claude Code (claude-fable-5-2) | The owner approved the plan and answered its eight questions. Recorded the answers in the plan and in `docs/DECISIONS.md` (decisions 16 to 18 added, the rest marked approved). Committed the process docs to `dev` and cut the branch `01-macos`. Nothing pushed. | `docs/plans/01-macos.md` |
| 2026-11-23 | 12:19 GMT | Claude Code (claude-fable-5-2) | Wrote the plan for macOS after reading the upstream host and launcher sources (cloned to a scratch folder, not into this repository) and this repository's launch and update code. Six phases, a parity checklist and eight questions for the owner. Created `docs/DECISIONS.md` with its 15 decisions. Recorded the owner's decision that shortcuts use Ctrl in the brief. Waiting for the owner's review. No code changed. | `docs/plans/01-macos.md` |
| 2026-11-23 | 12:19 GMT | Claude Code (claude-fable-5-2) | The owner confirmed the brief, adding that shortcuts use Ctrl. | `docs/briefs/01-macos.md` |
| 2026-11-23 | 11:55 GMT | Claude Code (claude-fable-5-2) | Wrote the brief for running natively on macOS, from the owner's request and their answers: native app, this Intel MacBook only, updates from the fork, exporter stays on Windows. Waiting for the owner to confirm it. No code changed. | `docs/briefs/01-macos.md` |
| 2026-11-23 | 11:45 GMT | Claude Code (claude-fable-5-2) | Put the folder under git: initialised it, added the fork as `origin`, fetched `dev` and pointed the local `dev` at `origin/dev` (`f4a77c589`) without changing any file. The code matched exactly; only the process docs are untracked. Nothing committed or pushed. | None: setup |
| 2026-11-23 | 11:35 GMT | Claude Code (claude-fable-5-2) | Created `AGENTS.md` with the brief, plan and build process. Rewrote `docs/CODE_STANDARDS.md` for this codebase. Rewrote this file to describe the codebase and added this log. No code changed. | None: docs only |
