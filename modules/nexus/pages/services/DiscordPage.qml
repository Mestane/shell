import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    // Activity types, ordered to match root.activityValues. Discord numbers these itself, and
    // only some of them mean anything for a music player - 4 is the app-only custom status.
    readonly property list<MenuItem> activityItems: [
        MenuItem {
            text: Tr.tr("Playing")
        },
        MenuItem {
            text: Tr.tr("Listening")
        },
        MenuItem {
            text: Tr.tr("Streaming")
        },
        MenuItem {
            text: Tr.tr("Watching")
        },
        MenuItem {
            text: Tr.tr("Competing")
        }
    ]
    // Discord's own activity type numbers, which are not in the order they are listed in
    readonly property list<int> activityValues: [0, 2, 1, 3, 5]

    // What Discord puts in the member-list status text, ordered to match statusDisplay
    // (App name, Artist, Song)
    readonly property list<MenuItem> statusItems: [
        MenuItem {
            text: Tr.trCtx("App name", "discord status text")
        },
        MenuItem {
            text: Tr.trCtx("Artist", "discord status text")
        },
        MenuItem {
            text: Tr.trCtx("Song", "discord status text")
        }
    ]

    title: Tr.tr("Discord rich presence")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Presence
        SectionHeader {
            first: true
            text: Tr.tr("Presence")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Enabled")
            subtext: Tr.tr("Mirror the local player on your Discord profile")
            checked: GlobalConfig.services.discord.enabled
            onToggled: GlobalConfig.services.discord.enabled = checked
        }

        SelectRow {
            last: true
            label: Tr.tr("Activity type")
            subtext: Tr.tr("How Discord labels what's playing; streaming needs a stream URL, so it may show as playing")
            menuItems: root.activityItems
            active: root.activityItems[Math.max(0, root.activityValues.indexOf(GlobalConfig.services.discord.activityType))]
            onSelected: item => GlobalConfig.services.discord.activityType = root.activityValues[root.activityItems.indexOf(item)]
        }

        // Activity card
        SectionHeader {
            text: Tr.tr("Activity card")
        }

        TextFieldRow {
            first: true
            label: Tr.tr("Title line")
            subtext: Tr.tr("Placeholders: {title}, {artist}, {album}, {file}")
            value: GlobalConfig.services.discord.titleFormat
            placeholderText: "{title}"
            onEditingFinished: value => GlobalConfig.services.discord.titleFormat = value
        }

        TextFieldRow {
            label: Tr.tr("Description line")
            subtext: Tr.tr("Shown under the title; leave blank to hide it")
            value: GlobalConfig.services.discord.descFormat
            placeholderText: "{artist}"
            onEditingFinished: value => GlobalConfig.services.discord.descFormat = value
        }

        ToggleRow {
            text: Tr.tr("Show album art")
            subtext: Tr.tr("Look the cover up online by artist and album (via MusicBrainz)")
            checked: GlobalConfig.services.discord.showCover
            onToggled: GlobalConfig.services.discord.showCover = checked
        }

        ToggleRow {
            text: Tr.tr("Show elapsed time")
            subtext: Tr.tr("Let Discord count up from where the track started")
            checked: GlobalConfig.services.discord.showElapsed
            onToggled: GlobalConfig.services.discord.showElapsed = checked
        }

        SelectRow {
            last: true
            label: Tr.tr("Status text")
            subtext: Tr.tr("What shows beside your name in member lists")
            menuItems: root.statusItems
            active: root.statusItems[GlobalConfig.services.discord.statusDisplay] ?? root.statusItems[2]
            onSelected: item => GlobalConfig.services.discord.statusDisplay = root.statusItems.indexOf(item)
        }

        // Application
        SectionHeader {
            text: Tr.tr("Application")
        }

        TextFieldRow {
            first: true
            last: true
            label: Tr.tr("Application ID")
            subtext: Tr.tr("Optional - only to use your own Discord application")
            value: GlobalConfig.services.discord.clientId
            placeholderText: Tr.tr("Bundled Caelestia application")
            onEditingFinished: value => GlobalConfig.services.discord.clientId = value
        }
    }
}
