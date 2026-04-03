#include <iostream>
#include <fstream>
#include <vector>
#include "lbm_kernels.cu"

const int CPU_CX[9] = {0, 1, 0, -1, 0, 1, -1, -1, 1};
const int CPU_CY[9] = {0, 0, 1, 0, -1, 1, 1, -1, -1};
const float CPU_W[9] = {4.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/36.0, 1.0/36.0, 1.0/36.0, 1.0/36.0};

/**
 * Main simulation runner
 * Validates parameters and manages GPU/CPU transfers.
 */
/**
 * Main simulation runner: Kármán Vortex Street
 * Author: [Your Name]
 */
int main() {
    const int nx = 400; // Increased width for better wake development
    const int ny = 100;
    const int steps = 100000; // Vortices take time to develop
    const float tau = 0.6f; 
    const float force = 0.005f; // Driving force (velocity)
    size_t f_mem_size = 9 * nx * ny * sizeof(float);
    size_t mask_mem_size = nx * ny * sizeof(int);

    // 1. Host Memory Setup
    std::vector<float> h_f(9 * nx * ny);
    std::vector<int> h_mask(nx * ny, 0);
    
    for (int i = 0; i < 9; ++i) {
    	float cu = 3.0f*(CPU_CX[i]*force);
    	float feq = CPU_W[i]*(1.0f+cu+0.5f*cu*cu-1.5f*(force*force));
    	for (int j = 0; j < nx*ny; ++j) {
    		h_f[i*nx*ny + j] = feq;
    	}
    }

    // Define the Cylinder Obstacle (Addition from step 2)
    int cx = nx / 4; 
    int cy = (ny / 2) + 1; 
    int r = ny / 10; 
    for (int y = 0; y < ny; y++) {
        for (int x = 0; x < nx; x++) {
            if ((x - cx)*(x - cx) + (y - cy)*(y - cy) < r * r) {
                h_mask[y * nx + x] = 1;
            }
        }
    }

    // 2. Device Memory Allocation
    float *d_f1, *d_f2;
    int *d_mask;
    cudaMalloc(&d_f1, f_mem_size);
    cudaMalloc(&d_f2, f_mem_size);
    cudaMalloc(&d_mask, mask_mem_size);

    cudaMemcpy(d_f1, h_f.data(), f_mem_size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_mask, h_mask.data(), mask_mem_size, cudaMemcpyHostToDevice);

    dim3 threadsPerBlock(16, 16);
    dim3 numBlocks((nx + 15) / 16, (ny + 15) / 16);

    std::cout << "Starting Kármán Vortex Street Simulation..." << std::endl;

    for (int t = 0; t < steps; t++) {
        // Pass the d_mask and force to the updated kernel
        lbm_kernel<<<numBlocks, threadsPerBlock>>>(d_f1, d_f2, d_mask, nx, ny, tau, force);
        
        float* temp = d_f1;
        d_f1 = d_f2;
        d_f2 = temp;

        if (t % 1000 == 0) std::cout << "Step: " << t << std::endl;
    }

    // 3. Data Export (Addition from step 3: Velocity Calculation)
    cudaMemcpy(h_f.data(), d_f1, f_mem_size, cudaMemcpyDeviceToHost);
    
    std::ofstream out("output.dat");
    for(int y = 0; y < ny; y++) {
        for(int x = 0; x < nx; x++) {
            int idx = y * nx + x;
            float rho = 0, ux = 0, uy = 0;

            if (h_mask[idx] == 1) {
                // If it's the cylinder, export a 0 velocity or a special marker
                out << x << " " << y << " " << 0.0 << "\n";
            } else {
                for(int i = 0; i < 9; i++) {
                    float fi = h_f[i * nx * ny + idx];
                    rho += fi;
                    ux += fi * CPU_CX[i];
                    uy += fi * CPU_CY[i];
                }
                // Calculate Velocity Magnitude for visualization
                float vel = sqrtf((ux/rho)*(ux/rho) + (uy/rho)*(uy/rho));
                out << x << " " << y << " " << vel << "\n";
            }
        }
        out << "\n"; 
    }
    out.close();

    // Cleanup
    cudaFree(d_f1); cudaFree(d_f2); cudaFree(d_mask);
    return 0;
}
