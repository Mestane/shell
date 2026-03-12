pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed

    property bool needsStart: false
    property bool needsRegion: false
    property bool needsStop: false
    property bool needsPause: false

    function start(extraArgs = []): void {
        needsStart = true;
        needsRegion = extraArgs && extraArgs.length > 0 && extraArgs[0] === "-r";
        checkProc.running = true;
    }

    function stop(): void {
        needsStop = true;
        checkProc.running = true;
    }

    function togglePause(): void {
        needsPause = true;
        checkProc.running = true;
    }

    PersistentProperties {
        id: props
        property bool running: false
        property bool paused: false
        property real elapsed: 0
        reloadableId: "recorder"
    }

    function startRecording(): void {
        const timestamp = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss");
        const home = Quickshell.env("HOME");
        const outputFile = `${home}/Videos/Recordings/recording-${timestamp}.mp4`;

        const shellCmd = root.needsRegion
            ? `gpu-screen-recorder -w region -region $(slurp -f '%wx%h+%x+%y') -f 144 -a "default_output|default_input" -o "${outputFile}"`
            : `gpu-screen-recorder -w screen -f 144 -a "default_output|default_input" -o "${outputFile}"`;

        console.log("Starting recording:", shellCmd);

        Quickshell.execDetached(["sh", "-c", shellCmd]);
        
        props.running = true;
        props.paused = false;
        props.elapsed = 0;
        root.needsStart = false;
        root.needsRegion = false;
    }

    Process {
        id: checkProc
        running: true
        command: ["pidof", "gpu-screen-recorder"]

        onExited: code => {
            props.running = code === 0;

            if (code === 0) {
                if (root.needsStop) {
                    Quickshell.execDetached(["killall", "-SIGINT", "gpu-screen-recorder"]);
                    props.running = false;
                    props.paused = false;
                    root.needsStop = false;
                } else if (root.needsPause) {
                    Quickshell.execDetached(["killall", "-SIGUSR2", "gpu-screen-recorder"]);
                    props.paused = !props.paused;
                    root.needsPause = false;
                }
            } else if (root.needsStart) {
                startRecording();
            }
        }
    }

    Connections {
        // enabled: props.running && !props.paused
        function onSecondsChanged(): void {
            props.elapsed++;
        }

        target: Time // qmllint disable incompatible-type
    }
}
