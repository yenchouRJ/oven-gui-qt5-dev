# dev.md — Development Memo & TODO

Working notes and next-step checklist for porting **oven-gui** from Qt6 to **Qt5.15.18**
on the **MA35D1** (no GPU → EGLFS + Mesa llvmpipe) Buildroot target.

See `AGENT.md` for the full project analysis and component breakdown.

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
- [ ] Switch `find_package(Qt6 …)` → `find_package(Qt5 COMPONENTS Core Quick Qml
      QuickControls2 Multimedia SerialPort Widgets Quick3D)`.
- [ ] `qt_add_big_resources` → `qt5_add_big_resources`.
- [ ] `Qt6::*` link targets → `Qt5::*`.
- [ ] (Optional) Add a `if(QT_VERSION_MAJOR ...)` switch to keep Qt6 buildable.
- [ ] Build with the Buildroot CMake toolchain; resolve compile/link errors.

### Phase 2 — C++ backend (src/)
- [ ] `main.cpp`: verify `QQuickStyle`, `QSGRendererInterface`, engine setup compile on Qt5.
- [ ] Force OpenGL backend if needed (Qt5 has no RHI):
      `QQuickWindow::setSceneGraphBackend(...)` / env.
- [ ] `serialhandler.{h,cpp}`: check `QSerialPort` enum/API (mostly stable 5↔6).
- [ ] `FpsMonitor`: `QQuickWindow::beforeRendering` signal signature OK on Qt5.

### Phase 3 — QML imports & Controls
- [ ] Make imports explicit/version-correct for Qt5.15
      (`QtQuick 2.15`, `QtQuick.Controls 2.15`, `QtQuick.Layouts 1.15`,
      `QtQuick.Window 2.15`, `QtQuick3D <ver>`).
- [ ] Verify `Theme.qml` singleton + `qmldir` still register correctly.
- [ ] Verify Material style (`QQuickStyle::setStyle("Material")`) available in qt5quickcontrols2.

### Phase 4 — QtMultimedia (background video DISABLED for now)
> Decision: **disable background video playback temporarily** — software decode +
> composite of a looping `.mov` is expected to tank FPS on MA35D1. Re-enable later
> only if perf allows.
- [ ] Replace looping background `Video` with a static image / gradient / solid color in:
      `MenuPage.qml`, `ProcessingPage.qml`, `AdjustmentPage.qml`.
- [ ] `StartupPage.qml` intro video: make it optional (flag) or replace with a
      static splash; ensure `page.finished()` still fires to advance the flow.
- [ ] Gate video behind a build/runtime flag (e.g. `property bool enableVideo: false`)
      so it can be flipped back on for testing.
- [ ] Keep `SoundEffect` (click sounds) in `Main.qml` — verify Qt5 property names.
- [ ] (Deferred) Full `Video`/`MediaPlayer` Qt6→Qt5 API port
      (drop `AudioOutput`, `onErrorOccurred`→`onError`, `playbackState`) — only when
      video is re-enabled.

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
- [ ] **Textures/icons** (`assets/media/*.png`): downscale to display resolution,
      recompress; remove unused art.
- [ ] **Video** (`assets/media/baking_pizza.mov`, ~large): since playback is
      disabled (Phase 4), drop it from `qml.qrc` or replace with a tiny static frame
      to cut binary size; keep original out-of-tree for later.
- [ ] **Meshes** (`assets/convert_model/**/*.mesh`): decimate / re-export lower-poly
      models; the high-poly desktop meshes are costly for software vertex processing.
- [ ] Trim `qml.qrc` to only the assets actually used (it embeds everything now).
- [ ] Measure resulting binary size + load time before/after.

### Phase 6 — Particles & misc
- [ ] Verify `QtQuick.Particles` smoke effect (ParticleSystem/Emitter/ItemParticle)
      in `MenuPage.qml` / `ProcessingPage.qml`.
- [ ] Fix missing default model `models/coffee_cup/Coffee_cup.qml`
      (add asset or change `DrinkModel3D.qml` fallback).

### Phase 7 — Integration & on-target testing
- [ ] Cross-compile, deploy `oven-gui` to MA35D1.
- [ ] Run: `QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./oven-gui`.
- [ ] Validate: startup video → menu carousel → 3D model → adjust → processing → screensaver.
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
> Start with **Phase 0 + Phase 1**: confirm Buildroot packages, then convert
> `CMakeLists.txt` to Qt5 and get a clean cross-compile before touching QML.
