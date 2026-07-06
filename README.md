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

If your Qt kit isn't at `~/Qt/6.10.3/gcc_64`, point the script at it:
`QT_DIR=~/Qt/<ver>/gcc_64 ./build.sh`.

For **Android**, open the folder in **Qt Creator**, pick an Android kit, and Run.

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
