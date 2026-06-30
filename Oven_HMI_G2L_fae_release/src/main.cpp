/**
 * @file main.cpp
 * @brief Application entry point for the Oven HMI GUI.
 * @details Initializes Qt, exposes backend helpers to QML, and loads Main.qml.
 * @author Sita  Chan
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 * All rights reserved.
 *
 * This source code is proprietary and confidential to Defond Electrical Industries Limited.
 * Unauthorized copying, modification, distribution, or use of this code, in whole or in part,
 * without prior written permission from Defond Electrical Industries Limited is strictly prohibited.
 */

#include <QQmlContext>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QScreen>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include "FpsMonitor.h"
#include "serialhandler.h"

/**
 * @brief Application entry point.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @return int Application exit code.
 */
int main(int argc, char *argv[])
{

    QGuiApplication app(argc, argv);

    QQuickStyle::setStyle(QStringLiteral("Material"));

    SerialHandler serialHandler;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("serialHandler"), &serialHandler);

    FpsMonitor *fpsMonitor = nullptr;

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [&](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             qWarning() << "Error: Main QML root object could not be created from" << url;
                             QCoreApplication::exit(-1);
                         } else if (obj && url == objUrl) {
                             // Create the FPS monitor once the root QQuickWindow is available.
                             QQuickWindow *rootWindow = qobject_cast<QQuickWindow*>(obj);
                             if (rootWindow) {
                                 if (fpsMonitor) {
                                     delete fpsMonitor;
                                     fpsMonitor = nullptr;
                                 }
                                 fpsMonitor = new FpsMonitor(rootWindow, &engine);
                                 engine.rootContext()->setContextProperty(QStringLiteral("fpsMonitor"), fpsMonitor);
                             } else {
                                 qWarning() << "Main QML root object is not a QQuickWindow. FPS monitoring might not work or needs adjustment.";
                             }
                         }
                     }, Qt::QueuedConnection);
    engine.load(url);

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
