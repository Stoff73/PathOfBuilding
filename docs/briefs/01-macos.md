# Path of Building on macOS

From Stoff73, the fork's owner.

## Where we're heading

Path of Building runs on Windows only. `docs/STATUS.md` describes what exists.

The Lua program in `src/` does not depend on Windows. What does is `runtime/`: the launcher, the SimpleGraphic host that provides the window, drawing, input, clipboard and files, LuaJIT, the native Lua libraries (`lcurl`, `lua-utf8`, `lzip`, `socket`) and the updater. All of these ship as Windows binaries, and the host's source is in a separate repository. The updater knows one runtime, `win32`, and downloads from the upstream community repository.

The owner works on an Intel MacBook running macOS 15 and wants to use the whole program there, natively, with nothing missing and nothing worse than on Windows.

## What we want

1. **A native Mac application.** Path of Building starts on this MacBook as a macOS application, from Finder or the Dock. No Wine, virtual machine or other compatibility layer, and no Windows binary is run.
2. **Every feature works.** Everything the program does on Windows it does on the Mac: the build list, the Tree, Skills, Items, Calcs, Configuration, Notes, Import/Export and Compare tabs, character import, share codes, trade search and its Path of Exile sign-in, timeless jewel search, the power report, copy and paste, opening links in the browser, screenshots, and saving and loading builds and settings.
3. **The same numbers.** A build shows the same calculated figures on the Mac as on Windows.
4. **The same look and responsiveness.** Text, the passive tree, images, scaling on the MacBook's display, window resizing and full screen all render correctly, and the program is as responsive as on Windows. Every keyboard shortcut and mouse action can be performed on a Mac keyboard and trackpad. Shortcuts use Ctrl, as on Windows.
5. **Builds move both ways.** A build saved on Windows opens on the Mac, and a build saved on the Mac opens on Windows. Builds and settings on the Mac survive an update.
6. **Updates work, from the fork.** The Mac application checks for, downloads and applies updates from `Stoff73/PathOfBuilding`, including updates to its own Mac runtime. An update never puts a Windows file in place of a Mac one.
7. **Built on this MacBook.** The Mac runtime can be built from source on this machine by following written steps.

## What stays the same

- Windows keeps working exactly as it does now, from the same code. The Windows runtime files, the `win32` entries in the manifest and the Windows installer are untouched.
- The calculation engine, the modifier parser and the game data do not change. One Lua program serves both platforms; a difference between them belongs in the runtime, not in a second copy of a module.
- Lua 5.1 on LuaJIT.
- The fork can still take changes from upstream `dev`, so changes to upstream's files are kept as small as the work allows.
- Not part of this: Apple Silicon, code signing and notarisation, an installer for other people's Macs, Linux, and the GGPK exporter, which stays a Windows tool.
- The process in `AGENTS.md` and the rules in `docs/CODE_STANDARDS.md`.

## What done looks like

- A demonstration the owner watches on this MacBook: start the application from Finder, open a build, use each tab, import a character, create and import a share code, run a trade search, take a screenshot, and check for updates.
- The busted suite passes on this MacBook under the Mac runtime's LuaJIT, and still passes in the CI image, with the same number of checks on each. `spec/System/TestTreeTab_spec.lua` is excepted until upstream fixes it: one of its checks never finishes on any platform. (Changed by the owner on 2026-11-24.)
- The builds in `spec/TestBuilds` produce the same calculated outputs on the Mac as in the CI image, and the mod cache regenerates identically on both. The stored outputs date from 2022 and no longer match the code anywhere. (Changed by the owner on 2026-11-24.)
- A parity checklist in the plan, with one line for every host function in `src/_SimpleGraphic.def.lua` and every feature in item 2, each ticked after being exercised on the Mac.
- An update published on the fork is found, downloaded and applied by the Mac application, and builds and settings are intact afterwards.
- A build saved on each platform opens on the other.
- The Windows runtime files and `win32` manifest entries are identical to `origin/dev`.
- `docs/STATUS.md`, `CONTRIBUTING.md`, `RELEASE.md`, `docs/rundown.md` and `docs/CODE_STANDARDS.md` describe the product as it now is, including how to build and run it on a Mac.

## Planning

Follow `docs/PROCESS.md`, and write the plan to `docs/plans/01-macos.md`.
