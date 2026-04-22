/**
 * File: main.cu
 * 
 * Program that runs the LBM solver on a GPU.
 * 
 * Programmer: Neil Ghugare ghugare.1@osu.edu
 * 
 * Revision History:
 *      04/02/2026 Initial version with Karman Vortex Street.
 *      04/10/2026 Updated version to work with .json simulation input and Strouhal probing.
 *      04/17/2026 Probe optimizations.
 *      04/22/2026 Main outputs changed to .bin instead of .dat. 
 * 
 * Notes:
 * Use Makefile to get executable to run.
 * Makefile can be used with "make -f Makefile".
 */

#include <iostream>
#include <vector>
#include <cmath>
#include <fstream>
#include <cuda_runtime.h>
#include "lbm_kernels.cu"   // Include the kernel logic directly.
#include "json.hpp"         // Include for flexible simulation config.
#include <sstream>

// For easier usage of JSON reading.
using json = nlohmann::json;

// CPU-side constants for initialization and data export.
// This is the same as the GPU in lbm_kernels.cu to deal with issues translating the arrays over.
// See lbm_kernels.cu for explanation.
const int CPU_CX[9] = {0, 1, 0, -1, 0, 1, -1, -1, 1};
const int CPU_CY[9] = {0, 0, 1, 0, -1, 1, 1, -1, -1};
const float CPU_W[9] = {4.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/36.0, 1.0/36.0, 1.0/36.0, 1.0/36.0};

/**
 * Main function that dictates how the simulation runs and what it outputs. 
 */
