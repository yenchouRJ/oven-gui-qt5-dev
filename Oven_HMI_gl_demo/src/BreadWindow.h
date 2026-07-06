/**
 * @file BreadWindow.h
 * @brief Standalone OpenGL window — no Qt Quick, no QML, no V4 JS engine.
 *
 * Render pipeline (two passes):
 *   Pass 1 — 3D scene into a small off-screen FBO (RENDER_W × RENDER_H).
 *             Only RENDER_W×RENDER_H pixels rasterized — much cheaper.
 *   Pass 2 — Blit FBO texture into MODEL_DW×MODEL_DH area on screen only.
 *             Background is a plain dark clear; rest of window is untouched.
 *
 * Adjust the four MODEL_* constants to match the actual UI layout.
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 */

#ifndef BREADWINDOW_H
#define BREADWINDOW_H

#include <QOpenGLWindow>
#include <QOpenGLExtraFunctions>
#include <QOpenGLShaderProgram>
#include <QOpenGLFramebufferObject>
#include <QElapsedTimer>

// ---- 3D render resolution ---------------------------------------------------
static constexpr int RENDER_W = 128;
static constexpr int RENDER_H = 128;

// ---- Model display area on screen (blit destination, pixels from top-left) --
// Centred in the right half of a 1280×480 window.
// Change these to match the real product UI layout.
static constexpr int MODEL_X  = 880;   // left edge of model area
static constexpr int MODEL_Y  =  40;   // top  edge of model area
static constexpr int MODEL_DW = 360;   // display width  (360×400 px)
static constexpr int MODEL_DH = 400;   // display height

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
    void initBlit();

    // ---- 3D scene -----------------------------------------------------------
    GLuint m_vbo        = 0;
    GLuint m_ibo        = 0;
    GLuint m_vao        = 0;
    int    m_indexCount = 0;

    QOpenGLShaderProgram *m_prog3d   = nullptr;
    GLint  m_locModel    = -1;
    GLint  m_locViewProj = -1;
    GLint  m_attrPos     = -1;
    GLint  m_attrNormal  = -1;
    GLint  m_attrColor   = -1;

    // ---- Off-screen FBO (RENDER_W × RENDER_H) --------------------------------
    QOpenGLFramebufferObject *m_fbo = nullptr;

    // ---- Blit (textured quad into model area) --------------------------------
    QOpenGLShaderProgram *m_progBlit = nullptr;
    GLuint m_quadVao = 0;
    GLuint m_quadVbo = 0;
    GLint  m_locTex  = -1;

    // ---- Window size --------------------------------------------------------
    int m_winW = 1280;
    int m_winH =  480;

    // ---- Animation / FPS ----------------------------------------------------
    QElapsedTimer m_timer;
    int           m_frameCount  = 0;
    qint64        m_lastFpsTime = 0;
};

#endif // BREADWINDOW_H
