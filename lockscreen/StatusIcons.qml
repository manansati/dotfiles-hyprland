// StatusIcons.qml
import Quickshell.Io
import QtQuick

Item {
    id: root
    width: row.width
    height: 38

    property bool expanded: false

    Row {
        id: row
        anchors.right: parent.right
        spacing: 15
        layoutDirection: Qt.RightToLeft

        // 1. Toggle Button (Power Icon)
        Item {
            width: 38
            height: 38
            Text {
                anchors.centerIn: parent
                text: root.expanded ? "\u{F0156}" : "\u{F0425}" // mdi-close or mdi-power
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                color: toggleArea.containsMouse ? Qt.rgba(1, 1, 1, 1.0) : Qt.rgba(1, 1, 1, 0.8)
                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                scale: toggleArea.pressed ? 0.85 : 1.0
            }
            MouseArea {
                id: toggleArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }

        // 2. Power Off (Actual action)
        Item {
            width: root.expanded ? 38 : 0
            height: 38
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            clip: true
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            
            Process { id: powerProc; command: ["systemctl", "poweroff"]; running: false }
            Text {
                anchors.centerIn: parent
                text: "\u{F0425}" // mdi-power
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                color: powerArea.containsMouse ? Qt.rgba(1.00, 0.40, 0.40, 0.95) : Qt.rgba(1, 1, 1, 0.60)
                scale: powerArea.pressed ? 0.85 : 1.0
                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                id: powerArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: powerProc.running = true
            }
        }

        // 3. Restart
        Item {
            width: root.expanded ? 38 : 0
            height: 38
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            clip: true
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            
            Process { id: restartProc; command: ["systemctl", "reboot"]; running: false }
            Text {
                anchors.centerIn: parent
                text: "\u{F0709}" // mdi-restart
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                color: restartArea.containsMouse ? Qt.rgba(0.40, 0.80, 1.00, 0.95) : Qt.rgba(1, 1, 1, 0.60)
                scale: restartArea.pressed ? 0.85 : 1.0
                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                id: restartArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: restartProc.running = true
            }
        }

        // 4. Logout
        Item {
            width: root.expanded ? 38 : 0
            height: 38
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            clip: true
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            
            Process { id: logoutProc; command: ["hyprctl", "dispatch", "exit"]; running: false }
            Text {
                anchors.centerIn: parent
                text: "\u{F0343}" // mdi-logout
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                color: logoutArea.containsMouse ? Qt.rgba(1.0, 0.82, 0.30, 0.95) : Qt.rgba(1, 1, 1, 0.60)
                scale: logoutArea.pressed ? 0.85 : 1.0
                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                id: logoutArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: logoutProc.running = true
            }
        }
    }
}
