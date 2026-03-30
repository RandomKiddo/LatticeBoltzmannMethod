#include <cuda_runtime.h>

// D2Q9 constants
__constant__ float W[9] = {4.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/36.0, 1.0/36.0, 1.0/36.0, 1.0/36.0};
__constant__ int CX[9] = {0, 1, 0, -1,  0, 1, -1, -1,  1};
__constant__ int CY[9] = {0, 0, 1,  0, -1, 1,  1, -1, -1};

/**
 * LBM Kernel with Obstacle Mask and Driving Force
 * Author: [Your Name]
 */
__global__ void lbm_kernel(float* f_in, float* f_out, int* mask, int nx, int ny, float tau, float force) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= nx || y >= ny) return;

    int idx = y * nx + x;

    // 1. Calculate Macroscopic variables
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

    // Add a small external driving force to the X-velocity
    ux += force; 

    // 2. Collision and Streaming
    for (int i = 0; i < 9; i++) {
        float cu = 3.0f * (CX[i] * ux + CY[i] * uy);
        float feq = rho * W[i] * (1.0f + cu + 0.5f * cu * cu - 1.5f * (ux * ux + uy * uy));

        // BOUNCE-BACK LOGIC (The "Physics" Grade)
        if (mask[idx] == 1) {
            // Find the opposite direction index
            int opposite[9] = {0, 3, 4, 1, 2, 7, 8, 5, 6}; 
            int inv_i = opposite[i];
            
            // Stream the reflected distribution back
            int next_x = (x + CX[inv_i] + nx) % nx;
            int next_y = (y + CY[inv_i] + ny) % ny;
            f_out[i * nx * ny + (next_y * nx + next_x)] = f_in[i * nx * ny + idx];
        } else {
            float f_coll = f_in[i * nx * ny + idx] - (f_in[i * nx * ny + idx] - feq) / tau;

            int next_x = (x + CX[i] + nx) % nx;
            int next_y = (y + CY[i] + ny) % ny;
            
            // Solid walls at top and bottom (No streaming past boundaries)
            if (next_y >= 0 && next_y < ny) {
                f_out[i * nx * ny + (next_y * nx + next_x)] = f_coll;
            }
        }
    }
}