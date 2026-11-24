"""Assembles "Path of Building.app" from the runtime that macos/build.sh staged.

Also writes runtime-macos.zip, the Mac runtime that the updater downloads, and
manifest-updated.xml, the manifest for this tree. Requires Python 3.10 or higher.
"""

import os
import pathlib
import shutil
import sys
import xml.etree.ElementTree as Et
import zipfile

REPO = pathlib.Path(__file__).resolve().parent.parent
STAGE = REPO / "macos" / "runtime"
APP = REPO / "macos" / "build" / "Path of Building.app"
PLATFORM = "macos"
# A branch name upstream does not have. GitHub answers a request for a branch the fork lacks with
# upstream's branch of that name, so a Mac copy following "master" could be handed a Windows release.
BRANCH = "macos-release"

# Not updated, as Update.exe is not on Windows: a helper cannot replace itself while it runs.
NOT_IN_ZIP = {"Update"}
# The host's own settings, written beside it while it runs, and the profiler, which manifest.cfg leaves out too.
NOT_SHIPPED = {"SimpleGraphic.cfg", "SimpleGraphicAuto.cfg", ".DS_Store", "lua-profiler.lua"}

# Where the files of each manifest part come from, and which folder of the bundle they go in.
PART_SOURCES = {"default": REPO, "program": REPO / "src", "tree": REPO / "src"}


def runtime_files() -> list[pathlib.Path]:
    """The staged runtime's files, relative to its folder."""
    return sorted(
        path.relative_to(STAGE)
        for path in STAGE.rglob("*")
        if path.is_file() and path.name not in NOT_SHIPPED
    )


def write_runtime_zip(zip_path: pathlib.Path) -> None:
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in runtime_files():
            if path.name not in NOT_IN_ZIP:
                archive.write(STAGE / path, path.as_posix())


def write_manifest() -> Et.Element:
    """Regenerate the manifest for this tree and return it."""
    sys.path.insert(0, str(REPO))
    import update_manifest

    os.chdir(REPO)
    update_manifest.create_manifest()
    return Et.parse(REPO / "manifest-updated.xml").getroot()


def installed_manifest(manifest: Et.Element) -> Et.ElementTree:
    """The manifest as an installed Mac copy holds it: its platform and branch, and no Windows files."""
    root = Et.Element("PoBVersion")
    for node in manifest:
        if node.tag == "Version":
            Et.SubElement(root, "Version", number=node.get("number", ""), platform=PLATFORM, branch=BRANCH)
        elif node.tag == "Source" or (node.get("runtime") is None and node.get("platform") in (None, PLATFORM)):
            root.append(node)
    tree = Et.ElementTree(root)
    Et.indent(tree, "\t")
    return tree


def build_app(manifest: Et.Element) -> None:
    shutil.rmtree(APP, ignore_errors=True)
    macos_dir = APP / "Contents" / "MacOS"
    resources = APP / "Contents" / "Resources"
    for path in runtime_files():
        (macos_dir / path).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(STAGE / path, macos_dir / path)

    for node in manifest.iter("File"):
        source = PART_SOURCES.get(node.get("part", ""))
        if source is not None:
            name = node.get("name", "")
            (resources / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source / name, resources / name)
    installed_manifest(manifest).write(resources / "manifest.xml", encoding="UTF-8", xml_declaration=True)
    shutil.copy2(REPO / "macos" / "PathOfBuilding.icns", resources / "PathOfBuilding.icns")

    version = manifest.find("Version")
    plist = (REPO / "macos" / "Info.plist").read_text().replace("@VERSION@", version.get("number", "") if version is not None else "")
    (APP / "Contents" / "Info.plist").write_text(plist)


def main() -> None:
    if not (STAGE / "Path of Building").exists():
        sys.exit("The runtime is not built. Run macos/build.sh first.")
    write_runtime_zip(REPO / "runtime-macos.zip")
    manifest = write_manifest()
    build_app(manifest)
    print(f"Built {APP}")


if __name__ == "__main__":
    main()
