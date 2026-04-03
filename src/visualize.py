import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as anim

from typing import Any

nx, ny = 400, 100
filename = 'output.dat'

# todo comments and time_fn

def load_frames(file_path: str) -> np.array:
	"""
	"""
	
	data = np.loadtxt(file_path)
	
	points_per_frame = nx*ny
	num_frames = len(data)//points_per_frame
	
	frames = data[:, 2].reshape((num_frames, ny, nx))
	return frames 

if __name__ == '__main__':
	all_frames = load_frames(filename)
	
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
	
	ani.save('vortex_street.mp4', fps=30)
	
	plt.close()
