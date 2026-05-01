// BatteryIndicator.qml
// Small horizontal glassmorphism pill: Nerd Font battery icon + percentage.
// Reads from /sys/class/power_supply/BAT0 via a looping bash process.

import Quickshell.Io
import QtQuick

Item {
    id: root

    // ── Battery state ──────────────────────────────────────────────────────
    property int  level:    100
    property bool charging: false

    implicitWidth:  pillRow.implicitWidth
    implicitHeight: pillRow.implicitHeight

    // ── Looping process: capacity (refreshes every 60 s) ──────────────────
    Process {
        command: ["bash", "-c",
                  "while true; do cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100; sleep 60; done"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                const n = parseInt(line.trim())
                if (!isNaN(n)) root.level = n
            }
        }
    }

    // ── Looping process: charging status ──────────────────────────────────
    Process {
        command: ["bash", "-c",
                  "while true; do cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo Unknown; sleep 60; done"]
        running: true
        stdout: SplitParser {
            onRead: (line) => { root.charging = line.trim() === "Charging" }
        }
    }

    // ── Derived display values ─────────────────────────────────────────────
    property color iconColor: {
        if (root.charging)   return "#4ade80"
        if (root.level > 50) return "#e5e7eb"
        if (root.level > 20) return "#fbbf24"
        return "#f87171"
    }

    // Nerd Font battery icons (Material Design)
    property string batIcon: {
        if (root.charging)     return "\u{F0084}"  // mdi-battery-charging
        if (root.level >= 90)  return "\u{F0079}"  // mdi-battery
        if (root.level >= 80)  return "\u{F007A}"  // mdi-battery-80
        if (root.level >= 60)  return "\u{F007C}"  // mdi-battery-60
        if (root.level >= 40)  return "\u{F007E}"  // mdi-battery-40
        if (root.level >= 20)  return "\u{F0080}"  // mdi-battery-20
        return "\u{F0082}"                          // mdi-battery-outline
    }

    // ── Battery Content ────────────────────────────────────────────────────
    Row {
        id: pillRow
        anchors.centerIn: parent
        spacing: 6

        // Battery icon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:  root.batIcon
            font {
                family:    "JetBrainsMono Nerd Font"
                pixelSize: 18
            }
            color: root.iconColor
            Behavior on color { ColorAnimation { duration: 500 } }
        }

        // Percentage
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:  root.level + "%"
            font {
                family:    "Outfit"
                pixelSize: 16
                weight:    Font.Medium
            }
            color: Qt.rgba(1, 1, 1, 0.80)
        }
    }
}
