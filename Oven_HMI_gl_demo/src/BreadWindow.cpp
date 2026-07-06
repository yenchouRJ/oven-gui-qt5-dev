/**
 * @file BreadWindow.cpp
 * @brief QOpenGLWindow renderer — direct OpenGL, no Qt Quick.
 *
 * Render pipeline:
 *   Pass 1 — bind off-screen FBO (128×128), glClear + glDrawElements
 *   Pass 2 — bind window FB, clear whole window, restrict viewport to
 *             MODEL_DW×MODEL_DH area, draw textured quad (blit)
 *
 * Timing (logged every second):
 *   tClear — FBO clear cost
 *   tDraw  — glDrawElements cost (3D rasterization into FBO)
 *   tBlit  — textured-quad draw cost (blit into model display area only)
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 */

#include "BreadWindow.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QMatrix4x4>
#include <QQuaternion>
#include <QVector3D>
#include <QDebug>

#include <cstring>
#include <vector>

// ---------------------------------------------------------------------------
// GLSL ES 3.00 — 3D scene shader
// ---------------------------------------------------------------------------
static const char *VERT3D = R"GLSL(#version 300 es
in highp   vec3 a_position;
in mediump vec3 a_normal;
in mediump vec3 a_color;

uniform highp mat4 u_model;
uniform highp mat4 u_viewProj;

out mediump vec3 v_nw;
out mediump vec3 v_color;

void main()
{
    vec4 world  = u_model * vec4(a_position, 1.0);
    gl_Position = u_viewProj * world;
    v_nw    = mat3(u_model) * a_normal;
    v_color = a_color;
}
)GLSL";

static const char *FRAG3D = R"GLSL(#version 300 es
precision mediump float;

in vec3 v_nw;
in vec3 v_color;
out vec4 fragColor;

void main()
{
    vec3  n     = normalize(v_nw);
    vec3  L     = normalize(vec3(1.0, 2.0, 1.5));
    float nDotL = max(dot(n, L), 0.0);
    vec3  col   = v_color * (0.35 + 0.75 * nDotL);
    fragColor   = vec4(col, 1.0);
}
)GLSL";

// ---------------------------------------------------------------------------
// GLSL ES 3.00 — fullscreen blit shader
// ---------------------------------------------------------------------------
static const char *VERT_BLIT = R"GLSL(#version 300 es
in vec2 a_pos;      // [-1..1] NDC
in vec2 a_uv;
out vec2 v_uv;
void main() { gl_Position = vec4(a_pos, 0.0, 1.0); v_uv = a_uv; }
)GLSL";

static const char *FRAG_BLIT = R"GLSL(#version 300 es
precision mediump float;
in  vec2      v_uv;
out vec4      fragColor;
uniform sampler2D u_tex;
void main() { fragColor = texture(u_tex, v_uv); }
)GLSL";

// ---------------------------------------------------------------------------
// GLB helpers
// ---------------------------------------------------------------------------
static inline uint32_t wReadU32(const uchar *d, int off) {
    return uint32_t(d[off]) | (uint32_t(d[off+1])<<8) | (uint32_t(d[off+2])<<16) | (uint32_t(d[off+3])<<24);
}
static inline uint16_t wReadU16(const uchar *d, int off) {
    return uint16_t(d[off]) | uint16_t(uint16_t(d[off+1])<<8);
}
static inline float wReadF32(const uchar *d, int off) { float v; std::memcpy(&v, d+off, 4); return v; }

struct WVertex { float px,py,pz, nx,ny,nz, cr,cg,cb; };

static QMatrix4x4 wNodeTransform(const QJsonObject &n) {
    QMatrix4x4 m;
    QJsonArray t=n["translation"].toArray(), r=n["rotation"].toArray(), s=n["scale"].toArray();
    if(!t.isEmpty()) m.translate(float(t[0].toDouble()),float(t[1].toDouble()),float(t[2].toDouble()));
    if(!r.isEmpty()) m.rotate(QQuaternion(float(r[3].toDouble()),float(r[0].toDouble()),float(r[1].toDouble()),float(r[2].toDouble())));
    if(!s.isEmpty()) m.scale(float(s[0].toDouble()),float(s[1].toDouble()),float(s[2].toDouble()));
    return m;
}
static QVector3D wMeshColor(int idx) {
    switch(idx) {
        case 0: return {0.800f,0.310f,0.090f};
        case 1: return {0.427f,0.125f,0.027f};
        case 2: return {0.310f,0.094f,0.020f};
        default:return {0.540f,0.440f,0.376f};
    }
}

