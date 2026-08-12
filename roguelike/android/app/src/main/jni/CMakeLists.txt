cmake_minimum_required(VERSION 3.22)
project(heapsapp C CXX)

# HashLink source tree. Default to a local third_party copy; the Gradle build
# passes HASHLINK_SRC via android/gradle.properties (hashlinkSrc).
if(NOT DEFINED HASHLINK_SRC)
    set(HASHLINK_SRC "${CMAKE_CURRENT_SOURCE_DIR}/../../../../third_party/hashlink")
endif()

# Mobile defines required by libhl (sys_android.c) and the generated game C
# (hlc_main.c / bundled hlsdl sources).
add_compile_definitions(HL_MOBILE HL_ANDROID)

# ---- HashLink native runtime: libhl + static hdlls + fetched third-party deps ----
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(DOWNLOAD_DEPENDENCIES ON CACHE BOOL "" FORCE)
set(WITH_VM OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(WITH_OPENAL OFF CACHE BOOL "" FORCE)   # game uses no audio
set(WITH_VIDEO OFF CACHE BOOL "" FORCE)
set(WITH_HEAPS OFF CACHE BOOL "" FORCE)    # native heaps not used by this game
set(WITH_SQLITE OFF CACHE BOOL "" FORCE)
set(WITH_SSL OFF CACHE BOOL "" FORCE)
set(WITH_FMT ON CACHE BOOL "" FORCE)
set(WITH_SDL ON CACHE BOOL "" FORCE)       # also provides SDL3::SDL3 for the bundled hlsdl
set(WITH_UI ON CACHE BOOL "" FORCE)
set(WITH_UV ON CACHE BOOL "" FORCE)
add_subdirectory(${HASHLINK_SRC} hashlink)

# ---- The game: haxe -hl AOT output ----
# game.c #includes the generated std/haxe/hlsdl sources itself (static HLC
# mode). The native fmt/ui/uv libs are linked from the HashLink hdlls above.
set(NATIVE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../native)
add_library(heapsapp SHARED ${NATIVE_DIR}/game.c)

target_include_directories(heapsapp PRIVATE
    ${NATIVE_DIR}
    ${HASHLINK_SRC}/src
)

target_link_libraries(heapsapp
    libhl
    fmt.hdll
    sdl.hdll
    ui.hdll
    uv.hdll
    SDL3::SDL3
    log
    android
    EGL
    GLESv3
)
