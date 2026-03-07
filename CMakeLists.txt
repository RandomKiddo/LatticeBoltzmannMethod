cmake_minimum_required(VERSION 3.18)
project(LBM_CUDA_Project LANGUAGES CXX CUDA)

find_package(CUDAToolkit REQUIRED)

# Tell CMake to optimize for your RTX 3060 (Ampere)
set(CMAKE_CUDA_ARCHITECTURES 86)

# Standard C++ version
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD 17)

# Include the 'src' directory so headers are found
include_directories(src)

# Define your executable and its source files
add_executable(LBM_Solver 
    src/main.cpp 
    src/test_kernels.cu
)

# Set compiler-specific optimizations
target_compile_options(LBM_Solver PRIVATE 
    $<$<COMPILE_LANGUAGE:CUDA>:--use_fast_math -O3>
    $<$<COMPILE_LANGUAGE:CXX>:-O3>
)

# Ensure the CUDA runtime library is linked
target_link_libraries(LBM_Solver PRIVATE CUDA::cudart)
