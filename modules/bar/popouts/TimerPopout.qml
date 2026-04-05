pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import qs.config

Item {
    id: root

    readonly property int contentWidth: 240

    implicitWidth: contentWidth + Appearance.padding.normal * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.normal * 2

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        width: root.contentWidth
        spacing: Appearance.spacing.normal

        // Header
        RowLayout {
            spacing: Appearance.spacing.normal

            // MaterialIcon {
            //     text: "timer"
            //     color: Colours.palette.m3primary
            //     font.pointSize: Appearance.font.size.extraLarge
            // }

            StyledText {
                text: qsTr("Pomodoro")
                font.pointSize: Appearance.font.size.normal
                font.weight: 500
                Layout.fillWidth: true
            }
        }

        // Active timer display
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: timerContent.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer
            visible: PomodoroTimer.running

            ColumnLayout {
                id: timerContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: PomodoroTimer.display
                    font.pointSize: Appearance.font.size.extraLarge * 2
                    font.weight: 300
                    color: PomodoroTimer.paused ? Colours.palette.m3outline : Colours.palette.m3onSurface
                    Behavior on color { CAnim {} }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: PomodoroTimer.label
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.normal
                    visible: PomodoroTimer.label.length > 0
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 4

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

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Appearance.spacing.normal

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: pauseIcon.implicitHeight + Appearance.padding.normal * 2
                        radius: Appearance.rounding.normal
                        color: Colours.palette.m3secondaryContainer

                        StateLayer {
                            function onClicked(): void { PomodoroTimer.pause(); }
                            color: Colours.palette.m3onSecondaryContainer
                            radius: parent.radius
                        }

                        MaterialIcon {
                            id: pauseIcon
                            anchors.centerIn: parent
                            text: PomodoroTimer.paused ? "play_arrow" : "pause"
                            color: Colours.palette.m3onSecondaryContainer
                            font.pointSize: Appearance.font.size.extraLarge
                            animate: true
                        }
                    }

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: addIcon.implicitHeight + Appearance.padding.normal * 2
                        radius: Appearance.rounding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                        StateLayer {
                            function onClicked(): void {
                                PomodoroTimer.remainingSeconds = Math.min(
                                    PomodoroTimer.remainingSeconds + 300,
                                    PomodoroTimer.totalSeconds + 300
                                );
                                PomodoroTimer.totalSeconds = Math.max(
                                    PomodoroTimer.totalSeconds,
                                    PomodoroTimer.remainingSeconds
                                );
                            }
                            radius: parent.radius
                        }

                        MaterialIcon {
                            id: addIcon
                            anchors.centerIn: parent
                            text: "more_time"
                            font.pointSize: Appearance.font.size.extraLarge
                        }
                    }

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: stopIcon.implicitHeight + Appearance.padding.normal * 2
                        radius: Appearance.rounding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                        StateLayer {
                            function onClicked(): void { PomodoroTimer.stop(); }
                            radius: parent.radius
                        }

                        MaterialIcon {
                            id: stopIcon
                            anchors.centerIn: parent
                            text: "stop"
                            color: Colours.palette.m3error
                            font.pointSize: Appearance.font.size.extraLarge
                        }
                    }
                }
            }
        }

        // Start new timer
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: startContent.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: startContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: PomodoroTimer.running ? qsTr("Start new timer") : qsTr("Set timer duration")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                    Layout.alignment: Qt.AlignHCenter
                }

                // Quick presets
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.smaller

                    Repeater {
                        model: [5, 10, 15, 25, 45]

                        StyledRect {
                            required property int modelData
                            Layout.fillWidth: true
                            implicitHeight: presetLabel.implicitHeight + Appearance.padding.small * 2
                            radius: Appearance.rounding.small
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                            StateLayer {
                                function onClicked(): void {
                                    PomodoroTimer.start(modelData, qsTr("%1 min timer").arg(modelData));
                                }
                                radius: parent.radius
                            }

                            StyledText {
                                id: presetLabel
                                anchors.centerIn: parent
                                text: `${modelData}m`
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3primary
                            }
                        }
                    }
                }

                // Custom input
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: customInput.implicitHeight + Appearance.padding.small * 2
                        radius: Appearance.rounding.small
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                        MouseArea {
                            anchors.fill: parent
                            onClicked: customInput.forceActiveFocus()
                        }

                        StyledTextField {
                            id: customInput
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Appearance.padding.normal
                            placeholderText: qsTr("Custom (min)")
                            validator: IntValidator { bottom: 1; top: 999 }

                            background: Item {}

                            onAccepted: {
                                const mins = parseInt(text);
                                if (!isNaN(mins) && mins > 0) {
                                    PomodoroTimer.start(mins, qsTr("%1 min timer").arg(mins));
                                    text = "";
                                }
                            }
                        }
                    }

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: startIcon.implicitHeight + Appearance.padding.small * 2
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3primaryContainer

                        StateLayer {
                            function onClicked(): void {
                                const mins = parseInt(customInput.text);
                                if (!isNaN(mins) && mins > 0) {
                                    PomodoroTimer.start(mins, qsTr("%1 min timer").arg(mins));
                                    customInput.text = "";
                                }
                            }
                            radius: parent.radius
                        }

                        MaterialIcon {
                            id: startIcon
                            anchors.centerIn: parent
                            text: "play_arrow"
                            color: Colours.palette.m3onPrimaryContainer
                            font.pointSize: Appearance.font.size.normal
                        }
                    }
                }
            }
        }
    }
}
