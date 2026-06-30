cmake_minimum_required(VERSION 3.16)
project(oven-gui LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS #need to modify to Qt5 for Remi Pi
    Core
    Quick
    QuickControls2
    Multimedia
    SerialPort
    Widgets
    Quick3D
)

set(PROJECT_SOURCES
    src/main.cpp
    qml/qml.qrc
    src/serialhandler.h
    src/serialhandler.cpp
    src/FpsMonitor.cpp
    src/FpsMonitor.h
)

set_property(SOURCE qml/qml.qrc PROPERTY SKIP_AUTORCC ON)
qt_add_big_resources(BIG_RESOURCES qml/qml.qrc)

add_executable(oven-gui
    ${PROJECT_SOURCES}
    ${BIG_RESOURCES}
)

target_link_libraries(oven-gui PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::SerialPort
    Qt6::Widgets
    Qt6::Quick3D
)

install(TARGETS oven-gui RUNTIME DESTINATION bin)
