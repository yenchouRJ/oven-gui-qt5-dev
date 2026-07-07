# 3D Project

- local buildroot : /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6
- latest buildroot repo : /home/joeylu/opencode/thirdparty/buildroot
- env : source output/host/environment-setup
- Source app : /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6/board/nuvoton/ma35d1/modules/coffee-machine-demo-qtlay/Oven_HMI_G2L_fae_release
- Binary for windows : /home/joeylu/Documents/workspace/ma35d1/demo/oven/ovenbin/oven
- target dir : /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6/board/nuvoton/ma35d1/modules/coffee-machine-demo-qtlay/usr/bin

I want to cross compile app and run on target board.

# Application Overview

- **Build system**: CMake 3.16+, C++17
- **Target arch**: aarch64 (Nuvoton MA35D1)
- **Cross-compiler**: `aarch64-nuvoton-linux-gnu-g++`
- **Qt version**: 6.4.3 (as defined in buildroot `package/qt6/qt6.mk`)

Required Qt6 modules (from `CMakeLists.txt`):

| Qt module | Buildroot package | Status in original tree |
|---|---|---|
| Qt6::Core, Gui, Widgets | `qt6base` | available |
| Qt6::Quick, QuickControls2 | `qt6declarative` | **must add** |
| Qt6::Multimedia | `qt6multimedia` | **must add** |
| Qt6::SerialPort | `qt6serialport` | available |
| Qt6::Quick3D | `qt6quick3d` | **must add** |
| Qt6ShaderTools (host build tool) | `qt6shadertools` | **must add** |

All required files are in `buildroot-qt6-patches/` next to this document.

# Build

## Step 1: Apply buildroot package changes

```bash
cd /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6
PATCHES=board/nuvoton/ma35d1/modules/coffee-machine-demo-qtlay/buildroot-qt6-patches

# Copy the 4 new packages
cp -r $PATCHES/package/qt6/qt6declarative  package/qt6/
cp -r $PATCHES/package/qt6/qt6shadertools  package/qt6/
cp -r $PATCHES/package/qt6/qt6multimedia   package/qt6/
cp -r $PATCHES/package/qt6/qt6quick3d      package/qt6/

# Patch Config.in (registers the new packages in the Qt6 menu block)
patch -p1 < $PATCHES/package/qt6/Config.in.patch

# Patch qt6base.mk (extends HOST_QT6BASE_CONF_OPTS for host tool builds)
patch -p1 < $PATCHES/package/qt6/qt6base/qt6base.mk.patch
```

### Why four new packages are needed

The original buildroot tree ships only `qt6base`, `qt6core5compat`, `qt6serialbus`,
`qt6serialport`, and `qt6svg`. The application requires four additional packages:

- **`qt6declarative`** — provides `Qt::Quick`, `Qt::Qml`, `Qt::QuickControls2`.
  Also builds host tools `qmlcachegen` and `qmltyperegistrar` via
  `$(eval $(host-cmake-package))`, which are invoked at compile time to pre-compile
  QML type registrations into the binary.

- **`qt6shadertools`** — provides the `qsb` (Qt Shader Baker) host tool.
  `qt6quick3d` uses `qsb` at build time to compile GLSL shaders into `.qsb` shader
  bundles for the target. Without it, `qt6quick3d` configure fails with
  "Failed to find the host tool Qt6::qsb".

- **`qt6multimedia`** — provides `Qt::Multimedia` (audio/video).
  Depends on `qt6declarative`. Also requires `Qt::Network` at configure time —
  `qtmultimedia 6.4.3/CMakeLists.txt` has an unconditional `if(NOT TARGET Qt::Network) return()`
  guard, so the entire build silently skips if network is absent from `qt6base`, producing no
  libraries and no cmake config files. `Config.in` selects `BR2_PACKAGE_QT6BASE_NETWORK`
  to enforce this automatically.

- **`qt6quick3d`** — provides `Qt::Quick3D`. Requires a host-side build
  (`host-qt6quick3d`) that produces `balsam` (3D asset converter) and related
  host tools. Without `host-qt6quick3d`, the target configure fails with
  "Failed to find the host tool Qt6::balsam".

### Why `qt6base.mk` must be patched (`HOST_QT6BASE_CONF_OPTS`)

When cross-compiling Qt modules that provide host-side tools (shadertools, declarative,
quick3d), Buildroot builds a host copy of `qt6base`. The original tree builds it with
`-DFEATURE_gui=OFF`, which causes cascading failures in all downstream host tool builds.
The patch enables `Qt::Gui`, `Qt::Concurrent`, and `Qt::Widgets` on the host:

| Flag | Reason |
|---|---|
| `-DFEATURE_gui=ON` | `qtshadertools/CMakeLists.txt` returns early (`return()`) if `Qt::Gui` is absent — the host build produces nothing and `qsb` is never installed |
| `-DFEATURE_concurrent=ON` | On Linux x86_64, `host-qt6quick3d` auto-enables the bundled Embree lightmapper; `Quick3DRuntimeRender` then links `Qt::Concurrent` unconditionally |
| `-DFEATURE_widgets=ON` | When `Qt::Concurrent` is present, `host-qt6quick3d` also builds `balsamui`, which links `Qt::Widgets` |
| `-DFEATURE_opengl=OFF` + `-DINPUT_opengl=no` | Host system has EGL/Mesa headers; Qt6 auto-detects them and enables `opengles2`, then fails a link test. Both flags are required: `FEATURE_opengl=OFF` sets the resolved feature state; `INPUT_opengl=no` is the user-visible cmake input that the fatal configure check reads |
| `-DFEATURE_linuxfb=ON` | Satisfies the "No QPA platform plugin enabled" cmake check without requiring any external display libraries |
| `-DFEATURE_system_freetype=OFF` | In Qt 6.4.3, `QGenericUnixFontDatabase` is a type alias for `QFreeTypeFontDatabase` when fontconfig is absent. FreeType must be compiled in using Qt's bundled copy; completely disabling it with `FEATURE_freetype=OFF` (the approach that works in Qt >= 6.7) removes the vtable and causes a linker error in the QPA plugins on 6.4.3 |
| `egl/vulkan/xcb/kms/fontconfig/libinput/tslib/png/gif/jpeg/harfbuzz/printsupport=OFF` | Prevents auto-detection of host display and font libraries that are not needed for host tool execution |

### Why `qt6quick3d` includes a source patch

`qt6quick3d 6.4.3` unconditionally adds `tools/materialeditor/` even though it
requires `Qt::Network` (`QLocalSocket`/`QLocalServer`). The host Qt6 base is built
without the Network module. The patch
`0001-tools-make-materialeditor-optional-when-network-absent.patch` adds the same
`if(TARGET Qt::Network)` guard that Qt upstream added after 6.4.x, skipping
`materialeditor` silently when Network is absent. The essential host tools (`balsam`,
`meshdebug`, `shadergen`) are unaffected.

## Step 2: Enable Qt6 in buildroot menuconfig

```bash
cd /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6
make menuconfig
```

Navigate to **Target packages → Libraries → Graphics → Qt6** and enable:

| Config symbol | Description |
|---|---|
| `BR2_PACKAGE_QT6` | Qt6 top-level enable |
| `BR2_PACKAGE_QT6BASE_GUI` | gui module (QtGui) |
| `BR2_PACKAGE_QT6BASE_WIDGETS` | widgets module (QtWidgets) |
| `BR2_PACKAGE_QT6BASE_NETWORK` | network module — **required by qt6multimedia** (its CMakeLists.txt returns early if Qt::Network is absent) |
| `BR2_PACKAGE_QT6BASE_EGLFS` | eglfs platform plugin (MA35D1 display) |
| `BR2_PACKAGE_QT6BASE_OPENGL_ES2` | OpenGL ES 2.x (MA35D1 GPU) |
| `BR2_PACKAGE_QT6DECLARATIVE` | Qt QML / Quick module |
| `BR2_PACKAGE_QT6SHADERTOOLS` | Qt Shader Tools (`qsb` host tool) |
| `BR2_PACKAGE_QT6MULTIMEDIA` | Qt Multimedia |
| `BR2_PACKAGE_QT6MULTIMEDIA_GSTREAMER` | GStreamer backend — **required for Video QML type** (sub-option under qt6multimedia) |
| `BR2_PACKAGE_QT6SERIALPORT` | Qt Serial Port |
| `BR2_PACKAGE_QT6QUICK3D` | Qt Quick 3D |

Save and exit.

### Why GStreamer is required

Qt6 Multimedia uses a plugin-based backend architecture. On Linux, the only supported
backend in Qt 6.4.x is GStreamer. Without it, any use of the `Video` QML type causes
Qt to print `could not load multimedia backend ""` and abort. The
`BR2_PACKAGE_QT6MULTIMEDIA_GSTREAMER` option:

- Sets `-DFEATURE_gstreamer=ON`, `-DFEATURE_gstreamer_1_0=ON`, `-DFEATURE_gstreamer_app=ON`
  in `qt6multimedia.mk`
- Auto-selects `gstreamer1` and `gst1-plugins-base` (with the `appsink`/`appsrc` plugins)
  as buildroot dependencies

For the `baking_pizza.mov` background videos to actually decode and play you will also
need GStreamer decode plugins on the target rootfs. Enable these additional packages in
menuconfig under **Target packages → Libraries → Multimedia → GStreamer 1.x**:

| Package | Purpose |
|---|---|
| `BR2_PACKAGE_GST1_PLUGINS_GOOD` | `qtdemux` (QuickTime/MOV container demuxer) |
| `BR2_PACKAGE_GST1_PLUGINS_GOOD_PLUGIN_ISOMP4` | MOV/MP4 demuxer plugin within gst1-plugins-good |
| `BR2_PACKAGE_GST1_LIBAV` | FFmpeg wrapper — H.264 decoder for the video track |

Without these, Qt Multimedia loads (no more abort) but video frames stay black.

## Step 3: Build Qt6 in buildroot

```bash
cd /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6

make qt6base
make qt6declarative
make qt6shadertools
make qt6multimedia
make qt6serialport
make qt6quick3d
```

Buildroot resolves the host/target dependency order automatically. Each `make <pkg>`
call also builds the required `host-<pkg>` prerequisites.

This installs:
- Host tools (`qmlcachegen`, `qsb`, `balsam`, `moc`, `rcc`) under `output/host/bin/` and `output/host/libexec/`
- Target Qt6 libraries into `output/host/aarch64-nuvoton-linux-gnu/sysroot/usr/`
- Qt6 cmake config files required for `find_package(Qt6 ...)` during app cross-compilation

## Step 4: Cross-compile the application

```bash
cd /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6

# Source the environment (sets CC, CXX, PKG_CONFIG_*, SYSROOT, SDK_PATH, etc.)
source output/host/environment-setup

mkdir -p /tmp/oven-build && cd /tmp/oven-build

cmake \
  -DCMAKE_TOOLCHAIN_FILE=$SDK_PATH/share/buildroot/toolchainfile.cmake \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_PREFIX_PATH="$SDK_PATH/aarch64-nuvoton-linux-gnu/sysroot/usr" \
  /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6/board/nuvoton/ma35d1/modules/coffee-machine-demo-qtlay/Oven_HMI_G2L_fae_release

make -j$(nproc)
```

The toolchain file at `output/host/share/buildroot/toolchainfile.cmake` sets
`QT_HOST_PATH=$(HOST_DIR)` and `QT_HOST_PATH_CMAKE_DIR=$(HOST_DIR)/lib/cmake`,
which tells Qt6 CMake where to find the host-side tools (`qmlcachegen`, `qsb`,
`balsam`) when cross-compiling.

## Step 5: Install to overlay target dir

```bash
cp /tmp/oven-build/oven-gui \
   /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6/board/nuvoton/ma35d1/modules/coffee-machine-demo-qtlay/usr/bin/
```

The post-build script copies overlay contents into the rootfs image automatically during `make`.

## Step 6: Run on target board

```bash
# On the MA35D1 target board:
export QT_QPA_PLATFORM=eglfs    # EGL/GPU display (recommended for MA35D1)
# or
export QT_QPA_PLATFORM=linuxfb  # software framebuffer fallback

./oven-gui
```

# Notes

- `qt_add_big_resources()` in `CMakeLists.txt` compiles QML resources into the binary
  at build time using the host-side `rcc` tool. The host Qt6 build (Step 3) is required
  even for a cross-compiled binary.
- `Qt6::Quick3D` depends on `qt6shadertools` at build time for the `qsb` shader
  compiler. Buildroot's dependency graph handles the build order automatically.
- If any host package must be rebuilt from scratch (e.g. after changing
  `HOST_QT6BASE_CONF_OPTS`), clean the full host + target chain before rebuilding:

```bash
make host-qt6base-dirclean \
     host-qt6shadertools-dirclean \
     host-qt6declarative-dirclean \
     host-qt6quick3d-dirclean \
     qt6shadertools-dirclean \
     qt6declarative-dirclean \
     qt6multimedia-dirclean \
     qt6quick3d-dirclean

make qt6quick3d
```

---

