# AGENT.md — Oven HMI (Qt6 → Qt5 Port)

This file is the working memory / context for AI agents and developers working on
this repository. It describes **what the project is**, **how it is built**, and the
**plan to port it from Qt6 to Qt5** for the MA35D1 (no-GPU, llvmpipe) target.

---

## 1. Project Overview

**Name:** `oven-gui` (a.k.a. *Oven Station* / Oven HMI G2L)
**Type:** Qt Quick + Qt Quick 3D embedded HMI (Human-Machine Interface) for a smart oven.
**Owner:** Defond Electrical Industries Limited (proprietary).
**Current target stack:** Qt **6** (Quick3D), CMake.
**Goal target stack:** Qt **5.15.18** on Buildroot for **MA35D1** (ARM, **no hardware GPU** → Mesa **llvmpipe** software rasterizer via EGLFS).

### What the application does
It is a full-screen (1280×480) touch HMI for an oven that:
- Boots into a **startup/intro video** page, then a **carousel menu** of cooking
  programs (pizza, chicken, turkey, meatball, fish, bread).
- Shows a rotating **3D model** of the selected food item (Qt Quick 3D).
- Lets the user **adjust** cooking parameters (strength, grind, quantity, time, temperature).
- Shows a **processing/cooking** page with a 3D model, smoke particles and a background video.
- Has a **screensaver** and an **FPS overlay** (debug).
- Talks to the oven MCU over a **serial port** (`/dev/ttySC1`, 115200 8N1) using a simple
  newline-terminated token protocol; high-level tokens are mapped to Qt signals.

### Hardware / runtime context
- Platform: **MA35D1**, **dual-core @ 800 MHz**, **no GPU**.
- Renderer: **Mesa llvmpipe** (software OpenGL — everything runs on the CPU).
- Launch command (target):
  ```sh
  QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./oven-gui
  ```

> **Performance reality:** With software rendering on a dual-core 800 MHz CPU,
> the frame budget is extremely tight. The app was authored on Windows with
> desktop-grade assets (high-poly meshes, full-HD video, large textures), so the
> port **must** aggressively reduce asset cost — see §1.1 and the `dev.md` plan.

### 1.1 Asset / performance optimization policy (part of the port)
The Qt5 port is **not a 1:1 port** — it deliberately trims the runtime cost:
- **Disable background video playback (temporarily).** The looping `.mov`
  backgrounds (`StartupPage`, `MenuPage`, `ProcessingPage`, `AdjustmentPage`) are
  expected to be too expensive for software decode + composite on MA35D1.
  Replace with a static image / solid color / gradient for now; revisit later.
- **Downscale assets.** Reduce texture/icon resolution, recompress/shrink (or
  remove) the video, and consider lower-poly meshes / decimated `.glb` re-exports.
  The current footprint (~94 MB of assets) is desktop-sized and must come down.
- **Reduce 3D cost.** Lower or disable MSAA/SSAA, drop shadows, simplify lights.

---

## 2. Repository Structure

```
coffee-machine-qt5-rework/
├── AGENT.md                      # <- this file
├── dev.md                        # porting TODO / step memo
├── build/                        # local build output (gitignored)
└── Oven_HMI_G2L_fae_release/     # the actual project
    ├── CMakeLists.txt            # build script (currently Qt6)
    ├── src/                      # C++ backend
    │   ├── main.cpp              # entry point; loads qrc:/qml/Main.qml
    │   ├── serialhandler.{h,cpp} # QSerialPort wrapper → QML signals
    │   └── FpsMonitor.{h,cpp}    # per-frame FPS counter for the QQuickWindow
    ├── qml/                      # UI (QML) + qrc
    │   ├── qml.qrc               # resource manifest (QML + meshes + media)
    │   ├── qmldir                # registers `Theme` singleton
    │   ├── Main.qml              # ApplicationWindow root, page state machine
    │   ├── StartupPage.qml       # intro video
    │   ├── HomePage.qml          # headless; opens serial port
    │   ├── MenuPage.qml          # carousel menu + 3D preview + particles + video
    │   ├── CarouselMenu.qml      # carousel widget
    │   ├── DrinkModel3D.qml      # Loader3D that maps drinkId → model .qml
    │   ├── AdjustmentPage.qml    # parameter tuning + 3D view
    │   ├── ProcessingPage.qml    # cooking page + 3D + smoke particles + video
    │   ├── Screensaver.qml       # idle screensaver
    │   ├── Theme.qml             # singleton color/size theme
    │   └── drinks.js             # recipe/data table
    └── assets/
        ├── convert_model/        # Qt Quick 3D models exported as .qml + .mesh
        │   ├── pizza/  chicken/  turkey/  meatball/  fish/  bread/
        │   │   ├── <Name>.qml    # Node tree w/ PrincipledMaterial + Model
        │   │   └── meshes/*.mesh # Quick3D binary mesh files
        ├── models/               # source .glb models (Box, bread, chicken, ...)
        └── media/                # baking_pizza.mov, *.png icons, *.wav clicks
```

