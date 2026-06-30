# dev.md — Development Memo & TODO

Working notes and next-step checklist for porting **oven-gui** from Qt6 to **Qt5.15.18**
on the **MA35D1** (no GPU → EGLFS + Mesa llvmpipe) Buildroot target.

See `AGENT.md` for the full project analysis and component breakdown.

> **Port location:** the Qt5 port lives in `Oven_HMI_G2L_QT5/` (the original Qt6
> sources stay untouched in `Oven_HMI_G2L_fae_release/`). Build notes are in
> `Oven_HMI_G2L_QT5/BUILD.md`.
>
> **Status (verified):** Qt5 port cross-compiles cleanly with the Buildroot
> aarch64 toolchain (`oven-gui` ELF produced). On-target run/FPS not yet validated.

---

## Progress Log
- **DONE** Phase 1 (build): `CMakeLists.txt` → Qt5 (`find_package(Qt5 ...)`,
  `Qt5::*`, `qt5_add_big_resources`, added `Gui`/`Qml`). Configures + builds clean
  via `output/host/share/buildroot/toolchainfile.cmake`.
- **DONE** Phase 2 (C++): `main.cpp`, `serialhandler`, `FpsMonitor` compile on Qt5
  with **no source changes** required.
- **DONE** Phase 4 (video disabled): removed `QtMultimedia` from MenuPage/Processing/
  Adjustment; replaced background `Video` with gradient/solid; `StartupPage` now a
  static splash + timer; `SoundEffect` kept in `Main.qml`; `.mov` excluded from qrc.
- **DONE** misc fixes: `ProcessingPage` `Root.finished()`→`processingRoot.finished()`;
  `DrinkModel3D` default fallback → existing model (was missing `coffee_cup`);
  removed 2 duplicate qrc mesh aliases.
- **DONE** runtime fix: this Buildroot Qt5 build **rejects version-less QML imports**
  (`Library import requires a version`). Added explicit versions to all 17 QML/model
  files: QtQuick 2.15, QtQuick.Controls 2.15, QtQuick.Layouts 1.15, QtQuick.Window
  2.15, QtQuick.Particles 2.15, QtMultimedia 5.15, QtQuick3D 1.15, Helpers 1.15.
- **NOTE** `MESA-LOADER: failed to open ma35-drm` at startup is harmless (Mesa falls
  back to llvmpipe).
- **DONE** Qt6-only type removed: `OrbitCameraController` (absent from this Quick3D
  1.15 Helpers backport) deleted from `ProcessingPage.qml`; replaced with an
  auto-rotate `NumberAnimation` on the model node. Verified all other Quick3D types
  used (Loader3D/View3D/SceneEnvironment/cameras/lights/PrincipledMaterial + MSAA/SSAA
  enums + brightness/fade/castsShadow) **do** exist in the backport.
- **DONE** Phase 5b (asset downscaling — fixes on-target OOM): first on-target run
  was OOM-killed (`oven-gui` hit ~1.1GB virt / ~80MB RSS on a board with only
  ~108MB managed RAM). Root cause: the menu `Repeater` builds all 5 carousel
  delegates at once, each an `Image` with **no `sourceSize`** (`mipmap:true`), so
  every full-res food PNG decoded simultaneously — chicken 4000×4000 = **61MB**
  RGBA, pizza 34MB, fish 24MB, meatball 24MB ≈ **144MB** of textures alone. Fixes:
  - Physically downscaled `chicken/pizza/fish/meatball.png` → **512×512** (LANCZOS,
    optimized): files 26.7MB → 1.26MB; decoded RGBA 144MB → ~4MB. `bread.png`
    already small (kept).
  - `MenuPage` carousel `Image`: added `sourceSize: Qt.size(256,256)` (matches the
    250px tile) + `asynchronous: true` to bound decode regardless of source.
  - `DrinkModel3D`: added an `active` gate on `Loader3D`; `MenuPage` binds it to the
    selected tile (`model3dLayer.visible`) so only **one** model's meshes (~max 13MB
    fish) is resident instead of all five at once. Fixed the auto-rotate
    `NumberAnimation` `running:` to use the same `model3dLayer.visible` (it was bound
    to `View3D.visible`, which is always true).
  - Binary shrank ~58MB → **33MB**; cross-compile + `qmllint` clean.
