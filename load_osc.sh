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
#   04/10/2026 Fixes for use as source file.
#
# Notes:
# Run with "sh load_osc.sh" or use as source with "source load_osc.sh".
# The latter with sourcing is preferred.
# --------------------------------------------------------

echo "Setting up the OSC shell for easy compilation and executing..."

# Define the absolute path to the Lmod executable
# We use the variable if it exists, otherwise we hardcode the standard OSC path
LMOD_EXE="${LMOD_CMD:-/usr/share/lmod/lmod/libexec/lmod}"

# Load modules using the absolute path to python/lmod
# Note: Lmod requires the shell type (bash) as the first argument
$LMOD_EXE bash load cuda/12.8.1
$LMOD_EXE bash load miniconda3/24.1.2-py310

# Verify
$LMOD_EXE bash list

# Setup Conda
# We use 'command -v' to find the absolute path of the conda binary
CONDA_BIN=$(command -v conda)
CONDA_ROOT=$(dirname $(dirname $CONDA_BIN))
source "$CONDA_ROOT/etc/profile.d/conda.sh"

# Activate or create environment
if conda env list | grep -q "lbm"; then
    conda activate lbm
else
    conda env create -f environment.yml
    conda activate lbm
fi

echo "Setup finished!"
