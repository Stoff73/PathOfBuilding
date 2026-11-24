# The macOS demonstration

The checks that need a person at the keyboard and trackpad, for the owner to make on the MacBook. It is the last criterion of `docs/plans/01-macos.md`, and it carries every line that plan leaves open. The agent sends no key or mouse input (decision 22), so the owner does each step and says what happened; the agent ticks the line here and in the plan, or writes down what went wrong.

Each line says what to do, then what should happen. "Ctrl" is the Control key throughout, as on Windows.

## Before starting

The agent prepares these, and says so when they are ready:

- The application, built and packaged at the final commit: `macos/build/Path of Building.app`.
- The five test builds copied from `spec/TestBuilds` into `~/Documents/Path of Building/Builds/`.
- A second copy of the application one release behind, at `macos/build/test/Path of Building.app`, for step 9.

The owner needs an internet connection, a Path of Exile account, and for step 3 the external display connected.

## 1. Start from Finder

- [ ] In Finder, open `macos/build` and double-click `Path of Building`. The window opens, with the version number at the bottom left and no "Dev Mode" beside it.
- [ ] The build list shows the five test builds. Sort it, type in the search box, make a folder, and make a new build, rename it and delete it.
- [ ] Open `Mirage Archer Toxic Rain`. It opens in about two seconds and the sidebar shows its figures.

## 2. Each tab

With a test build open:

- [ ] Tree: click an unallocated node next to an allocated one. That node is allocated, not its neighbour. Hover a distant node: the path to it is traced. Search for a word: matching nodes are ringed.
- [ ] Tree: click a jewel socket and pick a jewel. Change the tree version with the dropdown at the bottom. Use "Export Tree" to get a link and "Import Tree" to load one.
- [ ] Tree: tick "Show Node Power" and press "Show Power Report". The report fills in.
- [ ] Tree: press "Find Timeless Jewel", choose a jewel type and search. Results appear. The first search downloads the jewel's data.
- [ ] Skills: add a socket group, add a gem by typing part of its name, change its level, and remove it.
- [ ] Items: copy an item in another application (a trade site, or the game) and press Ctrl + V on the Items tab. The item appears. Pick one from the unique database and one from the rare templates. Press "Craft item..." and make one.
- [ ] Calcs: hover a figure. Its breakdown appears.
- [ ] Configuration: tick an option. The sidebar figures change.
- [ ] Notes: type some text, leave the tab and come back. The text is there.
- [ ] Compare: choose a second build to compare against. Both sets of figures show.
- [ ] Press Ctrl + S, go back to the build list and open the build again. The change is still there.
- [ ] Press "Options", change a setting, save, quit with Cmd + Q or the red button, and start again. The setting is kept. Quitting with an unsaved build asks first.

## 3. The display

- [ ] Resize the window by its edge. The contents follow without stretching or gaps.
- [ ] Press the green button for full screen, click a tree node, and leave full screen. The click lands on the node under the pointer in both.
- [ ] Drag the window from the built-in display to the external one and back. The picture fills the window on each, at the right size.
- [ ] On the Tree tab, drag the tree about and zoom in and out for ten seconds. It keeps up with the fingers without stutter. The program has no frame counter on any platform, so this is the owner's judgement.

## 4. Keyboard and trackpad

- [ ] In a text box: Ctrl + A, C, X, V, Z and Y select all, copy, cut, paste, undo and redo.
- [ ] In a text box with several words: Option + Left and Option + Right jump a word at a time.
- [ ] In the Notes tab: Ctrl + plus, Ctrl + minus and Ctrl + 0 make the text larger, smaller and normal.
- [ ] On the Tree tab: Ctrl + Z and Ctrl + Y undo and redo an allocation, Ctrl + F goes to the search box, Ctrl + M opens the window that manages trees, Ctrl + D turns the stat differences in node tooltips on and off, and Ctrl + C over a node copies its text.
- [ ] Ctrl + click and Shift + click on tree nodes and in lists do what their tooltips say.
- [ ] A two-finger tap is a right-click: on a jewel socket or an item slot it opens the menu a right-click does.
- [ ] Two-finger scrolling moves a long list at about the rate a mouse wheel would, and zooms the tree a step at a time, not in a rush.
- [ ] F1 opens the help. After an error prompt, F4 returns to the build list and F5 restarts.
- [ ] Copy text in the application and paste it into another Mac application, and the other way round.

## 5. The network

- [ ] Import/Export Build: enter the account name and press "Start". The character list arrives; import a character's tree, jewels, items and skills.
- [ ] Import/Export Build: press "Generate" for a share code, then "Share" to upload it to a build site. Copy the code, make a new build, and import the code. The same build appears.
- [ ] Import/Export Build: paste a build site link, such as a pobb.in address, and import it.
- [ ] Items: press "Trade for these items", sign in to Path of Exile when asked (the browser opens and returns to the application), and run a search. Results arrive with prices.
- [ ] Click a link in the application, such as one in the About window. It opens in the default browser.

## 6. A build link

- [ ] Quit the application. In the browser, open a `pob://` link from a build site. The application starts and imports that build.
- [ ] With the application running, open another `pob://` link. A second copy starts with that build. (On Windows a link also starts a new copy.)

## 7. A screenshot

- [ ] Take a screenshot. The picture appears in `~/Documents/Path of Building/Screenshots/`.

The shortcut is Ctrl + Print Screen. A MacBook's own keyboard has no such key; on an external Mac keyboard it is F13. This is open: see the question in `docs/STATUS.md`.

## 8. Dev Mode and errors

These run from Terminal, in the repository folder.

- [ ] `"macos/runtime/Path of Building"` starts the program in Dev Mode. Hold Option over a passive node: the tooltip gains the node's ID and modifiers. Press F5: the program restarts in place.
- [ ] `"macos/runtime/Path of Building" macos/host_check.lua` draws a test card for a few seconds, moves the pointer, and prints its results in Terminal. Every line reads PASS and the last reads `0 failed`.
- [ ] `printf '#@ SimpleGraphic\nerror("Forced")\n' > /tmp/fatal.lua; "macos/runtime/Path of Building" /tmp/fatal.lua` shows an alert on screen with the error's text. Pressing OK ends the program.

## 9. An update

- [ ] In the application from step 1, press "Check for Update". After about four minutes it reports that no update is available.
- [ ] Start `macos/build/test/Path of Building.app`. After about four minutes "Update Available" appears at the bottom left. Press it, then press "Update". The application closes and starts again by itself, with the new version, and does not offer the update again.
- [ ] The builds in `~/Documents/Path of Building/Builds/` are as they were, and the application folder holds no `.dll` or `.exe`: `find "macos/build/test/Path of Building.app" -name '*.dll' -o -name '*.exe'` prints nothing.

## Not on a trackpad

The mouse's back and forward buttons leave a build and move between folders in the build list on Windows. A trackpad has neither; the on-screen buttons do the same.
