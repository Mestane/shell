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

    // property bool showHistory: true  ← bunu kaldır
    property bool showHistory: WebSearch.showHistory
    onShowHistoryChanged: WebSearch.showHistory = showHistory

    function onClicked(): void {
        if (query.length === 0) return;
        if (isUrl)
            WebSearch.openUrl(query);
        else
            WebSearch.search(query);
        list.visibilities.launcher = false;
    }

    // implicitHeight: mainItem.implicitHeight + (historyToggle.visible ? historyToggle.implicitHeight : 0) + (historyList.visible ? historyList.implicitHeight : 0)

    implicitHeight: {
        const h = WebSearch.history.length;
        return mainItem.implicitHeight
            + (historyToggle.visible ? historyToggle.implicitHeight : 0)
            + (historyList.visible ? historyList.implicitHeight + Appearance.spacing.small : 0);
    }

    anchors.left: parent?.left
    anchors.right: parent?.right

    // Main search/url item
    Item {
        id: mainItem
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: Config.launcher.sizes.itemHeight

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

            // Engine switcher
            Row {
                spacing: Appearance.spacing.smaller
                Layout.alignment: Qt.AlignVCenter
                visible: !root.isUrl

                // Prev engine
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

                // Engine name
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

                // Next engine
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

    // History toggle button
    Item {
       id: historyToggle
       anchors.top: mainItem.bottom
       anchors.left: parent.left
       anchors.right: parent.right
       implicitHeight: WebSearch.history.length > 0 ? Config.launcher.sizes.itemHeight * 0.6 : 0
       visible: WebSearch.history.length > 0
       clip: true

       Behavior on implicitHeight { Anim {} }

        StateLayer {
            function onClicked(): void { root.showHistory = !root.showHistory; }
            radius: Appearance.rounding.normal
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Appearance.padding.larger
            anchors.rightMargin: Appearance.padding.larger

            MaterialIcon {
                text: "history"
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3outline
            }
            StyledText {
                text: qsTr("Recent searches")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
                Layout.fillWidth: true
            }
            MaterialIcon {
                text: root.showHistory ? "expand_less" : "expand_more"
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3outline
                animate: true
            }
        }
    }


    // History list
    Column {
        id: historyList

        anchors.top: historyToggle.bottom
        anchors.topMargin: visible ? Appearance.spacing.small : 0
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Appearance.spacing.smaller

        readonly property list<string> filteredHistory: {
            const h = WebSearch.history;
            return WebSearch.getFilteredHistory(root.query);
        }

        visible: root.showHistory && filteredHistory.length > 0

        Repeater {
            model: historyList.filteredHistory

            Item {
                id: historyItem
                required property string modelData
                required property int index

                anchors.left: parent?.left
                anchors.right: parent?.right
                implicitHeight: Config.launcher.sizes.itemHeight * 0.8

                StateLayer {
                    function onClicked(): void {
                        if (WebSearch.isUrl(historyItem.modelData))
                            WebSearch.openUrl(historyItem.modelData);
                        else
                            WebSearch.search(historyItem.modelData);
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
                        text: "history"
                        font.pointSize: Appearance.font.size.large
                        color: Colours.palette.m3outline
                        Layout.alignment: Qt.AlignVCenter
                    }

                    StyledText {
                        text: historyItem.modelData
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Delete from history
                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: deleteIcon.implicitHeight + Appearance.padding.smaller * 2
                        radius: Appearance.rounding.small
                        color: "transparent"
                        opacity: deleteHover.containsMouse ? 1 : 0

                        MaterialIcon {
                            id: deleteIcon
                            anchors.centerIn: parent
                            text: "close"
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3outline
                        }

                        MouseArea {
                            id: deleteHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                const h = [...WebSearch.history];
                                h.splice(WebSearch.history.indexOf(historyItem.modelData), 1);
                                WebSearch.history = h;
                                WebSearch.saveHistory();
                            }
                        }

                        Behavior on opacity { Anim {} }
                    }
                }
            }
        }
    }
}
