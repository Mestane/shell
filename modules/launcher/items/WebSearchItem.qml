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

    // Timer {
    //     id: searchTimer
    //     interval: 600
    //     onTriggered: {
    //         if (root.query.length > 2 && WebSearch.searchEnabled)
    //             WebSearch.fetchResults(root.query, 0);
    //         else
    //             WebSearch.clearResults();
    //     }
    // }

    // onQueryChanged: {
    //     if (query.length > 2) searchTimer.restart();
    //     else WebSearch.clearResults();
    // }

    Connections {
        target: WebSearch
        function onSearchEnabledChanged(): void {
            if (WebSearch.searchEnabled && root.query.length > 2)
                WebSearch.fetchResults(root.query, 0);
            else
                WebSearch.clearResults();
        }
        function onCurrentEngineIndexChanged(): void {
            if (root.query.length > 2 && WebSearch.searchEnabled)
                WebSearch.fetchResults(root.query, 0);
        }
    }

    // function onClicked(): void {
    //     if (query.length === 0) return;
    //     if (isUrl) WebSearch.openUrl(query);
    //     else WebSearch.search(query);
    //     list.visibilities.launcher = false;
    // }
    //
    //
    function onClicked(): void {
        if (query.length === 0) return;
        if (isUrl) {
            WebSearch.openUrl(query);
            list.visibilities.launcher = false;
        } else {
            WebSearch.fetchResults(query, 0);
        }
    }

    implicitHeight: mainItem.implicitHeight
        + (resultsList.visible ? resultsList.implicitHeight + Appearance.spacing.small : 0)
        + (pagination.visible ? pagination.implicitHeight + Appearance.spacing.small : 0)
    anchors.left: parent?.left
    anchors.right: parent?.right

    // Main search item
    Item {
        id: mainItem
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: Config.launcher.sizes.itemHeight

        StateLayer {
            function onClicked(): void {
                if (root.isUrl) WebSearch.openUrl(root.query);
                else WebSearch.search(root.query);
                root.list.visibilities.launcher = false;
            }
            radius: Appearance.rounding.normal
        }
        //
        // StateLayer {
        //     function onClicked(): void {
        //         if (root.isUrl) {
        //             WebSearch.openUrl(root.query);
        //             root.list.visibilities.launcher = false;
        //         } else {
        //             WebSearch.fetchResults(root.query, 0);
        //         }
        //     }
        //     radius: Appearance.rounding.normal
        // }

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

            // Search toggle
            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: searchToggleIcon.implicitHeight + Appearance.padding.small * 2
                radius: Appearance.rounding.small
                color: WebSearch.searchEnabled
                    ? Colours.palette.m3primaryContainer
                    : Colours.layer(Colours.palette.m3surfaceContainer, 2)

                StateLayer {
                    function onClicked(): void {
                        Config.launcher.webSearch.searchEnabled = !WebSearch.searchEnabled;
                        Config.save();
                    }
                    radius: parent.radius
                }

                MaterialIcon {
                    id: searchToggleIcon
                    anchors.centerIn: parent
                    text: "travel_explore"
                    font.pointSize: Appearance.font.size.normal
                    color: WebSearch.searchEnabled
                        ? Colours.palette.m3onPrimaryContainer
                        : Colours.palette.m3onSurfaceVariant
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

    // Search results
    Item {
        id: resultsList
        anchors.top: mainItem.bottom
        anchors.topMargin: Appearance.spacing.small
        anchors.left: parent.left
        anchors.right: parent.right
        visible: WebSearch.searchResults.length > 0 && !root.isUrl
        implicitHeight: webResults.visible ? webResults.implicitHeight
                      : videoResults.visible ? videoResults.implicitHeight
                      : imageResults.implicitHeight

        // Web results
        Column {
            id: webResults
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.smaller / 2
            visible: WebSearch.currentEngineType === "web"

            Repeater {
                model: webResults.visible ? WebSearch.searchResults : []

                Item {
                    id: webItem
                    required property var modelData
                    required property int index
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    implicitHeight: webContent.implicitHeight + Appearance.padding.normal * 2

                    StateLayer {
                        function onClicked(): void {
                            Quickshell.execDetached(["xdg-open", webItem.modelData.url]);
                            root.list.visibilities.launcher = false;
                        }
                        radius: Appearance.rounding.normal
                    }

                    StyledRect {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)

                        ColumnLayout {
                            id: webContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Appearance.padding.larger
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.small
                                StyledText {
                                    text: webItem.modelData.title ?? ""
                                    font.pointSize: Appearance.font.size.normal
                                    font.weight: 500
                                    color: Colours.palette.m3primary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: webItem.modelData.engines?.[0] ?? ""
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3outline
                                }
                            }
                            StyledText {
                                text: webItem.modelData.url ?? ""
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3tertiary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            StyledText {
                                text: webItem.modelData.content ?? ""
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        // Video results (YouTube)
        Column {
            id: videoResults
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.smaller / 2
            visible: WebSearch.currentEngineType === "video"

            Repeater {
                model: videoResults.visible ? WebSearch.searchResults : []

                Item {
                    id: videoItem
                    required property var modelData
                    required property int index
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    implicitHeight: 80

                    StateLayer {
                        function onClicked(): void {
                            Quickshell.execDetached(["xdg-open", videoItem.modelData.url]);
                            root.list.visibilities.launcher = false;
                        }
                        radius: Appearance.rounding.normal
                    }

                    StyledRect {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.normal
                            spacing: Appearance.spacing.normal

                            StyledRect {
                                implicitWidth: 120
                                implicitHeight: 68
                                radius: Appearance.rounding.small
                                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: videoItem.modelData.thumbnail ?? ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "play_circle"
                                    font.pointSize: Appearance.font.size.extraLarge
                                    color: Qt.rgba(1, 1, 1, 0.8)
                                    visible: !videoItem.modelData.thumbnail
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Appearance.spacing.smaller

                                StyledText {
                                    text: videoItem.modelData.title ?? ""
                                    font.pointSize: Appearance.font.size.normal
                                    font.weight: 500
                                    color: Colours.palette.m3primary
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    text: videoItem.modelData.content ?? ""
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3outline
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }

        // Image results
        Flow {
            id: imageResults
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.smaller
            visible: WebSearch.currentEngineType === "images"

            Repeater {
                model: imageResults.visible ? WebSearch.searchResults : []

                StyledRect {
                    id: imageItem
                    required property var modelData
                    required property int index
                    implicitWidth: 100
                    implicitHeight: 100
                    radius: Appearance.rounding.small
                    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: imageItem.modelData.img_src ?? imageItem.modelData.thumbnail ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    StateLayer {
                      function onClicked(): void {
                          if (query.length === 0) return;
                          if (isUrl) WebSearch.openUrl(query);
                          else WebSearch.fetchResults(query, 0);
                      }
                        radius: parent.radius
                    }
                }
                //
                // StyledRect {
                //     id: imageItem
                //     required property var modelData
                //     required property int index
                //     implicitWidth: img.status === Image.Error ? 0 : 100
                //     implicitHeight: img.status === Image.Error ? 0 : 100
                //     radius: Appearance.rounding.small
                //     color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                //     clip: true
                //     visible: img.status !== Image.Error
                // 
                //     Image {
                //         id: img
                //         anchors.fill: parent
                //         source: imageItem.modelData.img_src ?? imageItem.modelData.thumbnail ?? ""
                //         fillMode: Image.PreserveAspectCrop
                //         asynchronous: true
                //         // onStatusChanged: if (status === Image.Error) source = "" // hide logs
                //     }
                //     //
                //     //
                //     //
                // 
                //     StateLayer {
                //         function onClicked(): void {
                //             Quickshell.execDetached(["xdg-open", imageItem.modelData.url]);
                //             root.list.visibilities.launcher = false;
                //         }
                //         radius: parent.radius
                //     }
                // }
                //
                //
            }
        }
    }

    // Pagination
    Row {
        id: pagination
        anchors.top: resultsList.bottom
        anchors.topMargin: Appearance.spacing.small
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Appearance.spacing.smaller
        visible: WebSearch.totalResults > 5 && !root.isUrl

        readonly property int perPage: WebSearch.currentEngineType === "images" ? 12 : 5
        readonly property int totalPages: Math.min(Math.ceil(WebSearch.totalResults / perPage), 10)

        Repeater {
            model: pagination.totalPages

            StyledRect {
                required property int index

                implicitWidth: implicitHeight
                implicitHeight: pageLabel.implicitHeight + Appearance.padding.small * 2
                radius: Appearance.rounding.small
                color: WebSearch.currentPage === index
                    ? Colours.palette.m3primaryContainer
                    : Colours.layer(Colours.palette.m3surfaceContainer, 2)

                StateLayer {
                    function onClicked(): void {
                        WebSearch.fetchResults(root.query, index);
                    }
                    radius: parent.radius
                }

                StyledText {
                    id: pageLabel
                    anchors.centerIn: parent
                    text: `${index + 1}`
                    font.pointSize: Appearance.font.size.small
                    color: WebSearch.currentPage === index
                        ? Colours.palette.m3onPrimaryContainer
                        : Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
