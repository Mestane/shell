pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// "Good night, {user}" - both the phrase and the icon change with the hour, sat between the
// avatar and the password field
StyledRect {
    id: root

    readonly property int hour: Time.hours
    readonly property string period: {
        if (root.hour >= 5 && root.hour < 12)
            return "morning";
        if (root.hour >= 12 && root.hour < 17)
            return "afternoon";
        if (root.hour >= 17 && root.hour < 21)
            return "evening";
        return "night";
    }
    readonly property string periodIcon: ({
            morning: "light_mode",
            afternoon: "partly_cloudy_day",
            evening: "partly_cloudy_night",
            night: "bedtime"
        })[root.period]
    readonly property string periodGreeting: ({
            morning: Tr.tr("Good morning"),
            afternoon: Tr.tr("Good afternoon"),
            evening: Tr.tr("Good evening"),
            night: Tr.tr("Good night")
        })[root.period]

    implicitWidth: row.implicitWidth + Tokens.padding.large * 2
    implicitHeight: row.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.full
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: root.periodIcon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            // TRANSLATORS: %1 = time-of-day greeting ("Good morning"), followed by the username in bold
            text: Tr.tr("%1,").arg(root.periodGreeting)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.medium
        }

        StyledText {
            text: SysInfo.user
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
        }
    }
}
