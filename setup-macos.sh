#!/usr/bin/env bash
#
# Bootstrap a fresh macOS machine to build this app: installs the toolchain
# (Homebrew, Ninja, aqtinstall) and Qt with the Multimedia module, so that
# ./build.sh works afterwards. Safe to re-run — each step is skipped when it is
# already satisfied.
#
# Usage:
#   ./setup-macos.sh              # install the macOS Qt kit
#   INSTALL_IOS=1 ./setup-macos.sh  # also install the iOS Qt kit
#
# Override the Qt version or where it gets installed:
#   QT_VERSION=6.10.3 QT_BASE="$HOME/Qt" ./setup-macos.sh
#
set -euo pipefail

QT_VERSION="${QT_VERSION:-6.10.3}"
QT_BASE="${QT_BASE:-$HOME/Qt}"
MIN_XCODE_MAJOR=16

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "error: this script is for macOS only." >&2
    exit 1
fi

# ---- Xcode ----------------------------------------------------------------
# ZXing uses C++20 parenthesized aggregate initialization, which the Clang in
# Xcode 15.x rejects, so a full, recent Xcode is required (not just the CLI
# tools).
echo ">> Checking Xcode"
if ! xcodebuild -version >/dev/null 2>&1; then
    echo "error: full Xcode not found (only the command-line tools, or none)." >&2
    echo "       Install Xcode from the App Store, then:" >&2
    echo "         sudo xcode-select -s /Applications/Xcode.app" >&2
    echo "         sudo xcodebuild -license accept" >&2
    exit 1
fi
XCODE_VER="$(xcodebuild -version | awk 'NR==1 {print $2}')"
if (( ${XCODE_VER%%.*} < MIN_XCODE_MAJOR )); then
    echo "error: Xcode $XCODE_VER is too old; need ${MIN_XCODE_MAJOR}+." >&2
    exit 1
fi
echo "   Xcode $XCODE_VER OK"

# ---- Homebrew -------------------------------------------------------------
echo ">> Ensuring Homebrew"
if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi

# ---- Build tools ----------------------------------------------------------
echo ">> Installing Ninja + pipx"
brew list ninja >/dev/null 2>&1 || brew install ninja
brew list pipx  >/dev/null 2>&1 || brew install pipx
pipx ensurepath >/dev/null 2>&1 || true
export PATH="$HOME/.local/bin:$PATH"   # where pipx puts shims for this session

echo ">> Installing aqtinstall (Qt installer)"
command -v aqt >/dev/null 2>&1 || pipx install aqtinstall

# ---- Qt -------------------------------------------------------------------
install_qt() {
    local target="$1" kit_subdir="$2"; shift 2
    local kit_dir="$QT_BASE/$QT_VERSION/$kit_subdir"
    if [[ -x "$kit_dir/bin/qt-cmake" ]]; then
        echo ">> Qt $QT_VERSION ($target) already at $kit_dir"
        return
    fi
    echo ">> Installing Qt $QT_VERSION ($target) + Multimedia into $QT_BASE"
    aqt install-qt mac "$target" "$QT_VERSION" "$@" \
        --outputdir "$QT_BASE" --modules qtmultimedia
}

install_qt desktop macos clang_64
if [[ "${INSTALL_IOS:-0}" == "1" ]]; then
    install_qt ios ios
fi

# ---------------------------------------------------------------------------
echo
echo ">> Done. Build with:"
echo "     ./build.sh              # debug"
echo "     ./build.sh release run  # release, then launch qrreader.app"
if [[ "${INSTALL_IOS:-0}" == "1" ]]; then
    echo "     ./build.sh ios          # iOS device build (unsigned)"
    echo "     ./build.sh ios sim run  # build and run in the simulator"
fi
if [[ "$QT_BASE" != "$HOME/Qt" ]]; then
    echo "   (non-default QT_BASE: pass QT_DIR=$QT_BASE/$QT_VERSION/macos to build.sh)"
fi
