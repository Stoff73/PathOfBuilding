# Plan: macos

Builds what `docs/briefs/01-macos.md` asks for. Path of Building becomes a native macOS application on the owner's Intel MacBook: upstream's own graphics host built for macOS, a Mac launcher and updater of our own, an application bundle, and updates served from the fork. The Lua program, the calculations and everything Windows uses stay as they are.

## Approach

Checked against `docs/STATUS.md`, `docs/CODE_STANDARDS.md`, `docs/rundown.md`, `CONTRIBUTING.md`, `RELEASE.md` and the brief. The other docs (`addingMods.md`, `modSyntax.md`, `addingSkills.md`, `calcOffence.md`) cover code this plan does not touch.

What the code shows, which the decisions rest on:

- The Lua program has no Windows-specific code. Everything it needs from the system comes through the host's functions, declared in `src/_SimpleGraphic.def.lua`.
- The host is the upstream repository `PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic`, read at commit `421d188`. It is C++ on portable libraries (GLFW, ANGLE, LuaJIT, curl), and it already has macOS code for finding its own folder and opening URLs, plus a Unix console. Its build, its CI and several functions are still Windows-only.
- The launcher (`PathOfBuildingCommunity/PathOfBuilding-Launcher`, one 391-line file) is written against the Windows API throughout. The source of `Update.exe` is not published.
- The updater's manifest format already supports more than one platform: a `Source` can carry a `platform`, and a `Source` whose URL ends in `.zip` is unpacked file by file.

The decisions:

- **Build upstream's host for macOS; don't write a new one or adopt a third-party frontend.** The same C++ then draws the screen and answers every host function on both platforms, which is the only way to promise the same behaviour. A separate frontend would have to re-prove all of it.
- **Host changes live in a fork of the host repository, pinned here as a git submodule at `macos/SimpleGraphic`.** The changes are to upstream's files, so they need upstream's history under them to stay mergeable. Each is guarded for macOS so the Windows build of the host is unchanged and the work can be offered upstream. The owner has ruled out pushing to the host fork, so the host changes are committed in the submodule on this MacBook only.
- **Everything Mac-specific that we write goes in `macos/`.** Upstream's files in this repository are touched in four places only: `src/UpdateCheck.lua`, `update_manifest.py`, `manifest.xml` and `.gitignore`, plus the docs. That keeps merges from upstream `dev` simple.
- **Dependencies come from the vcpkg manifest already in the host repository, not from Homebrew.** The Mac build then uses the same pinned versions as the Windows build, including the same LuaJIT, which is what makes the numbers match.
- **Draw through ANGLE, as on Windows: its Metal backend first, its OpenGL backend if Metal fails on this hardware.** The renderer is written for OpenGL ES; keeping ANGLE under it means no renderer changes. Phase 1 records which backend works and why.
- **A Mac launcher of our own, `macos/launcher.cpp`.** It does what the Windows launcher does: finds `Launch.lua`, reads its `#@` line, loads the host library and calls `RunLuaFileAsWin`. It also receives `pob://` links from macOS and passes them on as the first argument, which is how Windows delivers them.
- **A separate update helper, `macos/updater.cpp`, with LuaJIT linked into it.** It runs `UpdateApply.lua` after the application has fully exited. Windows relies on file locks to hold the helper back until then; macOS has none, and rewriting a library that a running process has loaded crashes it. Like `Update.exe`, the helper is not itself updated.
- **The application is a bundle, `Path of Building.app`.** `Contents/MacOS` is the runtime folder and `Contents/Resources` is the script folder. Because the two differ, `Main.lua` already puts builds and settings in the user folder, outside the bundle, so they survive updates.
- **Builds and settings go in `~/Documents/Path of Building/`, and screenshots in its `Screenshots` folder.** Windows uses the Documents folder; the same place on the Mac keeps builds visible and easy to copy between machines. Windows saves screenshots in the runtime folder, which on the Mac is inside the bundle where Finder does not show it. The owner agreed to both.
- **The platform is named `macos`, and updates reuse the manifest design that exists.** The manifest gains `platform="macos"` sources for every part, pointing at the fork. The Mac runtime ships as `runtime-macos.zip` in the fork's root. The zip holds the whole runtime, including copies of `runtime/lua` and the fonts taken at packaging time, so the shared files still have one tracked copy.
- **Two small changes to `src/UpdateCheck.lua`.** It takes the local source for its own platform when the manifest has one, and it skips files marked for another platform's runtime. Today the Windows marker is `runtime="win32"`, which the existing `platform` filter does not look at. Neither change alters what a Windows install does, and a spec proves it.
- **The Mac application follows the fork's `master` branch.** That mirrors upstream: `dev` moves freely and `master` only changes when a release, with a regenerated manifest, is published. Following `dev` would break update checks every time `dev` moved without a new manifest.
- **Shortcuts use Ctrl, as on Windows, except that Option + Left and Option + Right jump a word.** The owner decided both. macOS takes Ctrl + Left and Ctrl + Right for switching desktops before the application sees them. The host reports Ctrl as held for those two key presses when Option is down, so `src/Classes/EditControl.lua` is unchanged. Cmd is not bound.
- **With no Windows machine, two checks are made another way.** "A Mac-saved build opens on Windows" is checked by loading the saved file in the Linux CI image, which runs the same Lua. Responsiveness is measured on the Mac alone and judged by the owner at the demonstration. The owner accepted this.
- **Fatal errors and startup messages are shown on screen.** On Windows a console window shows them. The host's Unix console only writes to standard error, which nobody sees when an application is started from Finder.
- **Specs on the Mac run with busted under a LuaJIT built from the same source as the runtime's.** busted and LuaRocks are development tools from Homebrew and are not shipped.

