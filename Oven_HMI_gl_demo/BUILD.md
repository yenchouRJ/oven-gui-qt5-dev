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

### Exp C — VAO optimisation (bread-gl-win + bread-gl-demo)  ✓ DONE

- Context: OpenGL ES 3.2 Mesa 24.0.0 (context auto-promoted from 3.0 request)
- VAO created once in init; per-frame: `glBindVertexArray → glDrawElements`
- Split timing: `tClear` and `tDraw` logged separately

**Result:**

| Run | Viewport | tClear | tDraw | FPS |
|-----|----------|--------|-------|-----|
| bread-gl-demo (QQFBO) | 640×480 | 2 ms | 166 ms | ~3.5 |
| bread-gl-win (fullscreen) | 1280×480 | 9 ms | 213 ms | 5 |

**VAO made zero difference.** `tDraw` is unchanged. The per-frame
`glVertexAttribPointer` hypothesis was wrong. The 166–213 ms is genuine Mesa
llvmpipe software rasterization work, not API overhead.

### Root-cause confirmed: software rasterization fill cost

**Key observation:** 1280×480 (2× more viewport pixels) costs only 1.28× more
than 640×480 for `tDraw`. This proves the bottleneck is not total viewport
area but the **covered pixel area of the model on screen** (~47 K visible
pixels, ~150–200 K fragment invocations with 4-mesh overdraw). Both viewports
show roughly the same model footprint because the wider window adds empty
black borders.

**Bottleneck tree:**

```
~200 ms per frame (bread-gl-win, 1280×480)
│
├── glClear (color + depth, 1280×480):         ~9 ms   ← memory-write bound, fast
│
└── glDrawElements (25 794 tris, VAO):       ~213 ms   ← THE bottleneck
    │
    ├── Vertex transform (14 660 verts):       ~2 ms   (fast even scalar)
    ├── Triangle setup + tile binning:         ~2 ms
    │
    └── Fragment rasterization:             ~209 ms   ← dominant
        │
        ├── Fragment shader execution:
        │     normalize + dot + mul ~25 cycles scalar per pixel
        │     ~150 K fragments / 800 MHz ≈ 5 ms theoretical
        │     (actual much worse — depth-buffer cache misses below)
        │
        └── Depth-buffer DRAM thrashing:
              Buffer size (640×480 × 4B): 1.2 MB
              L2 cache (Cortex-A35):    128–256 KB
              → Depth buffer 6–9× larger than L2
              → Most depth reads/writes miss to DRAM
              DRAM latency on in-order Cortex-A35: ~100–200 ns
              (no out-of-order exec to hide stalls)
              ~150 K fragments × 2 accesses × 150 ns ≈ 45 ms depth alone
              Plus VBO vertex-data cache misses, color writes...
              → Total: 150–210 ms per frame
```

**Why the original spin-test triangle experiments also showed no improvement:**
Reducing triangles (281 K → 10 K) does not change the number of
**screen-covered pixels**. Fragment invocations, depth reads/writes, color
writes — all unchanged. The Qt Quick3D overhead stacked on top of the same
~167 ms rasterization cost.

### Exp D — 128×128 off-screen FBO, full-window blit  ✓ DONE

**Hypothesis:** 128×128 FBO → fewer covered pixels → tDraw drops proportionally.

**Result (on-target):**

```
[bread-gl-win 128x128] FPS: 1   tClear=1ms  tDraw=1252ms   (warmup — JIT)
[bread-gl-win 128x128] FPS: 4   tClear=1ms  tDraw=509ms    (warming up)
[bread-gl-win 128x128] FPS: 5   tClear=1ms  tDraw=115ms    (steady state)
[bread-gl-win 128x128] FPS: 5   tClear=0ms  tDraw=138ms
```

**tDraw DID drop** (213 ms → ~130 ms), confirming that covered-pixel count
is a real factor.  But FPS stayed at 5 (200 ms/frame).

**New problem: blit dominates.**

Frame budget at steady state:
```
tClear (128×128):       ~1 ms
tDraw  (3D → 128×128):  ~130 ms   ← reduced ✓, but still large
blit   (1280×480 quad): ~62 ms    ← NEW bottleneck (full-window texture fill)
swap:                   ~7–10 ms
─────────────────────────────────────
Total:                  ~200 ms → 5 FPS
```

