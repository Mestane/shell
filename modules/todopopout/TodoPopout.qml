import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// The to-do list's own IPC target: `qs -c caelestia ipc call todo open|close|toggle`, or the
// `caelestia:todoPopout` global shortcut. The list itself is the sidebar's third tab (see
// modules/sidebar/Content.qml, modules/notifpopout/Content.qml) rather than a panel of its own,
// so this just points the shared sidebar/notifPopoutTab state at it.
Scope {
    id: root

    function setActive(open: bool): void {
        const state = ShellState.forActive();
        if (!state)
            return;

        if (open)
            state.notifPopoutTab = 2;
        state.sidebar = open;
    }

    function toggle(): void {
        const state = ShellState.forActive();
        if (state)
            root.setActive(!(state.sidebar && state.notifPopoutTab === 2));
    }

    IpcHandler {
        function open(): void {
            root.setActive(true);
        }

        function close(): void {
            root.setActive(false);
        }

        function toggle(): void {
            root.toggle();
        }

        target: "todo"
    }
}
