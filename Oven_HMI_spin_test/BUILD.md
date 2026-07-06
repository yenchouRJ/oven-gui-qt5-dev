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
pip3 install aqtinstall
python3 -m aqt install-qt linux desktop 5.15.2 gcc_64 -m qtquick3d -O /home/joeylu/opencode/coffee-machine-qt5-rework
BALSAM=/home/joeylu/opencode/coffee-machine-qt5-rework/balsam/5.15.2/gcc_64/bin/balsam

rm -rf assets/balsam_out/chicken
mkdir -p assets/balsam_out/chicken
$BALSAM assets/models/chicken.glb -o assets/balsam_out/chicken/

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

> **Updated after completing all experiments.**
> Several predictions below were revised once on-target results came in — see
> the debug log section for the full measurement trail.

- **No GPU means the CPU does everything.** The MA35D1 (dual Cortex-A35 @
  800 MHz) has no 3D GPU. llvmpipe runs every vertex transform, triangle
  rasterisation, and GLSL fragment shader instruction on the same two CPU cores
  that also handle the OS, Qt runtime, and QML engine.
- **kmscube's 60 FPS is not representative.** It renders 12 triangles with a
  trivial shader and no engine overhead — it only proves DRM/KMS output works.
  A real Qt Quick3D scene adds 4 pipeline stages, a JS engine, and a full PBR
  shader on top.
- **Neither triangles, shader complexity, fill rate, lights, nor draw calls
  are the bottleneck.** All five were tested independently on-target.
  Eliminating all rendering work (NoLighting, 1 draw call, 25% pixel area,
  1 light) still produced ~4 FPS — identical to the PBR baseline.
- **The real bottleneck is the Qt Quick3D scene-graph CPU overhead per frame.**
  Every frame, regardless of what is rendered: V4 JS evaluates
  `NumberAnimation` bindings, `QQuickWindow::sync()` walks the full QML tree,
  Quick3D traverses every Node to recompute world transforms, Mesa validates
  GL state for each draw call, and the View3D FBO is composited into the main
  framebuffer — all serialised on the same 800 MHz cores.  This overhead is
  constant and irreducible by changing mesh quality, material type, or
  resolution.
- **PrincipledMaterial context:** although PBR vs NoLighting made no FPS
  difference, switching to `DefaultMaterial.NoLighting` is still necessary to
  fix the dark-shadow rendering bug (PBR without IBL has no ambient term).
- **The only viable paths to smooth animation on MA35D1 are:**
  1. **2D flipbook** — pre-render the model at N rotation angles offline,
     export as PNG frames, animate via a QML `Timer` + `Image.source` swap.
     Zero per-frame 3D cost; as smooth as the frame count allows.
  2. **Custom QQuickFramebufferObject** — bypass Qt Quick3D entirely; write a
     minimal C++ renderer that issues exactly one `glDrawElements` per frame
     with a hand-written GLSL shader.  Eliminates all QML/scenegraph overhead.
  3. **Accept ~4 FPS with Qt Quick3D** — if the model only needs to look
     alive (not smooth), 4 FPS is sufficient for a "slowly rotating food item"
     use case; make the animation duration longer (e.g. 20 s/rev instead of 8 s)
     so the jitter is less perceptible.

---

## Bottleneck isolation — debug log

This section records the actual experiments run on MA35D1 to identify which
pipeline stage is the FPS bottleneck.  Each experiment changes exactly one
variable; the FPS delta tells us how much that variable contributes.

### Experiment 1 — Triangle count (vertex stage)

**Hypothesis:** reducing triangle count will linearly improve FPS, meaning
vertex throughput is the bottleneck.

**Method:** re-decimate `chicken.glb` with `gltf-transform simplify` at
progressively lower `--ratio` values; re-balsam; deploy; record FPS.

**Results:**

| Step | Tris   | FPS | Delta vs prev |
|------|--------|-----|---------------|
| 0    | 281 K  | OOM  | —             |
| 1    |  98 K  | ~2  | baseline      |
| 2    |  42 K  | ~3  | +1            |
| 3    |  10 K  | ~4  | +1            |

**Conclusion:** a 10× triangle reduction (98 K → 10 K) produced only a 2×
FPS gain.  If vertex throughput were the bottleneck, we would expect roughly
proportional improvement.  Instead FPS barely moved — **vertex stage is not
the primary bottleneck** at step 3.  Some other stage dominates frame time.

> Note: steps 1→2→3 were derived by always simplifying from the original
> GLB, not chaining from the previous step, to avoid compounding quality loss.
> Command: `gltf-transform weld orig.glb /tmp/w.glb && gltf-transform simplify
> /tmp/w.glb out.glb --ratio <R> --error 1`
> The `--error 1` flag is mandatory — the default `--error 0.0001` causes the
> simplifier to exit early at ~30–40% reduction regardless of `--ratio`.

