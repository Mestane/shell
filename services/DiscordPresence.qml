pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.Models
import Caelestia.Services
import qs.services

// NOTE(fork): mirrors the in-shell local player to Discord rich presence. Only the local
// player is pushed - external MPRIS players are other apps, which can already do this
// themselves. The C++ side connects, handshakes and remembers the last activity, so this
// only has to say what is playing whenever it changes.
Singleton {
    id: root

    readonly property var cfg: GlobalConfig.services.discord
    // Nothing to talk to until an application ID has been filled in
    readonly property bool active: root.cfg.enabled && root.cfg.clientId.length > 0

    // Title/artist/album for the current track. TagLib is what the library itself reads,
    // and QtMultimedia's own metadata drops fields on some containers (m4a among them), so
    // the tags win and the media player is only a fallback.
    property var meta: ({})
    // Whether the tag read for the current file has produced anything. An untagged file
    // never will, which is why the scan is also checked before waiting on it.
    property bool tagsReady: false

    // The cover for the current track, resolved from MusicBrainz and the Cover Art Archive.
    // Discord cannot show a local file, so the artwork has to be a public URL it can fetch
    // itself.
    property string coverUrl: ""
    // Track the current coverUrl belongs to, so a late reply for the previous track is dropped
    property string lookupKey: ""
    // Resolved covers by track key; empty strings too, so a track the API genuinely does not
    // know is not asked about again
    property var coverCache: ({})
    // Failed attempts for the current track, so a lookup that keeps failing gives up
    property int coverAttempts: 0

    function refreshMeta(): void {
        const path = Music.currentFile;
        if (path)
            Music.ensureTags();

        const tags = path ? MusicTags.tagsFor(path) : ({});
        root.tagsReady = Object.keys(tags).length > 0;

        root.meta = {
            title: tags.title || Music.title || Music.fileName || "",
            artist: tags.artist || Music.artist || "",
            album: tags.album || Music.album || "",
            file: Music.fileName || ""
        };
    }

    // Fills {title}/{artist}/{album}/{file} in a format string. Unknown placeholders are
    // left alone so nothing the user typed disappears silently. Discord caps these lines at
    // 128 characters.
    function expand(template: string): string {
        return String(template ?? "").replace(/\{(\w+)\}/g, (match, key) => key in root.meta ? root.meta[key] : match).trim().slice(0, 128);
    }

    function trackKey(): string {
        return `${root.meta.artist}|${root.meta.album}|${root.meta.title}`;
    }

    // MusicBrainz wants an identifying User-Agent, and the Cover Art Archive sits behind the
    // same front door, so both lookups are asked for under the shell's own name
    function apiHeaders(): var {
        return {
            "User-Agent": `caelestia-shell/${CUtils.version}`
        };
    }

    function applyCover(key: string, url: string): void {
        root.coverCache[key] = url;

        // A reply that arrives after the track already changed is only cached, not shown
        if (key !== root.lookupKey)
            return;

        root.coverUrl = url;
        root.push();
    }

    // A request that failed (the API rate limits, and connections to it get reset) is not
    // the same as the API not knowing the track, so it is never cached as "no art". The
    // track is retried with a growing backoff instead, and a later play tries again.
    function coverFailed(key: string): void {
        if (key !== root.lookupKey)
            return;

        if (root.coverAttempts < 4) {
            root.coverAttempts++;
            retryTimer.interval = 5000 * root.coverAttempts;
            retryTimer.restart();
        }
    }

    function maybeLookupCover(): void {
        if (!root.active || !root.cfg.showCover || !Music.hasTrack)
            return;

        const key = root.trackKey();
        if (key === root.lookupKey)
            return;

        // Tags are read in the background. Searching before they land searches the wrong
        // track (or no track), so the first push waits for the read and tagsChanged comes
        // back around to do the lookup for real.
        if (!root.tagsReady && MusicTags.scanning)
            return;

        root.lookupKey = key;
        root.coverAttempts = 0;

        if (key in root.coverCache) {
            root.coverUrl = root.coverCache[key];
            return;
        }

        // Cleared while the lookup is in flight so a stale cover is never shown
        root.coverUrl = "";
        root.lookupCover(key, false);
    }

    function lookupCover(key: string, useSong: bool): void {
        const album = root.meta.album;
        const title = root.meta.title;

        // A track can carry several artists ("I Monster, Silveer Vanholme, ..."), which
        // makes an unmatchable search term, so the first one is what gets searched
        const primary = root.meta.artist.split(/[,;&]/)[0].trim();

        // Without an artist a title-only search matches the wrong release more often than
        // the right one, so a track with no artist tag is left with no cover
        if (!primary) {
            root.applyCover(key, "");
            return;
        }

        // The album is the search worth doing: a recording turns up on the live album and on
        // the compilation it was also put out on, so the bare title lands on the wrong
        // pressing. The title is the fallback for a track with no album tag, and for one the
        // album search matched nothing at all.
        const byAlbum = !!album && !useSong;
        const field = byAlbum ? "release" : "recording";
        const subject = byAlbum ? album : title;
        const query = encodeURIComponent(`${field}:"${subject}" AND artist:"${primary}"`);
        const url = `https://musicbrainz.org/ws/2/${field}?query=${query}&fmt=json&limit=5`;

        Requests.get(url, text => {
            let ids = [];
            try {
                const body = JSON.parse(text);
                let hits = (byAlbum ? body.releases : body.recordings) ?? [];

                // Hits are scored out of 100. The weak ones are other releases that share a
                // word with the query, and showing their cover is worse than showing none,
                // so they are dropped - unless that would leave nothing to look at.
                const close = hits.filter(hit => (hit.score ?? 0) >= 70);
                if (close.length)
                    hits = close;

                // A release hit already is the id the archive is keyed by; a recording hit
                // carries the releases it appears on
                ids = byAlbum ? hits.map(hit => hit.id) : hits.reduce((all, hit) => all.concat((hit.releases ?? []).map(release => release.id)), []);
            } catch (error) {
                console.warn(`[DiscordPresence] Unreadable MusicBrainz response: ${error}`);
                root.coverFailed(key);
                return;
            }

            ids = ids.filter(id => !!id).slice(0, 5);

            if (!ids.length && byAlbum) {
                root.lookupCover(key, true);
                return;
            }

            root.tryCover(key, ids);
        }, error => {
            console.warn(`[DiscordPresence] MusicBrainz lookup failed: ${error}`);
            root.coverFailed(key);
        }, root.apiHeaders());
    }

    // Asks the archive about each hit in turn, because the release MusicBrainz likes best is
    // not always one somebody has scanned a cover for.
    function tryCover(key: string, ids: var): void {
        if (key !== root.lookupKey)
            return;

        // Out of releases to ask about, so this track really has no art to show
        if (!ids.length) {
            root.applyCover(key, "");
            return;
        }

        const id = ids[0];
        Requests.get(`https://coverartarchive.org/release/${id}`, text => {
            let hasArt = false;
            try {
                hasArt = (JSON.parse(text).images ?? []).length > 0;
            } catch (error) {
                console.warn(`[DiscordPresence] Unreadable Cover Art Archive response: ${error}`);
                root.coverFailed(key);
                return;
            }

            if (!hasArt) {
                root.tryCover(key, ids.slice(1));
                return;
            }

            // The archive's front cover endpoint: https, a fixed 500px, and the hop from it
            // to the image itself is followed by whoever fetches the URL, which is Discord
            root.applyCover(key, `https://coverartarchive.org/release/${id}/front-500`);
        }, (error, meta) => {
            // 404 is the archive answering that this release has no cover, which is worth
            // moving on from; anything else means the request failed and is worth retrying.
            if (meta?.statusCode !== 404) {
                console.warn(`[DiscordPresence] Cover art lookup failed: ${error}`);
                root.coverFailed(key);
                return;
            }

            root.tryCover(key, ids.slice(1));
        }, root.apiHeaders());
    }

    function push(): void {
        if (!root.active || !Music.playing || !Music.hasTrack) {
            rpc.clearActivity();
            return;
        }

        // Refresh the tags first: the cover lookup and both lines are built from them
        root.refreshMeta();
        root.maybeLookupCover();

        const track = {
            details: root.expand(root.cfg.titleFormat) || root.meta.title || root.meta.file
        };

        // The second line is optional; an empty format just drops it
        const state = root.expand(root.cfg.descFormat);
        if (state)
            track.state = state;

        if (root.cfg.showCover && root.coverUrl)
            track.assets = {
                large_image: root.coverUrl,
                large_text: root.meta.album || root.meta.title || root.meta.file
            };

        // Discord counts up from the start timestamp on its own, so hand it where the track
        // actually began rather than pushing the position every tick. Both ends are sent even
        // at position 0, because the end is what gives Discord the elapsed/total pair and the
        // progress bar - a lone start only renders as a bare counter.
        if (root.cfg.showElapsed) {
            const start = Date.now() - Math.round(Music.position * 1000);
            track.timestamps = {
                start: start
            };
            if (Music.duration > 0)
                track.timestamps.end = start + Math.round(Music.duration * 1000);
        }

        // 2 is Discord's Listening activity type; omitted, Discord shows it as Playing
        if (root.cfg.listeningType)
            track.type = 2;

        // Which field Discord puts in the member-list status text: 0 = app name, 1 = the
        // artist line, 2 = the song line. This is what makes it read like YouTube Music's
        // "Listening to <song>" instead of naming the app.
        track.status_display_type = root.cfg.statusDisplay;

        // Optional override for the header itself. Empty leaves the application's name.
        const name = root.expand(root.cfg.nameFormat);
        if (name)
            track.name = name;

        rpc.setActivity(track);
    }

    DiscordRpc {
        id: rpc

        clientId: root.active ? root.cfg.clientId : ""
    }

    // Retries a cover lookup that failed, without having to wait for the next track change.
    // The interval grows with each attempt and is set where the failure is handled.
    Timer {
        id: retryTimer

        interval: 5000
        onTriggered: {
            if (root.active && root.cfg.showCover && Music.playing && root.lookupKey !== "")
                root.lookupCover(root.lookupKey, false);
        }
    }

    Connections {
        function onPlayingChanged(): void {
            root.push();
        }

        function onCurrentFileChanged(): void {
            root.push();
        }

        function onTitleChanged(): void {
            root.push();
        }

        function onArtistChanged(): void {
            root.push();
        }

        function onAlbumChanged(): void {
            root.push();
        }

        // The decoder does not know the length the instant playback starts, so the activity
        // is sent again once it is reported and the end timestamp can be filled in
        function onDurationChanged(): void {
            if (Music.duration > 0)
                root.push();
        }

        target: Music
    }

    // The tags are read in the background, so the artist/album (and with them the cover
    // lookup) can land after the file switches
    Connections {
        function onTagsChanged(): void {
            root.push();
        }

        target: MusicTags
    }

    Connections {
        function onEnabledChanged(): void {
            root.push();
        }

        function onClientIdChanged(): void {
            root.push();
        }

        function onTitleFormatChanged(): void {
            root.push();
        }

        function onDescFormatChanged(): void {
            root.push();
        }

        function onShowCoverChanged(): void {
            root.coverUrl = "";
            root.lookupKey = "";
            root.push();
        }

        function onShowElapsedChanged(): void {
            root.push();
        }

        function onListeningTypeChanged(): void {
            root.push();
        }

        function onStatusDisplayChanged(): void {
            root.push();
        }

        function onNameFormatChanged(): void {
            root.push();
        }

        target: root.cfg
    }
}
