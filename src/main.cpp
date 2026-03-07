#include <iostream>
#include <vector>
#include <fstream>
#include "config.h"

void launch_lbm(float *d_f_in, float *d_f_out);
void launch_init(float* d_f_in);

int main() {
    size_t size = 9*NX*NY*sizeof(float);
    float *d_f_in, *d_f_out;

    cudaMalloc(&d_f_in, size);
    cudaMollac(&d_f_out, size);

    launch_init(d_f_in);
    std::cout << "Lattice initialized...\n";

    for (int t = 0; t < STEPS; ++t) {
        launch_lbm(d_f_in, d_f_out);
        std::swap(d_f_in, d_f_out);

        if (t % 1000 == 0) {
            std::cout << "Step: " << t << "\n";
        }
    }

    cudaFree(d_f_in);
    cudaFree(d_f_out);

    // todo: copy back to CPU and write CSV
    // todo: provide push to fluid
    // todo: comments (doc, top of file, and inline)

    return 0;
}