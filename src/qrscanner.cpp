#include "qrscanner.h"

#include <QImage>
#include <QVideoFrame>

#include <BarcodeFormat.h>
#include <ReaderOptions.h>
#include <ImageView.h>
#include <ReadBarcode.h>

QrScanner::QrScanner(QObject *parent)
    : QObject(parent)
{
    m_throttle.start();
}

void QrScanner::setVideoSink(QVideoSink *sink)
{
    if (m_videoSink == sink)
        return;

    if (m_videoSink)
        disconnect(m_videoSink, nullptr, this, nullptr);

    m_videoSink = sink;

    if (m_videoSink)
        connect(m_videoSink, &QVideoSink::videoFrameChanged, this, &QrScanner::onVideoFrameChanged);

    emit videoSinkChanged();
}

void QrScanner::setActive(bool active)
{
    if (m_active == active)
        return;
    m_active = active;
    emit activeChanged();
}

void QrScanner::reset()
{
    m_hasResult = false;
    m_throttle.restart();
}

void QrScanner::onVideoFrameChanged(const QVideoFrame &frame)
{
    // Skip frames while stopped or while a result is still waiting to be used.
    if (!m_active || m_hasResult)
        return;

    if (!frame.isValid())
        return;

    // Decoding every frame would be wasteful; about four reads per second are
    // more than enough and save battery.
    if (m_throttle.isValid() && m_throttle.elapsed() < 250)
        return;

    m_throttle.restart();

    QImage image = frame.toImage();
    if (image.isNull())
        return;

    // ZXing works on luminance, so convert to grayscale and point it straight
    // at the image bytes.
    QImage gray = image.convertToFormat(QImage::Format_Grayscale8);
    ZXing::ImageView view(gray.bits(), gray.width(), gray.height(),
                          ZXing::ImageFormat::Lum, gray.bytesPerLine());

    ZXing::ReaderOptions options;
    options.setTryHarder(true);
    options.setFormats(ZXing::BarcodeFormat::QRCode);

    const ZXing::Barcode barcode = ZXing::ReadBarcode(view, options);
    if (barcode.isValid()) {
        const QString text = QString::fromStdString(barcode.text());
        if (!text.isEmpty()) {
            m_hasResult = true;
            emit decoded(text);
        }
    }
}
