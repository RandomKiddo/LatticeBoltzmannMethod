#ifndef CONFIG_H
#define CONFIG_H

#include <cuda_runtime.h>

// Grid dimensions
const int NX = 400;
const int NY = 100;
const float TAU = 0.6f;
const int STEPS = 10000;

// D2Q9 lattice constants
// Directions: 0:center, 1-4:axes, 5-9:diagonals
__constant__ int dX[9] = {0, 1, 0, -1, 0, 1, -1, -1, 1};
__constant__ int dY[9] = {0, 0, 1, 0, -1, 1, 1, -1, -1};
__constant__ float W[9]  = {4.f/9.f, 1.f/9.f, 1.f/9.f, 1.f/9.f, 1.f/9.f, 
                            1.f/36.f, 1.f/36.f, 1.f/36.f, 1.f/36.f};

#endif