// ---------------------------------------------------------------------------
// BreadWindow
// ---------------------------------------------------------------------------

BreadWindow::BreadWindow(QWindow *parent)
    : QOpenGLWindow(QOpenGLWindow::NoPartialUpdate, parent)
{}

BreadWindow::~BreadWindow()
{
    makeCurrent();
    delete m_fbo;
    if (m_vao)     glDeleteVertexArrays(1, &m_vao);
    if (m_vbo)     glDeleteBuffers(1, &m_vbo);
    if (m_ibo)     glDeleteBuffers(1, &m_ibo);
    if (m_quadVao) glDeleteVertexArrays(1, &m_quadVao);
    if (m_quadVbo) glDeleteBuffers(1, &m_quadVbo);
    delete m_prog3d;
    delete m_progBlit;
    doneCurrent();
}

// ---------------------------------------------------------------------------
// initializeGL
// ---------------------------------------------------------------------------
void BreadWindow::initializeGL()
{
    initializeOpenGLFunctions();

    // ---- 3D scene shader ----------------------------------------------------
    m_prog3d = new QOpenGLShaderProgram(this);
    if (!m_prog3d->addShaderFromSourceCode(QOpenGLShader::Vertex,   VERT3D) ||
        !m_prog3d->addShaderFromSourceCode(QOpenGLShader::Fragment, FRAG3D) ||
        !m_prog3d->link()) {
        qCritical() << "bread-gl-win: 3D shader failed:" << m_prog3d->log();
        delete m_prog3d; m_prog3d = nullptr; return;
    }
    m_locModel    = m_prog3d->uniformLocation("u_model");
    m_locViewProj = m_prog3d->uniformLocation("u_viewProj");
    m_attrPos     = m_prog3d->attributeLocation("a_position");
    m_attrNormal  = m_prog3d->attributeLocation("a_normal");
    m_attrColor   = m_prog3d->attributeLocation("a_color");

    loadBread();

    // ---- VAO for 3D scene ---------------------------------------------------
    glGenVertexArrays(1, &m_vao);
    glBindVertexArray(m_vao);
    glBindBuffer(GL_ARRAY_BUFFER,         m_vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_ibo);
    constexpr GLsizei stride = sizeof(WVertex);
    glEnableVertexAttribArray(m_attrPos);
    glEnableVertexAttribArray(m_attrNormal);
    glEnableVertexAttribArray(m_attrColor);
    glVertexAttribPointer(m_attrPos,    3, GL_FLOAT, GL_FALSE, stride, reinterpret_cast<void*>(0));
    glVertexAttribPointer(m_attrNormal, 3, GL_FLOAT, GL_FALSE, stride, reinterpret_cast<void*>(12));
    glVertexAttribPointer(m_attrColor,  3, GL_FLOAT, GL_FALSE, stride, reinterpret_cast<void*>(24));
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // ---- Off-screen FBO (RENDER_W × RENDER_H) -------------------------------
    QOpenGLFramebufferObjectFormat fboFmt;
    fboFmt.setAttachment(QOpenGLFramebufferObject::Depth);
    fboFmt.setInternalTextureFormat(GL_RGBA8);
    m_fbo = new QOpenGLFramebufferObject(RENDER_W, RENDER_H, fboFmt);
    qDebug() << "bread-gl-win: FBO" << RENDER_W << "x" << RENDER_H
             << "valid=" << m_fbo->isValid();

    // ---- Blit shader + fullscreen quad VAO ----------------------------------
    initBlit();

    qDebug() << "bread-gl-win: GL:"
             << reinterpret_cast<const char*>(glGetString(GL_VERSION));

    m_timer.start();
    m_lastFpsTime = 0;
}

