import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    implicitWidth: 220
    implicitHeight: 220
    readonly property real tileSize: Math.min(width, height)
    property alias label: title.text
    property alias imageSource: drinkImage.source
    property bool selected: false
    property real progress: 0
    signal clicked()

    TapHandler {
        onTapped: root.clicked()
    }

    // Faux shadow
    Column {
        anchors.centerIn: parent
        spacing: 12
        width: tileSize

        Item {
            id: cupFrame
            width: tileSize * 0.9
            height: width
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: selected ? Theme.accent : Qt.rgba(1,1,1,0.15)
                border.width: selected ? 2 : 1
            }

            Image {
                id: drinkImage
                anchors.centerIn: parent
                width: tileSize * 0.7
                height: tileSize * 0.6
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        Text {
            id: title
            color: Theme.textPrimary
            font.pixelSize: Theme.cardTitle
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
            wrapMode: Text.NoWrap
        }
    }

    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

}
