/**
 * @file BreadWindow.cpp
 * @brief QOpenGLWindow renderer — direct OpenGL, no Qt Quick.
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
// GLSL ES 1.00 shaders (identical to MeshRenderer)
// ---------------------------------------------------------------------------

static const char *WIN_VERT = R"GLSL(
attribute highp   vec3 a_position;
attribute mediump vec3 a_normal;
attribute mediump vec3 a_color;

uniform highp mat4 u_model;
uniform highp mat4 u_viewProj;

varying mediump vec3 v_nw;
varying mediump vec3 v_color;

void main()
{
    vec4 world  = u_model * vec4(a_position, 1.0);
    gl_Position = u_viewProj * world;
    v_nw    = mat3(u_model) * a_normal;
    v_color = a_color;
}
)GLSL";

static const char *WIN_FRAG = R"GLSL(
precision mediump float;

varying vec3 v_nw;
varying vec3 v_color;

void main()
{
    vec3  n     = normalize(v_nw);
    vec3  L     = normalize(vec3(1.0, 2.0, 1.5));
    float nDotL = max(dot(n, L), 0.0);
    vec3  col   = v_color * (0.35 + 0.75 * nDotL);
    gl_FragColor = vec4(col, 1.0);
}
)GLSL";

// ---------------------------------------------------------------------------
// Shared GLB utilities (duplicated from MeshRenderer to keep files independent)
// ---------------------------------------------------------------------------

static inline uint32_t wReadU32(const uchar *d, int off)
{
    return  uint32_t(d[off])
          | (uint32_t(d[off+1]) << 8)
          | (uint32_t(d[off+2]) << 16)
          | (uint32_t(d[off+3]) << 24);
}
static inline uint16_t wReadU16(const uchar *d, int off)
{
    return uint16_t(d[off]) | uint16_t(uint16_t(d[off+1]) << 8);
}
static inline float wReadF32(const uchar *d, int off)
{
    float v; std::memcpy(&v, d + off, 4); return v;
}

struct WVertex { float px,py,pz, nx,ny,nz, cr,cg,cb; };

static QMatrix4x4 wNodeTransform(const QJsonObject &node)
{
    QMatrix4x4 m;
    QJsonArray t = node["translation"].toArray();
    QJsonArray r = node["rotation"].toArray();
    QJsonArray s = node["scale"].toArray();
    if (!t.isEmpty()) m.translate(float(t[0].toDouble()), float(t[1].toDouble()), float(t[2].toDouble()));
    if (!r.isEmpty()) m.rotate(QQuaternion(float(r[3].toDouble()), float(r[0].toDouble()), float(r[1].toDouble()), float(r[2].toDouble())));
    if (!s.isEmpty()) m.scale(float(s[0].toDouble()), float(s[1].toDouble()), float(s[2].toDouble()));
    return m;
}

static QVector3D wMeshColor(int idx)
{
    switch (idx) {
        case 0:  return {0.800f, 0.310f, 0.090f};
        case 1:  return {0.427f, 0.125f, 0.027f};
        case 2:  return {0.310f, 0.094f, 0.020f};
        default: return {0.540f, 0.440f, 0.376f};
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
    if (m_vao) glDeleteVertexArrays(1, &m_vao);
    if (m_vbo) glDeleteBuffers(1, &m_vbo);
    if (m_ibo) glDeleteBuffers(1, &m_ibo);
    delete m_prog;
    doneCurrent();
}

void BreadWindow::initializeGL()
{
    initializeOpenGLFunctions();

    // Compile shaders
    m_prog = new QOpenGLShaderProgram(this);
    if (!m_prog->addShaderFromSourceCode(QOpenGLShader::Vertex,   WIN_VERT) ||
        !m_prog->addShaderFromSourceCode(QOpenGLShader::Fragment, WIN_FRAG) ||
        !m_prog->link())
    {
        qCritical() << "bread-gl-win: shader link failed:" << m_prog->log();
        delete m_prog; m_prog = nullptr; return;
    }

    m_locModel    = m_prog->uniformLocation("u_model");
    m_locViewProj = m_prog->uniformLocation("u_viewProj");
    m_attrPos     = m_prog->attributeLocation("a_position");
    m_attrNormal  = m_prog->attributeLocation("a_normal");
    m_attrColor   = m_prog->attributeLocation("a_color");

    loadBread();    // uploads VBO + IBO

    // ---- VAO: record the vertex-attribute format once ----------------------
    // After this, per-frame draw only needs glBindVertexArray + glDrawElements.
    // This eliminates the per-frame glVertexAttribPointer calls that were
    // causing Mesa/llvmpipe to re-JIT the vertex-fetch pipeline every frame.
    glGenVertexArrays(1, &m_vao);
    glBindVertexArray(m_vao);
    glBindBuffer(GL_ARRAY_BUFFER,         m_vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_ibo);

    constexpr GLsizei stride = sizeof(WVertex);
    glEnableVertexAttribArray(m_attrPos);
    glEnableVertexAttribArray(m_attrNormal);
    glEnableVertexAttribArray(m_attrColor);
    glVertexAttribPointer(m_attrPos,    3, GL_FLOAT, GL_FALSE, stride, reinterpret_cast<void *>(0));
    glVertexAttribPointer(m_attrNormal, 3, GL_FLOAT, GL_FALSE, stride, reinterpret_cast<void *>(12));
    glVertexAttribPointer(m_attrColor,  3, GL_FLOAT, GL_FALSE, stride, reinterpret_cast<void *>(24));

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    // Note: do NOT unbind IBO while VAO is unbound — the IBO binding is part of VAO state.
    // (Already correct here because we unbound the VAO first.)

    qDebug() << "bread-gl-win: GL context:"
             << reinterpret_cast<const char *>(glGetString(GL_VERSION))
             << "/ GLSL:"
             << reinterpret_cast<const char *>(glGetString(GL_SHADING_LANGUAGE_VERSION));

    m_timer.start();
    m_lastFpsTime = 0;
}

void BreadWindow::resizeGL(int w, int h)
{
    m_aspect = w / float(h ? h : 1);
}

void BreadWindow::paintGL()
{
    if (!m_prog || m_indexCount == 0 || !m_vao) { update(); return; }

    // Compute spin angle from elapsed time (8 s per revolution)
    const float angle = float(m_timer.elapsed() % 8000) / 8000.f * 360.f;

    const int w = width();
    const int h = height();
    glViewport(0, 0, w, h);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);

    // ---- Split timing: measure glClear and glDrawElements separately --------
    const qint64 t0 = m_timer.elapsed();

    glClearColor(0.08f, 0.08f, 0.14f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glFinish();

    const qint64 tClear = m_timer.elapsed() - t0;

    // ---- Draw ---------------------------------------------------------------
    m_prog->bind();

    QMatrix4x4 model;
    model.rotate(angle, 0.f, 1.f, 0.f);

    QMatrix4x4 proj;
    proj.perspective(45.f, m_aspect, 0.1f, 50.f);

    QMatrix4x4 view;
    view.lookAt({0.f, 1.5f, 7.f}, {0.f, 0.4f, 0.f}, {0.f, 1.f, 0.f});

    m_prog->setUniformValue(m_locModel,    model);
    m_prog->setUniformValue(m_locViewProj, proj * view);

    const qint64 td0 = m_timer.elapsed();

    // VAO already has VBO/IBO bound and attribute pointers set — just bind + draw.
    glBindVertexArray(m_vao);
    glDrawElements(GL_TRIANGLES, m_indexCount, GL_UNSIGNED_SHORT, nullptr);
    glBindVertexArray(0);
    glFinish();

    const qint64 tDraw = m_timer.elapsed() - td0;

    m_prog->release();

    // ---- FPS + split timing log (every 30 frames) ---------------------------
    ++m_frameCount;
    const qint64 now = m_timer.elapsed();
    if (now - m_lastFpsTime >= 1000) {
        m_fps = m_frameCount;
        qDebug("[bread-gl-win] FPS: %d  tClear=%.1f ms  tDraw=%.1f ms",
               m_fps, float(tClear), float(tDraw));
        m_frameCount  = 0;
        m_lastFpsTime = now;
    }

    update();
}

// ---------------------------------------------------------------------------
// loadBread — identical logic to MeshRenderer::loadBread()
// ---------------------------------------------------------------------------
void BreadWindow::loadBread()
{
    QFile f(QStringLiteral(":/assets/models/bread.glb"));
    if (!f.open(QIODevice::ReadOnly)) {
        qCritical() << "bread-gl-win: cannot open :/assets/models/bread.glb"; return;
    }
    const QByteArray glbData = f.readAll();
    f.close();

    const auto *raw = reinterpret_cast<const uchar *>(glbData.constData());
    if (wReadU32(raw, 0) != 0x46546C67u) { qCritical() << "bad GLB magic"; return; }

    const uint32_t jsonLen = wReadU32(raw, 12);
    const QJsonObject root = QJsonDocument::fromJson(
        QByteArray::fromRawData(reinterpret_cast<const char *>(raw + 20), int(jsonLen))
    ).object();

    const int      binChunkOff = 20 + int(jsonLen);
    const uchar   *bin         = raw + binChunkOff + 8;

    const QJsonArray accessors   = root["accessors"].toArray();
    const QJsonArray bufferViews = root["bufferViews"].toArray();
    const QJsonArray nodes       = root["nodes"].toArray();
    const QJsonArray meshes      = root["meshes"].toArray();
    const QJsonArray sceneNodes  = root["scenes"].toArray()
                                       .at(root["scene"].toInt()).toObject()
                                       ["nodes"].toArray();

    auto accOffset = [&](int idx) -> const uchar * {
        const QJsonObject acc = accessors[idx].toObject();
        const QJsonObject bv  = bufferViews[acc["bufferView"].toInt()].toObject();
        return bin + bv["byteOffset"].toInt() + acc["byteOffset"].toInt(0);
    };
    auto accCount    = [&](int idx){ return accessors[idx].toObject()["count"].toInt(); };
    auto accCompType = [&](int idx){ return accessors[idx].toObject()["componentType"].toInt(); };

    std::vector<WVertex>  verts;
    std::vector<uint16_t> indices;

    std::function<void(int, QMatrix4x4)> traverse = [&](int nodeIdx, QMatrix4x4 parentWorld) {
        const QJsonObject node  = nodes[nodeIdx].toObject();
        const QMatrix4x4  world = parentWorld * wNodeTransform(node);
        const QJsonValue  meshVal = node["mesh"];
        if (!meshVal.isUndefined()) {
            const int meshIdx = meshVal.toInt();
            const QVector3D color = wMeshColor(meshIdx);
            for (const QJsonValue &primVal : meshes[meshIdx].toObject()["primitives"].toArray()) {
                const QJsonObject prim  = primVal.toObject();
                const QJsonObject attrs = prim["attributes"].toObject();
                const int posAcc  = attrs["POSITION"].toInt();
                const int normAcc = attrs["NORMAL"].toInt();
                const int idxAcc  = prim["indices"].toInt();
                const int vCount  = accCount(posAcc);
                const uchar *posPtr  = accOffset(posAcc);
                const uchar *normPtr = accOffset(normAcc);
                const auto baseVert  = static_cast<uint16_t>(verts.size());
                for (int vi = 0; vi < vCount; ++vi) {
                    const QVector3D wp = world.map(QVector3D(
                        wReadF32(posPtr, vi*12+0), wReadF32(posPtr, vi*12+4), wReadF32(posPtr, vi*12+8)));
                    const QVector3D wn = world.mapVector(QVector3D(
                        wReadF32(normPtr,vi*12+0), wReadF32(normPtr,vi*12+4), wReadF32(normPtr,vi*12+8))).normalized();
                    verts.push_back({wp.x(),wp.y(),wp.z(), wn.x(),wn.y(),wn.z(), color.x(),color.y(),color.z()});
                }
                const int   idxCount = accCount(idxAcc);
                const uchar *idxPtr  = accOffset(idxAcc);
                const int   ct       = accCompType(idxAcc);
                for (int ii = 0; ii < idxCount; ++ii) {
                    uint32_t idx = (ct == 5123) ? wReadU16(idxPtr, ii*2) : wReadU32(idxPtr, ii*4);
                    indices.push_back(static_cast<uint16_t>(baseVert + idx));
                }
            }
        }
        for (const QJsonValue &ch : node["children"].toArray()) traverse(ch.toInt(), world);
    };

    for (const QJsonValue &rn : sceneNodes) traverse(rn.toInt(), QMatrix4x4{});

    m_indexCount = int(indices.size());
    qDebug("[bread-gl-win] loaded %zu verts, %d tris", verts.size(), m_indexCount / 3);

    glGenBuffers(1, &m_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
    glBufferData(GL_ARRAY_BUFFER, GLsizeiptr(verts.size() * sizeof(WVertex)), verts.data(), GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glGenBuffers(1, &m_ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, GLsizeiptr(indices.size() * sizeof(uint16_t)), indices.data(), GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}
