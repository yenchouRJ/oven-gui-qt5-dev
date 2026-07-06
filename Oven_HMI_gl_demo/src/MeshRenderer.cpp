/**
 * @file MeshRenderer.cpp
 * @brief Direct-OpenGL renderer for the bread model.
 *
 * GLB node hierarchy of bread.glb (relevant nodes):
 *   node[3] Bakery  (parent): T(0.124, 0.787,-0.200)  S=1.826
 *     node[0] Cube.079 mesh=0  T(0.076,-0.025, 0)  R(q)  S=0.225  color #cc4f17
 *     node[1] Cube.080 mesh=1  T(0.076,-0.025, 0)  R(q)  S=0.278  color #6d2007
 *     node[2] Cube.099 mesh=2  T(-0.452,0.169,0.417) R(q) S=0.399 color #4f1805
 *   node[5] Empty   (parent): T(0, 2.490, 0)  S=4.964
 *     node[4] Plane.001 mesh=3  T(0,-0.711,0)  S=0.658  color #8a7060
 *
 * Copyright (c) 2026 Defond Electrical Industries Limited
 */

#include "MeshRenderer.h"
#include "MeshView.h"

#include <QOpenGLFramebufferObject>
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
#include <cmath>

// ---------------------------------------------------------------------------
// Inline GLSL ES 1.00 shaders
// ---------------------------------------------------------------------------

static const char *VERT_SRC = R"GLSL(
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
    // u_model is a pure rotation (Y*X), so mat3(u_model) is a valid normal matrix.
    v_nw    = mat3(u_model) * a_normal;
    v_color = a_color;
}
)GLSL";

static const char *FRAG_SRC = R"GLSL(
precision mediump float;

varying vec3 v_nw;
varying vec3 v_color;

void main()
{
    vec3  n     = normalize(v_nw);
    // Fixed directional light from upper-right-front in world space.
    vec3  L     = normalize(vec3(1.0, 2.0, 1.5));
    float nDotL = max(dot(n, L), 0.0);
    vec3  col   = v_color * (0.35 + 0.75 * nDotL);
    gl_FragColor = vec4(col, 1.0);
}
)GLSL";

// ---------------------------------------------------------------------------
// Helper: read little-endian uint32 from a byte buffer
// ---------------------------------------------------------------------------
static inline uint32_t readU32(const uchar *d, int off)
{
    return  uint32_t(d[off])
         | (uint32_t(d[off+1]) << 8)
         | (uint32_t(d[off+2]) << 16)
         | (uint32_t(d[off+3]) << 24);
}
static inline uint16_t readU16(const uchar *d, int off)
{
    return uint16_t(d[off]) | uint16_t(uint16_t(d[off+1]) << 8);
}
static inline float readF32(const uchar *d, int off)
{
    float v; std::memcpy(&v, d + off, 4); return v;
}

// ---------------------------------------------------------------------------
// Node-transform helper
// ---------------------------------------------------------------------------
static QMatrix4x4 nodeLocalTransform(const QJsonObject &node)
{
    QMatrix4x4 m;
    QJsonArray t = node["translation"].toArray();
    QJsonArray r = node["rotation"].toArray();
    QJsonArray s = node["scale"].toArray();

    if (!t.isEmpty())
        m.translate(float(t[0].toDouble()),
                    float(t[1].toDouble()),
                    float(t[2].toDouble()));
    if (!r.isEmpty()) {
        // GLB quaternion is [x, y, z, w]
        QQuaternion q(float(r[3].toDouble()),
                      float(r[0].toDouble()),
                      float(r[1].toDouble()),
                      float(r[2].toDouble()));
        m.rotate(q);
    }
    if (!s.isEmpty())
        m.scale(float(s[0].toDouble()),
                float(s[1].toDouble()),
                float(s[2].toDouble()));
    return m;
}

// ---------------------------------------------------------------------------
// Per-mesh baked colors (from Bread.qml PrincipledMaterial baseColor)
// mesh index → vec3 linear color
// ---------------------------------------------------------------------------
static QVector3D meshColor(int meshIdx)
{
    switch (meshIdx) {
        case 0:  return {0.800f, 0.310f, 0.090f};  // #cc4f17 crust top
        case 1:  return {0.427f, 0.125f, 0.027f};  // #6d2007 crust bottom
        case 2:  return {0.310f, 0.094f, 0.020f};  // #4f1805 inner crumb
        default: return {0.540f, 0.440f, 0.376f};  // #8a7060 board/plane
    }
}

