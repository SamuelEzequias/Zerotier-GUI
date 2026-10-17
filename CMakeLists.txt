cmake_minimum_required(VERSION 3.21)
project(ZerotierGUI VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick QuickControls2 Qml Network Svg)
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)
set_source_files_properties(qml/Main.qml PROPERTIES QT_RESOURCE_ALIAS Main.qml)

qt_add_executable(zerotier-gui
    src/main.cpp
    src/appsettings.cpp
    src/appsettings.h
    src/zerotiercontroller.cpp
    src/zerotiercontroller.h
)

qt_add_qml_module(zerotier-gui
    URI ZeroTierGUI
    VERSION 1.0
    QML_FILES qml/Main.qml
)

qt_add_resources(zerotier-gui "app_icon"
    PREFIX "/"
    FILES assets/zerotier-icon.svg
)

target_link_libraries(zerotier-gui PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Qml Qt6::Network Qt6::Svg)

install(TARGETS zerotier-gui RUNTIME DESTINATION bin)
install(FILES assets/zerotier-icon.svg
    DESTINATION share/icons/hicolor/scalable/apps
    RENAME zerotier-gui.svg
)
install(FILES packaging/zerotier-gui.desktop DESTINATION share/applications)
