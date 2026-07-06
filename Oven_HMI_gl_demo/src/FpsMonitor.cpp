/**
 * @file FpsMonitor.cpp
 * @brief Implementation of the FPS monitor.
 * @author Sita Chan
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 * All rights reserved.
 */

#include "FpsMonitor.h"
#include <QDebug>

FpsMonitor::FpsMonitor(QQuickWindow *window, QObject *parent)
    : QObject(parent), m_frameCount(0), m_fps(0), m_window(window)
{
    if (m_window) {
        connect(m_window, &QQuickWindow::beforeRendering,
                this, &FpsMonitor::onBeforeRendering);
        m_timer.start();
    } else {
        qWarning() << "FpsMonitor: no valid QQuickWindow";
    }
}

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
