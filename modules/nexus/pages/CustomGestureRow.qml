pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// One user-added custom gesture: a touchpad swipe bound to running a command
ConnectedRect {
    id: root

    required property int index
    required property int fingers
    required property string direction
    required property string command

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: "swipe"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                fill: 1
            }

            StyledSpinBox {
                fieldWidth: 32
                from: 2
                to: 5
                value: root.fingers
                onValueModified: Keybinds.setCustomGesture(root.index, value, root.direction, root.command)
            }

            GestureDirectionPicker {
                direction: root.direction
                onSelected: d => Keybinds.setCustomGesture(root.index, root.fingers, d, root.command)
            }

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                type: IconButton.Text
                isRound: true
                icon: "close"
                inactiveOnColour: Colours.palette.m3error
                font: Tokens.font.icon.medium
                onClicked: Keybinds.removeCustomGesture(root.index)
            }
        }

        StyledTextField {
            Layout.fillWidth: true
            text: root.command
            placeholderText: Tr.tr("Command to run")

            onEditingFinished: {
                if (text !== root.command)
                    Keybinds.setCustomGesture(root.index, root.fingers, root.direction, text);
            }
        }
    }
}
