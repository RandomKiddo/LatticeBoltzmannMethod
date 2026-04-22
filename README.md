# Lattice Boltzmann Method

A C++/CUDA/NVCC implementation of the Lattice Boltzmann Method for computational fluid dynamics (CFD), utilizing an NVIDIA H100 GPU on a high-performance computing (HPC) resource, with provided Makefiles and executables. Specifically, we investigate the [Kármán Vortex Street](https://en.wikipedia.org/wiki/K%C3%A1rm%C3%A1n_vortex_street).

![GitHub License](https://img.shields.io/github/license/RandomKiddo/LatticeBoltzmannMethod)
![GitHub language count](https://img.shields.io/github/languages/count/RandomKiddo/LatticeBoltzmannMethod)
![GitHub top language](https://img.shields.io/github/languages/top/RandomKiddo/LatticeBoltzmannMethod)
![GitHub repo size](https://img.shields.io/github/repo-size/RandomKiddo/LatticeBoltzmannMethod%20)


> [!NOTE]
> This project is still under development and this README is still being developed.

This project is licensed by the GNU GPLv3 License: `Copyright © 2026 RandomKiddo`.

___

### Project Overview and Example Results

*todo*

___

### Updating, Compiling, and Running

The JSON file `config.json` holds the simulation parameters:
```js
{
    "domain": {
        "nx": 1500,
        "ny": 375
    },
    "physics": {
        "tau": 0.6,
        "u_inlet": 0.1,
        "steps": 100000
    },
    "output": {
        "base_filename": "vortex_street",
        "interval": 200
    }
}
```
The domain `nx` and `ny` define the xy-domain size. The variable `u_inlet` controls the inlet velocity (velocity of the incoming fluid) and `tau` controls the kinematic viscosity. The `steps` is the total number of steps to take. In `output`, the `base_filename` is the base filename for the output (minus the addendums that give simulation parameters in the filename) and the `interval` is the output interval for the main file output (not the probe or the last step).

> [!WARNING]
> For simulation parameters, decreasing $\tau$ to be close to 0.5 could yield lossy results. This could also cause simulation failure or `nan` return values. This is a restriction of the code itself. 

___

### Analysis

The analysis is done through the Python files `strouhal.py` and `visualize.py`. The former compares to numerical numbers important to these kind of simulations, the Strouhal number and Reynolds number. The latter creates the visualizations from the simulation output.

___

### Architecture Changes

This code is built for NVIDIA H100 GPUs. As such the `Makefile` utilizes the following compile line:
```sh
nvcc -O3 -arch=sm_90 main.cu -o lbm_solver
```

The *architecture line* `-arch=sm_90` is required for the NVIDIA H100 Hopper GPUs.

> [!IMPORTANT]
> The architecture line will depend on the GPU being used. The flag `-arch=sm90` works for NVIDIA H100 GPUs. For a consumer-level GPU like the NVIDIA RTX 3060, typically the architecture flag `-arch=sm_70` works. You will need to look at your specific NVIDIA GPU architecture to know which flag to use. 

___

### On Conda Environments and Source Shells

The file `load_osc.sh` can be used to source necessary files for compilation and running.
```sh
source load_osc.sh
```
It is specifically designed to work on the [Ohio Supercomputer Center](https://www.osc.edu/) on the [Cardinal cluster](https://www.osc.edu/resources/technical_support/supercomputers/cardinal). Doing so will load necessary modules like Miniconda and CUDA. This also loads or installs the necessary Conda environment to use the Python analysis files. The environment for Linux HPC usage is in `environment.yml`. The Conda environment is called `lbm` and has the necessary packages and versions to run `strouhal.py` or `visualize.py`. 

> [!NOTE]
> If not able to run on the OSC or similar HPC systems, the necessary modules will need to be loaded and linked, and the Python version used will require the necessary installs.

___

### Acknowledgements

This project utilizes [Nlohmann's JSON C++ package](https://github.com/nlohmann/json) to read JSON files into C++ for dynamic simulation variables. 

It is licensed by the MIT License: `Copyright © 2013-2026 Niels Lohmann`.

___

<br />

[Back to Top](#lattice-boltzmann-method)

<sub>This page was last edited on 04.22.2026</sub>