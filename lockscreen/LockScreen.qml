// LockScreen.qml
// Main lock screen window. Auth is hardcoded: password "2255" → Qt.quit().

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: root

    // ── Wayland layer-shell ────────────────────────────────────────────────
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace:     "lockscreen"
    exclusionMode:               ExclusionMode.Ignore

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"

    // ── State ─────────────────────────────────────────────────────────────
    property string wallpaperPath: "/home/manan/Pictures/wallpaper.png"
    property bool   authFailed:    false
    property bool   shaking:       false

    // ── Hardcoded authentication ───────────────────────────────────────────
    function authenticate(password) {
        if (password === "2255") {
            slideUpAnim.start()
        } else {
            root.authFailed = true
            root.shaking    = true
            shakeResetTimer.restart()
        }
    }

    Timer {
        id: shakeResetTimer
        interval: 700
        onTriggered: {
            root.shaking   = false
            root.authFailed = false
            pwBox.clearField()
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Background instantly hides the desktop for privacy
    // ─────────────────────────────────────────────────────────────────────
    Image {
        id: bgLayer
        anchors.fill: parent
        source: "wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        
        // Dark overlay for text readability
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.4
        }
    }

    Item {
        id: mainContainer
        width: root.width
        height: root.height
        y: -root.height

        NumberAnimation on y {
            id: slideDownAnim
            to: 0
            duration: 900
            easing.type: Easing.OutQuint
        }

        NumberAnimation {
            id: slideUpAnim
            target: mainContainer
            property: "y"
            to: -root.height
            duration: 800
            easing.type: Easing.InQuint
            onFinished: Qt.quit()
        }

        // Delay startup animation slightly to let GPU textures upload and Wayland surface map
        Timer {
            interval: 50
            running: true
            onTriggered: slideDownAnim.start()
        }


        // ─────────────────────────────────────────────────────────────────────
        // TOP-LEFT: Battery
        // ─────────────────────────────────────────────────────────────────────
        BatteryIndicator {
            id: batIndicator
            anchors {
                top:        parent.top
                left:       parent.left
                topMargin:  8
                leftMargin: 24
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // TOP-RIGHT: Status icons
        // ─────────────────────────────────────────────────────────────────────
        StatusIcons {
            id: statusRow
            anchors {
                top:         parent.top
                right:       parent.right
                topMargin:   8
                rightMargin: 8
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // CENTRE: Clock → Date → Password
        // ─────────────────────────────────────────────────────────────────────
        Column {
            id: centerCol
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter:   parent.verticalCenter
                verticalCenterOffset: -30
            }
            spacing: 0

            Clock { anchors.horizontalCenter: parent.horizontalCenter }

            Text {
                id: dateLbl
                anchors.horizontalCenter: parent.horizontalCenter
                transform: Translate { y: -18 } // Shifts it up to cut out font padding
                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                font {
                    family:       "Outfit"
                    pixelSize:    15
                    weight:       Font.Medium
                    letterSpacing: 3
                }
                color: Qt.rgba(1, 1, 1, 0.50)
            }

            Item { width: 1; height: 40 }

            PasswordBox {
                id: pwBox
                anchors.horizontalCenter: parent.horizontalCenter
                authFailed: root.authFailed
                shaking:    root.shaking
                onSubmit:   (pwd) => root.authenticate(pwd)
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // BOTTOM: Media player
        // ─────────────────────────────────────────────────────────────────────
        MediaPlayer {
            anchors {
                bottom:           parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin:     72
            }
        }

        Component.onCompleted: pwBox.grabFocus()
    }

    Timer {
        interval: 60000
        running:  true
        repeat:   true
        onTriggered: dateLbl.text = Qt.formatDateTime(new Date(), "dddd, MMMM d")
    }
}
