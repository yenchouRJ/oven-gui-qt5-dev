cmake_minimum_required(VERSION 3.16)
project(oven-gui LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# -----------------------------------------------------------------------------
# Qt5 build (ported from Qt6) for MA35D1 / Buildroot.
#   Toolchain: source the Buildroot cross compiler under
#     /home/joeylu/Documents/workspace/ma35d1/ma35d1_br24_qt5
#   Run on target (no GPU -> Mesa llvmpipe software GL):
#     QT_QPA_PLATFORM=eglfs GALLIUM_DRIVER=llvmpipe ./oven-gui
# -----------------------------------------------------------------------------
find_package(Qt5 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Multimedia
    SerialPort
    Widgets
    Quick3D
)

set(PROJECT_SOURCES
    src/main.cpp
    src/serialhandler.h
    src/serialhandler.cpp
    src/FpsMonitor.cpp
    src/FpsMonitor.h
)

# The qrc embeds large 3D meshes; use the "big resources" generator.
set_property(SOURCE qml/qml.qrc PROPERTY SKIP_AUTORCC ON)
qt5_add_big_resources(BIG_RESOURCES qml/qml.qrc)

add_executable(oven-gui
    ${PROJECT_SOURCES}
    ${BIG_RESOURCES}
)

target_link_libraries(oven-gui PRIVATE
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Multimedia
    Qt5::SerialPort
    Qt5::Widgets
    Qt5::Quick3D
)

install(TARGETS oven-gui RUNTIME DESTINATION bin)
