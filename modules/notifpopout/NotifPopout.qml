import Quickshell.Io
import qs.services

// `qs -c caelestia ipc call notifPopout open|close|toggle` - kept as its own target for anyone
// already using it (the 4-finger swipe uses the same shortcuts), but notifications, the media
// library and the to-do list are tabs of the sidebar's own top card now (see
// modules/sidebar/Content.qml, modules/notifpopout/Content.qml), not a panel of their own, so
// this just points at the sidebar itself.
IpcHandler {
    function open(): void {
        const state = ShellState.forActive();
        if (state)
            state.sidebar = true;
    }

    function close(): void {
        const state = ShellState.forActive();
        if (state)
            state.sidebar = false;
    }

    function toggle(): void {
        const state = ShellState.forActive();
        if (state)
            state.sidebar = !state.sidebar;
    }

    target: "notifPopout"
}
