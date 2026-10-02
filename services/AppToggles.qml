pragma Singleton

import "../utils/appToggles.js" as Toggles
import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// NOTE(fork): the app-toggle mapping for the special-workspace keybinds (SUPER+D, SUPER+M, ...),
// for the Keybinds page in Nexus. The built-in apps (Discord/WhatsApp, Spotify/Feishin, btop,
// Todoist) are the default_config() table in ~/.config/hypr/utils/functions.lua; since that
// isn't in the flat shape keybinds.js already knows how to parse, its shape is mirrored as data
// in utils/appToggles.js instead (see the comment there - keep the two in sync by hand). The
// user's own choices are ~/.config/caelestia/cli.json's "toggles" key, merged over those
// defaults field by field exactly like functions.lua's own merge(), and the only thing this ever
// writes. Nothing here reloads Hyprland: the Lua side reads cli.json fresh on every keypress.
Singleton {
    id: root

    readonly property string path: `${Paths.config}/cli.json`

    property string text
    property bool loaded

    // The user's own overrides only, i.e. exactly what's on disk: { category: { appName: {...} } }
    readonly property var userToggles: {
        if (!root.loaded)
            return {};
        try {
            return JSON.parse(root.text || "{}").toggles ?? {};
        } catch (e) {
            return {};
        }
    }

    // Defaults merged with the user's overrides, field by field per app - what the keybind
    // actually opens right now: { category: { appName: { enable, match, command, move } } }
    readonly property var categories: Toggles.merged(root.userToggles)

    // Apps that only exist because the user added them (not in the defaults at all), so the
    // UI knows which ones can be fully removed rather than just disabled
    function isUserApp(category: string, appName: string): bool {
        return !(Toggles.defaults()[category]?.[appName]);
    }

    function classOf(match: var): string {
        return Toggles.classOf(match);
    }

    // The kb* id of a special-workspace keybind -> the app-toggle category it opens, or "" for
    // every other keybind. Kept here rather than in KeybindRow itself since AppToggles is the
    // thing that actually knows what a "category" is.
    function categoryFor(id: string): string {
        return ({
                kbCommunicationWs: "communication",
                kbMusicWs: "music",
                kbSystemMonitorWs: "sysmon",
                kbTodoWs: "todo"
            })[id] ?? "";
    }

    function setClass(category: string, appName: string, windowClass: string): void {
        root.setApp(category, appName, {
            match: [{
                    class: windowClass
                }]
        });
    }

    function setCommand(category: string, appName: string, command: string): void {
        root.setApp(category, appName, {
            command: Toggles.splitShellWords(command)
        });
    }

    function isSimpleMatch(match: var): bool {
        return Toggles.isSimpleMatch(match);
    }

    function commandText(command: var): string {
        return Toggles.joinShellWords(command ?? []);
    }

    // Merges these fields into one app's own override (creating it if this is the first change
    // to it), leaving every other app and field exactly as it was
    function setApp(category: string, appName: string, fields: var): void {
        const toggles = root.userToggles;
        toggles[category] = toggles[category] ?? {};
        toggles[category][appName] = Object.assign({}, toggles[category][appName] ?? {}, fields);
        root.write(toggles);
    }

    // A user-added app is removed outright; a default one has no id to actually delete (Lua's
    // merge() only ever adds fields onto the defaults, never removes an app from them), so this
    // is only offered for the former - disabling is what a default app's own switch is for
    function removeApp(category: string, appName: string): void {
        const toggles = root.userToggles;
        if (!toggles[category])
            return;

        delete toggles[category][appName];
        if (Object.keys(toggles[category]).length === 0)
            delete toggles[category];
        root.write(toggles);
    }

    // A brand new app, defaulting to the shape most of the built-in ones already use
    function addApp(category: string, appName: string, windowClass: string, command: string): void {
        root.setApp(category, appName, {
            enable: true,
            match: [{
                    class: windowClass
                }],
            command: Toggles.splitShellWords(command),
            move: true
        });
    }

    function write(toggles: var): void {
        let parsed = {};
        try {
            parsed = JSON.parse(root.text || "{}");
        } catch (e) {
            // Unreadable JSON: replacing it is the only sane option, same as functions.lua
            // falling back to defaults rather than crashing on it
        }
        parsed.toggles = toggles;
        root.text = JSON.stringify(parsed, null, 4) + "\n";
        storage.setText(root.text);
    }

    FileView {
        id: storage

        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.text = text();
            root.loaded = true;
        }
        onLoadFailed: err => {
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText("{}"));
        }
    }
}
