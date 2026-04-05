pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services
import qs.config
import qs.modules.launcher.services

Item {
    id: root

    required property var list

    readonly property string query: list.search.text.slice(`${Config.launcher.actionPrefix}web `.length)
    readonly property bool isUrl: WebSearch.isUrl(query)

    function onClicked(): void {
        if (query.length === 0) return;
        if (isUrl)
            WebSearch.openUrl(query);
        else
            WebSearch.search(query);
        list.visibilities.launcher = false;
    }

    implicitHeight: Config.launcher.sizes.itemHeight
    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        function onClicked(): void {
            if (root.isUrl)
                WebSearch.openUrl(root.query);
            else
                WebSearch.search(root.query);
            root.list.visibilities.launcher = false;
        }
        radius: Appearance.rounding.normal
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.padding.larger
        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: root.isUrl ? "link" : "search"
            font.pointSize: Appearance.font.size.extraLarge
            color: Colours.palette.m3primary
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: root.query.length > 0
                    ? (root.isUrl ? qsTr("Open URL") : qsTr("Search for \"%1\"").arg(root.query))
                    : qsTr("Type to search the web")
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            StyledText {
                text: root.isUrl ? root.query : WebSearch.currentEngine.name
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // New / Private window buttons
        Row {
            spacing: Appearance.spacing.smaller
            Layout.alignment: Qt.AlignVCenter
            visible: root.query.length > 0

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: newWinIcon.implicitHeight + Appearance.padding.small * 2
                radius: Appearance.rounding.small
                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                StateLayer {
                    function onClicked(): void {
                        if (root.isUrl) WebSearch.openUrlInNewWindow(root.query);
                        else WebSearch.searchInNewWindow(root.query);
                        root.list.visibilities.launcher = false;
                    }
                    radius: parent.radius
                }

                MaterialIcon {
                    id: newWinIcon
                    anchors.centerIn: parent
                    text: "open_in_new"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: privateWinIcon.implicitHeight + Appearance.padding.small * 2
                radius: Appearance.rounding.small
                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                StateLayer {
                    function onClicked(): void {
                        if (root.isUrl) WebSearch.openUrlInPrivateWindow(root.query);
                        else WebSearch.searchInPrivateWindow(root.query);
                        root.list.visibilities.launcher = false;
                    }
                    radius: parent.radius
                }

                MaterialIcon {
                    id: privateWinIcon
                    anchors.centerIn: parent
                    text: "privacy_tip"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        // Engine switcher
        Row {
            spacing: Appearance.spacing.smaller
            Layout.alignment: Qt.AlignVCenter
            visible: !root.isUrl

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: prevIcon.implicitHeight + Appearance.padding.small * 2
                radius: Appearance.rounding.small
                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                StateLayer {
                    function onClicked(): void { WebSearch.prevEngine(); }
                    radius: parent.radius
                }

                MaterialIcon {
                    id: prevIcon
                    anchors.centerIn: parent
                    text: "chevron_left"
                    font.pointSize: Appearance.font.size.normal
                }
            }

            StyledRect {
                implicitHeight: engineLabel.implicitHeight + Appearance.padding.small * 2
                implicitWidth: engineLabel.implicitWidth + Appearance.padding.normal * 2
                radius: Appearance.rounding.small
                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                StyledText {
                    id: engineLabel
                    anchors.centerIn: parent
                    text: WebSearch.currentEngine.name
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3primary
                }
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: nextIcon.implicitHeight + Appearance.padding.small * 2
                radius: Appearance.rounding.small
                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                StateLayer {
                    function onClicked(): void { WebSearch.nextEngine(); }
                    radius: parent.radius
                }

                MaterialIcon {
                    id: nextIcon
                    anchors.centerIn: parent
                    text: "chevron_right"
                    font.pointSize: Appearance.font.size.normal
                }
            }
        }
    }
}
