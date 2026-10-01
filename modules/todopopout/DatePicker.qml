pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

// A calendar and a time, picked together: day by tapping a grid, hour/minute by two small steppers.
// Unlike the dashboard's Calendar this keeps its own month in view rather than a shared shell-wide
// one, so opening it never moves what the dashboard happens to be showing.
ColumnLayout {
    id: root

    // The date/time it opens on, or now if unset
    property date initial: new Date()
    // Live as the picker is used; read this on "Set" rather than waiting for a signal
    property date value: root.initial

    readonly property int viewMonth: root.value.getMonth()
    readonly property int viewYear: root.value.getFullYear()

    function setDay(day: date): void {
        const v = root.value;
        root.value = new Date(day.getFullYear(), day.getMonth(), day.getDate(), v.getHours(), v.getMinutes());
    }

    function setHour(h: int): void {
        const v = root.value;
        root.value = new Date(v.getFullYear(), v.getMonth(), v.getDate(), h, v.getMinutes());
    }

    function setMinute(m: int): void {
        const v = root.value;
        root.value = new Date(v.getFullYear(), v.getMonth(), v.getDate(), v.getHours(), m);
    }

    spacing: Tokens.spacing.small

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        IconButton {
            isRound: true
            icon: "chevron_left"
            type: IconButton.Text
            font: Tokens.font.icon.small
            onClicked: root.value = new Date(root.viewYear, root.viewMonth - 1, root.value.getDate(), root.value.getHours(), root.value.getMinutes())
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: grid.title
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        IconButton {
            isRound: true
            icon: "chevron_right"
            type: IconButton.Text
            font: Tokens.font.icon.small
            onClicked: root.value = new Date(root.viewYear, root.viewMonth + 1, root.value.getDate(), root.value.getHours(), root.value.getMinutes())
        }
    }

    DayOfWeekRow {
        Layout.fillWidth: true
        locale: grid.locale

        delegate: StyledText {
            required property var model

            horizontalAlignment: Text.AlignHCenter
            text: model.shortName
            font: Tokens.font.body.builders.small.weight(Font.Medium).build()
            color: Colours.palette.m3outline
        }
    }

    MonthGrid {
        id: grid

        Layout.fillWidth: true
        month: root.viewMonth
        year: root.viewYear
        spacing: 2
        locale: Qt.locale()

        delegate: Item {
            id: dayItem

            required property var model

            readonly property bool selected: model.day === root.value.getDate() && model.month === root.value.getMonth() && model.year === root.value.getFullYear()

            implicitWidth: implicitHeight
            implicitHeight: label.implicitHeight + Tokens.padding.small * 2

            StyledRect {
                anchors.fill: parent
                anchors.margins: 1
                radius: Tokens.rounding.full
                color: dayItem.selected ? Colours.palette.m3primary : "transparent"

                Behavior on color {
                    CAnim {}
                }
            }

            StateLayer {
                radius: height / 2
                color: dayItem.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                onClicked: root.setDay(dayItem.model.date)
            }

            StyledText {
                id: label

                anchors.centerIn: parent
                text: grid.locale.toString(dayItem.model.day)
                color: dayItem.selected ? Colours.palette.m3onPrimary : dayItem.model.month === grid.month ? Colours.palette.m3onSurface : Colours.palette.m3outline
                font: Tokens.font.body.small
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "schedule"
            color: Colours.palette.m3outline
            fontStyle: Tokens.font.icon.small
        }

        Item {
            Layout.fillWidth: true
        }

        StyledSpinBox {
            // Narrower than the default: this sits in a sidebar card alongside a full month
            // grid, which doesn't leave room for the default field width on both of these
            fieldWidth: 44
            from: 0
            to: 23
            value: root.value.getHours()
            onValueModified: root.setHour(value)
        }

        StyledText {
            text: ":"
            font: Tokens.font.title.small
        }

        StyledSpinBox {
            fieldWidth: 44
            from: 0
            to: 59
            stepSize: 5
            value: root.value.getMinutes()
            onValueModified: root.setMinute(value)
        }
    }
}
