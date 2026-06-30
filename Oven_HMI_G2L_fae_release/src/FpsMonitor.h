/**
 * @file FpsMonitor.h
 * @brief Simple FPS counter for a QQuickWindow.
 *
 * @details Measures the time between render cycles and emits the current frames‑per‑second
 * value via a Qt property.  Useful for performance debugging of the UI.
 *
 * @author  Sita Chan
 */

#ifndef FPSMONITOR_H
#define FPSMONITOR_H

#include <QObject>
#include <QElapsedTimer>
#include <QPointer>
#include <QQuickWindow>

/**
 * @brief Monitors and reports the rendering frame rate of a QQuickWindow.
 *
 * Connects to the window’s before‑render signal, counts frames over a one‑second interval,
 * and updates the @c fps property.
 */
class FpsMonitor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int fps READ fps NOTIFY fpsChanged)

public:
    /**
     * @brief Constructs an FPS monitor for the supplied window.
     * @param window Pointer to the QQuickWindow to monitor.
     * @param parent QObject parent (default = nullptr).
     */
    explicit FpsMonitor(QQuickWindow *window, QObject *parent = nullptr);

    /** @brief Returns the most recent FPS measurement. */
    int fps() const { return m_fps; }

signals:
    /** @brief Emitted whenever the FPS value changes. */
    void fpsChanged();

private slots:
    /** @brief Slot called just before each frame is rendered. */
    void onBeforeRendering();

private:
    QElapsedTimer    m_timer;      ///< Measures elapsed time for FPS calculation.
    int              m_frameCount; ///< Number of frames seen in the current interval.
    int              m_fps;        ///< Last computed frames‑per‑second.
    QPointer<QQuickWindow> m_window; ///< Monitored window (may be nullptr).
};

#endif // FPSMONITOR_H