## Questions

Answered by the owner on 2026-11-23, before implementing.

1. **The host fork.** The plan needs `Stoff73/PathOfBuilding-SimpleGraphic`, a fork of the upstream host repository. Who creates it?
   Answer: the agent creates it with `gh repo fork`.
2. **Where builds and settings live.** `~/Documents/Path of Building/`, as on Windows, or `~/Library/Application Support/Path of Building/`?
   Answer: `~/Documents/Path of Building/`.
3. **Screenshots.** A `Screenshots` folder beside the builds, not the runtime folder inside the bundle?
   Answer: yes.
4. **Ctrl + Left and Ctrl + Right.** These jump a word in text boxes, but macOS takes them first to switch desktops. Turn the macOS shortcuts off, or use Option + arrow?
   Answer: Option + arrow jumps a word on the Mac.
5. **A Windows machine.** Is there one to open a Mac-saved build on, and to compare responsiveness against?
   Answer: no. The two checks are made the other way described under Approach.
6. **Disk space.** Is there room to build?
   Answer: proceed. 16.5 GB is free outright; Finder's 114 GB counts about 97 GB that macOS can reclaim, mostly local Time Machine snapshots. The build watches free space and stops if it runs short, and no snapshot is deleted without asking the owner.
7. **Pushing.** Phase 5 needs pushes to the fork: `dev`, a new `master` branch and a runtime zip committed to the repository.
   Answer: no pushes to the host fork. The agent asks before each push to `Stoff73/PathOfBuilding`.
8. **The process docs.** Commit `AGENTS.md` and `docs/` to `dev` before cutting the branch `01-macos`?
   Answer: yes.

## Layout

Paths under `macos/SimpleGraphic/` are in the host fork.

