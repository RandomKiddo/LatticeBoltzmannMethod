#include "config.h"

__device__ float get_feq(int i, float rho, float u, float v) {
    float edotu = dX[i]*u + dY[i]*v;
    float u2 = u*u + v*v;
    return W[i]*rho*(1.0f + 3.0f*edotu + 4.5f*edotu*edotu - 1.5f*u2);
}

__global__ void lbm_step(float *f_in, float *f_out) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= NX || y >= NY) { 
        return;
    }

    int idx = y*NX + x;

    float rho = 0, u = 0, v = 0;
    for (int i = 0; i < 9; ++i) {
        float fi = f_in[i*NX*NY + idx];
        rho += fi;
        u += fi*dX[i];
        v += fi*dY[i];
    }
    u /= rho;
    v /= rho;

    for (int i = 0; i < 9; ++i) {
        float fi = f_in[i*NX*NY + idx];
        float feq = get_feq(i, rho, u, v);

        float f_post = fi - (fi-feq)/TAU;

        int next_x = (x+dX[i]+NX) % NX;
        int next_y = (y+dY[i]+NY) % NY;
        int next_idx = i*NX*NY + (next_y*NX + next_x);

        f_out[next_idx] = f_post;
    }
}

void launch_lbm(float* d_f_in, float* d_f_out) {
    // 1. Define the number of threads per block (32x8 = 256 threads)
    // The RTX 3060 loves multiples of 32!
    dim3 blockSize(32, 8); 

    // 2. Calculate how many blocks we need to cover the whole grid
    dim3 gridSize((NX + blockSize.x - 1) / blockSize.x, 
                  (NY + blockSize.y - 1) / blockSize.y);

    // 3. Launch the kernel
    lbm_step<<<gridSize, blockSize>>>(d_f_in, d_f_out);

    // 4. Check for errors (crucial for debugging)
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("CUDA Error: %s\n", cudaGetErrorString(err));
    }
}

__global__ void lbm_init(float* f_in) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= NX || y >= NY) return;

    int idx = y * NX + x;
    
    // Initial conditions: Density = 1.0, Velocity = 0
    float rho_0 = 1.0f;
    float u_0 = 0.0f;
    float v_0 = 0.0f;

    for (int i = 0; i < 9; i++) {
        // At zero velocity, feq simplifies to rho * weight
        f_in[i * NX * NY + idx] = get_feq(i, rho_0, u_0, v_0);
    }
}

void launch_init(float* d_f_in) {
    dim3 blockSize(32, 8);
    dim3 gridSize((NX + blockSize.x - 1) / blockSize.x, 
                  (NY + blockSize.y - 1) / blockSize.y);

    lbm_init<<<gridSize, blockSize>>>(d_f_in);
    cudaDeviceSynchronize(); 
}