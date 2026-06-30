import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia
import QtQuick3D
import QtQuick3D.Helpers
import "drinks.js" as Data

Item {
    id: processingRoot
    objectName: "processingPage"
    implicitWidth: 1280
    implicitHeight: 480

    // Current drink ID passed from Main.qml
    property string drinkId: ""

    signal finished()
    signal cancelled()

    // UI-facing properties used for safe bindings.
    property string uiName:     "Preparing..."
    property string uiStrength: "--"
    property string uiGrind:    "--"
    property string uiQuantity: "--"
    property string uiQuantityUnit: ""
    property string uiTime:     "30"
    property string uiTimeUnit: "min"
    property string uiTemp:     "--"
    property string uiTempUnit: "C"

    property real progress: 0.0

    property bool processingComplete: false

    onProcessingCompleteChanged: {
        if(processingComplete & cancelPopup.visible){
            cancelPopup.close()
        }
    }

    // Timer that copies JS data into UI properties.
    Timer {
        interval: 200 // 200 ms delay
        running: true
        repeat: false
        onTriggered: {
            console.log("--> Timer Triggered: Loading Data...")

            // Fetch data or fall back to an empty object.
            var d = Data.currentBrewSettings || {}

            // Copy values into UI properties with string coercion.
            processingRoot.uiName     = d.drinkName   || "Cooking"
            processingRoot.uiStrength = (d.strength   || "0").toString()
            processingRoot.uiGrind    = (d.grind      || "0").toString()
            processingRoot.uiQuantity = (d.quantity   || "0").toString()
            processingRoot.uiQuantityUnit = d.quantityUnit || ""
            processingRoot.uiTime     = (d.time       || "30").toString()
            processingRoot.uiTimeUnit = d.timeUnit    || "min"
            processingRoot.uiTemp     = (d.temp       || "90").toString()
            processingRoot.uiTempUnit = d.tempUnit    || "C"

            console.log("--> UI Updated: " + processingRoot.uiName)

            processingRoot.processingComplete = false
            // Start the progress animation once the data is loaded.
            processAnim.start()
        }
    }

    SequentialAnimation {
        id: processAnim
        running: false
        NumberAnimation {
            target: processingRoot; property: "progress"; to: 1.0
            duration: parseInt(processingRoot.uiTime) * (processingRoot.uiTimeUnit === "min" ? 60000 : 1000)
            easing.type: Easing.Linear
        }
        ScriptAction { script: { processingRoot.processingComplete = true; Root.finished() } }
    }

    // UI layout (read-only bindings to the properties above).

    // Background video.
    Video {
        anchors.fill: parent
        source: "qrc:/assets/media/baking_pizza.mov"
        fillMode: VideoOutput.PreserveAspectCrop
        loops: -1
        autoPlay: true; muted: true
    }
    Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.85 }

    // 3D scene.
    Rectangle {
            x: 40; y: 40
            // Preserve the original layout size.
            width: processingRoot.width * 0.55; height: processingRoot.height - 80
            color: "transparent"

            View3D {
                id: view3D
                anchors.fill: parent

                // Input controller for rotating and zooming the model.
                OrbitCameraController {
                    anchors.fill: parent
                    // Bind to the camera below.
                    camera: camera
                    origin: cameraNode
                }

                environment: SceneEnvironment {
                    clearColor: "transparent"
                    backgroundMode: SceneEnvironment.Transparent
                    // Anti-aliasing for smoother edges.
                    antialiasingMode: SceneEnvironment.SSAA
                    antialiasingQuality: SceneEnvironment.High
                }

                // Camera node (rotation center).
                Node {
                    id: cameraNode
                    PerspectiveCamera {
                        id: camera
                        // Adjust Z distance to scale the model view.
                        position: Qt.vector3d(0, 100, 300) //default is (0, 0, 100)
                        eulerRotation.x: -20
                    }
                }

                // Key light.
                DirectionalLight {
                    id: dirLight
                    eulerRotation.x: -30; eulerRotation.y: -30
                    castsShadow: true 
                }

                // Fill light.
                PointLight {
                    id: pl1
                }

                // Top/back light.
                PointLight {
                    id: pl2
                    constantFade: 1.0; linearFade: 0.1
                }

                Node {
                    position: Qt.vector3d(0, -30, 0)

                    // Model loader with shared lighting updates.
                    DrinkModel3D {
                        id: model3d
                        // drinkId: "coffee_cup"
                        drinkId: selectedDrinkId
                        
                        // Keep the prior processing-page scale.
                        scale: Qt.vector3d(1.25, 1.25, 1.25)
                        
                        // Unified lighting logic.
                        onDrinkIdChanged: refreshLights()
                        Component.onCompleted: refreshLights()
                        
                        function refreshLights() {
                            if(dirLight) updateLighting(drinkId, dirLight, pl1, pl2)
                        }
                    }

                }
            }
        }
    // Right-side parameter panel.
    Rectangle {
          anchors.right: parent.right; anchors.rightMargin: 40
          anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 20
          width: 380; color: "#151515"; radius: 24; border.color: "#333"

          ColumnLayout {
              anchors.fill: parent; anchors.margins: 20
              spacing: 8

              Text { text: "COOK ASSIST"; color: "#666"; font.bold: true; font.letterSpacing: 1.2 }

              Text {
                  text: processingRoot.uiName
                  color: "white"; font.pixelSize: 32; font.bold: true; wrapMode: Text.WordWrap; Layout.fillWidth: true
              }
              Text { text: "Cooking..."; color: "#888"; font.pixelSize: 15 }

              // Parameter grid.
              GridLayout {
                  columns: 2; Layout.fillWidth: true;
                  columnSpacing: 10; rowSpacing: 8

                  // Compact layout height.
                  Rectangle {
                      Layout.fillWidth: true; height: 60; color: "#222"; radius: 12
                      Column { anchors.centerIn: parent; Text { text: "Crispness"; color: "#888"; font.pixelSize: 10 }
                      Text { text: processingRoot.uiStrength + "/9"; color: "white"; font.pixelSize: 18; font.bold: true } }
                  }
                  Rectangle {
                      Layout.fillWidth: true; height: 60; color: "#222"; radius: 12
                      Column { anchors.centerIn: parent; Text { text: "Fan Speed"; color: "#888"; font.pixelSize: 10 }
                      Text { text: processingRoot.uiGrind + "/9"; color: "white"; font.pixelSize: 18; font.bold: true } }
                  }
                  Rectangle {
                      Layout.fillWidth: true; height: 60; color: "#222"; radius: 12
                      Column { anchors.centerIn: parent; Text { text: "Portions"; color: "#888"; font.pixelSize: 10 }
                      Text { text: processingRoot.uiQuantity + (processingRoot.uiQuantityUnit ? (" " + processingRoot.uiQuantityUnit) : ""); color: "white"; font.pixelSize: 18; font.bold: true } }
                  }
                  Rectangle {
                      Layout.fillWidth: true; height: 60; color: "#222"; radius: 12
                      Column { anchors.centerIn: parent; Text { text: "Cook Time"; color: "#888"; font.pixelSize: 10 }
                      Text { text: processingRoot.uiTime + " " + processingRoot.uiTimeUnit; color: "white"; font.pixelSize: 18; font.bold: true } }
                  }
              }

              // Temperature row.
              Rectangle {
                  Layout.fillWidth: true; height: 60; color: "#222"; radius: 12
                  RowLayout {
                      anchors.fill: parent; anchors.margins: 20
                       Text { text: "Oven Temp"; color: "#888"; Layout.fillWidth: true; font.pixelSize: 13 }
                      Text {
                           text: processingRoot.uiTemp + " " + processingRoot.uiTempUnit
                          color: "white"; font.pixelSize: 20; font.bold: true
                      }
                  }
              }

              // Spacer to separate header and footer content.
              Item { Layout.fillHeight: true }

              // Progress indicator.
              Text { text: "COOKING PROGRESS"; color: "#666"; font.bold: true; font.pixelSize: 10 }

              Rectangle {
                  Layout.fillWidth: true
                  height: 4
                  color: "#333"; radius: 2
                  Rectangle {
                      width: parent.width * processingRoot.progress
                      height: parent.height; radius: 2
                      gradient: Gradient { GradientStop { position: 0; color: "#FF8D60" } GradientStop { position: 1; color: "#FFC107" } }
                  }
              }

              // Footer actions.
              Item { height: 5; width: 1 }
              Button {
                  text: "Cancel"
                  Layout.alignment: Qt.AlignRight
                  Layout.preferredHeight: 50
                  Layout.preferredWidth: 100
                  leftPadding: 16
                  rightPadding: 16
                  topPadding: 10
                  bottomPadding: 10
                  font.pixelSize: 22
                  background: Rectangle {
                      anchors.fill: parent
                      radius: height/2
                      color: Qt.rgba(0,0,0,0.2)
                      border.width: 1
                  }

                  contentItem: Text {
                      text: "Cancel"
                      color: "#FF8D60"
                      font.bold: true
                      font.pixelSize: 22
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                      anchors.fill: parent
                  }
                  onClicked: {
                      if (processingRoot.processingComplete)
                          return;
                        cancelPopup.open()
                  }
              }
          }
      }

    Popup {
        id: cancelPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: (processingRoot.width - width) / 2
        y: (processingRoot.height - height) / 2

        background: Rectangle {
            anchors.fill: parent
            color: "#222"
            radius: 12
            border.color: "#444"
            border.width: 1
        }

        contentItem: ColumnLayout {
           anchors.margins: 20
           anchors.fill: parent
           spacing: 16

           Text {
               text: "Cancel Cooking?"
               color: "white"
               font.pixelSize: 26
               font.bold: true
               Layout.fillWidth: true
               wrapMode: Text.WordWrap
           }

           Text {
               text: "This will stop the current process."
               color: "#cccccc"
               font.pixelSize: 18
               Layout.fillWidth: true
               wrapMode: Text.WordWrap
           }

           RowLayout {
               Layout.fillWidth: true
               spacing: 12
               Button {
                   text: "No"
                   Layout.fillWidth: true
                   onClicked: cancelPopup.close()
               }
               Button {
                   text: "Yes"
                   Layout.fillWidth: true
                   background: Rectangle { anchors.fill: parent; radius: height/2; color: Theme.accent }
                   onClicked: {
                       cancelPopup.close()
                       processAnim.stop()
                       processingRoot.cancelled()
                   }
               }
           }
        }
    }

}
