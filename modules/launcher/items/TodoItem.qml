import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Like ActionItem, but a task's name can run to a sentence or two, so it wraps onto up to three
// lines (and only then elides) instead of being cut off after one. The row's own height follows
// how many lines that took, unlike every other launcher row.
Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Math.max(Tokens.sizes.launcher.itemHeight, inner.implicitHeight + Tokens.padding.small * 2)

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        id: inner

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        implicitHeight: Math.max(icon.implicitHeight, name.implicitHeight + desc.implicitHeight)

        MaterialIcon {
            id: icon

            anchors.top: parent.top
            text: root.modelData?.icon ?? ""
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
        }

        Item {
            anchors.left: icon.right
            anchors.right: parent.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.top: parent.top

            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name

                anchors.left: parent.left
                anchors.right: parent.right
                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            StyledText {
                id: desc

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: name.bottom
                text: root.modelData?.desc ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }
    }
}
