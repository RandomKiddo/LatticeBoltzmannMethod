#include <iostream>
#include <vector>
#include <cuda_runtime.h>
#include "test_kernels.h"

int main() {
    int N = 1000;
    size_t size = N * sizeof(float);

    // Host memory
    std::vector<float> h_a(N, 1.0f); // Fill with 1.0
    std::vector<float> h_b(N, 2.0f); // Fill with 2.0
    std::vector<float> h_c(N, 0.0f);

    // Device memory
    float *d_a, *d_b, *d_c;
    cudaMalloc(&d_a, size);
    cudaMalloc(&d_b, size);
    cudaMalloc(&d_c, size);

    // Copy to GPU
    cudaMemcpy(d_a, h_a.data(), size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b.data(), size, cudaMemcpyHostToDevice);

    // Run!
    std::cout << "Running Vector Add on RTX 3060..." << std::endl;
    launch_vector_add(d_a, d_b, d_c, N);

    // Copy back to CPU
    cudaMemcpy(h_c.data(), d_c, size, cudaMemcpyDeviceToHost);

    // Verify (1.0 + 2.0 should be 3.0)
    bool success = true;
    for (int i = 0; i < 10; i++) { // Check first 10
        if (h_c[i] != 3.0f) success = false;
        std::cout << h_a[i] << " + " << h_b[i] << " = " << h_c[i] << std::endl;
    }

    std::cout << (success ? "TEST PASSED!" : "TEST FAILED!") << std::endl;

    cudaFree(d_a); cudaFree(d_b); cudaFree(d_c);
    return 0;
}