| File | Phase | Its one job |
|---|---|---|
| `.gitmodules` | 1 | Pins the host fork at `macos/SimpleGraphic` |
| `.gitignore` | 1 | Ignores `macos/build/`, `macos/runtime/` and the built `.app` |
| `macos/build.sh` | 1 | Builds the host, the four Lua libraries, LuaJIT, the launcher and the helper into `macos/build/`, and stages the runtime in `macos/runtime/` |
| `macos/launcher.mm` | 1, 4 | The Mac launcher |
| `macos/SimpleGraphic/CMakeLists.txt` | 1 | Builds on macOS: the Unix socket source for luasocket, library names and install rules that work off Windows |
| `macos/triplets/x64-osx-pob.cmake` | 1 | The vcpkg triplet: shared libraries, release only |
| `macos/SimpleGraphic/cmake/FindLuaJIT.cmake` | 1 | Finds LuaJIT under its macOS file names |
| `macos/SimpleGraphic/vcpkg-ports/ports/luajit/2026-07-20_1/` | 1 | The LuaJIT recipe builds off Windows |
| `macos/SimpleGraphic/engine/common/`, `engine/render/` | 1 | Portability fixes so the host compiles on macOS |
| `macos/SimpleGraphic/engine/system/win/sys_video.cpp` | 1, 3 | Chooses the ANGLE backend on macOS; cursor position, display scale and scrolling behave as on Windows |
| `macos/SimpleGraphic/engine/system/win/sys_macos.mm` | 3 | The macOS system calls: start a process, find the cursor, find Documents, name a cloud provider, show a message window |
| `macos/SimpleGraphic/engine/system/win/sys_main.cpp` | 3 | Calls those on macOS where it now has a "not implemented" stub; reports Ctrl as held for Option + Left and Option + Right |
| `macos/SimpleGraphic/engine/system/win/sys_console_unix.cpp` | 3 | Shows startup and fatal messages on screen on macOS |
| `macos/SimpleGraphic/ui_api.cpp` | 3 | `GetCloudProvider` answers on macOS |
| `macos/SimpleGraphic/engine/render/r_main.cpp` | 3 | Saves screenshots to `~/Documents/Path of Building/Screenshots/` on macOS |
| `macos/dump_build_outputs.lua` | 2 | Prints every calculated output of the test builds, to compare two platforms |
| `macos/host_check.lua` | 3 | Calls every host function that needs no person and reports pass or fail |
| `macos/host_check_system.lua`, `macos/host_check_card.lua` | 3 | The system checks and the drawn test card, split out of `host_check.lua` to keep each file to one job |
| `macos/SimpleGraphic/libs/LZip/lzip.cpp` | 3 | Zip header fields are 32 bits on every platform |
| `macos/Info.plist` | 4 | The bundle's name, version, icon and the `pob` link scheme |
| `macos/PathOfBuilding.icns` | 4 | The application icon, converted from upstream's |
| `macos/package.py` | 4 | Assembles `Path of Building.app` from the staged runtime, `src/` and the manifest, and writes `runtime-macos.zip` and `manifest-updated.xml` |
| `macos/updater.cpp` | 4 | The update helper |
| `src/UpdateCheck.lua` | 4 | The two changes under Approach, and the refusal of a release without this platform |
| `spec/System/TestUpdateCheck_spec.lua` | 4 | Runs `UpdateCheck.lua` against fixture manifests with the network stubbed |
| `update_manifest.py` | 4 | Also writes the `macos` sources and the Mac runtime's files |
| `manifest.xml` | 5 | Regenerated: gains `macos` lines only |
| `runtime-macos.zip` | 5 | The Mac runtime the updater downloads |
| `docs/DECISIONS.md` | Plan | The decisions above |
| `docs/CODE_STANDARDS.md` | 1, 6 | Gains the `macos/` boundary and the rules for its C++ and shell |
| `docs/STATUS.md` | Every | What's built, how to run it on a Mac, and the log |
| `CONTRIBUTING.md` | 6 | How to build and run on a Mac |
| `RELEASE.md` | 6 | How to publish a release and a Mac runtime on the fork |
| `docs/rundown.md` | 6 | Describes `macos/` and the Mac runtime |
| `LICENSE.md` | 6 | Any library in the Mac runtime that it does not already list |

Nothing under `runtime/`, and no existing line of `manifest.xml`, is changed.

## API changes

None. This is a desktop application with no HTTP API. The host's functions, the ones declared in `src/_SimpleGraphic.def.lua`, keep their names, arguments and results on macOS; none is added, removed or changed.

| Operation | Route | Change |
|---|---|---|
| None | None | None |

## Every phase

As `AGENTS.md` sets out (the template calls it `docs/PROCESS.md`), each phase is built with its tests, checked against every criterion, reviewed against `docs/CODE_STANDARDS.md`, ticked off here, written up in `docs/STATUS.md` and committed on the branch `01-macos`. There is no pre-commit hook yet, so each phase's checks are run by hand before its commit. Host changes are committed in the submodule on its branch `macos`, and this repository's commit moves the submodule to them. Nothing is pushed to the host fork, and nothing is pushed to `Stoff73/PathOfBuilding` without asking first.

## Phase 1: The host builds and draws

Adds the host fork as a submodule, makes its build work on macOS, writes the launcher's first version and `macos/build.sh`, and runs the program from this folder in Dev Mode.

Why first: it is the largest unknown. This MacBook is 2014 hardware (Intel Iris Pro) running macOS 15, and whether ANGLE draws correctly on it, and whether the build fits in the free disk space, can only be found by doing it. If it cannot be made to work, the phase stops and goes back to the owner, as `AGENTS.md` requires, before anything else is built.

