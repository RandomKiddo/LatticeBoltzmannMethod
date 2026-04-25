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

# 1. Use the absolute path to the Lmod executable.
# Since your function uses $LMOD_CMD, we'll use that directly.
# If someone runs this in a clean shell where $LMOD_CMD isn't set, 
# we provide the standard OSC absolute path as a fallback.
LMOD_EXE="${LMOD_CMD:-/usr/share/lmod/lmod/libexec/lmod}"

# 2. Replicate the 'module' function behavior using absolute paths.
# The 'eval' is necessary because Lmod generates shell commands 
# that need to be executed in the current session.
eval "$($LMOD_EXE bash load cuda/12.8.1)"
eval "$($LMOD_EXE bash load miniconda3/24.1.2-py310)"

echo "Modules loaded. Verifying with absolute path to list..."
eval "$($LMOD_EXE bash list)"

# 3. Initialize Conda using an absolute path.
# We find the conda path to be dynamic but specific.
CONDA_BIN=$(which conda 2>/dev/null || echo "/usr/local/miniconda3/24.1.2-py310/bin/conda")
CONDA_ROOT=$(dirname $(dirname "$CONDA_BIN"))

if [ -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]; then
    source "$CONDA_ROOT/etc/profile.d/conda.sh"
fi

# 4. Activate or create environment.
if conda env list | grep -q "lbm"; then
    conda activate lbm
else
    conda env create -f environment.yml
    conda activate lbm
fi

echo "Setup finished!"
