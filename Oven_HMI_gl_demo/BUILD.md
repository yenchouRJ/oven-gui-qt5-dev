# bread-gl-demo — BUILD LOG

## Goal

Bypass Qt Quick3D entirely (confirmed bottleneck in spin-test) and measure
whether the 4-FPS ceiling is in Qt Quick's overhead or in Mesa llvmpipe /
EGLFS display swap.

Two binaries are built to isolate the layer:

| Binary          | Stack                                    |
|-----------------|------------------------------------------|
| `bread-gl-demo` | Qt Quick → QQFBO → our `glDrawElements` |
| `bread-gl-win`  | QOpenGLWindow → our `glDrawElements`    |

If `bread-gl-win` (no Qt Quick at all) is also ~4 FPS, the bottleneck is in
Mesa llvmpipe rendering or `eglSwapBuffers()`.  If it is substantially faster,
Qt Quick's scene-graph sync / V4 JS is the remaining overhead.

Both binaries set `swapInterval(0)` to prevent vsync from capping the
measurement artificially.

---

## Model

`bread.glb` — original (un-decimated) quality.

| Metric       | Value                      |
|--------------|----------------------------|
| Meshes       | 4                          |
| Vertices     | 14 660                     |
| Triangles    | 25 794                     |
| Index type   | uint16                     |
| VBO layout   | pos(3f)+normal(3f)+color(3f) = 36 B/vert |
| VBO size     | ~515 KB                    |
| IBO size     | ~151 KB                    |

Node hierarchy baked into world-space VBO at load time (not re-evaluated per
frame):

```
Bakery  T(0.124, 0.787,-0.200) S=1.826
  Cube.079  mesh=0  S=0.225  T/R  color #cc4f17 (crust top)
  Cube.080  mesh=1  S=0.278  T/R  color #6d2007 (crust bottom)
  Cube.099  mesh=2  S=0.399  T/R  color #4f1805 (inner crumb)
Empty   T(0, 2.490, 0) S=4.964
  Plane.001 mesh=3  S=0.658       color #8a7060 (board)
```

---

## Architecture

### bread-gl-demo (Qt Quick + QQFBO)

```
QML: NumberAnimation → setAngle() → update()
     ↓  synchronize() on render thread (copy 2 floats)
     ↓  render(): glClear + setUniform×2 + glDrawElements
```

Timing probe: `glFinish()` + `QElapsedTimer` in `render()` logs `gl=X ms
interval=Y ms` every 30 frames.  If `gl` << `interval`, the bottleneck is
outside our GL work.

### bread-gl-win (QOpenGLWindow, no Qt Quick)

```
paintGL(): glClear + setUniform×2 + glDrawElements → update()
```

No QML engine, no V4 JS, no scene-graph sync.  Pure OpenGL → EGL swap.

---

## Build

```bash
cd Oven_HMI_gl_demo/build
cmake .. -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE=/home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5/output/host/usr/share/buildroot/toolchainfile.cmake \
  -DQt5_DIR=/home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5/output/host/usr/lib/cmake/Qt5
make -j$(nproc)
# Produces: bread-gl-demo  bread-gl-win
```

### Run on MA35D1

```bash
QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./bread-gl-demo
QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./bread-gl-win
```

`MESA-LOADER: failed to open ma35-drm` at startup is harmless.

---

## Experiment log

### Exp A — `bread-gl-demo` (QQFBO, swapInterval=0)  ✓ DONE

- Renderer: QQuickFramebufferObject, 1 glDrawElements, swapInterval=0
- FPS on-target: **~3.5** (interval ≈ 289 ms)
- `gl=` (pure GL cost, glFinish-timed): **167 ms**
- Qt Quick overhead: 289 − 167 = **122 ms** (scene-graph sync, FBO composite, swap)

Key finding: our GL work itself takes 167 ms — this is the dominant cost, not
Qt Quick overhead.

### Exp B — `bread-gl-win` (QOpenGLWindow, no Qt Quick)  ✓ DONE

