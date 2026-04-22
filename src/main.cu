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
 *      04/22/2026 Optimization updates between host and GPU.
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
#include "lbm_kernels.cu"   
#include "json.hpp"         
#include <sstream>

using json = nlohmann::json;

const int CPU_CX[9] = {0, 1, 0, -1, 0, 1, -1, -1, 1};
const int CPU_CY[9] = {0, 0, 1, 0, -1, 1, 1, -1, -1};
const float CPU_W[9] = {4.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/9.0, 1.0/36.0, 1.0/36.0, 1.0/36.0, 1.0/36.0};

int main(void) {
    /* --- 1. Configuration --- */
    std::ifstream fin("config.json");
    json data = json::parse(fin);

    const int nx = data["domain"]["nx"];
    const int ny = data["domain"]["ny"];
    const int steps = data["physics"]["steps"]; 
    const float tau = data["physics"]["tau"];           
    const float u_inlet = data["physics"]["u_inlet"];   
    const int interval = data["output"]["interval"];    
    const std::string base_filename = data["output"]["base_filename"];
    
    size_t f_size = 9 * nx * ny * sizeof(float);
    size_t mask_size = nx * ny * sizeof(int);
    size_t mag_size = nx * ny * sizeof(float);

    /* --- 2. Host Initialization --- */
    std::vector<float> h_f(9 * nx * ny);
    std::vector<int> h_mask(nx * ny, 0);

    int cx = nx / 4;
    int cy = (ny / 2) + 1;  
    int r = ny / 10;        

    for (int y = 0; y < ny; ++y) {
        for (int x = 0; x < nx; ++x) {
            int idx = y * nx + x;
            if ((x - cx)*(x - cx) + (y - cy)*(y - cy) < r * r) h_mask[idx] = 1;

            float u2 = u_inlet * u_inlet;
            for (int i = 0; i < 9; ++i) {
                float cu = 3.0f * (CPU_CX[i] * u_inlet);
                h_f[i * nx * ny + idx] = CPU_W[i] * 1.0f * (1.0f + cu + 0.5f * cu * cu - 1.5f * u2);
            }
        }
    }

    /* --- 3. GPU Memory Allocation --- */
    float *d_f1, *d_f2, *d_mag, *d_probe_res;
    int *d_mask;
    
    cudaMalloc(&d_f1, f_size);
    cudaMalloc(&d_f2, f_size);      
    cudaMalloc(&d_mask, mask_size);
    cudaMalloc(&d_mag, mag_size);           // Store velocity magnitudes for export
    cudaMalloc(&d_probe_res, sizeof(float)); // Store single probe result

    // Pinned Host Memory for faster D2H transfers
    float *h_mag_pinned, *h_probe_pinned;
    cudaMallocHost(&h_mag_pinned, mag_size);
    cudaMallocHost(&h_probe_pinned, sizeof(float));

    cudaMemcpy(d_f1, h_f.data(), f_size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_mask, h_mask.data(), mask_size, cudaMemcpyHostToDevice);

    /* --- 4. Topology --- */
    dim3 threadsPerBlock(16, 16);
    dim3 numBlocks((nx + 15) / 16, (ny + 15) / 16);
    int probe_idx = (ny / 2) * nx + (nx / 2); // Probe point behind cylinder

    /* --- 5. Files --- */
    std::stringstream ss_main, ss_probe;
    ss_main << base_filename << "_" << nx << "x" << ny << "_tau" << tau << ".dat";
    ss_probe << base_filename << "_" << nx << "x" << ny << "_PROBE.dat";
    
    std::ofstream out(ss_main.str());
    std::ofstream probe_file(ss_probe.str());
    out << "# x y velocity_magnitude\n";
    probe_file << "# t uy/rho\n";

    std::cout << "Starting Simulation..." << std::endl;

    /* --- 6. Simulation Loop --- */
    for (int t = 0; t <= steps; ++t) {
        
        // Step 1: LBM Evolution
        lbm_kernel<<<numBlocks, threadsPerBlock>>>(d_f1, d_f2, d_mask, nx, ny, tau, u_inlet);
        std::swap(d_f1, d_f2);

        // Step 2: Periodic Full Field Export
        if (t % interval == 0) {
            // Compute magnitude on GPU - No more 9-float-per-node CPU loops!
            compute_velocity_magnitude<<<numBlocks, threadsPerBlock>>>(d_f1, d_mask, d_mag, nx, ny);
            
            // Transfer ONLY the magnitude result
            cudaMemcpy(h_mag_pinned, d_mag, mag_size, cudaMemcpyDeviceToHost);

            for (int i = 0; i < nx * ny; ++i) {
                out << (i % nx) << " " << (i / nx) << " " << h_mag_pinned[i] << "\n";
            }
            if (t % 1000 == 0) std::cout << "Step: " << t << std::endl;
        }

        // Step 3: Optimized Probe (Post-transient)
        if (t > 5000) {
            // Kernel reduces 9 populations to 1 float on device
            get_probe_data<<<1, 1>>>(d_f1, probe_idx, nx, ny, d_probe_res);
            
            // Minimal transfer: 4 bytes instead of 36 bytes
            cudaMemcpy(h_probe_pinned, d_probe_res, sizeof(float), cudaMemcpyDeviceToHost);
            
            probe_file << t << " " << *h_probe_pinned << "\n";
        }
    }

    /* --- 7. Final Export (Formatted for Gnuplot pm3d) --- */
    std::cout << "Exporting final state for GNUPlot..." << std::endl;

    // Compute magnitude one last time for the current state
    compute_velocity_magnitude<<<numBlocks, threadsPerBlock>>>(d_f1, d_mask, d_mag, nx, ny);
    cudaMemcpy(h_mag_pinned, d_mag, mag_size, cudaMemcpyDeviceToHost);

    std::stringstream ss_last;
    ss_last << base_filename << "_" << nx << "x" << ny << "_tau" << tau << "_uinlet" << u_inlet << "_LASTSTEP.dat";
    std::ofstream out2(ss_last.str());

    for(int y = 0; y < ny; ++y) {
        for(int x = 0; x < nx; ++x) {
            int idx = y * nx + x;
            out2 << x << " " << y << " " << h_mag_pinned[idx] << "\n";
        }
        // CRITICAL: Gnuplot pm3d requires a blank line after each scanline (row)
        out2 << "\n"; 
    }

    /* --- 8. Cleanup --- */
    out.close();
    probe_file.close();
    out2.close();

    cudaFree(d_f1); cudaFree(d_f2); cudaFree(d_mask); 
    cudaFree(d_mag); cudaFree(d_probe_res);
    cudaFreeHost(h_mag_pinned); cudaFreeHost(h_probe_pinned);

    std::cout << "Done! Probe data saved to " << ss_probe.str() << std::endl;
    return 0;
}