void BreadWindow::initBlit()
{
    m_progBlit = new QOpenGLShaderProgram(this);
    if (!m_progBlit->addShaderFromSourceCode(QOpenGLShader::Vertex,   VERT_BLIT) ||
        !m_progBlit->addShaderFromSourceCode(QOpenGLShader::Fragment, FRAG_BLIT) ||
        !m_progBlit->link()) {
        qCritical() << "bread-gl-win: blit shader failed:" << m_progBlit->log();
        delete m_progBlit; m_progBlit = nullptr; return;
    }
    m_locTex = m_progBlit->uniformLocation("u_tex");

    // Fullscreen quad: 2 triangles covering [-1,1]^2 with UV [0,1]^2
    // Flip V so OpenGL FBO (bottom-left origin) maps correctly to screen (top-left)
    static const float kQuad[] = {
        // pos xy      uv
        -1.f, -1.f,  0.f, 0.f,
         1.f, -1.f,  1.f, 0.f,
         1.f,  1.f,  1.f, 1.f,
        -1.f, -1.f,  0.f, 0.f,
         1.f,  1.f,  1.f, 1.f,
        -1.f,  1.f,  0.f, 1.f,
    };

    glGenVertexArrays(1, &m_quadVao);
    glGenBuffers(1, &m_quadVbo);
    glBindVertexArray(m_quadVao);
    glBindBuffer(GL_ARRAY_BUFFER, m_quadVbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(kQuad), kQuad, GL_STATIC_DRAW);

    GLint aPos = m_progBlit->attributeLocation("a_pos");
    GLint aUv  = m_progBlit->attributeLocation("a_uv");
    glEnableVertexAttribArray(aPos);
    glEnableVertexAttribArray(aUv);
    glVertexAttribPointer(aPos, 2, GL_FLOAT, GL_FALSE, 4*sizeof(float), reinterpret_cast<void*>(0));
    glVertexAttribPointer(aUv,  2, GL_FLOAT, GL_FALSE, 4*sizeof(float), reinterpret_cast<void*>(2*sizeof(float)));

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void BreadWindow::resizeGL(int w, int h)
{
    m_winW = w;
    m_winH = h;
}

// ---------------------------------------------------------------------------
// paintGL — render to small FBO, then blit only into the model display area
// ---------------------------------------------------------------------------
void BreadWindow::paintGL()
{
    if (!m_prog3d || !m_fbo || !m_progBlit || m_indexCount == 0) { update(); return; }

    const float angle = float(m_timer.elapsed() % 8000) / 8000.f * 360.f;

    // =========================================================================
    // PASS 1 — render 3D model into RENDER_W × RENDER_H FBO
    // =========================================================================
    const qint64 t0 = m_timer.elapsed();

    m_fbo->bind();
    glViewport(0, 0, RENDER_W, RENDER_H);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glClearColor(0.08f, 0.08f, 0.14f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glFinish();
    const qint64 tClear = m_timer.elapsed() - t0;

    m_prog3d->bind();

    QMatrix4x4 model;
    model.rotate(angle, 0.f, 1.f, 0.f);

    QMatrix4x4 proj;
    proj.perspective(45.f, float(RENDER_W) / float(RENDER_H), 0.1f, 50.f);

    QMatrix4x4 view;
    view.lookAt({0.f, 1.5f, 7.f}, {0.f, 0.4f, 0.f}, {0.f, 1.f, 0.f});

    m_prog3d->setUniformValue(m_locModel,    model);
    m_prog3d->setUniformValue(m_locViewProj, proj * view);

    const qint64 td0 = m_timer.elapsed();
    glBindVertexArray(m_vao);
    glDrawElements(GL_TRIANGLES, m_indexCount, GL_UNSIGNED_SHORT, nullptr);
    glBindVertexArray(0);
    glFinish();
    const qint64 tDraw = m_timer.elapsed() - td0;

    m_prog3d->release();
    m_fbo->release();

    // =========================================================================
    // PASS 2 — composite onto window
    //   a) Clear full window to background colour (one fast memset)
    //   b) Restrict viewport to MODEL area, draw blit quad there only
    // =========================================================================
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebufferObject());
    glDisable(GL_DEPTH_TEST);

    // Full-window clear (background)
    glViewport(0, 0, m_winW, m_winH);
    glClearColor(0.05f, 0.05f, 0.10f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT);

    // GL viewport uses bottom-left origin; convert from top-left screen coords.
    // MODEL_Y is distance from screen top → GL y = winH - MODEL_Y - MODEL_DH
    const int glY = m_winH - MODEL_Y - MODEL_DH;

    // Restrict rasterization to the model area — only these pixels are touched
    glViewport(MODEL_X, glY, MODEL_DW, MODEL_DH);

    m_progBlit->bind();
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, m_fbo->texture());
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    m_progBlit->setUniformValue(m_locTex, 0);

    const qint64 tb0 = m_timer.elapsed();
    glBindVertexArray(m_quadVao);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glBindVertexArray(0);
    glFinish();
    const qint64 tBlit = m_timer.elapsed() - tb0;

    glBindTexture(GL_TEXTURE_2D, 0);
    m_progBlit->release();

    // =========================================================================
    // FPS + split timing log every second
    // =========================================================================
    ++m_frameCount;
    const qint64 now = m_timer.elapsed();
    if (now - m_lastFpsTime >= 1000) {
        qDebug("[bread-gl-win] FPS: %d  tClear=%.1f ms  tDraw=%.1f ms  tBlit=%.1f ms"
               "  model=%dx%d→%dx%d@(%d,%d)",
               m_frameCount,
               float(tClear), float(tDraw), float(tBlit),
               RENDER_W, RENDER_H, MODEL_DW, MODEL_DH, MODEL_X, MODEL_Y);
        m_frameCount  = 0;
        m_lastFpsTime = now;
    }

    update();
}

