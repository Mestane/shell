pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// One keybind: its name and shortcuts, and when clicked the controls to change them
ConnectedRect {
    id: root

    required property var entry
    property bool expanded
    // A new shortcut being added, not saved until it has a key
    property bool adding

    // One icon per section, the same leading-icon treatment every other settings row already
    // has (see RowButton) - Keybinds was the one page that never got it
    readonly property var sectionIcons: ({
            "Workspaces": "workspaces",
            "Window Group": "select_window",
            "Window Actions": "fullscreen",
            "Apps": "apps",
            "Utilities": "construction",
            "Media": "queue_music",
            "Misc": "tune",
            "Clipboard and emoji picker": "content_paste"
        })
    readonly property string icon: root.sectionIcons[root.entry.section] ?? "keyboard"

    readonly property var combos: root.entry.combos
    readonly property var clashing: {
        const found = [];
        for (const c of root.combos) {
            for (const other of Keybinds.usedBy(root.entry.id, c)) {
                if (!found.includes(other))
                    found.push(other);
            }
        }
        return found;
    }

    Layout.fillWidth: true
    implicitHeight: header.implicitHeight + (root.expanded ? editor.implicitHeight + Tokens.padding.medium : 0)
    clip: true

    Behavior on implicitHeight {
        Anim {
            type: Anim.FastSpatial
        }
    }

    function replace(index: int, combo: string): void {
        const next = [...root.combos];
        next[index] = combo;
        Keybinds.set(root.entry.id, next);
    }

    function remove(index: int): void {
        Keybinds.set(root.entry.id, root.combos.filter((_, i) => i !== index));
    }

    Item {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: headerRow.implicitHeight + Tokens.padding.medium * 2

        StateLayer {
            onClicked: {
                root.expanded = !root.expanded;
                if (!root.expanded)
                    root.adding = false;
            }
        }

        RowLayout {
            id: headerRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: root.icon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                fill: 1
            }

            Column {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                StyledText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: root.entry.prefix ? Tr.tr("%1 (with 1–0)").arg(root.entry.label) : root.entry.label
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: root.combos.length === 0
                    text: Tr.tr("Not set")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }

                Flow {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: root.combos.length > 0
                    spacing: Tokens.spacing.extraSmall

                    Repeater {
                        model: root.combos

                        StyledRect {
                            id: chip

                            required property string modelData

                            radius: Tokens.rounding.small
                            color: root.clashing.length > 0 ? Qt.alpha(Colours.palette.m3error, 0.15) : Colours.tPalette.m3surfaceContainerHighest
                            implicitWidth: chipLabel.implicitWidth + Tokens.padding.small * 2
                            implicitHeight: chipLabel.implicitHeight + Tokens.padding.extraSmall * 2

                            StyledText {
                                id: chipLabel

                                anchors.centerIn: parent
                                text: Keybinds.pretty(chip.modelData)
                                color: root.clashing.length > 0 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                            }
                        }
                    }
                }
            }

            MaterialIcon {
                visible: root.entry.overridden
                text: "edit"
                color: Colours.palette.m3tertiary
                fontStyle: Tokens.font.icon.small
            }

            MaterialIcon {
                visible: root.clashing.length > 0
                text: "warning"
                color: Colours.palette.m3error
                fontStyle: Tokens.font.icon.medium
            }

            MaterialIcon {
                text: "expand_more"
                rotation: root.expanded ? 180 : 0
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium

                Behavior on rotation {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: editor

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small
        visible: root.expanded

        StyledText {
            Layout.fillWidth: true
            visible: root.clashing.length > 0
            text: Tr.tr("Also used by %1").arg(root.clashing.join(", "))
            color: Colours.palette.m3error
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: root.combos

            ComboEditor {
                id: combo

                required property int index
                required property string modelData

                Layout.fillWidth: true
                combo: modelData
                prefix: root.entry.prefix
                removable: true
                onChanged: c => root.replace(combo.index, c)
                onRemoved: root.remove(combo.index)
            }
        }

        // A shortcut that has no key yet: it is only saved once one is pressed
        Loader {
            Layout.fillWidth: true
            active: root.adding
            visible: active

            sourceComponent: ComboEditor {
                startCapturing: true
                onChanged: c => {
                    root.adding = false;
                    Keybinds.set(root.entry.id, [...root.combos, c]);
                }
                onRemoved: root.adding = false
            }
        }

        RowLayout {
            spacing: Tokens.spacing.small

            TextButton {
                visible: !root.entry.prefix
                type: TextButton.Text
                isRound: true
                text: Tr.tr("Add shortcut")
                onClicked: root.adding = true
            }

            TextButton {
                visible: root.entry.overridden
                type: TextButton.Text
                isRound: true
                text: Tr.tr("Reset to default")
                onClicked: Keybinds.reset(root.entry.id)
            }
        }

        // A special-workspace keybind (SUPER+D, SUPER+M, ...) also controls which apps it
        // opens, on top of its own shortcut - see services/AppToggles.qml
        Loader {
            Layout.fillWidth: true
            active: root.expanded && AppToggles.categoryFor(root.entry.id) !== ""

            sourceComponent: AppListEditor {
                category: AppToggles.categoryFor(root.entry.id)
            }
        }
    }
}
