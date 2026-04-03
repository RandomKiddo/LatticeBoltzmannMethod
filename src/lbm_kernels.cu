#include <cuda_runtime.h>

__constant__ float W[9] = {4.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/36.0, 1.0/36.0, 1.0/36.0, 1.0/36.0};
__constant__ int CX[9] = {0, 1, 0, -1,  0, 1, -1, -1,  1};
__constant__ int CY[9] = {0, 0, 1,  0, -1, 1,  1, -1, -1};
__constant__ int OPP[9] = {0, 3, 4, 1, 2, 7, 8, 5, 6};

__global__ void lbm_kernel(float* f_in, float* f_out, int* mask, int nx, int ny, float tau, float u_inlet) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= nx || y >= ny) return;

    int idx = y * nx + x;

    // 1. PULL STREAMING (Prevents Race Conditions)
    float f_local[9];
    for (int i = 0; i < 9; i++) {
        int prev_x = x - CX[i];
        int prev_y = y - CY[i];

        // Periodic X, Solid Wall Y
        if (prev_y < 0 || prev_y >= ny) {
            // If hitting top/bottom wall, use bounce-back value
            f_local[i] = f_in[OPP[i] * nx * ny + idx];
        } else {
            // Standard Streaming (wrapping X)
            prev_x = (prev_x + nx) % nx;
            f_local[i] = f_in[i * nx * ny + (prev_y * nx + prev_x)];
        }
    }

    // 2. MACROSCOPIC VARIABLES
    float rho = 0.0f;
    float ux = 0.0f;
    float uy = 0.0f;
    for (int i = 0; i < 9; i++) {
        rho += f_local[i];
        ux += f_local[i] * CX[i];
        uy += f_local[i] * CY[i];
    }
    ux /= rho;
    uy /= rho;

    // 3. BOUNDARY CONDITIONS (Inlet)
    if (x == 0) {
        ux = u_inlet;
        uy = 0.0f;
        rho = 1.0f; // Fix density at inlet for stability
    }

    // 4. COLLISION OR BOUNCE-BACK
    if (mask[idx] == 1) {
        for (int i = 0; i < 9; i++) {
            f_out[i * nx * ny + idx] = f_local[OPP[i]];
        }
    } else {
        float u2 = ux * ux + uy * uy;
        for (int i = 0; i < 9; i++) {
            float cu = 3.0f * (CX[i] * ux + CY[i] * uy);
            float feq = W[i] * rho * (1.0f + cu + 0.5f * cu * cu - 1.5f * u2);
            f_out[i * nx * ny + idx] = f_local[i] - (f_local[i] - feq) / tau;
        }
    }
}
