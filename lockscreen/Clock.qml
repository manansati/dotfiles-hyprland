// Clock.qml
import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property string _time: Qt.formatDateTime(new Date(), "hh:mm")

    implicitWidth:  timeText.implicitWidth
    implicitHeight: timeText.implicitHeight

    Text {
        id: timeText
        text: root._time
        visible: false
        font {
            family: "Outfit"
            pixelSize: 120
            weight: Font.Bold
            letterSpacing: -1
        }
    }

    LinearGradient {
        id: gradientText
        anchors.fill: timeText
        source: timeText
        visible: false
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#9aa0a6" } // Metallic silver
            GradientStop { position: 1.0; color: "#ffffff" } // Pure white
        }
    }

    MultiEffect {
        id: effect
        source: gradientText
        anchors.fill: gradientText
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.7)
        shadowBlur: 1.5
        shadowVerticalOffset: 8
        shadowHorizontalOffset: 0
    }

    // ── 1-second timer ─────────────────────────────────────────────────────
    Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: {
            const now = Qt.formatDateTime(new Date(), "hh:mm")
            if (now !== root._time) {
                root._time = now
                pulseAnim.start()
            }
        }
    }

    SequentialAnimation {
        id: pulseAnim
        NumberAnimation { target: effect; property: "opacity"; to: 0.6; duration: 200; easing.type: Easing.OutQuad }
        NumberAnimation { target: effect; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.InQuad }
    }
}
