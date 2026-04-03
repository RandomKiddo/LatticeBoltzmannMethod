# --------------------------------------------------------
# File: load_osc.sh
#
# Loads CUDA (and NVCC) to the current shell instance.
#
# Programmer: Neil Ghugare	ghugare.1@osu.edu
#
# Revision History:
# 	04/02/2025 Initial version for the OSC.
#
# Notes:
# Run with "sh load_osc.sh"
# --------------------------------------------------------

set -x

# Load the CUDA module.
module load cuda/12.8.1

# Test that NVCC is active.
nvcc --version

set +x

