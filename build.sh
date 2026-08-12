#!/usr/bin/env bash
#
# Configure + build the app with the right qt-cmake, so you don't have to
# remember the Qt kit path or put it on PATH by hand.
#
# Usage (keywords, in any order):
#   ./build.sh                   # desktop debug build (enables the F5 demo shortcut)
#   ./build.sh release           # desktop release build
#   ./build.sh run               # desktop debug build, then launch the app
#   ./build.sh ios               # iOS device build (unsigned .app)
#   ./build.sh ios simulator     # iOS build for the simulator
#   ./build.sh ios sim run       # ... and install + launch it there
#
#   debug | release      build type          (default: debug)
#   ios | desktop        what to build for   (default: desktop)
#   simulator | device   iOS SDK             (default: device)
#   run                  launch after building
#
# Overrides:
#   QT_DIR=~/Qt/6.11.1/macos ./build.sh      # exact Qt kit to use
#   QT_BASE=/opt/Qt ./build.sh               # where the Qt versions live
#   IOS_TEAM=ABCDE12345 ./build.sh ios       # sign with a development team
#
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

# Run from the repo root regardless of where the script is called from.
cd "$(dirname "$0")"

# Qt's lrelease step splits its arguments on whitespace, so a source path with a
# space in it fails deep inside the build with a confusing message. Say so here.
case "$PWD" in
    *[[:space:]]*) die "the source path contains spaces, which Qt's lrelease cannot handle: $PWD" ;;
esac

HOST_OS="$(uname -s)"

# ---- Arguments ------------------------------------------------------------
BUILD_TYPE="Debug"
TARGET="desktop"
IOS_SDK="device"
RUN=0

for arg in "$@"; do
    case "$arg" in
        debug|Debug)         BUILD_TYPE="Debug" ;;
        release|Release)     BUILD_TYPE="Release" ;;
        ios|iOS)             TARGET="ios" ;;
        desktop|mac|macos|linux) TARGET="desktop" ;;
        sim|simulator)       IOS_SDK="simulator" ;;
        device)              IOS_SDK="device" ;;
        run)                 RUN=1 ;;
        *) die "unknown argument '$arg' (use: debug, release, ios, desktop, simulator, device, run)" ;;
    esac
done

# ---- Qt kit ---------------------------------------------------------------
# The kit is laid out per-target: gcc_64 on Linux, macos on macOS, ios for iOS.
if [[ "$TARGET" == "ios" ]]; then
    [[ "$HOST_OS" == "Darwin" ]] || die "iOS builds need macOS with Xcode; this is $HOST_OS."
    QT_KIT="ios"
elif [[ "$HOST_OS" == "Darwin" ]]; then
    QT_KIT="macos"
else
    QT_KIT="gcc_64"
fi

QT_BASE="${QT_BASE:-$HOME/Qt}"

# Pick the newest installed Qt that actually has this kit, so the script keeps
# working after a Qt upgrade instead of pointing at a hardcoded version.
# `sort -V` is missing on macOS, hence the numeric sort on the dotted fields.
find_qt_dir() {
    local version
    for version in $(ls -1 "$QT_BASE" 2>/dev/null \
            | grep -E '^[0-9]+(\.[0-9]+)*$' \
            | sort -t. -k1,1n -k2,2n -k3,3n); do
        if [[ -x "$QT_BASE/$version/$QT_KIT/bin/qt-cmake" ]]; then
            QT_DIR="$QT_BASE/$version/$QT_KIT"   # keep going: last one wins
        fi
    done
}

if [[ -z "${QT_DIR:-}" ]]; then
    find_qt_dir
fi
[[ -n "${QT_DIR:-}" ]] || die "no Qt kit '$QT_KIT' found under $QT_BASE; set QT_DIR to your kit."

QT_CMAKE="$QT_DIR/bin/qt-cmake"
[[ -x "$QT_CMAKE" ]] || die "qt-cmake not found at $QT_CMAKE (set QT_DIR to your Qt kit)."

# qt-cmake is a wrapper that execs a bare `cmake`, and a non-interactive shell —
# or a machine where Qt Creator brought its own toolchain — may have neither
# cmake nor ninja on PATH. Qt ships both under Tools/, so add those when needed.
QT_TOOLS="$(dirname "$(dirname "$QT_DIR")")/Tools"
for dir in "$QT_TOOLS/CMake/CMake.app/Contents/bin" "$QT_TOOLS/CMake/bin" "$QT_TOOLS/Ninja"; do
    if [[ -d "$dir" ]]; then
        PATH="$dir:$PATH"
    fi
done
export PATH
command -v cmake >/dev/null 2>&1 || die "cmake not found on PATH, and none shipped under $QT_TOOLS."

# ---- Configure ------------------------------------------------------------
CONFIGURE_ARGS=()