# Alternative: Qt5 Build (not yet verified)

The `CMakeLists.txt` already hints at this path with the comment:
```cmake
find_package(Qt6 REQUIRED COMPONENTS #need to modify to Qt5 for Remi Pi
```

Qt5 version is **5.15.11** (LTS). The steps below are planned but **have not been built or tested**.

## Why Qt5 is easier here

| Needed module | Qt5 buildroot package | Status |
|---|---|---|
| Core, Gui, Widgets | `qt5base` | available |
| Quick, QML | `qt5declarative` | available |
| QuickControls2 | `qt5quickcontrols2` | available |
| Multimedia | `qt5multimedia` | available |
| SerialPort | `qt5serialport` | available |
| **Quick3D** | **`qt5quick3d`** | **MISSING — needs adding** |

Only **one** package is missing for Qt5, versus four for Qt6.

> **Note**: `qt53d` in buildroot is the older **Qt 3D** framework (`Qt5::3DCore`, `Qt5::3DRender`, etc.) from the `qt3d` repository. The app uses `import QtQuick3D` which is **Qt Quick 3D** from the separate `qtquick3d` repository — a completely different module. They cannot be substituted.

## Step 1: Add qt5quick3d buildroot package

Create `package/qt5/qt5quick3d/qt5quick3d.mk`:
```makefile
################################################################################
#
# qt5quick3d
#
################################################################################

QT5QUICK3D_VERSION = $(QT5_VERSION)
QT5QUICK3D_SITE = $(QT5_SITE)/qtquick3d/-/archive/v$(QT5QUICK3D_VERSION)
QT5QUICK3D_SOURCE = qtquick3d-v$(QT5QUICK3D_VERSION).tar.bz2
QT5QUICK3D_DEPENDENCIES = qt5declarative qt5base
QT5QUICK3D_INSTALL_STAGING = YES
QT5QUICK3D_SYNC_QT_HEADERS = YES

QT5QUICK3D_LICENSE = GPL-2.0 or GPL-3.0 or LGPL-3.0
QT5QUICK3D_LICENSE_FILES = LICENSE.GPL2 LICENSE.GPL3 LICENSE.LGPLv3

$(eval $(qmake-package))
```

Create `package/qt5/qt5quick3d/Config.in`:
```
config BR2_PACKAGE_QT5QUICK3D
    bool "qt5quick3d"
    depends on BR2_PACKAGE_QT5_JSCORE_AVAILABLE  # qt5declarative/quick
    depends on BR2_PACKAGE_QT5_GL_AVAILABLE
    select BR2_PACKAGE_QT5DECLARATIVE
    select BR2_PACKAGE_QT5DECLARATIVE_QUICK
    help
      Qt Quick 3D module. Provides a high-level API for creating 3D
      content integrated into Qt Quick scenes.

      https://doc.qt.io/qt-5/qtquick3d-index.html
```

Register it in `package/qt5/Config.in` inside the `if BR2_PACKAGE_QT5` block by adding:
```
source "package/qt5/qt5quick3d/Config.in"
```

## Step 2: Enable Qt5 modules in buildroot menuconfig

Run `make menuconfig` and enable under **Target packages → Libraries → Graphics → Qt5**:

| Config symbol | Description |
|---|---|
| `BR2_PACKAGE_QT5` | Qt5 top-level enable |
| `BR2_PACKAGE_QT5BASE_GUI` | gui module (QtGui) |
| `BR2_PACKAGE_QT5BASE_WIDGETS` | widgets module (QtWidgets) |
| `BR2_PACKAGE_QT5BASE_OPENGL` | OpenGL support |
| `BR2_PACKAGE_QT5BASE_OPENGL_ES2` | OpenGL ES 2.x (for MA35D1 GPU) |
| `BR2_PACKAGE_QT5BASE_EGLFS` | eglfs platform plugin (for MA35D1 display) |
| `BR2_PACKAGE_QT5DECLARATIVE` | Qt QML module |
| `BR2_PACKAGE_QT5DECLARATIVE_QUICK` | Qt Quick sub-module |
| `BR2_PACKAGE_QT5QUICKCONTROLS2` | Qt Quick Controls 2 |
| `BR2_PACKAGE_QT5MULTIMEDIA` | Qt Multimedia |
| `BR2_PACKAGE_QT5SERIALPORT` | Qt Serial Port |
| `BR2_PACKAGE_QT5QUICK3D` | Qt Quick 3D (after adding the package) |

