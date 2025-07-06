cmake_minimum_required(VERSION 3.14)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_COLOR_DIAGNOSTICS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(mujoco-omniwheel-example)

find_package(Threads REQUIRED)

add_executable(${PROJECT_NAME} main.cc)

if(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
    # for macOS
    find_package(glfw3 REQUIRED)

    target_include_directories(${PROJECT_NAME} PRIVATE mujoco.framework/Headers)

    target_link_libraries(${PROJECT_NAME}
        ${CMAKE_CURRENT_SOURCE_DIR}/mujoco.framework/mujoco.tbd
        glfw
    )
elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    # for Linux
    find_package(glfw3 REQUIRED)

    target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/mujoco/include)

    target_link_libraries(${PROJECT_NAME}
        ${CMAKE_CURRENT_SOURCE_DIR}/mujoco/lib/libmujoco.so
        glfw
    )
endif()