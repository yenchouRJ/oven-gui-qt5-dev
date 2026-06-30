import QtQuick 2.15
import QtQuick.Controls 2.15

// Qt5 port: background video disabled for MA35D1 (software rendering / FPS).
// Original played an intro .mov and advanced on stop. Replaced with a short
// static splash + timer so the page flow (finished()) is preserved.
// To re-enable video later, restore the Video element (see git history of the
// Qt6 release) and gate it behind a flag.
Item {
    id: page
    signal finished()

    // Splash duration before auto-advancing to the menu (ms).
    property int splashMs: 1500

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0a0d18" }
            GradientStop { position: 1.0; color: "#05060c" }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 8
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "OVEN STATION"
            color: "white"
            font.pixelSize: 40
            font.bold: true
            font.letterSpacing: 6
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Starting up..."
            color: "#cfd8ff"
            font.pixelSize: 16
            opacity: 0.8
        }
    }

    // Tap to skip the splash.
    MouseArea {
        anchors.fill: parent
        onClicked: {
            introTimer.stop()
            page.finished()
        }
    }

    Timer {
        id: introTimer
        interval: page.splashMs
        repeat: false
        running: true
        onTriggered: page.finished()
    }
}
