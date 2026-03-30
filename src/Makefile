# Makefile for CUDA LBM Project
# Author: [Your Name]

# Compiler
NVCC = nvcc
# Flags: -O3 for optimization, -arch for GPU compatibility
CFLAGS = -O3 -arch=sm_70 

TARGET = lbm_solver

all: $(TARGET)

$(TARGET): main.cu
	$(NVCC) $(CFLAGS) main.cu -o $(TARGET)

clean:
	rm -f $(TARGET) *.csv *.png