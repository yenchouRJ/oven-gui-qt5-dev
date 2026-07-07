# br2_qt5_patches — Qt Quick 3D package for Nuvoton ma35d1_br24_qt5

## What this is

The Nuvoton **ma35d1_br24_qt5** buildroot tree (buildroot-2024.02 based)
does not include a `qt5quick3d` package.  This directory contains the single
patch that adds it, plus the plain package files for reference.

The patch is taken verbatim from the `package/qt5` sub-repository inside
`ma35d1_br24_qt5` (commit `368cec9`, author `yclu4 <yclu4@nuvoton.com>`).

## Base tree

| Item | Detail |
|------|--------|
| Repo | Nuvoton `ma35d1_br24_qt5` |
| Sub-repo | `package/qt5/` (has its own git, 2 commits) |
| Apply onto | sub-repo commit `cd21a5a` ("first commit") |
| Patch commit | sub-repo commit `368cec9` ("important: add qt5quick3d module to buildroot") |

## Contents

```
br2_qt5_patches/
├── README.md
├── 0001-add-qt5quick3d-package.patch       ← apply with git am / git apply
└── package/qt5/qt5quick3d/                ← plain files for inspection
    ├── Config.in
    └── qt5quick3d.mk
```

## Applying

The patch targets the `package/qt5/` sub-repository, **not** the main
buildroot repo root.  Apply it from inside `package/qt5/`:

```sh
BR=/home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5   # adjust path

cd $BR/package/qt5
git am /path/to/br2_qt5_patches/0001-add-qt5quick3d-package.patch
# or: git apply /path/to/br2_qt5_patches/0001-add-qt5quick3d-package.patch
```

After applying, verify:

```sh
ls $BR/package/qt5/qt5quick3d/
# → Config.in  qt5quick3d.mk

grep "qt5quick3d" $BR/package/qt5/Config.in
# → source "package/qt5/qt5quick3d/Config.in"
```

## What the patch adds

Three changes inside `package/qt5/`:

1. **`Config.in`** — one line added after `qt5quickcontrols2`:
   ```
   source "package/qt5/qt5quick3d/Config.in"
   ```

2. **`qt5quick3d/Config.in`** (new file) — menuconfig symbol
   `BR2_PACKAGE_QT5QUICK3D`, depends on JS core + GL, selects
   `qt5declarative` + `qt5declarative_quick`.

3. **`qt5quick3d/qt5quick3d.mk`** (new file) — `qmake-package` using
   `$(QT5_VERSION)` (inherits whatever version is set in `qt5.mk`).
   Downloads from `$(QT5_SITE)/qtquick3d/-/archive/v$(QT5QUICK3D_VERSION)`.

No hash file is included — buildroot will download and verify on first build.
If your network cannot reach `invent.kde.org`, pre-download the tarball and
place it in `$(BR2_DL_DIR)`.

## Enabling in menuconfig

After applying the patch, run `make menuconfig` from the buildroot root and
navigate to **Target packages → Libraries → Graphics → Qt5**.  Enable:

| Symbol | Description |
|--------|-------------|
| `BR2_PACKAGE_QT5` | Qt5 top-level |
| `BR2_PACKAGE_QT5BASE_GUI` | QtGui |
| `BR2_PACKAGE_QT5BASE_OPENGL` | OpenGL |
| `BR2_PACKAGE_QT5BASE_OPENGL_ES2` | GLES 2.x (MA35D1) |
| `BR2_PACKAGE_QT5BASE_EGLFS` | EGLFS platform plugin |
| `BR2_PACKAGE_QT5DECLARATIVE` | QtQml |
| `BR2_PACKAGE_QT5DECLARATIVE_QUICK` | QtQuick |
| `BR2_PACKAGE_QT5QUICKCONTROLS2` | Qt Quick Controls 2 |
| `BR2_PACKAGE_QT5MULTIMEDIA` | Qt Multimedia |
| `BR2_PACKAGE_QT5SERIALPORT` | Qt Serial Port |
| `BR2_PACKAGE_QT5QUICK3D` | Qt Quick 3D ← added by this patch |

GStreamer (for `qt5multimedia` video backend — optional, not required for 3D):

| Config symbol | Notes |
|---|---|
| `BR2_PACKAGE_GSTREAMER1` | GStreamer core |
| `BR2_PACKAGE_GST1_PLUGINS_BASE` | Base plugins (audioconvert, playback, …) |
| `BR2_PACKAGE_GST1_PLUGINS_GOOD` + `PLUGIN_ISOMP4` | MOV/MP4 demuxer |
| `BR2_PACKAGE_GST1_LIBAV` | H.264 decoder (ffmpeg wrapper) |

> GStreamer is only needed if the application plays back video files.
> Leave it disabled for a Qt Quick 3D-only build.

## Building

```sh
cd $BR

# Build only the Qt5 stack (faster than full make):
make qt5base qt5declarative qt5quickcontrols2 qt5multimedia qt5serialport qt5quick3d

# Full image (if targeting rootfs):
make
```

Host tools installed under `output/host/bin/`:
- `moc`, `rcc`, `qmake`, `qmlcachegen` — used during cross-compilation of the app
- `cmake` — `output/host/bin/cmake`
- Cross-compiler environment: `source output/host/environment-setup`

## Cross-compiling the application

```sh
cd $BR
source output/host/environment-setup

mkdir -p /tmp/oven-build && cd /tmp/oven-build
cmake \
  -DCMAKE_TOOLCHAIN_FILE=$SDK_PATH/share/buildroot/toolchainfile.cmake \
  /path/to/Oven_HMI_G2L_QT5   # or Oven_HMI_spin_test / Oven_HMI_gl_demo

make -j$(nproc)
```

## Why qt5quick3d is separate from qt53d

`qt53d` is the older Qt 3D framework (`Qt5::3DCore`, `Qt5::3DRender`) from
the `qt3d` repository.  `qt5quick3d` is Qt Quick 3D from the separate
`qtquick3d` repository — the module used with `import QtQuick3D 1.15` in QML.
They are unrelated and cannot substitute for each other.