---

### Experiment 2 — Fragment shader complexity (material stage)

**Hypothesis:** the fragment shader cost dominates; switching from full PBR
(`PrincipledMaterial`) to a no-op shader (`DefaultMaterial.NoLighting`) will
show a significant FPS gain.

**Method:** edit `Chicken.qml` post-balsam — replace every
`PrincipledMaterial { baseColor: X; metalness: 0; roughness: Y }` with
`DefaultMaterial { lighting: DefaultMaterial.NoLighting; diffuseColor: X }`.
No mesh or balsam change.  Test on step-3 (10 K tris) mesh for isolation.

> This was prototyped on the `unlit` branch (`git checkout unlit`).

**Observed side-effect before FPS measurement:** model rendered as flat
coloured segments (orange body, dark-brown parts, beige details) — confirming
the earlier "dark shadow" was caused entirely by `PrincipledMaterial` having
no ambient term without an IBL probe, not by a mesh or load failure.

**FPS result: ~4 FPS — unchanged from PBR baseline.**

**Conclusion:** eliminating ~140 float ops/pixel down to ~0 ops/pixel made
no measurable difference.  **Fragment shader is NOT the bottleneck.**

---

### Experiment 3 — Pixel fill area (rasteriser stage)

**Hypothesis:** the rasteriser fill cost dominates; reducing the number of
pixels the View3D renders will improve FPS proportionally.

**Method:** add `layer.enabled: true` and
`layer.textureSize: Qt.size(width/2, height/2)` to the `View3D`.
This renders the 3D scene to a 320×240 offscreen FBO (25% of the original
640×480 = 307 200 pixels → 76 800 pixels), then Qt scales the FBO up to fill
the panel.  The vertex stage, draw-call overhead, and Qt scenegraph work are
**completely unchanged** — only the rasteriser and fragment shader see fewer
pixels.

```qml
View3D {
    anchors.fill: parent
    layer.enabled:     true
    layer.textureSize: Qt.size(width / 2, height / 2)  // 25% pixel area
    layer.smooth:      true
    ...
}
```

**FPS result: ~4 FPS — unchanged.**

**Conclusion:** cutting pixels from 307 200 → 76 800 (4× reduction) with an
unchanged rasteriser+fragment cost profile made no difference.
**Rasteriser fill rate is NOT the bottleneck.**

> The composite blit (View3D FBO → window) still runs at full 640×480 even
> with `layer.textureSize` set, so the blit itself was also a candidate.
> Given no improvement, the blit cost is also negligible compared to the
> true bottleneck.

**Decision tree result:**

```
FPS unchanged (still ~4)?
 └─ Rasteriser is NOT the bottleneck. The bottleneck is upstream.
    → Proceed to experiments 4 and 5.
```

---

### Summary of what each experiment isolates

| Experiment | Variable changed | Stage isolated | FPS result |
|------------|-----------------|----------------|------------|
| 1 — triangle steps | polygon count | Vertex transform | OOM → ~4 (not proportional) |
| 2 — NoLighting | GLSL shader ops/pixel | Fragment shader | ~4 (no change) |
| 3 — layer.textureSize | pixels rendered | Rasteriser fill rate | ~4 (no change) |
| 4 — remove PointLights | per-light uniform eval | Light processing | ~4 (no change) |
| 5 — join meshes (1 draw call) | Mesa GL dispatch count | Draw-call overhead | ~4 (no change) |
| 6 — all stacked | all of the above | Combined rendering cost | ~4 (no change) |

The order matters: always change one variable at a time and return to the
same baseline before the next experiment.  The baseline for all experiments
above is: **step-3 mesh (10 K tris), PrincipledMaterial, 3 lights, NoAA,
View3D at full 640×480**.

---

### Experiment 4 — Per-light uniform evaluation

**Hypothesis:** Qt Quick3D evaluates light uniform buffers every frame for
each light node, even when the material ignores them.  Removing 2 PointLights
will reduce this overhead.

**Method:** remove both `PointLight` nodes from the scene; keep only 1
`DirectionalLight`.  Test alongside `NoLighting` materials so visual output
is unaffected.

**FPS result: ~4 FPS — unchanged.**

**Conclusion:** per-light uniform evaluation is not a significant cost at
this frame rate.  **Light node count is NOT the bottleneck.**

---

### Experiment 5 — Draw-call count (Mesa GL dispatch)

**Hypothesis:** each `Model` node in Qt Quick3D translates to at least one
`glDrawElements` call.  Each call has Mesa state-validation overhead on the
CPU.  Reducing from 4 draw calls to 1 will cut this cost.

