import QtQuick
import Quickshell
import qs.components

Image {
    id: root

    property bool hadPrevious
    property bool fadingOut
    property bool preventInit
    // Lets a consumer swap the source without the crossfade, for when the new
    // URL carries the same content as the old (a different size of the same
    // cover, say) and animating it would just look like the image reloading.
    property bool animateSourceChanges: true
    property int fadeOutAnim: Anim.FastEffects
    property int fadeInAnim: Anim.DefaultEffects
    property int fadeInLargeAnim: Anim.StandardLarge

    function maybeStartInAnim(): void {
        if (!preventInit && !opacityInAnim.running && status === Image.Ready) {
            opacityInAnim.type = hadPrevious ? fadeInAnim : fadeInLargeAnim;
            opacityInAnim.start();
        }
    }

    asynchronous: true
    fillMode: Image.PreserveAspectCrop

    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(width * dpr, height * dpr);
    }

    retainWhileLoading: true
    opacity: 0

    onStatusChanged: maybeStartInAnim()
    onPreventInitChanged: maybeStartInAnim()

    Anim on opacity {
        id: opacityInAnim

        running: false
        to: 1
    }

    Behavior on source {
        enabled: root.animateSourceChanges

        SequentialAnimation {
            ScriptAction {
                script: opacityInAnim.stop()
            }
            PropertyAction {
                target: root
                property: "fadingOut"
                value: true
            }
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: root.fadeOutAnim
            }
            PropertyAction {
                target: root
                property: "fadingOut"
                value: false
            }
            PropertyAction {
                target: root
                property: "hadPrevious"
                value: root.source
            }
            PropertyAction {}
            ScriptAction {
                script: root.maybeStartInAnim()
            }
        }
    }
}
