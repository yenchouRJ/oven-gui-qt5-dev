/**
 * @file FpsMonitor.cpp
 * @brief Implementation of the FPS monitor.
 * @details Tracks render callbacks and publishes frames-per-second updates.
 * @author Sita Chan
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 * All rights reserved.
 *
 * This source code is proprietary and confidential to Defond Electrical Industries Limited.
 * Unauthorized copying, modification, distribution, or use of this code, in whole or in part,
 * without prior written permission from Defond Electrical Industries Limited is strictly prohibited.
 */

#include "FpsMonitor.h"
#include <QDebug>

/**
 * @brief Constructs an FPS monitor for the supplied window.
 *
 * @param window Pointer to the QQuickWindow to monitor.
 * @param parent QObject parent (default = nullptr).
 */
FpsMonitor::FpsMonitor(QQuickWindow *window, QObject *parent)
    : QObject(parent), m_frameCount(0), m_fps(0), m_window(window)
{
    if (m_window) {
        connect(m_window, &QQuickWindow::beforeRendering, this, &FpsMonitor::onBeforeRendering);
        m_timer.start();
    } else {
        qWarning() << "FpsMonitor initialized without a valid QQuickWindow.";
    }
}

/**
 * @brief Handles the beforeRendering callback.
 *
 * @details Updates the FPS value once per second based on accumulated frames.
 */
void FpsMonitor::onBeforeRendering()
{
    m_frameCount++;
    if (m_timer.elapsed() >= 1000) {
        m_fps = m_frameCount;
        emit fpsChanged();
        m_frameCount = 0;
        m_timer.restart();
    }
}