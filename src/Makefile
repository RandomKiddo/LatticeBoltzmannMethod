# Updated Makefile
NVCC = nvcc
CFLAGS = -O3 -arch=sm_70 

all: lbm_solver

lbm_solver: main.cu
	$(NVCC) $(CFLAGS) main.cu -o lbm_solver

# This command runs the sim AND the plotter
plot: lbm_solver
	./lbm_solver
	gnuplot plot_lbm.plt
	@echo "Plot saved as density_map.png"

clean:
	rm -f lbm_solver *.dat *.png