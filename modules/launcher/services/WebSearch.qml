pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.utils

Singleton {
    id: root

    readonly property list<var> engines: Config.launcher.webSearch.engines

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

    // Suggestions
    property list<string> suggestions: []
    property string _lastSuggestionQuery: ""

    function fetchSuggestions(query: string): void {
        if (!query.trim() || query === _lastSuggestionQuery) return;
        _lastSuggestionQuery = query;
        suggestProc.command = ["bash", "-c",
            `curl -s 'https://duckduckgo.com/ac/?q=${encodeURIComponent(query)}&type=list'`
        ];
        suggestProc.running = true;
    }

    function clearSuggestions(): void {
        suggestions = [];
        _lastSuggestionQuery = "";
    }

    Process {
        id: suggestProc
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.suggestions = data[1] ?? [];
                } catch(e) {
                    root.suggestions = [];
                }
            }
        }
    }

    // SearXNG
    readonly property string searxngUrl: "http://localhost:8080"
    property list<var> searchResults: []
    property string _lastSearchQuery: ""

    function fetchResults(query: string): void {
        if (!query.trim() || query === _lastSearchQuery) return;
        _lastSearchQuery = query;
        searchResults = [];
        searxProc.command = ["bash", "-c",
            `curl -s '${root.searxngUrl}/search?q=${encodeURIComponent(query)}&format=json'`
        ];
        searxProc.running = true;
    }

    function clearResults(): void {
        searchResults = [];
        _lastSearchQuery = "";
    }

    Process {
        id: searxProc
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.searchResults = (data.results ?? []).slice(0, 5);
                } catch(e) {
                    root.searchResults = [];
                }
            }
        }
    }

    // Instant answers
    property string instantAnswer: ""
    property string instantAbstract: ""
    property string instantAbstractUrl: ""
    property string instantAbstractSource: ""
    property string _lastInstantQuery: ""

    function fetchInstant(query: string): void {
        if (!query.trim() || query === _lastInstantQuery) return;
        _lastInstantQuery = query;
        instantProc.command = ["bash", "-c",
            `curl -s 'https://api.duckduckgo.com/?q=${encodeURIComponent(query)}&format=json&no_html=1&skip_disambig=1'`
        ];
        instantProc.running = true;
    }

    function clearInstant(): void {
        instantAnswer = "";
        instantAbstract = "";
        instantAbstractUrl = "";
        instantAbstractSource = "";
        _lastInstantQuery = "";
    }

    Process {
        id: instantProc
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.instantAnswer = data.Answer ?? "";
                    root.instantAbstract = data.AbstractText ?? "";
                    root.instantAbstractUrl = data.AbstractURL ?? "";
                    root.instantAbstractSource = data.AbstractSource ?? "";
                } catch(e) {
                    root.clearInstant();
                }
            }
        }
    }

    function nextEngine(): void {
        currentEngineIndex = (currentEngineIndex + 1) % engines.length;
    }

    function prevEngine(): void {
        currentEngineIndex = (currentEngineIndex - 1 + engines.length) % engines.length;
    }
}