- Renderer: QOpenGLWindow::paintGL(), swapInterval=0
- FPS on-target: **5** (≈ 200 ms/frame)
- Interpretation: 200 ms ≈ 167 ms GL + ~33 ms eglSwapBuffers

**Conclusion**: Qt Quick is NOT the bottleneck. Mesa llvmpipe is taking
167 ms for each frame's GL work. Qt Quick removal saves ~89 ms (289→200 ms)
but the ceiling is the 167 ms GL cost.

---

## Root-cause analysis — why 167 ms?

### Pixel-fill hypothesis: ruled out

QQFBO renders to 640×480 (307 K pixels); `bread-gl-win` renders to 1280×480
(614 K pixels, 2× more). Both take ≈ 167 ms of GL. If fill-rate were the
bottleneck, doubling pixels would double time. It doesn't → **fill-rate is
not the bottleneck**.

### Most likely cause: per-frame `glVertexAttribPointer` calls

Our render path calls `glVertexAttribPointer` (×3) + `glEnableVertexAttribArray`
(×3) every frame.  In Mesa/Gallium3D each of these marks the vertex-element
CSO (Constant State Object) dirty.  On the next `glDrawElements`, llvmpipe
re-JITs the vertex-fetch pipeline via LLVM.  On the MA35D1 ARM CPU,
this re-compilation takes ~50 ms per dirty call × 3 calls ≈ 150 ms.

**Fix: Vertex Array Object (VAO).**  Encode the attribute format once in a
VAO; per frame only call `glBindVertexArray + glDrawElements`.  Zero
attribute-setup overhead per frame.

### Exp C — VAO optimisation (bread-gl-win + bread-gl-demo)  ← IN PROGRESS

- Context: request OpenGL ES 3.0 (VAO support)
- VAO created once in init; paintGL/render() reduced to:
  ```
  glClear → setUniforms → glBindVertexArray → glDrawElements → glBindVertexArray(0)
  ```
- Per-call split timing: `tClear` and `tDraw` logged separately every 30 frames
- Expected gl time: < 10 ms (tClear ≈ 2 ms, tDraw ≈ 1–5 ms)
- Expected FPS bread-gl-win: **> 30**
- Result: **pending**

---

## Decision tree (updated after Exp B)

```
gl=167ms confirmed in Exp A.  Pixel-fill ruled out (Exp A vs B comparison).

Exp C (VAO):
├── gl drops to < 10 ms → hypothesis confirmed; VAO = production fix
│   └── bread-gl-win becomes the production renderer
│       (drive animation from QElapsedTimer, touch via QTouchEvent)
└── gl still ≈ 167 ms → VAO did not help; investigate Mesa state further
    → Exp D: comment out glDrawElements (only glClear) to isolate clear cost
    → Exp E: tiny 128×128 window to check if ANY pixel reduction helps
```

---

## Performance Summary

| Demo            | Renderer              | Tris   | swapInt | VAO | FPS (MA35D1) | gl ms |
|-----------------|-----------------------|--------|---------|-----|--------------|-------|
| spin-test       | Qt Quick3D            | 281K   | default | —   | ~4           | —     |
| spin-test       | Qt Quick3D NoLighting | 10K    | default | —   | ~4           | —     |
| bread-gl-demo   | QQFBO direct-GL       | 25.8K  | 0       | no  | ~3.5         | 167   |
| bread-gl-win    | QOpenGLWindow         | 25.8K  | 0       | no  | 5            | ~167  |
| bread-gl-win    | QOpenGLWindow         | 25.8K  | 0       | yes | pending      | pending |
| bread-gl-demo   | QQFBO direct-GL       | 25.8K  | 0       | yes | pending      | pending |

---

## Notes

- GLSL shaders target ES 1.00 (`#version 100`), compatible with Mesa ES 2.0.
- `setMirrorVertically(true)` in `MeshView` corrects OpenGL FBO Y-flip.
- `update()` at end of `render()`/`paintGL()` drives continuous rendering.
- `bread-gl-win` links only `Qt5::Core Qt5::Gui` — no Qml/Quick dependency.
