/**
 * @file BreadWindow.h
 * @brief Standalone OpenGL window — no Qt Quick, no QML, no V4 JS engine.
 *
 * Uses QOpenGLWindow which renders directly to the EGL window surface.
 * The scene graph sync, property-binding evaluation, and FBO composite
 * steps that exist in the Qt Quick path are completely absent here.
 *
 * If this gives substantially higher FPS than bread-gl-demo (QQFBO), the
 * bottleneck is in the Qt Quick layer.  If it gives the same ~4 FPS, the
 * bottleneck is in Mesa llvmpipe or the EGLFS swap/display path.
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 */

#ifndef BREADWINDOW_H
#define BREADWINDOW_H

#include <QOpenGLWindow>
#include <QOpenGLExtraFunctions>
#include <QOpenGLShaderProgram>
#include <QElapsedTimer>

class BreadWindow : public QOpenGLWindow, protected QOpenGLExtraFunctions
{
    Q_OBJECT

public:
    explicit BreadWindow(QWindow *parent = nullptr);
    ~BreadWindow() override;

protected:
    void initializeGL() override;
    void paintGL()      override;
    void resizeGL(int w, int h) override;

private:
    void loadBread();

    // GL objects
    GLuint m_vbo        = 0;
    GLuint m_ibo        = 0;
    GLuint m_vao        = 0;    // VAO — attribute setup done once
    int    m_indexCount = 0;

    QOpenGLShaderProgram *m_prog     = nullptr;
    GLint  m_locModel    = -1;
    GLint  m_locViewProj = -1;
    GLint  m_attrPos     = -1;
    GLint  m_attrNormal  = -1;
    GLint  m_attrColor   = -1;

    // Viewport aspect (updated in resizeGL)
    float m_aspect = 1.f;

    // Animation / FPS
    QElapsedTimer m_timer;
    int           m_frameCount  = 0;
    qint64        m_lastFpsTime = 0;
    int           m_fps         = 0;
};

#endif // BREADWINDOW_H
