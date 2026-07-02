#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include "FpsMonitor.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    FpsMonitor *fpsMonitor = nullptr;

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [&](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             qWarning() << "Failed to create root QML object from" << url;
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
