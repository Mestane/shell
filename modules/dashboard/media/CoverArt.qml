import QtQuick
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.images
import qs.services

// One piece of cover art for a track or a folder, filling whatever it is put in. The picture
// inside the audio file is looked for first, since it is the track's own; failing that, the
// image that sits beside the file. A folder's own image goes the other way round (fallbackFirst),
// because there the track picture is only a stand-in.
//
// Nothing is shown until the file has been looked at, rather than the fallback and then a swap,
// so a track never flashes another track's picture on its way to its own.
Item {
    id: root

    // A track whose embedded picture to look for; empty for art that is only ever an image file
    property string path
    // An image file to show when the track has no picture of its own
    property string fallback
    property bool fallbackFirst
    property string icon: "music_note"
    property font iconStyle: Tokens.font.icon.medium

    property bool known: true
    property string embedded

    readonly property string source: {
        if (!root.known)
            return "";
        if (root.fallbackFirst && root.fallback)
            return root.fallback;
        return root.embedded || root.fallback;
    }
    readonly property bool ready: root.source !== "" && image.status !== Image.Error

    function refresh(): void {
        if (root.path === "") {
            root.known = true;
            root.embedded = "";
            return;
        }

        if (MusicCovers.knows(root.path)) {
            root.known = true;
            root.embedded = MusicCovers.coverOf(root.path);
        } else {
            root.known = false;
            root.embedded = "";
            MusicCovers.want(root.path);
        }
    }

    onPathChanged: refresh()
    Component.onCompleted: refresh()

    Connections {
        function onCoversChanged(): void {
            if (!root.known)
                root.refresh();
        }

        target: MusicCovers
    }

    FadeImage {
        id: image

        anchors.fill: parent
        visible: root.ready
        source: root.source
    }

    MaterialIcon {
        anchors.centerIn: parent
        visible: !root.ready
        text: root.icon
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: root.iconStyle
    }
}
