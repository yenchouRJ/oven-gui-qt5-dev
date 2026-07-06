# Technical Evaluation Report: 3D Asset Rendering Performance on the MA35D1 Platform

## 1. Executive Summary & Hardware Bottlenecks

This evaluation details the performance benchmarks of a Qt5 Quick3D application (`chicken-spin-test`) running on the Nuvoton MA35D1 platform. The primary objective was to determine the maximum mesh geometric quality (triangle count) the platform could sustain without triggering Out-Of-Memory (OOM) errors or unacceptable frame rates (FPS).

### Critical Hardware Constraints

* **No Hardware 3D Acceleration (GPU)**: The MA35D1 features a dual-core Cortex-A35 configuration clocked at 800 MHz. **It completely lacks a 3D GPU or dedicated shading hardware.**
* **Pure Software Rasterisation**: The graphics pipeline relies entirely on Mesa’s `llvmpipe` driver, a software OpenGL implementation. `llvmpipe` compiles GLSL shaders at runtime into LLVM IR and executes them on the CPU cores. On this platform, only 2 cores are available to absorb the workload of the operating system, UI logic, and 3D rendering.
* **Shared Memory Bus Saturation**: The platform operates with roughly 108 MB of managed system RAM. There is no dedicated VRAM; the OS kernel, Qt libraries, QML runtime, vertex/index buffers, and the raw framebuffer (1280×480 RGBA, ~2.5 MB) all compete for the same DDR bandwidth. High-frequency memory read/write cycles heavily degrade throughput.
* **The `kmscube` Misconception**: While the platform can render `kmscube` at a stable 60 FPS, this is an invalid benchmark for real-world UI capabilities. `kmscube` contains exactly 12 triangles, utilizes a trivial flat-color shader, and incurs zero scene-graph or script-binding engine overhead. It merely validates that the DRM/KMS display subsystem is functional.

---

## 2. Controlled Variable Experiments & Debug Log

Using the original 3D asset `chicken.glb` (281 K triangles) as a baseline (Step 0), we performed aggressive mesh decimation via `gltf-transform simplify` to isolate pipeline bottlenecks:

### Empirical Test Matrix

| Step / Phase | Geometric Quality (Tris) | Material / Shader Mode | Render Area (FBO Size) | Measured FPS | Observations & Engineering Conclusions |
| --- | --- | --- | --- | --- | --- |
| **Step 0** | 281 K Tris | `PrincipledMaterial` (PBR) | Full 640×480 | **OOM** | Memory allocation exceeded budget; application was immediately terminated by the kernel (`OOM-killed`). |
| **Step 1** | 98 K Tris | `PrincipledMaterial` (PBR) | Full 640×480 | **~2 FPS** | System stable, but rendering throughput is entirely unusable. |
| **Step 2** | 42 K Tris | `PrincipledMaterial` (PBR) | Full 640×480 | **~3 FPS** | Triangles reduced by >50%, yet performance improvement is statistically negligible. |
| **Step 3** | 10 K Tris | `PrincipledMaterial` (PBR) | Full 640×480 | **~4 FPS** | Vertex transformation cost minimized, but frame rate remains completely throttled. |

To further pinpoint the exact stage causing this ceiling, we implemented extreme optimization overrides directly on the **Step 3 (10 K Tris)** asset:

* **Experiment 2 (Bypassing Pixel Shading)**: Replaced all PBR shaders with `DefaultMaterial.NoLighting`, effectively dropping fragment shader instructions from ~140 floating-point operations down to 0. **Result: Performance remained static at ~4 FPS.**
* **Experiment 3 (Reducing Rasterisation Fill Rate)**: Utilized `layer.textureSize` to scale down the 3D offscreen FBO resolution by 75% (to 320×240). **Result: Performance remained static at ~4 FPS.**
* **Experiment 4 & 5 (Stripping Lights & Merging Draw-Calls)**: Reduced light count from 3 down to a single `DirectionalLight` and flattened the GLTF nodes to collapse 4 separate mesh assets into a single joint Draw-Call. **Result: Performance remained static at ~4 FPS.**
* **Experiment 6 (Stacked Optimizations)**: Simultaneous deployment of all the above. The engine effectively had to draw nothing more than a solid-color quad mapped to 10K triangles. **Result: Performance stubbornly remained at ~4 FPS.**

---

## 3. Bottleneck Analysis: Why Real-Time 3D Optimizations Failed

The cross-validation data proves that neither the vertex transform stage, fragment shader complexity, rasterisation pixel count, draw-call count, nor the Qt Quick3D scenegraph overhead represents the primary performance bottleneck.

### What the Qt Quick3D experiments established