**Asset footprint (large — desktop-grade):** `convert_model/` ~33 MB, `media/` ~34 MB,
`models/` (.glb) ~27 MB (~94 MB total). These were produced on Windows for desktop
GPUs and are **too heavy for MA35D1 software rendering** — the port will downscale
textures/video and may decimate meshes (see §1.1 and `dev.md` Phase 5/6).
The `.glb` files in `assets/models/` are the **source** art; the runtime uses the
**converted** `assets/convert_model/<item>/*.qml + meshes/*.mesh` (Quick3D `balsam`
output). Only the converted models + media are compiled into the resource (`qml.qrc`).

> Note: `qml.qrc` references a default `models/coffee_cup/Coffee_cup.qml`
> (see `DrinkModel3D.qml` fallback) that is **not present** in the repo — a
> leftover from the coffee-machine origin. Verify before relying on the default branch.

---

## 3. Build System (current = Qt6)

`CMakeLists.txt` highlights:
- `project(oven-gui)`, C++17, `AUTOMOC/AUTORCC/AUTOUIC` on.
- `find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Multimedia SerialPort Widgets Quick3D)`
  - There is already a comment: *"need to modify to Qt5 for Remi Pi"* — this is a
    **customer note and can be ignored**; our target is MA35D1, not a Remi/Raspberry Pi.
- Resource is compiled with `qt_add_big_resources()` (the qrc is large due to meshes/video).
- Links the matching `Qt6::*` targets; installs `oven-gui` to `bin/`.

---

## 4. Qt Components / Modules In Use

| Area            | Module (Qt6)              | QML imports seen                         | Qt5 Buildroot pkg     |
|-----------------|---------------------------|------------------------------------------|-----------------------|
| Core/QML        | Qt6::Core, Qt6::Quick     | `QtQuick`                                | qt5base, qt5declarative |
| Controls        | Qt6::QuickControls2       | `QtQuick.Controls`                       | qt5quickcontrols2     |
| Layouts         | (Quick)                   | `QtQuick.Layouts`                        | qt5declarative        |
| Window          | (Quick)                   | `QtQuick.Window`                         | qt5declarative        |
| Multimedia      | Qt6::Multimedia           | `QtMultimedia` (`Video`, `MediaPlayer`, `SoundEffect`, `VideoOutput`) | qt5multimedia |
| **3D**          | Qt6::Quick3D              | `QtQuick3D`, `QtQuick3D.Helpers`         | **qt5quick3d**        |
| Particles       | (Quick particles)         | `QtQuick.Particles` (`ParticleSystem`, `Emitter`, `ItemParticle`) | qt5declarative |
| Serial          | Qt6::SerialPort           | (C++ `QSerialPort`)                      | qt5serialport         |
| Widgets         | Qt6::Widgets              | (linked; minimal use)                    | qt5base (widgets)     |

**Quick3D features used:** `View3D`, `SceneEnvironment` (Transparent background,
MSAA/SSAA antialiasing), `PerspectiveCamera`, `DirectionalLight`, `PointLight`,
`Node`, `Model`, `PrincipledMaterial`, `Loader3D`, `.mesh` assets.

**C++ backend (no Qt6-only APIs of note):**
- `SerialHandler : QObject` — `QSerialPort`/`QSerialPortInfo`, `Q_INVOKABLE open/close/send`,
  `Q_PROPERTY connected`, token router → signals (`statusReceived`, `progressReceived`,
  `temperatureReceived`, `drinkStartRequested`, `pageNavigationRequested`,
  legacy `powerOn/Off`, `saver`, `wakeScreen`).
- `FpsMonitor : QObject` — hooks `QQuickWindow::beforeRendering`, exposes `fps` property.
- `main.cpp` — `QGuiApplication`, `QQuickStyle::setStyle("Material")`,
  `QQmlApplicationEngine`, context props `serialHandler` + `fpsMonitor`.

---

## 5. Cross-Compile / Target Environment

