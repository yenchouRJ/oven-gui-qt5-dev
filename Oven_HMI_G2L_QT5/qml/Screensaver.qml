import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
  id: saverRoot
  anchors.fill: parent

  // How long to wait before showing the screensaver (ms)
  property int timeoutMs: 100000
  // Emitted when screensaver activates (like React onIdle -> "saver" message)
  signal idle()
  // Emitted when screensaver deactivates (user touches screen)
  signal wakeUp()

  // Internal state
  property bool active: false

  onEnabledChanged: {
    if(!enabled) {
      idleTimer.stop()
      clockTimer.stop()
      active = false
    } else {
      resetIdle()
    }
  }

  function resetIdle() {
    idleTimer.restart()

    if (active) {
      active = false
      wakeUp()
    }
  }

  function activateNow() {
    idleTimer.stop()
    if (!active) {
      active = true
      idle()
    }
  }
  
  Component.onCompleted: {
      idleTimer.start()
  }

  // Idle timer: show screensaver after timeoutMs of no activity
  Timer {
    id: idleTimer
    interval: timeoutMs
    repeat: false
    onTriggered: {
      active = true
      idle()
    }
  }

  // Global input catcher
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.AllButtons
    
    // If the saver is active, consume clicks; otherwise pass them through.
    onPressed: (mouse) => handleInput(mouse)
    onReleased: (mouse) => handleInput(mouse)
    onPositionChanged: (mouse) => { saverRoot.resetIdle(); mouse.accepted = false }
    onWheel: (wheel) => { saverRoot.resetIdle(); wheel.accepted = false }
    
    function handleInput(event) {
        if (saverRoot.active) {
            // Wake up but swallow the click.
            saverRoot.resetIdle()
            event.accepted = true 
        } else {
            // Reset idle timer and allow the click to pass through.
            saverRoot.resetIdle()
            event.accepted = false
        }
    }
  }

  // Dark overlay
  Rectangle {
    anchors.fill: parent
    visible: saverRoot.active
    color: "#000000"
    opacity: 1.0
    z: 1
  }

  Text {
    id: clock
    anchors.centerIn: parent
    visible: saverRoot.active
    color: "#f2f2f2"
    font.pixelSize: 96
    font.bold: true
    opacity: 0.7
    text: Qt.formatTime(new Date(), "hh:mm:ss")
    z: 1
  }

  // Update clock text every second
  Timer {
    id: clockTimer
    interval: 1000
    repeat: true
    running: saverRoot.active
    onTriggered: {
      clock.text = Qt.formatTime(new Date(), "hh:mm:ss")
    }
  }

}
