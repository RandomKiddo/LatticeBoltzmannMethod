/**
 * File: lbm_kernels.cu
 * 
 * The LBM kernel logic for the simulation.
 * 
 * Programmer: Neil Ghugare ghugare.1@osu.edu
 * 
 * Revision History:
 *      04/02/2026 Initial version with Karman Vortex Street.
 *      04/15/2026 Better documentation comments.
 * 
 * Notes:
 * Use Makefile to get executable to run.
 */

#include <cuda_runtime.h>

/*
We use the D2Q9 model for Lattice Boltzmann Method (LBM), which represents 2 dimensions, 9 velocities.
Thus, we define constats for the D2Q9 model.

W are the lattice weights for each of the 9 velocity directions for the equilibrium distribution, to ensure isotropy.
CX and CY are the unit velocity vectors, 0: Center, 1-4: Axes (N, S, E, W), 5-8: Diagonals.
OPP are the opposite direction indices, used for bounce-back boundary conditions.
*/
__constant__ float W[9] = {4.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/36.0, 1.0/36.0, 1.0/36.0, 1.0/36.0};
__constant__ int CX[9] = {0, 1, 0, -1,  0, 1, -1, -1,  1};
__constant__ int CY[9] = {0, 0, 1,  0, -1, 1,  1, -1, -1};
__constant__ int OPP[9] = {0, 3, 4, 1, 2, 7, 8, 5, 6};

/**
 * lbm_kernel
 * @param f_in:     The distribution functions from the previous timestep.
 * @param f_out:    The updated distribution functions for the next timestep.
 * @param mask:     Integer array where 1=solid obstacle, 0=fluid.
 * @param nx:       Grid dimension in x-direction.
 * @param ny:       Grid dimension in y-direction.
 * @param tau:      Relaxation time (determines viscosity: nu = (tau-0.5)/3).
 * @param u_inlet:  The constant horizontal velocity pushed from the left wall.
 * @return          No returns.
 */
__global__ void lbm_kernel(float* f_in, float* f_out, int* mask, int nx, int ny, float tau, float u_inlet) {
    // Map CUDA threads to 2D grid coordinates.
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    
    // Boundary check for grid dimensions.
    if (x >= nx || y >= ny) return;

    // Linear index for 2D/3D array access.
    // The "Structure of Arrays" format is [direction][y][x].
    int idx = y * nx + x;

    /*
    --- 1. Pull Streaming ---
    Instead of pushing values to neighbors (causing race conditions), each cell
    "pulls" the particle distributions moving toward it from neighboring cells.
    */
    float f_local[9];
    for (int i = 0; i < 9; i++) {
        int prev_x = x - CX[i];
        int prev_y = y - CY[i];

        // Top/Bottom wall handling (no-slip bounce-back at y-boundaries).
        if (prev_y < 0 || prev_y >= ny) {
            // If the "source" is outside the y-bounds, take the value that was
            // heading out of the current cell and flip it back (OPP). 
            f_local[i] = f_in[OPP[i] * nx * ny + idx];
        } else {
            // Standard periodic boundary for x-axis (inlet/outlet wrap-around).
            prev_x = (prev_x + nx) % nx;
            f_local[i] = f_in[i * nx * ny + (prev_y * nx + prev_x)];
        }
    }

    /*
    --- 2. Macroscopic Moments ---
    Calculate density (rho) and velocity (u) from the local distributions.
    */
    float rho = 0.0f;
    float ux = 0.0f;
    float uy = 0.0f;
    for (int i = 0; i < 9; i++) {
        rho += f_local[i];              // Density is the sum of all directions.
        ux += f_local[i] * CX[i];       // x-momentum.
        uy += f_local[i] * CY[i];       // y-momentum.
    }
    // Normalize velocity by density.
    ux /= rho;
    uy /= rho;

    /*
    --- 3. Inlet Boundary Condition ---
    Force a specific velocity at the left boundary to drive the flow.
    */
    if (x == 0) {
        ux = u_inlet;
        uy = 0.0f;          // No y-velocity at inlet.
        rho = 1.0f;         // Stabilize density at the inlet.
    }

    /*
    --- 4. Collision or Obstacle Handling ---
    */
    if (mask[idx] == 1) {
        // Case 1: Solid Obstacle (Bounce-Back)
        // If the cell is part of the cylinder/obstacle, reflect all distributions .
        for (int i = 0; i < 9; i++) {
            f_out[i * nx * ny + idx] = f_local[OPP[i]];
        }
    } else {
        // Case 2: Fluid Cell
        // Fluid relaxes toward an equilibrium state based on current velocity.
        float u2 = ux * ux + uy * uy;
        
        for (int i = 0; i < 9; i++) {
            // cu = dot product of lattice velocity and fluid velocity (e_i . u).
            float cu = 3.0f * (CX[i] * ux + CY[i] * uy);
            
            // feq = Maxwell-Boltzmann equilibrium distribution for this direction.
            float feq = W[i] * rho * (1.0f + cu + 0.5f * cu * cu - 1.5f * u2);

            // LBM equation: f_new = f_old - (f_old - f_eq)/tau.
            // This simulates particle collisions returning the system to balance. 
            f_out[i * nx * ny + idx] = f_local[i] - (f_local[i] - feq) / tau;
        }
    }
}
