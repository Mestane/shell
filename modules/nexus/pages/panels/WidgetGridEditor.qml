pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Miniature of the desktop widget grid: one tile per widget, flowing into the same number of columns as the
// desktop. Drag a tile onto another slot to move it there. Turned-off widgets stay in the grid but faded.
Item {
    id: root

    // [{ id, enabled }] in desktop order
    required property var entries
    required property int columns
    // id -> display name
    required property var names

    signal moved(from: int, to: int)

    readonly property var icons: ({
            calendar: "calendar_month",
            weather: "partly_cloudy_day",
            pomodoro: "timer",
            resources: "monitoring",
            media: "music_note",
            battery: "battery_full"
        })

    readonly property int count: entries.length
    readonly property int cols: Math.max(1, columns)
    readonly property int rows: Math.max(1, Math.ceil(count / cols))
    readonly property real gap: Tokens.spacing.small
    readonly property real cellW: (width - gap * (cols - 1)) / cols
    readonly property real cellH: 64

    // Slot being dragged from, the slot it would land in, and where the pointer is
    property int heldIndex: -1
    property int dropIndex: -1
    property point pointer
    property point grab

    function slotX(i: int): real {
        return (i % cols) * (cellW + gap);
    }

    function slotY(i: int): real {
        return Math.floor(i / cols) * (cellH + gap);
    }

    function slotAt(x: real, y: real): int {
        const col = Math.max(0, Math.min(cols - 1, Math.floor(x / (cellW + gap))));
        const row = Math.max(0, Math.min(rows - 1, Math.floor(y / (cellH + gap))));
        return Math.min(count - 1, row * cols + col);
    }

    Layout.fillWidth: true
    implicitHeight: rows * cellH + (rows - 1) * gap

    Behavior on implicitHeight {
        Anim {}
    }

    // Outline of the slot the dragged tile would land in
    StyledRect {
        visible: root.heldIndex >= 0 && root.dropIndex >= 0
        x: root.slotX(Math.max(0, root.dropIndex))
        y: root.slotY(Math.max(0, root.dropIndex))
        width: root.cellW
        height: root.cellH
        radius: Tokens.rounding.large
        color: Colours.palette.m3primary
        opacity: 0.18

        Behavior on x {
            Anim {}
        }
        Behavior on y {
            Anim {}
        }
    }

    Repeater {
        model: root.entries

        StyledRect {
            id: tile

            required property var modelData
            required property int index

            readonly property bool held: root.heldIndex === index

            x: held ? root.pointer.x - root.grab.x : root.slotX(index)
            y: held ? root.pointer.y - root.grab.y : root.slotY(index)
            z: held ? 1 : 0
            width: root.cellW
            height: root.cellH
            radius: Tokens.rounding.large
            color: held ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
            opacity: modelData.enabled ? 1 : 0.45
            scale: held ? 1.04 : 1

            Behavior on x {
                enabled: !tile.held

                Anim {}
            }
            Behavior on y {
                enabled: !tile.held

                Anim {}
            }
            Behavior on scale {
                Anim {}
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - Tokens.padding.small * 2
                spacing: 2

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.icons[tile.modelData.id] ?? "widgets"
                    color: tile.held ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.names[tile.modelData.id] ?? tile.modelData.id
                    color: tile.held ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    font: Tokens.font.label.medium
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.heldIndex >= 0 ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        onPressed: mouse => {
            const i = root.slotAt(mouse.x, mouse.y);
            // Ignore a press on the empty slots after the last tile
            if (i < 0 || mouse.x > root.slotX(i) + root.cellW || mouse.y > root.slotY(i) + root.cellH || mouse.x < root.slotX(i) || mouse.y < root.slotY(i))
                return;
            root.grab = Qt.point(mouse.x - root.slotX(i), mouse.y - root.slotY(i));
            root.pointer = Qt.point(mouse.x, mouse.y);
            root.dropIndex = i;
            root.heldIndex = i;
        }

        onPositionChanged: mouse => {
            if (root.heldIndex < 0)
                return;
            root.pointer = Qt.point(mouse.x, mouse.y);
            root.dropIndex = root.slotAt(mouse.x, mouse.y);
        }

        onReleased: finish()
        onCanceled: finish()

        function finish(): void {
            const from = root.heldIndex;
            const to = root.dropIndex;
            root.heldIndex = -1;
            root.dropIndex = -1;
            if (from >= 0 && to >= 0 && from !== to)
                root.moved(from, to);
        }
    }
}
