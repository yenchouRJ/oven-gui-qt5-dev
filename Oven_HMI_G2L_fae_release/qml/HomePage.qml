import QtQuick 2.15

Item {
    id: root
    signal startVideo()

    // This page is headless; it only establishes the serial connection.
    visible: false
    width: 0
    height: 0

    // Serial connection parameters (override from outside if needed).
    property string portName: "/dev/ttySC1"
    property int baudRate: 115200

    Component.onCompleted: {
        if (serialHandler && !serialHandler.connected) {
            serialHandler.open(portName, baudRate)
        }
    }

    Connections {
        target: serialHandler

        function onPowerOnRequested() {
             root.startVideo()
        }
        function onPlayOnRequested() {

        }


    }
}
