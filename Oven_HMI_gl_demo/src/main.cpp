/**
 * @file main.cpp
 * @brief Entry point for bread-gl-demo.
 *
 * Registers MeshView as a QML type, loads Main.qml, wires FpsMonitor.
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 */

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include "FpsMonitor.h"
#include "MeshView.h"

int main(int argc, char *argv[])
{
    // Request OpenGL ES 3.0 so VAOs are available natively.
    // Disable vsync so swap does not artificially cap FPS.
    QSurfaceFormat fmt = QSurfaceFormat::defaultFormat();
    fmt.setRenderableType(QSurfaceFormat::OpenGLES);
    fmt.setVersion(3, 0);
    fmt.setSwapInterval(0);
    QSurfaceFormat::setDefaultFormat(fmt);

    QGuiApplication app(argc, argv);

    // Register MeshView so QML can use: import BreadDemo 1.0; MeshView { ... }
    qmlRegisterType<MeshView>("BreadDemo", 1, 0, "MeshView");

    QQmlApplicationEngine engine;
    FpsMonitor *fpsMonitor = nullptr;

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [&](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                qWarning() << "bread-gl-demo: failed to create root QML object";
                QCoreApplication::exit(-1);
                return;
            }
            if (obj && url == objUrl) {
                QQuickWindow *win = qobject_cast<QQuickWindow *>(obj);
                if (win) {
                    fpsMonitor = new FpsMonitor(win, &engine);
                    engine.rootContext()->setContextProperty(
                        QStringLiteral("fpsMonitor"), fpsMonitor);
                }
            }
        }, Qt::QueuedConnection);

    engine.load(url);
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
