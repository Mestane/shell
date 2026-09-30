pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// NOTE(fork): custom wording and layout for the lock screen's time-of-day greeting (see
// modules/lock/center/Greeting.qml). A real Config property would need a plugin rebuild for
// what's otherwise a pure QML feature, so this is its own small JSON store instead, the same
// pattern services/AppToggles.qml and a few others already use.
Singleton {
    id: root

    readonly property string path: `${Paths.config}/lock-greeting.json`
    readonly property string defaultFormat: "{icon} {greeting}, {user}"

    property bool loaded
    property string morning
    property string afternoon
    property string evening
    property string night
    // What order the pieces below go in, and what's between them - literally what's typed,
    // with {icon}, {weather_icon}, {greeting} and {user} standing in for the pieces that
    // change. Blank keeps defaultFormat.
    property string format

    function textFor(period: string): string {
        return root[period] ?? "";
    }

    function set(period: string, text: string): void {
        root[period] = text;
        root.write();
    }

    function setFormat(text: string): void {
        root.format = text;
        root.write();
    }

    function write(): void {
        storage.setText(JSON.stringify({
            morning: root.morning,
            afternoon: root.afternoon,
            evening: root.evening,
            night: root.night,
            format: root.format
        }, null, 4) + "\n");
    }

    FileView {
        id: storage

        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.morning = data.morning ?? "";
                root.afternoon = data.afternoon ?? "";
                root.evening = data.evening ?? "";
                root.night = data.night ?? "";
                root.format = data.format ?? "";
            } catch (e) {
                // Unreadable: leave everything at its built-in default rather than crash
            }
            root.loaded = true;
        }
        onLoadFailed: err => {
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText("{}"));
        }
    }
}
