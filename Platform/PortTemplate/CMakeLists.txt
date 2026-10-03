cmake_minimum_required(VERSION 3.19)
project(YMBOX C)

# Use this directory with add_subdirectory() from the board firmware project.
# The board toolchain supplies MCU flags, startup code and the linker script.
# Exactly one board port must be compiled by the final firmware target.
set(YMBOX_PORT_SOURCE "" CACHE FILEPATH "Implemented board port, optional here")
file(STRINGS "${CMAKE_CURRENT_LIST_DIR}/sources.txt" YMBOX_ALL_SOURCES)
set(YMBOX_CORE_SOURCES "")
foreach(source IN LISTS YMBOX_ALL_SOURCES)
    if(NOT source MATCHES "^Platform/")
        list(APPEND YMBOX_CORE_SOURCES "${CMAKE_CURRENT_LIST_DIR}/${source}")
    endif()
endforeach()
add_library(ymbox STATIC ${YMBOX_CORE_SOURCES})
target_compile_features(ymbox PUBLIC c_std_99)
target_include_directories(ymbox PUBLIC "${CMAKE_CURRENT_LIST_DIR}/include")
target_include_directories(ymbox PRIVATE "${CMAKE_CURRENT_LIST_DIR}/generated")
include("${CMAKE_CURRENT_LIST_DIR}/Platform/SharedMath/ymbox_math_backend.cmake")
ymbox_link_shared_math(ymbox CONFIGURATION
    "${CMAKE_CURRENT_LIST_DIR}/configuration/YMBOX_ActiveConfiguration.json")
if(YMBOX_PORT_SOURCE)
    target_sources(ymbox PRIVATE "${YMBOX_PORT_SOURCE}")
endif()
if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
    # Runtime finite-value checks must remain effective.
    target_compile_options(ymbox PRIVATE -fno-fast-math)
    target_link_libraries(ymbox PUBLIC m)
endif()
