/**
 * @file MeshRenderer.h
 * @brief QQuickFramebufferObject::Renderer that draws the bread model with raw OpenGL ES.
 *
 * Pipeline (all on the render thread):
 *   1. First render(): parse bread.glb from Qt resources, pre-transform vertices
 *      into world space, upload one interleaved VBO + IBO, compile GLSL shaders.
 *   2. Every render(): set spin+tilt uniforms, one glDrawElements call.
 *   3. synchronize(): copy angle/tilt from MeshView (called while GUI thread pauses).
 *
 * VBO layout per vertex (36 bytes):
 *   [0]  position  vec3  (pre-transformed to world space)
 *   [12] normal    vec3  (pre-transformed, unit length assumed for uniform scales)
 *   [24] color     vec3  (per-mesh constant from Bread.qml palette)
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 */

#ifndef MESHRENDERER_H
#define MESHRENDERER_H

#include <QQuickFramebufferObject>
#include <QOpenGLExtraFunctions>
#include <QOpenGLShaderProgram>
#include <QMatrix4x4>
#include <QSize>
#include <QElapsedTimer>

class MeshView;

class MeshRenderer : public QQuickFramebufferObject::Renderer,
                     protected QOpenGLExtraFunctions
{
public:
    MeshRenderer();
    ~MeshRenderer() override;

    // QQuickFramebufferObject::Renderer interface
    void render() override;
    void synchronize(QQuickFramebufferObject *item) override;

private:
    void initGL();
    void loadBread();       // parse GLB, upload VBO/IBO

    bool   m_initialized = false;

    // GL objects
    GLuint m_vbo = 0;
    GLuint m_ibo = 0;
    GLuint m_vao = 0;      // VAO — attribute setup done once
    int    m_indexCount = 0;   // total uint16 indices

    QOpenGLShaderProgram *m_prog = nullptr;

    // Uniform locations
    GLint m_locModel    = -1;
    GLint m_locViewProj = -1;

    // Attribute locations
    GLint m_attrPos    = -1;
    GLint m_attrNormal = -1;
    GLint m_attrColor  = -1;

    // Current transform state (updated via synchronize)
    float  m_angle = 0.f;   // Y-axis spin (degrees)
    float  m_tilt  = 0.f;   // X-axis tilt (degrees)

    // Per-frame timing probe (logs every 30 frames to stderr)
    QElapsedTimer m_frameTimer;
    qint64 m_prevFrameStart = 0;
    int    m_frameIdx       = 0;
};

#endif // MESHRENDERER_H
