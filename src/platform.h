#ifndef ZXINGQR_PLATFORM_H
#define ZXINGQR_PLATFORM_H

#include <QObject>
#include <qqmlintegration.h>

#if __has_include(<QPermissions>)
#include <QPermissions>
#endif

// Small bridge for the platform details the QML side needs to know about:
//   - whether the camera permission has been granted;
//   - whether this is a debug build (used to enable the F5 demo shortcut).
//
// Asking the operating system for the camera is a platform concern, so it
// lives here in C++. On desktop there is usually nothing to ask and access is
// granted straight away; on Android the system dialog is shown and the
// property updates once the user answers. Exposed to QML as a singleton.
class Platform : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool cameraGranted READ cameraGranted NOTIFY cameraGrantedChanged)
    Q_PROPERTY(bool debugBuild READ debugBuild CONSTANT)

public:
    explicit Platform(QObject *parent = nullptr);

    bool cameraGranted() const;
    bool debugBuild() const;

    // Asks for the camera permission if we do not already have it.
    Q_INVOKABLE void requestCamera();

signals:
    void cameraGrantedChanged();

#if QT_CONFIG(permissions)
private slots:
    // Called by Qt after the user closes the permission dialog.
    void onCameraPermissionResolved(const QPermission &permission);
#endif

private:
    void setCameraGranted(bool granted);

    bool m_cameraGranted = false;
};

#endif // ZXINGQR_PLATFORM_H