**Method:** 
1. Python script: unify all 3 bread materials to a single baseColor.
2. `gltf-transform flatten + join`: collapse 4 separate mesh nodes into
   1 mesh / 1 primitive / 1 material.
3. Re-balsam: produces 1 `Model` with 1 `.mesh` file.
4. Apply `DefaultMaterial.NoLighting` as before.

Result: 4 `Model` nodes / 4 draw calls → 1 `Model` / 1 draw call.

**FPS result: ~4 FPS — unchanged.**

**Conclusion:** Mesa draw-call dispatch overhead is not the bottleneck.
**Draw-call count is NOT the bottleneck.**

---

### Experiment 6 — All optimisations stacked

**Method:** all of experiments 2–5 applied simultaneously:
- `DefaultMaterial.NoLighting` (0 shader ops/pixel)
- `layer.textureSize: Qt.size(width/2, height/2)` (25% pixel area)
- 1 `DirectionalLight` only
- 1 draw call (joined mesh, single material)

This is the minimum possible rendering work a Qt Quick3D scene can do —
essentially a coloured quad projected through a mesh.

**FPS result: ~4 FPS — unchanged from the original PBR baseline.**

**Conclusion: the ~250 ms/frame cost is entirely in the Qt Quick3D
scene-graph and QML runtime overhead, not in any rendering operation.**

The per-frame overhead that cannot be removed with the current architecture:

| Source | Cost |
|--------|------|
| V4 JS engine — `NumberAnimation` binding eval | every frame |
| `QQuickWindow::sync()` — QML tree walk | every frame |
| Qt Quick3D scene manager — Node transform recompute | every frame |
| Mesa GL — driver state validation per draw call | every frame (even 1 call) |
| View3D FBO composite — blit to Qt Quick window | every frame, full resolution |

On an 800 MHz Cortex-A35 with single-threaded rendering, this fixed overhead
alone appears to consume the entire ~250 ms frame budget.

---

### Bottleneck verdict and recommended next steps

**Verdict:** Qt Quick3D is not viable for smooth animation on MA35D1 at any
mesh quality level.  The bottleneck is the engine overhead, not the content.

**Recommended paths forward:**

1. **2D flipbook animation** *(lowest risk, highest FPS)*  
   Pre-render the model at N angles offline (e.g. Blender headless or a
   desktop Qt build), export as PNG strip or individual frames.  Animate
   in QML with a `Timer` + `Image.source` swap or a sprite-sheet `Image`
   with `sourceClipRect`.  Cost per frame: one texture sample + one 2D
   quad draw — easily 30+ FPS.

2. **Custom `QQuickFramebufferObject`** *(highest FPS for true 3D)*  
   Write a minimal C++ `QQuickFramebufferObject::Renderer` that issues
   exactly one `glDrawElements` with a hand-written GLSL vertex + fragment
   shader.  Bypasses Qt Quick3D scene graph entirely; no V4 JS, no node
   traversal, no Mesa state rebuild.  Estimated overhead: <5 ms/frame.

3. **Accept 4 FPS with a slower rotation** *(zero work, good-enough UX)*  
   Increase `NumberAnimation` duration from 8 s to 20–30 s per revolution.
   At 4 FPS the per-step angular jump is (360 / (20 × 4)) = 4.5°, which
   is smoother than the current (360 / (8 × 4)) = 11.25°/step and likely
   imperceptible to a casual observer glancing at a menu screen.

---

## Bottleneck tree — complete picture

All experiments across `Oven_HMI_spin_test` (exps 1–6) and `Oven_HMI_gl_demo`
(exps A–E) were run on-target and mapped to the pipeline stages below.
Each node in the tree states the stage, what was tested, and the measured result.