// ---------------------------------------------------------------------------
// loadBread — same as before
// ---------------------------------------------------------------------------
void BreadWindow::loadBread()
{
    QFile f(QStringLiteral(":/assets/models/bread.glb"));
    if (!f.open(QIODevice::ReadOnly)) { qCritical() << "bread-gl-win: cannot open bread.glb"; return; }
    const QByteArray glbData = f.readAll(); f.close();
    const auto *raw = reinterpret_cast<const uchar*>(glbData.constData());
    if (wReadU32(raw, 0) != 0x46546C67u) { qCritical() << "bad GLB magic"; return; }
    const uint32_t jsonLen = wReadU32(raw, 12);
    const QJsonObject root = QJsonDocument::fromJson(
        QByteArray::fromRawData(reinterpret_cast<const char*>(raw+20), int(jsonLen))).object();
    const uchar *bin = raw + 20 + int(jsonLen) + 8;
    const QJsonArray accessors=root["accessors"].toArray(), bufferViews=root["bufferViews"].toArray();
    const QJsonArray nodes=root["nodes"].toArray(), meshes=root["meshes"].toArray();
    const QJsonArray sceneNodes=root["scenes"].toArray().at(root["scene"].toInt()).toObject()["nodes"].toArray();

    auto accOffset   = [&](int i) -> const uchar* { auto a=accessors[i].toObject(); auto b=bufferViews[a["bufferView"].toInt()].toObject(); return bin+b["byteOffset"].toInt()+a["byteOffset"].toInt(0); };
    auto accCount    = [&](int i){ return accessors[i].toObject()["count"].toInt(); };
    auto accCompType = [&](int i){ return accessors[i].toObject()["componentType"].toInt(); };

    std::vector<WVertex> verts; std::vector<uint16_t> indices;
    std::function<void(int, QMatrix4x4)> traverse = [&](int nodeIdx, QMatrix4x4 pw) {
        const QJsonObject nd = nodes[nodeIdx].toObject();
        const QMatrix4x4 w = pw * wNodeTransform(nd);
        const QJsonValue mv = nd["mesh"];
        if (!mv.isUndefined()) {
            const int mi = mv.toInt(); const QVector3D col = wMeshColor(mi);
            for (const QJsonValue &pv : meshes[mi].toObject()["primitives"].toArray()) {
                const QJsonObject p=pv.toObject(), at=p["attributes"].toObject();
                const int posA=at["POSITION"].toInt(), normA=at["NORMAL"].toInt(), idxA=p["indices"].toInt();
                const int vc=accCount(posA); const uchar *pp=accOffset(posA), *np=accOffset(normA);
                const auto base=static_cast<uint16_t>(verts.size());
                for (int vi=0;vi<vc;++vi) {
                    QVector3D wp=w.map(QVector3D(wReadF32(pp,vi*12),wReadF32(pp,vi*12+4),wReadF32(pp,vi*12+8)));
                    QVector3D wn=w.mapVector(QVector3D(wReadF32(np,vi*12),wReadF32(np,vi*12+4),wReadF32(np,vi*12+8))).normalized();
                    verts.push_back({wp.x(),wp.y(),wp.z(),wn.x(),wn.y(),wn.z(),col.x(),col.y(),col.z()});
                }
                const int ic=accCount(idxA); const uchar *ip=accOffset(idxA); const int ct=accCompType(idxA);
                for (int ii=0;ii<ic;++ii) { uint32_t idx=(ct==5123)?wReadU16(ip,ii*2):wReadU32(ip,ii*4); indices.push_back(static_cast<uint16_t>(base+idx)); }
            }
        }
        for (const QJsonValue &ch : nd["children"].toArray()) traverse(ch.toInt(), w);
    };
    for (const QJsonValue &rn : sceneNodes) traverse(rn.toInt(), QMatrix4x4{});

    m_indexCount = int(indices.size());
    qDebug("[bread-gl-win] loaded %zu verts, %d tris", verts.size(), m_indexCount/3);

    glGenBuffers(1, &m_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
    glBufferData(GL_ARRAY_BUFFER, GLsizeiptr(verts.size()*sizeof(WVertex)), verts.data(), GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glGenBuffers(1, &m_ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, GLsizeiptr(indices.size()*sizeof(uint16_t)), indices.data(), GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}
