pragma Singleton

import QtQuick

// Single source of colours for the whole app.
//
// By default it follows the device's light/dark setting. The sun/moon button
// pins one of the modes; toggle() switches between them.
QtObject {
    // Available modes. "Follow" obeys the operating system.
    enum Mode { Follow, Light, Dark }

    // Starts by following the device (Mode.Follow == 0).
    property int mode: 0

    readonly property bool dark: {
        if (mode === Theme.Light)
            return false
        if (mode === Theme.Dark)
            return true
        return Application.styleHints.colorScheme === Qt.Dark
    }

    // A fixed indigo/violet accent, with a second tone for subtle gradients.
    // Neutrals are hand-picked so contrast holds up in both themes.
    readonly property color accent:     dark ? "#7c8cff" : "#4e5be6"
    readonly property color accentAlt:  dark ? "#a78bfa" : "#7c5cf0"
    readonly property color accentText: "#ffffff"

    readonly property color background: dark ? "#0b0e14" : "#f3f5f9"
    readonly property color backgroundEdge: dark ? "#0f1420" : "#e9edf5"
    readonly property color surface:    dark ? "#151a23" : "#ffffff"
    readonly property color surfaceAlt: dark ? "#1e2531" : "#e9edf3"
    readonly property color line:       dark ? "#2a313d" : "#e1e6ef"
    readonly property color textStrong: dark ? "#f2f5fa" : "#0e1420"
    readonly property color textMuted:  dark ? "#93a0b4" : "#5a6576"

    // Soft shadow tint used under cards and buttons.
    readonly property color shadow: dark ? "#000000" : "#1a2440"

    function toggle() {
        mode = dark ? Theme.Light : Theme.Dark
    }
}
