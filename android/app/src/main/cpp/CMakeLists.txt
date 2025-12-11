# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                              CMakeLists.txt                                   ║
# ║              Build configuration para código nativo de NutriVision            ║
# ╠═══════════════════════════════════════════════════════════════════════════════╣
# ║  Configura la compilación de las bibliotecas nativas C++ para conversión      ║
# ║  de imágenes YUV420 a RGB optimizada con NEON (ARM SIMD).                     ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

cmake_minimum_required(VERSION 3.18.1)
project(nutrivision_native)

# Configuración de C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Optimizaciones para release
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

# Habilitar NEON para ARM (optimizaciones SIMD)
if(ANDROID_ABI STREQUAL "armeabi-v7a")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mfpu=neon")
elseif(ANDROID_ABI STREQUAL "arm64-v8a")
    # NEON está habilitado por defecto en arm64
endif()

# Crear biblioteca compartida
add_library(
    nutrivision_native
    SHARED
    native_image_processor.cpp
)

# Enlazar con bibliotecas del sistema
target_link_libraries(
    nutrivision_native
    android
    log
    jnigraphics
)

# Incluir headers
target_include_directories(
    nutrivision_native
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)
