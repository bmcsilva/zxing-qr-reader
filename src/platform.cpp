#include "platform.h"

#include <QFileInfo>
#include <QGuiApplication>
#include <QUrl>

Platform::Platform(QObject *parent)
    : QObject(parent)
{
}

bool Platform::cameraGranted() const
{
    return m_cameraGranted;
}

bool Platform::debugBuild() const
{
#ifdef QT_DEBUG
    return true;
#else
    return false;
#endif
}

QString Platform::scanFile() const
{
    const QStringList args = QCoreApplication::arguments();
    const qsizetype i = args.indexOf(QStringLiteral("--scan-file"));
    if (!debugBuild() || i < 0 || i + 1 >= args.size())
        return {};
    return QUrl::fromLocalFile(QFileInfo(args.at(i + 1)).absoluteFilePath()).toString();
}

void Platform::requestCamera()
{
#if QT_CONFIG(permissions)
    QCameraPermission permission;
    switch (qApp->checkPermission(permission)) {
    case Qt::PermissionStatus::Granted:
        setCameraGranted(true);
        break;
    case Qt::PermissionStatus::Denied:
        setCameraGranted(false);
        break;
    case Qt::PermissionStatus::Undetermined:
        // The answer arrives later in onCameraPermissionResolved().
        qApp->requestPermission(permission, this, &Platform::onCameraPermissionResolved);
        break;
    }
#else
    // Platforms without a permission model (typically desktop) can use the
    // camera right away.
    setCameraGranted(true);
#endif
}

#if QT_CONFIG(permissions)
void Platform::onCameraPermissionResolved(const QPermission &permission)
{
    setCameraGranted(permission.status() == Qt::PermissionStatus::Granted);
}
#endif

void Platform::setCameraGranted(bool granted)
{
    if (m_cameraGranted == granted)
        return;

    m_cameraGranted = granted;
    emit cameraGrantedChanged();
}
