// PasswordBox.qml
// 300×45 glassmorphism password input with shake animation on failure.
// Emits submit(password) when Enter is pressed.

import QtQuick

Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────────
    property bool authFailed: false
    property bool shaking:    false

    signal submit(string password)

    function clearField() { field.text = "" }
    function grabFocus()  { field.forceActiveFocus() }

    // ── Size ──────────────────────────────────────────────────────────────
    implicitWidth:  260
    implicitHeight: 40

    // ── Shake animation (horizontal jerk) ─────────────────────────────────
    property real _shakeX: 0

    SequentialAnimation {
        id: shakeAnim
        running: root.shaking
        NumberAnimation { target: root; property: "_shakeX"; to:  9;  duration: 55; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "_shakeX"; to: -8;  duration: 55; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "_shakeX"; to:  6;  duration: 55; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "_shakeX"; to: -5;  duration: 55; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "_shakeX"; to:  3;  duration: 55; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "_shakeX"; to:  0;  duration: 55; easing.type: Easing.OutQuad }
    }

    // ── Glass container ───────────────────────────────────────────────────
    Rectangle {
        id: glass
        x:      root._shakeX
        width:  root.implicitWidth
        height: root.implicitHeight
        radius: root.implicitHeight / 2   // pill shape

        // Background fill
        color: root.authFailed
               ? Qt.rgba(0.95, 0.20, 0.20, 0.12)
               : Qt.rgba(1.00, 1.00, 1.00, 0.08)

        // Border
        border.width: 0.5
        border.color: root.authFailed
                      ? Qt.rgba(1.00, 0.35, 0.35, 0.75)
                      : (field.activeFocus
                         ? Qt.rgba(1, 1, 1, 0.45)
                         : Qt.rgba(1, 1, 1, 0.20))

        Behavior on color        { ColorAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        // Focus inner highlight ring
        Rectangle {
            anchors { fill: parent; margins: -1 }
            radius:   parent.radius + 1
            color:    "transparent"
            border.width: 1
            border.color: field.activeFocus
                          ? Qt.rgba(1, 1, 1, 0.10)
                          : "transparent"
            Behavior on border.color { ColorAnimation { duration: 250 } }
        }

        // ── Lock icon (Material Design) ───────────────────────────────────
        Text {
            id: lockIcon
            anchors {
                left:           parent.left
                leftMargin:     16
                verticalCenter: parent.verticalCenter
            }
            text: "\u{F033E}"  // mdi-lock
            font {
                family:    "JetBrainsMono Nerd Font"
                pixelSize: 16
            }
            color: root.authFailed
                   ? Qt.rgba(1.0, 0.40, 0.40, 0.90)
                   : Qt.rgba(1, 1, 1, 0.40)
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // ── Text input ────────────────────────────────────────────────────
        TextInput {
            id: field
            anchors {
                left:           lockIcon.right
                leftMargin:     10
                right:          parent.right
                rightMargin:    16
                verticalCenter: parent.verticalCenter
            }

            echoMode:          TextInput.Password
            passwordCharacter: "✦"
            passwordMaskDelay: 0
            cursorVisible:     activeFocus

            font {
                family:       "Outfit"
                pixelSize:    17
                letterSpacing: 3
            }
            color:          Qt.rgba(1, 1, 1, 0.90)
            selectionColor: Qt.rgba(1, 1, 1, 0.25)

            Keys.onReturnPressed: root.submit(text)
            Keys.onEnterPressed:  root.submit(text)
            Keys.onEscapePressed: text = ""

            // Placeholder text (shown when empty)
            Text {
                anchors.fill: parent
                visible:      field.text.length === 0
                text:         "Enter password"
                font:         field.font
                color:        Qt.rgba(1, 1, 1, 0.25)
                verticalAlignment: Text.AlignVCenter
            }

            // Blinking cursor (only shown when empty so it doesn't overlap dots)
            Rectangle {
                visible:  field.activeFocus && field.text.length === 0
                width:    1.5
                height:   18
                radius:   1
                color:    Qt.rgba(1, 1, 1, 0.75)
                anchors.verticalCenter: parent.verticalCenter
                x: 0

                SequentialAnimation on opacity {
                    loops:   Animation.Infinite
                    running: parent.visible
                    NumberAnimation { to: 0;   duration: 520; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 520; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // ── Error label ────────────────────────────────────────────────────────
    Text {
        anchors {
            top:              glass.bottom
            topMargin:        8
            horizontalCenter: parent.horizontalCenter
        }
        text:  "Incorrect password"
        color: Qt.rgba(1.0, 0.38, 0.38, root.authFailed ? 1.0 : 0.0)
        font {
            family:    "Outfit"
            pixelSize: 11
            weight:    Font.Light
            letterSpacing: 1
        }
        Behavior on color { ColorAnimation { duration: 300 } }
    }
}
