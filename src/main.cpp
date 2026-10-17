#include "zerotiercontroller.h"
#include "appsettings.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName("ZeroTier GUI");
    QGuiApplication::setOrganizationName("ZeroTier GUI");
    QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/assets/zerotier-icon.svg")));
    QQuickStyle::setStyle("Basic");

    ZeroTierController controller;
    AppSettings appSettings;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("zt", &controller);
    engine.rootContext()->setContextProperty("appSettings", &appSettings);
    engine.load(QUrl("qrc:/qt/qml/ZeroTierGUI/Main.qml"));
    if (engine.rootObjects().isEmpty()) return 1;
    return app.exec();
}
