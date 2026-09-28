import Quickshell.Io
import qs.services

// Notification popout opened by a 4-finger swipe (see the Hyprland gestures). The panel itself is part of
// the drawers window (see Wrapper.qml); this is only its IPC entry point.
IpcHandler {
    function open(): void {
        const state = ShellState.forActive();
        if (state)
            state.notifPopout = true;
    }

    function close(): void {
        const state = ShellState.forActive();
        if (state)
            state.notifPopout = false;
    }

    function toggle(): void {
        const state = ShellState.forActive();
        if (state)
            state.notifPopout = !state.notifPopout;
    }

    target: "notifPopout"
}