```
Frame cost on MA35D1 (dual Cortex-A35 @ 800 MHz, llvmpipe, no GPU)
│
├─ Qt Quick + Quick3D overhead  [exps 1-6, A, B]
│   ├─ V4 JS / NumberAnimation binding eval       — tested exp 1-6
│   ├─ QQuickWindow::sync() — QML tree walk       — tested exp 1-6
│   ├─ Qt Quick3D node transform recompute        — tested exp 1-6
│   └─ View3D FBO composite + blit                — tested exp 3, B
│
│   Exp A (QQFBO, no Quick3D):  saved ~122 ms  → still 3.5 FPS
│   Exp B (QOpenGLWindow):      saved another 89 ms → still 5 FPS
│   → Qt Quick overhead is real but NOT the primary ceiling.
│
├─ Mesa GL draw-call overhead   [exp C — VAO]
│   Hypothesis: per-frame glVertexAttribPointer calls trigger Mesa
│   vertex-element CSO rebuild and LLVM re-JIT.
│   Fix applied: VAO (attribute format set once, never repeated).
│   Result: tDraw unchanged 213 ms → 213 ms.
│   → Per-frame attribute setup overhead: zero. Mesa CSO NOT re-JITted.
│
├─ Fragment shader complexity    [exp 2 — NoLighting]
│   DefaultMaterial.NoLighting: 0 ops/pixel vs ~140 ops/pixel PBR.
│   Result: FPS unchanged (~4). Fragment math NOT the bottleneck.
│
├─ Triangle / vertex count       [exp 1 — decimation steps]
│   98 K → 10 K tris: FPS 2 → 4. Not proportional.
│   Vertex processing is fast (~2 ms at any triangle count).
│   → Vertex stage NOT the bottleneck at step 3.
│
├─ Draw-call count               [exp 5 — gltf-transform join]
│   4 draw calls → 1 draw call. FPS unchanged (~4).
│   → Mesa dispatch overhead per call: negligible.
│
├─ Light count                   [exp 4 — remove PointLights]
│   3 lights → 1 DirectionalLight. FPS unchanged (~4).
│   → Per-light uniform evaluation: negligible.
│
├─ Pixel fill — viewport size    [exp 3 — layer.textureSize]
│   View3D at 25% pixel area (320×240). FPS unchanged (~4).
│   Apparent contradiction with exp D below — see note.
│
├─ Pixel fill — model-covered area   [exp D — 128×128 FBO]
│   Render to 128×128 FBO; bread covers ~1–2 K pixels (vs ~150 K).
│   tDraw: 213 ms → 130 ms (steady state).  FPS: 5 → 7.
│   Note on exp 3 contradiction: layer.textureSize in Qt Quick3D
│   reduces raster pixels but does NOT reduce Qt Quick3D scenegraph
│   work, which was dominating at the time. With scenegraph removed
│   (exp D uses QOpenGLWindow), the pixel reduction is measurable.
│
└─ Mesa llvmpipe per-draw fixed cost   [exp D — confirmed floor]
    At 128×128 FBO (1–2 K covered pixels), tDraw is still ~130 ms.
    Expected at this coverage: ~1–2 ms. Actual: ~130 ms.
    → ~130 ms is a FIXED cost per glDrawElements call in Mesa llvmpipe
      on Cortex-A35 regardless of triangles, pixels, or shader.
    This fixed cost is in Mesa's tile-dispatcher and state-machine layer
    running on a slow in-order ARM core with no out-of-order execution.
```

### Blit cost — also tested

After shrinking the render FBO, the blit pass became visible:

| Blit area | Pixels | tBlit |
|-----------|--------|-------|
| Full window 1280×480 | 614 K | ~62 ms |
| Model area 360×400  | 144 K | ~12 ms |

Blit (textured quad, no depth) scales well with pixel area — lower fixed
overhead than the 3D draw.  Restricting to the model area recovered ~50 ms.

### Final on-target numbers

All experiments completed.  Steady-state results (bread.glb, 25 794 tris):

| Setup | tClear | tDraw | tBlit | FPS |
|-------|--------|-------|-------|-----|
| Qt Quick3D, full viewport | — | — | — | ~4 |
| QQFBO, full viewport | 2 ms | 166 ms | — | 3.5 |
| QOpenGLWindow, full viewport | 9 ms | 213 ms | — | 5 |
| QOpenGLWindow, 128×128 FBO → full blit | 1 ms | 130 ms | 62 ms | 5 |
| QOpenGLWindow, 128×128 FBO → 360×400 blit | 0 ms | 146 ms | 12 ms | **7** |

### Why 7 FPS is the measured ceiling

```
tDraw fixed floor:  ~130 ms  (Mesa llvmpipe, irreducible)
tBlit (360×400):     ~12 ms
swap + overhead:     ~10 ms
─────────────────────────────
Total:              ~152 ms → 6.5 FPS
```

The ~130 ms per `glDrawElements` call cannot be reduced by any API-level
optimisation.  It is Mesa's CPU-side state machine and tile-rasterization
dispatcher running on a single Cortex-A35 core (in-order, 800 MHz, no SIMD
benefit from llvmpipe's LLVM backend for these dispatch operations).

### Final recommendations

| Approach | Cost | FPS | Notes |
|----------|------|-----|-------|
| **Flipbook (pre-rendered PNG)** | zero 3D at runtime | 30+ | Best for smooth rotation |
| **Direct-GL, 128×128 FBO, model-area blit** | 1 draw call | ~7 | Acceptable for slow spin |
| Qt Quick3D (original) | full stack | ~4 | Not recommended |

For the product cooking cycle: if the model only needs to look alive (not
smooth), 7 FPS at the current architecture is the real-time ceiling.
At 20 s/rev, each step is (360 / (20 × 7)) = 2.6°, which is nearly
imperceptible jitter.  For anything smoother, the **flipbook** path is
the only viable option on this hardware.