int main(void) {
    /*
    --- 1. Configuration and Hyperparameters ---
    */
    std::ifstream fin("config.json");
    json data = json::parse(fin);       // Parse the input file.

    // Fetch simulation parameters.
    const int nx = data["domain"]["nx"];
    const int ny = data["domain"]["ny"];
    const int steps = data["physics"]["steps"]; 
    const float tau = data["physics"]["tau"];           // Kinematic viscosity = (tau - 0.5)/3.
    const float u_inlet = data["physics"]["u_inlet"];   // Inlet velocity magnitude.
    const int interval = data["output"]["interval"];    // Output interval.
    const std::string base_filename = data["output"]["base_filename"];
    
    // Memory size calculation (SoA: 9 directions * total lattice nodes).
    size_t f_size = 9 * nx * ny * sizeof(float);
    size_t mask_size = nx * ny * sizeof(int);

    /*
    --- 2. Host Initialization ---
    */
    std::vector<float> h_f(9 * nx * ny);
    std::vector<int> h_mask(nx * ny, 0);

    // Cylinder steup: We place it at 1/4th of the domain length.
    int cx = nx / 4;
    int cy = (ny / 2) + 1;  // ! Physical Trick: Adding +1 breaks vertical symmetry.
                            // ! Perfect symmetric flow might delay vortex shredding indefinitely.
    int r = ny / 10;        // Cylinder radius is 10% of domain height.

    for (int y = 0; y < ny; ++y) {
        for (int x = 0; x < nx; ++x) {
            int idx = y * nx + x;
            
            // Define solid boundary (the cylinder).
            if ((x - cx)*(x - cx) + (y - cy)*(y - cy) < r * r) {
                h_mask[idx] = 1;
            }

            // Initialization: Fill fluid with equilibrium distribution based on u_inlet.
            // This prevents a "shock" at t=0 by assuming fluid is already moving.
            float u2 = u_inlet * u_inlet;
            for (int i = 0; i < 9; ++i) {
                float cu = 3.0f * (CPU_CX[i] * u_inlet);
                h_f[i * nx * ny + idx] = CPU_W[i] * 1.0f * (1.0f + cu + 0.5f * cu * cu - 1.5f * u2);
            }
        }
    }

    /*
    --- 3. GPU Memory Allocation ---
    */
    float *d_f1, *d_f2;             // Two buffers for "Ping-Pong" (double buffering).
    int *d_mask;
    cudaMalloc(&d_f1, f_size);
    cudaMalloc(&d_f2, f_size);      // Kernel reads from f1, writes to f2 (and vice versa).
    cudaMalloc(&d_mask, mask_size);

    // Copy data to GPU.
    cudaMemcpy(d_f1, h_f.data(), f_size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_mask, h_mask.data(), mask_size, cudaMemcpyHostToDevice);

    /*
    --- 4. CUDA Kernel Topology ---
    */
    // Using 16x16 threads per block. Grid covers the entire domain nx*ny. 
    dim3 threadsPerBlock(16, 16);
    dim3 numBlocks((nx + 15) / 16, (ny + 15) / 16);

    std::cout << "Starting Simulation for " << steps << " steps..." << std::endl;

    // Prepare output files with dynamic filename.
    std::stringstream ss;
    ss << base_filename << "_" << nx << "x" << ny << "_tau" << tau << "_uinlet" << u_inlet
       << ".bin";
    std::ofstream out(ss.str(), std::ios::binary);  // Use a binary file.
    // ! We cannot use a text header with this binary file.
    
    // Repeat for the "probe".
    // ! Probing: Tracking y-velocity at a point behind the cylinder to calculate the
    // ! Strouhal number (vortex shredding frequency) for theoretical comparison.
    std::stringstream ss2;
    ss2 << base_filename << "_" << nx << "x" << ny << "_tau" << tau << "_uinlet" << u_inlet
       << "_PROBE.dat";
    std::ofstream probe_file(ss2.str());
    
    // Probe output file header.
    probe_file << "# Probe data file for LBM Karman Vortex Street Simulation for Strouhal Number.\n"
        << "# t	    uy/rho \n";
    
    /*
    --- 5. Simulation Loop ---
    */
    for (int t = 0; t <= steps; ++t) {
        // Run LBM Kernel.
        lbm_kernel<<<numBlocks, threadsPerBlock>>>(d_f1, d_f2, d_mask, nx, ny, tau, u_inlet);
        
        // Swap pointers: The output of this step becomes the input for the next.
        // This avoids constly memory copies within the GPU.
        float* temp = d_f1;
        d_f1 = d_f2;
        d_f2 = temp;

        // Periodic console logging. 
        if (t % 1000 == 0) {
            std::cout << "Step: " << t << std::endl;
        }

        // Periodic data export (saves snapshots for animation).
        if (t % interval == 0) {
            // Prepare to copy.
            cudaMemcpy(h_f.data(), d_f1, f_size, cudaMemcpyDeviceToHost);

            // Loop and write x, y, and velocity magnitudes to the file.
            for (int y = 0; y < ny; ++y) {
            	for (int x = 0; x < nx; ++x) {
            	    int idx = y * nx + x;
                    float vel_mag = 0.0f;
            
                    if (h_mask[idx] == 0) {     // Fluid cell.
                        float rho = 0, ux = 0, uy = 0;
                        
                        for(int i = 0; i < 9; ++i) {
                            float fi = h_f[i * nx * ny + idx];
                            rho += fi;
                            ux += fi * CPU_CX[i];
                            uy += fi * CPU_CY[i];
                        }

                        // Normalize by density.
                        if (rho > 0.0001f) {
                            ux /= rho;
                            uy /= rho;
                        
                            vel_mag = sqrtf(ux*ux + uy*uy);
                        }
                    } // Else: vel_mag stays 0.0f for cylinder mask.

                    // Write the raw binary bits of the float to the file.
                    // We interpret the address of the float as a char pointer for the stream.
                    out.write(reinterpret_cast<const char*>(&vel_mag), sizeof(float));
                }
            }
        }

        // Virtual probe data extraction.
        // We wait until t>5000 to allow initial flow transients to settle,
        // so the vortex street fully develops.
        if (t > 5000) {
            // Define the spatial location for the probe (placed at the center of the domain).
            int probe_x = nx/2;
            int probe_y = ny/2;
            int idx = probe_y*nx + probe_x;     // Linear index for the 2D lattice point.

            // Local buffer to store the 9 discrete velocity populations (D2Q9).
            float f_local[9];

            // Extract populations from GPU memorty to Host memory.
            // * Note: This is a performance bottleneck for single float copying, which could be updated in the future.
            for (int i = 0; i < 9; ++i) {
                // Calculate the pointer using SoA offset.
                float *d_ptr = d_f1 + (i*nx*ny) + idx;

                // Synchronous transfer of a single distribution function value.
                cudaMemcpy(&f_local[i], d_ptr, sizeof(float), cudaMemcpyDeviceToHost);
            }

            // Macroscopic moment calculation.
            float rho = 0.0f;   // Macroscopic density (zeroth moment).
            float uy = 0.0f;    // Vertical momentum (first moment in y).

            for (int i = 0; i < 9; ++i) {
                rho += f_local[i];              // Sum of all populations.
                uy += f_local[i]*CPU_CY[i];     // Direction-weighted sum.
            }

            // Log normalized y-velocity to file if the cell is fluid (rho>0).
            // This time-series data is used for FFT to find the Strouhal number.
            if (rho > 0.0001f) {
                probe_file << t << " " << (uy/rho) << "\n";
            }
        }
    }

    /*
    --- 6. Cleanup & Final Export ---
    */
    std::cout << "Exporting animation data to " << ss.str() << "\n";
    std::cout << "Exporting probe data to " << ss2.str() << "\n";
    cudaMemcpy(h_f.data(), d_f1, f_size, cudaMemcpyDeviceToHost);
    
    // We output the last step for a GNUPlot visualization.
    std::stringstream ss3;
    ss3 << base_filename << "_" << nx << "x" << ny << "_tau" << tau << "_uinlet" << u_inlet
       << "_LASTSTEP.dat";
    std::ofstream out2(ss3.str());
    
    // Output header.
    out2 << "# Last step data file for LBM Karman Vortex Street Simulation for Final Position GNUPlot\n"
        << "# x  y  velocity_magnitude\n";
    
    // Loop and output the last state of the system, as prior.
    for(int y = 0; y < ny; ++y) {
        for(int x = 0; x < nx; ++x) {
            int idx = y * nx + x;
            
            if (h_mask[idx] == 1) {
                // Inside the cylinder: Force velocity to 0 for visualization.
                out2 << x << " " << y << " " << 0.0 << "\n";
            } else {
                float rho = 0, ux = 0, uy = 0;
                for(int i = 0; i < 9; ++i) {
                    float fi = h_f[i * nx * ny + idx];
                    rho += fi;
                    ux += fi * CPU_CX[i];
                    uy += fi * CPU_CY[i];
                }
                // Normalize by density.
                ux /= rho;
                uy /= rho;
                
                float vel_mag = sqrtf(ux*ux + uy*uy);
                out2 << x << " " << y << " " << vel_mag << "\n";
            }
        }
        out2 << "\n"; // Newline for gnuplot pm3d.
    }
    std::cout << "Exporting last step data to " << ss3.str() << "\n";

    // Close files.
    out.close();
    probe_file.close();
    out2.close();

    ss.close();
    ss2.close();
    ss3.close();

    // Cleanup the memory.
    cudaFree(d_f1);
    cudaFree(d_f2);
    cudaFree(d_mask);

    // All done! 
    std::cout << "Done!" << std::endl;
    return 0;
}
