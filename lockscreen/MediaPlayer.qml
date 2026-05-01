// MediaPlayer.qml
// MPRIS media player widget with self-fetched YouTube thumbnails.
// Firefox never exposes trackArtUrl via MPRIS, so we extract the YouTube
// video ID from xesam:url and build the thumbnail URL ourselves.

import Quickshell.Services.Mpris
import QtQuick

Item {
    id: root

    // ── Active player selection ────────────────────────────────────────────
    property var player: null

    function updatePlayer() {
        const players = Mpris.players.values;
        if (!players || players.length === 0) {
            if (root.player !== null) root.player = null;
            return;
        }
        let active = null;
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying) { active = players[i]; break; }
        }
        if (!active) active = players[0];
        if (root.player !== active) root.player = active;
    }

    Component.onCompleted: updatePlayer()

    visible: root.player !== null
    opacity: root.player !== null ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    implicitWidth:  420
    implicitHeight: card.implicitHeight

    // ── Position tracking ──────────────────────────────────────────────────
    property real posSec:  0.0
    property real durSec:  0.0
    property real progress: durSec > 0 ? Math.min(1.0, posSec / durSec) : 0.0
    property bool dragging: false

    onPlayerChanged: {
        if (player) {
            player.positionChanged();
            posSec = player.position;
            durSec = player.length;
        } else {
            posSec = 0; durSec = 0;
        }
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onPositionChanged() { if (!root.dragging && root.player) root.posSec = root.player.position; }
        function onLengthChanged()   { if (root.player) root.durSec = root.player.length; }
        function onTrackChanged()    {
            if (root.player) {
                root.player.positionChanged();
                root.posSec = root.player.position;
                root.durSec = root.player.length;
            }
        }
        function onPlaybackStateChanged() { root.updatePlayer(); }
        function onIsPlayingChanged()     { root.updatePlayer(); }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            root.updatePlayer();
            if (root.player && root.player.isPlaying && !root.dragging) {
                root.player.positionChanged();
                root.posSec = root.player.position;
                root.durSec = root.player.length;
            }
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    function fmtTime(s) {
        const t = Math.max(0, Math.floor(s));
        const m = Math.floor(t / 60);
        const ss = t % 60;
        return m + ":" + (ss < 10 ? "0" : "") + ss;
    }

    // Build a composite string of all identifiers for pattern matching
    function allFields() {
        if (!root.player) return "";
        const parts = [
            root.player.trackTitle,
            root.player.identity,
            root.player.desktopEntry,
            root.player.trackArtUrl,
            (root.player.metadata && root.player.metadata["xesam:url"]) ? root.player.metadata["xesam:url"] : ""
        ];
        return parts.map(p => p ? p.toString() : "").join(" ").toLowerCase();
    }

    // Extract YouTube video ID from the xesam:url metadata field.
    // Returns "" if not a YouTube URL.
    function getYouTubeThumbnailUrl() {
        if (!root.player || !root.player.metadata) return "";
        const metaUrl = root.player.metadata["xesam:url"];
        if (!metaUrl) return "";
        const url = metaUrl.toString();
        // Match standard watch URLs: youtube.com/watch?v=VIDEO_ID
        const watchMatch = url.match(/youtube\.com\/watch\?.*v=([a-zA-Z0-9_-]{11})/);
        if (watchMatch) return "https://img.youtube.com/vi/" + watchMatch[1] + "/mqdefault.jpg";
        // Match short URLs: youtu.be/VIDEO_ID
        const shortMatch = url.match(/youtu\.be\/([a-zA-Z0-9_-]{11})/);
        if (shortMatch) return "https://img.youtube.com/vi/" + shortMatch[1] + "/mqdefault.jpg";
        return "";
    }

    // Determine the best thumbnail source URL.
    // Priority: MPRIS artUrl > YouTube self-fetch > empty string
    function getThumbnailUrl() {
        if (!root.player) return "";
        const artUrl = root.player.trackArtUrl ? root.player.trackArtUrl.toString() : "";
        if (artUrl !== "") return artUrl;
        return getYouTubeThumbnailUrl();
    }

    // Determine the site logo glyph if recognized. Returns "" if not recognised.
    function getSiteIcon() {
        const all = allFields();
        if (all.includes("instagram"))             return "\uf16d";
        if (all.includes("reddit"))                return "\uf281";
        if (all.includes("youtube") || all.includes("ytimg")) return "\uf167";
        if (all.includes("spotify") || all.includes("scdn")) return "\uf1bc";
        if (all.includes("tiktok") || all.includes("tik tok")) return "\ue07b";
        if (all.includes("twitch") || all.includes("ttvnw"))  return "\uf1e8";
        if (all.includes("soundcloud") || all.includes("sndcdn")) return "\uf1be";
        return "";
    }

    // ── Glass card ─────────────────────────────────────────────────────────
    Rectangle {
        id: card
        width:   root.implicitWidth
        implicitHeight: cardCol.implicitHeight + 24
        radius:  18
        color:   Qt.rgba(1,1,1,0.08)
        border.width: 1
        border.color: Qt.rgba(1,1,1,0.18)

        Column {
            id: cardCol
            anchors { top: parent.top; left: parent.left; right: parent.right
                      topMargin: 14; leftMargin: 14; rightMargin: 14 }
            spacing: 10

            // ── Top row: art | info | controls ────────────────────────────
            Row {
                width:   parent.width
                spacing: 12

                // ── Artwork box ───────────────────────────────────────────
                Rectangle {
                    id: artBox
                    width: 52; height: 52; radius: 10
                    color:  Qt.rgba(1,1,1,0.10)
                    border.width: 1; border.color: Qt.rgba(1,1,1,0.18)
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter

                    // Layer 1 (bottom): Thumbnail
                    // Always present so Qt never skips the network fetch.
                    Image {
                        id: artImg
                        anchors.fill: parent
                        source: root.getThumbnailUrl()
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        // Keep invisible until ready so broken image icon never shows
                        opacity: 0
                        onStatusChanged: {
                            if (status === Image.Ready) opacity = 1;
                            else opacity = 0;
                        }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    // Layer 2 (top): Fallback cover — hides when thumbnail is ready
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(1,1,1,0.10)
                        visible: artImg.opacity < 1.0

                        // Site icon (highest priority among fallbacks)
                        Text {
                            id: siteIcon
                            anchors.centerIn: parent
                            text: root.getSiteIcon()
                            visible: text !== ""
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 28 }
                            color: Qt.rgba(1,1,1,0.55)
                        }

                        // App system icon (shown only when no site recognised)
                        Image {
                            id: appIcon
                            anchors.centerIn: parent
                            width: 32; height: 32
                            source: (!siteIcon.visible && root.player && root.player.desktopEntry)
                                    ? "image://icon/" + root.player.desktopEntry.toString() : ""
                            fillMode: Image.PreserveAspectFit
                            visible: !siteIcon.visible
                        }

                        // Generic music note (last resort)
                        Text {
                            anchors.centerIn: parent
                            text: "\uf001"
                            visible: !siteIcon.visible && appIcon.status !== Image.Ready
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 24 }
                            color: Qt.rgba(1,1,1,0.35)
                        }
                    }
                }

                // ── Title + Artist ────────────────────────────────────────
                Column {
                    width: parent.width - artBox.width - ctrlRow.width - parent.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        width: parent.width
                        text:  root.player ? (root.player.trackTitle  || "Unknown Track")  : "—"
                        font { family: "Outfit"; pixelSize: 14; weight: Font.Medium }
                        color: Qt.rgba(1,1,1,0.92)
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text:  root.player ? (root.player.trackArtist || "Unknown Artist") : "—"
                        font { family: "Outfit"; pixelSize: 11; weight: Font.Light }
                        color: Qt.rgba(1,1,1,0.50)
                        elide: Text.ElideRight
                    }
                }

                // ── Control buttons ───────────────────────────────────────
                Row {
                    id: ctrlRow
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    // Previous
                    Item {
                        width: 26; height: 26
                        enabled: root.player ? root.player.canGoPrevious : false
                        opacity: enabled ? 1.0 : 0.28
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Rectangle {
                            anchors.fill: parent; radius: width / 2
                            color: prevArea.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                            scale: prevArea.pressed ? 0.84 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                            Text {
                                anchors.centerIn: parent; text: "\uf048"
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
                                color: Qt.rgba(1,1,1,0.65)
                            }
                        }
                        MouseArea {
                            id: prevArea; anchors.fill: parent; enabled: parent.enabled
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.player) root.player.previous() }
                        }
                    }

                    // Play / Pause
                    Item {
                        width: 32; height: 32
                        Rectangle {
                            anchors.fill: parent; radius: width / 2
                            color: playArea.containsMouse ? Qt.rgba(1,1,1,0.25) : Qt.rgba(1,1,1,0.14)
                            border.width: 1; border.color: Qt.rgba(1,1,1,0.25)
                            scale: playArea.pressed ? 0.84 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                            Text {
                                anchors.centerIn: parent
                                text: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                                color: Qt.rgba(1,1,1,0.95)
                            }
                        }
                        MouseArea {
                            id: playArea; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.player) root.player.togglePlaying() }
                        }
                    }

                    // Next
                    Item {
                        width: 26; height: 26
                        enabled: root.player ? root.player.canGoNext : false
                        opacity: enabled ? 1.0 : 0.28
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Rectangle {
                            anchors.fill: parent; radius: width / 2
                            color: nextArea.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                            scale: nextArea.pressed ? 0.84 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                            Text {
                                anchors.centerIn: parent; text: "\uf051"
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
                                color: Qt.rgba(1,1,1,0.65)
                            }
                        }
                        MouseArea {
                            id: nextArea; anchors.fill: parent; enabled: parent.enabled
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.player) root.player.next() }
                        }
                    }
                }
            }

            // ── Progress bar + time labels ─────────────────────────────────
            Column {
                width:   parent.width
                spacing: 5

                Item {
                    id: seekBar
                    width: parent.width; height: 4

                    Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(1,1,1,0.15) }

                    Rectangle {
                        id: seekFill
                        height: parent.height; radius: 2
                        width: Math.max(radius * 2, seekBar.width * root.progress)
                        color: Qt.rgba(1,1,1,0.78)
                        Behavior on width {
                            enabled: !root.dragging
                            NumberAnimation { duration: 950; easing.type: Easing.Linear }
                        }
                    }

                    Rectangle {
                        id: seekThumb
                        width: 10; height: 10; radius: 5; color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(seekBar.width - width, seekBar.width * root.progress - width / 2))
                        visible: seekMouse.containsMouse || root.dragging
                        Behavior on x {
                            enabled: !root.dragging
                            NumberAnimation { duration: 950; easing.type: Easing.Linear }
                        }
                    }

                    MouseArea {
                        id: seekMouse
                        anchors { fill: parent; margins: -8 }
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPressed:         (e) => { root.dragging = true;  updateDrag(e.x) }
                        onPositionChanged: (e) => { if (pressed) updateDrag(e.x) }
                        onReleased: {
                            if (root.player && root.player.canSeek && root.player.positionSupported)
                                root.player.position = root.posSec;
                            root.dragging = false;
                        }
                        function updateDrag(mx) {
                            if (!root.player || root.durSec <= 0) return;
                            root.posSec = Math.max(0, Math.min(1, mx / seekBar.width)) * root.durSec;
                        }
                    }
                }

                Item {
                    width: parent.width; height: posLabel.implicitHeight

                    Text {
                        id: posLabel
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: root.fmtTime(root.posSec)
                        font { family: "Outfit"; pixelSize: 10; weight: Font.Light }
                        color: Qt.rgba(1,1,1,0.45)
                    }
                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: root.fmtTime(root.durSec)
                        font { family: "Outfit"; pixelSize: 10; weight: Font.Light }
                        color: Qt.rgba(1,1,1,0.45)
                    }
                }
            }
        }
    }
}
