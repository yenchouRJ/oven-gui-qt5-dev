# buildroot-qt6-patches

Changes required to add Qt Quick 3D (qt6quick3d) support to the `ma35d1_br24_linux6.6`
Buildroot tree. All files are relative to the Buildroot root (`ma35d1_br24_linux6.6/`).

## What to apply

### 1. New packages (copy entire directories)

```
package/qt6/qt6declarative/     → copy as-is
package/qt6/qt6shadertools/     → copy as-is
package/qt6/qt6multimedia/      → copy as-is
package/qt6/qt6quick3d/         → copy as-is (includes patch file)
```

```bash
cd /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6

cp -r <this_dir>/package/qt6/qt6declarative  package/qt6/
cp -r <this_dir>/package/qt6/qt6shadertools  package/qt6/
cp -r <this_dir>/package/qt6/qt6multimedia   package/qt6/
cp -r <this_dir>/package/qt6/qt6quick3d      package/qt6/
```

### 2. Patch existing files

```bash
cd /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_linux6.6

# Config.in — register the 4 new packages in the Qt6 block
patch -p1 < <this_dir>/package/qt6/Config.in.patch

# qt6base.mk — extend HOST_QT6BASE_CONF_OPTS for host tool builds
patch -p1 < <this_dir>/package/qt6/qt6base/qt6base.mk.patch
```

## Why each change is needed

### New packages

| Package | Why needed |
|---|---|
| `qt6declarative` | Provides `Qt::Quick`, `Qt::Qml`, `Qt::QuickControls2`. Also builds host tools `qmlcachegen` and `qmltyperegistrar` via `$(eval $(host-cmake-package))` |
| `qt6shadertools` | Provides the `qsb` (Qt Shader Baker) host tool. `qt6quick3d` uses `qsb` at build time to pre-compile GLSL shaders into `.qsb` bundles |
| `qt6multimedia` | Provides `Qt::Multimedia` (audio/video). Depends on `qt6declarative` |
| `qt6quick3d` | Provides `Qt::Quick3D`. Builds a host copy (`host-qt6quick3d`) that produces `balsam` and other asset-import host tools required when cross-compiling the target library |

### `qt6base.mk` — HOST_QT6BASE_CONF_OPTS

The original `HOST_QT6BASE_CONF_OPTS` only had `-DFEATURE_gui=OFF`. The new set enables
Qt::Gui, Qt::Concurrent, and Qt::Widgets on the host, which are required by `host-qt6quick3d`:

| Flag | Reason |
|---|---|
| `-DFEATURE_gui=ON` | `qtshadertools/CMakeLists.txt` checks `if(NOT TARGET Qt::Gui)` and returns early — an empty build — when Gui is absent. All host tool packages (shadertools, declarative, quick3d) need it |
| `-DFEATURE_concurrent=ON` | On Linux x86_64, `host-qt6quick3d` enables the bundled Embree lightmapper. `Quick3DRuntimeRender` unconditionally links `Qt::Concurrent` when Embree is active |
| `-DFEATURE_widgets=ON` | `host-qt6quick3d` builds `balsamui` when `Qt::Concurrent` is present; `balsamui` links `Qt::Widgets` |
| `-DFEATURE_opengl=OFF` + `-DINPUT_opengl=no` | Host has EGL headers (Mesa). Without both flags Qt6 auto-detects OpenGL ES 2 and fails a link test for it |
| `-DFEATURE_linuxfb=ON` | Satisfies the "No QPA platform plugin" cmake check without needing any system display libraries |
| `-DFEATURE_system_freetype=OFF` | In Qt 6.4.3, `QGenericUnixFontDatabase` is a type alias for `QFreeTypeFontDatabase` when fontconfig is absent. FreeType must be compiled in (using Qt's bundled copy); completely disabling it (`FEATURE_freetype=OFF`) removes the vtable and causes a linker error in the QPA plugins |
| `FEATURE_egl/vulkan/xcb/kms/fontconfig/libinput/tslib/printsupport/harfbuzz/png/gif/jpeg=OFF` | Prevent auto-detection of host system display/font libraries that are not needed for host tool execution |
| `FEATURE_network=OFF` | Not needed for host tools. `qt6quick3d`'s `materialeditor` tool would require it, but it is guarded by the patch below |

### `qt6quick3d` patch — `0001-tools-make-materialeditor-optional-when-network-absent.patch`

`tools/materialeditor/` unconditionally includes `<QtNetwork/qlocalsocket.h>`, but the
host Qt6 base is built without the Network module. The patch adds the same
`if(TARGET Qt::Network)` guard that upstream Qt added after 6.4.x, skipping
`materialeditor` when Network is absent (the essential host tools `balsam`, `meshdebug`,
`shadergen` are unaffected).

## Menuconfig settings

After applying the files above, run `make menuconfig` and enable under
**Target packages → Libraries → Graphics → Qt6**:

| Config symbol | Value |
|---|---|
| `BR2_PACKAGE_QT6` | `y` |
| `BR2_PACKAGE_QT6BASE_GUI` | `y` |
| `BR2_PACKAGE_QT6BASE_WIDGETS` | `y` |
| `BR2_PACKAGE_QT6BASE_NETWORK` | `y` (required by qt6multimedia — its CMakeLists.txt returns early if Qt::Network is absent) |
| `BR2_PACKAGE_QT6BASE_EGLFS` | `y` (MA35D1 display) |
| `BR2_PACKAGE_QT6BASE_OPENGL_ES2` | `y` (MA35D1 GPU) |
| `BR2_PACKAGE_QT6DECLARATIVE` | `y` |
| `BR2_PACKAGE_QT6SHADERTOOLS` | `y` |
| `BR2_PACKAGE_QT6MULTIMEDIA` | `y` |
| `BR2_PACKAGE_QT6SERIALPORT` | `y` |
| `BR2_PACKAGE_QT6QUICK3D` | `y` |