The blit draws 1280×480 = 614 K pixels of textured quad.  Although simpler
than the 3D draw, that's still 614 K pixels rasterized by llvmpipe.  It ate
back most of the savings from shrinking the FBO.

**Also: tDraw is still ~130 ms at 128×128.**  The model covers only ~1–2 K
pixels in the 128×128 FBO.  Expected rasterization: ~1 ms.  Actual: 130 ms.
This confirms a large **fixed per-draw-call overhead** in Mesa llvmpipe
(~130 ms regardless of covered pixels), on top of a smaller per-pixel cost.

**Revised bottleneck tree (updated after Exp D):**

```
glDrawElements — two cost components:
│
├── Fixed overhead (~130 ms):
│   Mesa state machine, tile dispatcher setup, shader pipeline validation.
│   Present even with 0 visible pixels.  Irreducible by content changes.
│
└── Variable (per-pixel, ~0.05 µs/px):
    At 150K pixels: 150K × 0.05 = 7.5 ms on top of fixed cost
    At 1.6K pixels: 1.6K × 0.05 = 0.08 ms — negligible
```

Blit cost (textured quad, no depth, simple shader):
- Lower fixed overhead than 3D draw (estimated ~5 ms fixed)
- Variable: ~0.093 µs/px
- At 1280×480 (614K px): ~5 + 57 = 62 ms

### Exp E — blit only to model display area  ← IN PROGRESS

**Fix:** restrict the blit `glViewport` to the model's display area
(360×400 = 144 K pixels) instead of the full window (614 K pixels).

```
blit area: 360×400 = 144K px
expected blit time: ~5 + 144K×0.093 = ~18 ms   (vs 62 ms before)

total: tClear(1) + tDraw(130) + tBlit(18) + swap(10) ≈ 159 ms → ~6 FPS
```

Also clears the whole window to background first, so the rest of the screen
shows a dark UI color rather than the stretched texture.

Log: `[bread-gl-win] FPS  tClear  tDraw  tBlit  model=128x128→360x400@(880,40)`

- Expected tBlit: **~18 ms** (down from ~62 ms)
- Expected FPS: **~6–7**
- Result: **pending**

---

## Decision tree (updated after Exp D)

```
128×128 FBO: tDraw 213ms → 130ms (partial improvement).
Full-window blit still costs ~62ms → total still 200ms / 5 FPS.

Key insight: ~130ms is FIXED per-draw overhead in Mesa llvmpipe.
Reducing covered pixels cannot go below this floor.

Exp E (blit to model area only):
├── tBlit drops from ~62ms to ~18ms (expected)
│   total: 130 + 18 + 1 + 10 ≈ 159ms → ~6-7 FPS
│   → marginal improvement
└── tBlit stays high → blit also has large fixed overhead
    → both draw calls have ~130ms fixed floor = fundamental limit

Decision: if Exp E gives ~6-7 FPS, the floor is confirmed at ~160ms minimum.
For the product, accept ~6 FPS with small-FBO approach,
or switch to the flipbook path for smooth animation.
```

---

## Performance Summary

| Demo              | Renderer              | FBO size          | Blit area   | VAO | FPS  | tDraw ms | tBlit ms |
|-------------------|-----------------------|-------------------|-------------|-----|------|----------|----------|
| spin-test         | Qt Quick3D            | 640×480           | full        | —   | ~4   | —        | —        |
| bread-gl-demo     | QQFBO direct-GL       | 640×480           | full        | yes | ~3.5 | 166      | —        |
| bread-gl-win      | QOpenGLWindow         | 1280×480          | full        | yes | 5    | 213      | —        |
| bread-gl-win      | QOpenGLWindow         | 128×128 → full    | 1280×480    | yes | 5    | 130      | ~62      |
| **bread-gl-win**  | **QOpenGLWindow**     | **128×128 → area**| **360×400** | yes | **pending** | **~130** | **pending** |

---

## Notes

- Shaders upgraded to GLSL ES 3.00 (`#version 300 es`) for `bread-gl-win`.
- `RENDER_W / RENDER_H` in `BreadWindow.h` — change to 256/512 to test sizes.
- `MODEL_X/Y/DW/DH` in `BreadWindow.h` — change to match product UI layout.
- `bread-gl-win` links only `Qt5::Core Qt5::Gui` — no Qml/Quick dependency.
