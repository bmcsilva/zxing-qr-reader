#include <QGuiApplication>
#include <QIcon>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QTranslator>

int main(int argc, char *argv[])
{
    QGuiApplication application(argc, argv);
    application.setApplicationName(QStringLiteral("QR Scanner"));
    application.setWindowIcon(QIcon(QStringLiteral(":/appicon.png")));

    // Load the translation that matches the device language. English is the
    // language the UI strings are written in, so it needs no file of its own:
    // if none of the bundled translations fits, the original text is shown.
    QTranslator translator;
    if (translator.load(QLocale::system(), QStringLiteral("QrReader"),
                        QStringLiteral("_"), QStringLiteral(":/i18n"))) {
        application.installTranslator(&translator);
    }

    // Everything else (camera permission, the debug-only demo shortcut, ...)
    // is driven from QML through the Platform singleton.
    QQmlApplicationEngine engine;
    engine.loadFromModule("QrReader", "Main");
    if (engine.rootObjects().isEmpty())
        return -1;

    return application.exec();
}
