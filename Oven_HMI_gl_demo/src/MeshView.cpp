/**
 * @file MeshView.cpp
 * @brief QQuickFramebufferObject item implementation.
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 */

#include "MeshView.h"
#include "MeshRenderer.h"

MeshView::MeshView(QQuickItem *parent)
    : QQuickFramebufferObject(parent)
{
    // Mirror so OpenGL's bottom-left origin matches Qt Quick's top-left origin.
    setMirrorVertically(true);
}

QQuickFramebufferObject::Renderer *MeshView::createRenderer() const
{
    return new MeshRenderer();
}

void MeshView::setAngle(float a)
{
    if (m_angle == a) return;
    m_angle = a;
    emit angleChanged();
    update();   // request a new render pass
}

void MeshView::setTilt(float t)
{
    if (m_tilt == t) return;
    m_tilt = t;
    emit tiltChanged();
    update();
}