- [x] `macos/build.sh` run from a clean checkout finishes and leaves the host library, `lcurl`, `lzip`, `lua-utf8`, `socket`, LuaJIT and the launcher in `macos/runtime/`. The time taken and disk used are recorded in `docs/STATUS.md`. Checked by deleting `macos/build/host` and `macos/runtime` and rebuilding: 183 seconds, with the dependencies restored from vcpkg's cache.
- [x] `otool -L` on each built file shows nothing outside `macos/runtime/`, `/usr/lib` and `/System`.
- [x] Starting the launcher from this folder opens the Path of Building window in Dev Mode, with no error on screen or on standard error. On a first run it opens a new unnamed build, not the build list as this criterion first said; `src/Modules/Main.lua` does the same on Windows. The log's only warnings are three image files that are not in the repository.
- [x] A screenshot of the build list and of the Tree tab of a build from `spec/TestBuilds` shows text, images and the tree drawn without gaps or garbling. Checked with `OccVortex`, after fixing text that was missing from the lower half of the window (see below).
- [x] The ANGLE backend in use is recorded in `docs/DECISIONS.md` with the reason: decision 19, OpenGL.
- [x] `git diff --stat origin/dev -- runtime runtime-win32.zip` prints nothing.

## Phase 2: The numbers match

Runs the existing specs on the Mac under LuaJIT built from the runtime's source. No product code is expected to change.

Why second: it is cheap, and it proves the Mac's LuaJIT calculates as the CI image's does before any work is spent on the interface.

The owner changed three of these criteria on 2026-11-24, after the findings recorded under "Decisions made while building": the reference is the CI image at the same commit, and `spec/System/TestTreeTab_spec.lua` is excepted until upstream fixes it.

- [x] busted passes on this MacBook under the built LuaJIT, with the same number of checks as the CI image: 909 pass and none fail on each, run with `--exclude-pattern=TestTreeTab`.
- [x] Every calculated output of every build in `spec/TestBuilds` is the same on the Mac as in the CI image. `macos/dump_build_outputs.lua` printed 4,398 outputs for the five builds on each, at 17 significant digits, and the two lists are identical. This replaces comparing against the stored outputs, which date from 2022.
- [x] The mod cache regenerated on the Mac is byte-identical to the one regenerated in the CI image (4,113,289 bytes). This replaces a clean `git diff`, which neither gives because the committed cache lacks 24 entries.
- [x] The suite still passes in the CI image: the same 909 checks, with the same exception.

## Phase 3: The host behaves as on Windows

Fills in every host function that is a stub or behaves differently on macOS: starting a process, the global cursor position, the Documents folder, cloud provider names, on-screen startup and error messages, screenshots, and trackpad scrolling, which today would send one wheel step per tiny movement. Checks cursor position and drawing on the Retina display, resizing and full screen. Writes `macos/host_check.lua`.

Why third: the application's features sit on these functions, so they are proven one by one before the features are.

- [x] `macos/host_check.lua`, run through the launcher, reports a pass for every function in part A of the parity checklist that it can call without a person. 25 checks pass and none fail, on the external display at scale 1 and on the built-in display at scale 2, and the test card it draws is correct on both.
The owner decided on 2026-11-24 to make the checks that need a person at the keyboard and trackpad at the demonstration, after synthetic input from the agent went to the wrong window. The five criteria below stay open until then. What the agent could establish without input is noted on each.

- [ ] Every other line in part A is ticked after being exercised by hand, with a note of how. Left for the demonstration: `OpenURL`, `Restart`, the key and mouse callbacks, `CanExit`, resizing and full screen.
- [ ] On the built-in Retina display the cursor lands on what it points at, in a window and in full screen: clicking a passive node allocates that node. Established so far: at scale 2, `SetCursorPos` then `GetCursorPos` returns the same point, the Skills button highlights under the pointer, and a click on it opened the Skills tab.
- [ ] Two-finger scrolling moves a list at a rate comparable to a mouse wheel, and zooms the tree a step at a time. Built, with the rate in one constant, `SCROLL_STEPS_PER_UNIT` in `sys_video.cpp`; not yet felt by a person.
- [ ] A fatal error forced at startup appears in a window on screen, not only on standard error. Built; the alert was raised twice by real errors during testing, but the agent did not see it on screen.
- [ ] Dragging and zooming the passive tree for ten seconds holds the display's refresh rate, and the figure is recorded. So is the time to open the largest build in `spec/TestBuilds`. Recorded: the five test builds load and calculate in 0.35 to 1.5 seconds headless (the largest, Mirage Archer Toxic Rain, in 1.3), and the program starts in 13 to 21 seconds in Dev Mode. The frame rate while dragging is left for the demonstration.
- [ ] Each shortcut in part C of the checklist does on the Mac what it does on Windows, and Option + Left and Option + Right jump a word in a text box.

