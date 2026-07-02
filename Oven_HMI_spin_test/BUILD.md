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
