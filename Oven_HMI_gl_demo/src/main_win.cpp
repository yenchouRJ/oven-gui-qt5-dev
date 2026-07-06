/**
 * @file main_win.cpp
 * @brief Entry point for bread-gl-win (QOpenGLWindow, no Qt Quick).
 *
 * Experiment: bypass Qt Quick entirely to isolate whether the 4-FPS ceiling
 * is in Qt Quick's scene-graph or in Mesa llvmpipe / EGLFS swap.
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 */

#include <QGuiApplication>
#include <QSurfaceFormat>
#include "BreadWindow.h"

int main(int argc, char *argv[])
{
    // Request OpenGL ES 3.0 so VAOs are available natively.
    // Disable vsync — let us see the raw rendering speed.
    QSurfaceFormat fmt;
    fmt.setRenderableType(QSurfaceFormat::OpenGLES);
    fmt.setVersion(3, 0);
    fmt.setSwapInterval(0);
    QSurfaceFormat::setDefaultFormat(fmt);

    QGuiApplication app(argc, argv);

    BreadWindow win;
    win.setTitle(QStringLiteral("bread-gl-win (QOpenGLWindow, no Qt Quick)"));
    win.resize(1280, 480);
    win.show();

    return app.exec();
}
