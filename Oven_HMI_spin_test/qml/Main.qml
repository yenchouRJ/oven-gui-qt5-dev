import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick3D 1.15

Window {
    id: root
    visible: true
    width:  1280
    height: 480
    color:  "#1a1a2e"
    title:  "Chicken Spin Test — MA35D1 Quality Check"

    // -------------------------------------------------------------------------
    // FPS overlay (top-left).  fpsMonitor is injected from C++ after root loads.
    // -------------------------------------------------------------------------
    Text {
        id: fpsLabel
        z: 10
        anchors { top: parent.top; left: parent.left; margins: 12 }
        text: (typeof fpsMonitor !== "undefined" && fpsMonitor)
              ? "FPS: " + fpsMonitor.fps
              : "FPS: --"
        color:  "#00ff88"
        font.pixelSize: 22
        font.bold: true
    }

    // -------------------------------------------------------------------------
    // Info overlay (top-right): current quality level label.
    // -------------------------------------------------------------------------
    Text {
        z: 10
        anchors { top: parent.top; right: parent.right; margins: 12 }
        text: "chicken.glb — step 3 (~10 K tris) · NoLighting"
        color:  "#aaaacc"
        font.pixelSize: 16
    }

    // =========================================================================
    // Side-by-side layout
    // =========================================================================
    Row {
        anchors.fill: parent

        // ------------------------------------------------------------------ //
        // LEFT PANEL — PNG reference image
        // ------------------------------------------------------------------ //
        Rectangle {
            width:  root.width  / 2
            height: root.height
            color:  "#0d0d1a"

            Text {
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 8 }
                text:  "PNG reference (256 × 256)"
                color: "#778899"
                font.pixelSize: 14
            }

            Image {
                anchors.centerIn: parent
                source: "qrc:/assets/media/chicken.png"
                fillMode: Image.PreserveAspectFit
                // bound to 80% of the panel so the label stays visible
                width:  parent.width  * 0.80
                height: parent.height * 0.80
                smooth: true
            }
        }

        // ------------------------------------------------------------------ //
        // RIGHT PANEL — spinning 3D model
        // ------------------------------------------------------------------ //
        Rectangle {
            width:  root.width  / 2
            height: root.height
            color:  "transparent"

            Text {
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 8 }
                text:  "3D model (spinning)"
                color: "#778899"
                font.pixelSize: 14
            }

            View3D {
                anchors.fill: parent

                // -- Scene environment -----------------------------------------
                environment: SceneEnvironment {
                    clearColor: "#0d0d1a"
                    backgroundMode: SceneEnvironment.Color

                    // Start with no AA for baseline FPS; change to MSAA/SSAA to
                    // gauge the quality/perf trade-off.
                    //   SceneEnvironment.NoAA   — fastest, jagged edges
                    //   SceneEnvironment.MSAA   + antialiasingQuality: Medium/High
                    //   SceneEnvironment.SSAA   + antialiasingQuality: High
                    antialiasingMode:    SceneEnvironment.NoAA
                    antialiasingQuality: SceneEnvironment.Medium
                }

                // -- Camera -----------------------------------------------------
                PerspectiveCamera {
                    id: camera
                    position:       Qt.vector3d(0, 100, 300)
                    eulerRotation.x: -20
                }

                // -- Key light (front/top) --------------------------------------
                DirectionalLight {
                    eulerRotation.x: -30
                    eulerRotation.y: -30
                    color:      "#ffffff"
                    brightness: 3.5
                    castsShadow: false
                }

                // -- Fill light (left) ------------------------------------------
                PointLight {
                    color:      "#eef5ff"
                    brightness: 2.0
                    position:   Qt.vector3d(-200, 100, 200)
                }

                // -- Rim light (right/back) -------------------------------------
                PointLight {
                    color:      "#ffffff"
                    brightness: 4.0
                    position:   Qt.vector3d(100, 250, -100)
                    constantFade: 1.0
                    linearFade:   0.1
                }

                // -- Rotating model node ----------------------------------------
                Node {
                    position: Qt.vector3d(0, -30, 0)

                    NumberAnimation on eulerRotation.y {
                        from:     0
                        to:       360
                        duration: 8000
                        loops:    Animation.Infinite
                        running:  true
                    }

                    Loader3D {
                        id: modelLoader
                        active: true
                        source: "qrc:/qml/models/chicken/Chicken.qml"

                        onLoaded: {
                            if (item) {
                                // Same transform as the main project's DrinkModel3D.qml
                                item.scale    = Qt.vector3d(30, 30, 30)
                                item.position = Qt.vector3d(-30, 20, -10)
                            }
                        }
                    }
                }
            }
        }
    }
}
