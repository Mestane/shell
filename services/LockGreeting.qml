pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// NOTE(fork): custom wording for the lock screen's time-of-day greeting (see
// modules/lock/center/Greeting.qml). A real Config property would need a plugin rebuild for
// what's otherwise a pure QML feature, so this is its own small JSON store instead, the same
// pattern services/AppToggles.qml and a few others already use. Anything left blank keeps the
// built-in phrase; the username after it is never part of this - only the greeting itself.
Singleton {
    id: root

    readonly property string path: `${Paths.config}/lock-greeting.json`

    property bool loaded
    property string morning
    property string afternoon
    property string evening
    property string night

    function textFor(period: string): string {
        return root[period] ?? "";
    }

    function set(period: string, text: string): void {
        root[period] = text;
        root.write();
    }

    function write(): void {
        storage.setText(JSON.stringify({
            morning: root.morning,
            afternoon: root.afternoon,
            evening: root.evening,
            night: root.night
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
            } catch (e) {
                // Unreadable: leave every period at the built-in default rather than crash
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
