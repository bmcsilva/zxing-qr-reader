#ifndef QRREADER_QRSCANNER_H
#define QRREADER_QRSCANNER_H

#include <QObject>
#include <QElapsedTimer>
#include <QVideoSink>
#include <QVideoFrame>
#include <qqmlintegration.h>

// Reads QR codes from the camera frames.
//
// The heavy lifting belongs to the ZXing library; this class only feeds the
// Qt Multimedia frames (through a QVideoSink) into ZXing and hands the decoded
// text back to QML. It is a QML_ELEMENT, so it can be used directly from QML.
class QrScanner : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QVideoSink* videoSink READ videoSink WRITE setVideoSink NOTIFY videoSinkChanged)
    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
public:
    explicit QrScanner(QObject *parent = nullptr);

    QVideoSink* videoSink() const { return m_videoSink; }
    void setVideoSink(QVideoSink *sink);

    bool isActive() const { return m_active; }
    void setActive(bool active);

    Q_INVOKABLE void reset();

signals:
    void videoSinkChanged();
    void activeChanged();
    void decoded(const QString &text);
    void decodeError(const QString &message);

private slots:
    void onVideoFrameChanged(const QVideoFrame &frame);

private:
    QVideoSink *m_videoSink = nullptr;
    bool m_active = false;
    bool m_hasResult = false;
    QElapsedTimer m_throttle;
};

#endif // QRREADER_QRSCANNER_H
