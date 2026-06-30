import QtQuick
import QtQuick.Controls
import QtMultimedia

Item {
    id: page
    signal finished()

    Rectangle {
        anchors.fill: parent
        color: "#05060c"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            intro.stop()
            page.finished() // Manually trigger just in case
        }
    }

    Video {
        id: intro
        anchors.fill: parent
        source: "qrc:/assets/media/baking_pizza.mov"
        fillMode: VideoOutput.PreserveAspectCrop

        loops: 1
        muted: true
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.StoppedState) {
                page.finished()
            }
        }

        onErrorOccurred: {
            console.log("Video Error:", errorString)
            page.finished()
        }
    }
    // Start the video manually when the component is ready
    Component.onCompleted: {
        intro.play()
    }
}
