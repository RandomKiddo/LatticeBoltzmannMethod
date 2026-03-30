#include <iostream>
#include <fstream>
#include <vector>
#include "lbm_kernels.cu"

/**
 * Main simulation runner
 * Validates parameters and manages GPU/CPU transfers.
 */
int main() {
    const int nx = 256;
    const int ny = 128;
    const int steps = 5000;
    const float tau = 0.6f; // Viscosity control
    size_t mem_size = 9 * nx * ny * sizeof(float);

    // Host Memory
    std::vector<float> h_f(9 * nx * ny, 1.0f / 9.0f); // Initialized to uniform density
    
    // Device Memory
    float *d_f1, *d_f2;
    cudaMalloc(&d_f1, mem_size);
    cudaMalloc(&d_f2, mem_size);
    cudaMemcpy(d_f1, h_f.data(), mem_size, cudaMemcpyHostToDevice);

    dim3 threadsPerBlock(16, 16);
    dim3 numBlocks((nx + 15) / 16, (ny + 15) / 16);

    std::cout << "Starting LBM simulation on GPU..." << std::endl;

    for (int t = 0; t < steps; t++) {
        lbm_kernel<<<numBlocks, threadsPerBlock>>>(d_f1, d_f2, nullptr, nx, ny, tau);
        
        // Swap pointers for next iteration
        float* temp = d_f1;
        d_f1 = d_f2;
        d_f2 = temp;

        if (t % 1000 == 0) std::cout << "Step: " << t << std::endl;
    }

    // Copy result back and save for Validation/Plotting
    cudaMemcpy(h_f.data(), d_f1, mem_size, cudaMemcpyDeviceToHost);
    
    std::ofstream out("output.csv");
    out << "x,y,rho\n";
    for(int y=0; y<ny; y++) {
        for(int x=0; x<nx; x++) {
            float rho = 0;
            for(int i=0; i<9; i++) rho += h_f[i * nx * ny + y * nx + x];
            out << x << "," << y << "," << rho << "\n";
        }
    }

    cudaFree(d_f1);
    cudaFree(d_f2);
    return 0;
}