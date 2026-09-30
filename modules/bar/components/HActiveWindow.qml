pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// Horizontal-bar counterpart to ActiveWindow.qml: that one rotates the title 90 degrees to run
// along a narrow vertical bar's length, which makes no sense here, so this just runs the icon
// and title left to right, elided to whatever room the rest of the bar's entries leave it
Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return Tr.trCtx("Desktop", "shown when no window is focused");
        if (Config.bar.activeWindow.compact) {
            // " - " (standard hyphen), " — " (em dash), " – " (en dash)
            const parts = title.split(/\s+[\-–—]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    // As wide as this could possibly be without the bar's other entries having to shrink -
    // the same technique ActiveWindow.qml uses for maxHeight, along the other axis
    readonly property real maxWidth: {
        const otherModules = bar.children.filter(c => c.entryId && c.item !== this && c.entryId !== "spacer");
        const otherWidth = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimWidth ?? curr.width), 0);
        return bar.width - otherWidth - bar.spacing * (bar.children.length - 1) - bar.hPadding * 2;
    }

    clip: true
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: !Config.bar.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPositionChanged: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = Qt.binding(() => root.mapToItem(root.bar, root.implicitWidth / 2, 0).x);
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            id: icon

            animate: true
            text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
            color: root.colour
        }

        StyledText {
            id: label

            Layout.maximumWidth: Math.max(0, root.maxWidth - icon.implicitWidth - row.spacing)
            text: root.windowTitle
            color: root.colour
            font: Tokens.font.body.builders.small.letterSpacing(1.4).build()
            elide: Text.ElideRight
        }
    }
}