## Phase 4: The application and every feature

Writes `macos/package.sh`, `macos/Info.plist` and the icon, and finishes the launcher: finding its scripts inside the bundle and receiving `pob://` links. Then exercises every feature in the packaged application.

Why fourth: the bundle changes where files are found and where data is saved, so features are proven in the form the owner will use.

- [x] `macos/package.py` produces `Path of Building.app`, and `open` starts it in installed mode: not Dev Mode, with the version number shown. (The plan first named this script `package.sh`.)
- [x] Builds and settings are written to `~/Documents/Path of Building/`, screenshots to its `Screenshots` folder, and nothing is written inside the bundle except by the updater and the host's own settings files, `SimpleGraphic/SimpleGraphic.cfg` and `imgui.ini`, which Windows keeps in the runtime folder too. Checked by quitting the application normally: `Settings.xml` was rewritten in Documents.
- [ ] Every line in part B of the parity checklist is ticked. Lines that need the owner's Path of Exile account are ticked at the demonstration and marked so. Left for the demonstration, as the features need a person at the keyboard.
- [ ] Opening a `pob://` link in the browser starts the application and imports that build. Established: with the application closed, a link starts it with the link as its first argument, and it requests that build from the site; with it running, a link opens in a second copy. Importing a real build is left for the demonstration.
- [x] A build from `spec/TestBuilds`, saved on Windows, opens in the application with its stored output. `OccVortex` opened in the packaged application from the Builds folder with the figures the CI image gives. "Stored output" here means the CI image's, as decided in phase 2.
- [x] A build saved by the application loads in the CI image with the same output as on the Mac. The five test builds, saved by the program's save code under the Mac's LuaJIT, give 4,398 identical outputs in the CI image. Saving from the window itself is left for the demonstration.
- [x] `find "Path of Building.app" -name '*.dll' -o -name '*.exe'` prints nothing.

## Phase 5: Updates from the fork

Writes the update helper, makes the two changes to `src/UpdateCheck.lua` with their spec, extends `update_manifest.py`, regenerates `manifest.xml`, produces `runtime-macos.zip` and publishes to the fork's `master`.

Why fifth: an update can only be tested against a finished application, and it needs pushes to the fork, which the owner approves one at a time.

- [ ] `spec/System/TestUpdateCheck_spec.lua` passes on the Mac and in the CI image. It shows that a `win32` install selects exactly the files it selected before the change, and that a `macos` install never selects a file marked `runtime="win32"`. Passes on the Mac, three checks, and fails against the unchanged `UpdateCheck.lua`; not yet run in the CI image.
- [ ] `git diff origin/dev -- manifest.xml` shows added lines only, each carrying `platform="macos"`.
- [ ] A program update works end to end: the application built from one commit finds, downloads and applies a later commit published on the fork's `master`, restarts, and shows the new version.
- [ ] A runtime update works end to end: with a changed host library published, the application exits, the helper applies the update and starts it again, the new host version is reported, and the launcher is still executable.
- [ ] Checksums of every file in the user folder are the same before and after both updates.
- [ ] After both updates the bundle still holds no `.dll` or `.exe`.

## Phase 6: Docs, a clean rebuild and the demonstration

Brings the docs up to date, proves the written build steps, and prepares what the owner will watch.

Why last: the docs describe the finished product, and the demonstration is the brief's final test.

- [ ] A fresh clone of this folder into a temporary folder, with its submodule taken from the local copy because the host changes are not pushed, built by following only the Mac section of `CONTRIBUTING.md`, yields a working `Path of Building.app`.
- [ ] `docs/STATUS.md`, `CONTRIBUTING.md`, `RELEASE.md`, `docs/rundown.md` and `docs/CODE_STANDARDS.md` describe the product as it now is, and `LICENSE.md` covers every library in the Mac runtime.
- [ ] The whole busted suite passes on the Mac and in the CI image at the final commit.
- [ ] `git diff --stat origin/dev -- runtime runtime-win32.zip` prints nothing, and the `manifest.xml` check from phase 5 still holds.
- [ ] The owner watches the demonstration the brief describes, and every line of the parity checklist left for the demonstration is ticked.

## Parity checklist

One line per host function and per feature, ticked once it has been exercised on the Mac.

### Part A: host functions

Callbacks and loading:

- [ ] `SetCallback`
- [ ] `GetCallback`
- [ ] `SetMainObject`
- [ ] The callbacks `OnInit`, `OnFrame`, `OnKeyDown`, `OnKeyUp`, `OnChar`, `CanExit` and `OnExit` are delivered
- [ ] `LoadModule`
- [ ] `PLoadModule`
- [ ] `PCall`

Images and textures:

- [ ] `NewImageHandle`
- [ ] `imageHandle:Load`
- [ ] `imageHandle:LoadArtRectangle`
- [ ] `imageHandle:LoadArtArcBand`
- [ ] `imageHandle:Unload`
- [ ] `imageHandle:IsValid`
- [ ] `imageHandle:IsLoading`
- [ ] `imageHandle:SetLoadingPriority`
- [ ] `imageHandle:ImageSize`
- [ ] `NewArtHandle`
- [ ] `artHandle:Size`
- [ ] `Texture.new`
- [ ] `texHandle:Allocate`
- [ ] `texHandle:Load`
- [ ] `texHandle:Save`
- [ ] `texHandle:Info`
- [ ] `texHandle:IsValid`
- [ ] `texHandle:StackTextures`
- [ ] `GetAsyncCount`

Drawing:

- [ ] `RenderInit`
- [ ] `GetScreenSize`
- [ ] `GetScreenScale`
- [ ] `SetClearColor`
- [ ] `SetDrawLayer`
- [ ] `GetDrawLayer`
- [ ] `SetViewport`
- [ ] `SetBlendMode`
- [ ] `SetDrawColor`, both forms
- [ ] `GetDrawColor`
- [ ] `SetDPIScaleOverridePercent`
- [ ] `GetDPIScaleOverridePercent`
- [ ] `DrawImage`, all three forms
- [ ] `DrawImageQuad`, all three forms
- [ ] `DrawString`
- [ ] `DrawStringWidth`
- [ ] `DrawStringCursorIndex`
- [ ] `StripEscapes`

Files and folders:

- [ ] `NewFileSearch`
- [ ] `fileSearchHandle:NextFile`
- [ ] `fileSearchHandle:GetFileName`
- [ ] `fileSearchHandle:GetFileSize`
- [ ] `fileSearchHandle:GetFileModifiedTime`
- [ ] `GetScriptPath`
- [ ] `GetRuntimePath`
- [ ] `GetUserPath`
- [ ] `GetWorkDir`
- [ ] `SetWorkDir`
- [ ] `MakeDir`
- [ ] `RemoveDir`
- [ ] `GetCloudProvider`

Window and input:

- [ ] `SetWindowTitle`
- [ ] `GetCursorPos`
- [ ] `SetCursorPos`
- [ ] `ShowCursor`
- [ ] `IsKeyDown`
- [ ] `Copy`
- [ ] `Paste`
- [ ] `SetForeground`
- [ ] `TakeScreenshot`

Processes, network and the rest:

- [ ] `LaunchSubScript`
- [ ] `AbortSubScript`
- [ ] `IsSubScriptRunning`
- [ ] The callbacks `OnSubCall`, `OnSubError` and `OnSubFinished` are delivered
- [ ] `SpawnProcess`
- [ ] `OpenURL`
- [ ] `Deflate`
- [ ] `Inflate`
- [ ] `GetTime`
- [ ] `ConPrintf`
- [ ] `ConPrintTable`
- [ ] `ConExecute`
- [ ] `ConClear`
- [ ] `SetProfiling`
- [ ] `Restart`
- [ ] `Exit`

Lua libraries the runtime provides:

- [ ] `lcurl.safe`: an HTTPS download succeeds
- [ ] `lzip`: a file is read out of a zip
- [ ] `lua-utf8`
- [ ] `socket`: the sign-in listener in `src/LaunchServer.lua` binds its port

### Part B: features

- [ ] The build list: folders, search, sorting, new, open, rename, delete
- [ ] The Tree tab: allocate, path tracing, search, jewel sockets, tree versions, import and export of tree links
- [ ] The Skills tab
- [ ] The Items tab: paste an item from the clipboard, the unique and rare databases, crafting
- [ ] The Calcs tab and its breakdowns
- [ ] The Configuration tab
- [ ] The Notes tab
- [ ] The Import/Export tab: character import from a Path of Exile account (demonstration)
- [ ] The Compare tab
- [ ] Share codes: generate one, and import one
- [ ] Importing from a build site link, and from a `pob://` link
- [ ] Trade search (demonstration)
- [ ] Path of Exile sign-in for trade (demonstration)
- [ ] Timeless jewel search
- [ ] The power report
- [ ] Copy and paste between the application and other Mac applications
- [ ] Links open in the default browser
- [ ] Screenshots
- [ ] Saving and loading builds
- [ ] Saving and loading settings, including the options window
- [ ] The update check

