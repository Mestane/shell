pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

// Sleep and logout, always reachable under the password field rather than only through
// Resources.qml's hover-reveal session panel - the exact same commands, just a second,
// always-visible way to reach the two most common ones
RowLayout {
    id: root

    spacing: Tokens.spacing.large

    SessionIcon {
        icon: Config.session.icons.sleep
        command: Config.session.commands.sleep
    }

    SessionIcon {
        icon: Config.session.icons.logout
        command: Config.session.commands.logout
    }

    component SessionIcon: Item {
        id: button

        required property string icon
        required property list<string> command

        function exec(): void {
            if (!SessionManager.exec(button.command))
                Quickshell.execDetached(button.command);
        }

        implicitWidth: implicitHeight
        implicitHeight: mIcon.implicitHeight + Tokens.padding.medium * 2

        StateLayer {
            radius: button.height / 2
            onClicked: button.exec()
        }

        MaterialIcon {
            id: mIcon

            anchors.centerIn: parent
            text: button.icon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }
    }
}
