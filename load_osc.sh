# !/bin/bash
# --------------------------------------------------------
# File: load_osc.sh
#
# Loads CUDA (and NVCC) to the current shell instance.
#
# Programmer: Neil Ghugare	ghugare.1@osu.edu
#
# Revision History:
# 	04/02/2026 Initial version for the OSC.
#       04/10/2026 Fixes for use as source file.
#
# Notes:
# Run with "sh load_osc.sh" or use as source with "source load_osc.sh".
# The latter with sourcing is preferred.
# --------------------------------------------------------

echo "Setting up the OSC shell for easy compilation and executing..."

# Load the CUDA module.
module load cuda/12.8.1

# Load Miniconda.
module load miniconda3/24.1.2-py310

# Test that NVCC is active.
nvcc --version

# Check which modules are loaded.
module list

# Activate conda (lbm) or create it if it doesn't exist.
conda env list | grep -q "lbm" && conda activate lbm || conda env create -f environment.yml 

echo "Setup finished!"
