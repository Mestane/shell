pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    x: bar.clampedInsetLeft + win.dragMaskPadding
    y: bar.clampedInsetTop + win.dragMaskPadding
    width: win.width - bar.clampedInsetLeft - bar.clampedInsetRight - win.dragMaskPadding * 2
    height: win.height - bar.clampedInsetTop - bar.clampedInsetBottom - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: root.panels.dashboard.atTop ? 0 : root.win.height - height
        height: panel.height * (1 - root.panels.dashboard.offsetScale) + (root.panels.dashboard.atTop ? root.bar.insetTop : root.bar.insetBottom)
    }

    R {
        panel: root.panels.launcher
        y: root.panels.launcher.atTop ? 0 : root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + (root.panels.launcher.atTop ? root.bar.insetTop : root.bar.insetBottom)
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.panels.sessionLeft ? 0 : root.win.width - width
        width: panel.width * (1 - root.panels.session.offsetScale) + (root.panels.sessionLeft ? root.bar.insetLeft : root.bar.insetRight) + (root.panels.sessionWithStack ? sidebarRegion.width : 0)
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.panels.stackLeft ? 0 : root.win.width - width
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + (root.panels.stackLeft ? root.bar.insetLeft : root.bar.insetRight)
    }

    R {
        panel: root.panels.osdWrapper
        x: root.panels.osdLeft ? 0 : root.win.width - width
        width: panel.width * (1 - root.panels.osd.offsetScale) + (root.panels.osdLeft ? root.bar.insetLeft : root.bar.insetRight) + (root.panels.osdWithSession ? sessionRegion.width : root.panels.osdWithStack ? sidebarRegion.width : 0)
    }

    R {
        panel: root.panels.notifications
        y: 0
        height: panel.height + root.bar.insetTop
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: panel.height * (1 - root.panels.utilities.offsetScale) + root.bar.insetBottom
    }

    // The desktop's app shortcuts sit under this window, which otherwise takes every click on the desktop. The area
    // left open is the box round the shortcuts, not the whole column they are laid out in.
    Region {
        readonly property Item loader: ShellState.componentsFor(root.win.screen)?.background?.desktopIcons ?? null
        readonly property Item flow: loader?.item ?? null
        readonly property bool shown: loader !== null && flow !== null && loader.visible

        x: shown ? loader.x + flow.childrenRect.x : 0
        y: shown ? loader.y + flow.childrenRect.y : 0
        width: shown ? flow.childrenRect.width : 0
        height: shown ? flow.childrenRect.height : 0
        intersection: Intersection.Subtract
    }

    // While a popout is open its input area is its final one, not the one it is animating through, so the pointer
    // can move onto it as soon as it starts to appear
    Region {
        readonly property Item p: root.panels.popoutsWrapper
        readonly property bool open: root.panels.popouts.hasCurrent || root.panels.popouts.isDetached

        x: root.bar.insetLeft + (open ? p.targetX : p.x)
        y: root.bar.insetTop + (open ? p.targetY : p.y)
        width: open ? p.targetW : (root.bar.vertical ? p.width * (1 - p.offsetScale) : p.width)
        height: open ? p.targetH : (root.bar.vertical ? p.height : p.height * (1 - p.offsetScale))
        intersection: Intersection.Subtract
    }

    component R: Region {
        required property Item panel

        x: panel.x + root.bar.insetLeft
        y: panel.y + root.bar.insetTop
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
