pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.services

// Four-way swipe direction picker for a gesture: one of up/down/left/right active at a time
RowLayout {
    id: root

    required property string direction

    signal selected(direction: string)

    readonly property var directions: [
        {
            value: "up",
            icon: "arrow_upward"
        },
        {
            value: "down",
            icon: "arrow_downward"
        },
        {
            value: "left",
            icon: "arrow_back"
        },
        {
            value: "right",
            icon: "arrow_forward"
        }
    ]

    spacing: Tokens.spacing.extraSmall

    Repeater {
        model: root.directions

        IconButton {
            required property var modelData

            type: modelData.value === root.direction ? IconButton.Filled : IconButton.Tonal
            isRound: true
            icon: modelData.icon
            font: Tokens.font.icon.small
            onClicked: root.selected(modelData.value)
        }
    }
}
