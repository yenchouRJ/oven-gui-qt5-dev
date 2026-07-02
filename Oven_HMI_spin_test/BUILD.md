# chicken-spin-test — MA35D1 Quality & Performance Probe

A minimal Qt5 Quick3D app that shows the chicken **PNG reference** and the
**spinning 3D model** side by side.  Purpose: find the highest mesh quality
the MA35D1 (llvmpipe, ~108 MB RAM) can sustain without OOM or unacceptable FPS.

```
QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./chicken-spin-test
```

## Layout

```
+---------------------------+---------------------------+
|  PNG reference (256×256)  |  3D model (spinning)      |
|                           |  NoAA baseline             |
|      chicken.png          |  281 K tris  (original)   |
|                           |                            |
+---------------------------+---------------------------+
 FPS: XX                              chicken.glb — original quality
```

FPS counter (green, top-left) is driven by `FpsMonitor` via `beforeRendering`.
Quality label (top-right) identifies the current mesh variant.

## Quick-start build (cross-compile for MA35D1)

```sh
BR=/home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5

cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=$BR/output/host/share/buildroot/toolchainfile.cmake \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

Binary: `build/chicken-spin-test`

## Mesh quality levels

The test uses the **original** `chicken.glb` (no decimation) as the starting
point.  If the board OOMs or FPS is too low, reduce quality in steps:

| Step | Source GLB | Command | Approx. tris | Est. mesh RAM |
|------|-----------|---------|--------------|---------------|
| 0 (current) | `assets/models/chicken.glb` | *(none — original)* | 281 K | ~13 MB |
| 1 | weld + simplify --ratio 0.35 --error 1 | see below | ~98 K | ~4.5 MB |
| 2 | weld + simplify --ratio 0.15 --error 1 | see below | ~42 K | ~2 MB |
| 3 | weld + simplify --ratio 0.03 --error 1 | see below | ~10 K | ~0.5 MB |

### Reducing quality (run on dev machine)

```sh
npm install -g @gltf-transform/cli   # once

# Example: step 1 (~35% kept)
gltf-transform weld assets/models/chicken.glb /tmp/cw.glb
gltf-transform simplify /tmp/cw.glb assets/models/chicken.glb \
    --ratio 0.35 --error 1
```

> **Important:** always pass `--error 1`.  The default `--error 0.0001` is so
> tight that the simplifier stops at only ~30–40% reduction regardless of the
> `--ratio` value.

After modifying `assets/models/chicken.glb`, regenerate meshes and `qml.qrc`:

```sh
BALSAM=/home/joeylu/opencode/coffee-machine-qt5-rework/balsam/5.15.2/gcc_64/bin/balsam

rm -rf assets/balsam_out/chicken
mkdir -p assets/balsam_out/chicken
$BALSAM assets/models/chicken.glb --outputPath assets/balsam_out/chicken/

python3 tools/gen_qrc.py   # regenerates qml/qml.qrc
```

Then rebuild and redeploy.

### Updating the quality label in Main.qml

Edit the `text:` property of the info overlay (line ~33):
```qml
text: "chicken.glb — step 1 (~98 K tris)"
```

## Anti-aliasing knob

In `qml/Main.qml`, find `SceneEnvironment` and change `antialiasingMode`:

```qml
// Fastest — use for baseline FPS measurement
antialiasingMode: SceneEnvironment.NoAA

// 2× MSAA — mild quality improvement, moderate cost
antialiasingMode:    SceneEnvironment.MSAA
antialiasingQuality: SceneEnvironment.Medium

// 4× SSAA — best quality, highest cost (may be too slow on llvmpipe)
antialiasingMode:    SceneEnvironment.SSAA
antialiasingQuality: SceneEnvironment.High
```

## File layout

```
Oven_HMI_spin_test/
├── CMakeLists.txt
├── BUILD.md
├── src/
│   ├── main.cpp          — QGuiApplication + QQmlEngine + FpsMonitor wiring
│   ├── FpsMonitor.h
│   └── FpsMonitor.cpp    — counts beforeRendering signals, 1-second window
├── qml/
│   ├── Main.qml          — Window: PNG panel (left) + View3D panel (right)
│   └── qml.qrc           — embeds Main.qml, chicken.png, Chicken.qml, *.mesh
└── assets/
    ├── media/
    │   └── chicken.png   — 256×256 RGBA (downscaled from original)
    ├── models/
    │   └── chicken.glb   — source model (replace to change quality step)
    └── balsam_out/
        └── chicken/
            ├── Chicken.qml    — Qt5 Quick3D scene wrapper (balsam-generated)
            └── meshes/        — Qt5 format-v3 .mesh files (balsam-generated)
                ├── cylinder_001.mesh   (main body)
                ├── cube.mesh … sphere_001.mesh
                └── plane_002.mesh      (emissive lighting plane)
