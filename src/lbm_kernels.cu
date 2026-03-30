#include <cuda_runtime.h>

// D2Q9 constants
__constant__ float W[9] = {4.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/36.0, 1.0/36.0, 1.0/36.0, 1.0/36.0};
__constant__ int CX[9] = {0, 1, 0, -1,  0, 1, -1, -1,  1};
__constant__ int CY[9] = {0, 0, 1,  0, -1, 1,  1, -1, -1};

/**
 * LBM Kernel: Combined Collision and Streaming
 * Author: [Your Name]
 * Version: 1.0
 */
__global__ void lbm_kernel(float* f_in, float* f_out, int* mask, int nx, int ny, float tau) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= nx || y >= ny) return;

    int idx = y * nx + x;
    
    // 1. Compute Macroscopic Variables (Density and Velocity)
    float rho = 0.0f;
    float ux = 0.0f;
    float uy = 0.0f;

    for (int i = 0; i < 9; i++) {
        float fi = f_in[i * nx * ny + idx];
        rho += fi;
        ux += fi * CX[i];
        uy += fi * CY[i];
    }
    ux /= rho;
    uy /= rho;

    // 2. Collision and Streaming
    for (int i = 0; i < 9; i++) {
        // Calculate Equilibrium f_eq
        float cu = 3.0f * (CX[i] * ux + CY[i] * uy);
        float feq = rho * W[i] * (1.0f + cu + 0.5f * cu * cu - 1.5f * (ux * ux + uy * uy));

        // Bounce-back logic for obstacles (mask[idx] == 1)
        if (mask[idx] == 1) {
            // Simple Bounce-Back: swap directions (approximate)
            // In a full implementation, you'd map i to its opposite direction
        } else {
            // Relaxation (Collision)
            float f_coll = f_in[i * nx * ny + idx] - (f_in[i * nx * ny + idx] - feq) / tau;

            // Streaming: Calculate neighbor coordinates with periodic wrap
            int next_x = (x + CX[i] + nx) % nx;
            int next_y = (y + CY[i] + ny) % ny;
            int next_idx = next_y * nx + next_x;

            f_out[i * nx * ny + next_idx] = f_coll;
        }
    }
}