- **Buildroot tree:** `/home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5`
- **Qt5 version:** `5.15.18` (`QT5_VERSION` in `package/qt5/qt5.mk`).
- **Available Qt5 packages:** `/home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5/package/qt5/`
  — includes `qt5base`, `qt5declarative`, `qt5quick3d`, `qt5quickcontrols2`,
  `qt5multimedia`, `qt5serialport`, `qt5quicktimeline`, `qt5svg`, etc.
- **Host tools:** `output/host/bin/qmake`, `output/host/bin/cmake`, `qt.conf`.
- **Source the toolchain** from the Buildroot tree before building (use its
  `output/host` CMake toolchain / `qmake`).
- **Run on target:**
  ```sh
  QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./oven-gui
  ```
  (EGLFS + Mesa llvmpipe software GL — no hardware GPU on MA35D1.)

> Confirm `qt5quick3d` (commit `b70ba91…`, the 5.15 backport) is **enabled** in the
> Buildroot `.config`, along with `qt5multimedia`, `qt5serialport`,
> `qt5quickcontrols2`, and gstreamer for video playback.

---

## 6. Key Qt6 → Qt5 Porting Concerns

These are the known breaking differences to address (details/steps tracked in `dev.md`):

1. **CMake / find_package**
   - `Qt6` → `Qt5`; `qt_add_big_resources` → `qt5_add_big_resources`;
     target names `Qt6::*` → `Qt5::*`.
   - Qt5 needs `find_package(Qt5 COMPONENTS Core Quick QuickControls2 Multimedia SerialPort Widgets Quick3D Qml)`.

2. **QML versioned imports**
   - Qt6 allows version-less imports (`import QtQuick`). Qt5.15 generally accepts
     version-less imports too, but **be explicit** where needed
     (`import QtQuick 2.15`, `import QtQuick.Controls 2.15`, `import QtQuick3D 1.15`/`6.x`→Qt5 module version).
   - `QtQuick3D` module versioning differs between Qt5 backport and Qt6.

3. **QtMultimedia (biggest change)**
   - Qt6 `MediaPlayer`/`Video`/`VideoOutput`/`AudioOutput` API differs from Qt5.
   - Qt5: `Video` has `autoPlay`, `loops`, `muted`, `fillMode`,
     `onStopped`/`playbackState` (no separate `AudioOutput` object).
   - `SoundEffect` exists in both but check property names.
   - `onErrorOccurred` (Qt6) vs `onError`/`error` (Qt5).
   - Video playback on target relies on **gstreamer** backend in Buildroot.
   - **Decision: background video is disabled for the initial port** (perf). The
     porting effort on `Video` is therefore minimal at first — keep the startup
     intro video optional/behind a flag and replace in-page backgrounds with a
     static image/gradient. Full multimedia port can be revisited once FPS is known.

4. **Qt Quick 3D**
   - Qt5 has a backported `QtQuick3D` (5.15). Verify `SceneEnvironment`,
     `antialiasingMode` (MSAA/SSAA), `Loader3D`, `PrincipledMaterial`,
     `.mesh` format compatibility. **Software rendering (llvmpipe) makes MSAA/SSAA
     expensive — likely need to reduce/disable AA for acceptable FPS.**

5. **Rendering backend**
   - Qt6 RHI vs Qt5 OpenGL. On Qt5 + EGLFS + llvmpipe, force the GL backend.
   - Expect low FPS in software; the `FpsMonitor` overlay helps tuning.

6. **Particles** — `QtQuick.Particles` API is largely stable 5↔6; verify.

7. **C++ backend** — minimal changes expected; check `QSGRendererInterface`,
   include paths, and any version-conditional APIs.

8. **Missing default model** — `models/coffee_cup/Coffee_cup.qml` referenced but absent.

9. **Asset downscaling (performance)** — desktop-grade assets (~94 MB) must be
   reduced: shrink/recompress textures & icons, shrink or drop the `.mov` video,
   and decimate meshes / re-export lower-poly `.glb`. Tracked in `dev.md` Phase 5/6.

---

## 7. Conventions for Agents

- The application code lives under `Oven_HMI_G2L_fae_release/`.
- Keep `AGENT.md` (this file) and `dev.md` updated as the port progresses.
- Prefer editing the existing `CMakeLists.txt` to add a Qt5/Qt6 switch rather than
  forking the build.
- Do not commit build artifacts (`build/` is gitignored).
- Validate every change against the **target** (cross-compile + llvmpipe), not just host Qt6.
