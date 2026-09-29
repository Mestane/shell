import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Overview")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.trCtx("Enabled", "toggle label")
            subtext: Tr.tr("A full-screen view of every workspace and its windows")
            checked: Config.overview.enabled
            onToggled: GlobalConfig.overview.enabled = checked
        }

        // Opening
        SectionHeader {
            text: Tr.tr("Opening")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Trackpad swipe")
            subtext: Tr.tr("Swipe up with four fingers to open it and down to close it")
            checked: GlobalConfig.overview.gestures
            onToggled: GlobalConfig.overview.gestures = checked
        }

        // A corner can be pointed at the overview from the Panels page, next to the other panels a
        // corner can open

        // Workspaces
        SectionHeader {
            text: Tr.tr("Workspaces")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Only workspaces in use")
            subtext: Tr.tr("List just the workspaces with windows, the focused one and the next free one, instead of every workspace in groups of ten")
            checked: GlobalConfig.overview.onlyInUse
            onToggled: GlobalConfig.overview.onlyInUse = checked
        }
    }
}
