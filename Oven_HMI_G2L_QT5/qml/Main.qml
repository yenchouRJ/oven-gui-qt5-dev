/**
 * @file Main.qml
 * @brief Root UI for the Oven HMI application.
 *
 * Provides the main window, integrates the 3‑D coffee preview, menu navigation,
 * and status display.  The UI is driven by signals emitted from the C++ backend
 * (SerialHandler, FpsMonitor, etc.).
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import QtMultimedia 5.15
import "drinks.js" as Data

ApplicationWindow {
    // Application window configuration
    id: root
    visible: true
    width: 1280
    height: 480
    color: "black" // Background set to black for better video playback
    title: "Oven Station"
    visibility: Window.FullScreen

    // Preload the menu for smooth transition from the startup page
    property var preloadedMenu: null

    // Brew data transferred between pages
    property var currentBrewData: {
        "drinkName": "Stone-Baked Pizza",
        "strength": 6, "grind": 4,
        "quantity": 1, "quantityUnit": "pcs",
        "time": 15, "timeUnit": "min",
        "temp": 220, "tempUnit": "C"
    }
    // Track the currently selected drink ID for quick start (tplay)
    property string selectedDrinkId: ""
    // Track the current page command for screen‑saver wake‑up
    property string currentPageCmd: "poff"

    // Power state: false = Production (wait for tpower), true = Debug (direct start)
    property bool isPoweredOn: true // Skip the first tpower request

    // Track whether the processing page is active (brew in progress)
    property bool brewActive: false

    // Global shortcut for exiting the application
    Shortcut {
        sequence: "Esc"
        onActivated: Qt.quit()
        context: Qt.ApplicationShortcut
    }

    // Serial signal listeners
    Connections {
        target: serialHandler

        function onPowerOffRequested() {
            console.log("CMD: Power Off (tpf)")
            sendSerialCommand("poff")
            isPoweredOn = false
            brewActive = false
            currentPageCmd = "poff"
            nav.clear() // Clear stack completely (no background startup/video)
        }

        function onPowerOnRequested() {
            console.log("CMD: Power On (tpower)")
            isPoweredOn = true
            // Send startup signal
            sendSerialCommand("su")
            nav.push(startupPageComponent) // Push fresh startup
        }

        function onPlayOnRequested() {
            if (brewActive || !isPoweredOn || screenSaver.active) return
            console.log("CMD: Quick Play (tplay)")

            // If on AdjustmentPage, use current UI settings
            if (currentPageCmd === "pm2" && nav.currentItem && nav.currentItem.startBrewFromSerial) {
                console.log(" -> Brewing with current Adjustment settings")
                nav.currentItem.startBrewFromSerial()
                return
            }

            // Only allow from menu (pm1)
            if (currentPageCmd !== "pm1") return

            var id = root.selectedDrinkId
            if (id === "") {
                if (Data.drinks.length > 0) id = Data.drinks[0].id
                else return
            }

            var drinkObj = null
            for (var i = 0; i < Data.drinks.length; i++) {
                if (Data.drinks[i].id === id) {
                    drinkObj = Data.drinks[i]
                    break
                }
            }

            if (drinkObj) {
                var source = drinkObj.userPreferences ? drinkObj.userPreferences : drinkObj.defaults
                var quantityUnit = drinkObj.defaults && drinkObj.defaults.quantity ? drinkObj.defaults.quantity.unit : ""
                var timeUnit = drinkObj.defaults && drinkObj.defaults.contactTime ? drinkObj.defaults.contactTime.unit : ""
                var tempUnit = drinkObj.defaults && drinkObj.defaults.temperature ? drinkObj.defaults.temperature.unit : ""

                Data.currentBrewSettings = {
                    "drinkName": drinkObj.label,
                    "strength": source.strength,
                    "grind": source.grind,
                    "quantity": source.quantity.value !== undefined ? source.quantity.value : source.quantity,
                    "quantityUnit": quantityUnit,
                    "time": source.contactTime.value !== undefined ? source.contactTime.value : source.contactTime,
                    "contactTime": source.contactTime.value !== undefined ? source.contactTime.value : source.contactTime,
                    "timeUnit": timeUnit,
                    "temp": source.temperature.value !== undefined ? source.temperature.value : source.temperature,
                    "temperature": source.temperature.value !== undefined ? source.temperature.value : source.temperature,
                    "tempUnit": tempUnit
                }
                showProcessingPage(id)
            }
        }

        function onSaverRequested() {
            if (brewActive || !isPoweredOn) return
            console.log("CMD: Screen saver (tsave)")
            screenSaver.activateNow()
        }

        function onWakeScreenRequested(){
            console.log("CMD: Wake Screen (twake)")
            screenSaver.resetIdle()
        }
    }

    StackView {
        id: nav
        anchors.fill: parent
        initialItem: startupPageComponent
        pushEnter: Transition { PropertyAnimation { properties: "opacity"; from: 0; to: 1; duration: 500 } }
        pushExit: Transition { PropertyAnimation { properties: "opacity"; from: 1; to: 0; duration: 500 } }
        popEnter: Transition { NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.InOutQuad } }
        popExit: Transition { NumberAnimation { properties: "opacity"; from: 1; to: 0; duration: 1000; easing.type: Easing.InOutQuad } }
    }

    // Sound effect system
    SoundEffect {
        id: uiSound
        source: "qrc:/assets/media/click_2.wav"
        volume: 0.5
    }
    function sendSerialCommand(cmd) {
        if (typeof serialHandler !== "undefined" && serialHandler && serialHandler.connected) {
            serialHandler.send(cmd)
        }
    }
    function sendAndRecordCmd(cmd) {
        currentPageCmd = cmd
        sendSerialCommand(cmd)
    }
    function showMenuPage(replace) {
        uiSound.play()
        sendAndRecordCmd("pm1")
        if (replace) nav.replace(menuPageComponent)
        else nav.push(menuPageComponent)
    }
    function showAdjustmentPage(drinkId) {
        uiSound.play()
        sendAndRecordCmd("pm2")
        nav.push(adjustmentPageComponent, { drinkId: drinkId })
    }
    function showProcessingPage(drinkId) {
        if (brewActive) return
        brewActive = true
        uiSound.play()
        sendSerialCommand("brew")
        nav.push(processingPageComponent, { "drinkId": drinkId })
    }

    Component.onCompleted: {
        console.log("Attempting to connect to serial port COM1...")
        if (typeof serialHandler !== "undefined") {
            serialHandler.open("/dev/ttySC1", 115200)
        }
    }

    // Page components definitions
    Component {
        id: startupPageComponent
        StartupPage {
            onFinished: {
                if (isPoweredOn) {
                    nav.replace(menuPageComponent, {}, StackView.Immediate)
                    sendAndRecordCmd("pm1")
                }
            }
        }
    }
    Component {
        id: menuPageComponent
        MenuPage {
            onCurrentDrinkIdChanged: {
                root.selectedDrinkId = currentDrinkId
            }
            onAdjustRequested: (drinkId) => {
                root.showAdjustmentPage(drinkId)
            }
        }
    }
    Component {
        id: adjustmentPageComponent
        AdjustmentPage {
            onBack: {
                sendAndRecordCmd("pm1")
                nav.pop()
            }
            onStartBrew: (drinkId) => {
                root.showProcessingPage(drinkId)
            }
        }
    }
    Component {
        id: processingPageComponent
        ProcessingPage {
            onFinished: {
                brewActive = false
                nav.pop(null)
                sendAndRecordCmd("pm1")
            }
            onCancelled: {
                brewActive = false
                nav.pop(null)
                sendSerialCommand("STOP")
                sendAndRecordCmd("pm1")
            }
        }
    }

    // Screensaver overlay
    Screensaver {
        id: screenSaver
        z: 100
        anchors.fill: parent
        enabled: isPoweredOn
        timeoutMs: 60000 // 60 s idle timeout
        onIdle: {
            console.log("Screensaver Activated -> Sending 'saver'")
            root.sendSerialCommand("saver")
        }
        onWakeUp: {
            console.log("Screensaver Woke Up -> Resending " + currentPageCmd)
            root.sendSerialCommand(currentPageCmd)
        }
    }

    // Power‑off overlay (hard sleep)
    Rectangle {
        id: powerOffOverlay
        z: 999
        anchors.fill: parent
        color: "black"
        visible: !root.isPoweredOn
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => { mouse.accepted = true }
            onReleased: (mouse) => { mouse.accepted = true }
            onPositionChanged: (mouse) => { mouse.accepted = true }
            onWheel: (wheel) => { wheel.accepted = true }
        }
    }
}
