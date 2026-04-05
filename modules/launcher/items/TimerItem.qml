pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services
import qs.config
import qs.modules.launcher.services

Item {
    id: root

    required property var list

    readonly property string input: list.search.text.slice(`${Config.launcher.actionPrefix}timer `.length).trim()
    readonly property int parsedMinutes: parseInt(input) || 0

    function onClicked(): void {
        if (parsedMinutes > 0) {
            PomodoroTimer.start(parsedMinutes, "");
            root.list.visibilities.launcher = false;
        }
    }

    implicitHeight: Config.launcher.sizes.itemHeight
    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        function onClicked(): void { root.onClicked(); }
        radius: Appearance.rounding.normal
        disabled: root.parsedMinutes <= 0 && !PomodoroTimer.running
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.padding.larger
        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: PomodoroTimer.running ? "timer" : "add_alarm"
            font.pointSize: Appearance.font.size.extraLarge
            color: PomodoroTimer.running ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            animate: true
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: {
                    if (PomodoroTimer.running)
                        return qsTr("%1 — %2").arg(PomodoroTimer.label).arg(PomodoroTimer.display);
                    if (root.parsedMinutes > 0)
                        return qsTr("Start %1 minute timer").arg(root.parsedMinutes);
                    return qsTr("Type minutes to start a timer");
                }
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Progress bar
            Item {
                Layout.fillWidth: true
                implicitHeight: 3
                visible: PomodoroTimer.running

                StyledRect {
                    anchors.fill: parent
                    radius: Appearance.rounding.full
                    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                }

                StyledRect {
                    width: parent.width * PomodoroTimer.progress
                    height: parent.height
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3primary

                    Behavior on width { Anim { duration: 900 } }
                }
            }
        }

        // Controls when timer is running
        Row {
            spacing: Appearance.spacing.smaller
            Layout.alignment: Qt.AlignVCenter
            visible: PomodoroTimer.running

            // Pause/Resume
            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: pauseIcon.implicitHeight + Appearance.padding.small * 2
                radius: Appearance.rounding.small
                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                StateLayer {
                    function onClicked(): void { PomodoroTimer.pause(); }
                    radius: parent.radius
                }

                MaterialIcon {
                    id: pauseIcon
                    anchors.centerIn: parent
                    text: PomodoroTimer.paused ? "play_arrow" : "pause"
                    font.pointSize: Appearance.font.size.normal
                    animate: true
                }
            }

            // Stop
            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: stopIcon.implicitHeight + Appearance.padding.small * 2
                radius: Appearance.rounding.small
                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                StateLayer {
                    function onClicked(): void { PomodoroTimer.stop(); }
                    radius: parent.radius
                }

                MaterialIcon {
                    id: stopIcon
                    anchors.centerIn: parent
                    text: "stop"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3error
                }
            }
        }
    }
}
