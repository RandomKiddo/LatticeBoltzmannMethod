#include "test_kernels.h"
#include <cuda_runtime.h>
#include <device_launch_parameters.h>

__global__ void vector_add_kernel(float* a, float* b, float* c, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        c[i] = a[i] + b[i];
    }
}

void launch_vector_add(float* d_a, float* d_b, float* d_c, int n) {
    int threadsPerBlock = 256;
    int blocksPerGrid = (n + threadsPerBlock - 1) / threadsPerBlock;

    vector_add_kernel<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, d_c, n);
    
    // Synchronize to catch any immediate errors
    cudaDeviceSynchronize();
}