pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.modules.nexus.common
import qs.services

PageBase {
    id: root

    title: Tr.tr("Lock screen")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Greeting")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.small
            text: Tr.tr("Shown above the password field. Leave one blank to use its default wording - the username after it is always added on top.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        TextFieldRow {
            first: true
            label: Tr.tr("Morning")
            subtext: Tr.tr("05:00–11:59")
            value: LockGreeting.morning
            placeholderText: Tr.tr("Good morning")
            onEditingFinished: value => LockGreeting.set("morning", value)
        }

        TextFieldRow {
            label: Tr.tr("Afternoon")
            subtext: Tr.tr("12:00–16:59")
            value: LockGreeting.afternoon
            placeholderText: Tr.tr("Good afternoon")
            onEditingFinished: value => LockGreeting.set("afternoon", value)
        }

        TextFieldRow {
            label: Tr.tr("Evening")
            subtext: Tr.tr("17:00–20:59")
            value: LockGreeting.evening
            placeholderText: Tr.tr("Good evening")
            onEditingFinished: value => LockGreeting.set("evening", value)
        }

        TextFieldRow {
            last: true
            label: Tr.tr("Night")
            subtext: Tr.tr("21:00–04:59")
            value: LockGreeting.night
            placeholderText: Tr.tr("Good night")
            onEditingFinished: value => LockGreeting.set("night", value)
        }
    }
}
