cmake_minimum_required(VERSION 3.16)
project(bread-gl-demo LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# -----------------------------------------------------------------------------
# Two experimental binaries:
#
#   bread-gl-demo  — QQuickFramebufferObject inside Qt Quick (swapInterval=0)
#   bread-gl-win   — QOpenGLWindow, NO Qt Quick, NO QML, NO V4 JS engine
#
# Comparing them isolates whether the 4-FPS ceiling is in Qt Quick or in
# Mesa llvmpipe / EGLFS swap.
#
# Target: MA35D1, no GPU, EGLFS + Mesa llvmpipe.
# Run:    QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./<binary>
# Toolchain: Buildroot at
#   /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5
# -----------------------------------------------------------------------------
find_package(Qt5 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
)

# ---------------------------------------------------------------------------
# Shared QRC (bread.glb + Main.qml + bread.png)
# Both binaries embed the same asset file via big-resources.
# ---------------------------------------------------------------------------
set_property(SOURCE qml/qml.qrc PROPERTY SKIP_AUTORCC ON)
qt5_add_big_resources(BIG_RESOURCES qml/qml.qrc)

# ---------------------------------------------------------------------------
# bread-gl-demo — Qt Quick + QQuickFramebufferObject
# ---------------------------------------------------------------------------
add_executable(bread-gl-demo
    src/main.cpp
    src/FpsMonitor.h
    src/FpsMonitor.cpp
    src/MeshView.h
    src/MeshView.cpp
    src/MeshRenderer.h
    src/MeshRenderer.cpp
    ${BIG_RESOURCES}
)
target_link_libraries(bread-gl-demo PRIVATE
    Qt5::Core Qt5::Gui Qt5::Qml Qt5::Quick
)

# ---------------------------------------------------------------------------
# bread-gl-win — QOpenGLWindow only (no Qt Quick, no QML)
# ---------------------------------------------------------------------------
add_executable(bread-gl-win
    src/main_win.cpp
    src/BreadWindow.h
    src/BreadWindow.cpp
    ${BIG_RESOURCES}
)
target_link_libraries(bread-gl-win PRIVATE
    Qt5::Core Qt5::Gui
)

install(TARGETS bread-gl-demo bread-gl-win RUNTIME DESTINATION bin)

