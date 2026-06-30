import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia
import QtQuick3D
import QtQuick3D.Helpers
import "drinks.js" as Data

Item {
    id: page
    objectName: "adjustmentPage"
    // Indicates when external signal bindings are ready.
    property bool connectionsReady: false
    implicitWidth: 1280
    implicitHeight: 480

    // Recipe parameters
    property string drinkId: ""
    property var    drink:   ({})

    // Center point used by the dial controls.
    property point origin: Qt.point(width / 2, height / 2)

    // Intermediate UI values used by the signals/slots flow.
    property int strengthValue:      5
    property int grindValue:         5
    property int quantityValue:      200
    property int contactTimeValue:   30
    property int temperatureValue:   90

    signal back()
    signal startBrew(string drinkId)

    Component.onCompleted: initDrink(drinkId)
    onDrinkIdChanged: initDrink(drinkId)

    // Initialize drink parameters
    function initDrink(id) {
        var chosen = Data.drinks.length > 0 ? Data.drinks[0] : null
        for (var i = 0; i < Data.drinks.length; ++i) {
            if (Data.drinks[i].id === id) { chosen = Data.drinks[i]; break; }
        }
        if (!chosen) return;
        
        drink = chosen

        // Priority: User Preferences > Factory Defaults
        var source = chosen.userPreferences ? chosen.userPreferences : chosen.defaults

        strengthValue    = source.strength
        grindValue       = source.grind
        quantityValue    = source.quantity.value !== undefined ? source.quantity.value : source.quantity
        contactTimeValue = source.contactTime.value !== undefined ? source.contactTime.value : source.contactTime
        temperatureValue = source.temperature.value !== undefined ? source.temperature.value : source.temperature
    }

    // Save current settings to User Preferences
    function saveToUserPrefs() {
        var targetId = page.drink.id
        for(var i=0; i<Data.drinks.length; i++) {
            if(Data.drinks[i].id === targetId) {
                Data.drinks[i].userPreferences = {
                    strength: strengthValue,
                    grind: grindValue,
                    quantity: quantityValue,
                    contactTime: contactTimeValue,
                    temperature: temperatureValue
                }
                console.log("Auto-saved User Preferences for: " + targetId)
                break
            }
        }
    }

    function currentSettings() {
        return { strength: strengthValue, grind: grindValue, quantity: quantityValue,
                 contactTime: contactTimeValue, temperature: temperatureValue }
    }

    // Background
    Rectangle { anchors.fill: parent; color: "#05060c" }
    Video {
        anchors.fill: parent
        source: "qrc:/assets/media/baking_pizza.mov"
        autoPlay: true
        loops: -1;
        muted: true
        fillMode: VideoOutput.PreserveAspectCrop
        opacity: 0.25
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0;  color: Qt.rgba(1,1,1,0.12) }
            GradientStop { position: 0.65; color: Qt.rgba(0.04,0.05,0.12,0.85) }
            GradientStop { position: 1.0;  color: Qt.rgba(0.01,0.01,0.03,0.95) }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Math.max(12, Math.min(page.height * 0.04, 28))
        spacing: Math.max(16, page.width * 0.02)

        // Hero Card
        Rectangle {
            Layout.preferredWidth: Math.min(360, page.width * 0.28); Layout.fillHeight: true
            radius: 40; color: Qt.rgba(0.06,0.08,0.18,0.9)
            border.color: Qt.rgba(1,1,1,0.2); border.width: 1
            antialiasing: true

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - 36, parent.height - 72)
                height: width
                Rectangle {
                    anchors.centerIn: parent; width: parent.width * 0.85; height: width; radius: width/2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1,0.75,0.35,0.5) }
                        GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0) }
                    }
                    opacity: 0.85
                }
                View3D {
                    anchors.fill: parent
                    environment: SceneEnvironment {
                        backgroundMode: SceneEnvironment.Transparent
                        antialiasingMode: SceneEnvironment.MSAA
                        antialiasingQuality: SceneEnvironment.High
                    }

                    PerspectiveCamera {
                        id: camera
                        position: Qt.vector3d(0, 50, 220)
                        eulerRotation.x: -15
                    }

                    Node {
                        position: Qt.vector3d(0, -40, 0)
                        
                        DirectionalLight { id: dirLight; eulerRotation: Qt.vector3d(-35, -45, 0); castsShadow: true }
                        PointLight { id: pl1 }
                        PointLight { id: pl2 }

                        Node {
                            scale: Qt.vector3d(0.6, 0.6, 0.6)
                            NumberAnimation on eulerRotation.y { from: 0; to: 360; duration: 20000; loops: Animation.Infinite }

                            DrinkModel3D {
                                id: model3d
                                drinkId: page.drink.id
                                
                                onDrinkIdChanged: refreshLights()
                                Component.onCompleted: refreshLights()
                                
                                function refreshLights() {
                                    if(dirLight) updateLighting(drinkId, dirLight, pl1, pl2)
                                }
                            }
                        }
                    }
                }
            }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom; anchors.bottomMargin: 20
                spacing: 4
                Text {
                    text: drink.label ? drink.label.toUpperCase() : ""
                    color: "#fefefe"; font.pixelSize: 14; font.letterSpacing: 5
                    horizontalAlignment: Text.AlignHCenter
                }
                Repeater {
                    model: drink.notes ? drink.notes.length : 0
                    delegate: Text {
                        text: "• " + drink.notes[index]
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        opacity: 0.75
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        // Controls column
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop

                RowLayout {
                    Layout.fillWidth: true
                Text { text: "Cook Assist"; color: Theme.textSecondary; font.pixelSize: 12; opacity: 0.8 }
                    Item { Layout.fillWidth: true }
                    Button {
                        id: headerBack
                        text: "Back"
                        implicitHeight: 32
                        implicitWidth: 90
                        background: Rectangle {
                            anchors.fill: parent
                            radius: height/2
                            color: Qt.rgba(0,0,0,0.2)
                            border.color: Theme.accent
                            border.width: 1
                        }
                        contentItem: Text {
                            text: headerBack.text
                            color: Theme.accent
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            anchors.fill: parent
                        }
                        onClicked: {
                            saveToUserPrefs()
                            page.back()
                        }
                    }
                }

                Text { Layout.fillWidth: true; text: drink.label; color: Theme.textPrimary; font.pixelSize: 22; font.bold: true }

                // First row - Step Meters (Crispness & Fan)
                RowLayout {
                    Layout.fillWidth: true; spacing: 10

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight-10
                        title: "Crispness"
                        value: strengthValue
                        maxValue: 9
                        unit: "/9"
                        isStep: true
                        onValueEdited: function(val) { strengthValue = val }
                    }
                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        title: "Fan Speed"
                        value: grindValue
                        maxValue: 9
                        unit: "/9"
                        isStep: true
                        onValueEdited: function(val) { grindValue = val }
                    }
                }

                // Second row - Range Meters
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 10; rowSpacing: 10

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        title: "Portions"; value: quantityValue; maxValue: drink.defaults.quantity.max
                        unit: drink.defaults.quantity.unit
                        onValueEdited: function(val) { quantityValue = val }
                    }
                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        title: "Cook Time"; value: contactTimeValue; maxValue: drink.defaults.contactTime.max
                        unit: drink.defaults.contactTime.unit
                        onValueEdited: function(val) { contactTimeValue = val }
                    }
                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        title: "Oven Temperature"; value: temperatureValue; maxValue: drink.defaults.temperature.max
                        unit: drink.defaults.temperature.unit
                        onValueEdited: function(val) { temperatureValue = val }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Button {
                        id: resetButton
                        text: "Reset to Default"
                        // Enlarged hit area for easier touch input.
                        Layout.preferredWidth: 240
                        Layout.preferredHeight: 80
                        background: Rectangle {
                            // Visual size stays compact.
                            width: 200; height: 45
                            anchors.centerIn: parent
                            radius: height/2
                            color: Qt.rgba(0,0,0,0.05)
                            border.color: Theme.accent
                            border.width: 1
                        }
                        contentItem: Text {
                            text: resetButton.text
                            color: Theme.accent
                            font.pixelSize: 16
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if(drink && drink.defaults) {
                                strengthValue    = drink.defaults.strength
                                grindValue       = drink.defaults.grind
                                quantityValue    = drink.defaults.quantity.value
                                contactTimeValue = drink.defaults.contactTime.value
                                temperatureValue = drink.defaults.temperature.value
                                saveToUserPrefs() 
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                    Button {
                        id: startButton
                        text: "Start Cook"
                        // Enlarged hit area for easier touch input.
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 80
                        background: Rectangle {
                            // Visual size stays compact.
                            width: 220; height: 45
                            anchors.centerIn: parent
                            radius: height/2
                            color: Theme.accent
                        }
                        contentItem: Text {
                            text: startButton.text
                            color: Theme.background
                            font.pixelSize: 16
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            saveToUserPrefs()
                            Data.currentBrewSettings = {
                                 "drinkName": page.drink.label,
                                 "strength": page.strengthValue,
                                 "grind":    page.grindValue,
                                 "quantity": page.quantityValue,
                                 "quantityUnit": drink.defaults.quantity.unit,
                                 "time":     page.contactTimeValue,
                                 "contactTime": page.contactTimeValue,
                                 "timeUnit": drink.defaults.contactTime.unit,
                                 "temp":     page.temperatureValue,
                                 "temperature": page.temperatureValue,
                                 "tempUnit": drink.defaults.temperature.unit
                             }
                            page.startBrew(drink.id)
                        }
                    }
                }
            }
        }

    function startBrewFromSerial() {
        startButton.clicked() 
    }

    // ------------------------------- Glass Card Component -------------------------------
    component GlassCard: Rectangle {
        id: card
        property string title: ""
        property real value: 0
        property real maxValue: 100
        property string unit: ""
        property bool isStep: false

        signal valueEdited(real newValue)

        readonly property real rangeMax: isStep ? 9 : Math.max(1, maxValue)
        readonly property real normalizedValue: Math.max(0, Math.min(rangeMax, value))
        readonly property int stepValue: Math.round(normalizedValue)
        readonly property real clampedRatio: rangeMax > 0 ? normalizedValue / rangeMax : 0

        implicitWidth: 360
        implicitHeight: isStep ? 160 : 130
        radius: 22
        color: Qt.rgba(0.1, 0.12, 0.2, 0.65)
        border.color: Qt.rgba(1,1,1,0.15); border.width: 1

        layer.enabled: true

        Column {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: card.isStep ? 18 : 22
            anchors.bottomMargin: card.isStep ? 28 : 24
            spacing: card.isStep ? 10 : 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: title
                    color: "#ffffff"
                    font.pixelSize: 15
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(value) + unit
                    color: Theme.accent
                    font.pixelSize: 22
                    font.bold: true
                }
            }

            Rectangle {
                id: track
                width: parent.width; height: isStep ? 26 : 18; radius: 9
                color: isStep ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.12)
                property real segmentSpacing: 6
                property real segmentWidth: card.rangeMax > 0
                                           ? Math.max(0, (width - segmentSpacing * (card.rangeMax - 1)) / card.rangeMax)
                                           : width

                Rectangle {
                    width: track.width * card.clampedRatio
                    height: parent.height; radius: parent.radius
                    visible: !isStep
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#FF8D60" }
                        GradientStop { position: 1; color: "#FFCC33" }
                    }
                }

                Repeater {
                    model: isStep ? card.rangeMax : 0
                    delegate: Rectangle {
                        width: track.segmentWidth
                        height: track.height
                        radius: 4
                        x: index * (track.segmentWidth + track.segmentSpacing)
                        color: index < card.stepValue ? "#FFB347" : Qt.rgba(1,1,1,0.15)
                        opacity: index < card.stepValue ? 1 : 0.4
                        border.color: Qt.rgba(1,1,1,0.25)
                    }
                }

                MouseArea {
                    id: stepInput
                    visible: isStep
                    enabled: isStep
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: false
                    z: 6
                    onPressed: function(mouse) { updateFromPosition(mouse.x) }
                    onPositionChanged: function(mouse) { if (pressed) updateFromPosition(mouse.x) }
                    function updateFromPosition(pos) {
                        var localX = Math.max(0, Math.min(width, pos))
                        var ratio = width > 0 ? localX / width : 0
                        card.valueEdited(Math.round(ratio * card.rangeMax))
                    }
                }

                MouseArea {
                    visible: !isStep
                    enabled: !isStep
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onPressed: function(mouse) { updateFromPosition(mouse.x) }
                    onPositionChanged: function(mouse) { if (pressed) updateFromPosition(mouse.x) }
                    function updateFromPosition(pos) {
                        var localX = Math.max(0, Math.min(width, pos))
                        var ratio = width > 0 ? localX / width : 0
                        card.valueEdited(Math.round(ratio * card.rangeMax))
                    }
                }

                Rectangle {
                    visible: !isStep
                    width: 34; height: 34; radius: 17
                    color: "white"; border.color: "#FFB347"; border.width: 3
                    anchors.verticalCenter: parent.verticalCenter
                    x: (track.width * card.clampedRatio) - width/2
                    z: 10

                    MouseArea {
                        // Larger hit area for easier touch drag.
                        anchors.centerIn: parent
                        width: 64; height: 64
                        drag.target: parent
                        drag.axis: Drag.XAxis
                        drag.minimumX: -parent.width/2
                        drag.maximumX: track.width - parent.width/2
                        onPositionChanged: if (drag.active) {
                            var ratio = track.width > 0 ? (parent.x + parent.width/2) / track.width : 0
                            ratio = Math.max(0, Math.min(1, ratio))
                            card.valueEdited(Math.round(ratio * card.rangeMax))
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width
                Text { text: "0"; color: Theme.textSecondary; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Text { text: (isStep ? "9" : maxValue) + unit; color: Theme.textSecondary; font.pixelSize: 12 }
            }
        }
    }
}
