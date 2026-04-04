import QtQuick
import qs.components
import qs.services
import qs.config

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Config.launcher.sizes.itemHeight
    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        function onClicked(): void {
            root.modelData?.onClicked(root.list);
        }
        radius: Appearance.rounding.normal
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.larger
        anchors.rightMargin: Appearance.padding.larger
        anchors.margins: Appearance.padding.smaller

        MaterialIcon {
            id: icon
            text: root.modelData?.icon ?? "settings"
            font.pointSize: Appearance.font.size.extraLarge
            color: Colours.palette.m3primary
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Appearance.spacing.normal
            anchors.verticalCenter: icon.verticalCenter
            implicitWidth: parent.width - icon.width
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name
                text: root.modelData?.name ?? ""
                font.pointSize: Appearance.font.size.normal
            }

            StyledText {
                id: desc
                text: root.modelData?.desc ? qsTr("Settings → %1").arg(root.modelData.desc) : ""
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
                width: root.width - icon.width - Appearance.rounding.normal * 2
                anchors.top: name.bottom
                font.capitalization: Font.Capitalize
            }
        }
    }
}