### Part C: shortcuts and mouse

- [ ] Ctrl + C, X, V, A, Z and Y in text boxes
- [ ] Option + Left and Option + Right jump a word in text boxes
- [ ] Ctrl + plus, minus and 0 zoom text where zoom is allowed
- [ ] Ctrl + Z, Y, F, M and D on the Tree tab, and Ctrl + C over a node
- [ ] Ctrl + click and Shift + click
- [ ] Right-click by two-finger tap, and scrolling by two fingers
- [ ] The function keys the program uses: F1, F4 and F5
- [ ] Alt for the extra tooltip detail in Dev Mode

## Decisions made while building

- **ANGLE's OpenGL backend, not Metal (phase 1).** With the Metal backend the host started and ran `Launch.lua`, then failed with "EGL: Failed to get EGL display". A Metal query showed the Intel Iris Pro does not support the Mac2 family, which ANGLE's Metal backend needs. The vcpkg recipe builds either backend but not both, so `vcpkg.json` is left as upstream has it, which gives OpenGL. This is the fallback the plan named.
- **The build uses one vcpkg triplet for host and target, `x64-osx-pob` (phase 1).** With a separate host triplet vcpkg treated the build as a cross-compile and built LuaJIT twice.
- **Fixes to the host's LuaJIT recipe (phase 1).** Its `configure` script was not executable, and it lacked the stock recipe's fix for an install step that replaces the `luajit` binary with a link to itself. Both only matter off Windows.
- **Small portability fixes in the host (phase 1).** Missing includes in `base64` and `r_texture.cpp`, a bare `Sleep` call in `r_main.cpp`, a Windows-only define for `lua-utf8`, LuaJIT's file names in `FindLuaJIT.cmake`, and `IndexUTF8ToUTF32` moved out of a Windows-only block in `common.cpp`. None changes the Windows build's behaviour.
- **The launcher sets `LUA_PATH` and `LUA_CPATH` (phase 1).** LuaJIT on Windows searches the executable's folder; on macOS it has no such default, so the launcher names the runtime folder.
- **Text is culled against the framebuffer's height, not the window's (phase 1).** `r_font.cpp` skipped any line of text below the window's height in screen points while positions are in pixels, so on a Retina display the lower half of the window had no text. The two heights are equal on Windows, so nothing changes there.
- **The LuaJIT patch calls `getenv` directly off Windows (phase 1).** Its non-Windows branch copied the result without checking for an unset variable, which crashed `os.getenv`.
- **The build renames ANGLE's libraries to `libEGL.dylib` and `libGLESv2.dylib` and re-signs them (phase 1).** GLFW opens ANGLE by those names; the vcpkg recipe produces `liblibEGL_angle.dylib` and `liblibGLESv2_angle.dylib`.

- **The Windows host is the same commit (phase 3).** `runtime/SimpleGraphic.dll` reports `v2.5-421d188`, the commit the Mac host is built from, so differences found on the Mac are differences of platform, not of version.
- **ANGLE's layer follows the window's display scale (phase 3).** ANGLE gives its drawing layer the display's scale once. On a display with another scale the picture was a quarter of the window. `PlatformSyncLayerScale` in `sys_macos.mm` sets it whenever the scale changes. Found by running on the external display, which is scale 1 where the built-in one is scale 2.
- **Three host faults that only showed on the Mac (phase 3).** `lzip` read zip headers with `unsigned long` fields, 64 bits off Windows, so no zip opened. The file search threw when a match was a folder. The non-Windows fatal error message dropped its text. All three are fixed; the first two would have broken timeless jewel data, updates and folders in the build list.
- **The host build ignores any system Lua (phase 3).** sol2 includes `<lua/lua.hpp>` if one exists, and Homebrew's Lua, installed with LuaRocks, provides one. The build now offers LuaJIT's headers under that name first.
- **The launcher passes an absolute script path (phase 3).** The host reads a relative one as relative to the runtime folder.
- **Two entries in the parity checklist cannot be exercised, on any platform (phase 3).** `SetBlendMode` is declared in `src/_SimpleGraphic.def.lua` but is in neither the Windows binary nor the host source, and no Lua calls it. `imageHandle:LoadArtRectangle` copies each row once per pixel of width and overruns its buffer; the code is the same on Windows, and no Lua calls it either. Both are left as they are.
- **The window reopens where it was last (phase 3).** The host saves the window's position in `SimpleGraphic/SimpleGraphic.cfg` in the runtime folder, as on Windows, so "opens on the display the pointer is on" applies to a first run only.

