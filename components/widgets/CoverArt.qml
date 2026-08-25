pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services

Item {
    id: root

    readonly property alias shape: shape

    property bool hadPrevious
    property color fallbackColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

    // Slight glow to separate from bg
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: 1
        shadowColor: Colours.palette.m3outline
        shadowOpacity: 0.3
    }

    Behavior on fallbackColour {
        CAnim {}
    }

    Item {
        id: shapeWrapper

        anchors.fill: parent
        layer.enabled: true
        opacity: root.fallbackColour.a

        MaterialShape {
            id: shape

            implicitSize: root.width
            shape: MaterialShape.Cookie12Sided
            color: Qt.alpha(root.fallbackColour, 1)

            Anim on rotation {
                running: true
                paused: !Players.active?.isPlaying
                from: 360
                to: 0
                duration: 23500
                easing.type: Easing.Linear
                loops: Animation.Infinite
            }
        }
    }

    MaterialIcon {
        anchors.centerIn: parent

        grade: 200
        text: image.status === Image.Error ? "broken_image" : "art_track"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.size((parent.width * 0.35) || 1).build()
        opacity: image.status === Image.Null || image.status === Image.Error ? 1 : 0
        animate: true

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: image.status === Image.Loading ? 1 : 0

        sourceComponent: LoadingIndicator {
            implicitSize: root.width * 0.3
            color: Colours.palette.m3primaryContainer
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    FadeImage {
        id: image

        // Players fill metadata progressively (see Players.qml), so trackArtUrl
        // goes briefly empty between tracks, and some hand the cover out more
        // than once for a single track - YouTube Music does it for songs (a
        // first URL, then another) while videos only ever produce one, which is
        // why only songs flashed. FadeImage animates a full fade-out/in per
        // source change, so either of those turned one track change into two
        // crossfades: the cover appeared, then immediately reloaded.
        //
        // A blank is held briefly, so the next track's art usually replaces the
        // outgoing one directly; a blank that outlasts the delay is a genuine
        // "no art" and still clears. A second URL arriving for the track that's
        // already showing swaps without the crossfade - it's the same artwork,
        // so there's nothing to animate between.
        readonly property string artUrl: Players.getArtUrl(Players.active)
        // Keyed on the title alone: artist and album land later than the title
        // does, and including them would make this look like another track
        // change partway through the current one.
        readonly property string trackKey: Players.active?.trackTitle ?? ""
        property string settledArtUrl
        property string settledKey

        anchors.fill: parent

        source: settledArtUrl

        Component.onCompleted: {
            settledArtUrl = artUrl;
            settledKey = trackKey;
        }
        onArtUrlChanged: {
            if (!artUrl) {
                blankArtDelay.restart();
                return;
            }
            blankArtDelay.stop();
            animateSourceChanges = trackKey !== settledKey;
            settledKey = trackKey;
            settledArtUrl = artUrl;
        }

        layer.enabled: true
        layer.effect: Mask {
            maskSource: shapeWrapper
        }

        Timer {
            id: blankArtDelay

            interval: 1000
            onTriggered: image.settledArtUrl = ""
        }
    }
}