```

## Mesh format note

Qt5 Quick3D (`qssgmeshutilities.cpp`) only accepts mesh format versions 1–3
(magic `0xC8A07F4D`).  Qt6 `balsam` writes version 7 — those files silently
return `nullptr` and the model renders blank.  Always use the Qt5 balsam:

```sh
BALSAM=/home/joeylu/opencode/coffee-machine-qt5-rework/balsam/5.15.2/gcc_64/bin/balsam
```

## On-target run notes

- `MESA-LOADER: failed to open ma35-drm` at startup is harmless (Mesa probes
  for the absent HW DRM driver and falls back to llvmpipe automatically).
- All vertex/index buffers and textures live in system RAM under llvmpipe — there
  is no VRAM separation.  The key RAM consumers for this test:
  - Qt libraries: ~40–50 MB
  - Framebuffer (1280×480 RGBA): ~2.5 MB
  - Mesh vertex+index data: ~13 MB at original quality, ~0.5 MB at step 3
  - chicken.png decoded RGBA: ~0.25 MB
- Board has ~108 MB managed RAM.  Step 0 (original) is likely to OOM.
  Step 1 or 2 is a reasonable starting point to verify visible quality.

---

## Results so far

| Step | Tris   | Outcome on MA35D1     |
|------|--------|-----------------------|
| 0    | 281 K  | OOM-killed            |
| 1    | 98 K   | Stable, ~2 FPS        |
| 2    | 42 K   | Stable, ~3 FPS        |
| 3    | 10 K   | Stable, ~4 FPS, burr on edges but profile recognisable |

Motion feels smoother than the FPS number suggests because Qt Quick's
`NumberAnimation` interpolates the rotation every paint event, so the
model's position updates even between rendered frames.

---

## Next steps — shadow fix and optimisation directions

### Problem: model appears as a dark shadow with no colour

**Root cause:** Qt5 Quick3D's `PrincipledMaterial` is a full PBR shader.  It
has no built-in ambient term — without an IBL (Image Based Lighting) environment
probe the only illumination is from explicit lights, and surfaces facing away
from those lights go completely black.  The original model was designed for a
desktop renderer where IBL is always present.  llvmpipe supports the required
OpenGL extension, but we never set up an environment probe.

**Fix options (in order of ease):**

1. **Add a low-brightness back-fill light** *(easiest, pure QML, no asset
   changes)* — add a second `DirectionalLight` pointing opposite to the key
   light with brightness ~0.5–0.8.  This simulates the ambient bounce that PBR
   normally gets from IBL.  Try this first.

   ```qml
   // In Main.qml, inside View3D, alongside the existing DirectionalLight:
   DirectionalLight {
       eulerRotation.x: 150   // pointing up-back (opposite of key)
       eulerRotation.y: 150
       color:      "#ffffff"
       brightness: 0.6
       castsShadow: false
   }
   ```

2. **Switch balsam-generated materials to `DefaultMaterial`** — Qt5 Quick3D's
   `DefaultMaterial` uses a Phong model with a configurable `ambientColor`
   property.  Edit `assets/balsam_out/chicken/Chicken.qml` after each balsam
   run: replace every `PrincipledMaterial { ... }` block with
   `DefaultMaterial { diffuseColor: <original baseColor>; ambientColor: "#404040" }`.
   This is a pure QML edit, no C++ change.  `DefaultMaterial` is also cheaper to
   shade than `PrincipledMaterial` on llvmpipe, so FPS may improve.

3. **Add an IBL environment probe** — set `SceneEnvironment.lightProbe` to a
   small equirectangular HDR image.  Gives the most realistic ambient but adds
   memory and a texture lookup per fragment.  Likely not worth the cost on
   this platform.

### Optimisation directions beyond `gltf-transform simplify`

Auto-decimation removes triangles mathematically but has no artistic intent —
the result looks blurry/burry because the algorithm can't know which edges matter
visually.  Here are higher-impact alternatives:

#### A. Hand-crafted low-poly model (best quality/poly ratio)

Re-model the chicken in Blender at a deliberately low resolution:
  - Target 500–2 000 tris with clean topology (quads, meaningful edge loops).
  - A hand-crafted 1 000-tri chicken will look better than a 10 000-tri
    auto-decimated one because the artist places vertices where they matter.
  - Export as `.glb`, run through the normal balsam pipeline.

This is the right long-term solution if visual quality matters to the customer.

#### B. Reduce the View3D render resolution

The software rasteriser cost scales with **pixel count**, not just triangle
count.  At 4 FPS on step 3 (10K tris), the bottleneck is likely the
fragment/fill stage, not vertex throughput.  Halving the View3D size quarters
the pixel work:

```qml
// In Main.qml, replace the right-panel View3D anchors with:
View3D {
    width:  parent.width  / 2   // logical half-screen
    height: parent.height
    layer.enabled: true
    layer.smooth:  true
    // Render at half physical resolution, Qt scales up automatically:
    layer.textureSize: Qt.size(parent.width / 4, parent.height / 2)
}
```

Expected benefit: ~2–4× FPS gain.  Cost: slight blurriness on edges (less
noticeable than the current NoAA jaggies).

#### C. Reduce light count

Every additional light re-runs the full PBR equation per fragment.  The current
scene has 1 `DirectionalLight` + 2 `PointLight`s = 3 lighting passes.
`PointLight` is the most expensive because it computes per-fragment distance
attenuation.  Try:

- Drop to 1 `DirectionalLight` only.
- Or replace `PointLight`s with additional cheap `DirectionalLight`s.

Expected benefit: ~20–40% FPS improvement.

#### D. Replace `PrincipledMaterial` with `DefaultMaterial`

`DefaultMaterial` uses a simpler Phong GLSL shader — noticeably cheaper per
fragment than the full PBR `PrincipledMaterial` on a software renderer.  This
also fixes the shadow issue (see Fix option 2 above) as a side effect.

#### E. Pre-rendered sprite sheet (maximum performance, zero 3D cost)

If real-time 3D proves too slow for the target, pre-render the spinning
animation on the dev machine (where GPU is available) and play it back as a
`AnimatedImage` or a `Repeater`-of-`Image` frame strip.

- 36 frames × 256×256 RGBA PNG = ~9 MB (or ~2 MB as JPEG strip).
- On-target cost: one `Image` decode + blit per frame — trivially cheap.
- Quality: indistinguishable from a real-time 3D render.
- Workflow: render in Blender or on a Linux host with `QT_QPA_PLATFORM=offscreen`,
  export frames, pack into a sprite sheet or numbered PNGs, play back in QML.

This is the fallback if real-time 3D never reaches acceptable FPS on llvmpipe.

### Recommended next sequence

1. **Fix shadow first** — try option 1 (back-fill `DirectionalLight`) in `Main.qml`.
   Quick to test, no rebuilding of assets.
2. **Replace lights** — drop to 1 `DirectionalLight`, measure FPS delta.
3. **Halve View3D resolution** — measure FPS delta with `layer.textureSize`.
4. **Switch to `DefaultMaterial`** — edit `Chicken.qml`, measure FPS delta.
5. **If still not acceptable** — hand-craft a low-poly model or go sprite sheet.


## Performance Analysis: Why MA35D1 Struggles with Qt 3D Assets

### Hardware context

- **MA35D1 SoC:** dual Cortex-A35 @ 800 MHz, ~108 MB managed RAM, **no 3D GPU,
  no hardware rasteriser, no dedicated shading units.**
- **llvmpipe:** Mesa's pure-software OpenGL implementation.  Compiles GLSL
  shaders to LLVM IR at startup and executes them on the CPU cores.
  Multi-threaded, but only 2 cores are available here.
- **Shared memory bus:** the same DDR that holds the OS kernel, Qt libraries,
  QML runtime, vertex data, and decoded PNG textures also serves as the
  "framebuffer VRAM".  Every render operation is a DDR read/write.
- **kmscube is not representative:** kmscube achieves 60 FPS because it renders
  exactly 12 triangles with a trivial flat-colour shader and zero engine
  overhead.  It confirms DRM/KMS output works, nothing more.

### What the CPU must compute per frame (no GPU)

Every task below is normally handled by dedicated fixed-function or programmable
GPU hardware.  On MA35D1 with llvmpipe, the Cortex-A35 cores do it all:

**1. Vertex stage** — runs once per unique vertex per draw call:
- Model-View-Projection transform: one 4×4 float matrix multiplication per
  vertex.  At step 3 (10 K tris ≈ 8 K unique verts): ~8 000 matrix muls/frame.
- Normal transform: inverse-transpose of the MV matrix × normal vec3, needed
  for lighting to be correct in world space.  One per vertex.
- Perspective divide + viewport mapping: converts clip-space to pixel coords.
- **With 9 separate mesh objects** (balsam output for chicken): the vertex stage
  runs 9 separate draw calls, each with its own matrix state.

**2. Primitive assembly and rasterisation** — runs once per triangle, then
per pixel:
- Triangle setup: edge equations, bounding box, backface-cull test — per tri.
- Scanline / edge-function rasterisation: determines which pixels each triangle
  covers.  At View3D = 640 × 480, the chicken fills roughly half the panel
  (~100 K–200 K covered fragments per frame).
- Barycentric interpolation of all vertex attributes (position, normal, UV) for
  every covered pixel.
- **This is the confirmed bottleneck** (see Results section): halving triangles
  from 98 K → 10 K gained only 2→4 FPS because the pixel count — and therefore
  the fragment work — didn't change.

**3. Fragment shader stage** — the most expensive, runs per pixel per light:

`PrincipledMaterial` compiles to a full **PBR (Cook-Torrance BRDF)** GLSL
fragment shader.  For each light it evaluates:

- **D** — GGX microfacet normal-distribution function (~8 float ops)
- **G** — Smith joint geometric-masking function (~10 float ops)
- **F** — Schlick Fresnel approximation (~5 float ops)
- Light-direction normalisation, half-vector, dot products (~10 float ops)
- Energy-conservation division, gamma correction (~5 float ops)

≈ **~40 float operations per light per fragment.**

This project has **1 `DirectionalLight` + 2 `PointLight`s = 3 lights**.
`PointLight` adds per-fragment distance and attenuation calculations on top.
Total: ~140 float ops per fragment.

Rough estimate:
```
~150 K fragments × ~140 float ops = ~21 M float ops/frame
Cortex-A35 effective throughput (llvmpipe, NEON): ~200–400 M float ops/s
→ fragment stage alone ≈ 50–100 ms/frame → 10–20 FPS theoretical ceiling
```
Qt/scenegraph overhead and memory-bus saturation push the real number below
that ceiling — which matches the measured 4 FPS.

**4. Qt / QML / Quick3D software stack overhead** — before a single triangle
is drawn, every frame:

- **QML engine (V4 JS):** evaluates all changed bindings — including the
  `NumberAnimation` driving `eulerRotation.y`, which fires a JS callback
  every paint event, updates a QML property, triggers Qt property-notification
  chains, and marks scene nodes dirty.
- **Qt Quick scene graph sync:** `QQuickWindow::sync()` traverses the QML
  object tree, copies property values into C++ scene-graph nodes.
- **Qt Quick3D render loop:** traverses the 3D scene graph, updates transform
  matrices for the rotating `Node`, rebuilds model-view matrices for each of
  the 9 mesh nodes, uploads changed uniform buffers to the Mesa GL driver.
- **Mesa GL → llvmpipe dispatch:** each `glDrawElements` call goes through
  Mesa's state validation, the JIT-compiled vertex shader, rasteriser, and
  JIT-compiled fragment shader — all in software on the same cores.
- **Framebuffer blit:** the rendered View3D FBO must be composited back into
  the Qt Quick scene graph's main framebuffer (another DDR read-write pass).

### What this project specifically loads (current step 3)

| Component | Detail | CPU cost category |
|-----------|--------|-------------------|
| Mesh objects | 9 draw calls (cylinder × 2, cube × 3, sphere × 2, cylinder_002, plane) | Vertex + draw-call overhead |
| Triangle count | 10 186 tris, 8 379 verts | Vertex transform |
| Materials | 5 × `PrincipledMaterial` (orange, brown, red, beige, emissive) | PBR fragment shader |
| Lights | 1 × `DirectionalLight` + 2 × `PointLight` | ×3 BRDF eval per fragment |
| View3D size | 640 × 480 pixels (half of 1280 × 480 window) | ~150 K rasterised fragments |
| Anti-aliasing | NoAA | no extra pass |
| Shadows | `castsShadow: false` | saved a shadow-map render pass |
| Rotation | `NumberAnimation` on `eulerRotation.y` @ 8 s/rev | JS binding + matrix update per frame |
| PNG image | 256 × 256 RGBA decoded once, blitted as 2D item | negligible per-frame cost |

### Why the FPS numbers are what they are

- **2 FPS at 98 K tris (step 1)** — vertex transform is a significant fraction
  of frame time alongside fragment fill.  Each draw call also has Mesa overhead.
- **3 FPS at 42 K tris (step 2)** — vertex cost halved but fill cost unchanged;
  diminishing returns already visible.
- **4 FPS at 10 K tris (step 3)** — vertex stage is now negligible (<5% of
  frame time).  Bottleneck is entirely the PBR fragment shader × 3 lights ×
  ~150 K pixels, plus Qt/scenegraph overhead.
- **Perceived motion smoother than 4 FPS** — `NumberAnimation` runs on Qt
  Quick's animation timer and updates `eulerRotation.y` on every paint event
  even when the 3D render hasn't produced a new frame.  The QML item tree
  interpolates position between 3D renders, so motion looks smoother than the
  reported `beforeRendering` count.

### Optimisation targets (highest impact first)

The following are ranked by estimated FPS gain for this specific workload:

- **Fragment shader complexity** *(highest impact)* — switching 5 ×
  `PrincipledMaterial` to `DefaultMaterial` (Phong) cuts per-fragment cost
  from ~140 ops to ~20–30 ops (6–7×).  Expected gain: 2–3× FPS.
- **Pixel fill area** — rendering `View3D` at half physical resolution
  (`layer.textureSize`) and scaling up cuts fill work by 4×.  Expected
  gain: 2–4× FPS.  This is independent of material type.
- **Light count** — dropping from 3 lights to 1 `DirectionalLight` removes
  two full BRDF evaluations per fragment.  Expected gain: ~30–50%.
  `PointLight` is the most expensive (distance attenuation adds per-fragment
  divisions).
- **Draw calls** — 9 separate mesh objects means 9 × Mesa GL dispatch overhead
  per frame.  Merging the chicken into 1–3 objects via `gltf-transform join`
  (same-material meshes) reduces that overhead.  Expected gain: 5–15%.
- **Qt property / JS overhead** — replacing the QML `NumberAnimation` with a
  C++ `QTimer`-driven property update removes V4 JS evaluation from the render
  hot path.  Expected gain: small (< 5%) but measurable on a 800 MHz CPU.
- **Mesh topology** — auto-decimation (`gltf-transform simplify`) reduces
  triangle count but cannot improve the quality/tri ratio.  A hand-crafted
  500–2 000-tri model in Blender would look comparable to the current 10 K-tri
  auto-decimated model while halving the vertex cost further.

## Performance Summary

- **No GPU means the CPU does everything.** The MA35D1 (dual Cortex-A35 @
  800 MHz) has no 3D GPU. llvmpipe runs every vertex transform, triangle
  rasterisation, and GLSL fragment shader instruction on the same two CPU cores
  that also handle the OS, Qt runtime, and QML engine.
- **kmscube's 60 FPS is not representative.** It renders 12 triangles with a
  trivial shader and no engine overhead — it only proves DRM/KMS output works.
  A real Qt Quick3D scene adds 4 pipeline stages, a JS engine, and a full PBR
  shader on top.
- **Triangles are not the bottleneck.** Reducing from 281 K to 10 K tris
  (96% cut) only lifted FPS from OOM → 4 FPS. The real bottleneck is the
  fragment shader: ~150 K pixels × ~140 float ops (PBR × 3 lights) = ~21 M
  float ops per frame — already near the A35's effective throughput ceiling.
- **Three lights make every pixel expensive.** Each `PointLight` re-evaluates
  the full Cook-Torrance BRDF (GGX distribution, Smith masking, Schlick
  Fresnel) per fragment. With 3 lights the fragment stage is 3× slower than
  it needs to be; dropping to 1 `DirectionalLight` is the single cheapest
  FPS gain available.
- **PrincipledMaterial is a full desktop PBR shader.** It was designed for
  systems where the fragment stage runs on hundreds of parallel GPU shading
  units. On a single-threaded software renderer it costs ~140 float ops per
  pixel vs ~25 for `DefaultMaterial` (Phong). Switching materials is also the
  fix for the dark-shadow appearance (Phong has a built-in ambient term; PBR
  without IBL has none).
- **Qt's software stack adds meaningful overhead.** Every frame: V4 JS
  evaluates `NumberAnimation` bindings, `QQuickWindow::sync()` walks the QML
  tree, Quick3D rebuilds 9 transform matrices, Mesa validates GL state, and the
  View3D FBO is composited back into the main framebuffer — all on the same
  800 MHz cores, before a single triangle is drawn.
- **The real fix is offloading pixel work, not reducing triangles.** Halving
  the View3D render resolution (`layer.textureSize`) cuts fill work by 4×.
  Switching to `DefaultMaterial` cuts shader cost by ~6×. Dropping to 1 light
  saves ~30–50%. These three changes together could realistically push the
  scene from 4 FPS into the 20–30 FPS range without touching the mesh.
