import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick3D
import QtQuick3D.Helpers
import "drinks.js" as Data
import QtQuick.Particles
import "qrc:/assets/media/"
// Model imports are centralized in DrinkModel3D.

Item {
    id: page
    objectName: "menuPage"
    implicitWidth: 1280
    implicitHeight: 480

    // Current selected drink id for the carousel.
    property string currentDrinkId: ""
    // Adaptive layout paddings.
    property real horizontalPadding: Math.max(24, width * 0.04)
    property real verticalPadding: Math.max(16, height * 0.04)
    // Fixed height for the bottom action strip.
    property real actionStripHeight: 110

    signal adjustRequested(string drinkId)
    signal playVideo()

    // Background video.

    Loader {
        id: backgroundVideoLoader
        anchors.fill: parent
        sourceComponent: Video {
            source: "qrc:/assets/media/baking_pizza.mov"
            fillMode:VideoOutput.PreserveAspectCrop
            loops: -1
            autoPlay: true
            muted: true
        }
    }

    Component.onCompleted: {
        if(visible) {
            backgroundVideoLoader.active = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
            GradientStop { position: 0.65; color: Qt.rgba(0.04, 0.05, 0.08, 0.85) }
            GradientStop { position: 1.0; color: Qt.rgba(0.01, 0.01, 0.03, 0.95) }
        }
    }

    // Header bar with FPS display.
    RowLayout {
        id: headerRow
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: horizontalPadding; anchors.topMargin: verticalPadding
        spacing: 12

        Column {
            Layout.fillWidth: true
            Text { text: "Oven Station"; color: "#cfd8ff"; font.pixelSize: 14; opacity: 0.8 }
            Text { text: "Menu"; color: "white"; font.pixelSize: 32; font.bold: true }
        }

        // FPS display from the C++ fpsMonitor context property.
                Rectangle {
                    Layout.preferredWidth: 120; Layout.preferredHeight: 60
                    radius: 18; color: "#101226"; border.color: Qt.rgba(1,1,1,0.1)

                    // Guard against fpsMonitor not being injected yet.
                    property int realFps: (typeof fpsMonitor !== "undefined" && fpsMonitor) ? fpsMonitor.fps : 0

                    Column {
                        anchors.centerIn: parent
                        Text { text: "FPS"; color: "#666"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }

                        Text {
                            id: fpsText
                            text: parent.parent.realFps

                            // Color coding based on FPS thresholds.
                            color: parent.parent.realFps > 55 ? "#00ff00" : (parent.parent.realFps > 30 ? "white" : "red")
                            font.bold: true; font.pixelSize: 18; anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }


    }

    // Carousel content (mouse click and swipe supported).
        Item {
            id: carouselHost
            height: Math.max(220, page.height - 250)
            width: parent.width
            // anchors.top: headerRow.bottom; anchors.topMargin: 20  <-- Removed
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -40

            property int selectedIndex: 0
            // Drag offset used for swipe tracking.
            property real dragOffset: 0

            ListModel {
                id: drinkModel
                Component.onCompleted: {
                    if(Data && Data.drinks) {
                        for (var i=0; i<Data.drinks.length; ++i) append(Data.drinks[i])
                        if (Data.drinks.length > 0) {
                             page.currentDrinkId = Data.drinks[0].id
                             carouselHost.select(0)
                        }
                    }
                }
            }

            function offsetFor(index) {
                const total = drinkModel.count
                if (total === 0) return 0
                var offset = (((index - selectedIndex) % total) + total) % total
                if(offset > total/2) offset -= total
                return offset
            }

            function select(index) {
                if(drinkModel.count === 0) return
                selectedIndex = ((index % drinkModel.count) + drinkModel.count) % drinkModel.count
                page.currentDrinkId = drinkModel.get(selectedIndex).id
            }

            function shift(delta) { select(selectedIndex + delta) }

            Item {
                id: carouselStage
                anchors.fill: parent

                // Gesture area for swipe navigation.
                            MouseArea {
                                anchors.fill: parent
                                propagateComposedEvents: true

                                property real startX: 0
                                property bool isDragging: false

                                onPressed: (mouse) => {
                                    startX = mouse.x
                                    isDragging = false
                                }

                                onPositionChanged: (mouse) => {
                                    if (Math.abs(mouse.x - startX) > 10) {
                                        isDragging = true
                                    }
                                }

                                onReleased: (mouse) => {
                                    if (isDragging) {
                                        var diff = mouse.x - startX
                                        if (diff > 50) {
                                            carouselHost.shift(-1)
                                        } else if (diff < -50) {
                                            carouselHost.shift(1)
                                        }
                                    } else {
                                        // Tap navigation.
                                        if (mouse.x > width * 0.75) carouselHost.shift(1)
                                        else if (mouse.x < width * 0.25) carouselHost.shift(-1)
                                    }
                                }
                            }
                Repeater {
                    model: drinkModel
                    delegate: Item {
                        readonly property real offset: carouselHost.offsetFor(index)
                        property bool selected: carouselHost.selectedIndex === index

                        // Base size and placement.
                        width: 250; height: 250
                        x: (carouselStage.width - width) / 2 + offset * 200
                        y: (carouselStage.height - height) / 2 + Math.abs(offset) * 50
                        z: 100 - Math.abs(offset)
                        scale: 1 - Math.abs(offset) * 0.2

                        // Dim non-selected items.
                        opacity: 1 - Math.abs(offset) * 0.4

                        Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }
                        Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }
                        Behavior on scale { NumberAnimation { duration: 450 } }

                        // Layer 1: 2D preview (default state).

                        Image {
                            anchors.fill: parent
                            source: model.image
                            fillMode: Image.PreserveAspectFit; mipmap: true
                            opacity: parent.selected ? 0.0 : 1.0
                            visible: opacity > 0.0
                            Behavior on opacity { NumberAnimation { duration: 500 } }
                        }

                        // Layer 2: 3D model (selected state).
                        Item {
                            anchors.fill: parent
                            opacity: parent.selected ? 1.0 : 0.0
                            visible: opacity > 0.0

                            Behavior on opacity { NumberAnimation { duration: 500 } }
                            View3D {
                                anchors.fill: parent
                                environment: SceneEnvironment {
                                    backgroundMode: SceneEnvironment.Transparent
                                    antialiasingMode: SceneEnvironment.MSAA
                                    antialiasingQuality: SceneEnvironment.High
                                }

                                // Camera.
                                PerspectiveCamera {
                                    id: camera
                                    position: Qt.vector3d(0, 50, 300)
                                    eulerRotation.x: -10
                                }

                                // Scene nodes and lighting.
                                Node {
                                    position: Qt.vector3d(0, -30, 0)

                                    DirectionalLight {
                                        id: dirLight
                                        eulerRotation: Qt.vector3d(-35, -45, 0); castsShadow: true
                                    }
                                    PointLight {
                                        id: pl1
                                    }
                                    PointLight {
                                        id: pl2
                                        constantFade: 1.0; linearFade: 0.01; quadraticFade: 0.001
                                    }

                                    Node {
                                        NumberAnimation on eulerRotation.y { running: parent.parent.parent.visible; from: 0; to: 360; duration: 12000; loops: Animation.Infinite }

                                        // Model loader with per-drink lighting adjustments.
                                        DrinkModel3D {
                                            id: model3d
                                            drinkId: model.id

                                            // Refresh lighting when the drink changes.
                                            onDrinkIdChanged: refreshLights()
                                            Component.onCompleted: refreshLights()

                                            function refreshLights() {
                                                model3d.updateLighting(drinkId, dirLight, pl1, pl2)
                                            }
                                        }
                                    }
                                }
                            }

                            // Particle smoke overlay.
                            Item {
                                anchors.fill: parent
                                // Only show smoke when item is selected (opacity > 0.8 is a rough check for 'centered')
                                visible: parent.opacity > 0.8

                                ParticleSystem { id: smokeSys; anchors.fill: parent; running: parent.visible }

                                Emitter {
                                   system: smokeSys
                                   x: parent.width / 2 - 25; y: parent.height / 2 - 30
                                   width: 60; height: 20
                                   emitRate: 40; lifeSpan: 3500; lifeSpanVariation: 1000
                                   size: 30; sizeVariation: 20
                                   velocity: AngleDirection { angle: 270; angleVariation: 20; magnitude: 40; magnitudeVariation: 20 }
                                   acceleration: PointDirection { y: -15 }
                                }

                                ItemParticle {
                                   system: smokeSys; opacity: 0.15; fade: true
                                   delegate: Rectangle {
                                       width: 20; height: 20; color: "white"; radius: 10
                                       Rectangle { anchors.centerIn: parent; width: 40; height: 40; color: "transparent"; radius: 20; border.color: Qt.rgba(1,1,1,0.08); border.width: 20 }
                                   }
                                }
                            }
                        }
                        // Interactive hit area for selection and swipe.
                        MouseArea {
                            anchors.fill: parent
                            property real startX: 0
                            property bool isDragging: false

                            // Prevent event passthrough to the background.
                            preventStealing: true

                            onPressed: (mouse) => {
                                startX = mouse.x
                                isDragging = false
                            }

                            onPositionChanged: (mouse) => {
                                // Treat movement over 10px as a drag.
                                if (Math.abs(mouse.x - startX) > 10) {
                                    isDragging = true
                                }
                            }

                            onReleased: (mouse) => {
                                if (isDragging) {
                                    // Swipe navigation.
                                    var diff = mouse.x - startX
                                    if (diff > 50) carouselHost.shift(-1)
                                    else if (diff < -50) carouselHost.shift(1)
                                } else {
                                    // Tap to select the centered item.
                                    if (parent.selected) {
                                    } else {
                                        carouselHost.select(index)
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.top: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                            text: model.label
                            color: "white"; font.bold: true; font.pixelSize: 20
                            visible: parent.selected
                        }
                    }
                }
            }

            // Carousel navigation buttons.
            Button {
                width: 90; height: 90
                anchors.left: parent.left; anchors.leftMargin: 30
                anchors.verticalCenter: parent.verticalCenter
                background: Image {
                    source: parent.pressed ? "qrc:/assets/media/left_click.png" : "qrc:/assets/media/left_unclick.png"
                    fillMode: Image.PreserveAspectFit
                }
                onClicked: carouselHost.shift(-1)
            }
            Button {
                width: 90; height: 90
                anchors.right: parent.right; anchors.rightMargin: 30
                anchors.verticalCenter: parent.verticalCenter
                background: Image {
                    source: parent.pressed ? "qrc:/assets/media/right_click.png" : "qrc:/assets/media/right_unclick.png"
                    fillMode: Image.PreserveAspectFit
                }
                onClicked: carouselHost.shift(1)
            }
        }
    // Bottom action strip.
    Item {
        id: actionStrip
        width: page.width - (horizontalPadding * 2)
        height: actionStripHeight
        z: 20
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: verticalPadding + 16

        Button {
            id: adjustButton
            width: Math.min(200, actionStrip.width * 0.3); height: 70
            anchors.centerIn: parent
            text: "Adjust Recipe"

            background: Rectangle {
                anchors.fill: parent; radius: height/2
                color: Qt.rgba(0,0,0,0.25); border.color: "#FF8D60"; border.width: 2
            }
            contentItem: Text {
                text: adjustButton.text; color: "#FF8D60"
                font.pixelSize: 18; font.bold: true
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
            onClicked: page.adjustRequested(page.currentDrinkId)
        }
    }
}
