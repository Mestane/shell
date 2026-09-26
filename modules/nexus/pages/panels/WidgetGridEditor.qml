pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import "../../../../utils/widgetgrid.js" as WidgetGrid

// A miniature of the screen with the desktop widgets on it. Drag a widget and it snaps to the desktop's grid;
// it can go anywhere it doesn't overlap another widget.
Item {
    id: root

    // [{ id, enabled, col, row }] as in the config
    required property var entries
    required property int columns
    required property string position
    // id -> display name
    required property var names
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Where every widget ends up, parallel to `entries`, after a drop. Only widgets that are turned on have a cell.
    signal placed(var placements)

    readonly property var icons: ({
            calendar: "calendar_month",
            weather: "partly_cloudy_day",
            pomodoro: "timer",
            resources: "monitoring",
            media: "music_note",
            battery: "bolt"
        })

    readonly property real factor: width / Math.max(1, screenWidth)
    readonly property real cell: WidgetGrid.unit * factor
    readonly property int gridCols: Math.floor(screenWidth / WidgetGrid.unit)
    readonly property int gridRows: Math.floor(screenHeight / WidgetGrid.unit)
    readonly property var placements: WidgetGrid.place(entries, gridCols, gridRows, columns, position)

    // The widget being dragged, where the pointer is, and the cell it would drop into
    property int heldIndex: -1
    property point pointer
    property point grab
    property int dropCol
    property int dropRow
    property bool dropValid

    function updateDrop(): void {
        const p = placements[heldIndex];
        dropCol = Math.max(0, Math.min(gridCols - p.w, Math.round((pointer.x - grab.x) / cell)));
        dropRow = Math.max(0, Math.min(gridRows - p.h, Math.round((pointer.y - grab.y) / cell)));
        dropValid = !WidgetGrid.collides(placements, heldIndex, dropCol, dropRow, p.w, p.h);
    }

    function tileAt(x: real, y: real): int {
        for (let i = placements.length - 1; i >= 0; i--) {
            const p = placements[i];
            if (p.enabled && x >= p.col * cell && x < (p.col + p.w) * cell && y >= p.row * cell && y < (p.row + p.h) * cell)
                return i;
        }
        return -1;
    }

    Layout.fillWidth: true
    implicitHeight: screenHeight * factor

    Behavior on implicitHeight {
        Anim {}
    }

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLowest
    }

    // Grid lines, only while a widget is being moved
    Canvas {
        anchors.fill: parent
        opacity: root.heldIndex >= 0 ? 1 : 0
        visible: opacity > 0
        // Every fourth line, so it reads as a grid without turning into a wall of lines
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = Qt.alpha(Colours.palette.m3outline, 0.25);
            ctx.lineWidth = 1;
            ctx.beginPath();
            const step = root.cell * 4;
            for (let x = step; x < width; x += step) {
                ctx.moveTo(x, 0);
                ctx.lineTo(x, height);
            }
            for (let y = step; y < height; y += step) {
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
            }
            ctx.stroke();
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Behavior on opacity {
            Anim {}
        }
    }

    // Where the dragged widget would land: blue when it fits, red when it would overlap another
    StyledRect {
        readonly property var held: root.heldIndex >= 0 ? root.placements[root.heldIndex] : null

        visible: held !== null
        x: root.dropCol * root.cell
        y: root.dropRow * root.cell
        width: (held?.w ?? 0) * root.cell
        height: (held?.h ?? 0) * root.cell
        radius: Tokens.rounding.small
        color: root.dropValid ? Colours.palette.m3primary : Colours.palette.m3error
        opacity: 0.25
    }

    Repeater {
        model: root.placements

        StyledRect {
            id: tile

            required property var modelData
            required property int index

            readonly property bool held: root.heldIndex === index

            visible: modelData.enabled
            x: held ? root.pointer.x - root.grab.x : modelData.col * root.cell
            y: held ? root.pointer.y - root.grab.y : modelData.row * root.cell
            z: held ? 1 : 0
            width: modelData.w * root.cell
            height: modelData.h * root.cell
            radius: Tokens.rounding.small
            color: held ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outline, 0.5)
            opacity: held ? 0.9 : 1

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 4
                spacing: 0

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
                    font: Tokens.font.label.small
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.heldIndex >= 0 ? Qt.ClosedHandCursor : Qt.ArrowCursor

        onPressed: mouse => {
            const i = root.tileAt(mouse.x, mouse.y);
            if (i < 0)
                return;
            const p = root.placements[i];
            root.grab = Qt.point(mouse.x - p.col * root.cell, mouse.y - p.row * root.cell);
            root.pointer = Qt.point(mouse.x, mouse.y);
            root.heldIndex = i;
            root.updateDrop();
        }

        onPositionChanged: mouse => {
            if (root.heldIndex < 0)
                return;
            root.pointer = Qt.point(mouse.x, mouse.y);
            root.updateDrop();
        }

        onReleased: finish()
        onCanceled: finish()

        function finish(): void {
            const i = root.heldIndex;
            if (i < 0)
                return;
            const p = root.placements[i];
            const ok = root.dropValid && (root.dropCol !== p.col || root.dropRow !== p.row || !p.placed);
            const col = root.dropCol;
            const row = root.dropRow;
            root.heldIndex = -1;
            if (!ok)
                return;

            // Pin every widget where it is now, so nothing else shifts when the layout stops flowing
            const out = root.placements.map(q => ({
                        enabled: q.enabled,
                        col: q.col,
                        row: q.row
                    }));
            out[i].col = col;
            out[i].row = row;
            root.placed(out);
        }
    }
}
