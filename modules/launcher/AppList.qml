pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.config
import qs.modules.launcher.items
import qs.modules.launcher.services

StyledListView {
    id: root

    required property StyledTextField search
    required property DrawerVisibilities visibilities

    model: ScriptModel {
        id: model
        onValuesChanged: root.currentIndex = 0
    }

    spacing: Appearance.spacing.small
    orientation: Qt.Vertical
    // implicitHeight: (Config.launcher.sizes.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    implicitHeight: {
        if (state === "calc" || state === "timer")
            return currentItem?.implicitHeight ?? Config.launcher.sizes.itemHeight;
            if (state === "web")
                return Config.launcher.sizes.itemHeight
                    + (WebSearch.instantAnswer.length > 0 ? Config.launcher.sizes.itemHeight * 0.85 + Appearance.spacing.small : 0)
                    + (WebSearch.instantAbstract.length > 0 ? 120 + Appearance.spacing.small : 0)
                    + (WebSearch.searchResults.length > 0 ? WebSearch.searchResults.length * 90 + Appearance.spacing.small : 0);
        return (Config.launcher.sizes.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing;
    }


    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange
    highlightFollowsCurrentItem: false

    highlight: StyledRect {
        radius: Appearance.rounding.normal
        color: Colours.palette.m3onSurface
        opacity: 0.08
        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0
        Behavior on y {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }

    state: {
        const text = search.text;
        const prefix = Config.launcher.actionPrefix;
        if (text.startsWith(prefix)) {
            for (const action of ["calc", "scheme", "variant"])
                if (text.startsWith(`${prefix}${action} `))
                    return action;

            if (text.startsWith(`${prefix}search `))
                return "settings";

            if (text.startsWith(`${prefix}web `))
                return "web";

            if (text.startsWith(`${prefix}timer `))
                return "timer";

            return "actions";
        }
        return "apps";
    }

    onStateChanged: {
        if (state === "scheme" || state === "variant")
            Schemes.reload();
    }

    states: [
        State {
            name: "apps"
            PropertyChanges {
                model.values: Apps.search(search.text)
                root.delegate: appItem
            }
        },
        State {
            name: "actions"
            PropertyChanges {
                model.values: Actions.query(search.text)
                root.delegate: actionItem
            }
        },
        State {
            name: "calc"
            PropertyChanges {
                model.values: [0]
                root.delegate: calcItem
            }
        },
        State {
            name: "scheme"
            PropertyChanges {
                model.values: Schemes.query(search.text)
                root.delegate: schemeItem
            }
        },
        State {
            name: "variant"
            PropertyChanges {
                model.values: M3Variants.query(search.text)
                root.delegate: variantItem
            }
        },
        // State {
        //     name: "settings"
        //     PropertyChanges {
        //         model.values: SettingsSearch.query(search.text)
        //         root.delegate: settingsItem
        //     }
        // },
        State {
            name: "web"
            PropertyChanges {
                model.values: [0]
                root.delegate: webSearchItem
            }
        },
        State {
            name: "timer"
            PropertyChanges {
                model.values: [0]
                root.delegate: timerItem
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                Anim { target: root; property: "opacity"; from: 1; to: 0; duration: Appearance.anim.durations.small; easing.bezierCurve: Appearance.anim.curves.standardAccel }
                Anim { target: root; property: "scale"; from: 1; to: 0.9; duration: Appearance.anim.durations.small; easing.bezierCurve: Appearance.anim.curves.standardAccel }
            }
            PropertyAction { targets: [model, root]; properties: "values,delegate" }
            ParallelAnimation {
                Anim { target: root; property: "opacity"; from: 0; to: 1; duration: Appearance.anim.durations.small; easing.bezierCurve: Appearance.anim.curves.standardDecel }
                Anim { target: root; property: "scale"; from: 0.9; to: 1; duration: Appearance.anim.durations.small; easing.bezierCurve: Appearance.anim.curves.standardDecel }
            }
            PropertyAction { targets: [root.add, root.remove]; property: "enabled"; value: true }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar { flickable: root }

    add: Transition {
        enabled: !root.state
        Anim { properties: "opacity,scale"; from: 0; to: 1 }
    }
    remove: Transition {
        enabled: !root.state
        Anim { properties: "opacity,scale"; from: 1; to: 0 }
    }
    move: Transition {
        Anim { property: "y" }
        Anim { properties: "opacity,scale"; to: 1 }
    }
    addDisplaced: Transition {
        Anim { property: "y"; duration: Appearance.anim.durations.small }
        Anim { properties: "opacity,scale"; to: 1 }
    }
    displaced: Transition {
        Anim { property: "y" }
        Anim { properties: "opacity,scale"; to: 1 }
    }

    Component { id: appItem; AppItem { visibilities: root.visibilities } }
    Component { id: actionItem; ActionItem { list: root } }
    Component { id: calcItem; CalcItem { list: root } }
    Component { id: schemeItem; SchemeItem { list: root } }
    Component { id: variantItem; VariantItem { list: root } }
    // Component { id: settingsItem; SettingsItem { list: root } }
    Component { id: webSearchItem; WebSearchItem { list: root } }
    Component { id: timerItem; TimerItem { list: root } }
}