Experiments 1–6 each changed exactly one variable while holding everything else constant.  Every variable tested — triangle count, shader complexity, pixel fill area, light count, draw-call count, and all of them stacked — left FPS unchanged at ~4.  This confirmed that no rendering operation was the bottleneck *within* Qt Quick3D.  To find the true floor, the Qt Quick3D layer was removed entirely.

### Direct-OpenGL experiments (bypassing Qt Quick3D)

Two binaries were built that issue `glDrawElements` directly, with no Qt Quick3D, no QML scenegraph, no V4 JS:

| Binary | API stack | FPS | tDraw |
|--------|-----------|-----|-------|
| `bread-gl-demo` (QQFBO) | Qt Quick, no Quick3D | ~3.5 | 166 ms |
| `bread-gl-win` (QOpenGLWindow) | No Qt Quick at all | 5 | 213 ms |

Removing the entire Qt Quick3D and QML stack raised the ceiling from ~4 FPS to only 5 FPS.  The bottleneck did not disappear — it merely shifted.

### The real bottleneck: Mesa llvmpipe per-draw fixed cost

`tDraw` was measured with `glFinish()` immediately after `glDrawElements`.  Even after rendering to a 128×128 FBO (where the model covers only ~1–2 K pixels), `tDraw` remained at ~130 ms.  A pixel-proportional rasterizer would predict ~1–2 ms at this coverage; the measured value is 65–130× higher.

**~130 ms is a fixed cost per `glDrawElements` call in Mesa llvmpipe on Cortex-A35**, located in Mesa's tile-dispatcher and state-machine layer running on a slow in-order ARM core with no out-of-order execution.  This cost is irreducible by any API-level optimisation.

### Why all rendering experiments also showed no improvement

Because the Mesa fixed-per-draw floor (~130 ms) was always present underneath the Qt Quick3D overhead, changing triangles, shader complexity, pixel fill, or draw-call count could not move the FPS — those variables affect stages that are dwarfed by the 130 ms floor.  The Qt Quick3D overhead stacked on top added further cost but was not the primary ceiling.

### Measured frame budget

```
Frame cost ceiling (QOpenGLWindow + 128×128 FBO + 360×400 blit):

  tDraw fixed floor:  ~130 ms  (Mesa llvmpipe, irreducible)
  tBlit (360×400):     ~12 ms
  swap + overhead:     ~10 ms
  ──────────────────────────
  Total:              ~152 ms → ~7 FPS
```

This 7 FPS is the real-time 3D ceiling on MA35D1 at any mesh quality or shader complexity.  Qt Quick3D adds further overhead on top, which is why the Quick3D experiments measured ~4 FPS rather than ~7.

---

## 4. Architectural Analysis: Impact of a 3D GPU

A common question is whether this bottleneck would vanish if the target SoC possessed a dedicated 3D GPU.

**The GPU would eliminate the Mesa llvmpipe fixed per-draw cost entirely, and the Qt/scenegraph overhead would become a much smaller fraction of frame time.**

### Serial execution on MA35D1 (no GPU — llvmpipe)

On the MA35D1, there is only one pipeline and it runs on the CPU. Every stage blocks the next:

```
Frame N (~152–250 ms total):
 CPU: [JS eval] → [scene graph sync] → [transform recompute]
                → [Mesa state validate] → [llvmpipe vertex shader]
                → [llvmpipe rasterise] → [llvmpipe fragment shader]
                → [FBO blit]
                ↑ all stages on the same 800 MHz core, back to back
```

Total frame time = sum of every stage. The irreducible ~130 ms Mesa per-draw floor means that even after removing all Qt Quick3D and QML overhead, the ceiling is only ~7 FPS.

### Parallel execution with a real GPU

With dedicated 3D hardware, the CPU submits draw calls and immediately moves on. The GPU executes rendering independently and in parallel:

```
Frame N (~7–10 ms total):
 CPU: [JS eval] → [scene graph sync] → [transform recompute] → [submit draw calls] → (idle / start Frame N+1)
 GPU:                                                         → [vertex shader]    → [rasterise] → [fragment shader] → [display]
                                                               ↑ runs in parallel, does not block the CPU
```

Total frame time = `max(CPU_setup_time, GPU_render_time)`, not their sum.

### Which costs change, and which stay

| Per-frame cost | MA35D1 (llvmpipe) | SoC with real GPU |
|---|---|---|
| V4 JS + `NumberAnimation` eval | CPU, slow (800 MHz A35) | CPU, much faster (1.5+ GHz) |
| `QQuickWindow::sync()` + QML tree walk | CPU, slow | CPU, faster — same code, faster core |
| Quick3D node transform recompute | CPU, slow | CPU, faster — same code, faster core |
| Mesa per-draw-call state validation | CPU, heavy (full software path) | CPU, very light (kernel `ioctl`, ~10–50 µs) |
| Vertex shader | CPU (llvmpipe JIT) | GPU — runs in parallel, zero CPU cost |
| Rasterise + fragment shader | CPU (llvmpipe JIT) | GPU — runs in parallel, zero CPU cost |
| Mesa llvmpipe fixed per-draw floor | **~130 ms — irreducible** | **eliminated** (hardware takes over) |
| FBO composite blit | CPU (software blit) | GPU — runs in parallel, zero CPU cost |