- **The update code was built with phase 4 (phases 4 and 5).** A packaged application checks for updates as it starts, so the changes to `UpdateCheck.lua`, their spec, `update_manifest.py` and the update helper had to exist before the bundle could be run safely. Phase 5 keeps what needs publishing.
- **The Mac application follows the fork's `macos-release` branch, not `master` (phase 4). This changes decision 12.** GitHub answers a request for a branch the fork lacks with upstream's branch of that name. The first packaged run was therefore offered upstream's Windows release, which would have replaced the Mac's Lua with older files and deleted the Mac runtime had it been applied. A branch name upstream does not have cannot be answered that way.
- **`UpdateCheck.lua` refuses a release with no runtime for its platform (phase 4).** A third change to that file, for the same reason. It cannot affect Windows, whose runtime source every manifest has. The spec covers it.
- **The update helper carries out the operations itself (phase 4). This changes decision 7.** It reads the operations file and does the three operations `UpdateApply.lua` does, without Lua, so it links nothing but system libraries. Linking LuaJIT in would have needed a second, static build of it.
- **The launcher leaves the event loop to the host (phase 4).** Its first version pumped events to catch the link the application was opened with, which made GLFW skip its start-up and left the application with no Quit handling. Now it only registers for link events. A link that arrives in the first five seconds restarts the application with the link as its argument; a later one opens in a second copy.
- **`update_manifest.py` skips the `macos` folder (phase 4).** Its `default` part takes any file named `LICENSE.md`, wherever it is, and found one in the Mac build tree.
- **Packaging is `macos/package.py`, not `package.sh` (phase 4).** It reads the manifest to decide what goes in the bundle, which is easier in typed Python than in shell.

### Phase 2 findings, and the owner's decisions

Three of phase 2's criteria rested on assumptions about the repository that turned out to be wrong. On 2026-11-24 the owner decided that `TestTreeTab_spec.lua` is an accepted exception until upstream fixes it, that "the same numbers" is judged by the Mac equalling the CI image, and that the reference files stay as upstream has them. The findings: None of the three is caused by the Mac work. Each is checked against the CI image at the same commit instead.

- **The suite.** On the Mac, under LuaJIT built from the runtime's source, 909 checks pass and none fail. The CI image gives the same 909 and none failing. Both exclude `spec/System/TestTreeTab_spec.lua`, whose check "Copies multiple times with unique IDs" never finishes: it deep-compares two whole passive specs. It hung on the Mac in every attempt and in the CI image, and upstream's own CI runs of this code either finish in under three minutes or are cancelled at six hours. The spec came from upstream on 2026-11-22. So "the whole suite passes" cannot be shown on either platform until that spec is fixed.
- **The mod cache.** Regenerating it on the Mac adds 24 entries for newly added support gems and changes nothing else, so `git diff --exit-code` is not clean. The CI image regenerates a byte-identical file (4,113,289 bytes). The committed cache is behind the data; the Mac and the CI image agree exactly.
- **The stored test builds.** The outputs in `spec/TestBuilds` were last generated in 2022, and nothing in CI runs them. Against today's code 900 of 2,164 values differ on the Mac, as they would anywhere. The meaningful check is to generate the outputs on the Mac and in the CI image at the same commit and compare. The repository's generator, `spec/GenerateBuilds.lua`, turned out not to finish on either platform and leaves half-written files, so `macos/dump_build_outputs.lua` was written to do the comparison: 4,398 outputs, identical.
- **The documented headless command.** `LUA_PATH='../runtime/lua/?.lua;../runtime/lua/?/init.lua'` no longer finds `Data.PearlSupports`, in the CI image as on the Mac. Adding `./?.lua;./?/init.lua` fixes it, and `docs/CODE_STANDARDS.md` rule 10 now says so.

## Not in this build

- Apple Silicon, and a universal binary.
- Code signing and notarisation, and an installer or disk image for other people's Macs.
- A macOS job in CI. The Mac build is made and checked on this MacBook.
- The GGPK exporter on macOS.
- Linux.
- Offering the host changes upstream. They are written so that they can be, but that is a separate piece of work.
- Changes to the Windows runtime, launcher or installer.
- A pre-commit hook and an automatic check of the 200-line rule.

## Lessons

To be written at the end.
