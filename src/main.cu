#include <iostream>
#include <vector>
#include <cmath>
#include <fstream>
#include <cuda_runtime.h>
#include "lbm_kernels.cu"

// CPU-side constants for initialization and data export
const int CPU_CX[9] = {0, 1, 0, -1, 0, 1, -1, -1, 1};
const int CPU_CY[9] = {0, 0, 1, 0, -1, 1, 1, -1, -1};
const float CPU_W[9] = {4.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/36.0, 1.0/36.0, 1.0/36.0, 1.0/36.0};

int main() {
    // 1. Simulation Parameters
    const int nx = 400;
    const int ny = 100;
    const int steps = 20000; 
    const float tau = 0.6f;      // Kinematic viscosity = (tau - 0.5)/3
    const float u_inlet = 0.1f;  // Inlet velocity magnitude
    
    size_t f_size = 9 * nx * ny * sizeof(float);
    size_t mask_size = nx * ny * sizeof(int);

    // 2. Host Memory Setup
    std::vector<float> h_f(9 * nx * ny);
    std::vector<int> h_mask(nx * ny, 0);

    // Define Cylinder Obstacle (Slightly off-center to trigger vortex shedding)
    int cx = nx / 4;
    int cy = (ny / 2) + 1; // The "+1" breaks the symmetry
    int r = ny / 10;

    for (int y = 0; y < ny; y++) {
        for (int x = 0; x < nx; x++) {
            int idx = y * nx + x;
            
            // Set mask for cylinder
            if ((x - cx)*(x - cx) + (y - cy)*(y - cy) < r * r) {
                h_mask[idx] = 1;
            }

            // Initialize f with equilibrium distribution based on u_inlet
            // This "primes" the fluid so it doesn't start from a dead stop
            float u2 = u_inlet * u_inlet;
            for (int i = 0; i < 9; i++) {
                float cu = 3.0f * (CPU_CX[i] * u_inlet);
                h_f[i * nx * ny + idx] = CPU_W[i] * 1.0f * (1.0f + cu + 0.5f * cu * cu - 1.5f * u2);
            }
        }
    }

    // 3. Device Memory Allocation
    float *d_f1, *d_f2;
    int *d_mask;
    cudaMalloc(&d_f1, f_size);
    cudaMalloc(&d_f2, f_size);
    cudaMalloc(&d_mask, mask_size);

    // Copy data to GPU
    cudaMemcpy(d_f1, h_f.data(), f_size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_mask, h_mask.data(), mask_size, cudaMemcpyHostToDevice);

    // 4. Execution Configuration
    dim3 threadsPerBlock(16, 16);
    dim3 numBlocks((nx + 15) / 16, (ny + 15) / 16);

    std::cout << "Starting Simulation for " << steps << " steps..." << std::endl;

    // 5. Main Simulation Loop
    for (int t = 0; t <= steps; t++) {
        lbm_kernel<<<numBlocks, threadsPerBlock>>>(d_f1, d_f2, d_mask, nx, ny, tau, u_inlet);
        
        // Swap pointers (Double Buffering)
        float* temp = d_f1;
        d_f1 = d_f2;
        d_f2 = temp;

        if (t % 1000 == 0) {
            std::cout << "Step: " << t << std::endl;
        }
    }

    // 6. Data Export
    std::cout << "Exporting to output.dat..." << std::endl;
    cudaMemcpy(h_f.data(), d_f1, f_size, cudaMemcpyDeviceToHost);
    
    std::ofstream out("output.dat");
    for(int y = 0; y < ny; y++) {
        for(int x = 0; x < nx; x++) {
            int idx = y * nx + x;
            
            if (h_mask[idx] == 1) {
                // Inside the cylinder: Force velocity to 0 for visualization
                out << x << " " << y << " " << 0.0 << "\n";
            } else {
                float rho = 0, ux = 0, uy = 0;
                for(int i = 0; i < 9; i++) {
                    float fi = h_f[i * nx * ny + idx];
                    rho += fi;
                    ux += fi * CPU_CX[i];
                    uy += fi * CPU_CY[i];
                }
                // Normalize by density
                ux /= rho;
                uy /= rho;
                
                float vel_mag = sqrtf(ux*ux + uy*uy);
                out << x << " " << y << " " << vel_mag << "\n";
            }
        }
        out << "\n"; // Newline for gnuplot pm3d
    }
    out.close();

    // Cleanup
    cudaFree(d_f1);
    cudaFree(d_f2);
    cudaFree(d_mask);

    std::cout << "Done!" << std::endl;
    return 0;
}
