pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.utils

Singleton {
    id: root

    property bool showHistory: true

    readonly property list<var> engines: [
        { name: "DuckDuckGo", url: "https://duckduckgo.com/?q=%1" },
        { name: "Google",     url: "https://www.google.com/search?q=%1" },
        { name: "Brave",      url: "https://search.brave.com/search?q=%1" },
        { name: "YouTube",    url: "https://www.youtube.com/results?search_query=%1" },
        { name: "GitHub",     url: "https://github.com/search?q=%1" },
    ]

    property int currentEngineIndex: 0
    readonly property var currentEngine: engines[currentEngineIndex]

    property list<string> history: []
    readonly property int maxHistory: 20
    readonly property string historyPath: `${Paths.state}/websearch_history.json`

    function search(query: string): void {
        if (!query.trim()) return;
        const url = currentEngine.url.replace("%1", encodeURIComponent(query));
        Quickshell.execDetached(["xdg-open", url]);
        addToHistory(query);
    }

    function openUrl(url: string): void {
        const fullUrl = url.startsWith("http") ? url : "https://" + url;
        Quickshell.execDetached(["xdg-open", fullUrl]);
        addToHistory(url);
    }

    function isUrl(text: string): bool {
        return /^(https?:\/\/)/.test(text) ||
               /^www\./.test(text) ||
               /^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(\/.*)?$/.test(text);
    }

    function addToHistory(query: string): void {
        const h = history.filter(item => item !== query);
        history = [query, ...h].slice(0, maxHistory);
        saveHistory();
    }

    function getFilteredHistory(query: string): list<string> {
        if (!query) return history.slice(0, 5);
        return history.filter(h => h.toLowerCase().includes(query.toLowerCase())).slice(0, 5);
    }

    function removeFromHistory(query: string): void {
        history = history.filter(h => h !== query);
        saveHistory();
    }

    function nextEngine(): void {
        currentEngineIndex = (currentEngineIndex + 1) % engines.length;
    }

    function prevEngine(): void {
        currentEngineIndex = (currentEngineIndex - 1 + engines.length) % engines.length;
    }

    function saveHistory(): void {
        saveProc.command = ["bash", "-c",
            `mkdir -p '${Paths.state}' && printf '%s' '${JSON.stringify(root.history).replace(/'/g, "'\\''")}' > '${root.historyPath}'`
        ];
        saveProc.running = true;
    }

    Process {
        id: saveProc
        command: []
    }

    FileView {
        id: historyReader
        path: root.historyPath
        onLoaded: {
            try {
                root.history = JSON.parse(historyReader.text()) ?? [];
            } catch(e) {
                root.history = [];
            }
        }
        onLoadFailed: root.history = []
    }

    Component.onCompleted: historyReader.reload()
}
