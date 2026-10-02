pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

// The apps one special-workspace keybind (SUPER+D, SUPER+M, ...) opens - see
// services/AppToggles.qml. Shown inside that keybind's own row in the Keybinds page, once
// expanded, alongside its shortcut editor.
ColumnLayout {
    id: root

    required property string category

    property bool adding
    property string pendingName
    property string pendingClass
    property string pendingCommand

    readonly property var apps: AppToggles.categories[root.category] ?? {}
    readonly property var appNames: Object.keys(root.apps)

    function commitAdd(): void {
        const name = root.pendingName.trim();
        if (name === "" || root.appNames.includes(name))
            return;

        AppToggles.addApp(root.category, name, root.pendingClass.trim(), root.pendingCommand.trim());
        root.adding = false;
        root.pendingName = "";
        root.pendingClass = "";
        root.pendingCommand = "";
    }

    Layout.fillWidth: true
    Layout.topMargin: Tokens.spacing.small
    spacing: Tokens.spacing.small

    StyledText {
        Layout.fillWidth: true
        text: Tr.tr("Apps this opens")
        color: Colours.palette.m3outline
        font: Tokens.font.label.small
    }

    Repeater {
        model: root.appNames

        ColumnLayout {
            id: appRow

            required property string modelData

            readonly property var app: root.apps[appRow.modelData]
            readonly property bool isUser: AppToggles.isUserApp(root.category, appRow.modelData)
            readonly property bool simple: AppToggles.isSimpleMatch(appRow.app.match)

            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledSwitch {
                    checked: appRow.app.enable !== false
                    onToggled: AppToggles.setApp(root.category, appRow.modelData, {
                        enable: checked
                    })
                }

                StyledText {
                    Layout.fillWidth: true
                    text: appRow.modelData
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                IconButton {
                    visible: appRow.isUser
                    type: IconButton.Text
                    isRound: true
                    icon: "close"
                    inactiveOnColour: Colours.palette.m3error
                    font: Tokens.font.icon.small
                    label.fill: 0
                    onClicked: AppToggles.removeApp(root.category, appRow.modelData)
                }
            }

            StyledTextField {
                Layout.fillWidth: true
                visible: appRow.simple
                text: AppToggles.classOf(appRow.app.match)
                placeholderText: Tr.tr("Window class")
                onEditingFinished: {
                    if (text !== AppToggles.classOf(appRow.app.match))
                        AppToggles.setClass(root.category, appRow.modelData, text);
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: !appRow.simple
                text: Tr.tr("Has a custom match rule - edit cli.json directly to change it")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            StyledTextField {
                id: commandField

                Layout.fillWidth: true
                text: AppToggles.commandText(appRow.app.command)
                placeholderText: Tr.tr("Command to run")
                onEditingFinished: {
                    if (text !== AppToggles.commandText(appRow.app.command))
                        AppToggles.setCommand(root.category, appRow.modelData, text);
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.adding
        spacing: Tokens.spacing.extraSmall

        StyledTextField {
            Layout.fillWidth: true
            text: root.pendingName
            placeholderText: Tr.tr("Name (used as its id)")
            onTextEdited: root.pendingName = text
        }

        StyledTextField {
            Layout.fillWidth: true
            text: root.pendingClass
            placeholderText: Tr.tr("Window class")
            onTextEdited: root.pendingClass = text
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                Layout.fillWidth: true
                text: root.pendingCommand
                placeholderText: Tr.tr("Command to run")
                onTextEdited: root.pendingCommand = text
                Keys.onReturnPressed: root.commitAdd()
            }

            IconButton {
                type: IconButton.Filled
                isRound: true
                icon: "check"
                disabled: root.pendingName.trim() === "" || root.appNames.includes(root.pendingName.trim())
                font: Tokens.font.icon.medium
                onClicked: root.commitAdd()
            }

            IconButton {
                type: IconButton.Text
                isRound: true
                icon: "close"
                font: Tokens.font.icon.medium
                onClicked: {
                    root.adding = false;
                    root.pendingName = "";
                    root.pendingClass = "";
                    root.pendingCommand = "";
                }
            }
        }
    }

    TextButton {
        visible: !root.adding
        type: TextButton.Text
        isRound: true
        text: Tr.tr("Add app")
        onClicked: root.adding = true
    }
}