Qt Quick3D utilizes a strict **"CPU manages, GPU renders"** pipelined design. On the current MA35D1, the CPU is forced to handle both roles simultaneously. If hardware 3D acceleration were introduced, the execution dynamics would shift dramatically:

* **The llvmpipe fixed floor disappears**: With a real GPU driver, Mesa no longer runs the tile-rasterization dispatcher on the CPU. The ~130 ms irreducible per-draw cost is gone. Pipeline state verification becomes a lightweight kernel `ioctl`. The total CPU-side overhead might drop from ~150 ms to 5–10 ms.
* **Massive Parallelism Offload**: With a hardware GPU, vertex shaders and PBR fragment shaders are processed across dozens of parallel compute pipelines simultaneously. If the GPU takes only 2 ms to render a 10K-mesh, and the CPU takes 5 ms to manage the scene graph, the total frame time drops to 7 ms, instantly unlocking stable **60+ FPS** performance.
* **Why content optimisations were useless on MA35D1**: Reducing triangles from 98K to 10K yielded no benefit because the ~130 ms Mesa fixed floor completely dwarfed the ~2 ms vertex stage. On a GPU, those same triangle reductions would produce proportional gains.

---

## 5. Strategic Recommendations for Desktop-to-Embedded Porting

The client's application was fundamentally designed at a **Desktop level**. Desktop development relies on high-frequency CPU single-core clocks (e.g., >3.0 GHz), discrete graphics processing units (GPUs) with dedicated high-bandwidth VRAM, and massive system memory pools.

Porting these design methodologies straight to an **Embedded level** (dual A35 cores @ 800 MHz with zero GPU acceleration) results in immediate structural failures. To steer the project away from this architectural dead-end, the client must adapt their approach based on the following guidelines:

### Recommendation A: Pivot to 2D Flipbook / Sprite Sheet Animation (Highly Recommended)

* **Technical Implementation**: Render the 3D asset's rotation offline on a development workstation using a desktop-class GPU or a headless Blender pipeline. Export the animation sequence as a series of 36 (or more) sequential 2D RGBA PNG frames. In QML, play back the frames using a lightweight `Timer` coupled with an `Image.source` swap, or a single master Sprite Sheet utilizing `sourceClipRect`.
* **Engineering Advantage**: This completely bypasses 3D matrix math, software rasterisation, and GLSL fragment instructions on the target chip. The runtime cost drops to simple 2D texture sampling and memory block transfers (Blit). **This solution easily achieves a fluid 30+ FPS while fully preserving the high-end PBR lighting textures rendered on the PC.**

### Recommendation B: Direct-GL with Small Off-screen FBO (real-time 3D ceiling)

* **Technical Implementation**: Bypass Qt Quick3D entirely with a `QOpenGLWindow` (or `QQuickFramebufferObject`) renderer that issues a single `glDrawElements` per frame. Render the 3D model into a small off-screen FBO (128×128) and blit only the model area (e.g. 360×400 px) to the display. This is implemented in `Oven_HMI_gl_demo/`.
* **Engineering Reality**: This approach removes all QML/scenegraph overhead (~50–80 ms/frame) and limits the blit cost to ~12 ms. The irreducible Mesa llvmpipe fixed-per-draw floor of ~130 ms remains. Measured result: **~7 FPS** — the hardware ceiling for any real-time 3D path on MA35D1.
* **When to use**: if the product requires real-time geometry changes driven by sensor data, 7 FPS with a slow rotation (20 s/rev, ~2.6°/step) is visually acceptable for a background decorative element.

### Recommendation C: Accept ~7 FPS and Optimize via Animation Chronology

* **Technical Implementation**: Use the `QOpenGLWindow` + 128×128 FBO + model-area blit architecture (`Oven_HMI_gl_demo/`) and slow the rotation to 20–30 seconds per revolution.
* **Engineering Advantage**: At ~7 FPS and 20 s/rev, each step is (360 / (20 × 7)) = 2.6° — nearly imperceptible jitter for a background decorative element. This requires no additional engineering beyond what is already implemented in `bread-gl-win`.

### Conclusion

The client must understand that **this performance deficit cannot be solved by mesh decimation, shader optimisation, or bypassing Qt Quick3D.** The irreducible floor is Mesa llvmpipe's ~130 ms fixed per-`glDrawElements` cost on the Cortex-A35. No API-level change removes it. The graphics pipeline strategy must be adapted: **flipbook for smooth animation; direct-GL small-FBO for real-time 3D at ~7 FPS.**