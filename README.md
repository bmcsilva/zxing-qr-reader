# zxing-qr-reader

An Android QR-code reader built with Qt 6 / QML. It shows the decoded value in
full — never truncated — and lets you select and copy it. Decoding is done by
the **ZXing** library.

## What it does

- **Camera screen** — opens the camera with a viewfinder and a sweeping line.
  As soon as `QrScanner` (C++ + ZXing) recognises a code, it moves to the
  result screen.
- **Result screen** — the value is shown in a text area that wraps and scrolls,
  so long payloads are never cut off. From here you can:
  - **Select all** and **Copy** to the clipboard;
  - **Open link** when the value is a URL;
  - go **back** to the camera.

## Notes

- **Automatic language.** UI strings are written in English; translations for
  Portuguese (pt-PT), Spanish, French and British English live in
  [i18n/](i18n/). On start-up `main.cpp` loads the one matching the device
  language.
- **Light / dark theme.** Follows the device setting and can be pinned with the
  sun/moon button. All colours live in [Theme.qml](Theme.qml).
- **Camera permission.** Handled in C++ by [Platform](src/platform.h): granted
  immediately on desktop, requested from the system on Android. The CAMERA
  permission is injected automatically by linking Qt Multimedia; the
  [android/](android) folder only supplies the icon and app name.
- **Demo shortcut (F5).** In debug builds, pressing `F5` fakes a scan and opens
  the result screen without needing a real code in front of the camera. Each
  press uses a different sample (URL, Wi-Fi, vCard). It is disabled in release
  builds.

## Layout

```
zxing-qr-reader/
├── CMakeLists.txt
├── main.cpp                 start-up: language, icon, window
├── Main.qml                 camera and result screens
├── Theme.qml                colour palette (light/dark)
├── src/
│   ├── qrscanner.{h,cpp}    camera frames -> ZXing
│   └── platform.{h,cpp}     camera permission + build info
├── icon/appicon.png         app icon (512x512 master)
├── android/                 launcher icon (per density) + app name
└── i18n/                    pt-PT, es, fr, en-GB translations
```

## Build and run

Needs Qt 6.10+ and a C++20 compiler. ZXing is fetched automatically by CMake
(the first configure needs network access). `qt-cmake` is the `qt-cmake` from
your Qt kit, e.g. `~/Qt/6.10.3/gcc_64/bin/qt-cmake`.

Debug build (enables the F5 demo shortcut):

```bash
qt-cmake -S . -B build-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug
./build-debug/qrreader
```

Release build:

```bash
qt-cmake -S . -B build-release -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build-release
./build-release/qrreader
```

You can also open the folder in **Qt Creator** and hit *Run* — for Android,
pick an Android kit and run it on the device.
