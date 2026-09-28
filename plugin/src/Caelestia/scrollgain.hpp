#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia {

// Scales continuous (trackpad/touchpad gesture) scroll deltas for every scrollable in the
// shell. Instantiated once from shell.qml; see scrollgain.cpp for why it exists.
class ScrollGain : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ScrollGain(QObject* parent = nullptr);

    // The multiplier applied to continuous scroll deltas. CAELESTIA_SCROLL_GAIN overrides the
    // default so the value can be tuned without rebuilding the shell.
    [[nodiscard]] static int configuredGain();

protected:
    bool eventFilter(QObject* watched, QEvent* event) override;

private:
    const int m_gain;
    bool m_scaling = false;
};

} // namespace caelestia
