/**
 * @file serialhandler.h
 * @brief QObject‑derived serial‑port helper for the Oven HMI.
 *
 * @details Provides a thin Qt wrapper around QSerialPort that parses newline‑terminated
 * command tokens and emits high‑level signals for the UI.  It is used by the
 * QML/Qt front‑end to open/close the port, send lines and receive protocol events.
 *
 * @author  Sita Chan
 */

#ifndef SERIALHANDLER_H
#define SERIALHANDLER_H

#include <QObject>
#include <QSerialPort>
#include <QSerialPortInfo>

/**
 * @brief Handles serial communication with the MCU.
 *
 * The class opens a serial port, buffers incoming data until a newline is seen,
 * then routes known tokens to dedicated signals.  Unknown tokens are forwarded
 * unchanged via @c serialLineReceived().
 */
class SerialHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)

public:
    /**
     * @brief Constructs a SerialHandler with an optional parent.
     * @param parent QObject parent (default = nullptr).
     */
    explicit SerialHandler(QObject *parent = nullptr);

    /**
     * @brief Opens the given serial port.
     * @param portName Name of the serial device (e.g. "/dev/ttyUSB0").
     * @param baudRate Desired baud rate (default 115200).
     */
    Q_INVOKABLE void open(const QString &portName, int baudRate = 115200);

    /**
     * @brief Closes the currently‑opened serial port.
     */
    Q_INVOKABLE void close();

    /**
     * @brief Sends a line (terminated with '\n') to the device.
     * @param line UTF‑8 text to transmit.
     */
    Q_INVOKABLE void send(const QString &line);

    /**
     * @brief Returns whether the serial port is currently open.
     * @return true if open, false otherwise.
     */
    bool isConnected() const;

signals:
    /** @brief Raw line received from the MCU (after trimming). */
    void serialLineReceived(const QString &line);
    /** @brief Emitted on serial‑port errors. */
    void errorOccurred(const QString &message);

    // --- High‑level protocol signals --------------------------------

    /** @brief Machine status update, e.g. "READY" or "BREWING". */
    void statusReceived(const QString &status);
    /** @brief Brew progress percentage (0‑100). */
    void progressReceived(int percent);
    /** @brief Current temperature reading from the MCU. */
    void temperatureReceived(double temp);
    /** @brief Request to start a drink (drinkId corresponds to a recipe). */
    void drinkStartRequested(const QString &drinkId);
    /** @brief Request to navigate to a UI page (pageId corresponds to a QML page). */
    void pageNavigationRequested(const QString &pageId);

    // Legacy signals (kept for backward compatibility) --------------

    void powerOnRequested();
    void playOnRequested();
    void powerOffRequested();
    void saverRequested();
    void wakeScreenRequested();

    /** @brief Emitted whenever the connection state changes. */
    void connectedChanged();

private slots:
    /** @brief Reads incoming data and extracts complete lines. */
    void handleReadyRead();
    /** @brief Handles low‑level serial errors. */
    void handleError(QSerialPort::SerialPortError error);

private:
    /** @brief Dispatches a token to the appropriate high‑level signal. */
    void routeToken(const QString &token);

    QSerialPort m_port;          ///< Underlying Qt serial‑port object.
    QByteArray   m_buffer;       ///< Buffer that accumulates partial lines.
};

#endif // SERIALHANDLER_H
