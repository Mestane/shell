#include "scrollgain.hpp"

#include <qcoreapplication.h>
#include <qevent.h>

namespace {

// A trackpad reports continuous scrolling as pixel deltas, and QQuickFlickable applies them
// literally: the content moves one pixel per pixel the compositor reports. Compositors keep
// those deltas small on purpose - Hyprland scales them by input:touchpad:scroll_factor, which
// has to stay low because every other client scales them again - while toolkits and browsers
// multiply them by a factor of their own. The shell taking them at face value is what makes a
// trackpad crawl over the panels while a mouse wheel, which reports angleDelta instead, feels
// right at the same setting. Scaling the deltas here fixes that for the shell alone: it has no
// effect on any other client, and the global touchpad factor is left where browsers like it.
//
// Only pixel deltas are touched. Discrete mouse wheels, the wheel steps handled by sliders and
// scrollbars, and touch scrolling all keep the distance they had.
constexpr int SCROLL_GAIN = 8;

constexpr auto GAIN_ENV = "CAELESTIA_SCROLL_GAIN";

} // namespace

namespace caelestia {

int ScrollGain::configuredGain() {
    bool ok = false;
    const int gain = qEnvironmentVariableIntValue(GAIN_ENV, &ok);
    return ok && gain > 0 ? gain : SCROLL_GAIN;
}

ScrollGain::ScrollGain(QObject* parent)
    : QObject(parent)
    , m_gain(configuredGain()) {
    if (auto* app = QCoreApplication::instance())
        app->installEventFilter(this);
}

bool ScrollGain::eventFilter(QObject* watched, QEvent* event) {
    // The scaled event is delivered through this same filter, so ignore it on the way back in.
    if (m_scaling || event->type() != QEvent::Wheel)
        return QObject::eventFilter(watched, event);

    const auto* wheel = static_cast<const QWheelEvent*>(event);
    const QPoint pixelDelta = wheel->pixelDelta();
    if (pixelDelta.isNull())
        return QObject::eventFilter(watched, event);

    QWheelEvent scaled(wheel->position(), wheel->globalPosition(), pixelDelta * m_gain, wheel->angleDelta(),
        wheel->buttons(), wheel->modifiers(), wheel->phase(), wheel->inverted(), wheel->source(),
        wheel->pointingDevice());

    m_scaling = true;
    QCoreApplication::sendEvent(watched, &scaled);
    m_scaling = false;

    return true;
}

} // namespace caelestia