## Step 3: CMakeLists.txt changes

Three edits are required in `Oven_HMI_G2L_fae_release/CMakeLists.txt`:

**1. Switch find_package from Qt6 to Qt5** (line 11):
```cmake
# Before
find_package(Qt6 REQUIRED COMPONENTS
# After
find_package(Qt5 REQUIRED COMPONENTS
```

**2. Replace qt_add_big_resources with the Qt5 version** (line 31):
```cmake
# Before
qt_add_big_resources(BIG_RESOURCES qml/qml.qrc)
# After
qt5_add_big_resources(BIG_RESOURCES qml/qml.qrc)
```

**3. Switch target_link_libraries from Qt6:: to Qt5::** (lines 38-46):
```cmake
# Before
target_link_libraries(oven-gui PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::SerialPort
    Qt6::Widgets
    Qt6::Quick3D
)
# After
target_link_libraries(oven-gui PRIVATE
    Qt5::Core
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Multimedia
    Qt5::SerialPort
    Qt5::Widgets
    Qt5::Quick3D
)
```

## Step 4: QML import fixes

Qt5 requires explicit version numbers on all import statements. The following unversioned imports (Qt6 style) must be updated:

| File | Old | New |
|---|---|---|
| `Main.qml` | `import QtQuick` | `import QtQuick 2.15` |
| `Main.qml` | `import QtQuick.Controls` | `import QtQuick.Controls 2.15` |
| `Main.qml` | `import QtMultimedia` | `import QtMultimedia 5.15` |
| `MenuPage.qml` | `import QtQuick` | `import QtQuick 2.15` |
| `MenuPage.qml` | `import QtQuick.Controls` | `import QtQuick.Controls 2.15` |
| `MenuPage.qml` | `import QtQuick.Layouts` | `import QtQuick.Layouts 1.15` |
| `MenuPage.qml` | `import QtMultimedia` | `import QtMultimedia 5.15` |
| `MenuPage.qml` | `import QtQuick3D` | `import QtQuick3D 1.15` |
| `MenuPage.qml` | `import QtQuick3D.Helpers` | `import QtQuick3D.Helpers 1.15` |
| `MenuPage.qml` | `import QtQuick.Particles` | `import QtQuick.Particles 2.15` |
| `AdjustmentPage.qml` | `import QtMultimedia` | `import QtMultimedia 5.15` |
| `AdjustmentPage.qml` | `import QtQuick3D` | `import QtQuick3D 1.15` |
| `AdjustmentPage.qml` | `import QtQuick3D.Helpers` | `import QtQuick3D.Helpers 1.15` |
| `DrinkModel3D.qml` | `import QtQuick3D` | `import QtQuick3D 1.15` |
| `ProcessingPage.qml` | `import QtMultimedia` | `import QtMultimedia 5.15` |
| `ProcessingPage.qml` | `import QtQuick3D` | `import QtQuick3D 1.15` |
| `ProcessingPage.qml` | `import QtQuick3D.Helpers` | `import QtQuick3D.Helpers 1.15` |
| `StartupPage.qml` | `import QtQuick` | `import QtQuick 2.15` |
| `StartupPage.qml` | `import QtQuick.Controls` | `import QtQuick.Controls 2.15` |
| `StartupPage.qml` | `import QtMultimedia` | `import QtMultimedia 5.15` |

## Step 5: Build Qt5 in buildroot

```bash
cd /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6

make qt5base
make qt5declarative
make qt5quickcontrols2
make qt5multimedia
make qt5serialport
make qt5quick3d
```

## Step 6: Cross-compile the application

```bash
cd /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6

source output/host/environment-setup

mkdir -p /tmp/oven-build-qt5 && cd /tmp/oven-build-qt5

cmake \
  -DCMAKE_TOOLCHAIN_FILE=$SDK_PATH/share/buildroot/toolchainfile.cmake \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_PREFIX_PATH="$SDK_PATH/aarch64-nuvoton-linux-gnu/sysroot/usr" \
  /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6/board/nuvoton/ma35d1/modules/coffee-machine-demo-qtlay/Oven_HMI_G2L_fae_release

make -j$(nproc)
```

## Step 7: Install to overlay

```bash
cp /tmp/oven-build-qt5/oven-gui \
   /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6/board/nuvoton/ma35d1/modules/coffee-machine-demo-qtlay/usr/bin/
```

## Now status
There are too many unresolved issue with qt6, so I will use qt5 instead. This almost discard.