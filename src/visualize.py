"""
File: visualize.py

Program that makes the animated visualizations of the LBM output.

Programmer: Neil Ghugare ghugare.1@osu.edu

Revision History:
	04/15/2026 Initial version with comments.
	04/22/2026 Update visualizations for .bin instead of .dat files.
	04/22/2026 Styling updates for plotting.
	04/24/2026 Zoom-in visualization capabilities.

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

# Matplotlib styling updates.
plt.rcParams.update({
    # Text styling (LaTeX and Stix font). 
    "text.usetex": True,                                                
    "font.family": "serif",
    "font.serif": ["Nimbus Roman", "Times New Roman", "Times"],
    "mathtext.fontset": "stix",                                         
    
	# X-axis ticks
	"xtick.major.size": 7,     
        "xtick.major.width": 1,
        "xtick.minor.size": 3,      
        "xtick.minor.width": 1,     
    
	# Y-axis ticks
	"ytick.major.size": 7,      
	"ytick.major.width": 1,       
	"ytick.minor.size": 3,       
	"ytick.minor.width": 1
})

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
	
	# Load the data.
	data = np.fromfile(file_path, dtype=np.float32)
	
	# The number of data points per frame and calculate the # of frames.
	points_per_frame = nx*ny
	num_frames = len(data)//points_per_frame
	
	# Return the frames reshaped to work on an image.
	frames = data.reshape((num_frames, ny, nx))
	return frames 

@timefn
def make_animation(all_frames: np.array, output: str, zoomed: bool = False, nx: int = 4000, ny: int = 2000) -> None:
	"""
	Makes and saves the animation.

	Arguments (required)
	1. all_frames - The array of frames.
	2. output - The output file name.
	
	Arguments (optional)
	1. zoomed - If the visualization should zoom in on the cylinder. Default=false.
	2. nx - The x domain for zooming in. Default=4000.
	3. ny - The y domain for zooming in. Default=1000.

	Returns
	None
	"""
	
	fig, ax = plt.subplots(figsize=(10, 4))
	
	if zoomed:
		x_start, x_end = nx//8, nx//1.5
		y_start, y_end = ny//4, 3*ny//4
		
		ax.set_xlim([x_start, x_end])
		ax.set_ylim([y_start, y_end])

	# Show the first frame.
	img = ax.imshow(all_frames[0], origin='lower', cmap='inferno', interpolation='bilinear',
			vmin=0, vmax=0.15)
	
	# Add a colorbar and format properly.
	fig.colorbar(img, label=r'Velocity Magnitude ($u$)')
	ax.set_title('Kármán Vortex Street Evolution')
	ax.set_xlabel('Lattice X')
	ax.set_ylabel('Lattice Y')
	
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
	parser.add_argument('--zoomed', help='Zooms in on the cylinder region in the animation output.', action='store_true')
	
	# Parse the command line arguments.
	args = parser.parse_args()
	
	# Filename safety checks.
	if not args.config.endswith('.json'):
		args.config += '.json'
	if not args.output.endswith('.mp4'):
		args.output += '.mp4'

	# Load the JSON config file (this is from helper.py).
	config = load_json(args.config)
	
	# Get the details of the simulation we ran.
	nx = config['domain']['nx']
	ny = config['domain']['ny']
	tau = config['physics']['tau']
	u_inlet = config['physics']['u_inlet']
	base = config['output']['base_filename']
	
	# Find the .dat file for the simulation (see helper.py).
	filename = assemble_data_filename(base, nx, ny, tau, u_inlet) + '.bin'

	# Load the frame and make the animation.
	all_frames = load_frames(filename)
	make_animation(all_frames, args.output, args.zoomed, nx, ny)


