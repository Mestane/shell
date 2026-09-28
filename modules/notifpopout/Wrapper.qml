pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.modules.sidebar as Sidebar

// The notification / media library popout, opened by a 4-finger swipe. A panel in the drawers window like the
// sidebar, so its background is one of the frame's morphing blobs rather than a window of its own.
Item {
    id: root

    required property ScreenState screenState
    // Separate from the sidebar's own so expanding cards in one doesn't affect the other
    readonly property Sidebar.Props props: Sidebar.Props {
        reloadableId: "notifPopout"
    }

    readonly property bool shouldBeActive: screenState.notifPopout
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.rightMargin: (-implicitWidth - 5) * offsetScale
    implicitWidth: Tokens.sizes.sidebar.width
    opacity: 1 - offsetScale

    // Both live on the same edge by default, so only one can be open
    onShouldBeActiveChanged: {
        if (shouldBeActive)
            screenState.sidebar = false;
    }

    Connections {
        function onSidebarChanged(): void {
            if (root.screenState.sidebar)
                root.screenState.notifPopout = false;
        }

        target: root.screenState
    }

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: Tokens.padding.large
        anchors.margins: CUtils.clamp(anchors.leftMargin - Config.border.thickness, 0, anchors.leftMargin)
        anchors.bottomMargin: anchors.margins

        // Created up front so opening doesn't wait on building the notification list
        active: true

        sourceComponent: Content {
            // The content itself keeps its normal (unmirrored) layout
            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: true
            implicitWidth: Tokens.sizes.sidebar.width - content.anchors.leftMargin - content.anchors.margins

            shown: root.visible
            props: root.props
            screenState: root.screenState
        }
    }
}
