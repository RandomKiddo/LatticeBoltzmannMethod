# -------------------------------------------------------------------
# File: Makefile
#
# Program to compile or make the LBM solver code.
#
# Programmer: Neil Ghugare	ghugare.1@osu.edu
#
# Revision History:
# 	04/02/2025 Initial version with NVCC.
#
# Notes:
# Compile with "make -f Makefile".
# Clean with "make clean".
# -------------------------------------------------------------------

# We are using NVCC to compile for the GPU.
# This needs to be active in your current shell.
# For OSC usage with Cardinal, use the included "load_osc.sh" file.
# This will load CUDA, which comes with NVCC.
NVCC = nvcc
CFLAGS = -O3 -arch=sm_70 

all: lbm_solver

# Instructions to compile the code.
lbm_solver: main.cu
	$(NVCC) $(CFLAGS) main.cu -o lbm_solver

# This command runs the sim and the plotter.
plot: lbm_solver
	./lbm_solver
	gnuplot plot_lbm.plt
	@echo "Plot saved as density_map.png"

# Clean the working directory.
# ! Deletes all .dat and .png files too!
clean:
	rm -f lbm_solver *.dat *.png