- **TODO next:** re-deploy to MA35D1 (verify no OOM, measure FPS) → then Phase 5
  (cut Quick3D AA/shadows). Mesh decimation (`*.mesh`) still pending if FPS is low.

---

## Quick Facts
- App: `oven-gui` (Oven HMI), Qt Quick + Qt Quick 3D, 1280×480 fullscreen.
- Target: **MA35D1, dual-core @ 800 MHz, no GPU** → EGLFS + Mesa **llvmpipe** (software GL).
- Buildroot: `/home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5`
- Qt5 packages: `…/ma35d1_br24_qt5/package/qt5` (Qt **5.15.18**, incl. `qt5quick3d`).
- Run on target: `QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./oven-gui`

> **Note:** the `CMakeLists.txt` comment *"need to modify to Qt5 for Remi Pi"* is a
> customer note — **ignore it**; our target is MA35D1.

> **Perf strategy for this port:** assets were authored on Windows (desktop-grade),
> and the CPU is weak. So the port also **(a) disables background video playback
> temporarily** and **(b) downscales assets**, expecting very low FPS otherwise.

---

## TODO — Porting Roadmap

### Phase 0 — Environment & baseline
- [ ] Confirm Buildroot `.config` enables: `qt5quick3d`, `qt5multimedia`,
      `qt5quickcontrols2`, `qt5serialport`, `qt5declarative`, gstreamer (for video).
- [ ] Confirm Mesa/llvmpipe + EGLFS are enabled in the Buildroot image.
- [ ] Source the cross toolchain (Buildroot `output/host`), locate the CMake
      toolchain file / `qmake` for Qt5.
- [ ] Do a clean host build with Qt6 first to confirm the baseline still works.

### Phase 1 — Build system (CMakeLists.txt)
- [x] Switch `find_package(Qt6 …)` → `find_package(Qt5 COMPONENTS Core Gui Qml Quick
      QuickControls2 Multimedia SerialPort Widgets Quick3D)`.
- [x] `qt_add_big_resources` → `qt5_add_big_resources`.
- [x] `Qt6::*` link targets → `Qt5::*`.
- [ ] (Optional) Add a `if(QT_VERSION_MAJOR ...)` switch to keep Qt6 buildable.
- [x] Build with the Buildroot CMake toolchain; resolve compile/link errors.

### Phase 2 — C++ backend (src/)
- [x] `main.cpp`: `QQuickStyle`, `QSGRendererInterface`, engine setup compile on Qt5
      (no changes needed).
- [ ] Force OpenGL backend if needed (Qt5 has no RHI):
      `QQuickWindow::setSceneGraphBackend(...)` / env. (Not needed so far; revisit on target.)
- [x] `serialhandler.{h,cpp}`: `QSerialPort` API OK on Qt5 (`errorOccurred` exists since 5.8).
- [x] `FpsMonitor`: `QQuickWindow::beforeRendering` signal OK on Qt5.

### Phase 3 — QML imports & Controls
- [x] Imports OK for Qt5.15 (version-less imports supported in 5.15; explicit where
      already present). No churn required.
- [ ] Verify `Theme.qml` singleton + `qmldir` register correctly **on target** (built OK).
- [ ] Verify Material style (`QQuickStyle::setStyle("Material")`) at runtime on qt5quickcontrols2.

### Phase 4 — QtMultimedia (background video DISABLED)
> Decision: **disable background video playback temporarily** — software decode +
> composite of a looping `.mov` is expected to tank FPS on MA35D1. Re-enable later
> only if perf allows.
- [x] Replace looping background `Video` with gradient/solid in:
      `MenuPage.qml`, `ProcessingPage.qml`, `AdjustmentPage.qml` (+ removed `QtMultimedia`).
- [x] `StartupPage.qml`: replaced intro video with a static splash + `Timer`;
      `page.finished()` still fires to advance the flow.
