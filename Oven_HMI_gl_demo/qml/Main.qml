import QtQuick 2.15
import QtQuick.Window 2.15
import BreadDemo 1.0

Window {
    id: root
    visible: true
    width:  1280
    height: 480
    color:  "#14141e"
    title:  "Bread GL Demo — QQuickFramebufferObject direct-OpenGL"

    // -------------------------------------------------------------------------
    // FPS overlay (top-left)
    // -------------------------------------------------------------------------
    Text {
        z: 10
        anchors { top: parent.top; left: parent.left; margins: 12 }
        text:  (typeof fpsMonitor !== "undefined" && fpsMonitor)
               ? "FPS: " + fpsMonitor.fps
               : "FPS: --"
        color: "#00ff88"
        font.pixelSize: 22
        font.bold: true
    }

    // -------------------------------------------------------------------------
    // Info label (top-right)
    // -------------------------------------------------------------------------
    Text {
        z: 10
        anchors { top: parent.top; right: parent.right; margins: 12 }
        text:  "bread.glb (original quality, 25 794 tris) · direct OpenGL"
        color: "#aaaacc"
        font.pixelSize: 16
    }

    // =========================================================================
    // Side-by-side layout: PNG reference | 3D direct-GL
    // =========================================================================
    Row {
        anchors.fill: parent

        // ------------------------------------------------------------------ //
        // LEFT PANEL — PNG reference
        // ------------------------------------------------------------------ //
        Rectangle {
            width:  root.width  / 2
            height: root.height
            color:  "#0d0d1a"

            Text {
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter
                          topMargin: 8 }
                text:  "PNG reference"
                color: "#778899"
                font.pixelSize: 14
            }

            Image {
                anchors.centerIn: parent
                source:   "qrc:/assets/media/bread.png"
                fillMode: Image.PreserveAspectFit
                width:    parent.width  * 0.80
                height:   parent.height * 0.80
                smooth:   true
            }
        }

        // ------------------------------------------------------------------ //
        // RIGHT PANEL — direct-OpenGL via QQuickFramebufferObject
        // ------------------------------------------------------------------ //
        Item {
            id: glPanel
            width:  root.width  / 2
            height: root.height

            Text {
                z: 1
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter
                          topMargin: 8 }
                text:  "QQuickFramebufferObject (direct GL)"
                color: "#778899"
                font.pixelSize: 14
            }

            // MeshView fills the right panel; angle/tilt drive the GL uniforms.
            MeshView {
                id: meshView
                anchors.fill: parent

                // Y-axis auto-spin (same 8 s period as spin-test baseline)
                NumberAnimation on angle {
                    from:     0
                    to:       360
                    duration: 8000
                    loops:    Animation.Infinite
                    running:  true
                }
            }

            // Touch/mouse drag → X-tilt
            // Horizontal drag adds to the auto-spin offset (dragAngle)
            // Vertical drag tilts the model up/down
            MouseArea {
                anchors.fill: parent
                property real lastX: 0
                property real lastY: 0

                onPressed: {
                    lastX = mouseX
                    lastY = mouseY
                }
                onPositionChanged: {
                    var dx = mouseX - lastX
                    var dy = mouseY - lastY
                    lastX  = mouseX
                    lastY  = mouseY
                    // Clamp tilt to [-60 .. +60] degrees
                    meshView.tilt = Math.max(-60, Math.min(60, meshView.tilt + dy * 0.4))
                }
            }
        }
    }
}
