#!/bin/bash
# Path of Building
#
# Builds the macOS runtime from source and stages it in macos/runtime/.
# Needs Xcode's command line tools, CMake and Ninja.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(dirname "$here")"
host="$here/SimpleGraphic"
build="$here/build/host"
stage="$here/runtime"
triplet=x64-osx-pob
libdir="$build/vcpkg_installed/$triplet/lib"

# A build cannot use the space macOS reclaims on demand, so check what is free now.
free_gb="$(df -g "$here" | awk 'NR==2 {print $4}')"
if [ "$free_gb" -lt 3 ]; then
	echo "Only ${free_gb} GB free; the build needs at least 3 GB. Stopping." >&2
	exit 1
fi

[ -x "$host/vcpkg/vcpkg" ] || "$host/vcpkg/bootstrap-vcpkg.sh" -disableMetrics

cmake -S "$host" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
	-DVCPKG_TARGET_TRIPLET="$triplet" -DVCPKG_HOST_TRIPLET="$triplet" \
	-DVCPKG_OVERLAY_TRIPLETS="$here/triplets" \
	-DVCPKG_INSTALL_OPTIONS=--clean-after-build
cmake --build "$build"

rm -rf "$stage"
mkdir -p "$stage/SimpleGraphic"
cp "$build/libSimpleGraphic.dylib" "$build"/{lcurl,lzip,lua-utf8,socket}.so "$stage/"
clang++ -std=c++17 -O2 -o "$stage/Path of Building" "$here/launcher.cpp"

# Copy each library the binaries name, and each library those name, beside them.
copy_libraries() {
	local name
	for name in $(otool -L "$1" | awk '$1 ~ /^@rpath\// {sub("@rpath/", "", $1); print $1}'); do
		if [ ! -e "$stage/$name" ]; then
			cp -L "$libdir/$name" "$stage/$name"
			copy_libraries "$stage/$name"
		fi
	done
}
for binary in "$stage"/*.dylib "$stage"/*.so; do
	copy_libraries "$binary"
done

chmod u+w "$stage"/*.dylib "$stage"/*.so

# GLFW opens ANGLE as libEGL.dylib and libGLESv2.dylib, so the libraries take those names.
for pair in "liblibEGL_angle.dylib libEGL.dylib" "liblibGLESv2_angle.dylib libGLESv2.dylib"; do
	read -r from to <<< "$pair"
	mv "$stage/$from" "$stage/$to"
	install_name_tool -id "@rpath/$to" "$stage/$to"
	for binary in "$stage"/*.dylib "$stage"/*.so; do
		install_name_tool -change "@rpath/$from" "@rpath/$to" "$binary"
	done
done

# Every binary looks for its libraries in its own folder, and is signed again after the edits above.
for binary in "$stage"/*.dylib "$stage"/*.so; do
	otool -l "$binary" | grep -q "path @loader_path " || install_name_tool -add_rpath @loader_path "$binary"
	codesign --force --sign - "$binary"
done

# The Lua libraries and fonts are shared with the Windows runtime.
cp -R "$repo/runtime/lua" "$stage/lua"
cp -R "$repo/runtime/SimpleGraphic/Fonts" "$stage/SimpleGraphic/Fonts"

echo "Runtime staged in $stage"
