pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.utils

Singleton {
    id: root

    readonly property list<var> engines: Config.launcher.webSearch.engines
    property bool searchEnabled: Config.launcher.webSearch.searchEnabled
    property list<var> allSearchResults: []

    property int currentEngineIndex: 0
    readonly property var currentEngine: engines[currentEngineIndex]

    readonly property var browserCommands: ({
        "firefox":              { new: ["firefox", "--new-window"],          private: ["firefox", "--private-window"] },
        "firefox-esr":          { new: ["firefox-esr", "--new-window"],      private: ["firefox-esr", "--private-window"] },
        "chromium":             { new: ["chromium", "--new-window"],         private: ["chromium", "--incognito"] },
        "chromium-browser":     { new: ["chromium-browser", "--new-window"], private: ["chromium-browser", "--incognito"] },
        "google-chrome":        { new: ["google-chrome", "--new-window"],    private: ["google-chrome", "--incognito"] },
        "google-chrome-stable": { new: ["google-chrome-stable", "--new-window"], private: ["google-chrome-stable", "--incognito"] },
        "brave-browser":        { new: ["brave-browser", "--new-window"],    private: ["brave-browser", "--incognito"] },
        "microsoft-edge":       { new: ["microsoft-edge", "--new-window"],   private: ["microsoft-edge", "--inprivate"] },
        "opera":                { new: ["opera", "--new-window"],            private: ["opera", "--private"] },
        "vivaldi":              { new: ["vivaldi", "--new-window"],          private: ["vivaldi", "--incognito"] },
        "waterfox":             { new: ["waterfox", "--new-window"],         private: ["waterfox", "--private-window"] },
        "librewolf":            { new: ["librewolf", "--new-window"],        private: ["librewolf", "--private-window"] },
    })

    property string detectedBrowser: "firefox"

    Process {
        id: browserDetect
        command: ["xdg-settings", "get", "default-web-browser"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const b = text.trim().replace(".desktop", "");
                if (root.browserCommands[b])
                    root.detectedBrowser = b;
            }
        }
    }

    function getBrowserCmd(type: string): list<string> {
        const cmds = browserCommands[detectedBrowser];
        if (!cmds) return ["xdg-open"];
        return type === "private" ? cmds.private : cmds.new;
    }

    function isUrl(text: string): bool {
        return /^(https?:\/\/)/.test(text) ||
               /^www\./.test(text) ||
               /^localhost(:\d+)?(\/.*)?$/.test(text) ||
               /^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(\/.*)?$/.test(text);
    }

    function search(query: string): void {
        if (!query.trim()) return;
        const url = currentEngine.url.replace("%1", encodeURIComponent(query));
        Quickshell.execDetached(["xdg-open", url]);
    }

    function openUrl(url: string): void {
        const fullUrl = url.startsWith("http") ? url : "https://" + url;
        Quickshell.execDetached(["xdg-open", fullUrl]);
    }

    function searchInNewWindow(query: string): void {
        if (!query.trim()) return;
        const url = currentEngine.url.replace("%1", encodeURIComponent(query));
        Quickshell.execDetached([...getBrowserCmd("new"), url]);
    }

    function searchInPrivateWindow(query: string): void {
        if (!query.trim()) return;
        const url = currentEngine.url.replace("%1", encodeURIComponent(query));
        Quickshell.execDetached([...getBrowserCmd("private"), url]);
    }

    function openUrlInNewWindow(url: string): void {
        const fullUrl = url.startsWith("http") ? url : "https://" + url;
        Quickshell.execDetached([...getBrowserCmd("new"), fullUrl]);
    }

    function openUrlInPrivateWindow(url: string): void {
        const fullUrl = url.startsWith("http") ? url : "https://" + url;
        Quickshell.execDetached([...getBrowserCmd("private"), fullUrl]);
    }

    function nextEngine(): void {
        currentEngineIndex = (currentEngineIndex + 1) % engines.length;
    }

    function prevEngine(): void {
        currentEngineIndex = (currentEngineIndex - 1 + engines.length) % engines.length;
    }

    // SearXNG search
    readonly property string searxngUrl: "http://localhost:8080"
    property list<var> searchResults: []
    property int totalResults: 0
    property int currentPage: 0
    property string _lastSearchQuery: ""

    function fetchResults(query: string, page: int): void {
        if (!query.trim()) return;
        currentPage = page ?? 0;
        // Yeni query ise fetch et, aynıysa sadece sayfa değiştir
        if (query !== _lastSearchQuery) {
            _lastSearchQuery = query;
            allSearchResults = [];
            searchResults = [];
            searxProc.command = ["bash", "-c",
                `curl -s '${root.searxngUrl}/search?q=${encodeURIComponent(query)}&format=json'`
            ];
            searxProc.running = true;
        } else {
            // Sadece sayfa değiştir
            searchResults = allSearchResults.slice(currentPage * 5, (currentPage + 1) * 5);
        }
    }

    function clearResults(): void {
        searchResults = [];
        allSearchResults = [];
        totalResults = 0;
        currentPage = 0;
        _lastSearchQuery = "";
    }

    Process {
        id: searxProc
        command: []
        stdout: StdioCollector {
          // onStreamFinished: {
          //     try {
          //         const data = JSON.parse(text);
          //         const allResults = data.results ?? [];
          //         root.totalResults = allResults.length;
          //         root.searchResults = allResults.slice(
          //             root.currentPage * 5,
          //             (root.currentPage + 1) * 5
          //         );
          //     } catch(e) {
          //         root.searchResults = [];
          //         root.totalResults = 0;
          //     }
          // }
          //
          onStreamFinished: {
              try {
                  const data = JSON.parse(text);
                  root.allSearchResults = data.results ?? [];
                  root.totalResults = root.allSearchResults.length;
                  root.searchResults = root.allSearchResults.slice(0, 5);
              } catch(e) {
                  root.allSearchResults = [];
                  root.searchResults = [];
                  root.totalResults = 0;
              }
          }
        }
    }

    // Engine index persistence
    readonly property string engineIndexPath: `${Paths.state}/websearch_engine.txt`

    onCurrentEngineIndexChanged: {
        saveEngineProc.command = ["bash", "-c",
            `mkdir -p '${Paths.state}' && printf '%s' '${currentEngineIndex}' > '${root.engineIndexPath}'`
        ];
        saveEngineProc.running = true;
    }

    Process { id: saveEngineProc; command: [] }

    FileView {
        id: engineReader
        path: root.engineIndexPath
        onLoaded: {
            const idx = parseInt(engineReader.text());
            if (!isNaN(idx) && idx >= 0 && idx < root.engines.length)
                root.currentEngineIndex = idx;
        }
        onLoadFailed: {}
    }

    Component.onCompleted: engineReader.reload()
}
