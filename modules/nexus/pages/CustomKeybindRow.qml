pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// One user-added custom keybind: an arbitrary combo bound to running a command, unlike every
// other row on this page which just rebinds a fixed, already-existing shortcut
ConnectedRect {
    id: root

    required property int index
    required property string combo
    required property string command

    readonly property var clashing: Keybinds.usedBy(`custom:${root.index}`, root.combo)

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

            ComboEditor {
                Layout.fillWidth: true
                combo: root.combo
                removable: false
                onChanged: c => Keybinds.setCustomBind(root.index, c, root.command)
            }

            MaterialIcon {
                visible: root.clashing.length > 0
                text: "warning"
                color: Colours.palette.m3error
                fontStyle: Tokens.font.icon.medium
            }

            IconButton {
                type: IconButton.Text
                isRound: true
                icon: "close"
                inactiveOnColour: Colours.palette.m3error
                font: Tokens.font.icon.medium
                onClicked: Keybinds.removeCustomBind(root.index)
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.clashing.length > 0
            text: Tr.tr("Also used by %1").arg(root.clashing.join(", "))
            color: Colours.palette.m3error
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        StyledTextField {
            id: commandField

            Layout.fillWidth: true
            text: root.command
            placeholderText: Tr.tr("Command to run")

            onEditingFinished: {
                if (text !== root.command)
                    Keybinds.setCustomBind(root.index, root.combo, text);
            }
        }
    }
}
