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
    
    float f_local[9];
    for (int i = 0; i < 9; ++i) {
    	int prev_x = (x - CX[i] + nx) % nx;
    	int prev_y = (x - CY[i] + ny) % ny;
    	f_local[i] = f_in[i*nx*ny + (prev_y*nx + prev_x)];
    }

    // 1. Calculate Macroscopic variables
    float rho = 0.0f;
    float ux = 0.0f;
    float uy = 0.0f;

    for (int i = 0; i < 9; i++) {
        float fi = f_local[i];
        rho += fi;
        ux += fi * CX[i];
        uy += fi * CY[i];
    }
    ux /= rho;
    uy /= rho;

    // Add a small external driving force to the X-velocity
    ux += force; 
    

    // 2. Collision and Streaming
    if (mask[idx] == 1) {
    	ux = 0.0f;
    	uy = 0.0f;
    	int opposite[9] = {0, 3, 4, 1, 2, 7, 8, 5, 6};
    	for (int i = 0; i < 9; ++i) {
    		f_out[i*nx*ny + idx] = f_local[opposite[i]];
    	}
    } else {
    	for (int i = 0; i < 9; ++i) {
    		float cu = 3.0f * (CX[i]*ux + CY[i]*uy);
    		float feq = rho*W[i] * (1.0f + cu + 0.5f*cu*cu - 1.5f*(ux*ux + uy*uy));
    		f_out[i*nx*ny + idx] = f_local[i] - (f_local[i]-feq)/tau;
    	}
    }
}
