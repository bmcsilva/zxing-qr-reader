#!/usr/bin/env bash
#
# Configure + build the desktop app with the right qt-cmake, so you don't have
# to remember the Qt kit path or put it on PATH by hand.
#
# Usage:
#   ./build.sh            # debug build (enables the F5 demo shortcut)
#   ./build.sh release    # release build
#   ./build.sh debug run  # build, then launch the app
#
# Override the Qt kit if yours lives elsewhere:
#   QT_DIR=~/Qt/6.10.3/gcc_64 ./build.sh
#
set -euo pipefail

# Run from the repo root regardless of where the script is called from.
cd "$(dirname "$0")"

# Where the desktop Qt kit lives. Override with the QT_DIR env var.
QT_DIR="${QT_DIR:-$HOME/Qt/6.10.3/gcc_64}"
QT_CMAKE="$QT_DIR/bin/qt-cmake"

if [[ ! -x "$QT_CMAKE" ]]; then
    echo "error: qt-cmake not found at $QT_CMAKE" >&2
    echo "       set QT_DIR to your Qt kit, e.g. QT_DIR=~/Qt/6.10.3/gcc_64 $0" >&2
    exit 1
fi

# First positional arg: build type (debug|release). Default: debug.
BUILD_TYPE="Debug"
case "${1:-debug}" in
    debug|Debug)     BUILD_TYPE="Debug" ;;
    release|Release) BUILD_TYPE="Release" ;;
    *) echo "error: unknown build type '${1}' (use debug or release)" >&2; exit 1 ;;
esac

BUILD_DIR="build-$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')"

echo ">> Configuring $BUILD_TYPE in $BUILD_DIR"
"$QT_CMAKE" -S . -B "$BUILD_DIR" -G Ninja -DCMAKE_BUILD_TYPE="$BUILD_TYPE"

echo ">> Building"
cmake --build "$BUILD_DIR"

echo ">> Done: $BUILD_DIR/qrreader"

# "run" as any later argument launches the app.
for arg in "$@"; do
    if [[ "$arg" == "run" ]]; then
        exec "./$BUILD_DIR/qrreader"
    fi
done
