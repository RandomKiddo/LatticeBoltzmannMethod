import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as anim
import json
import argparse
import time

from typing import Any
from functools import wraps

# todo comments and time_fn

# * Adapted from pg.31 of High Performance Python by Gorelick & Osvald, 2nd ed.
# Function decorator to time a function.
def timefn(fn):
	@wraps(fn)
	def measure_time(*args, **kwargs):
		t0 = time.time()
		returns = fn(*args, **kwargs)
		tf = time.time()
		print(f'Fcn *{fn.__name__}* completed in {tf-t0:.3f}s.')
		return returns
	return measure_time

def load_json(filename: str) -> dict:
	with open(filename, 'r') as f:
		config = json.load(f)
	
	return dict(config)

def assemble_data_filename(base: str, nx: int, ny: int, tau: float, u_inlet: float) -> str:
	return f'{base}_{nx}x{ny}_tau{tau}_uinlet{u_inlet}.dat'

@timefn
def load_frames(file_path: str) -> np.array:
	"""
	"""
	
	data = np.loadtxt(file_path)
	
	points_per_frame = nx*ny
	num_frames = len(data)//points_per_frame
	
	frames = data[:, 2].reshape((num_frames, ny, nx))
	return frames 

@timefn
def make_animation(all_frames: np.array, output: str) -> None:
	fig, ax = plt.subplots(figsize=(10, 4))
	img = ax.imshow(all_frames[0], origin='lower', cmap='inferno', interpolation='bilinear',
			vmin=0, vmax=0.15)
	fig.colorbar(img, label='Velocity Magnitude')
	ax.set_title('Karman Vortex Street Evolution')
	ax.set_xlabel('x')
	ax.set_ylabel('y')
	
	def update(frame_idx: int) -> Any:
		img.set_array(all_frames[frame_idx])
		return [img]
	
	ani = anim.FuncAnimation(fig, update, frames=len(all_frames), interval=50, blit=True)
	
	ani.save(output, fps=30)
	plt.close()

if __name__ == '__main__':
	parser = argparse.ArgumentParser(prog='Karman Vortex Street LBM Visualizer',
					 description='Makes output MP4 animations from Karman Vortex Street LBM .dat files')
	parser.add_argument('--config', type=str, help='Path to JSON config file.', default='config.json')
	parser.add_argument('--output', type=str, help='Path and filename of output visualization.', default='vortex_street.mp4')
	
	args = parser.parse_args()

	config = load_json(args.config)
	
	nx = config['domain']['nx']
	ny = config['domain']['ny']
	tau = config['physics']['tau']
	u_inlet = config['physics']['u_inlet']
	base = config['output']['base_filename']
	
	filename = assemble_data_filename(base, nx, ny, tau, u_inlet)

	all_frames = load_frames(filename)
	
	make_animation(all_frames, args.output)


