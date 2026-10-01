import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Lyrics backends, ordered to match config::LyricsBackend (Auto, Local, LRCLIB, NetEase)
    readonly property list<MenuItem> lyricsItems: [
        MenuItem {
            text: Tr.trCtx("Auto", "lyrics backend")
        },
        MenuItem {
            text: Tr.trCtx("Local", "lyrics backend")
        },
        MenuItem {
            text: "LRCLIB"
        },
        MenuItem {
            text: "NetEase"
        }
    ]

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

    // GPU types, ordered to match config::GpuType (Auto, Nvidia, Generic, None)
    readonly property list<MenuItem> gpuItems: [
        MenuItem {
            text: Tr.trCtx("Auto", "gpu type")
        },
        MenuItem {
            text: "NVIDIA"
        },
        MenuItem {
            text: Tr.trCtx("Generic", "gpu type")
        },
        MenuItem {
            text: Tr.trCtx("None", "gpu type")
        }
    ]

    title: Tr.tr("Services")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Detected running players, used as default-player options
        Variants {
            id: playerVariants

            model: [...new Set(Players.list.map(p => Players.getIdentity(p)).filter(id => id))]

            MenuItem {
                required property string modelData

                text: modelData
                icon: modelData === GlobalConfig.services.defaultPlayer ? "check" : ""
                activeIcon: "music_note"
            }
        }

        // Notifications
        SectionHeader {
            first: true
            text: Tr.tr("Notifications")
        }

        NavRow {
            first: true
            last: true
            icon: "notifications"
            text: Tr.tr("Notifications")
            subtext: Tr.tr("Notifications, toasts, timeouts")
            onClicked: root.nState.openSubPage(1)
        }

        // Polling
        SectionHeader {
            text: Tr.tr("Polling")
        }

        StepperRow {
            first: true
            label: Tr.tr("Media refresh")
            // TRANSLATORS: ms is the millisecond unit, leave it untranslated
            subtext: Tr.tr("How often the media position updates (ms)")
            value: GlobalConfig.dashboard.mediaUpdateInterval
            from: 100
            to: 2000
            stepSize: 50
            onMoved: v => GlobalConfig.dashboard.mediaUpdateInterval = v
        }

        StepperRow {
            label: Tr.tr("System stats refresh")
            // TRANSLATORS: CPU and GPU are hardware abbreviations, leave them untranslated
            subtext: Tr.tr("CPU, memory and GPU update interval (seconds)")
            value: GlobalConfig.dashboard.resourceUpdateInterval / 1000
            from: 0.5
            to: 10
            stepSize: 0.5
            onMoved: v => GlobalConfig.dashboard.resourceUpdateInterval = Math.round(v * 1000)
        }

        StepperRow {
            last: true
            label: Tr.tr("Wi-Fi rescan")
            subtext: Tr.tr("How often available networks are rescanned (seconds)")
            value: GlobalConfig.nexus.networkRescanInterval / 1000
            from: 5
            to: 120
            stepSize: 5
            onMoved: v => GlobalConfig.nexus.networkRescanInterval = Math.round(v * 1000)
        }

        // Media & lyrics
        SectionHeader {
            text: Tr.tr("Media & lyrics")
        }

        SelectRow {
            first: true
            label: Tr.tr("Lyrics backend")
            subtext: Tr.tr("Source used to fetch synced lyrics")
            menuItems: root.lyricsItems
            active: root.lyricsItems[Lyrics.preferredBackend] ?? root.lyricsItems[0]
            onSelected: item => Lyrics.preferredBackend = root.lyricsItems.indexOf(item)
        }

        SelectRow {
            last: true
            label: Tr.tr("Default player")
            subtext: Tr.tr("Preferred media player when several are open")
            menuItems: playerVariants.instances
            active: menuItems.find(i => i.text === GlobalConfig.services.defaultPlayer) ?? null
            fallbackIcon: "music_note"
            fallbackText: GlobalConfig.services.defaultPlayer || Tr.trCtx("Auto", "default media player")
            onSelected: item => GlobalConfig.services.defaultPlayer = item.text
        }

        // Input increments
        SectionHeader {
            text: Tr.tr("Input increments")
        }

        StepperRow {
            first: true
            label: Tr.tr("Volume step")
            subtext: Tr.tr("Amount the volume changes per scroll (%)")
            value: Math.round(GlobalConfig.services.audioIncrement * 100)
            from: 1
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.services.audioIncrement = v / 100
        }

        StepperRow {
            label: Tr.tr("Brightness step")
            subtext: Tr.tr("Amount the brightness changes per scroll (%)")
            value: Math.round(GlobalConfig.services.brightnessIncrement * 100)
            from: 1
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.services.brightnessIncrement = v / 100
        }

        StepperRow {
            last: true
            label: Tr.tr("Max volume")
            subtext: Tr.tr("Upper limit for output volume (%)")
            value: Math.round(GlobalConfig.services.maxVolume * 100)
            from: 50
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.services.maxVolume = v / 100
        }

        // Service tuning
        SectionHeader {
            text: Tr.tr("Service tuning")
        }

        StepperRow {
            first: true
            // TRANSLATORS: bars of a spectrum analyser, not the taskbar
            label: Tr.tr("Visualiser bars")
            subtext: Tr.tr("Number of bars in the audio visualisers")
            value: GlobalConfig.services.visualiserBars
            from: 10
            to: 120
            stepSize: 2
            onMoved: v => GlobalConfig.services.visualiserBars = v
        }

        ToggleRow {
            text: Tr.tr("Smart colour scheme")
            subtext: Tr.tr("Derive theme mode and variant from the wallpaper")
            checked: GlobalConfig.services.smartScheme
            onToggled: GlobalConfig.services.smartScheme = checked
        }

        SelectRow {
            last: true
            label: Tr.tr("GPU")
            subtext: Gpu.name ? Tr.tr("Monitoring: %1").arg(Gpu.name) : Tr.tr("Override for GPU type")
            menuOnTop: true
            menuItems: root.gpuItems
            active: root.gpuItems[GlobalConfig.services.gpuType]
            onSelected: item => GlobalConfig.services.gpuType = root.gpuItems.indexOf(item)
        }

        // Discord rich presence
        SectionHeader {
            text: Tr.tr("Discord rich presence")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Show what's playing")
            subtext: Tr.tr("Mirror the local player on your Discord profile")
            checked: GlobalConfig.services.discord.enabled
            onToggled: GlobalConfig.services.discord.enabled = checked
        }

        TextFieldRow {
            label: Tr.tr("Application ID")
            subtext: Tr.tr("Optional - only to use your own Discord application")
            value: GlobalConfig.services.discord.clientId
            placeholderText: Tr.tr("Bundled Caelestia application")
            onEditingFinished: value => GlobalConfig.services.discord.clientId = value
        }

        TextFieldRow {
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
            subtext: Tr.tr("Look the cover up online by artist and album (via Apple)")
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
            label: Tr.tr("Status text")
            subtext: Tr.tr("What shows beside your name in member lists")
            menuItems: root.statusItems
            active: root.statusItems[GlobalConfig.services.discord.statusDisplay] ?? root.statusItems[2]
            onSelected: item => GlobalConfig.services.discord.statusDisplay = root.statusItems.indexOf(item)
        }

        TextFieldRow {
            label: Tr.tr("Header text")
            subtext: Tr.tr("Blank uses the app name; same placeholders as above")
            value: GlobalConfig.services.discord.nameFormat
            placeholderText: Tr.tr("App name")
            onEditingFinished: value => GlobalConfig.services.discord.nameFormat = value
        }

        ToggleRow {
            last: true
            text: Tr.tr("Show as listening")
            subtext: Tr.tr("Use the Listening status instead of Playing")
            checked: GlobalConfig.services.discord.listeningType
            onToggled: GlobalConfig.services.discord.listeningType = checked
        }
    }
}