if [[ "$TARGET" == "ios" ]]; then
    # Qt for iOS needs the Xcode generator: it is what builds the .app bundle,
    # compiles the launch storyboard and runs the device-side packaging steps.
    xcodebuild -version >/dev/null 2>&1 \
        || die "full Xcode not found; install it and run: sudo xcode-select -s /Applications/Xcode.app"

    # The iOS SDK alone is not enough — ibtool needs the iOS platform component
    # or the storyboard step dies with "iOS <version> Platform Not Installed".
    xcodebuild -showsdks 2>/dev/null | grep -q "iphoneos" \
        || die "Xcode has no iOS platform installed; run: xcodebuild -downloadPlatform iOS"

    BUILD_DIR="build-ios"
    CONFIGURE_ARGS+=(-G Xcode)

    # The iOS kit builds the app, but moc/rcc/qmlcachegen run on the host, so
    # Qt needs the desktop kit too. The path baked into the kit at packaging
    # time does not exist here, so point it at the matching macOS kit.
    QT_HOST_DIR="$(dirname "$QT_DIR")/macos"
    [[ -x "$QT_HOST_DIR/bin/qmake" ]] \
        || die "the desktop Qt kit is missing at $QT_HOST_DIR; iOS builds need it for the host tools (INSTALL_IOS=1 ./setup-macos.sh installs both)."
    CONFIGURE_ARGS+=(-DQT_HOST_PATH="$QT_HOST_DIR")

    if [[ "$IOS_SDK" == "simulator" ]]; then
        BUILD_DIR="build-ios-sim"
        CONFIGURE_ARGS+=(-DCMAKE_OSX_SYSROOT=iphonesimulator)
    fi

    # Without a team the build stays unsigned (see CMakeLists.txt); with one it
    # signs, which is what a build meant to run on a real device needs.
    if [[ -n "${IOS_TEAM:-}" ]]; then
        CONFIGURE_ARGS+=(-DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM="$IOS_TEAM")
    fi
else
    BUILD_DIR="build-$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')"
    # Ninja is the fast default, but do not insist on it if it is not installed.
    if command -v ninja >/dev/null 2>&1; then
        CONFIGURE_ARGS+=(-G Ninja)
    fi
    CONFIGURE_ARGS+=(-DCMAKE_BUILD_TYPE="$BUILD_TYPE")
fi

echo ">> Configuring $BUILD_TYPE for $TARGET in $BUILD_DIR (Qt: $QT_DIR)"
"$QT_CMAKE" -S . -B "$BUILD_DIR" "${CONFIGURE_ARGS[@]}"

# Xcode is a multi-config generator, so the build type is chosen here rather
# than at configure time. Single-config generators ignore --config.
echo ">> Building"
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE"

# ---- Result ---------------------------------------------------------------
# On Apple platforms the app is a .app bundle; Xcode also puts it in a
# per-configuration subfolder named after the SDK it was built against.
if [[ "$TARGET" == "ios" ]]; then
    if [[ "$IOS_SDK" == "simulator" ]]; then
        APP="$BUILD_DIR/$BUILD_TYPE-iphonesimulator/qrreader.app"
    else
        APP="$BUILD_DIR/$BUILD_TYPE-iphoneos/qrreader.app"
    fi
elif [[ "$HOST_OS" == "Darwin" ]]; then
    APP="$BUILD_DIR/qrreader.app"
else
    APP="$BUILD_DIR/qrreader"
fi

echo ">> Done: $APP"

[[ "$RUN" == 1 ]] || exit 0

# ---- Run ------------------------------------------------------------------
if [[ "$TARGET" != "ios" ]]; then
    # Launch the executable itself rather than `open`, so the app's output stays
    # in this terminal.
    if [[ "$HOST_OS" == "Darwin" ]]; then
        exec "$APP/Contents/MacOS/qrreader"
    fi
    exec "$APP"
fi

if [[ "$IOS_SDK" != "simulator" ]]; then
    echo
    echo ">> Nothing to launch: this is a device build. Install it with Xcode," \
         "or sideload the .app with AltServer."
    exit 0
fi

# A device has to be booted before simctl can install into it, so boot the
# first available iPhone unless one is already running. `open` then brings the
# Simulator window up in front of the booted device.
BUNDLE_ID="pt.bmcsilva.qrreader"

if ! xcrun simctl list devices booted | grep -q "(Booted)"; then
    DEVICE="$(xcrun simctl list devices available \
        | grep -E '^[[:space:]]+iPhone' \
        | head -1 \
        | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')"
    [[ -n "$DEVICE" ]] || die "no iPhone simulator available; add one in Xcode > Window > Devices and Simulators."
    echo ">> Booting the simulator"
    xcrun simctl boot "$DEVICE"
fi
open -a Simulator
xcrun simctl bootstatus booted -b >/dev/null

echo ">> Installing and launching $BUNDLE_ID"
xcrun simctl install booted "$APP"
exec xcrun simctl launch --console booted "$BUNDLE_ID"
