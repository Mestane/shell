import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// A pill split into equal segments, one of them picked out by a highlight that slides between
// them rather than each segment lighting up on its own. The model is a list of
// { icon, text, badge } (all optional but one of icon and text); `compact` drops the text.
StyledRect {
    id: root

    property var model: []
    property int currentIndex
    property bool compact
    property real segmentHeight: 36
    // Where the highlight is, in segments: follows currentIndex through the animation below,
    // and is what anything that moves along with the bar should read
    property real position: currentIndex

    readonly property real segmentWidth: root.model.length > 0 ? (width - inset * 2) / root.model.length : 0
    readonly property real inset: 3

    signal activated(int index)

    implicitHeight: segmentHeight + inset * 2
    implicitWidth: compact ? root.model.length * segmentHeight * 1.4 + inset * 2 : 240
    radius: Tokens.rounding.full
    color: Colours.tPalette.m3surfaceContainerHigh

    Behavior on position {
        Anim {
            type: Anim.FastSpatial
        }
    }

    StyledRect {
        id: highlight

        x: root.inset + root.position * root.segmentWidth
        y: root.inset
        width: root.segmentWidth
        height: root.segmentHeight
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary
    }

    Repeater {
        model: root.model

        StyledRect {
            id: segment

            required property var modelData
            required property int index

            // How far the highlight is from covering this segment, 1 when it is right under it
            readonly property real cover: Math.max(0, 1 - Math.abs(root.position - index))
            readonly property color contentColour: Qt.tint(Colours.palette.m3onSurfaceVariant, Qt.alpha(Colours.palette.m3onPrimary, cover))

            x: root.inset + index * root.segmentWidth
            y: root.inset
            width: root.segmentWidth
            height: root.segmentHeight
            radius: Tokens.rounding.full
            color: "transparent"

            StateLayer {
                color: Colours.palette.m3onSurface
                radius: parent.radius
                // Only asks: whatever owns the bar moves currentIndex, so a binding on it survives
                onClicked: root.activated(segment.index)
            }

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: (segment.modelData.icon ?? "") !== ""
                    text: segment.modelData.icon ?? ""
                    color: segment.contentColour
                    fontStyle: Tokens.font.icon.medium
                    fill: segment.cover
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.compact && (segment.modelData.text ?? "") !== ""
                    text: segment.modelData.text ?? ""
                    color: segment.contentColour
                    font: Tokens.font.label.large
                }

                // A count on the segment, such as how much is queued
                StyledRect {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: (segment.modelData.badge ?? 0) > 0
                    implicitWidth: Math.max(badgeText.implicitWidth + Tokens.padding.small * 2, implicitHeight)
                    implicitHeight: badgeText.implicitHeight + 2
                    radius: Tokens.rounding.full
                    color: segment.cover > 0.5 ? Colours.palette.m3onPrimary : Colours.palette.m3primary

                    StyledText {
                        id: badgeText

                        anchors.centerIn: parent
                        text: segment.modelData.badge ?? ""
                        color: segment.cover > 0.5 ? Colours.palette.m3primary : Colours.palette.m3onPrimary
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }
}