// ---------------------------------------------------------------------------
// Interleaved vertex: position(3f) + normal(3f) + color(3f) = 9 floats = 36 B
// ---------------------------------------------------------------------------
struct Vertex {
    float px, py, pz;
    float nx, ny, nz;
    float cr, cg, cb;
};

// ---------------------------------------------------------------------------
// MeshRenderer
// ---------------------------------------------------------------------------

MeshRenderer::MeshRenderer() = default;

MeshRenderer::~MeshRenderer()
{
    if (m_vao) glDeleteVertexArrays(1, &m_vao);
    if (m_vbo) glDeleteBuffers(1, &m_vbo);
    if (m_ibo) glDeleteBuffers(1, &m_ibo);
    delete m_prog;
}

// Called while the GUI thread is paused — safe to copy QML item state.
void MeshRenderer::synchronize(QQuickFramebufferObject *item)
{
    auto *view = static_cast<MeshView *>(item);
    m_angle = view->angle();
    m_tilt  = view->tilt();
}

// ---------------------------------------------------------------------------
// render() — called every frame on the render thread
// ---------------------------------------------------------------------------
void MeshRenderer::render()
{
    if (!m_initialized) {
        initializeOpenGLFunctions();
        m_frameTimer.start();
        m_prevFrameStart = 0;
        initGL();
        loadBread();
        // ---- VAO: record attribute format once -----------------------------
        glGenVertexArrays(1, &m_vao);
        glBindVertexArray(m_vao);
        glBindBuffer(GL_ARRAY_BUFFER,         m_vbo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_ibo);
        constexpr GLsizei vstride = sizeof(Vertex);
        glEnableVertexAttribArray(m_attrPos);
        glEnableVertexAttribArray(m_attrNormal);
        glEnableVertexAttribArray(m_attrColor);
        glVertexAttribPointer(m_attrPos,    3, GL_FLOAT, GL_FALSE, vstride, reinterpret_cast<void *>(0));
        glVertexAttribPointer(m_attrNormal, 3, GL_FLOAT, GL_FALSE, vstride, reinterpret_cast<void *>(12));
        glVertexAttribPointer(m_attrColor,  3, GL_FLOAT, GL_FALSE, vstride, reinterpret_cast<void *>(24));
        glBindVertexArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        qDebug() << "bread-gl-demo: GL context:"
                 << reinterpret_cast<const char *>(glGetString(GL_VERSION));
        m_initialized = true;
    }

    // ------------------------------------------------------------------
    // Timing probe — measure frame interval, clear, and draw separately
    // ------------------------------------------------------------------
    const qint64 frameStart    = m_frameTimer.elapsed();
    const qint64 frameInterval = frameStart - m_prevFrameStart;
    m_prevFrameStart = frameStart;

    if (!m_prog || m_indexCount == 0 || !m_vao) return;

    // Viewport from FBO size
    const QSize sz = framebufferObject()->size();
    glViewport(0, 0, sz.width(), sz.height());

    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glDisable(GL_BLEND);

    // ---- Split timing: clear -----------------------------------------------
    glClearColor(0.08f, 0.08f, 0.14f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glFinish();
    const qint64 tClear = m_frameTimer.elapsed() - frameStart;

    // ---- Uniforms -----------------------------------------------------------
    m_prog->bind();

    QMatrix4x4 model;
    model.rotate(m_angle, 0.f, 1.f, 0.f);   // Y spin
    model.rotate(m_tilt,  1.f, 0.f, 0.f);   // X tilt

    const float aspect = sz.width() / float(sz.height() ? sz.height() : 1);
    QMatrix4x4 proj;
    proj.perspective(45.f, aspect, 0.1f, 50.f);

    QMatrix4x4 view;
    view.lookAt({0.f, 1.5f, 7.f}, {0.f, 0.4f, 0.f}, {0.f, 1.f, 0.f});

    m_prog->setUniformValue(m_locModel,    model);
    m_prog->setUniformValue(m_locViewProj, proj * view);

    // ---- Split timing: draw (VAO path — no per-frame attribute setup) -------
    const qint64 td0 = m_frameTimer.elapsed();

    glBindVertexArray(m_vao);
    glDrawElements(GL_TRIANGLES, m_indexCount, GL_UNSIGNED_SHORT, nullptr);
    glBindVertexArray(0);
    glFinish();

    const qint64 tDraw = m_frameTimer.elapsed() - td0;

    m_prog->release();

    ++m_frameIdx;
    if (m_frameIdx % 30 == 0) {
        qDebug("[bread-gl-demo] frame %4d  tClear=%.1f ms  tDraw=%.1f ms  "
               "interval=%.1f ms  FPS~%.1f",
               m_frameIdx, float(tClear), float(tDraw),
               float(frameInterval),
               frameInterval > 0 ? 1000.f / float(frameInterval) : 0.f);
    }

    // Tell Qt Quick to keep rendering continuously.
    update();
}

// ---------------------------------------------------------------------------
// initGL — compile shaders, cache locations
// ---------------------------------------------------------------------------
void MeshRenderer::initGL()
{
    m_prog = new QOpenGLShaderProgram();
    if (!m_prog->addShaderFromSourceCode(QOpenGLShader::Vertex,   VERT_SRC) ||
        !m_prog->addShaderFromSourceCode(QOpenGLShader::Fragment, FRAG_SRC) ||
        !m_prog->link())
    {
        qCritical() << "bread-gl-demo: shader link failed:" << m_prog->log();
        delete m_prog;
        m_prog = nullptr;
        return;
    }

    m_locModel    = m_prog->uniformLocation("u_model");
    m_locViewProj = m_prog->uniformLocation("u_viewProj");
    m_attrPos     = m_prog->attributeLocation("a_position");
    m_attrNormal  = m_prog->attributeLocation("a_normal");
    m_attrColor   = m_prog->attributeLocation("a_color");
}

// ---------------------------------------------------------------------------
// loadBread — parse bread.glb, pre-transform vertices, upload VBO/IBO
// ---------------------------------------------------------------------------
void MeshRenderer::loadBread()
{
    // ---- Read file from Qt resources ----------------------------------------
    QFile f(QStringLiteral(":/assets/models/bread.glb"));
    if (!f.open(QIODevice::ReadOnly)) {
        qCritical() << "bread-gl-demo: cannot open :/assets/models/bread.glb";
        return;
    }
    const QByteArray glbData = f.readAll();
    f.close();

    const auto *raw = reinterpret_cast<const uchar *>(glbData.constData());
    const int   len = glbData.size();

    // ---- GLB header ---------------------------------------------------------
    if (len < 20) { qCritical() << "bread-gl-demo: GLB too small"; return; }
    const uint32_t magic = readU32(raw, 0);
    if (magic != 0x46546C67u) {   // "glTF"
        qCritical() << "bread-gl-demo: bad GLB magic" << Qt::hex << magic;
        return;
    }

    // ---- JSON chunk (chunk 0) -----------------------------------------------
    const uint32_t jsonLen  = readU32(raw, 12);
    const int      jsonOff  = 20;
    const QByteArray jsonBytes = QByteArray::fromRawData(
        reinterpret_cast<const char *>(raw + jsonOff), int(jsonLen));
    const QJsonObject root = QJsonDocument::fromJson(jsonBytes).object();

    // ---- BIN chunk (chunk 1) ------------------------------------------------
    const int      binChunkOff = jsonOff + int(jsonLen);
    const uint32_t binLen      = readU32(raw, binChunkOff);
    const uchar   *bin         = raw + binChunkOff + 8;

    // ---- Parse glTF arrays --------------------------------------------------
    const QJsonArray accessors   = root["accessors"].toArray();
    const QJsonArray bufferViews = root["bufferViews"].toArray();
    const QJsonArray nodes       = root["nodes"].toArray();
    const QJsonArray meshes      = root["meshes"].toArray();
    const QJsonArray sceneNodes  = root["scenes"].toArray()
                                       .at(root["scene"].toInt()).toObject()
                                       ["nodes"].toArray();

    // Helper: extract a typed slice from the BIN chunk via accessor index
    // Returns raw pointer into bin at the correct byte offset.
    auto accOffset = [&](int idx) -> const uchar * {
        const QJsonObject acc = accessors[idx].toObject();
        const QJsonObject bv  = bufferViews[acc["bufferView"].toInt()].toObject();
        return bin + bv["byteOffset"].toInt() + acc["byteOffset"].toInt(0);
    };
    auto accCount = [&](int idx) -> int {
        return accessors[idx].toObject()["count"].toInt();
    };
    auto accCompType = [&](int idx) -> int {
        return accessors[idx].toObject()["componentType"].toInt();
    };

    // ---- Build combined VBO + IBO by traversing node hierarchy --------------
    std::vector<Vertex>   verts;
    std::vector<uint16_t> indices;

    // Recursive node traversal
    std::function<void(int, QMatrix4x4)> traverse =
        [&](int nodeIdx, QMatrix4x4 parentWorld)
    {
        const QJsonObject node = nodes[nodeIdx].toObject();
        const QMatrix4x4  world = parentWorld * nodeLocalTransform(node);

        // If this node references a mesh, extract and transform its geometry
        const QJsonValue meshVal = node["mesh"];
        if (!meshVal.isUndefined()) {
            const int meshIdx = meshVal.toInt();
            const QJsonObject mesh = meshes[meshIdx].toObject();
            const QVector3D color  = meshColor(meshIdx);

            // Each GLB mesh has exactly one primitive here (confirmed by inspection)
            for (const QJsonValue &primVal : mesh["primitives"].toArray()) {
                const QJsonObject prim = primVal.toObject();
                const QJsonObject attrs = prim["attributes"].toObject();

                const int posAcc  = attrs["POSITION"].toInt();
                const int normAcc = attrs["NORMAL"].toInt();
                const int idxAcc  = prim["indices"].toInt();

                const int   vCount   = accCount(posAcc);
                const uchar *posPtr  = accOffset(posAcc);
                const uchar *normPtr = accOffset(normAcc);

                // Base vertex index for this mesh within the combined VBO
                const auto baseVert = static_cast<uint16_t>(verts.size());

                // Compute the 3×3 rotation/scale sub-matrix for normal transform.
                // All node scales are uniform, so this equals mat3(world).
                const QMatrix4x4 &wm = world;
                // mat3(world): column-major in Qt is [m(0,0) m(1,0) m(2,0) ...]
                // QMatrix4x4(row,col) accessor used below.

                for (int vi = 0; vi < vCount; ++vi) {
                    const float px = readF32(posPtr,  vi * 12 + 0);
                    const float py = readF32(posPtr,  vi * 12 + 4);
                    const float pz = readF32(posPtr,  vi * 12 + 8);
                    const float nx = readF32(normPtr, vi * 12 + 0);
                    const float ny = readF32(normPtr, vi * 12 + 4);
                    const float nz = readF32(normPtr, vi * 12 + 8);

                    // Transform position into world space
                    const QVector3D wp = wm.map(QVector3D(px, py, pz));

                    // Transform normal (uniform scale → mat3(world) is correct)
                    // QMatrix4x4::mapVector does M * v (homogeneous w=0, no translate)
                    const QVector3D wn = wm.mapVector(QVector3D(nx, ny, nz)).normalized();

                    verts.push_back({wp.x(), wp.y(), wp.z(),
                                     wn.x(), wn.y(), wn.z(),
                                     color.x(), color.y(), color.z()});
                }

                // Indices — may be uint16 (5123) or uint32 (5125)
                const int idxCount = accCount(idxAcc);
                const uchar *idxPtr = accOffset(idxAcc);
                const int    ct     = accCompType(idxAcc);

                for (int ii = 0; ii < idxCount; ++ii) {
                    uint32_t idx = 0;
                    if (ct == 5123)       idx = readU16(idxPtr, ii * 2);
                    else if (ct == 5125)  idx = readU32(idxPtr, ii * 4);
                    indices.push_back(static_cast<uint16_t>(baseVert + idx));
                }
            }
        }

        // Recurse into children
        for (const QJsonValue &ch : node["children"].toArray())
            traverse(ch.toInt(), world);
    };

    for (const QJsonValue &rootNode : sceneNodes)
        traverse(rootNode.toInt(), QMatrix4x4{});

    m_indexCount = static_cast<int>(indices.size());
    qDebug() << "bread-gl-demo: loaded" << verts.size() << "verts,"
             << (m_indexCount / 3) << "tris";

    // ---- Upload to GPU (CPU for llvmpipe) -----------------------------------
    glGenBuffers(1, &m_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
    glBufferData(GL_ARRAY_BUFFER,
                 GLsizeiptr(verts.size() * sizeof(Vertex)),
                 verts.data(), GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glGenBuffers(1, &m_ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                 GLsizeiptr(indices.size() * sizeof(uint16_t)),
                 indices.data(), GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}