- [x] `.mov` excluded from `qml.qrc` (saves ~30 MB in the binary); file kept on disk.
- [x] Keep `SoundEffect` (click sounds) in `Main.qml`.
- [ ] (Deferred) Full `Video`/`MediaPlayer` Qt6→Qt5 API port — only if video re-enabled.

### Phase 5 — Qt Quick 3D
- [ ] Verify `View3D`, `SceneEnvironment`, `PerspectiveCamera`,
      `DirectionalLight`/`PointLight`, `Loader3D`, `PrincipledMaterial` on qt5quick3d.
- [ ] Verify `.mesh` files load (check balsam/Quick3D mesh format vs 5.15 backport).
- [ ] **llvmpipe perf:** reduce/disable `antialiasingMode` MSAA/SSAA in
      MenuPage/AdjustmentPage/ProcessingPage; lower light/shadow cost
      (`castsShadow` off), simplify materials if FPS is too low.
- [ ] Re-export `.glb` (assets/models) with the Qt5 balsam if mesh format mismatches.

### Phase 5b — Asset downscaling (performance / size)
> ~94 MB of desktop-grade assets. Goal: shrink runtime cost & resource size.
- [x] **Textures/icons** (`assets/media/*.png`): downscaled the four food PNGs to
      512×512 (chicken/pizza/fish/meatball: 26.7MB → 1.26MB on disk; 144MB → ~4MB
      decoded). Added `sourceSize`/`asynchronous` to the carousel `Image` so decode
      is bounded. **This was the on-target OOM fix.**
- [x] **Video** (`assets/media/baking_pizza.mov`): already excluded from `qml.qrc`
      (Phase 4). Original kept on disk for later re-enable/downscaling.
- [ ] **Meshes** (`assets/convert_model/**/*.mesh`): decimate / re-export lower-poly
      models; the high-poly desktop meshes are costly for software vertex processing.
      (Mitigated for now: `Loader3D.active` gate keeps only the selected model
      resident instead of all five.)
- [ ] Trim `qml.qrc` to only the assets actually used (it embeds everything now).
- [x] Measure resulting binary size before/after: ~58MB → **33MB**.

### Phase 6 — Particles & misc
- [ ] Verify `QtQuick.Particles` smoke effect (ParticleSystem/Emitter/ItemParticle)
      in `MenuPage.qml` / `ProcessingPage.qml` (built OK; verify on target).
- [x] Fix missing default model `models/coffee_cup/Coffee_cup.qml`
      (`DrinkModel3D.qml` fallback now points to an existing model).

### Phase 7 — Integration & on-target testing
- [ ] Cross-compile, deploy `oven-gui` to MA35D1. (Cross-compile DONE; deploy pending.)
- [ ] Run: `QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./oven-gui`.
- [ ] Validate: startup splash → menu carousel → 3D model → adjust → processing → screensaver.
- [ ] Validate serial protocol with MCU (`/dev/ttySC1`, 115200).
- [ ] Use FPS overlay to tune; record acceptable FPS target.
- [ ] **Decide whether background video can be re-enabled** based on measured FPS
      (default: keep disabled).
- [ ] Optimize asset/resource size if boot/load time is an issue.

---

## Open Questions / Risks
- Quick3D performance under llvmpipe on dual-core 800 MHz — very tight; expect to
  cut AA/shadows and decimate meshes heavily.
- Mesh `.mesh` format compatibility between the model export tool and qt5quick3d 5.15.
- Multimedia/gstreamer codec support for `.mov` on the target (moot while video disabled).
- Qt5 has no RHI: confirm EGLFS OpenGL path works with Quick3D + llvmpipe.
- How much can assets be downscaled before visual quality is unacceptable to the customer?

## Next Step
> Port builds and cross-compiles. **Next: deploy to MA35D1 and run** with
> `QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./oven-gui`, read the FPS overlay,
> then tackle **Phase 5** (cut Quick3D AA/shadows) and **Phase 5b** (downscale
> textures/meshes) based on measured performance.
