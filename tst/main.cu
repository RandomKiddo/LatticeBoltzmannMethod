#include <iostream>
#include <cuda_runtime.h>

// CUDA Kernel: This runs on the GPU
__global__ void vectorAdd(const float* a, const float* b, float* c, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        c[i] = a[i] + b[i]; // In LBM, this will be your Collision/Stream logic
    }
}

int main() {
    int n = 1 << 20; // 1 million elements
    size_t size = n * sizeof(float);

    // 1. Allocate Host (CPU) memory
    float *h_a = new float[n], *h_b = new float[n], *h_c = new float[n];
    for (int i = 0; i < n; i++) {
        h_a[i] = 1.0f; h_b[i] = 2.0f;
    }

    // 2. Allocate Device (GPU) memory
    float *d_a, *d_b, *d_c;
    cudaMalloc(&d_a, size);
    cudaMalloc(&d_b, size);
    cudaMalloc(&d_c, size);

    // 3. Copy data from Host to Device
    cudaMemcpy(d_a, h_a, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, size, cudaMemcpyHostToDevice);

    // 4. Launch Kernel (256 threads per block)
    int threadsPerBlock = 256;
    int blocksPerGrid = (n + threadsPerBlock - 1) / threadsPerBlock;
    vectorAdd<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, d_c, n);

    // 5. Copy result back to Host
    cudaMemcpy(h_c, d_c, size, cudaMemcpyDeviceToHost);

    // Verify
    std::cout << "Result at index 0: " << h_c[0] << " (Expected: 3.0)" << std::endl;

    // Cleanup
    cudaFree(d_a); cudaFree(d_b); cudaFree(d_c);
    delete[] h_a; delete[] h_b; delete[] h_c;

    return 0;
}