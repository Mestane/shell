import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Notification fullscreen visibility, ordered to match config::NotifsFullscreen (On, Off)
    readonly property list<MenuItem> notifFullscreenItems: [
        MenuItem {
            text: Tr.trCtx("On", "show notifications over fullscreen apps")
            icon: "notifications"
        },
        MenuItem {
            text: Tr.trCtx("Off", "show notifications over fullscreen apps")
            icon: "notifications_off"
        }
    ]

    // Toast fullscreen visibility, mapped to GlobalConfig.utilities.toasts.fullscreen
    readonly property list<MenuItem> toastFullscreenItems: [
        MenuItem {
            text: Tr.trCtx("Off", "show toasts over fullscreen apps")
            icon: "notifications_off"
        },
        MenuItem {
            text: Tr.trCtx("Important", "show toasts over fullscreen apps: important ones only")
            icon: "priority_high"
        },
        MenuItem {
            text: Tr.trCtx("On", "show toasts over fullscreen apps")
            icon: "notifications"
        }
    ]
    readonly property list<string> toastFullscreenValues: ["off", "important", "all"]

    property string pendingSilencedApp: ""

    function addSilencedApp(): void {
        const app = root.pendingSilencedApp.trim();
        if (app === "" || GlobalConfig.notifs.silencedApps.includes(app))
            return;
        GlobalConfig.notifs.silencedApps = [...GlobalConfig.notifs.silencedApps, app];
        root.pendingSilencedApp = "";
    }

    function removeSilencedApp(index: int): void {
        const apps = [...GlobalConfig.notifs.silencedApps];
        apps.splice(index, 1);
        GlobalConfig.notifs.silencedApps = apps;
    }

    title: Tr.tr("Notifications")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Notifications
        SectionHeader {
            first: true
            text: Tr.tr("Notifications")
        }

        SelectRow {
            first: true
            label: Tr.tr("Show in fullscreen")
            subtext: Tr.tr("Whether notifications appear over fullscreen apps")
            menuItems: root.notifFullscreenItems
            active: root.notifFullscreenItems[GlobalConfig.notifs.fullscreen]
            onSelected: item => GlobalConfig.notifs.fullscreen = root.notifFullscreenItems.indexOf(item)
        }

        ToggleRow {
            text: Tr.tr("Expire automatically")
            subtext: Tr.tr("Dismiss notifications after their timeout")
            checked: GlobalConfig.notifs.expire
            onToggled: GlobalConfig.notifs.expire = checked
        }

        ToggleRow {
            text: Tr.tr("Keep every chat message")
            subtext: Tr.tr("Chat apps like Discord replace a chat's notification with each new message; keep the earlier ones too")
            checked: GlobalConfig.notifs.keepChatHistory
            onToggled: GlobalConfig.notifs.keepChatHistory = checked
        }

        ToggleRow {
            text: Tr.tr("Open expanded")
            subtext: Tr.tr("Show notifications expanded by default")
            checked: GlobalConfig.notifs.openExpanded
            onToggled: GlobalConfig.notifs.openExpanded = checked
        }

        StepperRow {
            label: Tr.tr("Default timeout")
            // TRANSLATORS: ms is the millisecond unit, leave it untranslated
            subtext: Tr.tr("Time before a notification dismisses (ms)")
            value: GlobalConfig.notifs.defaultExpireTimeout
            from: 1000
            to: 60000
            stepSize: 500
            onMoved: v => GlobalConfig.notifs.defaultExpireTimeout = Math.round(v)
        }

        StepperRow {
            last: true
            label: Tr.tr("Group preview count")
            subtext: Tr.tr("Notifications shown per group before collapsing")
            value: GlobalConfig.notifs.groupPreviewNum
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.notifs.groupPreviewNum = Math.round(v)
        }

        // Silenced apps
        SectionHeader {
            text: Tr.tr("Silenced apps")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.small
            text: Tr.tr("Notifications from these apps never pop up - they go straight to the notification centre, the same as every app does while do not disturb is on")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: GlobalConfig.notifs.silencedApps

            ConnectedRect {
                id: silencedAppRow

                required property string modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                implicitHeight: silencedAppContent.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: silencedAppContent

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "notifications_off"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: silencedAppRow.modelData
                        elide: Text.ElideRight
                    }

                    IconButton {
                        type: IconButton.Text
                        isRound: true
                        icon: "close"
                        inactiveOnColour: Colours.palette.m3error
                        font: Tokens.font.icon.medium
                        onClicked: root.removeSilencedApp(silencedAppRow.index)
                    }
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: GlobalConfig.notifs.silencedApps.length === 0
            last: true
            implicitHeight: addSilencedAppRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: addSilencedAppRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                StyledTextField {
                    Layout.fillWidth: true
                    text: root.pendingSilencedApp
                    placeholderText: Tr.tr("App name, e.g. spotify")
                    onTextEdited: root.pendingSilencedApp = text
                    Keys.onReturnPressed: root.addSilencedApp()
                }

                IconButton {
                    type: IconButton.Filled
                    isRound: true
                    icon: "add"
                    disabled: root.pendingSilencedApp.trim() === ""
                    font: Tokens.font.icon.medium
                    onClicked: root.addSilencedApp()
                }
            }
        }

        // Toasts
        SectionHeader {
            text: Tr.tr("Toasts")
        }

        SelectRow {
            first: true
            label: Tr.tr("Show in fullscreen")
            subtext: Tr.tr("Whether toasts appear over fullscreen apps")
            menuItems: root.toastFullscreenItems
            active: root.toastFullscreenItems[Math.max(0, root.toastFullscreenValues.indexOf(GlobalConfig.utilities.toasts.fullscreen))]
            onSelected: item => GlobalConfig.utilities.toasts.fullscreen = root.toastFullscreenValues[root.toastFullscreenItems.indexOf(item)]
        }

        StepperRow {
            last: true
            label: Tr.tr("Visible toasts")
            subtext: Tr.tr("Maximum number of toasts shown at once")
            value: GlobalConfig.utilities.maxToasts
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.utilities.maxToasts = Math.round(v)
        }

        // Toast events
        SectionHeader {
            text: Tr.tr("Toast events")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Charging changes")
            checked: GlobalConfig.utilities.toasts.chargingChanged
            onToggled: GlobalConfig.utilities.toasts.chargingChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Power profile settings applied")
            subtext: Tr.tr("Show what was applied whenever a profile's settings are applied")
            checked: GlobalConfig.utilities.toasts.lowPowerModeChanged
            onToggled: GlobalConfig.utilities.toasts.lowPowerModeChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Game mode changes")
            checked: GlobalConfig.utilities.toasts.gameModeChanged
            onToggled: GlobalConfig.utilities.toasts.gameModeChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Do not disturb changes")
            checked: GlobalConfig.utilities.toasts.dndChanged
            onToggled: GlobalConfig.utilities.toasts.dndChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Audio output changes")
            checked: GlobalConfig.utilities.toasts.audioOutputChanged
            onToggled: GlobalConfig.utilities.toasts.audioOutputChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Audio input changes")
            checked: GlobalConfig.utilities.toasts.audioInputChanged
            onToggled: GlobalConfig.utilities.toasts.audioInputChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Caps lock changes")
            checked: GlobalConfig.utilities.toasts.capsLockChanged
            onToggled: GlobalConfig.utilities.toasts.capsLockChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Num lock changes")
            checked: GlobalConfig.utilities.toasts.numLockChanged
            onToggled: GlobalConfig.utilities.toasts.numLockChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Keyboard layout changes")
            checked: GlobalConfig.utilities.toasts.kbLayoutChanged
            onToggled: GlobalConfig.utilities.toasts.kbLayoutChanged = checked
        }

        ToggleRow {
            text: Tr.tr("VPN changes")
            checked: GlobalConfig.utilities.toasts.vpnChanged
            onToggled: GlobalConfig.utilities.toasts.vpnChanged = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Repo update available")
            subtext: Tr.tr("New commit on cykler01/cykler-caelestia")
            checked: GlobalConfig.utilities.toasts.repoUpdateAvailable
            onToggled: GlobalConfig.utilities.toasts.repoUpdateAvailable = checked
        }
    }
}
