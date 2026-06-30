# Oven HMI — Qt5 Port (MA35D1)

Qt5 port of the Oven HMI (`oven-gui`), targeting **MA35D1** (dual-core @ 800 MHz,
**no GPU**) running Qt **5.15.18** from Buildroot, rendered with Mesa **llvmpipe**
(software OpenGL) via **EGLFS**.

See `../AGENT.md` and `../dev.md` for the full analysis and port roadmap.

## What changed vs the Qt6 release (`../Oven_HMI_G2L_fae_release`)
- **CMakeLists.txt:** `Qt6` → `Qt5` (`find_package(Qt5 ...)`, `Qt5::*` targets,
  `qt6_add_big_resources` → `qt5_add_big_resources`; added explicit `Gui`/`Qml`).
- **Background video DISABLED** (FPS on software rendering):
  - `StartupPage.qml` — intro `.mov` replaced by a static splash + timer that
    still emits `finished()` to advance to the menu.
  - `MenuPage.qml`, `ProcessingPage.qml`, `AdjustmentPage.qml` — looping background
    `Video` replaced by the existing gradient/solid background; `QtMultimedia`
    import removed from those files.
  - `Main.qml` keeps `QtMultimedia` only for `SoundEffect` (UI click sounds).
  - `qml.qrc` — `baking_pizza.mov` excluded from the binary (saves ~30 MB).
    File still on disk for later re-enable / downscaling.
- **Bug fixes:** `ProcessingPage.qml` `Root.finished()` → `processingRoot.finished()`;
  `DrinkModel3D.qml` default model fallback now points to an existing model
  (the original `coffee_cup/Coffee_cup.qml` asset is missing).
- **Qt6-only type removed:** `OrbitCameraController` (not in this Quick3D 1.15
  Helpers backport) dropped from `ProcessingPage.qml`; the model now auto-rotates
  via a `NumberAnimation` instead of mouse-orbit.

> Qt 5.15 supports inline `component` definitions and ES6 syntax, so most QML was
> kept as-is. **This Buildroot Qt5 build requires _versioned_ QML imports** (it
> rejects version-less `import QtQuick`), so all imports carry explicit versions:
> QtQuick 2.15, QtQuick.Controls 2.15, QtQuick.Layouts 1.15, QtQuick.Window 2.15,
> QtQuick.Particles 2.15, QtMultimedia 5.15, QtQuick3D 1.15, QtQuick3D.Helpers 1.15.
> The C++ backend (`serialhandler`, `FpsMonitor`, `main`) needs no source changes.

## Cross-compile (Buildroot)

Toolchain: `/home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5`

Option A — Buildroot CMake toolchain file:
```sh
BR=/home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5
cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=$BR/output/host/share/buildroot/toolchainfile.cmake \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

Option B — Buildroot SDK environment:
```sh
source /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5/output/host/environment-setup
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release   # 'cmake' alias is preconfigured
cmake --build build -j$(nproc)
```

The resulting binary is `build/oven-gui`.

## Run on the target (no GPU → llvmpipe)
```sh
QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./oven-gui
```

> `MESA-LOADER: failed to open ma35-drm ... _dri.so` on startup is **harmless** —
> Mesa probes for the (absent) hardware DRM driver and falls back to llvmpipe.

Serial protocol: opens `/dev/ttySC1` @ 115200 8N1 (see `src/serialhandler.cpp`).

## Notes / next steps
- If FPS is still too low: reduce/disable `antialiasingMode` (MSAA/SSAA) in
  `MenuPage.qml` / `AdjustmentPage.qml` / `ProcessingPage.qml`, drop `castsShadow`,
  and decimate meshes (see `../dev.md` Phase 5/5b).
- Confirm Buildroot `.config` enables `qt5quick3d`, `qt5quickcontrols2`,
  `qt5multimedia` (for `SoundEffect`), and `qt5serialport`.
