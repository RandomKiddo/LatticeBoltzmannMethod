# -------------------------------------------------------------------
# File: Makefile
#
# Program to compile or make the LBM solver code.
#
# Programmer: Neil Ghugare	ghugare.1@osu.edu
#
# Revision History:
# 	04/02/2026 Initial version with NVCC.
#	04/22/2026 Update for .bin files.
#	04/24/2026 Update comments.
#
# Notes:
# Compile with "make -f Makefile".
# Clean with "make clean".
# Remove only the executable with "make new".
# Run the executable with "./lbm_solver".
# -------------------------------------------------------------------

# We are using NVCC to compile for the GPU.
# This needs to be active in your current shell.
# For OSC usage with Cardinal, use the included "load_osc.sh" file.
# This will load CUDA, which comes with NVCC.
# We use sm_90 architecture for our NVIDIA H100 GPU.
NVCC = nvcc
CFLAGS = -O3 -arch=sm_90

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
# ! Deletes all .dat, .bin, .mp4, and .png files too!
clean:
	rm -f lbm_solver *.dat *.png *.mp4 *.bin

new:
	rm -f lbm_solver
