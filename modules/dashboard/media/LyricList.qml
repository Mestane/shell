pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    // Funny binding hack to make lyrics update
    readonly property var _: {
        const p = Players.active;
        if (!p) {
            Lyrics.clearTrack();
            return;
        }

        // Read all of these up front so they stay binding dependencies even
        // when the guard below bails out early.
        const artist = p.trackArtist;
        const title = p.trackTitle;
        const album = p.trackAlbum;
        const length = p.length;

        // Players fill metadata progressively (see Players.qml), so both of
        // these are briefly empty while switching tracks. Passing that on
        // would send doLoad() down its "no track" branch, which drops the
        // lines and clears loading together - the pane flashed "No lyrics
        // found" for an instant before the new track's metadata landed. Wait
        // for something usable instead, the same way maybeToastNowPlaying()
        // waits before announcing a track.
        if (!title && !artist)
            return;

        Lyrics.setTrack(artist, title, album, length);
    }

    readonly property real fadeAmount: 0.1
    property list<string> lyricList: Lyrics.lyrics

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask

        Rectangle {
            id: mask

            layer.enabled: true
            visible: false
            implicitWidth: root.width
            implicitHeight: root.height

            gradient: Gradient {
                orientation: Gradient.Vertical

                GradientStop {
                    color: Qt.alpha("black", 0)
                    position: 0
                }
                GradientStop {
                    color: Qt.alpha("black", 1)
                    position: root.fadeAmount
                }
                GradientStop {
                    color: Qt.alpha("black", 1)
                    position: 1 - root.fadeAmount
                }
                GradientStop {
                    color: Qt.alpha("black", 0)
                    position: 1
                }
            }
        }
    }

    state: {
        if (Lyrics.hasLyrics)
            return "hasLyrics";
        if (Lyrics.loading)
            return "loading";
        return "noLyrics";
    }

    states: [
        State {
            name: "loading"

            PropertyChanges {
                loadingIndicator.opacity: 1
                lyrics.opacity: 0
                noLyrics.opacity: 0
            }
        },
        State {
            name: "hasLyrics"

            PropertyChanges {
                loadingIndicator.opacity: 0
                lyrics.opacity: 1
                noLyrics.opacity: 0
            }
        },
        State {
            name: "noLyrics"

            PropertyChanges {
                loadingIndicator.opacity: 0
                lyrics.opacity: 0
                noLyrics.opacity: 1
            }
        }
    ]

    transitions: [
        Transition {
            from: "loading"

            SequentialAnimation {
                Anim {
                    target: loadingIndicator
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
                Anim {
                    targets: [lyrics, noLyrics]
                    property: "opacity"
                    type: Anim.SlowEffects
                }
            }
        },
        Transition {
            from: "hasLyrics"

            SequentialAnimation {
                Anim {
                    target: lyrics
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
                Anim {
                    targets: [loadingIndicator, noLyrics]
                    property: "opacity"
                    type: Anim.SlowEffects
                }
            }
        },
        Transition {
            from: "noLyrics"

            SequentialAnimation {
                Anim {
                    target: noLyrics
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
                Anim {
                    targets: [loadingIndicator, lyrics]
                    property: "opacity"
                    type: Anim.SlowEffects
                }
            }
        }
    ]

    // The highlight follows Players.active.position, which is an interpolated
    // value - it only moves when something emits positionChanged(). The media
    // UI does that on a shared timer at mediaUpdateInterval (500ms by
    // default), which is coarse for lyrics: a line lands up to half a second
    // late, and lines closer together than one tick all arrive at once, so the
    // highlight sat still and then jumped several lines. Refresh faster while
    // lyrics are actually on screen. Position is interpolated locally, so this
    // re-evaluates bindings rather than adding any D-Bus traffic.
    Timer {
        running: root.visible && Lyrics.hasLyrics && (Players.active?.isPlaying ?? false)
        interval: 100
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    Loader {
        id: loadingIndicator

        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: 0

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.large

            StyledRect {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: shape.implicitSize + Tokens.padding.medium * 2
                implicitHeight: shape.implicitSize + Tokens.padding.medium * 2
                color: Colours.palette.m3primaryContainer
                radius: Tokens.rounding.full

                LoadingIndicator {
                    id: shape

                    anchors.centerIn: parent
                    implicitSize: Math.round(Tokens.sizes.dashboard.mediaSectionWidth / 5)
                    containsIcon: true // This removes the pentagon, which is not centered
                }
            }

            StyledText {
                text: qsTr("Loading lyrics...")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.title.medium
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: noLyrics

        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: 0

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "sentiment_sad"
                fontStyle: Tokens.font.icon.builders.large.scale(2).build()
                color: Colours.palette.m3outline
            }

            StyledText {
                text: qsTr("No lyrics found")
                color: Colours.palette.m3outline
                font: Tokens.font.title.medium
            }
        }
    }

    StyledListView {
        id: lyrics

        anchors.fill: parent
        anchors.topMargin: parent.height * root.fadeAmount / 2
        anchors.bottomMargin: parent.height * root.fadeAmount / 2

        displayMarginBeginning: anchors.topMargin
        displayMarginEnd: anchors.bottomMargin

        model: root.lyricList
        Component.onCompleted: {
            currentIndex = Qt.binding(() => {
                model; // Force update when lyrics change
                return Lyrics.indexForTime(Players.active?.position ?? 0);
            });
            positionViewAtIndex(currentIndex, ListView.Center);
        }
        onModelChanged: Qt.callLater(() => positionViewAtIndex(currentIndex, ListView.Center))

        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: Tokens.anim.durations.large
        highlightMoveVelocity: -1
        preferredHighlightBegin: (height - (currentItem?.implicitHeight ?? 0)) / 2
        preferredHighlightEnd: (height + (currentItem?.implicitHeight ?? 0)) / 2

        spacing: Tokens.spacing.small
        opacity: 0
        // Opacity alone doesn't stop input: at 0 this list still scrolled and
        // its delegates still took clicks (seeking to whichever line was
        // invisibly under the cursor) and showed a pointing-hand cursor,
        // including while "Loading lyrics..." or "No lyrics found" was showing
        // over it - the previous track's lines deliberately stay in the model
        // so the fade-out has something to fade. Disabling rather than hiding
        // keeps the list laid out, so delegate creation, positionViewAtIndex
        // and the highlight range all still behave while it's fading.
        enabled: opacity > 0

        delegate: StyledText {
            id: lyric

            required property string modelData
            required property int index
            property real effectScale: ListView.isCurrentItem ? 1 : 0

            anchors.left: lyrics.contentItem.left
            anchors.right: lyrics.contentItem.right

            text: modelData || ". . ."
            color: ListView.isCurrentItem ? Colours.palette.m3primary : mouse.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font: Tokens.font.body.medium
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            layer.enabled: effectScale > 0
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Colours.palette.m3primary
                shadowOpacity: 0.5 * lyric.effectScale
                shadowBlur: 0.6 * lyric.effectScale
                blur: 0.4 * lyric.effectScale
            }

            Behavior on effectScale {
                Anim {
                    type: Anim.SlowEffects
                }
            }

            MouseArea {
                id: mouse

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    const p = Players.active;
                    if (p)
                        p.position = Lyrics.timeForIndex(lyric.index);
                }
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
