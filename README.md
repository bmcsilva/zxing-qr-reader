# zxing-qr-reader

An Android/desktop QR-code reader built with Qt 6 / QML. It decodes with the
**ZXing** library and shows the value in full — never truncated — so you can
select, copy, or open it as a link. Follows the device light/dark theme, with a
manual sun/moon toggle.

## Build and run

Needs **Qt 6.10+** and a **C++20** compiler. ZXing is fetched automatically on
the first configure (needs network access). Developed and built on **Ubuntu
24.04**.

`qt-cmake` lives in your Qt kit and isn't on the PATH, so use the
[build.sh](build.sh) wrapper — it points at the right kit and runs the
configure + build steps for you:

```bash
./build.sh              # debug build (enables the F5 "fake scan" shortcut)
./build.sh release      # release build
./build.sh debug run    # build, then launch
```

The script picks the newest kit it finds under `~/Qt` for the platform you are
building for. To use a different one, point it there explicitly:
`QT_DIR=~/Qt/<ver>/gcc_64 ./build.sh` (or set `QT_BASE` if your Qt versions
don't live in `~/Qt`).

For **Android**, open the folder in **Qt Creator**, pick an Android kit, and Run.

## Building on macOS

On a fresh Mac, [setup-macos.sh](setup-macos.sh) installs the whole toolchain
(Homebrew, Ninja, `aqt`) and Qt with the Multimedia module — then `build.sh`
works exactly as on Linux (it auto-detects the `~/Qt/<ver>/macos` kit):

```bash
./setup-macos.sh        # one-time environment setup (skips what's present)
./build.sh              # debug
./build.sh release run  # release, then launch qrreader.app
```

The setup script needs **Xcode 16 or newer** already installed from the App
Store. `xcode-select --install` only gives the command-line tools, but ZXing
needs a full recent Xcode: older Xcode 15.x ships a Clang without C++20
*parenthesized aggregate initialization* and fails to compile ZXing with
`no matching function for call to 'construct_at'`.

Prefer to install Qt yourself (e.g. via the Qt online installer)? Make sure the
**Multimedia** module is included. `build.sh` also adds the `cmake` and `ninja`
that Qt ships under `~/Qt/Tools` to the PATH when the system has none of its
own, which is the usual case on a machine set up only with Qt Creator.

Apple-specific behaviour, handled in [CMakeLists.txt](CMakeLists.txt):

- The app is built as a **`.app` bundle**. macOS is case-insensitive, so a bare
  `qrreader` binary would collide with the `QrReader/` QML module folder; the
  bundle (`qrreader.app`) avoids that and is the correct form for a GUI app.
- The **FFmpeg multimedia backend is excluded**; Apple builds use the native
  **darwin (AVFoundation)** backend. Qt's iOS package ships only the FFmpeg
  plugin stub without the FFmpeg libraries, which otherwise breaks the link with
  hundreds of undefined `_av_*` symbols.
- **Camera permission** is declared via a custom `Info.plist` carrying
  `NSCameraUsageDescription`; without it the OS terminates the app on first
  camera access. macOS and iOS need different keys, so they get one each:
  [platform/Info.macos.plist.in](platform/Info.macos.plist.in) and
  [platform/Info.ios.plist.in](platform/Info.ios.plist.in).

## Building for iOS

`build.sh` drives the iOS build too (`INSTALL_IOS=1 ./setup-macos.sh` installs
the kit). It uses the Xcode generator, which is what produces the `.app` bundle
and compiles the launch storyboard:

```bash
./build.sh ios              # device build (unsigned), Debug
./build.sh ios release      # device build, Release
./build.sh ios simulator    # build against the simulator SDK
./build.sh ios sim run      # ... and install + launch it in the simulator
```

Because the iOS kit only ships the target libraries, the build also needs the
**desktop** kit for the host-side tools (`moc`, `rcc`, `qmlcachegen`);
`build.sh` finds it next to the iOS kit and passes it as `QT_HOST_PATH`. The
path baked into the kit at packaging time does not exist on your machine, so
without this the configure step fails.

Three more things have to be in place, or the build fails before it produces an
`.app`:

- **Signing, or the choice to skip it.** By default the build is left
  **unsigned** — enough to check that the code compiles, and what a build meant
  for sideloading with AltServer wants. To sign instead, pass a development
  team: `IOS_TEAM=ABCDE12345 ./build.sh ios release`. Sign in under *Xcode →
  Settings → Accounts* with any Apple ID first; a free personal team is enough
  for running on your own device.

- **Xcode's iOS platform component.** The iOS SDK alone is not enough: `ibtool`
  compiles the launch storyboard and fails with `iOS <version> Platform Not
  Installed` without it. Install it once with `xcodebuild -downloadPlatform iOS`
  (several GB). `build.sh` checks for it and says so up front.

- **A source path with no spaces.** Qt's `lrelease` step splits the path on
  whitespace and dies with `Cannot open <path-up-to-the-space>: file to open is
  a directory`, leaving a stray folder named after the rest of the path.
  `build.sh` refuses to start in such a path.

Qt Creator also works: open the folder, pick the **iOS** kit, and Build (set the
development team under *Projects → iOS kit → Build*).

> Recent Qt targets **iOS 17 or newer** (`CMAKE_OSX_DEPLOYMENT_TARGET` is pinned
> by the Qt kit), so the app will not install on devices that stop at iOS 15 or
> 16 — an iPhone 7/7 Plus, for example.

## Signing an Android release

Android only installs/publishes a **signed** APK/AAB. Debug builds use a
throwaway key automatically; a release needs your own permanent key. It is
personal and secret, so it is **not** in this repo — create your own.

**1. Create a keystore (once)**, kept outside the repo. `keytool` ships with the
JDK:

```bash
mkdir -p ~/keys
keytool -genkeypair -v -keystore ~/keys/qrreader-release.keystore \
  -alias qrreader -keyalg RSA -keysize 2048 -validity 10000
```

> ⚠️ Back up the keystore and its password. Lose them and you can never ship an
> update to the same Play Store app. Never commit it.

**2. Sign** in Qt Creator: *Projects → Android kit → Build → Build Android APK →
Sign package*, then build in Release (tick *Build .aab* for the Play Store). On
the command line, `androiddeployqt` reads `QT_ANDROID_KEYSTORE_PATH`,
`QT_ANDROID_KEYSTORE_ALIAS`, `QT_ANDROID_KEYSTORE_STORE_PASS` and
`QT_ANDROID_KEYSTORE_KEY_PASS`.

**3. Before publishing:** set your own `package` id in
[android/AndroidManifest.xml](android/AndroidManifest.xml) (reverse-domain, e.g.
`com.yourname.qrreader` — it can't change once published) and bump `versionCode`
on every upload.
