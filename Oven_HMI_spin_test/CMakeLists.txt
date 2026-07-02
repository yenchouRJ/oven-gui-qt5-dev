cmake_minimum_required(VERSION 3.16)
project(chicken-spin-test LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# -----------------------------------------------------------------------------
# Minimal Qt5 test app — chicken PNG + spinning 3D model side by side.
# Target: MA35D1, no GPU, EGLFS + Mesa llvmpipe.
# Run: QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./chicken-spin-test
# Toolchain: Buildroot at
#   /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5
# -----------------------------------------------------------------------------
find_package(Qt5 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    Quick3D
)

set(PROJECT_SOURCES
    src/main.cpp
    src/FpsMonitor.h
    src/FpsMonitor.cpp
)

# Embeds meshes; use big-resources to avoid linker section-size limits.
set_property(SOURCE qml/qml.qrc PROPERTY SKIP_AUTORCC ON)
qt5_add_big_resources(BIG_RESOURCES qml/qml.qrc)

add_executable(chicken-spin-test
    ${PROJECT_SOURCES}
    ${BIG_RESOURCES}
)

target_link_libraries(chicken-spin-test PRIVATE
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::Quick3D
)

install(TARGETS chicken-spin-test RUNTIME DESTINATION bin)
