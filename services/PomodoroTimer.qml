pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs.utils

Singleton {
    id: root

    // State
    property bool running: false
    property bool paused: false
    property int totalSeconds: 0
    property int remainingSeconds: 0
    property string label: ""

    readonly property int minutes: Math.floor(remainingSeconds / 60)
    readonly property int seconds: remainingSeconds % 60
    readonly property string display: `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
    readonly property real progress: totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0

    function start(mins: int, lbl: string): void {
        totalSeconds = mins * 60;
        remainingSeconds = mins * 60;
        label = lbl || qsTr("%1 min timer").arg(mins);
        running = true;
        paused = false;
        ticker.restart();
    }

    function pause(): void {
        if (!running) return;
        paused = !paused;
        if (paused) ticker.stop();
        else ticker.start();
    }

    function stop(): void {
        running = false;
        paused = false;
        ticker.stop();
        totalSeconds = 0;
        remainingSeconds = 0;
        label = "";
    }

    Timer {
        id: ticker
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.remainingSeconds <= 0) {
                root.running = false;
                root.paused = false;
                ticker.stop();
                Quickshell.execDetached([
                    "caelestia", "shell", "toaster",
                    "success", qsTr("Timer finished"), root.label, "timer"
                ]);
                return;
            }
            root.remainingSeconds--;
        }
    }
}
