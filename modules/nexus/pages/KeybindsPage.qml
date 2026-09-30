pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// NOTE(fork): change the Hyprland keybinds without editing Lua. See services/Keybinds.qml.
PageBase {
    id: root

    // A custom bind being added, not saved until it has both a combo and a command
    property bool addingCustom
    property string pendingCombo
    property string pendingCommand

    function commitCustom(): void {
        if (root.pendingCombo === "" || root.pendingCommand.trim() === "")
            return;

        Keybinds.addCustomBind(root.pendingCombo, root.pendingCommand.trim());
        root.addingCustom = false;
        root.pendingCombo = "";
        root.pendingCommand = "";
    }

    // Sections of the binds that match the search, in file order
    readonly property var groups: {
        const q = search.text.trim().toLowerCase();
        const sections = new Map();
        for (const e of Keybinds.entries) {
            if (q && !`${e.label} ${e.combos.map(c => Keybinds.pretty(c)).join(" ")}`.toLowerCase().includes(q))
                continue;
            if (!sections.has(e.section))
                sections.set(e.section, []);
            sections.get(e.section).push(e);
        }
        return [...sections].map(([name, items]) => ({
                    name: name.charAt(0).toUpperCase() + name.slice(1),
                    items
                }));
    }

    title: Tr.tr("Keybinds")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledTextField {
            id: search

            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.large
            visible: Keybinds.available
            leadingIcon: "search"
            placeholderText: Tr.tr("Search keybinds")
        }

        StyledText {
            Layout.fillWidth: true
            visible: !Keybinds.available
            text: Tr.tr("No keybinds were found in your Hyprland config (hypr/variables.lua).")
            color: Colours.palette.m3outline
            wrapMode: Text.WordWrap
        }

        StyledText {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.small
            visible: Keybinds.available && search.text === ""
            text: Tr.tr("Click a keybind to change it. Pick its modifiers, then click the key and press the one you want. Changes are saved to your hypr-vars.lua and Hyprland is reloaded.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        Repeater {
            // Keyed by name, so a row keeps being expanded while its own shortcuts change
            model: ScriptModel {
                values: root.groups
                objectProp: "name"
            }

            ColumnLayout {
                id: group

                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    first: group.index === 0
                    text: group.modelData.name
                }

                Repeater {
                    model: ScriptModel {
                        values: group.modelData.items
                        objectProp: "id"
                    }

                    KeybindRow {
                        required property var modelData
                        required property int index

                        entry: modelData
                        first: index === 0
                        last: index === group.modelData.items.length - 1
                    }
                }
            }
        }

        ColumnLayout {
            id: customGroup

            Layout.fillWidth: true
            visible: search.text === ""
            spacing: Tokens.spacing.extraSmall / 2

            SectionHeader {
                first: root.groups.length === 0
                text: Tr.tr("Custom")
            }

            Repeater {
                model: ScriptModel {
                    values: Keybinds.customBinds
                }

                CustomKeybindRow {
                    // index is filled in directly since this already declares its own
                    // "required property int index"
                    required property var modelData

                    combo: modelData.combo
                    command: modelData.command
                }
            }

            ConnectedRect {
                Layout.fillWidth: true
                last: true
                implicitHeight: addRow.implicitHeight + Tokens.padding.medium * 2

                ColumnLayout {
                    id: addRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium
                        visible: root.addingCustom

                        ComboEditor {
                            Layout.fillWidth: true
                            combo: root.pendingCombo
                            startCapturing: root.pendingCombo === ""
                            removable: true
                            onChanged: c => root.pendingCombo = c
                            onRemoved: {
                                root.addingCustom = false;
                                root.pendingCombo = "";
                                root.pendingCommand = "";
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium
                        visible: root.addingCustom

                        StyledTextField {
                            Layout.fillWidth: true
                            text: root.pendingCommand
                            placeholderText: Tr.tr("Command to run")
                            onTextEdited: root.pendingCommand = text
                            Keys.onReturnPressed: root.commitCustom()
                        }

                        IconButton {
                            type: IconButton.Filled
                            isRound: true
                            icon: "check"
                            disabled: root.pendingCombo === "" || root.pendingCommand.trim() === ""
                            font: Tokens.font.icon.medium
                            onClicked: root.commitCustom()
                        }
                    }

                    TextButton {
                        visible: !root.addingCustom
                        type: TextButton.Text
                        isRound: true
                        text: Tr.tr("Add keybind")
                        onClicked: root.addingCustom = true
                    }
                }
            }
        }
    }
}
