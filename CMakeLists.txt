cmake_minimum_required(VERSION 3.21)

project(QrReader VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia LinguistTools)

qt_standard_project_setup(REQUIRES 6.10)

# ---- ZXing ----
# Does the actual barcode decoding; pulled in at configure time.
include(FetchContent)
set(_QRR_PREV_CXX_STANDARD ${CMAKE_CXX_STANDARD})
set(_QRR_PREV_AUTOMOC ${CMAKE_AUTOMOC})
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC OFF)
FetchContent_Declare(
    zxing_cpp
    URL https://github.com/bmcsilva/zxing-cpp/archive/refs/heads/master.zip
    DOWNLOAD_EXTRACT_TIMESTAMP true
)
set(ZXING_READERS ON CACHE STRING "" FORCE)
set(ZXING_WRITERS OFF CACHE STRING "" FORCE)
set(ZXING_USE_BUNDLED_ZINT OFF CACHE BOOL "" FORCE)
set(ZXING_C_API OFF CACHE BOOL "" FORCE)
set(ZXING_EXAMPLES OFF CACHE BOOL "" FORCE)
set(ZXING_BLACKBOX_TESTS OFF CACHE BOOL "" FORCE)
set(ZXING_UNIT_TESTS OFF CACHE BOOL "" FORCE)
set(ZXING_DEPENDENCIES LOCAL CACHE STRING "" FORCE)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(BUILD_UNIT_TESTS OFF CACHE BOOL "" FORCE)
set(BUILD_BLACKBOX_TESTS OFF CACHE BOOL "" FORCE)
set(BUILD_PYTHON_MODULE OFF CACHE BOOL "" FORCE)
set(BUILD_C_API OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(zxing_cpp)
set(CMAKE_CXX_STANDARD ${_QRR_PREV_CXX_STANDARD})
set(CMAKE_AUTOMOC ${_QRR_PREV_AUTOMOC})

qt_add_executable(QrReader
    main.cpp
)

# The "QrReader" module URI creates a QrReader/ folder in the build tree, which
# would clash with an executable of the same name, so rename the binary.
set_target_properties(QrReader PROPERTIES OUTPUT_NAME qrreader)

# ---- Android packaging ----
# The android/ folder provides the launcher icon and app name. The CAMERA
# permission itself is still injected automatically by linking Qt6::Multimedia
# (the manifest just keeps the %%INSERT_PERMISSIONS%% placeholder for it).
if(ANDROID)
    set_property(TARGET QrReader PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
        ${CMAKE_CURRENT_SOURCE_DIR}/android)
    set_property(TARGET QrReader PROPERTY QT_ANDROID_MIN_SDK_VERSION 28)
    set_property(TARGET QrReader PROPERTY QT_ANDROID_TARGET_SDK_VERSION 34)
endif()

# App icon shown in the desktop window title bar / task switcher.
qt_add_resources(QrReader "appicon"
    PREFIX "/"
    BASE ${CMAKE_CURRENT_SOURCE_DIR}/icon
    FILES icon/appicon.png
)

# Theme.qml is a singleton: one palette shared across the whole app.
set_source_files_properties(Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(QrReader
    URI QrReader
    VERSION 1.0
    QML_FILES
        Main.qml
        Theme.qml
    RESOURCES
        icons/sun.png
        icons/moon.png
    SOURCES
        src/qrscanner.h
        src/qrscanner.cpp
        src/platform.h
        src/platform.cpp
)

target_include_directories(QrReader PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(QrReader PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Multimedia
    ZXing::ZXing
)

# ---- Apple multimedia backend ----
# On iOS/macOS Qt 6.8+ defaults to the FFmpeg media backend, but the official
# Qt for iOS package ships the plugin stub without the FFmpeg libraries, so the
# link fails with hundreds of undefined _av_* symbols. The app only needs the
# camera, which the native darwin (AVFoundation) backend fully covers, so drop
# the FFmpeg plugin from the link on Apple platforms.
if(APPLE)
    qt_import_plugins(QrReader EXCLUDE Qt6::QFFmpegMediaPlugin)
endif()

# ---- Translations ----
# Compiles the .ts files to .qm and embeds them under qrc:/i18n. main.cpp then
# loads whichever one matches the device language (English is the source).
qt_add_translations(QrReader
    TS_FILES
        i18n/QrReader_pt_PT.ts
        i18n/QrReader_es.ts
        i18n/QrReader_fr.ts
        i18n/QrReader_en_GB.ts
    RESOURCE_PREFIX "/i18n"
)
