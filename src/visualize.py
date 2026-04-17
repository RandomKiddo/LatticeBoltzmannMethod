"""
File: visualize.py

Program that makes the animated visualizations of the LBM output.

Programmer: Neil Ghugare ghugare.1@osu.edu

Revision History:
	04/15/2026 Initial version with comments.

Notes:
Best method to run is "python visualize.py" in the command line.
Command line arguments are available, use "python visualize.py -h" to see them.
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as anim
import argparse

from typing import Any
from helper import *        # From helper.py file.

@timefn
def load_frames(file_path: str) -> np.array:
	"""
	Loads the frames for the visualization.

	Arguments (required)
	1. file_path - The string file path.
	
	Arguments (optional)
	None

	Returns
	The array of frames.
	"""
	
	# Load the data
	data = np.loadtxt(file_path)
	
	# The number of data points per frame and calculate the # of frames.
	points_per_frame = nx*ny
	num_frames = len(data)//points_per_frame
	
	# Return the frames reshaped to work on an image.
	frames = data[:, 2].reshape((num_frames, ny, nx))
	return frames 

@timefn
def make_animation(all_frames: np.array, output: str) -> None:
	"""
	Makes and saves the animation.

	Arguments (required)
	1. all_frames - The array of frames.
	2. output - The output file name.
	
	Arguments (optional)
	None

	Returns
	None
	"""
	
	fig, ax = plt.subplots(figsize=(10, 4))

	# Show the first frame.
	img = ax.imshow(all_frames[0], origin='lower', cmap='inferno', interpolation='bilinear',
			vmin=0, vmax=0.15)
	
	# Add a colorbar and format properly.
	fig.colorbar(img, label='Velocity Magnitude')
	ax.set_title('Karman Vortex Street Evolution')
	ax.set_xlabel('x')
	ax.set_ylabel('y')
	
	# Update function to update the plot.
	def update(frame_idx: int) -> Any:
		"""
		Updates the matplotlib frame.

		Arguments (required)
		1. frame_idx - The integer index of the frame.
		
		Arguments (optional)
		None

		Returns
		The new image.
		"""
		img.set_array(all_frames[frame_idx])
		return [img]
	
	# Animate based on the update function.
	ani = anim.FuncAnimation(fig, update, frames=len(all_frames), interval=50, blit=True)
	
	# Save the animation and close matplotlib.
	ani.save(output, fps=30)
	plt.close()

# If we are running this file...
if __name__ == '__main__':
	# Command line argument parsing for the JSON config file and the output file name.
	parser = argparse.ArgumentParser(prog='Karman Vortex Street LBM Visualizer',
					 description='Makes output MP4 animations from Karman Vortex Street LBM .dat files')
	parser.add_argument('--config', type=str, help='Path to JSON config file.', default='config.json')
	parser.add_argument('--output', type=str, help='Path and filename of output visualization.', default='vortex_street.mp4')
	
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
	filename = assemble_data_filename(base, nx, ny, tau, u_inlet)

	# Load the frame and make the animation.
	all_frames = load_frames(filename)
	make_animation(all_frames, args.output)


