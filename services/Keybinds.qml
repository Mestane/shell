pragma Singleton

import "../utils/keybinds.js" as Lua
import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// NOTE(fork): the keybinds of the Hyprland Lua config, for the Keybinds page in Nexus. The
// defaults are the `kb*` variables in hypr/variables.lua and the user's own choices are the same
// variables in caelestia/hypr-vars.lua, which is the only file this ever writes (after keeping a
// copy of it the first time). Hyprland is reloaded so a change takes effect straight away.
Singleton {
    id: root

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${Paths.home}/.config`
    readonly property string defaultsPath: `${root.configHome}/hypr/variables.lua`
    readonly property string overridesPath: `${Paths.config}/hypr-vars.lua`

    property string defaultsText
    property string overridesText

    // Every keybind in file order: { id, label, section, prefix, defaults, combos, overridden }
    readonly property var entries: {
        const overrides = {};
        for (const e of Lua.parse(root.overridesText))
            overrides[e.id] = e.combos;

        return Lua.parse(root.defaultsText).map(e => {
            const combos = overrides[e.id] ?? e.combos;
            // Bound under a modifier alone, then a number key: the modifiers are the setting
            const prefix = e.combos.length > 0 && e.combos.every(c => Lua.split(c).key === "");
            return {
                id: e.id,
                label: Lua.label(e.id),
                section: /^kb(GoToWs|MoveWinToWs)(Group)?$/.test(e.id) ? "Workspaces" : e.section,
                prefix,
                defaults: e.combos,
                combos,
                overridden: !Lua.sameCombos(combos, e.combos)
            };
        });
    }
    readonly property bool available: root.entries.length > 0

    // Arbitrary { combo, command } binds added from the settings page, on top of the fixed kb*
    // ids above - see the customBinds functions in keybinds.js for why they're parsed apart
    // from those. Pseudo-ids ("custom:0", "custom:1", ...) let them share the clash detection
    // below without needing a real id of their own; they're recomputed fresh each time, so
    // reordering or removing one is never stale.
    readonly property var customBinds: Lua.parseCustomBinds(root.overridesText)

    // { NORMALISED COMBO: [ids] } for the shortcuts two binds share, kb* ids and custom
    // pseudo-ids together so either kind can warn about clashing with the other
    readonly property var clashes: Lua.conflicts([...root.entries, ...root.customBinds.map((b, i) => ({
                    id: `custom:${i}`,
                    combos: [b.combo]
                }))])

    // Which other binds already use this shortcut, as display labels
    function usedBy(id: string, combo: string): list<string> {
        const ids = root.clashes[Lua.normalise(combo)] ?? [];
        return ids.filter(other => other !== id).map(other => other.startsWith("custom:") ? root.customBinds[Number(other.slice(7))]?.command ?? "" : Lua.label(other));
    }

    function addCustomBind(combo: string, command: string): void {
        root.write(Lua.withCustomBinds(root.overridesText, [...root.customBinds, {
                        combo,
                        command
                    }]));
    }

    function setCustomBind(index: int, combo: string, command: string): void {
        if (index < 0 || index >= root.customBinds.length)
            return;

        const next = [...root.customBinds];
        next[index] = {
            combo,
            command
        };
        root.write(Lua.withCustomBinds(root.overridesText, next));
    }

    function removeCustomBind(index: int): void {
        root.write(Lua.withCustomBinds(root.overridesText, root.customBinds.filter((_, i) => i !== index)));
    }

    function pretty(combo: string): string {
        return Lua.pretty(combo);
    }

    function split(combo: string): var {
        return Lua.split(combo);
    }

    function join(mods: var, key: string): string {
        return Lua.join(mods, key);
    }

    function keyName(qtName: string, typed: string): string {
        return Lua.keyName(qtName, typed);
    }

    // Saves the new shortcuts for one keybind. Going back to the defaults removes the override.
    function set(id: string, combos: var): void {
        const entry = root.entries.find(e => e.id === id);
        if (!entry)
            return;

        const cleaned = combos.filter(c => c !== "");
        root.write(Lua.edit(root.overridesText, id, Lua.sameCombos(cleaned, entry.defaults) ? null : cleaned));
    }

    function reset(id: string): void {
        root.write(Lua.edit(root.overridesText, id, null));
    }

    function write(text: string): void {
        if (text === root.overridesText)
            return;

        // The first change keeps the file as it was
        Quickshell.execDetached(["cp", "-n", root.overridesPath, `${root.overridesPath}.bak-keybinds`]);
        root.overridesText = text;
        overridesFile.setText(text);
        reloadTimer.restart();
    }

    Timer {
        id: reloadTimer

        interval: 600
        onTriggered: Quickshell.execDetached(["hyprctl", "reload"])
    }

    FileView {
        path: root.defaultsPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.defaultsText = text()
    }

    FileView {
        id: overridesFile

        path: root.overridesPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.overridesText = text()
        // No file yet: nothing is overridden
        onLoadFailed: root.overridesText = ""
    }
}
