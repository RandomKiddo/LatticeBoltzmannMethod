"""
File: strouhal.py

Program that calculates Strouhal number for simulation from probe.

Programmer: Neil Ghugare ghugare.1@osu.edu

Revision History:
	04/16/2026 Created initial version with comments.

Notes:
Best method to run is "python strouhal.py" in the command line.
Command line arguments are available, use "python strouhal.py -h" to see them.
"""

import numpy as np
import argparse

from helper import *		# From helper.py file.

def calculate_strouhal(filename: str, ny: int, u_inlet: float) -> float:
	"""
	Calculates the Strouhal number for the simulation.

	Arguments (required)
	1. filename - The data filename.
	2. ny - The number of y-direction cells.
	3. u_inlet - The inlet flow velocity.
	
	Arguments (optional)
	None

	Returns
	The Strouhal number.
	"""

	# Load the data and get the time and y-velocity from the .dat file.
	data = np.loadtxt(filename)
	t = data[:, 0]
	uy = data[:, 1]
	
	# Apply a Fast Fourier Transform (FFT) to the y-velocity.
	# We can then extract the frequency of the vortices.
	uy_fft = np.abs(np.fft.fft(uy))
	freqs = np.fft.fftfreq(len(t), d=1)

	# We can then get the lattice frequency from the FFT.
	idx = np.argmax(uy_fft[1:len(uy)//2]) + 1
	f_lattice = freqs[idx]

	# The radius of the cylinder and the maximum velocity.
	r = ny//10
	u_max = u_inlet * (ny/(ny-2*r))

	# Return the Strouhal number.
	return (f_lattice * 2*r / u_max)

# If we are running this file...
if __name__ == '__main__':
	# Command line argument parsing for the JSON config file and the output file name.
	parser = argparse.ArgumentParser(prog='Karman Vortex Street LBM Strouhal',
					 description='Verifies the Strouhal Number for the LBM simulation.')
	parser.add_argument('--config', type=str, help='Path to JSON config file.', default='config.json')
	
	# Parse the command line arguments.
	args = parser.parse_args()
	
	# Load the JSON config file (this is from helper.py).
	config = load_json(args.config)
	
	# Get the details of the simulation we ran.
	nx = config['domain']['nx']
	ny = config['domain']['ny']
	tau = config['physics']['tau']
	u_inlet = config['physics']['u_inlet']
	base = config['output']['base_filename']
	
	# Find the .dat file for the simulation (see helper.py).
	# We add the addendum '_PROBE' to get the probe data file.
	filename = assemble_data_filename(base, nx, ny, tau, u_inlet, addendum='_PROBE')
	
	# Output the Strouhal number to the console.
	print(f'Strouhal Number: {calculate_strouhal(filename, ny, u_inlet):.6f}')

