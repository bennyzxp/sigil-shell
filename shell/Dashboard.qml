import Quickshell
import QtQuick

PanelWindow {
    id: win

    // Only the top edge is anchored, so the window is centered horizontally
    anchors { top: true }
    exclusionMode: ExclusionMode.Ignore   // don't push other windows around
    implicitWidth: 880
    implicitHeight: 320
    color: "transparent"

    // Only these two regions catch the mouse; everything else clicks through
    mask: Region {
        item: trigger
        regions: [ Region { item: card } ]
    }

    property bool open: false

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Small delay before closing so the card doesn't flicker
    Timer {
        id: closeTimer
        interval: 350
        onTriggered: win.open = false
    }

    Item {
        anchors.fill: parent

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    closeTimer.stop();
                    win.open = true;
                } else {
                    closeTimer.restart();
                }
            }
        }

        // Invisible strip at the very top of the screen
        Item {
            id: trigger
            width: parent.width
            height: 6
        }

        // The dashboard card
        Rectangle {
            id: card
            width: parent.width
            height: parent.height
            radius: Theme.radius
            border.color: Theme.border
            border.width: 1

            // Open: tucked up so the top corners are off-screen. Closed: fully hidden.
            y: win.open ? -Theme.radius : -height
            Behavior on y {
                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
            }

            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.surfaceAlt }
                GradientStop { position: 1.0; color: Theme.surface }
            }

            Row {
                x: 20
                y: Theme.radius + 14
                spacing: 14

                // Clock tile
                Rectangle {
                    width: 260
                    height: card.height - Theme.radius - 14 - 20
                    radius: Theme.radius - 8
                    color: "#14ffffff"

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.date, "hh:mm")
                            color: Theme.text
                            font.pixelSize: 56
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toUpperCase()
                            color: Theme.textDim
                            font.pixelSize: 11
                            font.letterSpacing: 2
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 40; height: 2; radius: 1
                            color: Theme.accent
                        }
                    }
                }

                // Placeholder tiles (we fill these in next)
                Repeater {
                    model: ["MEDIA", "SYSTEM"]

                    Rectangle {
                        required property string modelData
                        width: 276
                        height: card.height - Theme.radius - 14 - 20
                        radius: Theme.radius - 8
                        color: "#14ffffff"

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: Theme.textDim
                            font.pixelSize: 12
                            font.letterSpacing: 3
                        }
                    }
                }
            }
        }
    }
}
