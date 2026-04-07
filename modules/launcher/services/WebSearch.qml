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

    property int currentEngineIndex: 0
    readonly property var currentEngine: engines[currentEngineIndex]
    readonly property string currentEngineType: currentEngine?.type ?? "web"

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
        clearResults();
    }

    function prevEngine(): void {
        currentEngineIndex = (currentEngineIndex - 1 + engines.length) % engines.length;
        clearResults();
    }

    // SearXNG search
    readonly property string searxngUrl: "http://localhost:8080"
    property list<var> searchResults: []
    property list<var> allSearchResults: []
    property int totalResults: 0
    property int currentPage: 0
    property string _lastSearchQuery: ""

    function buildSearchUrl(query: string): string {
        const engine = root.currentEngine?.searxEngine ?? "";
        const type = root.currentEngineType;
        let params = `q=${encodeURIComponent(query)}&format=json`;
        if (type === "images") {
            params += "&categories=images";
        } else if (type === "video") {
            params += "&categories=videos";
            if (engine) params += `&engines=${engine}`;
        } else {
            if (engine) params += `&engines=${engine}`;
        }
        return `${root.searxngUrl}/search?${params}`;
    }


      property var _cache: ({})


      function fetchResults(query: string, page: int): void {
          if (!query.trim()) return;
          if (!root.searchEnabled) return;
          currentPage = page ?? 0;
      
          if (query !== _lastSearchQuery) {
              _lastSearchQuery = query;
      
              // Cache'de var mı?
              const cacheKey = `${query}__${root.currentEngineIndex}`;
              if (root._cache[cacheKey]) {
                  const perPage = root.currentEngineType === "images" ? 12 : 5;
                  root.allSearchResults = root._cache[cacheKey];
                  root.totalResults = root._cache[cacheKey].length;
                  root.searchResults = root._cache[cacheKey].slice(0, perPage);
                  return;
              }
      
              allSearchResults = [];
              searchResults = [];
              const pages = [1, 2, 3];
              let completed = 0;
              let combined = [];
      
              pages.forEach(pageno => {
                  const xhr = new XMLHttpRequest();
                  xhr.open("GET", root.buildSearchUrl(query) + `&pageno=${pageno}`);
                  xhr.onreadystatechange = () => {
                      if (xhr.readyState === XMLHttpRequest.DONE) {
                          try {
                              const data = JSON.parse(xhr.responseText);
                              combined = combined.concat(data.results ?? []);
                          } catch(e) {}
                          completed++;
                          if (completed === pages.length) {
                              const perPage = root.currentEngineType === "images" ? 12 : 5;
                              const filtered = root.currentEngineType === "images"
                                  ? combined.filter(r => {
                                      const src = r.img_src ?? r.thumbnail ?? "";
                                      return src.startsWith("http");
                                  })
                                  : combined;
                              // Cache'e kaydet
                              const newCache = Object.assign({}, root._cache);
                              newCache[cacheKey] = filtered;
                              root._cache = newCache;
                              root.allSearchResults = filtered;
                              root.totalResults = filtered.length;
                              root.searchResults = filtered.slice(0, perPage);
                          }
                      }
                  };
                  xhr.send();
              });
          } else {
              const perPage = root.currentEngineType === "images" ? 12 : 5;
              searchResults = allSearchResults.slice(currentPage * perPage, (currentPage + 1) * perPage);
          }
      }




      
      // function fetchResults(query: string, page: int): void {
      //     if (!query.trim()) return;
      //     if (!root.searchEnabled) return;
      //     currentPage = page ?? 0;
      // 
      //     const cacheKey = `${query}__${root.currentEngineIndex}`;
      // 
      //     if (query !== _lastSearchQuery) {
      //         _lastSearchQuery = query;
      // 
      //         // Cache'de var mı?
      //         if (root._cache[cacheKey]) {
      //             const perPage = root.currentEngineType === "images" ? 12 : 5;
      //             root.allSearchResults = root._cache[cacheKey];
      //             root.totalResults = root._cache[cacheKey].length;
      //             root.searchResults = root._cache[cacheKey].slice(currentPage * perPage, (currentPage + 1) * perPage);
      //             return;
      //         }
      // 
      //         allSearchResults = [];
      //         searchResults = [];
      //         const xhr = new XMLHttpRequest();
      //         xhr.open("GET", root.buildSearchUrl(query));
      //         xhr.onreadystatechange = () => {
      //             if (xhr.readyState === XMLHttpRequest.DONE) {
      //                 try {
      //                     const data = JSON.parse(xhr.responseText);
      //                     const perPage = root.currentEngineType === "images" ? 12 : 5;
      //                     const allResults = data.results ?? [];
      //                     const filtered = root.currentEngineType === "images"
      //                         ? allResults.filter(r => {
      //                             const src = r.img_src ?? r.thumbnail ?? "";
      //                             return src.startsWith("http");
      //                         })
      //                         : allResults;
      //                     // Cache'e kaydet
      //                     const newCache = Object.assign({}, root._cache);
      //                     newCache[cacheKey] = filtered;
      //                     root._cache = newCache;
      //                     root.allSearchResults = filtered;
      //                     root.totalResults = filtered.length;
      //                     root.searchResults = filtered.slice(0, perPage);
      //                 } catch(e) {
      //                     root.allSearchResults = [];
      //                     root.searchResults = [];
      //                     root.totalResults = 0;
      //                 }
      //             }
      //         };
      //         xhr.send();
      //     } else {
      //         const perPage = root.currentEngineType === "images" ? 12 : 5;
      //         searchResults = allSearchResults.slice(currentPage * perPage, (currentPage + 1) * perPage);
      //     }
      // }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// üsttekini kullaniyorum

    // function fetchResults(query: string, page: int): void {
    //     if (!query.trim()) return;
    //     currentPage = page ?? 0;
    //
    //     if (query !== _lastSearchQuery) {
    //         _lastSearchQuery = query;
    //         allSearchResults = [];
    //         searchResults = [];
    //         const xhr = new XMLHttpRequest();
    //         xhr.open("GET", root.buildSearchUrl(query));
    //         xhr.onreadystatechange = () => {
    //             if (xhr.readyState === XMLHttpRequest.DONE) {
    //                 try {
    //                     const data = JSON.parse(xhr.responseText);
    //                     const perPage = root.currentEngineType === "images" ? 12 : 5;
    //                     const blockedDomains = ["artic.edu", "flickr.com"];
    //                     // root.allSearchResults = data.results ?? [];
    //
    //                     root.allSearchResults = (data.results ?? []).filter(r => {
    //                         if (root.currentEngineType !== "images") return true;
    //                         const src = r.img_src ?? r.thumbnail ?? "";
    //                         if (!src.startsWith("http")) return false;
    //                         return !blockedDomains.some(d => src.includes(d));
    //                     });
    //                     root.totalResults = root.allSearchResults.length;
    //                     root.searchResults = root.allSearchResults.slice(0, perPage);
    //                 } catch(e) {
    //                     root.allSearchResults = [];
    //                     root.searchResults = [];
    //                     root.totalResults = 0;
    //                 }
    //             }
    //         };
    //         xhr.send();
    //     } else {
    //         const perPage = root.currentEngineType === "images" ? 12 : 5;
    //         searchResults = allSearchResults.slice(currentPage * perPage, (currentPage + 1) * perPage);
    //     }
    // }
    //
    //
    // function fetchResults(query: string, page: int): void {
    //       if (!query.trim()) return;
    //       currentPage = page ?? 0;
    //       if (query !== _lastSearchQuery) {
    //           _lastSearchQuery = query;
    //           allSearchResults = [];
    //           searchResults = [];
    //           const xhr = new XMLHttpRequest();
    //           xhr.open("GET", root.buildSearchUrl(query));
    //           xhr.onreadystatechange = () => {
    //               if (xhr.readyState === XMLHttpRequest.DONE) {
    //                   try {
    //                       const data = JSON.parse(xhr.responseText);
    //                       const perPage = root.currentEngineType === "images" ? 12 : 5;
    //                       const allResults = data.results ?? [];
    //                       const filtered = root.currentEngineType === "images"
    //                           ? allResults.filter(r => {
    //                               const src = r.img_src ?? r.thumbnail ?? "";
    //                               return src.startsWith("http");
    //                           })
    //                           : allResults;
    //                       root.allSearchResults = filtered;
    //                       root.totalResults = filtered.length;
    //                       root.searchResults = filtered.slice(0, perPage);
    //                   } catch(e) {
    //                       root.allSearchResults = [];
    //                       root.searchResults = [];
    //                       root.totalResults = 0;
    //                   }
    //               }
    //           };
    //           xhr.send();
    //       } else {
    //           const perPage = root.currentEngineType === "images" ? 12 : 5;
    //           searchResults = allSearchResults.slice(currentPage * perPage, (currentPage + 1) * perPage);
    //       }
    //   }
    //
    //
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // function fetchResults(query: string, page: int): void {
    //     if (!query.trim()) return;
    //     currentPage = page ?? 0;
    //     if (query !== _lastSearchQuery) {
    //         _lastSearchQuery = query;
    //         allSearchResults = [];
    //         searchResults = [];
    //         const xhr = new XMLHttpRequest();
    //         xhr.open("GET", root.buildSearchUrl(query));
    //         xhr.onreadystatechange = () => {
    //             if (xhr.readyState === XMLHttpRequest.DONE) {
    //                 try {
    //                     const data = JSON.parse(xhr.responseText);
    //                     const perPage = root.currentEngineType === "images" ? 12 : 5;
    //                     const allResults = data.results ?? [];
    //                     const filtered = root.currentEngineType === "images"
    //                         ? allResults.filter(r => {
    //                             const src = r.img_src ?? r.thumbnail ?? "";
    //                             return src.startsWith("http");
    //                         })
    //                         : allResults;
    //                     root.allSearchResults = filtered;
    //                     root.totalResults = filtered.length;
    //                     root.searchResults = filtered.slice(0, perPage);
    //                 } catch(e) {
    //                     root.allSearchResults = [];
    //                     root.searchResults = [];
    //                     root.totalResults = 0;
    //                 }
    //             }
    //         };
    //         xhr.send();
    //     } else {
    //         const perPage = root.currentEngineType === "images" ? 12 : 5;
    //         searchResults = allSearchResults.slice(currentPage * perPage, (currentPage + 1) * perPage);
    //     }
    // }
    //
    //
    //

    function clearResults(): void {
        searchResults = [];
        allSearchResults = [];
        totalResults = 0;
        currentPage = 0;
        _lastSearchQuery = "";
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
