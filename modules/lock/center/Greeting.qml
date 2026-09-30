pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// "{icon} Good night, {user}" by default, laid out from LockGreeting.format (or defaultFormat
// if that's blank) - see the Lock screen settings page. {icon}/{weather_icon} become the period's
// own icon and the current weather's; {greeting} and {user} become text, {user} in bold; anything
// else in the format is kept as literal text exactly where it's written, spaces included, so the
// format string is the only thing controlling what's shown, in what order, and how it's spaced.
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
    // A custom phrase from the Lock screen settings page wins if there is one; otherwise the
    // built-in wording for the period
    readonly property string periodGreeting: LockGreeting.textFor(root.period) || ({
            morning: Tr.tr("Good morning"),
            afternoon: Tr.tr("Good afternoon"),
            evening: Tr.tr("Good evening"),
            night: Tr.tr("Good night")
        })[root.period]

    readonly property string format: LockGreeting.format || LockGreeting.defaultFormat
    // The format split into { icon: glyph } / { text, bold } pieces in order, so mixed icon and
    // text tokens can sit in a row together in whatever order the format put them in
    readonly property var segments: {
        const out = [];
        const re = /\{(\w+)\}|([^{}]+)/g;
        let m;
        while ((m = re.exec(root.format)) !== null) {
            if (m[1] === "icon")
                out.push({
                        icon: root.periodIcon
                    });
            else if (m[1] === "weather_icon")
                out.push({
                        icon: Weather.icon
                    });
            else if (m[1] === "greeting")
                out.push({
                        text: root.periodGreeting
                    });
            else if (m[1] === "user")
                out.push({
                        text: SysInfo.user,
                        bold: true
                    });
            else if (m[1])
                out.push({}); // an unknown {token}: dropped rather than shown literally
            else
                out.push({
                        text: m[2]
                    });
        }
        return out;
    }

    implicitWidth: row.implicitWidth + Tokens.padding.large * 2
    implicitHeight: row.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.full
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.segments

            Segment {}
        }
    }

    component Segment: Item {
        id: seg

        required property var modelData

        implicitWidth: seg.modelData.icon !== undefined ? icon.implicitWidth : label.implicitWidth
        implicitHeight: seg.modelData.icon !== undefined ? icon.implicitHeight : label.implicitHeight

        MaterialIcon {
            id: icon

            visible: seg.modelData.icon !== undefined
            text: seg.modelData.icon ?? ""
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            id: label

            visible: seg.modelData.icon === undefined
            text: seg.modelData.text ?? ""
            color: Colours.palette.m3onSurfaceVariant
            font: seg.modelData.bold ? Tokens.font.body.builders.medium.weight(Font.DemiBold).build() : Tokens.font.body.medium
        }
    }
}
