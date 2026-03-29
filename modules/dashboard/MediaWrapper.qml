import QtQuick

Item {
    property alias visibilities: media.visibilities
    readonly property alias needsKeyboard: media.needsKeyboard
    readonly property bool menuOpen: media.playerSelectorExpanded

    implicitWidth: media.implicitWidth
    implicitHeight: media.nonAnimHeight

    Media {
        id: media
    }
}
