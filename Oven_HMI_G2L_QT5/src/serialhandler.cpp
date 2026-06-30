/**
 * @file serialhandler.cpp
 * @brief Serial-port handler implementation for the Oven HMI protocol.
 * @details Opens the port, reads newline-delimited tokens, and emits UI-facing signals.
 * @author Sita Chan
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 * All rights reserved.
 *
 * This source code is proprietary and confidential to Defond Electrical Industries Limited.
 * Unauthorized copying, modification, distribution, or use of this code, in whole or in part,
 * without prior written permission from Defond Electrical Industries Limited is strictly prohibited.
 */

#include "serialhandler.h"
#include <QDebug>

namespace {
constexpr auto CMD_T_POWER     = "tpower";
constexpr auto CMD_T_PLAY      = "tplay";
constexpr auto CMD_T_POWER_OFF = "tpf";
constexpr auto CMD_T_SAVE       ="tsave";
constexpr auto CMD_T_WAKE       ="twake";
}

/**
 * @brief Constructs a SerialHandler with an optional parent.
 *
 * @param parent QObject parent (default = nullptr).
 */
SerialHandler::SerialHandler(QObject *parent)
    : QObject(parent)
{
    connect(&m_port, &QSerialPort::readyRead,
            this, &SerialHandler::handleReadyRead);
    connect(&m_port, &QSerialPort::errorOccurred,
            this, &SerialHandler::handleError);
}

/**
 * @brief Opens the given serial port.
 *
 * @param portName Name of the serial device (e.g. "/dev/ttyUSB0").
 * @param baudRate Desired baud rate (default 115200).
 */
void SerialHandler::open(const QString &portName, int baudRate)
{
    if (m_port.isOpen())
        m_port.close();

    m_port.setPortName(portName);
    m_port.setBaudRate(baudRate);
    m_port.setDataBits(QSerialPort::Data8);
    m_port.setParity(QSerialPort::NoParity);
    m_port.setStopBits(QSerialPort::OneStop);
    m_port.setFlowControl(QSerialPort::NoFlowControl);

    if (!m_port.open(QIODevice::ReadWrite)) {
        emit errorOccurred(tr("Open failed: %1").arg(m_port.errorString()));
        emit connectedChanged();
        return;
    }

    m_port.setDataTerminalReady(true);
    m_port.setRequestToSend(false);
    m_port.clear();//clear buffer

    emit connectedChanged();
}

/**
 * @brief Closes the currently-open serial port.
 */
void SerialHandler::close()
{
    if (m_port.isOpen())
        m_port.close();

    emit connectedChanged();
}

/**
 * @brief Sends a line (terminated with '\n') to the device.
 *
 * @param line UTF-8 text to transmit.
 */
void SerialHandler::send(const QString &line)
{
    if (!m_port.isOpen())
        return;

    qInfo() << "[SERIAL] -> " << line;

    QByteArray data = (line + "\n").toUtf8();          // always add newline
    qint64 written = m_port.write(data);
    if (written == -1) {
        qWarning() << "Write failed";
    } else {
        m_port.waitForBytesWritten(50);   // make sure it really goes out
    }
}

/**
 * @brief Returns whether the serial port is currently open.
 *
 * @return bool true if open, false otherwise.
 */
bool SerialHandler::isConnected() const
{
    return m_port.isOpen();
}

/**
 * @brief Reads incoming data and extracts complete lines.
 */
void SerialHandler::handleReadyRead()
{
    m_buffer += m_port.readAll();

    while (!m_buffer.isEmpty()) {
        // Find line ending (\n or \r)
        int idx = m_buffer.indexOf('\n');
        if (idx == -1) idx = m_buffer.indexOf('\r');

        QByteArray rawLine;

        if (idx == -1) {
            // No line ending → treat the whole buffer as one line (common on many MCUs)
            rawLine = m_buffer;
            m_buffer.clear();
        } else {
            rawLine = m_buffer.left(idx);
            m_buffer.remove(0, idx + 1);                 // remove \n or \r
            // Skip the other half if \r\n or \n\r
            if (!m_buffer.isEmpty() && (m_buffer.at(0) == '\r' || m_buffer.at(0) == '\n'))
                m_buffer.remove(0, 1);
        }

        QString token = QString::fromUtf8(rawLine).trimmed();
        if (!token.isEmpty()) {
            qInfo() << "[SERIAL] <- " << token;
            emit serialLineReceived(token);   // show in log
            routeToken(token);                // trigger actions
        }
    }
}



/**
 * @brief Handles low-level serial errors.
 *
 * @param error Error code from QSerialPort.
 */
void SerialHandler::handleError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError)
        return;

    emit errorOccurred(m_port.errorString());
}

/**
 * @brief Dispatches a token to the appropriate high-level signal.
 *
 * @param token Parsed command token.
 */
void SerialHandler::routeToken(const QString &token)
{
    // 1. Legacy Commands (Keep for compatibility)
    if (token == CMD_T_POWER) {
        emit powerOnRequested();
        return;
    } else if(token == CMD_T_PLAY) {
        emit playOnRequested();
        return;
    } else if (token == CMD_T_POWER_OFF) {
        emit powerOffRequested();
        return;
    } else if (token == CMD_T_SAVE) {
        emit saverRequested();
        return;
    } else if (token == CMD_T_WAKE) {
        emit wakeScreenRequested();
        return;
    }

    // 2. New Protocol Parsing (CMD:PARAM)
    // Example: "STATUS:READY", "TEMP:95.5", "MAKE:latte"
    const QStringList parts = token.split(':');
    if (parts.isEmpty()) return;

    QString cmd = parts[0].toUpper(); // Case-insensitive command
    QString param = (parts.size() > 1) ? parts[1] : "";

    if (cmd == "STATUS") {
        emit statusReceived(param);
    } 
    else if (cmd == "PROGRESS") {
        bool ok;
        int val = param.toInt(&ok);
        if (ok) emit progressReceived(val);
    }
    else if (cmd == "TEMP") {
        bool ok;
        double val = param.toDouble(&ok);
        if (ok) emit temperatureReceived(val);
    }
    else if (cmd == "MAKE") {
        if (!param.isEmpty()) emit drinkStartRequested(param);
    }
    else if (cmd == "PAGE") {
        if (!param.isEmpty()) emit pageNavigationRequested(param);
    }
}
