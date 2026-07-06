/**
 * @file MeshView.h
 * @brief QQuickFramebufferObject subclass that exposes the bread model viewport.
 *
 * The item owns two properties driven from QML:
 *   - angle  (Y-axis spin, degrees) — driven by a NumberAnimation
 *   - tilt   (X-axis tilt, degrees) — driven by touch/mouse drag
 *
 * Each property change calls QQuickItem::update() which triggers a new FBO
 * render pass.  createRenderer() constructs the MeshRenderer on the render
 * thread; synchronize() ferries the current angle/tilt values to it.
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 */

#ifndef MESHVIEW_H
#define MESHVIEW_H

#include <QQuickFramebufferObject>

class MeshView : public QQuickFramebufferObject
{
    Q_OBJECT

    Q_PROPERTY(float angle READ angle WRITE setAngle NOTIFY angleChanged)
    Q_PROPERTY(float tilt  READ tilt  WRITE setTilt  NOTIFY tiltChanged)

public:
    explicit MeshView(QQuickItem *parent = nullptr);

    // QQuickFramebufferObject interface
    Renderer *createRenderer() const override;

    float angle() const { return m_angle; }
    float tilt()  const { return m_tilt;  }

    void setAngle(float a);
    void setTilt (float t);

signals:
    void angleChanged();
    void tiltChanged();

private:
    float m_angle = 0.f;
    float m_tilt  = 0.f;
};

#endif // MESHVIEW_H
